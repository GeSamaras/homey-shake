#!/bin/bash

# Source helper functions and variables
source ./helpers.sh

info "--- Starting Development Tools Installation ---"

# --- Docker (Official Install Script Method - Idempotent) ---
info "Setting up Docker..."

if ! check_command docker; then
    info "Docker command not found. Proceeding with installation using official script..."

    DOCKER_SCRIPT_URL="https://get.docker.com"
    DOCKER_SCRIPT_FILE="get-docker.sh"
    # !!! IMPORTANT: Docker does not provide a stable official checksum for the get.docker.com script itself.
    # This checksum is based on a specific point in time and WILL likely change when Docker updates the script.
    # Running this script relies on trusting the source (get.docker.com) or manually verifying the script/checksum yourself.
    # You can get the current checksum by downloading the script and running `sha256sum get-docker.sh`
    EXPECTED_DOCKER_SCRIPT_CHECKSUM="PLACE_A_RECENT_VALID_SHA256_SUM_HERE_OR_REMOVE_CHECK" # e.g. "abcdef123..."
    VERIFY_CHECKSUM=true # Set to false to skip checksum verification if desired (less secure)

    if [ "$EXPECTED_DOCKER_SCRIPT_CHECKSUM" == "PLACE_A_RECENT_VALID_SHA256_SUM_HERE_OR_REMOVE_CHECK" ]; then
        warn "No valid checksum provided for Docker install script. Checksum verification will be skipped."
        VERIFY_CHECKSUM=false
    fi

    # Download the script
    info "Downloading Docker installation script from $DOCKER_SCRIPT_URL..."
    if curl -fsSL "$DOCKER_SCRIPT_URL" -o "$DOCKER_SCRIPT_FILE"; then
        info "Download successful."

        # Verify checksum if enabled
        if [ "$VERIFY_CHECKSUM" = true ]; then
            info "Verifying checksum for $DOCKER_SCRIPT_FILE..."
            ACTUAL_CHECKSUM=$(sha256sum "$DOCKER_SCRIPT_FILE" | awk '{print $1}')
            if [ "$ACTUAL_CHECKSUM" == "$EXPECTED_DOCKER_SCRIPT_CHECKSUM" ]; then
                info "Checksum valid."
            else
                error "CHECKSUM MISMATCH for $DOCKER_SCRIPT_FILE!"
                error "Expected: $EXPECTED_DOCKER_SCRIPT_CHECKSUM"
                error "Got:      $ACTUAL_CHECKSUM"
                error "The official Docker install script may have changed."
                error "Please update the EXPECTED_DOCKER_SCRIPT_CHECKSUM in the script or download/verify manually."
                rm "$DOCKER_SCRIPT_FILE"
                exit 1
            fi
        fi

        # Execute the script
        info "Executing Docker installation script..."
        # The script itself handles adding repos and installing packages
        if sudo sh "$DOCKER_SCRIPT_FILE"; then
             info "Docker installation script executed successfully."
        else
             error "Docker installation script failed."
             rm "$DOCKER_SCRIPT_FILE" # Clean up even on failure
             exit 1
        fi

        # Clean up the script
        rm "$DOCKER_SCRIPT_FILE"

    else
        error "Failed to download Docker installation script."
        exit 1
    fi

    # --- Post-installation steps --- (These remain mostly the same)
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
    # Check if systemctl is available first
    if check_command systemctl; then
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
    else
        warn "systemctl not found. Cannot manage Docker service automatically."
    fi

    # Verify docker compose plugin (installed by the script)
    if ! docker compose version &> /dev/null; then
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
    if check_command systemctl && ! systemctl is-active --quiet docker; then
        warn "Docker service is not active. You may need to start it ('sudo systemctl start docker')."
    fi
fi

# --- Virtualization (QEMU/KVM, libvirt, virt-manager) ---
info "Setting up Virtualization..."

if [ "$DISTRO" == "fedora" ]; then
    # Install the GUI manager tool
    install_package virt-manager

    # Install the core virtualization group packages
    # We'll check for libvirtd service as a proxy for the group being installed
    # but run the group install anyway to ensure all components are present/updated.
    info "Ensuring @virtualization group packages are installed..."
    if sudo dnf group install -y virtualization; then
        info "@virtualization group packages installed/verified successfully."
    else
        error "Failed during @virtualization group installation."
        # Consider exiting if this is critical: exit 1
    fi

    # Enable and start the libvirt daemon service
    LIBVIRT_SERVICE="libvirtd"
    if systemctl list-unit-files | grep -q "^${LIBVIRT_SERVICE}.service"; then
        if ! systemctl is-active --quiet "$LIBVIRT_SERVICE"; then
            info "Starting $LIBVIRT_SERVICE service..."
            sudo systemctl start "$LIBVIRT_SERVICE"
        else
            info "$LIBVIRT_SERVICE service is already active."
        fi
        if ! systemctl is-enabled --quiet "$LIBVIRT_SERVICE"; then
            info "Enabling $LIBVIRT_SERVICE service..."
            sudo systemctl enable "$LIBVIRT_SERVICE"
        else
            info "$LIBVIRT_SERVICE service is already enabled."
        fi
    else
        error "libvirtd.service not found. Virtualization setup may be incomplete."
    fi

    # Add user to the libvirt group for non-root VM management
    LIBVIRT_GROUP="libvirt"
    if ! id -nG "$USER" | grep -qw "$LIBVIRT_GROUP"; then
        info "Adding user $USER to the $LIBVIRT_GROUP group..."
        sudo usermod -aG "$LIBVIRT_GROUP" "$USER"
        if [ $? -eq 0 ]; then
             warn "User $USER added to $LIBVIRT_GROUP group. You MUST log out and log back in or reboot for this to take effect!"
        else
             error "Failed to add user $USER to $LIBVIRT_GROUP group."
        fi
    else
        info "User $USER is already in the $LIBVIRT_GROUP group."
    fi

elif [ "$DISTRO" == "debian" ]; then
    # Placeholder for Debian/Ubuntu KVM setup
    warn "QEMU/KVM/virt-manager automatic setup for Debian/Ubuntu is not implemented yet."
    # Steps would involve:
    # sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager -y
    # sudo adduser $USER libvirt
    # sudo adduser $USER libvirt-qemu # Often needed too
    # Check service: libvirtd
    # Check group: libvirt
fi

info "--- Virtualization Setup Complete ---"

# --- Python Development Tools ---
info "Setting up Python development tools..."

# Ensure pip3 command is available (should be installed by install_system.sh)
if ! check_command pip3; then
    error "pip3 command not found. Cannot install pip packages (like cookiecutter)."
    error "Ensure 'python3-pip' was installed successfully in the system stage."
else
    # Install Cookiecutter
    info "Checking/Installing cookiecutter..."
    # Check if the command exists as proxy for installation
    if ! check_command cookiecutter; then
         info "Attempting to install cookiecutter via pip..."
         # Use sudo to install system-wide for simplicity in this script context
         # Using 'pip3' explicitly is safer than just 'pip'
         if sudo pip3 install cookiecutter; then
             info "cookiecutter installed successfully."
         else
             error "Failed to install cookiecutter via pip."
             # Don't exit, just report error
         fi
    else
        info "cookiecutter command found. Assuming it is installed."
    fi
fi


info "--- Development Tools Installation Complete ---"