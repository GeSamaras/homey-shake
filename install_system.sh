#!/bin/bash

# Source helper functions and variables
source ./helpers.sh

info "--- Starting System Package Installation ---"

# Update package lists and upgrade existing packages (Run always if stage is selected)
info "Updating system packages..."
if $UPDATE_CMD; then
    info "System packages updated successfully."
else
    error "Failed to update system packages. Proceeding with caution..."
    # Decide if this should be fatal: exit 1
fi

# Install core utilities (Idempotent checks within install_package)
info "Installing core utilities..."
install_package curl
install_package wget
install_package unzip
install_package zsh
install_package tmux
install_package gnupg
install_package fzf
install_package keepassxc
install_package btop
install_package tldr
install_package yt-dlp
install_package python3-pip
install_package ffmpeg

# --- Distro-Specific Repo Setups ---
if [ "$DISTRO" == "fedora" ]; then
    info "Checking RPM Fusion repositories (Fedora)..."
    # Ensure dnf-plugins-core is installed for config-manager
    install_package "$PKG_PLUGIN_CORE"

    # RPM Fusion Free
    if ! check_package rpmfusion-free-release; then
        info "Adding RPM Fusion Free repository..."
        if $PKG_MANAGER install -y \
            https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm; then
            info "RPM Fusion Free repo added."
        else
            error "Failed to add RPM Fusion Free repo."
        fi
    else
        info "RPM Fusion Free repo already installed."
    fi

    # RPM Fusion Non-Free
    if ! check_package rpmfusion-nonfree-release; then
        info "Adding RPM Fusion Non-Free repository..."
        if $PKG_MANAGER install -y \
            https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm; then
            info "RPM Fusion Non-Free repo added."
        else
            error "Failed to add RPM Fusion Non-Free repo."
        fi
    else
        info "RPM Fusion Non-Free repo already installed."
    fi

    # Optional: Install AppStream metadata or multimedia group after repos are added
    # sudo dnf groupupdate core -y
    # sudo dnf groupupdate multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y
    # sudo dnf groupupdate sound-and-video -y

elif [ "$DISTRO" == "debian" ]; then
    info "Ensuring contrib and non-free repos are enabled (Debian/Ubuntu)..."
    warn "Automatic check/enable for contrib/non-free/multiverse not implemented."
    warn "Please ensure these are enabled manually in /etc/apt/sources.list if needed for specific packages (like Steam or codecs)."
fi

info "--- System Package Installation Complete ---"
