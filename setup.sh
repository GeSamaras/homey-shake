#!/bin/bash

# --- Main Setup Script for togeprii ---

# Ensure helper functions are sourced first for messages
# Handle potential errors if helpers.sh is missing
if [ -f ./helpers.sh ]; then
    source ./helpers.sh
else
    echo "ERROR: helpers.sh not found. Cannot continue." >&2
    exit 1
fi


TOGEPRII_ASCII_ART=$(cat <<'EOF'
                                                       +++
                                                     ;;;;;++
                                                   +;;;;;;;+++
                                                 +;;;;;;;;;;;+;
                                                ;;;;;;;;;;;;;;++
                                              +;;;;;;;;;;;;;;;;++
                                             ;;;;;;;;;;;;;;;;;;;;+
                                            ;;;;;;;;;;;;;;;;;;;;;;+;
                                           ;;;;;;;;;;;;;;;;;;;;;;;;++
                                         +;;;;;;;;;;;;;;;;;;;;;;;;;;++
                                 xxx    +;;;;;;;;;;;;;;;;;;;;;;;;;;;;+;
         +++++x                 x+++++x+;;;;;;;;;;;;;;;;;;;;;;;;;;;;;++;            xx
         ++;;;;;+++++           ++xxxx++;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;++     +++++++x++
         ++;;;;;;;;;;;++++     ;+xxxx++;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;+++x+++++++++x++     +;;;;;;;+;;;;;;++++
          +;;;;;;;;;;;;;;;;+++x+xx++x+;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;++;;+++xx+++xxx+;;;;;;;;;;;;;;;;;;;;++x+
          x+;;;;;;;;;;;;;;;;;;;++++++;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;++++x+;;;;;;;;;;;;;;;;;;;;;;;;;;;+++++
           x+;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;++++++
           x+;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;++++++x+
            x+;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;++++++xx:
             x+;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;++++++++x+
              ++;;;;;;;;;;;;;;;;;;;;;;;;+XX+Xx;;;;;;;;;;;;;;xx+;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;+++++++++x;
              +++;;;;;;;;;;;;;;;;;;;;;;;xx;;++;;;;;;;;;;;;xx;;+X;;;;;;;;;;;;;;;;;;;;;;;;;;;;+++++++++xx:
               +++;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;++++++++++x+
               +++;;;;;;;;;;;;;;;;;;;;;;;;;;;;;+;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;++++++++++++x+
                x++;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;++++;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;+++++++++++++x;:
                x+++;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;++++++++++++++;
                +++++;;;+++;++;;;;;;;;;;;;;xxxxxxxx+;;;;;;;;;;;;;;;;;;;;;;+++;++;;;++++++++++++x+;
            ;;+x+++++;++;;;;;;++;;;;;;;;;+xxxxxxxxxxXXX++;;;;;;;;;;;;;;++;;;+xxXX+;++++++++++++++
          ;;;;;;+x++x+;;+xXXxx+xxx+++;;;xXxxxxxxxxxXXXX;;++;;;;;;;;;++;xXXXXXXXXXXx+++++++++++xxxx
         ;;;;;;;;;+++++;;;;;;;;;;;;;;;;+XxxxxxxxxxxXXx+++++++++++++++++xX$$x+++XXXXXx++++++xx+++++xXxx
        ;;;;;;;;;;;+;;;;;;;;;;;;;;;;;;;+xxxxxxxxxx+;;;;;;;;;;;;;;;;;;;;;;;;+++xXXXX+++++xx++++++++++++x
       +;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;xXXXXXXXXXX+;;;;;;;;;;;;;;;;;;;;;;;;;;;;+XX+;;;++++++++++++++++++
       ;;;;;;;;;;;+;;;;;;;;;;;;;;;;;++;;;xXXXXXXXXXX+;;;;;;;;;;;;;;;;;;;;;;;;;;;++;;;;;++++++++++++++++x;
      ;;;;;;;;;;;;+;;;;;;;;;;;;+++;;;;;;;;;;;++xxx+;;;++;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;++++++++++++++++++
      ;;;;;;;;;;;;;;;;;;;+++++;;;;;;;;;;;;;;;;;;;;;;;;;;;++;;;;;;;;;;;;;;;;;;;;;+;;;;;;+++++++++++++++++++
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;++;;;;;;;;;;;;;;;;++;;;;;;+++++++++++++++++++
     ;;;;;+xxx+;+xxXXxx+;;;;;;;;;;;;;++;;;;;;;;;;;;;;;;;;;;;;;;;++++;;;;;;;;;++;;;;;;;+++++++++++++++++++x;
     ++xxxx+;;+xXXXXXxxxx;;;;;;;;;;xxxxxxxx+;;;;;;;;;;;;;;;;;;;;;;;;;++++++++;;;;;;;;;+++++++++++++++++++++
                 xXXXXXXXX;;;;;;;;xxxxxxxxxxxxx+;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;+++++++++++++++++++++
                   XXXX+;+x+;;;;+xXXXXxxxxxxxxxxxx+;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;++++++++++++++++++++++
                    XXXxx+:+XXXXXXXXxxxXXxxxxxxxxxxxx+;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;++++++++++++++++++++++
                     XXXXXxXXXXXXXXXxxxxxX$XXXXXXXXxxxxx+;;;;;;;;;;;;;;;;;;;;;;;;;;;;++++++;;;;+x+++++++++x
                             +xxXXXXXXxXX$XXXXxxxxxxXxxxxxx+;;;;;;;;;;;;;;;;;;;;;;;;+++;;;+++++xx+x+++++++x
                                         ;xXXXXXxxx+xXXxxxxxx+;;;;;;;;;;;;;;;;;;;+++;;;++++++++xx++x++++++x
                                                  xXXXXXxxxxxxx+;;;;;;;;;;;;;;;;;;;;;++++++++++++++++++++++
EOF
)

clear # Optional: Clears the screen for a clean intro
echo -e "${BYellow}$TOGEPRII_ASCII_ART${Color_Off}"
echo -e "${BWhite}Welcome to the togeprii!${Color_Off}"
echo -e "${Cyan}Please remember to read the script and hydrate!${Color_Off}\n"

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

info "Welcome to Togeprii!"
echo -e "${BWhite}Selected Stages:${Color_Off}"
[ "$run_system" = true ] && echo -e "  ${Yellow}- System Packages${Color_Off}"
[ "$run_apps" = true ] && echo -e "  ${Yellow}- Desktop Applications${Color_Off}"
[ "$run_dev" = true ] && echo -e "  ${Yellow}- Development Tools${Color_Off}"
[ "$run_docker_dirs" = true ] && echo -e "  ${Yellow}- Docker Directories${Color_Off}"
echo

# Check for sudo privileges early if any stage requiring it is selected
if $run_system || $run_apps || $run_dev; then
    if [ "$EUID" -ne 0 ]; then # Check if already root
        step_info "Checking sudo privileges..."
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
    echo -e -n "${BYellow}Do you want to proceed with the selected stages? (y/N): ${Color_Off}"
    read -r confirm
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
    stage_header "🌟 System package installation 🌟"
    if bash ./install_system.sh; then
         info "Stage Complete"
    else
         error "Stage Failed: System Package Installation. Exiting."
         exit 1
    fi
fi

if [ "$run_apps" = true ]; then
    stage_header "🌟 Desktop apps installation 🌟"
     if bash ./install_apps.sh; then
         info "Stage Complete"
    else
         error "Stage Failed: Desktop Application Installation. Exiting."
         exit 1
    fi
fi

if [ "$run_dev" = true ]; then
    stage_header "🌟 Development tools 🌟"
    if bash ./install_dev_tools.sh; then
         info "Stage Complete"
    else
         error "Stage Failed: Development Tools Installation. Exiting."
         exit 1
    fi
fi

if [ "$run_docker_dirs" = true ]; then
    stage_header "🌟 Docker directories 🌟"
    if bash ./setup_docker_dirs.sh; then
         info "Stage Complete"
    else
         error "Stage Failed: Docker Directory Setup. Exiting."
         exit 1
    fi
fi

# --- Final Instructions ---

echo -e "\n${BGreen}>>> togeprii Setup Script Finished <<<${Color_Off}"
if $run_dev; then
    warn "              + ~~+    |         .       .-.         '        |          * "
    warn "${BWhite}IMPORTANT:${Color_Off} If Docker or Virtualization tools were installed, or user added"
    warn "to 'docker' or 'libvirt' groups, you ${BRed}MUST reboot or log out and log back in${Color_Off}"
    warn "for changes to take effect.                                              "
    warn " +'       -o-   .       ' .      +.                                    *  ."
fi
if $run_docker_dirs; then
    step_info "After logging back in (if needed):"
    step_info "- Review and customize ${Cyan}docker-compose.yml${Color_Off} files in ${Cyan}~/homelab-docker/*/ ${Color_Off}"
    step_info "- Run '${Cyan}docker compose up -d${Color_Off}' in each service directory to start containers."
fi
if $run_apps; then
     step_info "- Oh My Zsh might require you to type '${Cyan}zsh${Color_Off}' or set it as default shell ('${Cyan}chsh -s \$(which zsh)${Color_Off}')."
fi
echo -e "${BGreen}All done! Enjoy your togeprii-enhanced setup! ✨${Color_Off}"

exit 0