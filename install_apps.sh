#!/bin/bash

# Source helper functions and variables
source ./helpers.sh

info "--- Starting Desktop Application Installation ---"

# --- Install using Package Manager (Idempotent) ---
info "Installing common applications..."
install_package vlc      # Needs RPM Fusion on Fedora / contrib/multiverse maybe?
install_package neovim
install_package micro

# --- Install using specific Repositories (Idempotent) ---

# Brave Browser
info "Setting up Brave Browser..."
if ! check_command brave-browser; then
	if [ "$DISTRO" == "fedora" ]; then
		if ! check_dnf_repo "brave-browser"; then
			info "Adding Brave repo (Fedora)..."
			sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
			sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
		else
			info "Brave repo (Fedora) already exists."
		fi
		install_package brave-browser
	elif [ "$DISTRO" == "debian" ]; then
		if ! check_apt_repo_source "brave-browser-apt-release"; then
			 info "Adding Brave repo (Debian/Ubuntu)..."
			 install_package apt-transport-https # Dependency check
			 sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
			 echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
			 $PKG_MANAGER update
		else
			info "Brave repo (Debian/Ubuntu) already exists."
		fi
		install_package brave-browser
	fi
else
	info "Brave Browser already installed. Skipping setup."
fi

# Sublime Text
info "Setting up Sublime Text..."
if ! check_command subl; then # Check for sublime command `subl`
	if [ "$DISTRO" == "fedora" ]; then
		if ! check_dnf_repo "sublime-text"; then
			 info "Adding Sublime Text repo (Fedora)..."
			 sudo rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
			 sudo dnf config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo
		else
			info "Sublime Text repo (Fedora) already exists."
		fi
		install_package sublime-text
	elif [ "$DISTRO" == "debian" ]; then
		if ! check_apt_repo_source "download.sublimetext.com"; then
			info "Adding Sublime Text repo (Debian/Ubuntu)..."
			install_package apt-transport-https # Dependency check
			wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null
			echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
			$PKG_MANAGER update
		else
			info "Sublime Text repo (Debian/Ubuntu) already exists."
		fi
		install_package sublime-text
	fi
else
	info "Sublime Text appears to be installed. Skipping setup."
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