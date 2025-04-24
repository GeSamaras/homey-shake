#!/bin/bash

# Source helper functions
source ./helpers.sh

info "--- Setting up Docker Directories and Compose Files ---"

# Define the base directory for Docker configurations
DOCKER_BASE_DIR="$HOME/homelab-docker"
TEMPLATE_DIR="./docker-compose-templates"

info "Creating base Docker directory: $DOCKER_BASE_DIR"
mkdir -p "$DOCKER_BASE_DIR"

# List of services (directories in the template folder)
# Exclude files like READMEs if necessary
services=$(find "$TEMPLATE_DIR" -maxdepth 1 -mindepth 1 -type d -printf '%f\n')

# Copy template files
for service in $services; do
    source_path="$TEMPLATE_DIR/$service"
    dest_path="$DOCKER_BASE_DIR/$service"

    if [ -d "$source_path" ]; then
        info "Setting up directory for $service at $dest_path"
        mkdir -p "$dest_path"

        info "Copying files from $source_path to $dest_path"
        # Use cp -n to avoid overwriting existing user changes if script is re-run
        cp -Rn "$source_path"/* "$dest_path/"

        # Create common subdirectories if they don't exist (optional, compose usually handles this)
        # mkdir -p "$dest_path/config"
        # mkdir -p "$dest_path/data"

        # Add placeholder .env file if one doesn't exist? Might be too intrusive.
        # touch "$dest_path/.env" # Example placeholder

        info "Copied configuration template for $service."
        warn "IMPORTANT: Review and customize '$dest_path/docker-compose.yml' and any '.env' files before running 'docker compose up -d' in that directory."
    fi
done

# Special handling for services without compose files (like Kali)
kali_readme="$TEMPLATE_DIR/kali/README.md"
kali_dest_dir="$DOCKER_BASE_DIR/kali"
if [ -f "$kali_readme" ]; then
    mkdir -p "$kali_dest_dir"
    cp "$kali_readme" "$kali_dest_dir/"
    info "Copied instructions for Kali Linux to $kali_dest_dir."
fi

sierra_readme="$TEMPLATE_DIR/sierra/README.md"
sierra_dest_dir="$DOCKER_BASE_DIR/sierra"
if [ -f "$sierra_readme" ]; then
    mkdir -p "$sierra_dest_dir"
    cp "$sierra_readme" "$sierra_dest_dir/"
    info "Copied placeholder/instructions for SIERRA to $sierra_dest_dir."
fi


info "--- Docker Directory Setup Complete ---"
info "Navigate to subdirectories within $DOCKER_BASE_DIR, customize the docker-compose.yml files,"
info "and run 'docker compose up -d' to start the services."