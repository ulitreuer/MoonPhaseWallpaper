#!/bin/bash
#
#==============================================================================
#  Project:     MoonPhaseWallpaper
#------------------------------------------------------------------------------
#  File:        install.sh
#  Author:      Uli Treuer
#  Purpose:     Orchestrates the installation of the MoonPhaseWallpaper
#               application
#
#  Copyright (c) 2026 Uli Treuer
#  License: MIT
#==============================================================================

#==================================================================================================
# Installation script for the MoonPhaseWallpaper Generator
#
# Features:
# - Idempotent
# - Safe to run multiple times
# - Never modifies user configuration without asking
# - Clear progress messages
# - Fail with meaningful error messages
#==================================================================================================

# for determining run duration
SECONDS=0

# enable logging during installation
verbose_mode=true

# Determine the directory containing this script.
# (directory in which the script is located - no matter what it is called)
readonly wdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

source "$wdir/lib/directories.sh"
source "$wdir/lib/logger.sh"

#==============================================================================
# Function definitions
#==============================================================================

#==================================================================================================
# main
#
# Orchestration of the installation script
#==================================================================================================
main()
{
    welcome

    check_repository || return 1

    set_directories

    check_dependencies || return 1

    configure_systemd_integration || return 1

    goodbye
}

#==================================================================================================
# welcome
#
# Display a nice and informative 'Welcome' screen
#==================================================================================================
welcome()
{
    clear
    headline " MoonPhaseWallpaper: Installation"
    echo " This script will"
    echo
    echo "    ✓ verify the installation environment"
    echo "    ✓ check required software"
    echo "    ✓ optionally configure the user systemd timer"
    echo
    echo " Your existing configuration will never be modified without your consent."
    echo
    echo " Press <Enter> to continue..."
    read -r
}

#==================================================================================================
# check_repository
#
# Checks whether the repository is complete (spotchecks of most important files and directories)
# to make sure the installation script was started in the project directory
#==================================================================================================
check_repository()
{
local missing=false
local -a required=(
    moon_wallpaper.sh
    install.sh
    README.md
    INSTALL.md
    LICENSE
    lib
    images
    configuration
    systemd
)

    headline " MoonPhaseWallpaper: Repository Verification"

    for item in "${required[@]}"; do
        if [[ ! -e "$item" ]]; then
            echo " x Missing: $item"
            missing=true
        fi
    done

    if $missing; then
        echo
        echo " This script must be executed from the MoonPhaseWallpaper project directory."
        echo
        echo " Press <Enter> to continue..."
        read -r
    else
        echo
        echo " ✓ Repository structure verified."
        echo
        echo " Press <Enter> to continue..."
        read -r
    fi
    $missing && return 1
    return 0
}

#==================================================================================================
# check_command
#
# Checks whether the specified binary exists
#==================================================================================================
check_command()
{
local binary=$1
local -n status_ref=$2

    if command -v "$binary" >/dev/null 2>&1; then
        status_ref=true
    else
        status_ref=false
    fi
}

#==================================================================================================
# check_dependencies
#
# Checks whether all required software is in installed.
#==================================================================================================
check_dependencies()
{
local i status

local -a module_binary=(
    git
    gawk
    magick
    curl
    qdbus-qt6
)

local -a module_name=(
    "Git"
    "GNU Awk"
    "ImageMagick"
    "curl"
    "D-Bus Tools Qt 6"
)

local -a missing

    headline " MoonPhaseWallpaper Installation: Check of required software"

    for ((i=0; i<${#module_binary[@]}; i++)); do
        check_command "${module_binary[i]}" status
         if $status; then
            echo " ✓ ${module_name[i]}"
        else
            echo " ✗ ${module_name[i]}"
            missing+=("${module_name[i]}")
        fi

    done

    local desktop_name="KDE Plasma"

    if [[ $XDG_CURRENT_DESKTOP == *KDE* ]]; then
        echo  " ✓ $desktop_name"
    else
        echo " x MoonPhaseWallpaper currently supports $desktop_name only."
        missing+=("$desktop_name")
    fi

    if (( ${#missing[@]} > 0 )); then
        echo
        echo " The following required software is missing:"
        printf '    %s\n' "${missing[@]}"
        echo
        echo " Please install the missing software and run install.sh again."
        echo
        echo " Example (Fedora):"
        echo " sudo dnf install ..."
        echo
        echo " Press <Enter> to continue..."
        read -r
        return 1
    else
        echo
        echo " All required software is installed."
        echo
        echo " Press <Enter> to continue..."
        read -r
        return 0
    fi
 }

#==================================================================================================
# configure_systemd_integration
#
# Configures and enables the systemd timer to run the script at a user-defined interval.
#==================================================================================================
configure_systemd_integration()
{
local answer
local interval
local MIN_INTERVAL=3
local MAX_INTERVAL=60
local DEFAULT_INTERVAL=5

    headline " MoonPhaseWallpaper Installation: systemd timer"
    ask_yes_no " Configure systemd timer for automatic wallpaper updates? [Y/n]: " answer

    echo
    if [[ $answer == y ]]; then
        ask_positive_integer \
            " Update interval in minutes (3-60) [5]:" \
            "$MIN_INTERVAL" \
            "$MAX_INTERVAL" \
            "$DEFAULT_INTERVAL" \
            interval

        install_systemd_timer "$interval" || return 1
    else
        echo
        echo " Not installing systemd timer."
    fi
    echo
    echo " Press <Enter> to continue..."
    read -r
}

#==================================================================================================
# install_systemd_timer
#
# Install and configure the user systemd integration.
#==================================================================================================
install_systemd_timer()
{
local interval="$1"
local service_file
local timer_file
local service_target
local timer_target
local systemd_dir

    service_file="moon_wallpaper.service"
    timer_file="moon_wallpaper.timer"

    systemd_dir="$HOME/.config/systemd/user"
    service_target="$systemd_dir/$service_file"
    timer_target="$systemd_dir/$timer_file"

    mkdir -p "$systemd_dir"

    # Stop the timer before replacing the timer definition.
    # This ensures a changed OnCalendar schedule becomes effective.
    systemctl --user disable --now moon_wallpaper.timer >/dev/null 2>&1 || true

    # Copy the service template
    cp -f "$wdir/systemd/$service_file" "$service_target" || {
        logv "Failed to copy systemd service."
        return 1
    }

    # Replace placeholder with installation directory
    sed -i "s|@INSTALL_DIR@|$wdir|g" "$service_target" || {
        logv "Failed to replace @INSTALL_DIR@ in systemd service."
        return 1
    }

    # Copy the timer template
    cp -f "$wdir/systemd/$timer_file" "$timer_target" || {
        logv "Failed to copy systemd timer."
        return 1
    }

    # Replace placeholder with update interval
    if (( interval == 60 )); then
        oncalendar="hourly"
    else
        oncalendar="*:0/$interval"
    fi
    sed -i "s|@INTERVAL@|$oncalendar|g" "$timer_target" || {
        logv "Failed to replace @INTERVAL@ in systemd service."
        return 1
    }

    # Reload the user systemd configuration and enable the timer:
    systemctl --user daemon-reload || {
        logv "Failed to reload systemd daemon."
        return 1
    }

    systemctl --user enable --now moon_wallpaper.timer || {
        logv "Failed to enable moon_wallpaper.timer."
        return 1
    }

    echo
    echo " ✓ systemd user timer installed and enabled successfully."
    echo
    echo " The wallpaper will now be updated automatically every $interval minutes."
}

#==================================================================================================
# goodbye
#
# Shows an installation summary screen
#==================================================================================================
goodbye()
{
    headline " MoonPhaseWallpaper: Installation Summary"
    echo " Installation completed successfully."
    echo
    echo " Next, configure MoonPhaseWallpaper:"
    echo
    echo "    ./moon_wallpaper.sh -c"
    echo
    echo " Thank you for trying MoonPhaseWallpaper!"
    echo " Enjoy the Moon! 🌙"
    echo
}

#==================================================================================================
# ask_yes_no
#
# Asks for user input to yes-no questions with a variable prompt
# Y,y, N, n is accepted input.
# y is the default ((for <Enter> with no input)
# Data validation is included
#==================================================================================================
ask_yes_no()
{
local prompt=$1
local -n answer_ref=$2

    while true; do
        read -rp " $prompt " answer_ref

        # User just pressed Enter -> use defaults
        if [[ -z $answer_ref ]]; then
            answer_ref="y"
            break
        fi
        if [[ $answer_ref =~ ^[YyNn]$ ]]; then
            answer_ref=${answer_ref,,}    # Convert to lowercase
            break
        fi

        echo " Please enter exactly one of these characters: Y, y, N, or n."
        echo
    done
}

#==================================================================================================
# ask_positive_integer
#
# Asks the user to input a positive number in a certain interval with a variable prompt
# Only positive integers within the specified interval are accepted.
# For input without a value, the specified default is provided.
# Data validation is included.
# Inputs:
#   $1  prompt
#   $2  minimum
#   $3  maximum
#   $4  default
# Output
#   $5  entered value
#==================================================================================================
ask_positive_integer()
{
local prompt="$1"
local minimum="$2"
local maximum="$3"
local default="$4"
local -n answer_ref="$5"

    while true; do
        read -rp " $prompt " answer_ref

        # User just pressed Enter -> use defaults
        if [[ -z $answer_ref ]]; then
            answer_ref="$default"
            break
        fi
        if [[ $answer_ref =~ ^[1-9][0-9]*$ ]]; then
            if [[ $answer_ref -ge $minimum ]]; then
                if [[ $answer_ref -le $maximum ]]; then
                    break
                fi
            fi
        fi

        echo " Please enter a value in the range [$minimum..$minimum]."
        echo
    done
}

#==================================================================================================
# headline
#
# Shows a nice header for a section. Variable text is passed as an argument
#==================================================================================================
headline()
{
local title=$1
local underline

    printf -v underline '%*s' "${#title}" ''
    underline=${underline// /=}

    echo
    echo " $title"
    echo " $underline"
    echo
}

#==================================================================================================
# Program entry point
#==================================================================================================

main
rc=$?

if ((rc > 0)); then
    echo "Installation failed."
    echo "Please correct the reported problems and run install.sh again."
fi

logv "Completed in ${SECONDS} seconds."
logv "================================================================================"

exit "$rc"

# --- This is the end, my friend ------------------------------------------------------------------
