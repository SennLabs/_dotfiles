# dotfiles

Personal shell, terminal and editor configuration, aimed primarily at **headless
Linux hosts reached over SSH** (Debian, Ubuntu, Fedora), with a desktop profile
and partial Windows support. Everything is symlinked from this repo, so edits
here take effect immediately.

[![CI](https://github.com/SennLabs/_dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/SennLabs/_dotfiles/actions/workflows/ci.yml)

## Quick start

On a fresh machine:

```sh
curl -fsSL https://raw.githubusercontent.com/SennLabs/_dotfiles/main/bootstrap.sh | sh
```

That installs git, clones the repo to `~/_dotfiles`, and links the configs. Add
packages too with:

```sh
curl -fsSL .../bootstrap.sh | DOTFILES_APPS=1 sh
```

If you already have the repo:

```sh
git clone https://github.com/SennLabs/_dotfiles.git ~/_dotfiles
cd ~/_dotfiles
./Init.sh --profile server        # or: --profile desktop
./Init.sh --profile server --apps # also install packages
```

Re-running is safe. `SetupSimLink.sh` is idempotent, and anything already at a
target path is moved to `~/.dotfiles-backup/<timestamp>/` rather than deleted.

## Profiles

Cumulative — `server` includes `core`, `desktop` includes both. `container` sits
off to the side, taking the same packages as `core`.

| Profile | Packages | Configs |
| --- | --- | --- |
| `core` | git, curl, tmux, neovim, bat, fd, fzf, less, column | all non-GUI |
| `container` | same as `core` | non-GUI, minus fish and yazi |
| `server` | + fish, htop, jq, ripgrep, rsync, ncdu, unzip, yazi, python, rust, gh, docker | all non-GUI |
| `desktop` | + VSCode, WezTerm, browsers, graphics apps | everything, incl. WezTerm & KZones |

`server` is the default, since most installs here are headless. It deliberately
does not link WezTerm or KZones.

`container` is for dev containers, where a language toolchain or a Docker engine
belongs in the image or a devcontainer feature rather than in here — see
[Dev containers](#dev-containers).

## Scripts

| Script | Purpose |
| --- | --- |
| `bootstrap.sh` | One-shot setup on a bare machine (POSIX sh; installs git) |
| `Init.sh` | Records the repo path, then links configs |
| `SetupSimLink.sh` | Does the linking; idempotent, backs up what it replaces |
| `InstallApps.sh` | Installs packages from `apps/app_list.csv` via apt or dnf |
| `InstallApps.ps1` | Windows equivalent, via winget, same CSV |
| `SetupCron.sh` | Installs the 2-hourly pull-only sync |
| `AutoGitSync.sh` | **Pulls only.** Never commits or pushes |

`apps/app_list.csv` is the single source of truth for packages, with per-manager
columns (`Apt`, `Dnf`, `Winget`). A `-` means "not available here". Packages
missing from a host's repos are reported and skipped, not fatal.

## Where things get linked

| Repo path | Target | Profile |
| --- | --- | --- |
| `scripts/` | `~/.config/scripts` | all |
| `config/ssh/config` | `~/.ssh/config` | all |
| `config/git/config` | `~/.config/git/config` | all |
| `config/readline/inputrc` | `~/.inputrc` | all |
| `config/fish/config.fish` | `~/.config/fish/config.fish` | all but `container` |
| `config/fish/functions/` | `~/.config/fish/functions` | all but `container` |
| `config/nvim/` | `~/.config/nvim` | all |
| `config/yazi/` | `~/.config/yazi` | all but `container` |
| `config/tmux/tmux.conf` | `~/.tmux.conf` | all |
| `config/bash/.bash_aliases` | `~/.bash_aliases` | all |
| `config/bash/.bash_functions` | `~/.bash_functions` | all |
| `config/misc_env_var.sh` | `~/.config/dotfiles_env.sh` | all |
| `config/wezterm/.wezterm.lua` | `~/.wezterm.lua` | desktop |
| `config/kzones/layouts.json` | `~/.local/share/kzones/layouts.json` | desktop |

## Dev containers

Use the editor's own dotfiles support rather than a devcontainer feature. It
clones this repo into the container and runs the installer there as you, on
every container it builds, with nothing to publish or version:

```jsonc
// VS Code user settings (not the project's devcontainer.json)
"dotfiles.repository": "SennLabs/_dotfiles",
"dotfiles.installCommand": "Init.sh --profile container"
```

`installCommand` is optional — left out, the tooling finds `bootstrap.sh` on its
own, which detects that it is already inside a clone and links that tree in
place. It also reads `CODESPACES`, `REMOTE_CONTAINERS` and `DEVCONTAINER` from
the environment and selects the `container` profile without being told.

Tools are a separate matter. The install runs on every container create and is
never cached, so anything slow or heavy belongs in `devcontainer.json`, where it
caches into the image and into prebuilds:

```jsonc
"features": { "ghcr.io/devcontainers/features/common-utils:2": {} }
```

Two behaviours worth knowing about:

- **Your host's git config wins.** The container is handed a copy of the host's
  `~/.gitconfig`, and git reads that after the XDG file this repo links. So your
  real identity and any preference you set on the host follow you in, while the
  aliases and the settings the host leaves alone still come from here. This is
  deliberate; `config/git/config` says so too.
- **Bash only.** Aliases and functions are installed for bash. If something in
  your image makes zsh the default shell, the environment still reaches it (the
  image's `.zprofile` sources `.profile`) but the aliases and functions do not.

### Shell startup, and why it is split

SSH gives you a *login* shell, which reads `~/.profile` or `~/.bash_profile` —
never `~/.bashrc` directly. Ubuntu's stock `~/.bashrc` also returns early when
non-interactive. So:

- **Environment** (`dotfiles_env.sh`) is sourced from the **login file**, so
  `EDITOR`, `LANG` and `PAGER` are set even for `ssh host -t <cmd>`.
- **Aliases and functions** are sourced from **`~/.bashrc`**, because they are
  only meaningful in an interactive shell.

Both hooks are marker-delimited and added once. Check the environment loaded
with `ssh host 'echo $DOTFILES_ENV'` (prints `1`).

## Working over SSH

**Clipboard.** A headless host has no X11 or Wayland selection, so yanking
normally goes nowhere. tmux is set to `set-clipboard on` and Neovim emits OSC 52,
which the terminal turns into a copy on your *local* machine. Neovim ≥ 0.10 does
this itself when `$SSH_TTY` is set; the config wires it up explicitly for 0.9.

**Reconnecting.** `ta` attaches to the `main` tmux session, creating it if
needed — the normal way back in after a dropped link. `prefix + S` does the same
for a named session, `prefix + R` reloads the config.

**Readline.** `~/.inputrc` gives case-insensitive completion and ↑/↓ history
search on prefix, which is most of what makes a bare SSH prompt tolerable.

## Machine-specific and private config

Nothing secret belongs in a public repo:

- **SSH** — `config/ssh/config` starts with `Include ~/.ssh/config.local`. Put
  private hosts and identity files there; it is gitignored, and because the
  include comes first it wins over the shared defaults.
- **Git identity** — `config/git/config` includes `~/.config/git/config.local`,
  which is where `user.name` and `user.email` go:
  ```sh
  git config -f ~/.config/git/config.local user.email "you@example.com"
  ```
- **Anything else** — `.gitignore` covers `*.local`, `.env*` and key material.

## Distro differences handled

`bat` and `fd` are packaged as `batcat` and `fdfind` on Debian/Ubuntu but as
`bat` and `fd` on Fedora. Both shells detect which exists and export
`BAT_CMD` / `FD_CMD`. Similarly, `column` comes from `bsdextrautils` on Debian
and `util-linux` on Fedora, and `lsh` degrades gracefully when it is absent.
`EDITOR` falls back through nvim → vim → vi → nano and stays unset if none
exist, rather than pointing at a missing binary.

## Automatic updates

```sh
./SetupCron.sh
```

Adds a 2-hourly cron job running `AutoGitSync.sh`, which **only pulls** — it
never commits or pushes, and skips entirely if the tree is dirty or the branch
has diverged. Committing stays manual.

Two caveats: cron is absent from most containers (use a systemd timer instead),
and cron has no SSH agent, so this only works while the repo is public over
HTTPS.

## CI

`.github/workflows/ci.yml` runs shellcheck, parses the fish and Lua configs, and
then installs the dotfiles inside minimal `debian:stable-slim`, `ubuntu:latest`
and `fedora:latest` containers — asserting that the run is idempotent, that
every symlink resolves, that a login shell picks up the environment, and that
the package installer actually resolves real packages on both apt and dnf.

## Requirements

Core: `git`, `bash`. Everything else is optional and detected at runtime.

## TODO

- Neovim plugin management
- Per-host overrides beyond the `.local` files

## License

MIT — see [LICENSE](LICENSE).
