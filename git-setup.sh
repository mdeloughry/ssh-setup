#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────
# Git Setup Script
# Sets up Git with sane defaults and
# 1Password SSH commit signing on a new machine.
# ─────────────────────────────────────────────

echo "🔧 Git Setup"
echo "─────────────────────────────────────"

# ── Identity ──────────────────────────────────

read -rp "Full name: " GIT_NAME < /dev/tty

git config --global user.name "$GIT_NAME"

echo ""
echo "Do you do personal development, work development, or both?"
echo "  [p] Personal only"
echo "  [w] Work only"
echo "  [b] Both"
read -rp "Choice [p/w/b]: " DEV_TYPE < /dev/tty

case "$DEV_TYPE" in
    b|B)
        echo ""
        read -rp "Would you like different Git emails based on project folder? [y/N]: " FOLDER_EMAILS < /dev/tty

        if [[ "$FOLDER_EMAILS" =~ ^[Yy]$ ]]; then
            read -rp "Personal email: " PERSONAL_EMAIL < /dev/tty
            read -rp "Work email: " WORK_EMAIL < /dev/tty

            echo ""
            echo "Enter the folder paths where your projects live."
            echo "  (use ~ for home directory, e.g. ~/projects/personal)"
            read -rp "Personal projects folder: " PERSONAL_DIR < /dev/tty
            read -rp "Work projects folder: " WORK_DIR < /dev/tty

            # Expand ~ to $HOME
            PERSONAL_DIR="${PERSONAL_DIR/#\~/$HOME}"
            WORK_DIR="${WORK_DIR/#\~/$HOME}"

            # Ensure trailing slash for gitdir matching
            [[ "$PERSONAL_DIR" != */ ]] && PERSONAL_DIR="${PERSONAL_DIR}/"
            [[ "$WORK_DIR" != */ ]] && WORK_DIR="${WORK_DIR}/"

            # Set personal as the global default
            git config --global user.email "$PERSONAL_EMAIL"

            # Create folder-specific gitconfig files
            echo -e "[user]\n    email = $PERSONAL_EMAIL" > "$HOME/.gitconfig-personal"
            echo -e "[user]\n    email = $WORK_EMAIL" > "$HOME/.gitconfig-work"

            # Add includeIf directives
            git config --global --remove-section "includeIf \"gitdir:${PERSONAL_DIR}\"" 2>/dev/null || true
            git config --global --remove-section "includeIf \"gitdir:${WORK_DIR}\"" 2>/dev/null || true
            git config --global "includeIf.gitdir:${PERSONAL_DIR}.path" "$HOME/.gitconfig-personal"
            git config --global "includeIf.gitdir:${WORK_DIR}.path" "$HOME/.gitconfig-work"

            echo "✅ Folder-based emails configured:"
            echo "   ${PERSONAL_DIR} → $PERSONAL_EMAIL"
            echo "   ${WORK_DIR} → $WORK_EMAIL"
        else
            read -rp "Email: " GIT_EMAIL < /dev/tty
            git config --global user.email "$GIT_EMAIL"
        fi
        ;;
    *)
        read -rp "Email: " GIT_EMAIL < /dev/tty
        git config --global user.email "$GIT_EMAIL"
        ;;
esac

# ── 1Password SSH Commit Signing ──────────────

echo ""
echo "Detecting OS..."

case "$(uname -s)" in
    Darwin)
        OP_SSH_SIGN="/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
        ;;
    Linux)
        OP_SSH_SIGN="/opt/1Password/op-ssh-sign"
        ;;
    MINGW*|MSYS*|CYGWIN*)
        OP_SSH_SIGN="C:\\Users\\${USERNAME}\\AppData\\Local\\1Password\\app\\8\\op-ssh-sign.exe"
        ;;
    *)
        echo "⚠️  Unknown OS — skipping 1Password signing setup."
        echo "   You'll need to set gpg.ssh.program manually."
        OP_SSH_SIGN=""
        ;;
esac

if [[ -n "$OP_SSH_SIGN" ]]; then
    # Check the signing program exists (skip check on Windows)
    if [[ "$(uname -s)" =~ ^(MINGW|MSYS|CYGWIN) ]] || [[ -f "$OP_SSH_SIGN" ]]; then
        echo "✅ Found 1Password SSH signer: $OP_SSH_SIGN"
        git config --global gpg.format ssh
        git config --global gpg.ssh.program "$OP_SSH_SIGN"
        git config --global commit.gpgsign true
        git config --global tag.gpgsign true
    else
        echo "⚠️  1Password SSH signer not found at: $OP_SSH_SIGN"
        echo "   Install 1Password desktop app, then re-run this script."
        echo "   Skipping signing setup for now."
    fi
fi

# ── SSH Key ───────────────────────────────────

echo ""
read -rp "Paste your SSH public key from 1Password (or leave blank to skip): " SSH_PUB_KEY < /dev/tty

if [[ -n "$SSH_PUB_KEY" ]]; then
    git config --global user.signingkey "$SSH_PUB_KEY"
    echo "✅ Signing key configured."
else
    echo "⏭️  Skipped — remember to set user.signingkey later:"
    echo "   git config --global user.signingkey 'key ssh-ed25519 AAAA...'"
fi

# ── Sane Defaults ─────────────────────────────

echo ""
echo "Applying sane defaults..."

# Default branch name
git config --global init.defaultBranch main

# Pull strategy
echo ""
echo "How should 'git pull' handle diverged branches?"
echo "  [m] Merge (Recommended) - creates a merge commit to combine changes"
echo "  [f] Fast-forward only - fails if branches have diverged"
read -rp "Choice [m/f]: " PULL_STRATEGY < /dev/tty

case "$PULL_STRATEGY" in
    f|F)
        git config --global pull.rebase false
        git config --global pull.ff only
        echo "✅ Pull strategy: fast-forward only"
        ;;
    *)
        git config --global pull.rebase false
        git config --global --unset pull.ff 2>/dev/null || true
        echo "✅ Pull strategy: merge"
        ;;
esac

# Better diff algorithm
git config --global diff.algorithm histogram

# Show moved lines in diffs
git config --global diff.colorMoved default

# Cleaner merge conflict markers (shows base ancestor)
git config --global merge.conflictstyle zdiff3

# Auto-fix typos in commands (e.g. git stauts → git status)
git config --global help.autocorrect prompt

# Sort branches by most recent commit
git config --global branch.sort -committerdate

# Sort tags by version number
git config --global tag.sort version:refname

# Push the current branch only by default
git config --global push.default current

# Auto-set upstream on first push
git config --global push.autoSetupRemote true

# Prune deleted remote branches on fetch
git config --global fetch.prune true

# Prune deleted remote tags on fetch
git config --global fetch.prunetags true

# Reuse recorded conflict resolutions
git config --global rerere.enabled true

# Use patience for better hunk headers
git config --global diff.mnemonicPrefix true

# ── Aliases ───────────────────────────────────

echo "Setting up aliases..."

git config --global alias.st "status -sb"
git config --global alias.co "checkout"
git config --global alias.sw "switch"
git config --global alias.br "branch"
git config --global alias.cm "commit"
git config --global alias.amend "commit --amend --no-edit"
git config --global alias.undo "reset --soft HEAD~1"
git config --global alias.lg "log --oneline --graph --decorate -20"
git config --global alias.last "log -1 --stat"
git config --global alias.wip "commit -am 'wip'"

# ── Summary ───────────────────────────────────

echo ""
echo "─────────────────────────────────────"
echo "✅ Done! Here's your config:"
echo ""
echo "   Name:     $(git config --global user.name)"
echo "   Email:    $(git config --global user.email)"
echo "   Signing:  $(git config --global gpg.format 2>/dev/null || echo 'not set')"
echo "   Branch:   $(git config --global init.defaultBranch)"
echo "   Pull:     $(git config --global pull.ff 2>/dev/null && echo 'fast-forward only' || echo 'merge')"

if [[ -f "$HOME/.gitconfig-personal" ]] && [[ -f "$HOME/.gitconfig-work" ]]; then
    echo ""
    echo "   Folder-based emails:"
    echo "   Personal: $(git config --file "$HOME/.gitconfig-personal" user.email)"
    echo "   Work:     $(git config --file "$HOME/.gitconfig-work" user.email)"
fi

echo ""
echo "📋 Next steps:"
echo "   1. Make sure 1Password SSH Agent is enabled"
echo "      (1Password -> Settings -> Developer -> SSH Agent)"
echo "   2. Upload your SSH public key to GitHub/GitLab as a Signing Key"
echo "   3. Test with: git commit --allow-empty -m 'test signed commit'"
echo "   4. Verify with: git log --show-signature -1"
