#!/bin/bash
#
#==============================================================================
#  Project:     MoonPhaseWallpaper
#------------------------------------------------------------------------------
#  File:        kde_activity_tools.sh
#  Author:      Uli Treuer
#  Purpose:     Provides helper functions for managing KDE Activities.
#
#  Copyright (c) 2026 Uli Treuer
#  License: MIT
#==============================================================================

#==================================================================================================
# switch_to_activity
#
# Activate the Activity with the specified ID. Do nothing if this Activity is already active.
#==================================================================================================

#==================================================================================================
# activity_id_from_name
#
# Return the ID of the Activity with the specified name.
#==================================================================================================
activity_id_from_name()
{
local activity_name=$1
local -n activity_id_ref=$2

local -A activity_map

# num_activities is not used in this function.
# Serves only the purpose to satisfy the signature of create_activity_map
local num_activities

    logd "In activity_id_from_name"
    create_activity_map activity_map num_activities

    # Get ID of requested activity from activity_map
    activity_id_ref="${activity_map["$activity_name"]}"
    if [[ -z $activity_id_ref ]]; then
        logv "Error: Activity '$activity_name' not found. Exiting script now."
        exit 1
    fi
    logd "Using Activity ID: $activity_id_ref"
}

#==================================================================================================
# get_activity_bus
#
# Get the BUS variable required for most Activity-related function calls.
#==================================================================================================
get_activity_bus()
{
local -n bus_ref=$1
local current_user

    get_current_user current_user
    bus_ref="unix:path=/run/user/$(id -u "$current_user")/bus"
}

#==================================================================================================
# get_current_user
#
# Return the login name of the current user.
#==================================================================================================
get_current_user()
{
local -n user_ref=$1

    user_ref=$(id -un)
}

#==================================================================================================
# create_activity_map
#
# Create an associative array connecting Activity name and Activity ID for all Activities.
#==================================================================================================
create_activity_map()
{
local -n map_ref=$1
local -n num_activities_ref=$2

local BUS
local ACTIVITIES_RAW
local quoted
local count
local ACT_ID ACT_NAME ACT_DESC ACT_ICON

    logd "In create_activity_map"
    get_activity_bus BUS

    ACTIVITIES_RAW=$(
        DBUS_SESSION_BUS_ADDRESS="$BUS" \
        qdbus-qt6 --literal \
        org.kde.ActivityManager \
        /ActivityManager/Activities \
        ListActivitiesWithInformation)

    num_activities_ref=0
    while read -r block; do
        quoted=$(grep -oP '"[^"]*"' <<< "$block")

        count=0
        while read -r value; do
            value="${value%\"}"
            value="${value#\"}"

            case $count in
                0) ACT_ID=$value ;;
                1) ACT_NAME=$value ;;
                2) ACT_DESC=$value ;;
                3) ACT_ICON=$value ;;
            esac

            ((count++))
            ((count >= 4)) && break
        done <<< "$quoted"

        num_activities_ref=$((num_activities_ref+1))
        map_ref["$ACT_NAME"]="$ACT_ID"
        logd "Activity Name | ID: $ACT_NAME | $ACT_ID"

    done < <(grep -oP '\[Argument: \(ssssi\).*?\]' <<< "$ACTIVITIES_RAW")
}

#==================================================================================================
# get_num_screens
#
# Return the number of connected screens reported by KDE.
# Returns non-zero if PlasmaShell is not yet available.
#==================================================================================================
get_num_screens()
{
local -n num_screens_ref=$1
local BUS
local js_script

    logd "In get_num_screens"

    get_activity_bus BUS
    js_script=$(<"$wdir/lib/get_num_screens.js")

    num_screens_ref=$(
        DISPLAY=:0 \
        DBUS_SESSION_BUS_ADDRESS="$BUS" \
        qdbus-qt6 org.kde.plasmashell /PlasmaShell evaluateScript \
        "$js_script"
    ) || return 1
}

#==================================================================================================
# verify_screen
#
# Verify, whether a specific screen is currently connected and available.
# Input:
#      screen
#
# Output:
#      "1" if screen is available.
#      "0" if screen is not available
#==================================================================================================
verify_screen()
{
local test_screen=$1
local -n screen_available_ref=$2
local js_script
local BUS

    logd "In verify_screen"
    js_script=$(<"$wdir/lib/verify_screen.js")
    js_script="${js_script//__SCREEN__/$test_screen}"
    logd "Executing Plasma JavaScript verify availability of screen."
    get_activity_bus BUS
    screen_available_ref=$(
        DISPLAY=:0 \
        DBUS_SESSION_BUS_ADDRESS="$BUS" \
        qdbus-qt6 org.kde.plasmashell /PlasmaShell evaluateScript \
        "$js_script"
    )

    if (( screen_available_ref == 1 )); then
        logd "Screen $test_screen is available."
    else
        logd "Screen $test_screen is not connected."
    fi
}

# --- This is the end, my friend ------------------------------------------------------------------
