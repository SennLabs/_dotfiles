# dotfiles

Personal shell, terminal and editor configuration for Linux (Debian/Ubuntu and
Fedora), with partial Windows support. Everything is symlinked into place from
this repo, so edits here take effect immediately and nothing is copied around.

## What's in here

| Path | What it configures |
| --- | --- |
| `config/bash/` | Bash aliases and functions |
| `config/fish/` | Fish config, colours and functions |
| `config/nvim/` | Neovim options and keymaps |
| `config/tmux/` | tmux keybinds, status line and theme |
| `config/wezterm/` | WezTerm keys, mouse bindings and colour scheme |
| `config/yazi/` | Yazi file manager |
| `config/ssh/` | Shared SSH client defaults |
| `config/kzones/` | KDE KZones window layouts |
| `config/misc_env_var.sh` | Shared env vars (`EDITOR`, fzf, `bat`/`fd`) |
| `scripts/` | Helper scripts, linked to `~/.config/scripts` |
| `apps/` | Package lists for provisioning a new machine |

## Setup

```sh
git clone https://github.com/SennLabs/_dotfiles.git ~/_dotfiles
cd ~/_dotfiles
./Init.sh
```

`Init.sh` records the repo path in `~/.config/dotfiles`, then runs
`SetupSimLink.sh` to create the symlinks. Restart your shell afterwards.

Re-running is safe. `SetupSimLink.sh` is idempotent, and anything already
sitting at a target path is moved into `~/.dotfiles-backup/<timestamp>/`
rather than deleted.

### Optional: automatic updates

```sh
./SetupCron.sh
```

Adds a 2-hourly cron job running `AutoGitSync.sh`, which **only pulls**. It
never commits or pushes, and it skips the pull entirely if the working tree is
dirty or the branch has diverged. Committing your own changes stays manual.

## Where things get linked

| Repo path | Target |
| --- | --- |
| `scripts/` | `~/.config/scripts` |
| `config/ssh/config` | `~/.ssh/config` |
| `config/fish/config.fish` | `~/.config/fish/config.fish` |
| `config/fish/functions/` | `~/.config/fish/functions` |
| `config/nvim/` | `~/.config/nvim` |
| `config/yazi/` | `~/.config/yazi` |
| `config/tmux/tmux.conf` | `~/.tmux.conf` |
| `config/wezterm/.wezterm.lua` | `~/.wezterm.lua` |
| `config/bash/.bash_aliases` | `~/.bash_aliases` |
| `config/bash/.bash_functions` | `~/.bash_functions` |
| `config/misc_env_var.sh` | `~/.config/dotfiles_env.sh` |

`SetupSimLink.sh` also appends a small marked block to `~/.bashrc` that sources
the three bash files, because Fedora's default `~/.bashrc` — unlike Debian's —
does not pick up `~/.bash_aliases` on its own.

## Machine-specific and private config

Nothing secret belongs in a public repo. Two escape hatches:

- **SSH** — `config/ssh/config` starts with `Include ~/.ssh/config.local`.
  Put private hosts, internal hostnames and identity files there; it is
  gitignored and the `Include` comes first, so it wins over the shared defaults.
- **Anything else** — `.gitignore` covers `*.local`, `.env*`, key material and
  `known_hosts`.

## Distro differences handled

`bat` and `fd` are packaged as `batcat` and `fdfind` on Debian/Ubuntu because
of name collisions, but as `bat` and `fd` on Fedora. `config/misc_env_var.sh`
(bash) and `config/fish/config.fish` (fish) each detect which is present and
export `BAT_CMD` / `FD_CMD`; aliases and fzf's preview command use those.

## Requirements

Core: `git`, `bash`. Optional but assumed by parts of the config: `nvim`,
`tmux`, `fish`, `fzf`, `bat`, `fd`, `yazi`, `column` (util-linux).

## Provisioning a new machine

`apps/app_list.csv` is the cross-platform inventory, with `Win` / `Linux`
columns marking availability. `apps/winget.txt` is the Windows subset, ready
for:

```powershell
Get-Content apps/winget.txt | ForEach-Object { winget install --id $_ --exact }
```

There is no Linux installer script yet — see TODO.

## TODO

- Linux package install script driven by `apps/app_list.csv`
- Configurable install profiles (CLI, GUI, server, Windows)
- Neovim plugin management

## License

MIT — see [LICENSE](LICENSE).
