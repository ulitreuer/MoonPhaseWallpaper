#!/bin/bash
#
#==============================================================================
#  Project:     MoonPhaseWallpaper
#------------------------------------------------------------------------------
#  File:        moon_wallpaper.sh
#  Author:      Uli Treuer
#  Purpose:     Orchestrates the creation process of the MoonPhaseWallpaper.
#
#  Copyright (c) 2026 Uli Treuer
#  License: MIT
#==============================================================================

#==================================================================================================
# Moon Phase Wallpaper Generator
#
# Generates hourly wallpapers using NASA SVS Moon imagery.
# Script to download information about moon phases and an image of the moon in the current
# moon phase from the NASA web page https://svs.gsfc.nasa.gov/.
# A nice image is created by overlaying the moon phase information to the downloaded image.
# Finally, the image is set as the wallpaper on the screen of the Activity selected during
# configuration. This script is called by a user-specific systemd timer at minute 0 of every hour.
#
# Features:
# - Automatic download of NASA yearly Moon dataset
# - Correct lunar phase
# - Correct libration
# - Observer-dependent apparent orientation
# - Dynamic text overlay
# - Automatic wallpaper generation

# Dependencies:
# - bash
# - ImageMagick
# - gawk
# - curl
#==================================================================================================

# for determining run duration
SECONDS=0

# Determine the directory containing this script.
# (directory in which the script is located - no matter what it is called)
readonly wdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

source "$wdir/lib/configuration.sh"
source "$wdir/lib/configuration_wizard.sh"

source "$wdir/lib/directories.sh"
source "$wdir/lib/logger.sh"

source "$wdir/lib/kde_activity_tools.sh"

source "$wdir/lib/astronomy.sh"
source "$wdir/lib/image_processing.sh"
source "$wdir/lib/moon_data.sh"
source "$wdir/lib/moon_images.sh"
source "$wdir/lib/wallpaper.sh"

# Evaluate command line options
debug_mode=false
verbose_mode=false
configuration_mode=false
while getopts ":cdv" opt; do
    case "$opt" in
        c)
            configuration_mode=true ;;
        d)
            debug_mode=true ;;
        v)
            verbose_mode=true ;;
        \?)
            echo "Unknown option: -$OPTARG"
            echo "Usage:"
            echo "    moon_wallpaper.sh [-c] [-d] [-v]"
            exit 1
            ;;
    esac
done

# Define all working directories
set_directories

# Start configuration wizard when called with option '-c'
if $configuration_mode; then
    configure_application
    exit 0
fi

# Read all configuration data
read_configuration
case $? in
    1)
        # exit application
        fatal_configuration_error "Configuration file is missing:" "$configfile"
        ;;
    2)
        # exit application
        fatal_configuration_error "Configuration file is corrupt:" "$configfile"
        ;;
esac

# Declare all global arrays which are needed
declare -a moonimage
declare -a moonimage_URL
declare -a datestamp
declare -a timestamp
declare -a phase
declare -a distance
declare -a cycle
declare -a ra
declare -a dec
declare -a axisA
declare -a moonrise
declare -a moonset
declare -a moonstatus

# Verify that configured screen is available/connected.
# If not then do not try to update the wallpaper and exit gracefully.
verify_screen "$SCREEN" screen_available
if (( screen_available == 0 )); then
    loge "Configured screen is not connected."
    loge "Wallpaper cannot be updated."
    exit 0
fi

# Cleanup (just in case the previous run was interrupted and there are leftovers)
clear_image_dir

# Defines the URLs from which the moon images will be downloaded.
# The URLs must be updated at the end of each year for the following year.
# Instructions are contained in the header of function define_moonimage_URLs
# in the file lib/config.sh
define_moonimage_URLs

# Download the text file for phase/illumination from the NASA web page
read_moon_info

# Determine metadata for all days
calculate_moon_metadata

# Download all moon image as defined before from the NASA web page in parallel
download_moon_images

# Create the final image (one big image for current date and time) and 6 small inserts on the final
# image showing the moon image for the 6 days before today (making it the complete last week)
# The name of the created image is returned
image_processing wallpaper_name

# Call the function to set the completed image as the new wallpaper on the second display
# in Activity 'Main Screen'
set_wallpaper "$wallpaper_name"

#--------------------------------------------------------------------------------------------------
logv "Moon Wallpaper successfully updated."
logv "Completed in ${SECONDS} seconds."
logv "================================================================================"

exit 0
# --- This is the end, my friend ------------------------------------------------------------------
