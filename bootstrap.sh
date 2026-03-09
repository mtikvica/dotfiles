#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh — Toma's Omarchy post-install setup
# Run AFTER: fresh Omarchy install + SSH keys copied to ~/.ssh/
# Usage: bash bootstrap.sh
# =============================================================================

set -e

DOTFILES_REPO="git@github.com:mtikvica/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

step() { echo -e "\n${CYAN}==> $1${NC}"; }
ok() { echo -e "${GREEN}    ✓ $1${NC}"; }
warn() { echo -e "${YELLOW}    ! $1${NC}"; }
die() {
  echo -e "${RED}    ✗ $1${NC}"
  exit 1
}

# =============================================================================
# 0. PREFLIGHT CHECKS
# =============================================================================
step "Preflight checks"

# SSH key present?
if [ ! -f "$HOME/.ssh/id_ed25519" ] && [ ! -f "$HOME/.ssh/id_rsa" ]; then
  die "No SSH key found in ~/.ssh/ — copy your keys first, then re-run."
fi
ok "SSH key found"

# SSH agent running + key loaded?
ssh-add -l &>/dev/null || warn "SSH agent has no keys loaded. Run: ssh-add ~/.ssh/id_ed25519"

# Test GitHub SSH access
if ! ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
  warn "GitHub SSH auth failed — dotfiles clone may fail. Check your key is added to GitHub."
fi

# Omarchy installs yay — verify it's present
command -v yay &>/dev/null || die "yay not found. Is Omarchy fully installed?"
ok "yay found"

# =============================================================================
# 1. SYSTEM UPDATE
# =============================================================================
step "System update"
yay -Syu --noconfirm
ok "System up to date"

# =============================================================================
# 2. CLONE DOTFILES
# =============================================================================
step "Dotfiles"

if [ -d "$DOTFILES_DIR" ]; then
  warn "~/dotfiles already exists, pulling latest"
  git -C "$DOTFILES_DIR" pull
else
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  ok "Cloned dotfiles"
fi

# =============================================================================
# 3. PACKAGES — pacman/yay
# =============================================================================
step "Packages (pacman/yay)"

PKGLIST="$DOTFILES_DIR/packages/pkglist.txt"
AURLIST="$DOTFILES_DIR/packages/aurlist.txt"

if [ -f "$PKGLIST" ]; then
  yay -S --needed --noconfirm - <"$PKGLIST"
  ok "pacman packages installed"
else
  warn "No packages/pkglist.txt found in dotfiles — skipping"
  warn "Generate it on your existing machine with: yay -Qqen > ~/dotfiles/packages/pkglist.txt"

  # Fallback: install known base deps for the rest of this script
  step "Installing base dependencies (fallback)"
  yay -S --needed --noconfirm \
    git stow zsh tmux neovim \
    fzf fd ripgrep \
    ghostty \
    docker \
    go \
    dotnet-sdk \
    base-devel \
    kanata
  ok "Base dependencies installed"
fi

if [ -f "$AURLIST" ]; then
  yay -S --needed --noconfirm - <"$AURLIST"
  ok "AUR packages installed"
else
  warn "No packages/aurlist.txt found — skipping AUR restore"
  warn "Generate it with: yay -Qqem > ~/dotfiles/packages/aurlist.txt"
fi

# =============================================================================
# 4. PACKAGES — Flatpak
# =============================================================================
step "Flatpak apps"

FLATPAK_LIST="$DOTFILES_DIR/packages/flatpak.txt"

if command -v flatpak &>/dev/null; then
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

  if [ -f "$FLATPAK_LIST" ]; then
    while IFS= read -r app; do
      [[ -z "$app" || "$app" == \#* ]] && continue
      flatpak install -y flathub "$app" || warn "Failed to install flatpak: $app"
    done <"$FLATPAK_LIST"
    ok "Flatpak apps installed"
  else
    warn "No packages/flatpak.txt found — skipping"
    warn "Generate it with: flatpak list --app --columns=application > ~/dotfiles/packages/flatpak.txt"
  fi
else
  warn "flatpak not found, skipping"
fi

# =============================================================================
# 5. FONTS
# =============================================================================
step "Fonts"

if ! fc-list | grep -qi "JetBrainsMono"; then
  yay -S --needed --noconfirm ttf-jetbrains-mono-nerd
  ok "JetBrains Mono Nerd Font installed"
else
  ok "JetBrains Mono already present"
fi

fc-cache -f
ok "Font cache refreshed"

# =============================================================================
# 6. ZSH + OH MY ZSH
# =============================================================================
step "Zsh + Oh My Zsh"

# Set zsh as default shell if not already
if [ "$SHELL" != "$(which zsh)" ]; then
  chsh -s "$(which zsh)"
  ok "Default shell set to zsh (takes effect on next login)"
else
  ok "zsh already default shell"
fi

# Install Oh My Zsh if missing
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  ok "Oh My Zsh installed"
else
  ok "Oh My Zsh already present"
fi

# Plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  ok "zsh-autosuggestions installed"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  ok "zsh-syntax-highlighting installed"
fi

# =============================================================================
# 7. TMUX — TPM
# =============================================================================
step "Tmux plugin manager"

if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone --depth=1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  ok "TPM installed"
else
  ok "TPM already present"
fi

# =============================================================================
# 8. STOW DOTFILES
# =============================================================================
step "Stowing dotfiles"

cd "$DOTFILES_DIR"

STOW_PACKAGES=(ghostty git hypr kanata nvim tmux zsh)

for pkg in "${STOW_PACKAGES[@]}"; do
  if [ -d "$DOTFILES_DIR/$pkg" ]; then
    stow --restow "$pkg" 2>/dev/null && ok "stowed: $pkg" || warn "stow conflict in: $pkg (manual fix may be needed)"
  else
    warn "Package not found in dotfiles, skipping: $pkg"
  fi
done

# =============================================================================
# 9. DEV TOOLS — Rust
# =============================================================================
step "Rust (rustup)"

if ! command -v rustup &>/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
  ok "rustup installed"
else
  rustup update
  ok "rustup updated"
fi

# Source cargo env for remainder of script
# shellcheck disable=SC1091
source "$HOME/.cargo/env" 2>/dev/null || true

# =============================================================================
# 10. DEV TOOLS — Node via fnm
# =============================================================================
step "Node.js (fnm)"

if ! command -v fnm &>/dev/null; then
  curl -fsSL https://fnm.vercel.app/install | bash --no-use
  # shellcheck disable=SC1090
  export PATH="$HOME/.local/share/fnm:$PATH"
  eval "$(fnm env)"
  ok "fnm installed"
else
  ok "fnm already present"
fi

fnm install --lts 2>/dev/null && ok "Node LTS installed" || warn "Node install failed (may already exist)"

# =============================================================================
# 11. DEV TOOLS — Python via pyenv
# =============================================================================
step "Python (pyenv)"

if [ ! -d "$HOME/.pyenv" ]; then
  curl https://pyenv.run | bash
  ok "pyenv installed"
else
  ok "pyenv already present"
fi

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)" 2>/dev/null || true

# Install latest stable Python 3.12 if not present
if ! pyenv versions | grep -q "3.12"; then
  pyenv install 3.12
  pyenv global 3.12
  ok "Python 3.12 installed and set as global"
else
  ok "Python 3.12 already installed"
fi

# =============================================================================
# 12. DOCKER
# =============================================================================
step "Docker"

if command -v docker &>/dev/null; then
  # Enable and start Docker daemon
  sudo systemctl enable --now docker
  # Add user to docker group if not already
  if ! groups "$USER" | grep -q docker; then
    sudo usermod -aG docker "$USER"
    warn "Added $USER to docker group — log out and back in for it to take effect"
  else
    ok "User already in docker group"
  fi
  ok "Docker ready"
else
  warn "docker not found — install via yay or check pkglist.txt"
fi

# =============================================================================
# 13. KANATA
# =============================================================================
step "Kanata"

if command -v kanata &>/dev/null; then
  # kanata needs to run as root or with uinput group access
  if ! groups "$USER" | grep -q uinput; then
    sudo groupadd -f uinput
    sudo usermod -aG uinput "$USER"
    warn "Added $USER to uinput group — log out and back in for it to take effect"
  else
    ok "User already in uinput group"
  fi

  # udev rule so /dev/uinput is accessible without root
  UDEV_RULE='/etc/udev/rules.d/99-uinput.rules'
  if [ ! -f "$UDEV_RULE" ]; then
    echo 'KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"' |
      sudo tee "$UDEV_RULE" >/dev/null
    sudo udevadm control --reload-rules && sudo udevadm trigger
    ok "udev rule for uinput created"
  else
    ok "udev rule already present"
  fi

  # Enable kanata systemd user service (assumes kanata.service exists in dotfiles/kanata)
  systemctl --user enable --now kanata 2>/dev/null &&
    ok "kanata service enabled" ||
    warn "kanata user service not found — you may need a system service instead"
else
  warn "kanata binary not found — make sure it's in pkglist.txt or aurlist.txt"
fi

# =============================================================================
# 14. NEOVIM — trigger lazy.nvim sync (now 14, was 13)
# =============================================================================
step "Neovim plugins (lazy.nvim)"

if command -v nvim &>/dev/null; then
  nvim --headless "+Lazy! sync" +qa 2>/dev/null && ok "Neovim plugins synced" || warn "Neovim sync had issues (run :Lazy sync manually)"
else
  warn "nvim not found, skipping plugin sync"
fi

# =============================================================================
# 15. SYSTEMD USER SERVICES
# =============================================================================
step "Systemd user services"

SERVICES_FILE="$DOTFILES_DIR/packages/services.txt"

if [ -f "$SERVICES_FILE" ]; then
  while IFS= read -r svc; do
    [[ -z "$svc" || "$svc" == \#* ]] && continue
    systemctl --user enable --now "$svc" 2>/dev/null && ok "enabled: $svc" || warn "failed to enable: $svc"
  done <"$SERVICES_FILE"
else
  warn "No packages/services.txt found — skipping"
  warn "Add services you want auto-enabled, one per line"
fi

# =============================================================================
# DONE
# =============================================================================
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Bootstrap complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "  ${YELLOW}Manual steps remaining:${NC}"
echo -e "  1. Log out and back in (docker group + zsh shell take effect)"
echo -e "  2. Open tmux → Ctrl+Space then Shift+I  (install tmux plugins)"
echo -e "  3. Import GPG key if you sign commits"
echo -e "  4. Log into browser sync"
echo -e "  5. Add any secrets / API keys manually"
echo ""
echo -e "  ${CYAN}Package list maintenance:${NC}"
echo -e "  Save packages:  yay -Qqen > ~/dotfiles/packages/pkglist.txt"
echo -e "  Save AUR:       yay -Qqem > ~/dotfiles/packages/aurlist.txt"
echo -e "  Save flatpaks:  flatpak list --app --columns=application > ~/dotfiles/packages/flatpak.txt"
echo ""
