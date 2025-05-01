#!/bin/bash

# Source helper functions
source ./helpers.sh

info "--- Setting up Docker Directories and Compose Files ---"

# Define the base directory for Docker configurations
DOCKER_BASE_DIR="$HOME/homelab-docker"
TEMPLATE_DIR="./docker-compose-templates"

# List of services to set up (directories in the template folder)
services="jellyfin-stack navidrome immich homeassistant" # Update this list

# Check if template directory exists
if [ ! -d "$TEMPLATE_DIR" ]; then
    error "Template directory '$TEMPLATE_DIR' not found. Cannot set up Docker directories."
    exit 1
fi

info "Ensuring base Docker directory exists: $DOCKER_BASE_DIR"
mkdir -p "$DOCKER_BASE_DIR"

# Copy template files for specified services
for service in $services; do
    source_path="$TEMPLATE_DIR/$service"
    dest_path="$DOCKER_BASE_DIR/$service"

    if [ -d "$source_path" ]; then
        # Only proceed if destination doesn't exist or is empty, to be less destructive
        # Or use `cp -n` to avoid overwriting existing files
        if [ ! -d "$dest_path" ] || [ -z "$(ls -A "$dest_path")" ]; then
             info "Setting up directory and copying templates for $service at $dest_path"
             mkdir -p "$dest_path"
             cp -R "$source_path"/* "$dest_path/" # Copy contents recursively
             info "Copied configuration template for $service."
             warn "IMPORTANT: Review and customize '$dest_path/docker-compose.yml' before running 'docker compose up -d'."
        else
            info "Directory $dest_path for service $service already exists and is not empty. Skipping copy."
            warn "Review contents of $dest_path manually."
        fi
    else
        warn "Template directory '$source_path' for service $service not found. Skipping."
    fi
done

info "--- Docker Directory Setup Complete ---"
info "Navigate to subdirectories within $DOCKER_BASE_DIR, customize the docker-compose.yml files,"
info "and run 'docker compose up -d' to start the services."