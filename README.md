# homey-shake


This repo helps you quickly set up a fresh Linux install (Fedora KDE and Mint tested) for development, media, and homelab tinkering. It uses a mix of bash scripts and Docker to get everything installed and configured.
---
## How it Works:
You'll clone this repo, run a main script, and it'll handle installing system packages, desktop apps, development tools, and setting up Docker containers via Docker Compose.
Prerequisites
Fresh Fedora KDE Install: This is designed for a clean slate. While it might work on an existing system, it's untested and could overwrite things.
Internet Connection: The scripts need to download packages, installers, and container images.
`sudo` privileges: The scripts need root access to install software.
How to Use
---
# DISCLAIMER!
This is meant for personal use. Be cautious when running scripts unless you trust and understand them!
First read the scripts and how they work, and test it on a virtual machine before running on your local computer.
---
## Clone the Repo:
```bash
    # First, make sure git is installed (it might be already)
    sudo dnf install -y git
    git clone https://github.com/GeSamaras/homey-shake ~/homelab-setup
    cd ~/homelab-setup
```
## Review the Scripts (RECOMMENDED!):
Take a good look at setup.sh and any sub-scripts (like install_system.sh, install_apps.sh, setup_docker.sh) to see what they'll do. Never run scripts you don't trust!
## Make Scripts Executable:
```bash
    chmod +x setup.sh *.sh
```
Use code with caution.
## Run the Main Setup Script:
```bash
    ./setup.sh
```
Follow on-screen prompts. Some installations (like Miniconda or Oh My Zsh) might ask for confirmation. You'll likely need to enter your sudo password.
Reboot or Re-login: After the script finishes, reboot or log out and back in. This is crucial for changes like adding your user to the docker group to take effect.
What Gets Installed
Here's the rundown:
1. Core System & Utilities:
- DNF Updates: Ensures your base system is up-to-date.
- RPM Fusion Repos: Enables access to packages like VLC, Steam, and multimedia codecs (Free and Non-Free).
- Git: Essential version control.
- Zsh: An improved shell.
- Oh My Zsh: Framework for managing Zsh configuration (installs Zsh if needed).
- fzf: Command-line fuzzy finder.
- tmux: Terminal multiplexer.
- GnuPG (gpg): For encryption and signing.
- OpenVPN: VPN client (with NetworkManager integration).
- Curl, Wget, Unzip: Common download/utility tools.
- Password Manager: We'll install KeePassXC by default (dnf install keepassxc). You can swap this in the script if you prefer another (like Bitwarden via Flatpak/AppImage).
2. Desktop Apps:
VLC: Media player (via RPM Fusion).
Discord: Communication (via Flatpak).
Brave Browser: Web browser (via Brave's official repo).
Sublime Text: Text editor (via Sublime's official repo).
Neovim: Vim-based text editor (via dnf).
Micro: Terminal-based text editor (via dnf).
Steam: Gaming platform (via RPM Fusion or Flatpak - script will likely use RPM Fusion).
Moonlight: Game streaming client (likely via Flatpak).
Obsidian: Note-taking app (likely via Flatpak).
3. Development & Containerization:
Docker:
Docker Engine
Docker CLI
Docker Compose (v2+)
(Installs Docker Desktop for Linux, which bundles these)
Adds your user to the docker group (requires re-login!).
Python (via Miniconda):
Installs Miniconda for managing Python environments. You'll likely need to run conda init or manually configure your shell after install if the script doesn't do it automatically.
Bun: Fast JavaScript runtime/bundler/package manager (via official install script).
4. Docker Containers / Stacks (via Docker Compose):
Location: Compose files (docker-compose.yml) and configurations will be placed in ~/homelab-docker/ by default.
Setup: The script will copy the template docker-compose.yml files. It will NOT automatically start them. You need to:
Navigate to the specific service directory (e.g., cd ~/homelab-docker/jellyfin-stack).
Review and customize the docker-compose.yml file (check ports, volumes, environment variables). You might need to create .env files for secrets.
Run docker compose up -d to start the stack in the background.
Containers Planned:
Jellyfin Stack: (in ~/homelab-docker/jellyfin-stack/)
Jellyfin (Media Server)
Sonarr (TV Show PVR)
Radarr (Movie PVR)
Torrent Client (e.g., qBittorrent)
Jellyseerr (Media Requests)
Jackett / Prowlarr (Indexer Proxy)
ComfyUI: (in ~/homelab-docker/comfyui/) - AI Image Generation UI. Note: GPU passthrough might require installing NVIDIA Container Toolkit separately.
Navidrome: (in ~/homelab-docker/navidrome/) - Music Streaming Server.
Open Source Google Photos Alternative: (e.g., Immich, in ~/homelab-docker/immich/) - Self-hosted photos. Note: Immich has multiple components.
Home Assistant: (in ~/homelab-docker/homeassistant/) - Home automation platform.
Kali Linux: (in ~/homelab-docker/kali/ or just provide docker run command) - Penetration testing distro.
Safe Browser: (e.g., using jlesage/firefox, in ~/homelab-docker/safe-browser/) - Isolated browser instance. Need to pick a specific image.
ELK Stack: (in ~/homelab-docker/elk/) - Elasticsearch, Logstash, Kibana for log analysis. Resource intensive!
Wazuh: (in ~/homelab-docker/wazuh/) - Security monitoring (SIEM/XDR). Complex, follow their official Docker guide.
deep-seekV3: Needs clarification. Is this run via Ollama or another framework? Add Ollama container? (e.g., ~/homelab-docker/ollama/)
SIERRA: Needs clarification. What tool is this? Find its Docker image/compose setup. (e.g., ~/homelab-docker/sierra/)