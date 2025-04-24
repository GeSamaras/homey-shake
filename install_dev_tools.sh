#!/bin/bash

# Source helper functions and variables
source ./helpers.sh

info "--- Starting Development Tools Installation ---"

# --- Docker ---
info "Installing Docker Engine, CLI, and Compose..."
if ! command -v docker &> /dev/null; then
    # Use the official convenience script
    if command -v curl &> /dev/null; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        rm get-docker.sh
        info "Docker installation script executed."
    else
        error "curl is required to download the Docker installation script."
        # Consider adding a wget alternative if needed
    fi

    # Add user to the docker group
    if id -nG "$USER" | grep -qw docker; then
        info "User $USER already in docker group."
    else
        info "Adding user $USER to the docker group..."
        sudo usermod -aG docker $USER
        warn "You MUST log out and log back in or reboot for Docker group changes to take effect!"
    fi

    # Enable and start Docker service
    info "Enabling and starting Docker service..."
    sudo systemctl enable docker --now
    info "Docker service enabled and started."

else
    info "Docker appears to be already installed."
fi

# Verify Docker Compose (v2 plugin) installation
if ! docker compose version &> /dev/null; then
    warn "Docker Compose v2 command not found. It should be installed as part of Docker Engine now."
    warn "Please check Docker installation or install docker-compose-plugin manually if needed."
    # Fedora: sudo dnf install docker-compose-plugin
    # Debian: sudo apt-get install docker-compose-plugin
else
    info "Docker Compose v2 verified."
fi


# --- Miniconda ---
info "Installing Miniconda..."
if [ ! -d "$HOME/miniconda3" ]; then
    # Download the latest Miniconda3 installer for Linux 64-bit
    MINICONDA_INSTALLER="Miniconda3-latest-Linux-x86_64.sh"
    info "Downloading Miniconda installer..."
    if command -v curl &> /dev/null; then
        curl -fsSL https://repo.anaconda.com/miniconda/$MINICONDA_INSTALLER -o "$MINICONDA_INSTALLER"
    elif command -v wget &> /dev/null; then
        wget https://repo.anaconda.com/miniconda/$MINICONDA_INSTALLER
    else
        error "Cannot download Miniconda installer. Curl or Wget not found."
        exit 1 # Or handle more gracefully
    fi

    # Run the installer in batch mode (-b), specify install path (-p)
    info "Running Miniconda installer..."
    bash "$MINICONDA_INSTALLER" -b -p "$HOME/miniconda3"

    # Clean up installer
    rm "$MINICONDA_INSTALLER"

    # Initialize conda for the current shell (might need adjustment for zsh vs bash)
    # This adds setup to .bashrc or .zshrc but requires a new shell to take effect
    info "Initializing Miniconda..."
    eval "$($HOME/miniconda3/bin/conda shell.bash hook)" # Attempt to make conda available immediately in bash
    # Attempt initialization for common shells
    if [ -f "$HOME/miniconda3/bin/conda" ]; then
         "$HOME/miniconda3/bin/conda" init bash
         "$HOME/miniconda3/bin/conda" init zsh
         info "Miniconda initialized for bash and zsh. Please restart your shell or source your config file."
    else
         error "Could not find conda executable to run init."
    fi

    info "Miniconda installed to $HOME/miniconda3."
    warn "You need to restart your shell or run 'source ~/.bashrc' or 'source ~/.zshrc' for conda commands to be available."
else
    info "Miniconda directory $HOME/miniconda3 already exists. Skipping installation."
fi

# --- Bun ---
info "Installing Bun..."
if ! command -v bun &> /dev/null; then
    if command -v curl &> /dev/null; then
        curl -fsSL https://bun.sh/install | bash
        # Add bun to PATH for the current session if possible (installation script might do this)
        export PATH="$HOME/.bun/bin:$PATH"
        info "Bun installed. Added to PATH for current session."
        warn "You might need to add $HOME/.bun/bin to your shell's PATH manually in .bashrc or .zshrc if it's not already done."
    else
        error "curl is required to install Bun."
    fi
else
    info "Bun already installed."
fi


info "--- Development Tools Installation Complete ---"