#!/bin/bash

# --- Main Setup Script for homey-shake ---

# Ensure helper functions are sourced first for messages
# Handle potential errors if helpers.sh is missing
if [ -f ./helpers.sh ]; then
    source ./helpers.sh
else
    echo "ERROR: helpers.sh not found. Cannot continue." >&2
    exit 1
fi

# --- Argument Parsing with getopts ---

# Default values: Run no stages unless specified or --all is used
run_system=false
run_apps=false
run_dev=false
run_docker_dirs=false
run_all=false
assume_yes=false

# Use getopt for long options (requires getopt package, usually present)
# If getopt isn't available, fallback to basic getopts or simplify flags
if command -v getopt &> /dev/null; then
    TEMP=$(getopt -o 'ysadp' --long 'yes,system,apps,dev,docker-dirs,all' -n 'setup.sh' -- "$@")
    if [ $? != 0 ] ; then error "Terminating..." >&2 ; exit 1 ; fi
    eval set -- "$TEMP" # Note the quoting and eval
    unset TEMP
else
    warn "getopt command not found, long options (--system, etc.) might not work reliably."
    # Basic getopts fallback (only short options)
    while getopts ":ysadp" opt; do
      case $opt in
        y) assume_yes=true ;;
        s) run_system=true ;;
        a) run_apps=true ;;
        d) run_dev=true ;;
        p) run_docker_dirs=true ;; # 'p' for path/project dirs
        \?) error "Invalid option: -$OPTARG" >&2; exit 1 ;;
      esac
    done
    shift $((OPTIND-1))
    # If no flags were given in basic mode, assume --all
    if ! $run_system && ! $run_apps && ! $run_dev && ! $run_docker_dirs; then
        run_all=true
    fi
fi

# Process options parsed by getopt (if used)
if command -v getopt &> /dev/null; then
    while true; do
      case "$1" in
        -y | --yes ) assume_yes=true; shift ;;
        -s | --system ) run_system=true; shift ;;
        -a | --apps ) run_apps=true; shift ;;
        -d | --dev ) run_dev=true; shift ;;
        -p | --docker-dirs ) run_docker_dirs=true; shift ;; # Match the p above
        --all ) run_all=true; shift ;;
        -- ) shift; break ;; # End of options
        * ) break ;; # Should not happen with getopt error checking
      esac
    done
fi

# --- Determine Execution Stages ---

# If --all is specified, enable all stages
if [ "$run_all" = true ]; then
    info "Running all setup stages (--all specified)."
    run_system=true
    run_apps=true
    run_dev=true
    run_docker_dirs=true
fi

# If no flags were specified at all (getopt processes '--' resulting in no flags set)
# check if any run_* variable is true. If not, default to running all.
if ! $run_system && ! $run_apps && ! $run_dev && ! $run_docker_dirs && ! $run_all; then
    info "No specific stages selected, defaulting to run all stages."
    run_system=true
    run_apps=true
    run_dev=true
    run_docker_dirs=true
fi

# --- Start Setup ---

info "Starting Homey-Shake Setup Process..."
warn "This script will install/configure software based on selected flags."
warn "System: $run_system, Apps: $run_apps, Dev: $run_dev, Docker Dirs: $run_docker_dirs"
warn "Assume Yes: $assume_yes"

# Check for sudo privileges early if any stage requiring it is selected
if $run_system || $run_apps || $run_dev; then
    if [ "$EUID" -ne 0 ]; then # Check if already root
        info "Checking sudo privileges..."
        if ! sudo -v; then
             error "Sudo privileges are required but could not be obtained. Exiting."
             exit 1
        fi
         info "Sudo privileges verified."
    else
        info "Running as root."
    fi
fi


# Confirmation Prompt (unless -y is used)
if [ "$assume_yes" = false ]; then
    read -p "Do you want to proceed with the selected stages? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[yY](es)?$ ]]; then
        info "Setup cancelled by user."
        exit 0
    fi
fi

# --- Execute Selected Stages ---

# Ensure script exits if a sub-script fails critically
# We removed set -e from helpers, but might want it for the main flow control
set -e

if [ "$run_system" = true ]; then
    info "--- Executing Stage: System Package Installation ---"
    if bash ./install_system.sh; then
         info "--- Stage Complete: System ---"
    else
         error "Stage Failed: System Package Installation. Exiting."
         exit 1
    fi
fi

if [ "$run_apps" = true ]; then
    info "--- Executing Stage: Desktop Application Installation ---"
     if bash ./install_apps.sh; then
         info "--- Stage Complete: Apps ---"
    else
         error "Stage Failed: Desktop Application Installation. Exiting."
         exit 1
    fi
fi

if [ "$run_dev" = true ]; then
    info "--- Executing Stage: Development Tools Installation ---"
    if bash ./install_dev_tools.sh; then
         info "--- Stage Complete: Dev Tools ---"
    else
         error "Stage Failed: Development Tools Installation. Exiting."
         exit 1
    fi
fi

if [ "$run_docker_dirs" = true ]; then
    info "--- Executing Stage: Docker Directory Setup ---"
    if bash ./setup_docker_dirs.sh; then
         info "--- Stage Complete: Docker Dirs ---"
    else
         error "Stage Failed: Docker Directory Setup. Exiting."
         exit 1
    fi
fi

# --- Final Instructions ---

info "--- Homey-Shake Setup Script Finished ---"
if $run_dev; then # Only show Docker warning if dev tools were installed
    warn "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    warn "!!! IMPORTANT: If Docker was installed or user added to group, you MUST    !!!"
    warn "!!! reboot or log out and log back in for changes to take effect.        !!!"
    warn "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
fi
if $run_docker_dirs; then # Only show Docker compose warning if dirs were set up
    warn "After logging back in (if needed):"
    warn " - Review and customize docker-compose.yml files in ~/homelab-docker/*/"
    warn " - Run 'docker compose up -d' in each service directory to start containers."
fi
if $run_apps && ! check_directory "$HOME/.oh-my-zsh"; then # If apps were run but OMZ failed/skipped
     # This condition might be tricky if OMZ install fails silently
     : # Maybe add a more specific check later
elif $run_apps; then
     warn " - Oh My Zsh might require you to type 'zsh' or set it as default shell ('chsh -s $(which zsh)')."
fi

exit 0