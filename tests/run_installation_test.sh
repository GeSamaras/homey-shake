#!/bin/bash
set -e

SETUP_FLAG="$1"

# shellcheck source=../helpers.sh
source "$(dirname "$0")/../helpers.sh"

info "=== Starting Installation Test for stage: $SETUP_FLAG on Ubuntu ==="

cd "$(dirname "$0")/.."
chmod +x *.sh

info "Running: ./setup.sh $SETUP_FLAG -y"
if ! ./setup.sh "$SETUP_FLAG" -y; then
    error "Homey-shake setup script failed for stage $SETUP_FLAG"
    exit 1
fi

if [[ "$SETUP_FLAG" == *"--system"* ]] || [[ "$SETUP_FLAG" == *"--all"* ]]; then
    info "--- Verifying System Tools ---"
    check_command git || (error "git not found" && exit 1)
    check_command zsh || (error "zsh not found" && exit 1)
    check_command tmux || (error "tmux not found" && exit 1)
    check_command fzf || (error "fzf not found" && exit 1)
    check_command btop || (error "btop not found" && exit 1)
    check_command tldr || (error "tldr not found" && exit 1)
    check_command yt-dlp || (error "yt-dlp not found" && exit 1)
    check_command ffmpeg || (error "ffmpeg not found" && exit 1)
    check_command pip3 || (error "pip3 not found" && exit 1)
    info "System tool checks passed."
fi

if [[ "$SETUP_FLAG" == *"--apps"* ]] || [[ "$SETUP_FLAG" == *"--all"* ]]; then
    info "--- Verifying App Tools ---"
    check_command flatpak || (error "flatpak not found" && exit 1)
    if ! flatpak remote-list | grep -q '^flathub\s'; then error "Flathub remote not found" && exit 1; fi
    check_flatpak_app com.brave.Browser || (error "Brave (Flatpak) not found" && exit 1)
    check_flatpak_app io.github.zyedidia.micro || (error "Micro (Flatpak) not found" && exit 1)
    check_flatpak_app org.gimp.GIMP || (error "GIMP (Flatpak) not found" && exit 1)
    check_flatpak_app com.obsproject.Studio || (error "OBS (Flatpak) not found" && exit 1)
    check_command qbittorrent || (error "qbittorrent not found" && exit 1)
    # TODO: Might difficult to verify full suite easily, could see a workaround or remove it. 
    check_command libreoffice || (error "libreoffice command not found" && exit 1)
    info "App tool checks passed."
fi

if [[ "$SETUP_FLAG" == *"--dev"* ]] || [[ "$SETUP_FLAG" == *"--all"* ]]; then
    info "--- Verifying Dev Tools ---"
    check_command docker || (error "docker command not found" && exit 1)
    docker --version
    if ! docker compose version &> /dev/null; then error "docker compose not found" && exit 1; fi

    if command -v systemctl &> /dev/null && systemctl is-active --quiet docker; then
        info "Docker service is active."
    elif command -v systemctl &> /dev/null; then
        warn "Docker service not immediately active. Attempting to start..."
        sudo systemctl start docker
        sleep 5 # Give it a moment
        if ! systemctl is-active --quiet docker; then error "Docker service failed to start." && exit 1; fi
        info "Docker service started."
    else
        warn "Cannot check docker service status (no systemctl or alternative)."
    fi

    info "Attempting to run docker hello-world..."
    if ! docker run hello-world; then
        error "docker run hello-world FAILED. Trying with sudo..."
        if ! sudo docker run hello-world; then
            error "sudo docker run hello-world ALSO FAILED. Core Docker issue." && exit 1
        fi
        warn "docker run hello-world required sudo. User permission setup might need re-login on real desktop."
    fi
    info "Docker hello-world ran."

    check_command virt-manager || (error "virt-manager not found" && exit 1)
    # Check libvirtd service
    LIBVIRT_SERVICE="libvirtd"
    if command -v systemctl &> /dev/null && systemctl is-active --quiet "$LIBVIRT_SERVICE"; then
        info "$LIBVIRT_SERVICE service is active."
    elif command -v systemctl &> /dev/null; then
        warn "$LIBVIRT_SERVICE service not immediately active. Attempting to start..."
        sudo systemctl start "$LIBVIRT_SERVICE"
        sleep 3
        if ! systemctl is-active --quiet "$LIBVIRT_SERVICE"; then error "$LIBVIRT_SERVICE service failed to start." && exit 1; fi
        info "$LIBVIRT_SERVICE service started."
    else
        warn "Cannot check $LIBVIRT_SERVICE status (no systemctl or alternative)."
    fi

    check_command cookiecutter || (error "cookiecutter not found" && exit 1)
    info "Dev tool checks passed."
fi

info "=== Installation Test for stage: $SETUP_FLAG PASSED ==="
exit 0