#!/bin/bash

# Source helper functions and variables
source ./helpers.sh

info "--- Starting Development Tools Installation ---"

# --- Docker (Official Repo Method - Idempotent) ---
info "Setting up Docker..."

if ! check_command docker; then
    info "Docker command not found. Proceeding with installation..."

    if [ "$DISTRO" == "fedora" ]; then
        # Ensure dnf-plugins-core is installed
        install_package "$PKG_PLUGIN_CORE"

        # Add Docker repository if not already added
        if ! check_dnf_repo "docker-ce-stable"; then
            info "Adding Docker CE repository (Fedora)..."
            sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
        else
            info "Docker CE repository (Fedora) already exists."
        fi

        # Install Docker packages
        info "Installing Docker packages (Fedora)..."
        install_package docker-ce
        install_package docker-ce-cli
        install_package containerd.io
        install_package docker-buildx-plugin
        install_package docker-compose-plugin # Docker Compose V2

    elif [ "$DISTRO" == "debian" ]; then
        # Install prerequisites
        info "Installing Docker prerequisites (Debian/Ubuntu)..."
        install_package ca-certificates
        install_package curl
        install_package gnupg
        install_package lsb-release # If not present

        # Add Docker GPG key if not already added
        DOCKER_GPG_KEYRING="/etc/apt/keyrings/docker.gpg"
        if [ ! -f "$DOCKER_GPG_KEYRING" ]; then
             info "Adding Docker GPG key..."
             sudo install -m 0755 -d /etc/apt/keyrings
             curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o "$DOCKER_GPG_KEYRING"
             sudo chmod a+r "$DOCKER_GPG_KEYRING" # Ensure readable
        else
            info "Docker GPG key already exists."
        fi

        # Add Docker repository if not already added
        DOCKER_APT_SOURCE="/etc/apt/sources.list.d/docker.list"
         if [ ! -f "$DOCKER_APT_SOURCE" ]; then
            info "Adding Docker APT repository..."
            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=$DOCKER_GPG_KEYRING] https://download.docker.com/linux/debian \
              $(lsb_release -cs) stable" | sudo tee "$DOCKER_APT_SOURCE" > /dev/null
            $PKG_MANAGER update # Update list after adding repo
         else
            info "Docker APT repository already exists."
         fi

        # Install Docker packages
        info "Installing Docker packages (Debian/Ubuntu)..."
        install_package docker-ce
        install_package docker-ce-cli
        install_package containerd.io
        install_package docker-buildx-plugin
        install_package docker-compose-plugin # Docker Compose V2
    fi

    # Post-installation steps (Run only if Docker was installed or not enabled/running)
    info "Performing Docker post-installation steps..."

    # Add user to the docker group if not already a member
    if ! id -nG "$USER" | grep -qw docker; then
        info "Adding user $USER to the docker group..."
        sudo usermod -aG docker $USER
        if [ $? -eq 0 ]; then
             warn "User $USER added to docker group. You MUST log out and log back in or reboot for this to take effect!"
        else
             error "Failed to add user $USER to docker group."
        fi
    else
        info "User $USER is already in the docker group."
    fi

    # Enable and start Docker service if not already active/enabled
    if ! systemctl is-active --quiet docker; then
        info "Starting Docker service..."
        sudo systemctl start docker
    else
        info "Docker service is already active."
    fi
     if ! systemctl is-enabled --quiet docker; then
        info "Enabling Docker service to start on boot..."
        sudo systemctl enable docker
    else
        info "Docker service is already enabled."
    fi

    # Verify docker compose plugin
    if ! check_command docker-compose && ! docker compose version &> /dev/null; then
         warn "Docker Compose command verification failed. Please check installation."
    else
         info "Docker Compose command verified."
    fi

else
    info "Docker command detected. Assuming Docker is installed and configured."
    # Optional: Still check group membership and service status here if desired
    if ! id -nG "$USER" | grep -qw docker; then
         warn "User $USER is not in the docker group. You may need to add manually ('sudo usermod -aG docker $USER') and re-login."
    fi
     if ! systemctl is-active --quiet docker; then
        warn "Docker service is not active. You may need to start it ('sudo systemctl start docker')."
    fi
fi


# --- Removed Miniconda & Bun ---
info "Skipping Miniconda and Bun installation as they were removed from scope."


info "--- Development Tools Installation Complete ---"