#!/bin/bash

# --- Main Setup Script for Fedora KDE Homelab ---

# Ensure the script exits if any command fails
set -e

# Source helper functions (especially for initial messages)
source ./helpers.sh

info "Starting Homelab Setup Process..."
info "This script will install system packages, desktop apps, development tools, and set up Docker configurations."
info "Please read through the README.md for more information." 
warn "Ensure you have a stable internet connection and sudo privileges."
warn "As of now, this is intended for a FRESH Fedora KDE install. Run on an virtual machine first of all."
warn "Proceed with caution!"

# Quick check before initializing the scripts.
read -p "Do you want to proceed with the setup? (y/N): " confirm
if [[ ! "$confirm" =~ ^[yY](es)?$ ]]; then
    info "Setup cancelled by user."
    exit 0
fi

# --- Run Installation Stages ---

info "Running: System Package Installation"
bash ./install_system.sh

info "Running: Desktop Application Installation"
bash ./install_apps.sh

info "Running: Development Tools Installation"
bash ./install_dev_tools.sh

info "Running: Docker Directory and Compose File Setup"
bash ./setup_docker_dirs.sh

# --- Final Instructions ---

info "--- Homelab Setup Script Finished ---"
warn "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
warn "!!! IMPORTANT: You MUST reboot or log out and log back in                  !!!"
warn "!!! for all changes (especially Docker group membership) to take effect.   !!!"
warn "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
warn "After logging back in:"
warn " - Review and customize docker-compose.yml files in ~/homelab-docker/*/"
warn " - Run 'docker compose up -d' in each service directory to start containers."
warn " - You might need to run 'conda init' or source ~/.bashrc / ~/.zshrc for Conda."
warn " - Oh My Zsh might require you to type 'zsh' or set it as default shell ('chsh -s $(which zsh)')."
warn " - For GPU usage in Docker (e.g., ComfyUI), install NVIDIA drivers and nvidia-container-toolkit manually."

exit 0