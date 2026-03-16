# Git Setup

Opinionated Git configuration with 1Password SSH commit signing and sane defaults. Run it once on a new machine and you're good to go.

## What it does

**1Password commit signing** — auto-detects your OS and configures Git to sign commits and tags using 1Password's SSH agent. No GPG keyrings, no passphrases — just biometric auth when you commit.

**Sane defaults** — linear history with `pull.rebase` and `pull.ff only`, `zdiff3` conflict markers that show the common ancestor, auto-pruning of stale remote branches, `rerere` to remember conflict resolutions, and more.

**Aliases** — `git st`, `git lg`, `git amend`, `git undo`, `git wip`, and others.

## Prerequisites

- [1Password desktop app](https://1password.com/downloads) installed
- SSH Agent enabled in 1Password (Settings → Developer → SSH Agent)
- An SSH key stored in 1Password
- Git 2.34+ (required for SSH signing)

## Quick start

### Option 1: One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/YOURUSER/dotfiles/main/bootstrap.sh | bash
```

This downloads `git-setup.sh`, verifies its SHA-256 checksum, shows you the contents, and asks for confirmation before running.

### Option 2: Inspect first

```bash
curl -fsSL -o bootstrap.sh https://raw.githubusercontent.com/YOURUSER/dotfiles/main/bootstrap.sh
less bootstrap.sh
bash bootstrap.sh
```

### Option 3: Run directly

```bash
git clone https://github.com/YOURUSER/dotfiles.git
cd dotfiles
bash git-setup.sh
```

## After running

1. **Upload your SSH public key** to [GitHub](https://github.com/settings/keys) or [GitLab](https://gitlab.com/-/user_settings/ssh_keys) as a **Signing Key** (not just an Authentication Key — you need both).

2. **Test it works:**

   ```bash
   git commit --allow-empty -m "test signed commit"
   git log --show-signature -1
   ```

   1Password should prompt you for biometric auth on the commit, and the log should show a valid signature.

## Updating the setup script

If you edit `git-setup.sh`, regenerate the checksum and update `bootstrap.sh`:

```bash
# Generate new hash
shasum -a 256 git-setup.sh

# Paste the output into bootstrap.sh on the EXPECTED_SHA256 line
```

## What gets configured

### Signing

| Setting | Value | Why |
|---|---|---|
| `gpg.format` | `ssh` | Use SSH keys instead of GPG |
| `gpg.ssh.program` | `op-ssh-sign` | Delegate signing to 1Password |
| `commit.gpgsign` | `true` | Sign every commit automatically |
| `tag.gpgsign` | `true` | Sign every tag automatically |

### Defaults

| Setting | Value | Why |
|---|---|---|
| `init.defaultBranch` | `main` | Modern default branch name |
| `pull.rebase` | `true` | Rebase on pull for linear history |
| `pull.ff` | `only` | No surprise merge commits |
| `rebase.autoStash` | `true` | Stash dirty work before rebase, pop after |
| `merge.conflictstyle` | `zdiff3` | Shows common ancestor in conflicts |
| `push.default` | `current` | Push current branch only |
| `push.autoSetupRemote` | `true` | No more "set upstream" errors |
| `fetch.prune` | `true` | Clean up stale remote branches |
| `fetch.prunetags` | `true` | Clean up stale remote tags |
| `rerere.enabled` | `true` | Remember conflict resolutions |
| `diff.algorithm` | `histogram` | Better diff output |
| `diff.colorMoved` | `default` | Highlight moved lines in diffs |
| `branch.sort` | `-committerdate` | Most recent branches first |
| `help.autocorrect` | `prompt` | Offer to fix typos in commands |

### Aliases

| Alias | Command | |
|---|---|---|
| `git st` | `status -sb` | Short status |
| `git co` | `checkout` | |
| `git sw` | `switch` | |
| `git br` | `branch` | |
| `git cm` | `commit` | |
| `git amend` | `commit --amend --no-edit` | Update last commit |
| `git undo` | `reset --soft HEAD~1` | Undo last commit, keep changes |
| `git lg` | `log --oneline --graph --decorate -20` | Pretty log |
| `git last` | `log -1 --stat` | Show last commit |
| `git wip` | `commit -am 'wip'` | Quick work-in-progress commit |

## Files

```
├── bootstrap.sh    # Secure download wrapper with checksum verification
├── git-setup.sh    # Main setup script
└── README.md
```

## License

MIT — do whatever you like with it.
