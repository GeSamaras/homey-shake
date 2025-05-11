#!/bin/bash


Color_Off='\033[0m' # Text Reset

# Regular Colors
Black='\033[0;30m'  Red='\033[0;31m'    Green='\033[0;32m'  Yellow='\033[0;33m'
Blue='\033[0;34m'   Purple='\033[0;35m' Cyan='\033[0;36m'  White='\033[0;37m'

# Bold
BBlack='\033[1;30m' BRed='\033[1;31m'   BGreen='\033[1;32m' BYellow='\033[1;33m'
BBlue='\033[1;34m'  BPurple='\033[1;35m'BCyan='\033[1;36m' BWhite='\033[1;37m'

# Underline
UBlack='\033[4;30m' URed='\033[4;31m'   UGreen='\033[4;32m' UYellow='\033[4;33m'
UBlue='\033[4;34m'  UPurple='\033[4;35m'UCyan='\033[4;36m' UWhite='\033[4;37m'

# Background
On_Black='\033[40m' On_Red='\033[41m'   On_Green='\033[42m' On_Yellow='\033[43m'
On_Blue='\033[44m'  On_Purple='\033[45m'On_Cyan='\033[46m' On_White='\033[47m'

# High Intensity
IBlack='\033[0;90m' IRed='\033[0;91m'   IGreen='\033[0;92m' IYellow='\033[0;93m'
IBlue='\033[0;94m'  IPurple='\033[0;95m'ICyan='\033[0;96m' IWhite='\033[0;97m'

# Bold High Intensity
BIBlack='\033[1;90m'BIRed='\033[1;91m'  BIGreen='\033[1;92m'BIYellow='\033[1;93m'
BIBlue='\033[1;94m' BIPurple='\033[1;95m'BICyan='\033[1;96m'BIWhite='\033[1;97m'

# High Intensity backgrounds
On_IBlack='\033[0;100m'On_IRed='\033[0;101m'On_IGreen='\033[0;102m'On_IYellow='\033[0;103m'
On_IBlue='\033[0;104m'On_IPurple='\033[0;105m'On_ICyan='\033[0;106m'On_IWhite='\033[0;107m'

# --- Helper Functions ---

CHECK_MARK="${BGreen}✔${Color_Off}"
CROSS_MARK="${BRed}✖${Color_Off}"
ARROW="${BBlue}➜${Color_Off}"

info() { echo -e "${BBlue}INFO:${Color_Off} $1"; }
warn() { echo -e "${BYellow}WARN:${Color_Off} $1"; }
error() { echo -e "${BRed}${CROSS_MARK} ERROR:${Color_Off} $1" >&2; }
success() { echo -e "${BGreen}${CHECK_MARK} SUCCESS:${Color_Off} $1"; }
stage_header() { echo -e "\n${BPurple}>>> $1 <<${Color_Off}"; } # For major stages
step_info() { echo -e "${BCyan} ${ARROW} $1${Color_Off}"; }      # For steps within a stage

# Detect package manager and set command variables
# The way this function works is to populate variables with
# their respective OS CLI commands. It's gonna check which
# package manager in available in the machine, and from there
# determine the appropriate commands to be run.

detect_package_manager() {
    if command -v dnf &> /dev/null; then
        step_info "Detected dnf package manager (Fedora/RHEL-based)."
        PKG_MANAGER="sudo dnf" # Prefix to run install commands
        UPDATE_CMD="$PKG_MANAGER update -y"
        INSTALL_CMD="$PKG_MANAGER install -y"
        CHECK_PKG_CMD="rpm -q" # Command to check if a package is installed
        REPO_QUERY_CMD="dnf repolist enabled" # Command to list enabled repos
        PKG_PLUGIN_CORE="dnf-plugins-core" # Package providing repo management commands
        DISTRO="fedora"
    elif command -v apt-get &> /dev/null; then
        step_info "Detected apt package manager (Debian/Ubuntu-based)."
        PKG_MANAGER="sudo apt-get"
        UPDATE_CMD="$PKG_MANAGER update && $PKG_MANAGER upgrade -y"
        INSTALL_CMD="$PKG_MANAGER install -y"
        CHECK_PKG_CMD="dpkg -s" # Command to check if a package is installed
        REPO_QUERY_CMD="grep -R --include=\*.list ^deb /etc/apt/sources.list /etc/apt/sources.list.d/" # Command to check repo sources
        PKG_PLUGIN_CORE="software-properties-common" # Provides add-apt-repository, often installed
        DISTRO="debian"
    else
        error "Unsupported package manager. Exiting."
        exit 1
    fi
}

# Function to check if a command exists
check_command() {
    command -v "$1" &> /dev/null
}

# Function to check if a package is installed
check_package() {
    local pkg_name="$1"
    # Need to adjust check command syntax slightly based on manager
    if [ "$DISTRO" == "fedora" ]; then
        $CHECK_PKG_CMD "$pkg_name" &> /dev/null
    elif [ "$DISTRO" == "debian" ]; then
        $CHECK_PKG_CMD "$pkg_name" 2>/dev/null | grep -q '^Status: install ok installed'
    else
        return 1 # Unknown distro
    fi
}

# Function to install packages idempotently, aiming to avoid repetition.
# This will be called by other scripts, filled in with the packaged to be installed,
# and then proceed with either installing or skipping.
install_package() {
    local package_name="$1"
    step_info "Checking package: ${BYellow}$package_name${Color_Off}..."
    if check_package "$package_name"; then
        echo -e "      ${IGreen}$package_name is already installed. Skipping.${Color_Off}"
    else
        step_info "Attempting to install ${BYellow}$package_name${Color_Off}..."
        if $INSTALL_CMD "$package_name"; then
            info "$package_name installed successfully."
        else
            error "Failed to install $package_name."
            # Optionally exit here: exit 1
            return 1 # Indicate failure
        fi
    fi
    return 0 # Indicate success or already installed
}

check_directory() {
    [ -d "$1" ]
}

check_file() {
    [ -f "$1" ]
}

# Check if a DNF repo is enabled (Fedora)
check_dnf_repo() {
    local repo_id="$1"
    $REPO_QUERY_CMD | grep -q "^$repo_id\s"
}

# If an Apt repo source exists
check_apt_repo_source() {
    local source_pattern="$1" # e.g., download.docker.com
    $REPO_QUERY_CMD | grep -q "$source_pattern"
}

# If a Flatpak remote exists
check_flatpak_remote() {
    local remote_name="$1"
    flatpak remote-list | grep -q "^$remote_name\s"
}

# Check if a Flatpak app is installed
check_flatpak_app() {
    local app_id="$1"
    flatpak info "$app_id" &> /dev/null
}

# Function to install flatpak packages idempotently
install_flatpak_package() {
    local app_id="$1"
    step_info "Checking Flatpak: ${BYellow}$app_id${Color_Off}..."
    if check_flatpak_app "$app_id"; then
        echo -e "      ${IGreen}Flatpak: $app_id already installed. Skipping.${Color_Off}"
    else
        step_info "Attempting to install Flatpak: ${BYellow}$app_id${Color_Off}..."
        if flatpak install flathub "$app_id"; then
            info "Flatpak: $app_id installed successfully."
        else
            error "Failed to install Flatpak: $app_id."
            return 1
        fi
    fi
    return 0
}

# --- Initial Setup ---
detect_package_manager

# Ensure script exits on first error (can be overridden by checks)
# set -e # Removing this for now, as checks should handle failures gracefully. Add back if preferred.
