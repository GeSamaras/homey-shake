# togeprii

This repo helps you quickly set up a fresh Linux install (Fedora KDE and Mint tested) for development, media, and homelab tinkering. These are tools i personally use and want in my system by default. So, while the configurations might not be pristine and standardized, the point is to get a new machine up and running with all the useful stuff i personally want (bloat🤠). It uses a mix of bash scripts and Docker to get everything installed and configured, and i highly encourage for you to add and tweak your own fork with things you like! 

---
## How it Works:

You'll clone this repo, run the main script, and it'll handle installing system packages, desktop apps, development tools, and setting up Docker containers.

---
### Prerequisites

- Debian/Ubuntu or Fedora system.
- git.
- `sudo` privileges: The scripts need root access to install software.

---

# DISCLAIMER!

This is meant for personal use. Be cautious when running scripts unless you trust and understand them!

First read the scripts and how they work, and test it on a virtual machine before running on your local computer.

By the way, throughout this project i warn caution when running any script, however i advise to only consider using this repo if you're fairly familiar and comfortable with bash scripts and Linux.

---

## Clone the Repo:

```bash
# First, make sure git is installed
sudo dnf install -y git
git clone https://github.com/GeSamaras/togeprii.git ~/togeprii
cd ~/togeprii
# Recommended to read all the scripts top to bottom.
cat setup.sh
cat install_system.sh
# And so on
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
| btop        | System Monitor      | View system resources                   |
| tldr        | Command manual      | Community-driven manual                 |
| ffmpeg      | Video/Audio tool    | Tool for video and audio processing     |
| python3-pip | Dev                 | Package manager for python              |

2. And Some Desktop Apps:

| Name          | Category        | Notes                                  |
| ------------- | --------------- | -------------------------------------- |
| VLC           | Media           | Videoplayer                            |
| Discord       | Social          | For chatting                           |
| Brave Browser | Browser         | Preferred Browser                      |
| Neovim        | Text Editor/IDE | Not so easy to use text editor and IDE |
| Steam         | Gaming          | Hub for games                          |
| Moonlight     | Streaming       | Streaming games throughout network     |
| Obsidian      | Notes           | Note-taking app                        |
| qBitTorrent   | Torrent         | Torrent client                         |
| GIMP          | Editor          | Image editor                           |
| OBS           | Video capture   | Software for recording                 |


3. Containerization:

- **Docker**:
    - Docker Engine
    - Docker CLI
    - Docker Compose (v2+)

(Installs Docker Desktop for Linux, which bundles these)

Adds your user to the docker group (requires re-login!).


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
*interesting services to add: Readarr, Lidarr, Kapowarr, Gluetun, Tdarr, Bazarr, Flaresolverr, Homarr*

- Navidrome: (in ~/homelab-docker/navidrome/) - Music Streaming Server.
- Immich: (in ~/homelab-docker/immich/) - Self-hosted photos.
- Home Assistant: (in ~/homelab-docker/homeassistant/) - Home automation platform.


---

### Future Plans:

- [X] Automatic testing, Github Actions, CI/CD
- [ ] Ricing maybe?
- [ ] Better setup for docker compose.
- [X] Graphical flair, coloring, better readability and formatting.
- [ ] Interactive UI.
- [ ] Setup Go, TS and Python environment.
- [ ] Finding a way to setup Wazuh and ELK Stack agents.