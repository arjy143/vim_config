#!/usr/bin/env bash
# install_dependencies.sh - set up this vim config on a new machine.
#
# Usage: ./install_dependencies.sh [-y]
#   -y, --yes   don't ask before installing packages
#
# 1. installs the tools the config uses (clangd, ripgrep, glow, ...)
#    with apt (Debian/Ubuntu/WSL), dnf (Fedora) or pacman (Arch)
# 2. links ~/.vimrc to this repo (backing up an existing one)
# 3. installs the vim plugins (:PlugInstall)
# 4. puts bin/project_harness.sh on your PATH via ~/.local/bin
set -euo pipefail

repo="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
assume_yes=0
for arg in "$@"; do
    case $arg in
        -y | --yes) assume_yes=1 ;;
        -h | --help) sed -n '2,11s/^# \{0,1\}//p' "$0"; exit 0 ;;
        *) echo "unknown option: $arg (see --help)" >&2; exit 2 ;;
    esac
done

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*"; }
# run CMD...: print a command, then run it
run() { printf '  $ %s\n' "$*"; "$@"; }

sudo=""
((EUID == 0)) || sudo=sudo

# ---- 1. system packages --------------------------------------------------------
# what each package is for:
#   vim git curl          the editor itself, and downloading plugins
#   clangd clang-format   C/C++ language server + formatter (ALE, <leader>l...)
#   ripgrep               <leader>/ project-wide search
#   glow                  <leader>m markdown preview
#   cmake g++ gdb         building and debugging project_harness.sh projects
step "System packages"
if command -v apt-get >/dev/null; then
    packages=(vim git curl clangd clang-format ripgrep glow cmake g++ gdb)
    installed() { dpkg -s "$1" &>/dev/null; }
    available() { apt-cache show "$1" &>/dev/null; }
    install() { run $sudo apt-get install -y "$@"; }
    $sudo apt-get update -qq
elif command -v dnf >/dev/null; then
    packages=(vim-enhanced git curl clang-tools-extra ripgrep glow cmake gcc-c++ gdb)
    installed() { rpm -q "$1" &>/dev/null; }
    available() { dnf info -q "$1" &>/dev/null; }
    install() { run $sudo dnf install -y "$@"; }
elif command -v pacman >/dev/null; then
    packages=(vim git curl clang ripgrep glow cmake gcc gdb)
    installed() { pacman -Qi "$1" &>/dev/null; }
    available() { pacman -Si "$1" &>/dev/null; }
    install() { run $sudo pacman -S --needed --noconfirm "$@"; }
else
    packages=()
    warn "no apt, dnf or pacman found; install these yourself: vim git curl clangd clang-format ripgrep glow cmake g++ gdb"
fi

to_install=() unavailable=()
for pkg in "${packages[@]}"; do
    if installed "$pkg"; then
        continue
    elif available "$pkg"; then
        to_install+=("$pkg")
    else
        unavailable+=("$pkg")
    fi
done

if ((${#to_install[@]} == 0)); then
    echo "  everything available is already installed"
else
    echo "  to install: ${to_install[*]}"
    if ((!assume_yes)); then
        read -rp "  continue? [Y/n] " answer
        [[ ${answer:-y} =~ ^[Yy] ]] || { echo "aborted"; exit 1; }
    fi
    install "${to_install[@]}"
fi

# glow isn't packaged on every distro (e.g. older Ubuntu); fall back to the
# official release binary in ~/.local/bin.
for pkg in "${unavailable[@]}"; do
    if [[ $pkg == glow ]] && command -v glow >/dev/null; then
        continue    # already installed some other way
    elif [[ $pkg == glow ]]; then
        case $(uname -m) in
            x86_64) arch=x86_64 ;;
            aarch64 | arm64) arch=arm64 ;;
            *) warn "glow: no release binary for $(uname -m)"; continue ;;
        esac
        url="https://github.com/charmbracelet/glow/releases/download/v2.0.0/glow_2.0.0_Linux_${arch}.tar.gz"
        echo "  glow isn't packaged here; downloading the release binary to ~/.local/bin"
        run mkdir -p "$HOME/.local/bin"
        printf '  $ curl -fsSL %s | tar -xz ...\n' "$url"
        if curl -fsSL "$url" | tar -xzO "glow_2.0.0_Linux_${arch}/glow" >"$HOME/.local/bin/glow"; then
            run chmod +x "$HOME/.local/bin/glow"
        else
            rm -f "$HOME/.local/bin/glow"
            warn "couldn't download glow; install it manually"
        fi
    else
        warn "$pkg isn't available from your package manager; install it manually"
    fi
done

# ---- 2. ~/.vimrc -----------------------------------------------------------------
step "Linking ~/.vimrc"
if [[ -L $HOME/.vimrc && "$(readlink -f "$HOME/.vimrc")" == "$repo/.vimrc" ]]; then
    echo "  already linked"
else
    if [[ -e $HOME/.vimrc || -L $HOME/.vimrc ]]; then
        backup="$HOME/.vimrc.backup.$(date +%Y%m%d-%H%M%S)"
        echo "  backing up your existing ~/.vimrc to $backup"
        run mv "$HOME/.vimrc" "$backup"
    fi
    run ln -s "$repo/.vimrc" "$HOME/.vimrc"
fi

# ---- 3. vim plugins ---------------------------------------------------------------
step "Installing vim plugins"
run vim -Nu "$repo/.vimrc" -i NONE -Es +'PlugInstall --sync' +'qa!' >/dev/null || warn "PlugInstall reported a problem; run :PlugInstall inside vim to see it"

# ---- 4. project_harness.sh on PATH ------------------------------------------------
step "Installing project_harness.sh"
run mkdir -p "$HOME/.local/bin"
run ln -sfn "$repo/bin/project_harness.sh" "$HOME/.local/bin/project_harness.sh"
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    rc="$HOME/.$(basename "${SHELL:-bash}")rc"
    warn "~/.local/bin isn't on your PATH. Add this line to $rc and restart your shell:"
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# ---- 5. summary ---------------------------------------------------------------------
step "Summary"
for tool in vim clangd clang-format rg glow cmake g++ gdb; do
    if command -v "$tool" >/dev/null || [[ -x $HOME/.local/bin/$tool ]]; then
        printf '  \033[32mok\033[0m       %s\n' "$tool"
    else
        printf '  \033[31mmissing\033[0m  %s\n' "$tool"
    fi
done
if vim --version 2>/dev/null | grep -q -- '-clipboard' && ! grep -qi microsoft /proc/version 2>/dev/null; then
    echo
    echo "  note: this vim has no system clipboard support. For copy/paste with other"
    echo "  apps, install a GUI-enabled build (vim-gtk3 on Debian/Ubuntu, gvim on Arch)."
fi
