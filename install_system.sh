#!/bin/bash

# Source helper functions and variables
source ./helpers.sh

info "--- Starting System Package Installation ---"

# Update package lists and upgrade existing packages
info "Updating system packages..."
if $UPDATE_CMD; then
  info "System packages updated successfully."
else
  error "Failed to update system packages."
  exit 1
fi

# Install core utilities
info "Installing core utilities (git, curl, wget, unzip, zsh, tmux, gpg)..."
install_package git
install_package curl
install_package wget
install_package unzip
install_package zsh
install_package tmux
install_package gnupg # Often gpg or gnupg2 depending on distro

# Install fzf (Fuzzy Finder)
install_package fzf

# Install OpenVPN & NetworkManager integration
info "Installing OpenVPN..."
if [ "$DISTRO" == "fedora" ]; then
    install_package openvpn
    install_package NetworkManager-openvpn-gnome # Provides GUI integration
elif [ "$DISTRO" == "debian" ]; then
    install_package openvpn
    install_package network-manager-openvpn-gnome # Check exact name for KDE if needed
fi

# Install KeePassXC Password Manager
info "Installing KeePassXC..."
install_package keepassxc

# --- Distro-Specific Repo Setups ---

if [ "$DISTRO" == "fedora" ]; then
  info "Setting up RPM Fusion repositories (Fedora)..."
  # Check if already installed might be good here
  if ! rpm -q rpmfusion-free-release &>/dev/null; then
      $PKG_MANAGER install -y \
        https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
      info "RPM Fusion Free repo added."
  else
      info "RPM Fusion Free repo already installed."
  fi
  if ! rpm -q rpmfusion-nonfree-release &>/dev/null; then
      $PKG_MANAGER install -y \
        https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
      info "RPM Fusion Non-Free repo added."
  else
      info "RPM Fusion Non-Free repo already installed."
  fi
  # Install tools needed for codecs later maybe? (dnf groupupdate multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin) - Keep simple for now.
  # Install AppStream metadata for PackageKit
  sudo dnf groupupdate core -y

elif [ "$DISTRO" == "debian" ]; then
  info "Ensuring contrib and non-free repos are enabled (Debian/Ubuntu)..."
  # This often requires manual editing of /etc/apt/sources.list or adding files
  # Installing ubuntu-restricted-extras might cover some multimedia needs on Ubuntu.
  warn "Please ensure 'contrib' and 'non-free' (Debian) or 'multiverse'/'restricted' (Ubuntu) repos are enabled for full multimedia/driver support."
fi

info "--- System Package Installation Complete ---"