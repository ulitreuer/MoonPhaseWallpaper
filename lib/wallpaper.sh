#!/bin/bash
#
#==============================================================================
#  Project:     MoonPhaseWallpaper
#------------------------------------------------------------------------------
#  File:        wallpaper.sh
#  Author:      Uli Treuer
#  Purpose:     Updates the KDE wallpaper using the generated image.
#
#  Copyright (c) 2026 Uli Treuer
#  License: MIT
#==============================================================================

#==================================================================================================
# set_wallpaper
#
# Set the generated image as the wallpaper for the configured Activity and Screen
# using Plasma 6 functionality.
#==================================================================================================
set_wallpaper()
{
local wallpaper_name=$1
local BUS
local target_activity_id target_screen
local wallpaper_replaced
local wallpaper_output
local wallpaper_image js_script
local start end elapsed

    start=$(date +%s.%N)
    logv "In set_wallpaper"
    logd "Name of new wallpaper: $wallpaper_name"

    # Get the configured target activity and screen
    conf_get_target_activity target_activity_id target_screen

    # Set wallpaper on the configured Activity and screen
    wallpaper_image="$wdir/images/$wallpaper_name"

    js_script=$(<"$wdir/lib/set_wallpaper.js")
    js_script="${js_script//__SCREEN__/$target_screen}"
    js_script="${js_script//__WALLPAPER_IMAGE__/$wallpaper_image}"
    js_script="${js_script//__ACTIVITY__/$target_activity_id}"

    logd "Executing Plasma JavaScript to update wallpaper."
    get_activity_bus BUS
    wallpaper_output=$(
        DISPLAY=:0 \
        DBUS_SESSION_BUS_ADDRESS="$BUS" \
        qdbus-qt6 org.kde.plasmashell /PlasmaShell evaluateScript \
        "$js_script"
    )
    logd "$wallpaper_output"
    wallpaper_replaced="${wallpaper_output##*__RESULT__:}"

    if (( wallpaper_replaced == 1 )); then
        logv "Wallpaper replaced."
    else
        loge "Wallpaper could not be replaced."
        loge "The configured screen is not connected."
        loge "A 'Default' wallpaper will be used."
    fi

    end=$(date +%s.%N)
    elapsed=$(awk "BEGIN { printf \"%.2f\", $end - $start }")
    logd "Completed in ${elapsed} seconds."
    logv "================================================================================"
    logv " "
}


# --- This is the end, my friend ------------------------------------------------------------------
