#!/bin/bash

# --- Helper Functions ---

# Function to print messages
info() { echo "INFO: $1"; }
warn() { echo "WARN: $1"; }
error() { echo "ERROR: $1" >&2; }

# Detect package manager and set command variables
# The way this function works is to populate variables with
# their respective OS CLI commands. It's gonna check which
# package manager in available in the machine, and from there
# determine the appropriate commands to be run.

detect_package_manager() {
    if command -v dnf &> /dev/null; then
        info "Detected dnf package manager (Fedora/RHEL-based)."
        PKG_MANAGER="sudo dnf" # Prefix to run install commands
        UPDATE_CMD="$PKG_MANAGER update -y"
        INSTALL_CMD="$PKG_MANAGER install -y"
        CHECK_PKG_CMD="rpm -q" # Command to check if a package is installed
        REPO_QUERY_CMD="dnf repolist enabled" # Command to list enabled repos
        PKG_PLUGIN_CORE="dnf-plugins-core" # Package providing repo management commands
        DISTRO="fedora"
    elif command -v apt-get &> /dev/null; then
        info "Detected apt package manager (Debian/Ubuntu-based)."
        PKG_MANAGER="sudo apt-get"
        UPDATE_CMD="$PKG_MANAGER update && $PKG_MANAGER upgrade -y"
        INSTALL_CMD="$PKG_MANAGER install -y"
        CHECK_PKG_CMD="dpkg -s" # Command to check if a package is installed
        REPO_QUERY_CMD="grep -R --include=\*.list ^deb /etc/apt/sources.list /etc/apt/sources.list.d/" # Command to check repo sources
        PKG_PLUGIN_CORE="software-properties-common" # Provides add-apt-repository, often installed
        DISTRO="debian"
    else
        error "Unsupported package manager. Exiting."
        exit 1
    fi
}

# Function to check if a command exists
check_command() {
    command -v "$1" &> /dev/null
}

# Function to check if a package is installed
check_package() {
    local pkg_name="$1"
    # Need to adjust check command syntax slightly based on manager
    if [ "$DISTRO" == "fedora" ]; then
        $CHECK_PKG_CMD "$pkg_name" &> /dev/null
    elif [ "$DISTRO" == "debian" ]; then
        $CHECK_PKG_CMD "$pkg_name" 2>/dev/null | grep -q '^Status: install ok installed'
    else
        return 1 # Unknown distro
    fi
}

# Function to install packages idempotently, aiming to avoid repetition.
# This will be called by other scripts, filled in with the packaged to be installed,
# and then proceed with either installing or skipping.
install_package() {
    local package_name="$1"
    info "Checking package: $package_name..."
    if check_package "$package_name"; then
        info "$package_name is already installed. Skipping."
    else
        info "Attempting to install $package_name..."
        if $INSTALL_CMD "$package_name"; then
            info "$package_name installed successfully."
        else
            error "Failed to install $package_name."
            # Optionally exit here: exit 1
            return 1 # Indicate failure
        fi
    fi
    return 0 # Indicate success or already installed
}

check_directory() {
    [ -d "$1" ]
}

check_file() {
    [ -f "$1" ]
}

# Check if a DNF repo is enabled (Fedora)
check_dnf_repo() {
    local repo_id="$1"
    $REPO_QUERY_CMD | grep -q "^$repo_id\s"
}

# If an Apt repo source exists
check_apt_repo_source() {
    local source_pattern="$1" # e.g., download.docker.com
    $REPO_QUERY_CMD | grep -q "$source_pattern"
}

# Function to check if a Flatpak remote exists
check_flatpak_remote() {
    local remote_name="$1"
    flatpak remote-list | grep -q "^$remote_name\s"
}

# Function to check if a Flatpak app is installed
check_flatpak_app() {
    local app_id="$1"
    flatpak info "$app_id" &> /dev/null
}

# Function to install flatpak packages idempotently
install_flatpak_package() {
    local app_id="$1"
    info "Checking Flatpak package: $app_id..."
    if check_flatpak_app "$app_id"; then
        info "Flatpak: $app_id already installed. Skipping."
    else
        info "Attempting to install Flatpak package $app_id..."
        if flatpak install flathub -y "$app_id"; then
            info "Flatpak: $app_id installed successfully."
        else
            error "Failed to install Flatpak: $app_id."
            return 1
        fi
    fi
    return 0
}

# --- Initial Setup ---
detect_package_manager

# Ensure script exits on first error (can be overridden by checks)
# set -e # Removing this for now, as checks should handle failures gracefully. Add back if preferred.
