#!/bin/bash
#
#==============================================================================
#  Project:     MoonPhaseWallpaper
#------------------------------------------------------------------------------
#  File:        moon_images.sh
#  Author:      Uli Treuer
#  Purpose:     Downloads and manages the caching of the moon images from
#               the NASA web page for MoonPhaseWallpaper.
#
#  Copyright (c) 2026 Uli Treuer
#  License: MIT
#==============================================================================

#==================================================================================================
# download_moon_images
#
# download all required moon images from the NASA web page in parallel
# (if they are not in the cache directory already)
#==================================================================================================
download_moon_images()
{
local i
local start end elapsed
local cache_name
local status

    start=$(date +%s.%N)
    logv "In download_moon_images"

    determine_moonimage_name_url

    ensure_cache status
    if (( status == 0 )); then
        logd "Using cached moon images."
        return 0 # all required moon imaged are already in the cache directory
    fi

    logd "Moon image cache is incomplete. Rebuilding!"
    # get the name of the current cache directory
    get_cache_name cache_name

    for (( i=0; i<7; i++ )); do
        logv "Downloading image $((i+1)) of 7"
        # download the moon image
        curl -L -o "$imdir"/"$cache_name"/"${moonimage[$i]}" "${moonimage_URL[$i]}" 2> /dev/null &
    done
    wait # wait until all downloads have been completed

    end=$(date +%s.%N)
    elapsed=$(awk "BEGIN { printf \"%.2f\", $end - $start }")
    logd "Completed in ${elapsed} seconds."
    logv "================================================================================"
    logv " "
}

#==================================================================================================
# determine_moonimage_name_url
#
# Determine the name and the URL for the moon images needed for the current hour.
#==================================================================================================
determine_moonimage_name_url()
{
local i
local selected_year
local num

    for (( i=0; i<7; i++ )); do
        selected_year=$(date --utc -d "$i days ago" +"%Y")
        calculate_hour_of_year "$i" num

       #----------------------------------------------------------------------------------------------
        # determine name and URL of the moon image to be downloaded from the NASA web page
        moonimage+=("moon.$(printf '%04d' $num).tif") # filename for image to download
        moonimage_URL+=("${nasa_url[$selected_year]}/frames/3840x2160_16x9_30p/plain/${moonimage[i]}")

        logd "Moonimage:     ${moonimage[i]}"
        logd "Moonimage_URL: ${moonimage_URL[i]}"
        #----------------------------------------------------------------------------------------------
    done
}

#==================================================================================================
# clear_image_dir
#
# Removes all temporary files from the image directory
#==================================================================================================
clear_image_dir()
{
local start end elapsed

    start=$(date +%s.%N)
    logv "In clear_image_dir"
    cd "$imdir" || {
        logv "ERROR: cannot enter $imdir" >&2
        exit 1
    }
    logv "Removing potential leftovers images"

    rm -f final.tif # intermediate file from ImageMagick
    end=$(date +%s.%N)
    elapsed=$(awk "BEGIN { printf \"%.2f\", $end - $start }")
    logd "Completed in ${elapsed} seconds."
    logv "================================================================================"
    logv " "
}

#==================================================================================================
# get_cache_name
#
# Return the current cache directory.
# The directory is created if it does not already exist.
#==================================================================================================
get_cache_name()
{
local -n cachename_ref="$1"

    cachename_ref=$(date '+%Y%m%d%H')
    mkdir -p "$imdir"/"$cachename_ref"

}

#==================================================================================================
# cache_complete
#
# Verifies whether the cache directory contains all moon images for the current hour.
#==================================================================================================
cache_complete()
{
local cache_dir="$1"
local i

    for (( i=0; i<${#moonimage[@]}; i++ )); do
        [[ -f "$cache_dir/${moonimage[i]}" ]] || return 1
    done

    return 0
}

#==================================================================================================
# ensure_cache
#
# Verify the existence and completeness of the cache directory for the current hour.
# All outdated cache directories will be deleted.
# If it is missing or incomplete the cache directory will be deleted and recreated (empty).
#==================================================================================================
ensure_cache()
{
local -n status_ref="$1"
local cache_name

    # get the name of the current cache directory
    get_cache_name cache_name

    # delete all obsolete caches (subdirectories) in imdir except the current cache directory
    find "$imdir" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d \
        ! -name "$cache_name" \
        -exec rm -rf {} +

    if cache_complete "$imdir/$cache_name"; then
        status_ref=0
        logd "Cache is complete."
    else
        status_ref=1
        clear_cache_dir
        # recreate the empty cache directory
        get_cache_name cache_name
        logd "Cache was incomplete. Recreated."
    fi

}

#==================================================================================================
# clear_cache_dir
#
# Removes the current cache directory including all files
#==================================================================================================
clear_cache_dir()
{
local cache_name

    get_cache_name cache_name

    rm -rf "$imdir/$cache_name"
}

# --- This is the end, my friend ------------------------------------------------------------------
