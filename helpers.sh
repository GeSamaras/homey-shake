#!/bin/bash

# --- Helper Functions ---

# Function to print messages
info() {
  echo "INFO: $1"
}

warn() {
  echo "WARN: $1"
}

error() {
  echo "ERROR: $1" >&2
}

# Detect package manager and set command variable
detect_package_manager() {
  if command -v dnf &> /dev/null; then
    info "Detected dnf package manager (Fedora/RHEL-based)."
    PKG_MANAGER="sudo dnf"
    UPDATE_CMD="$PKG_MANAGER update -y"
    INSTALL_CMD="$PKG_MANAGER install -y"
    ADD_REPO_CMD="$PKG_MANAGER config-manager --add-repo" # Specific to dnf
    DISTRO="fedora"
  elif command -v apt &> /dev/null; then
    info "Detected apt package manager (Debian/Ubuntu-based)."
    PKG_MANAGER="sudo apt-get" # Use apt-get for scripting consistency
    UPDATE_CMD="$PKG_MANAGER update && $PKG_MANAGER upgrade -y"
    INSTALL_CMD="$PKG_MANAGER install -y"
    # Adding repos varies greatly on apt, handled case-by-case
    DISTRO="debian"
  else
    error "Unsupported package manager. Exiting."
    exit 1
  fi
}

# Function to install packages with status feedback
install_package() {
  local package_name="$1"
  info "Attempting to install $package_name..."
  if $INSTALL_CMD "$package_name"; then
    info "$package_name installed successfully."
  else
    error "Failed to install $package_name."
    # Optionally exit here: exit 1
  fi
}

# Function to install flatpak packages
install_flatpak_package() {
    local app_id="$1"
    info "Attempting to install Flatpak package $app_id..."
    if flatpak install flathub -y "$app_id"; then
        info "Flatpak: $app_id installed successfully."
    else
        error "Failed to install Flatpak: $app_id."
    fi
}

# --- Initial Setup ---
detect_package_manager

# Ensure script exits on first error
set -e