# dotfiles

Personal config: `neovim`, `zsh`, `ghostty`. macOS-primary, Linux
(Arch/Hyprland) fallback.

## Install

Requires `stow` and `git`.

```sh
git clone <this repo> ~/.dotfiles
cd ~/.dotfiles
stow --restow -v --no-folding --dotfiles -t ~ -d ~/.dotfiles .
stow-dot   # subsequent runs
```

Flags:

- `--dotfiles` — `dot-zshrc` → `~/.zshrc`
- `--no-folding` — link files not dirs; keeps runtime state out of the repo

## Layout

| Path | Target | Notes |
| --- | --- | --- |
| `dot-config/` | `~/.config/` | `nvim`, `zsh`, `ghostty`, `newsraft` |
| `dot-local/bin/` | `~/.local/bin/` | user scripts |
| `dot-vim/` | `~/.vim/` | rescue vim config |
| `dot-bashrc` | `~/.bashrc` | rescue shell fallback |
| `dot-gitconfig` | `~/.gitconfig` | |
| `dot-zshenv` | `~/.zshenv` | sets `ZDOTDIR=~/.config/zsh` |
| `dot-ssh/` | `~/.ssh/` | placeholder |
| `dot-claude/` | `~/.claude/` | `CLAUDE.md` + per-skill links → `agents/` |
| `dot-codex/` | `~/.codex/` | `AGENTS.md` link → `agents/` |
| `agents/` | — (not stowed) | shared `AGENTS.md` + skills; reached only via `dot-claude/`, `dot-codex/` links |

## Local overrides

`~/.config/zsh/local` is gitignored and sourced first. Put machine-only state
there — never commit it:

- `PATH` prepends for machine-only tools
- corporate certs (`SSL_CERT_FILE`, `CURL_CA_BUNDLE`)
- secrets

## Stow ignores

`.stow-local-ignore` replaces stow's default list, so it re-declares the
defaults, then excludes repo-only files: `README.*`, `LICENSE`, `.github/`,
`.pre-commit-config.yaml`, `.typos.toml`, `stylua.toml`, `agents/`, and itself.

Skills: add a link per skill, `dot-claude/skills/<name> -> ../../agents/skills/<name>`.
Never link the whole `skills/` dir: `--no-folding` merges it into
`~/.claude/skills` (which holds non-stowed skills) as real dirs.

## Software

Inventory across hosts. Not every item is required on every host. Linux
provisioning lives in `~/.ansible`; macOS installs via Homebrew.

### Core

| Category | Packages |
| --- | --- |
| Shell | `zsh`, `bash`, `starship`, `zoxide`, `direnv`, `fzf`, `zsh-autosuggestions`, `zsh-history-substring-search`, `zsh-syntax-highlighting` |
| Editors/terminal | `neovim`, `vim`, `ptpython`, `ghostty` |
| Base | `git`, `stow`, `curl`, `wget`, `make`, `flatpak` |

### CLI

| Category | Packages |
| --- | --- |
| Replacements/viewers | `bat`, `eza`, `erdtree`, `ripgrep`, `fd`, `git-delta`, `difftastic`, `dust`, `duf`, `bottom`, `glow`, `tealdeer` |
| Data/docs | `duckdb`, `jq`, `yq` (mikefarah; Arch pkg `go-yq` — Arch `yq` is the Python jq wrapper), `visidata`, `chafa`, `poppler`, `zathura`, `Foliate` |
| Utilities | `tokei`, `hyperfine`, `just`, `sd`, `ast-grep`, `tree-sitter-cli`, `typos`, `ctags`, `gping`, `socat`, `7zip`, `zip`, `atuin`, `choose`, `procs`, `ripgrep-all`, `sdcv` |

### Dev

| Category | Packages |
| --- | --- |
| Languages | `go`, `rust` (Arch pkg, not rustup), `nodejs`, `pnpm`, `python`, `lua`, `luarocks`, `julia`, `ruby` |
| Python | `uv`, `ruff`, `ty`, `pyright` |
| Go tooling | `go-tools`, `gopls`, `gofumpt`, `golangci-lint`, `govulncheck` |
| Rust tooling | `rust-analyzer`, `cargo-nextest`, `cargo-deny`, `cargo-machete`, `cargo-update`, `cargo-mutants` (AUR) |
| Lua tooling | `lua-language-server` |
| Checks/CI | `prek` (pre-commit runner), `gitleaks`, `actionlint`, `zizmor` |
| Shell | `shellcheck`, `shfmt` |
| Git | `gh`, `lazygit`, `git-cliff` |
| Containers/infra | `docker`, `docker-buildx`, `docker-compose`, `lazydocker`, `kubectl`, `kubectx`, `k9s`, `argocd`, `helm`, `aws-cli-v2` |
| Build/libs | `libpq` (brew; Arch `postgresql-libs`), `base-devel` |

### Python tools (via `uv tool install`)

Current: `git-sim`, `radon`, `visidata`, `yt-dlp` (playbook), `ragwatcher`
(manual: local checkout, `uv tool install ~/Desktop/Projects/ragwatcher`).

Linters/type checkers come from pacman (above), not `uv tool`. Extend as
needed: `mypy`, `sqlfluff`.

### Linux desktop (Arch + Hyprland)

| Category | Packages |
| --- | --- |
| WM/compositor | `hyprland`, `hyprpaper`, `hyprsunset`, `waybar`, `mako`, `wofi` |
| Session | `network-manager-applet`, `wireplumber`, `brightnessctl`, `playerctl` |
| Screen/clipboard | `grim`, `slurp`, `cliphist`, `wl-clipboard` |
| File/image | `yazi`, `imv` |
| Apps/media | `firefox`, `newsraft`, `mpv`, `surfraw`, `yt-dlp`, `ollama`, `restic`, `task`, `keyd` |
| Agents | `claude-code` (AUR). `dot-codex/` and OpenCode config are stowed, but neither tool is installed by the playbook |
