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

read -rp "Full name: " GIT_NAME
read -rp "Email: " GIT_EMAIL

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"

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
read -rp "Paste your SSH public key from 1Password (or leave blank to skip): " SSH_PUB_KEY

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

# Rebase on pull instead of merge commits
git config --global pull.rebase true

# Auto-stash before rebase, pop after
git config --global rebase.autoStash true

# Fast-forward only when pulling (no surprise merges)
git config --global pull.ff only

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
echo "   Pull:     rebase + ff-only"
echo ""
echo "📋 Next steps:"
echo "   1. Make sure 1Password SSH Agent is enabled"
echo "      (1Password → Settings → Developer → SSH Agent)"
echo "   2. Upload your SSH public key to GitHub/GitLab as a Signing Key"
echo "   3. Test with: git commit --allow-empty -m 'test signed commit'"
echo "   4. Verify with: git log --show-signature -1"
