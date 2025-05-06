#!/bin/bash

# Source helper functions and variables
source ./helpers.sh

info "--- Starting Desktop Application Installation ---"

# --- Install using Package Manager (Idempotent) ---
info "Installing common applications..."
install_package vlc      # Needs RPM Fusion on Fedora / contrib/multiverse maybe?
install_package neovim
install_package qbittorrent

# --- Install using specific Repositories (Idempotent) ---



# --- Visual Studio Code ---
info "Setting up Visual Studio Code..."
if ! check_command code; then # Check if 'code' command exists
    if [ "$DISTRO" == "fedora" ]; then
        # Check if repo exists using the repo ID 'code'
        if ! check_dnf_repo "code"; then
             info "Adding VS Code repository (Fedora)..."
             # Import Microsoft GPG key
             sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
             # Add the VS Code repository configuration
             sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
             # dnf should pick up the new repo on next install/update automatically
             info "VS Code repository added."
        else
            info "VS Code repository (Fedora) already exists."
        fi
        # Install the package
        install_package code
    elif [ "$DISTRO" == "debian" ]; then
        # Placeholder for Debian/Ubuntu - requires different repo setup steps
        warn "VS Code automatic setup for Debian/Ubuntu is not implemented yet."
    fi
else
    info "VS Code command 'code' found. Skipping setup."
fi

# --- Install using Flatpak (Idempotent) ---

info "Setting up Flatpak..."
install_package flatpak # Ensure flatpak is installed

# Add Flathub repository if it doesn't exist
if ! check_flatpak_remote "flathub"; then
	info "Adding Flathub remote..."
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
	info "Flathub repository added."
else
	info "Flathub repository already exists."
fi

# Install Flatpak Apps (Idempotent checks within install_flatpak_package)
info "Installing Flatpak applications..."
install_flatpak_package com.discordapp.Discord
install_flatpak_package com.valvesoftware.Steam
install_flatpak_package com.moonlight_stream.Moonlight
install_flatpak_package md.obsidian.Obsidian
install_flatpak_package com.brave.Browser 
install_flatpak_package io.github.zyedidia.micro
install_flatpak_package org.gimp.GIMP
install_flatpak_package com.obsproject.Studio

# --- Oh My Zsh ---
info "Setting up Oh My Zsh..."
if ! check_directory "$HOME/.oh-my-zsh"; then
	if check_command zsh; then
		info "Installing Oh My Zsh..."
		# Run non-interactively; user must manually chsh if needed or start zsh
		if check_command curl; then
			sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || warn "Oh My Zsh installation script failed."
		elif check_command wget; then
			sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" "" --unattended || warn "Oh My Zsh installation script failed."
		else
			error "Cannot download Oh My Zsh installer. Curl or Wget not found."
		fi
		if check_directory "$HOME/.oh-my-zsh"; then # Verify install dir exists after attempt
			 info "Oh My Zsh installed. You may need to type 'zsh' or restart your terminal."
			 warn "Default shell might not be changed automatically. Use 'chsh -s $(which zsh)' if desired."
		fi
	else
		error "Zsh is not installed. Cannot install Oh My Zsh."
	fi
else
	info "Oh My Zsh directory already exists. Skipping installation."
fi

info "--- Desktop Application Installation Complete ---"