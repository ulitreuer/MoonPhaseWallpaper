#!/bin/bash
#
#==============================================================================
#  Project:     MoonPhaseWallpaper
#------------------------------------------------------------------------------
#  File:        directories.sh
#  Author:      Uli Treuer
#  Purpose:     Defines working directories for MoonPhaseWallpaper.
#
#  Copyright (c) 2026 Uli Treuer
#  License: MIT
#==============================================================================

#==================================================================================================
# set_directories
#
# Initialize all application directories and file paths.
#==================================================================================================
set_directories()
{
local start end elapsed

    start=$(date +%s.%N)
    logv "In set_directories"
    # Define application directories
    readonly imdir="$wdir/images"               # image directory
    mkdir -p "$imdir"
    readonly ddir="$wdir/data"                  # data directory
    mkdir -p "$ddir"

    readonly configdir="$wdir/configuration"    # configuration directory
    mkdir -p "$configdir"
    readonly configfile="$configdir/moon_wallpaper.conf"
    readonly configfile_default="$configdir/moon_wallpaper.conf.default"

    readonly AWK_ASTRONOMY="$wdir/lib/astronomy.awk"

    logd "wdir:      $wdir"
    logd "imdir:     $imdir"
    logd "ddir:      $ddir"
    logd "configdir:        $configdir"
    logd "configfile:       $configfile"
    logd "default config:   $configfile_default"
    logd "AWKlib:           $AWK_ASTRONOMY"

    end=$(date +%s.%N)
    elapsed=$(awk "BEGIN { printf \"%.2f\", $end - $start }")
    logd "Completed in ${elapsed} seconds."
    logv "================================================================================"
    logv " "
}

# --- This is the end, my friend ------------------------------------------------------------------
