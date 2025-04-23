# homey-shake

This repo helps you quickly set up a fresh Linux install (Fedora KDE and Mint tested) for development, media, and homelab tinkering. It uses a mix of bash scripts and Docker to get everything installed and configured.

---
## How it Works:

You'll clone this repo, run a main script, and it'll handle installing system packages, desktop apps, development tools, and setting up Docker containers via Docker Compose.

---
### Prerequisites

Fresh Fedora KDE Install: This is designed for a clean slate. While it might work on an existing system, it's untested and could overwrite things.
Internet Connection: The scripts need to download packages, installers, and container images.
`sudo` privileges: The scripts need root access to install software.

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

Follow on-screen prompts when asked. Some installations (like Miniconda or Oh My Zsh) might ask for confirmation. You'll likely need to enter your sudo password.

Reboot or Re-login: After the script finishes, reboot or log out and back in. This is crucial for changes like adding your user to the docker group to take effect.

---
## What Gets Installed
Here's the rundown:

| Name        | Category            | Notes                                   |
| ----------- | ------------------- | --------------------------------------- |
| DNF Updates | Utilities           | Ensures your base system is up-to-date. |
| Git         | Version Control     | (duh🤠)                                 |
| Zsh         | Shell               | Different shell                         |
| Oh My Zsh   | Shell               | A cooler shell for looks-maxxing        |
| fzf         | Utility             | Fuzzy finder                            |
| tmux        | Utility             | Terminal window manager                 |
| GnuPG       | Utility             | Encryption and signing                  |
| OpenVPN     | Network             | VPN client                              |
| Curl        | Utility             | Staple tool                             |
| Wget        | Utility             | Another staple tool                     |
| KeePassXC   | Password            | An Open-source password manager         |
| RPM Fusion  | Software Collection | Multimedia codecs, drivers              |


2. And Some Desktop Apps:

| Name          | Category        | Notes                                  |
| ------------- | --------------- | -------------------------------------- |
| VLC           | Media           | Videoplayer                            |
| Discord       | Social          | For chatting                           |
| Brave Browser | Browser         | Preferred Browser                      |
| Sublime       | Text Editor     | Easy to use text editor                |
| Neovim        | Text Editor/IDE | Not so easy to use text editor and IDE |
| Micro         | Text Editor     | Lightweight text editor                |
| Steam         | Gaming          | Hub for games                          |
| Moonlight     | Streaming       | Streaming games throughout network     |
| Obsidian      | Notes           | Note-taking app                        |

3. Containerization:

- **Docker**:
    - Docker Engine
    - Docker CLI
    - Docker Compose (v2+)

(Installs Docker Desktop for Linux, which bundles these)

Adds your user to the docker group (requires re-login!).

Python (via Miniconda):
Installs Miniconda for managing Python environments. You'll likely need to run conda init or manually configure your shell after install if the script doesn't do it automatically.

Bun: Fast JavaScript runtime/bundler/package manager (via official install script).


4. Docker Containers / Stacks (via Docker Compose):

**Location**: Compose files (docker-compose.yml) and configurations will be placed in ~/homelab-docker/ by default.

**Setup**: The script will copy the template docker-compose.yml files. It will NOT automatically start them. You need to:

Navigate to the specific service directory (e.g., cd ~/homelab-docker/jellyfin-stack).

Review and customize the docker-compose.yml file (check ports, volumes, environment variables). You might need to create .env files for secrets.

Run docker compose up -d to start the stack in the background.

---
## Containers Planned:

| Jellyfin Stack | Purpose                                  |
| -------------- | ---------------------------------------- |
| Jellyfin       | Media Server                             |
| Sonarr         | Looks up TV Shows, Series, Anime         |
| Radarr         | Same as Sonarr, but for movies           |
| qBittorrent    | P2P Torrent client with VPN capabilities |
| Jellyseerr     | Manages requests and monitors Jellyfin   |
| Jackett        | Index manager for Sonarr and Radarr      |
*(interesting services to add: Readarr, Lidarr, Kapowarr, Gluetun, Tdarr, Bazarr, Flaresolverr, Homarr*

- ComfyUI: (in ~/homelab-docker/comfyui/) - AI Image Generation UI. Note: GPU passthrough might require installing NVIDIA Container Toolkit separately.
- Navidrome: (in ~/homelab-docker/navidrome/) - Music Streaming Server.
- Immich: (in ~/homelab-docker/immich/) - Self-hosted photos.
- Home Assistant: (in ~/homelab-docker/homeassistant/) - Home automation platform.
- Kali Linux: (in ~/homelab-docker/kali/ or just provide docker run command) - Penetration testing distro.

---

### Future Plans:

- [ ] Finding a way to setup Wazuh and ELK Stack agents on the user's computer.
- [ ] Compatibility with Windows.
- [ ] Interactive GUI.