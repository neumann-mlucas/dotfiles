#!/usr/bin/env bash

# TODO: SEPARATE PGKS INTO GROPS
# ADD XORG LIST
# ADD AUDIO LIST
# ADD BLUETOOTH LIST

echo
echo "INSTALLING SOFTWARE"
echo

PKGS=(
	# basic
	"docker"
	"git"
	"openssh"
	"reflector"
	"stow"
	"thermald"
	"ufw"
	# WM, terminal & editor
	"alacritty"
	"bspwm"
	"neovim"
	"rxvt-unicode"
	"starship"
	"sxhkd"
	"urxvt-perls"
	"zoxide"
	"zsh"
	"zsh-autosuggestions"
	"zsh-history-substring-search"
	"zsh-syntax-highlighting"
	# desktop utils
	"arandr"
	"clipmenu"
	"dmenu"
	"feh"
	"polybar"
	"redshift"
	"unclutter"
	"wget"
	"zoxide"
	# misc software
	"cronie"
	"ctags"
	"dictd"
	"direnv"
	"flite"
	"foliate"
	"hunspell"
	"hunspell-en_us"
	"mplayer"
	"syncthing"
	"transmission-gtk"
	"typespeed"
	"vlc"
	"words"
	"zathura"
	"zathura-djvu"
	"zathura-pdf-mupdf"
	"openvpn"
	# cli
	"wget"
	"xclip"
	"xsel"
	"curl"
	"gtop"
	"htop"
	"procs"
	"bat"
	"duf"
	"dust"
	"exa"
	"fd"
	"fzf"
	"git-delta"
	"github-cli"
	"glow"
	"gping"
	"jq"
	"newsboat"
	"ripgrep"
	"rsync"
	"scrot"
	"starship"
	"sxiv"
	"tealdeer"
	"tokei"
	"trash-cli"
	# languages
	"clang"
	"go"
	"julia"
	"nodejs"
	"npm"
	# browsers
	"firefox"
	"chromium"
	# python
	"python-pip"
	"python-pipx"
	# formatters
	"prettier"
	"shfmt"
	"stylua"
)

for PKG in "${PKGS[@]}"; do
	echo "INSTALLING: ${PKG}"
	sudo pacman -S "$PKG" --noconfirm --needed
done
