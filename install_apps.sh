#!/bin/bash

# Source helper functions and variables
source ./helpers.sh

info "--- Starting Desktop Application Installation ---"

# --- Install using Package Manager ---

# VLC (Needs RPM Fusion on Fedora, often in main repos on Debian/Ubuntu)
info "Installing VLC..."
install_package vlc

# Neovim
info "Installing Neovim..."
install_package neovim

# Micro Editor
info "Installing Micro Editor..."
install_package micro

# --- Install using specific Repositories ---

# Brave Browser
info "Setting up Brave Browser repository and installing..."
if [ "$DISTRO" == "fedora" ]; then
    sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
    sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
    install_package brave-browser
elif [ "$DISTRO" == "debian" ]; then
    install_package apt-transport-https # Dependency
    curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
    $PKG_MANAGER update
    install_package brave-browser
fi

# Sublime Text
info "Setting up Sublime Text repository and installing..."
if [ "$DISTRO" == "fedora" ]; then
    sudo rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
    $ADD_REPO_CMD https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo
    install_package sublime-text
elif [ "$DISTRO" == "debian" ]; then
    install_package apt-transport-https # Dependency
    wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null
    echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
    $PKG_MANAGER update
    install_package sublime-text
fi

# --- Install using Flatpak ---

info "Setting up Flatpak and Flathub..."
install_package flatpak
# Add Flathub repository if it doesn't exist
if ! flatpak remote-list | grep -q flathub; then
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    info "Flathub repository added."
else
    info "Flathub repository already exists."
fi

# Install Flatpak Apps
install_flatpak_package com.discordapp.Discord     # Discord
install_flatpak_package com.valvesoftware.Steam     # Steam (Alternative to RPM Fusion / apt version)
install_flatpak_package com.moonlight_stream.Moonlight # Moonlight Game Streaming
install_flatpak_package md.obsidian.Obsidian         # Obsidian

# Optionally Install Steam via package manager if preferred (needs RPM Fusion non-free on Fedora)
# info "Installing Steam (via package manager)..."
# if [ "$DISTRO" == "fedora" ]; then
#     install_package steam # Requires RPM Fusion non-free enabled
# elif [ "$DISTRO" == "debian" ]; then
#     # Requires enabling multiverse on Ubuntu, or non-free on Debian
#     install_package steam
# fi


# Oh My Zsh (Installs for the current user)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "Installing Oh My Zsh..."
    # Needs user interaction to confirm changing default shell unless automated further
    # sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || warn "Oh My Zsh installation failed or was cancelled."
    # Run non-interactively, but user must manually chsh if needed
    if command -v curl &> /dev/null; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    elif command -v wget &> /dev/null; then
        sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" "" --unattended
    else
        error "Cannot download Oh My Zsh installer. Curl or Wget not found."
    fi

    if [ $? -eq 0 ]; then
        info "Oh My Zsh installed. You may need to type 'zsh' or restart your terminal."
        warn "Default shell might not be changed automatically. Use 'chsh -s $(which zsh)' if needed."
    else
        warn "Oh My Zsh installation script finished with errors or was interrupted."
    fi
else
    info "Oh My Zsh already installed."
fi


info "--- Desktop Application Installation Complete ---"