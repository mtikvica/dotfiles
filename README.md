# My Dotfiles

Personal configuration files for my development environment.

## What's included

- **Zsh**: Oh-My-Zsh with plugins (autosuggestions, syntax-highlighting)
- **Tmux**: Modern config with vim-tmux-navigator
- **Neovim**: LazyVim configuration
- **Git**: Global git configuration
- **Ghostty**: Terminal emulator settings

## Quick Install
```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

## Manual Install

### Dependencies
```bash
# Arch/Manjaro
sudo pacman -S git zsh tmux neovim fzf fd ripgrep stow

# Fedora
sudo dnf install git zsh tmux neovim fzf fd-find ripgrep stow
```

### Using GNU Stow
```bash
cd ~/dotfiles
stow zsh
stow tmux
stow nvim
stow git
stow ghostty
```

## Post-Install

1. Install Oh-My-Zsh:
```bash
   sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

2. Install Zsh plugins:
```bash
   git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
   git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

3. Install TPM (Tmux Plugin Manager):
```bash
   git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

4. Install tmux plugins:
   - Start tmux: `tmux`
   - Press: `Ctrl+Space` then `Shift+I`

5. Change default shell:
```bash
   chsh -s $(which zsh)
```

## System Info

- OS: Arch Linux (Omakub)
- Terminal: Ghostty
- Shell: Zsh with Oh-My-Zsh
- Editor: Neovim (LazyVim)
- Font: JetBrains Mono

EOF
