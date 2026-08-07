#!/bin/bash
#
#==============================================================================
#  Project:     MoonPhaseWallpaper
#------------------------------------------------------------------------------
#  File:        manage_moon_images.sh
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
# download all moon images as defined before from the NASA web page in parallel
#==================================================================================================
download_moon_images()
{
local i
local start end elapsed
local cache_name

    start=$(date +%s.%N)
    logv "In download_moon_images"

    determine_moonimage_name_url
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
# get_cache_name
#
# Return the name of the cache folder to hold the downloaded moon images.
# It will be created if is does not exist yet.
#==================================================================================================
get_cache_name()
{
local -n cachename_ref=$1

    cachename_ref=$(date '+%Y%m%d%H')
    mkdir -p "$imdir"/"$cachename_ref"

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

        if [[ "$selected_year" -eq "$this_year" ]]; then
            moonimage_URL+=("$url_for_this_year/frames/3840x2160_16x9_30p/plain/${moonimage[i]}")  # URL for download
        else
            moonimage_URL+=("$url_for_prev_year/frames/3840x2160_16x9_30p/plain/${moonimage[i]}")  # URL for download
        fi
        logd "Moonimage:     ${moonimage[i]}"
        logd "Moonimage_URL: ${moonimage_URL[i]}"
        #----------------------------------------------------------------------------------------------
    done
}

# --- This is the end, my friend ------------------------------------------------------------------
