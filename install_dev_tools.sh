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
    step_info "Installing QEMU/KVM, libvirt, and virt-manager (Debian/Ubuntu)..."
    # Check if KVM can be used (CPU virtualization support)
    if ! egrep -c '(vmx|svm)' /proc/cpuinfo > /dev/null; then
        warn "CPU does not support KVM virtualization (vmx or svm flag not found). virt-manager might run, but KVM acceleration will not be available."
    else
        success "CPU supports KVM virtualization."
    fi

    install_package qemu-kvm
    install_package libvirt-daemon-system
    install_package libvirt-clients
    install_package bridge-utils
    install_package virt-manager

    # Enable and start the libvirt daemon service
    LIBVIRT_SERVICE="libvirtd" # libvirtd on Debian/Ubuntu too
    if command -v systemctl &> /dev/null; then # systemd is standard
        if systemctl list-unit-files | grep -q "^${LIBVIRT_SERVICE}.service"; then
            if ! systemctl is-active --quiet "$LIBVIRT_SERVICE"; then
                step_info "Starting $LIBVIRT_SERVICE service..."
                sudo systemctl start "$LIBVIRT_SERVICE"
            else
                step_info "$LIBVIRT_SERVICE service is already active."
            fi
            if ! systemctl is-enabled --quiet "$LIBVIRT_SERVICE"; then
                step_info "Enabling $LIBVIRT_SERVICE service..."
                sudo systemctl enable "$LIBVIRT_SERVICE"
            else
                step_info "$LIBVIRT_SERVICE service is already enabled."
            fi
        else
            error "$LIBVIRT_SERVICE.service not found. Virtualization setup may be incomplete."
        fi
    else
        warn "systemctl not found. Cannot manage $LIBVIRT_SERVICE automatically."
    fi


    # Add user to the libvirt and kvm groups
    LIBVIRT_GROUP="libvirt"
    KVM_GROUP="kvm" # KVM group is also common/needed on Debian/Ubuntu

    # Add to libvirt group
    if ! id -nG "$USER" | grep -qw "$LIBVIRT_GROUP"; then
        step_info "Adding user $USER to the $LIBVIRT_GROUP group..."
        sudo usermod -aG "$LIBVIRT_GROUP" "$USER"
        if [ $? -eq 0 ]; then
             warn "User $USER added to $LIBVIRT_GROUP group. You MUST log out and log back in or reboot!"
        else
             error "Failed to add user $USER to $LIBVIRT_GROUP group."
        fi
    else
        step_info "User $USER is already in the $LIBVIRT_GROUP group."
    fi

    # Add to kvm group (if it exists, some setups might not strictly need this if libvirt is set up for qemu:///system)
    if getent group "$KVM_GROUP" &>/dev/null; then
        if ! id -nG "$USER" | grep -qw "$KVM_GROUP"; then
            step_info "Adding user $USER to the $KVM_GROUP group..."
            sudo usermod -aG "$KVM_GROUP" "$USER"
            if [ $? -eq 0 ]; then
                warn "User $USER added to $KVM_GROUP group. You MUST log out and log back in or reboot!"
            else
                error "Failed to add user $USER to $KVM_GROUP group."
            fi
        else
            step_info "User $USER is already in the $KVM_GROUP group."
        fi
    else
        step_info "Group '$KVM_GROUP' does not exist. Skipping adding user to it."
    fi
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


# --- Golang Installation ---
step_info "Setting up Golang..."
GO_VERSION="1.24.3"
GO_INSTALL_DIR="/usr/local/go"
GO_TARBALL="go${GO_VERSION}.linux-amd64.tar.gz"
GO_URL="https://golang.org/dl/${GO_TARBALL}"

if ! check_command go || ! (go version 2>/dev/null | grep -q "go${GO_VERSION}"); then
    if check_directory "$GO_INSTALL_DIR"; then
        step_info "Found existing Go installation at $GO_INSTALL_DIR. Removing to install version $GO_VERSION..."
        sudo rm -rf "$GO_INSTALL_DIR" # Ensure clean install of specific version
    fi

    step_info "Downloading Go v${GO_VERSION}..."
    if curl -fsSL "$GO_URL" -o "/tmp/${GO_TARBALL}"; then
        step_info "Extracting Go to $GO_INSTALL_DIR..."
        sudo tar -C /usr/local -xzf "/tmp/${GO_TARBALL}"
        rm "/tmp/${GO_TARBALL}"

        # Add Go to PATH for all users (if not already there for /usr/local/go/bin)
        # This is often handled by default PATH including /usr/local/bin,
        # and /usr/local/go/bin should be in PATH or symlinked.
        # For immediate use in current shell (and for .bashrc/.zshrc hints):
        # export PATH=$PATH:/usr/local/go/bin
        # export GOPATH=$HOME/go
        # export PATH=$PATH:$GOPATH/bin

        if check_command go && (go version | grep -q "go${GO_VERSION}"); then
            success "Golang v${GO_VERSION} installed to $GO_INSTALL_DIR."
            warn "You may need to add ${BCyan}/usr/local/go/bin${Color_Off} to your PATH if not already present."
            warn "Consider setting ${BCyan}GOPATH${Color_Off} (e.g., export GOPATH=\$HOME/go) and adding ${BCyan}\$GOPATH/bin${Color_Off} to PATH in your shell config (.bashrc, .zshrc)."
        else
            error "Golang installation failed or version mismatch."
        fi
    else
        error "Failed to download Golang."
    fi
else
    step_info "Golang v${GO_VERSION} or newer already installed."
    go version
fi

# --- Node.js (via nvm) & TypeScript ---
step_info "Setting up Node.js (via nvm) and TypeScript..."
export NVM_DIR="$HOME/.nvm" # Set NVM_DIR explicitly

# Install nvm if not already installed
# Check for nvm command by trying to source its script
if ! ( [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && command -v nvm &>/dev/null ); then
    step_info "nvm not found. Installing nvm..."
    # Download and run nvm install script
    # Check for curl
    if check_command curl; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash # Check for latest nvm version
        # Source nvm script for current session
        if [ -s "$NVM_DIR/nvm.sh" ]; then
            # shellcheck source=/dev/null
            . "$NVM_DIR/nvm.sh"
            # shellcheck source=/dev/null
            . "$NVM_DIR/bash_completion"
            success "nvm installed. Please source your shell config (e.g., 'source ~/.bashrc') or open a new terminal."
        else
            error "nvm installation script ran, but nvm.sh not found in $NVM_DIR."
        fi
    else
        error "curl is required to install nvm. Please install curl."
    fi
else
    step_info "nvm is already installed."
    # Ensure nvm is sourced if script is re-run in same non-login shell
    if [ -s "$NVM_DIR/nvm.sh" ] && ! command -v nvm &>/dev/null; then
        # shellcheck source=/dev/null
        . "$NVM_DIR/nvm.sh"
    fi
fi

# Install Node.js LTS if nvm is available
if command -v nvm &> /dev/null; then
    # Check if any node version is installed, if not, install LTS
    if ! nvm list | grep -q "node"; then # A simple check
        step_info "No Node.js version found via nvm. Installing latest LTS..."
        if nvm install --lts; then
            nvm alias default 'lts/*' # Set LTS as default
            nvm use default
            success "Node.js LTS installed and set as default via nvm."
            node -v
            npm -v
        else
            error "Failed to install Node.js LTS via nvm."
        fi
    else
        step_info "Node.js appears to be installed via nvm. Current versions:"
        nvm current || echo " (no default alias set)"
        node -v || echo " (node not in current PATH)"
        npm -v || echo " (npm not in current PATH)"
    fi

    # Install TypeScript globally if Node/npm is available
    if command -v npm &> /dev/null; then
        if ! command -v tsc &> /dev/null; then
            step_info "Installing TypeScript globally via npm..."
            if sudo npm install -g typescript; then # Install globally for tsc command
                success "TypeScript installed globally."
                tsc --version
            else
                error "Failed to install TypeScript globally."
            fi
        else
            step_info "TypeScript (tsc) command found. Assuming it's installed."
            tsc --version
        fi
    else
        warn "npm not found. Cannot install TypeScript globally."
    fi
else
    warn "nvm command not available. Skipping Node.js and TypeScript installation via nvm."
fi

# --- Rust Installation (via rustup) ---
step_info "Setting up Rust..."
RUSTUP_CARGO_HOME="$HOME/.cargo" # Default rustup installation path

if ! check_command rustc || ! check_command cargo; then
    step_info "Rust (rustc/cargo) not found. Installing via rustup..."
    # Check for curl
    if check_command curl; then
        # Download and run rustup-init.sh non-interactively with default options
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
        # The --no-modify-path is used because we will source the env file next.
        # Alternatively, let it modify path and warn user to source.

        # Source cargo env for current session (rustup usually adds this to .profile or .bashrc/.zshrc)
        if [ -f "$RUSTUP_CARGO_HOME/env" ]; then
            # shellcheck source=/dev/null
            source "$RUSTUP_CARGO_HOME/env"
            success "Rust installed via rustup."
            rustc --version
            cargo --version
            warn "Rust environment sourced for current session. You may need to source ${BCyan}$RUSTUP_CARGO_HOME/env${Color_Off} or open a new terminal."
        else
            error "rustup installation script ran, but $RUSTUP_CARGO_HOME/env not found."
        fi
    else
        error "curl is required to install rustup. Please install curl."
    fi
else
    step_info "Rust (rustc/cargo) already installed."
    rustc --version
    cargo --version
fi


info "--- Development Tools Installation Complete ---"