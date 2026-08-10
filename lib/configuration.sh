#!/bin/bash
#
#==============================================================================
#  Project:     MoonPhaseWallpaper
#------------------------------------------------------------------------------
#  File:        configuration.sh
#  Author:      Uli Treuer
#  Purpose:     Manages configuration information for MoonPhaseWallpaper.
#
#  Copyright (c) 2026 Uli Treuer
#  License: MIT
#==============================================================================

# Indicate whether the configuration files have already been read.
CONFIGURATION_FILE_READ=false
CONFIGURATION_FILE_DEFAULT_READ=false

#==================================================================================================
# read_configuration
#
# Load the configuration containing all user-defined data
# - Target activity and screen for generated wallpaper
# - observer coordinates
# - specification for NASA data from NASA website
# Return values:
#       0 => configuration successfully loaded
#       1 => configuration file missing
#       2 => configuration file is invalid
#==================================================================================================
read_configuration()
{
local year
local start end elapsed

    if $CONFIGURATION_FILE_READ; then
        return 0 # configuration file was loaded before already - no need to reload it
    fi
    start=$(date +%s.%N)
    logv "In read_configuration"
    # If configuration file exists, then read it
    if [[ -f "$configfile" ]]; then
        if ! source "$configfile"; then
            return 2
        fi
        CONFIGURATION_FILE_READ=true
        load_nasa_data_sources || return 2
        validate_configuration || return 2

        logd "CONFIGURATION_VERSION:      $CONFIGURATION_VERSION"
        logd "ACTIVITY_NAME:              $ACTIVITY_NAME"
        logd "ACTIVITY_ID:                $ACTIVITY_ID"
        logd "SCREEN:                     $SCREEN"
        logd "OBSERVER_LATITUDE:          $OBSERVER_LATITUDE"
        logd "OBSERVER_LONGITUDE:         $OBSERVER_LONGITUDE"
        for year in "${!nasa_url[@]}"; do
            logd "NASA_URL: $year ${nasa_url[$year]}"
        done
    else
        return 1
    fi

    end=$(date +%s.%N)
    elapsed=$(awk "BEGIN { printf \"%.2f\", $end - $start }")
    logd "Completed in ${elapsed} seconds."
    logv "================================================================================"
    logv " "
    return 0
}

#==================================================================================================
# load_nasa_data_sources
#
# Processes the NASA entries from the configuration file and stores them in an associative array.
# The plausibility of the NASA URLs is checked.
#
# Return values:
#       0 => valid
#       1 => invalid
#==================================================================================================
load_nasa_data_sources()
{
    local year_var
    local url_var
    local id
    local -a nasa_years
    local -a nasa_urls
    local i

    # build a lookup table
    for year_var in "${!NASA_YEAR_@}"; do
        id="${year_var#NASA_YEAR_}"
        nasa_years+=("${!year_var}")

        url_var="NASA_SVS_URL_$id"
        nasa_urls+=("${!url_var}")
    done
    validate_nasa_configuration nasa_years nasa_urls || {
        nasa_configuration_error
        return 1
    }
    # fill the final associate array for the URLs after validation
    for i in "${!nasa_years[@]}"; do
       nasa_url["${nasa_years[$i]}"]="${nasa_urls[$i]}"
    done
}

#==================================================================================================
# validate_configuration
#
# Validate the configuration as sourced from the configuration file.
#
# Return values:
#       0 => valid
#       1 => invalid
#==================================================================================================
validate_configuration()
{
    validate_configuration_version "$CONFIGURATION_VERSION" || {
        configuration_error "Invalid CONFIGURATION_VERSION in file" "$configfile"
        return 2
    }
    validate_activity_name         "$ACTIVITY_NAME" || {
        configuration_error "Invalid ACTIVITY_NAME in file" "$configfile"
        return 2
    }
    validate_activity_id "$ACTIVITY_ID" || {
        configuration_error "Invalid ACTIVITY_ID in file" "$configfile"
        return 2
    }
    validate_screen_setting       "$SCREEN" || {
        configuration_error "Invalid SCREEN in file" "$configfile"
        return 2
    }
    validate_latitude              "$OBSERVER_LATITUDE" || {
        configuration_error "Invalid OBSERVER_LATITUDE in file" "$configfile"
        return 2
    }
    validate_longitude             "$OBSERVER_LONGITUDE" || {
        configuration_error "Invalid OBSERVER_LONGITUDE in file" "$configfile"
        return 2
    }

    return 0
}

#==================================================================================================
# validate_configuration_version
#
# Verify the configuration version as read from the configuration file.
# Current configuration version: 1
#
# Return values:
#       0 => valid
#       1 => invalid
#==================================================================================================
validate_configuration_version()
{
local conf_version="$1"

    [[ -n $conf_version ]] || return 1
    validate_positive_integer_incl_zero "$conf_version" || return 1
    (( $conf_version == 1 )) || return 1

    return 0
}

#==================================================================================================
# validate_activity_name
#
# Verify the activity name as read from the configuration file.
# Verify non-empty only as renaming an activity is perfectly fine
# and will not affect the functionality.
#
# Return values:
#       0 => valid
#       1 => invalid
#==================================================================================================
validate_activity_name()
{
local act_name="$1"

    [[ -n $act_name ]] || return 1
    return 0
}

#==================================================================================================
# validate_activity_id
#
# Verify the activity id as read from the configuration file does still exist
# and has not been deleted.
#
# Return values:
#       0 => valid
#       1 => invalid
#==================================================================================================
validate_activity_id()
{
local act_id="$1"
local num_activities
local act_name
declare -A activity_map

    [[ -n $act_id ]] || return 1

    create_activity_map activity_map num_activities

    for act_name in "${!activity_map[@]}"; do
        [[ ${activity_map[$act_name]} == "$act_id" ]] && return 0
    done

    return 1
}

#==================================================================================================
# validate_screen_setting
#
# Verify that the configured screen setting is syntactically valid.
#
# Return values:
#       0 => valid
#       1 => invalid
#==================================================================================================
validate_screen_setting()
{
local screen="$1"

    [[ -n $screen ]] || return 1
    validate_positive_integer_incl_zero "$screen" || return 1

    return 0
}

#==================================================================================================
# validate_latitude
#
# Verify that latitude is a valid decimal coordinate and is in the range [-90..90].
#
# Return values:
#       0 => valid
#       1 => invalid
#==================================================================================================
validate_latitude()
{
local lat="$1"

    [[ -n $lat ]] || return 1
    validate_decimal "$lat" || return 1

    awk -v lat="$lat" '
        BEGIN {
            exit !(lat >= -90  && lat <= 90)
        }'
    return $?
}

#==================================================================================================
# validate_longitude
#
# Verify that longitude is a valid decimal coordinate and is in the range [-180..180].
#
# Return values:
#       0 => valid
#       1 => invalid
#==================================================================================================
validate_longitude()
{
local lon="$1"

    [[ -n $lon ]] || return 1
    validate_decimal "$lon" || return 1

    awk -v lon="$lon" '
        BEGIN {
            exit !(lon >= -180 && lon <= 180)
        }'
    return $?
}

#==================================================================================================
# validate_observer_location
#
# Verify that latitude and longitude are valid decimal coordinates.
#
# Return values:
#       0 => valid
#       1 => invalid
#==================================================================================================
validate_observer_location()
{
local lat="$1"
local lon="$2"

    validate_latitude "$lat"  || return 1
    validate_longitude "$lon" || return 1

    return 0
}

#==================================================================================================
# validate_nasa_configuration
#
# Verify that NASA years as loaded from the configuration file exist and contain the expected
# values for the current and previous year (and next year for the edge case Dec. 31).
# Verify also that the file does not contain duplicate entries for the years relevant for the
# operation of the script.
# Correctness of URLs cannot be verified as NASA does not follow a known logic.
# Only plausibility checks are possible.
#
# Return values:
#       0 => valid
#       1 => invalid
#==================================================================================================
validate_nasa_configuration()
{
local -n year_array="$1"
local -n url_array="$2"
local curr_year
local prev_year
local next_year
local today
local edge_day
local i
local year
local url

local curr_year_specified=false
local prev_year_specified=false
local next_year_required=false

local next_year_specified

local curr_year_count=0
local prev_year_count=0
local next_year_count=0

    curr_year=$(date --utc +%Y)
    prev_year=$((curr_year - 1))
    next_year=$((curr_year + 1))

    today=$(date --utc +%d-%m)
    edge_day="31-12"
    if [[ $today == $edge_day ]]; then
        # entry for next year is needed
        next_year_required=true
    fi

    for i in "${!year_array[@]}"; do
        year=${year_array[$i]}
        url=${url_array[$i]}

        if [[ $year == $curr_year ]]; then
            curr_year_specified=true
            validate_nasa_url_format "$url" || {
                configuration_error "Invalid NASA configuration in file" "$configfile"
                return 2
            }
        elif [[ $year == $prev_year ]]; then
            prev_year_specified=true
            validate_nasa_url_format "$url" || {
                configuration_error "Invalid NASA configuration in file" "$configfile"
                return 2
            }
        elif [[ $year == $next_year ]]; then
            if $next_year_required; then
                next_year_specified=true
                validate_nasa_url_format "$url" || {
                    configuration_error "Invalid NASA configuration in file" "$configfile"
                    return 2
                }
            else
                unset 'year_array[$i]'
                unset 'url_array[$i]'
            fi
        else
            unset 'year_array[$i]'
            unset 'url_array[$i]'
        fi
    done

    # now check for duplicate years
    for i in "${!year_array[@]}"; do
        year=${year_array[$i]}
        url=${url_array[$i]}

        if [[ $year == $curr_year ]]; then
            ((++curr_year_count))
        elif [[ $year == $prev_year ]]; then
            ((++prev_year_count))
        elif [[ $year == $next_year ]]; then
            if $next_year_required; then
                ((++next_year_count))
            fi
        fi
    done

    [[ $curr_year_specified == true ]] || return 1
    [[ $prev_year_specified == true ]] || return 1

    if $next_year_required && ! $next_year_specified; then
        return 1
    fi

    (( curr_year_count > 1 )) && return 1
    (( prev_year_count > 1 )) && return 1

    if $next_year_required ; then
        (( next_year_count != 1 )) && return 1
    fi

    return 0
}

#==================================================================================================
# validate_nasa_year
#
# Verify that an individual NASA year as loaded from the configuration file exists
# and is a positive integer.
#
# Return values:
#       0 => valid
#       1 => invalid
#==================================================================================================
validate_nasa_year()
{
local year="$1"

    [[ -n $year ]] || return 1
    validate_positive_integer_incl_zero "$year" || return 1

    return 0
}

#==================================================================================================
# validate_nasa_url_format
#
# Verify that an individual NASA URL as loaded from the configuration file exists
# and that the URL starts correctly.
# The complete correctness of the URL cannot be verified as NASA does not follow a known logic.
# Only a plausibility check is possible.
#
# Return values:
#       0 => valid
#       1 => invalid
#==================================================================================================
validate_nasa_url_format()
{
local url="$1"

    [[ -n $url ]] || return 1
    [[ $url =~ ^https://svs\.gsfc\.nasa\.gov/vis/ ]] || return 1
    return 0
}

#==================================================================================================
# nasa_configuration_error
#
# Inform the user if there are inconsistencies for the years defined in the NASA section
# of the configuration and instruct him to update the configuration.
#
# Return values:
#       0 => valid
#       1 => invalid
#==================================================================================================
nasa_configuration_error()
{
    echo "The NASA configuration appears to be out of date or inconsistent."
    echo
    echo "Please update the NASA configuration section in:"
    echo "    $configfile"
}

#==================================================================================================
# validate_decimal
#
# Verify that passed argument is a valid decimal number.
#
# Return values:
#       0 => valid
#       1 => invalid
#==================================================================================================
validate_decimal()
{
local value="$1"

    [[ -n $value ]] || return 1
    [[ $value =~ ^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$ ]] || return 1
    return 0
}

#==================================================================================================
# validate_integer
#
# Verify that passed argument is a valid integer number.
#
# Return values:
#       0 => valid
#       1 => invalid
#==================================================================================================
validate_integer()
{
local value="$1"

    [[ -n $value ]] || return 1
    [[ $value =~ ^[+-]?[0-9]+$ ]] || return 1
    return 0
}

#==================================================================================================
# validate_positive_integer_incl_zero
#
# Verify that passed argument is a valid positive integer number (including 0).
#
# Return values:
#       0 => valid
#       1 => invalid
#==================================================================================================
validate_positive_integer_incl_zero()
{
local value="$1"

    [[ -n $value ]] || return 1
    [[ $value =~ ^[0-9]+$ ]] || return 1
    return 0
}

#==================================================================================================
# validate_positive_integer
#
# Verify that passed argument is a valid positive integer number (excluding 0).
#
# Return values:
#       0 => valid
#       1 => invalid
#==================================================================================================
validate_positive_integer()
{
local value="$1"

    [[ -n $value ]] || return 1
    [[ $value =~ ^[1-9][0-9]*$ ]] || return 1
    return 0
}

#==================================================================================================
# read_default_configuration
#
# Load the default configuration file as a fallback for the user-specific configuration file.
# Return values:
#       0 => default configuration successfully loaded
#       1 => default file missing
#       2 => default file is invalid
#==================================================================================================
read_default_configuration()
{
local start end elapsed

    if $CONFIGURATION_FILE_DEFAULT_READ; then
        return 0 # default configuration file was loaded before already - no need to reload it
    fi
    start=$(date +%s.%N)
    logv "In read_default_configuration"
    # If configuration file exists, then read it
    if [[ -f "$configfile_default" ]]; then
        if ! source "$configfile_default"; then
            return 2
        fi
        CONFIGURATION_FILE_DEFAULT_READ=true
        logd "DEFAULT_CONFIGURATION_VERSION:      $CONFIGURATION_VERSION"
        logd "DEFAULT_ACTIVITY_NAME:              $ACTIVITY_NAME"
        logd "DEFAULT_ACTIVITY_ID:                $ACTIVITY_ID"
        logd "DEFAULT_SCREEN:                     $SCREEN"
        logd "DEFAULT_OBSERVER_LATITUDE:          $OBSERVER_LATITUDE"
        logd "DEFAULT_OBSERVER_LONGITUDE:         $OBSERVER_LONGITUDE"
        logd "DEFAULT_NASA_CURR_YEAR:             $NASA_CURR_YEAR"
        logd "DEFAULT_NASA_SVS_URL_CURRENT_YEAR:  $NASA_SVS_URL_CURRENT_YEAR"
        logd "DEFAULT_NASA_PREV_YEAR:             $NASA_PREV_YEAR"
        logd "DEFAULT_NASA_SVS_URL_PREVIOUS_YEAR: $NASA_SVS_URL_PREVIOUS_YEAR"
    else
        return 1
    fi

    end=$(date +%s.%N)
    elapsed=$(awk "BEGIN { printf \"%.2f\", $end - $start }")
    logd "Completed in ${elapsed} seconds."
    logv "================================================================================"
    logv " "
    return 0
}

#==================================================================================================
# conf_get_target_activity
#
# Returns by reference the target activity ID and target screen as loaded from configuration file
#==================================================================================================
conf_get_target_activity()
{
local -n activity_id_ref=$1
local -n screen_ref=$2

    read_configuration
    activity_id_ref=$ACTIVITY_ID
    screen_ref=$SCREEN
}

#==================================================================================================
# conf_get_observer_data
#
# Returns by reference the observer latitude and longitude as loaded from configuration file
#==================================================================================================
conf_get_observer_data()
{
local -n latitude_ref=$1
local -n longitude_ref=$2

    read_configuration
    latitude_ref=$OBSERVER_LATITUDE
    longitude_ref=$OBSERVER_LONGITUDE
}

#==================================================================================================
# conf_write_configuration
#
# Make the configuration as determined by the configuration wizard persistent
# by writing it to the config file
#==================================================================================================
conf_write_configuration()
{
cat >"$configfile" <<EOF
#==============================================================================
# MoonPhaseWallpaper configuration
#
# This file is created and maintained by MoonPhaseWallpaper.
# You may edit it manually if necessary. When doing so make sure that the
# variable assignments must not contain spaces around '='.
#       LABEL=value     => Good
#       LABEL = value   => BAD!!
#==============================================================================

# Configuration version (do not change manually!)
CONFIGURATION_VERSION=1

# KDE Activity
# Defines the Activity (identified by its ID) and screen (0, 1, 2, ...)
# where the generated MoonPhaseWallpaper will be shown.
ACTIVITY_NAME="$wizard_activity_name"
ACTIVITY_ID="$wizard_activity_id"
SCREEN="$wizard_screen"

# Observer location (decimal degrees)
# Latitude:
#       > 0 => north of equator
#       < 0 => south of equator
# Longitude:
#       > 0 => east of Greenwich
#       < 0 => west of Greenwich
OBSERVER_LATITUDE="$wizard_latitude"
OBSERVER_LONGITUDE="$wizard_longitude"

# NASA data
# Defines the URLs from which the moon images and data will be downloaded.
# This section must be updated at the end of each year for the following year
# (as the URL on the NASA site does not follow any systematic convention).
# Check the API view on the NASA page for the URL for the current and
# potentially next year.
# Navigate to https://svs.gsfc.nasa.gov/ and search for 'libration'
# using the search field in the upper right corner of the NASA web page.
# This is the NASA page with the data for 2026: https://svs.gsfc.nasa.gov/5587/
# This is the NASA page with the data for 2025: https://svs.gsfc.nasa.gov/5415/
NASA_CURR_YEAR="$wizard_default_curr_year"
NASA_SVS_URL_CURRENT_YEAR="$wizard_default_curr_url"
NASA_PREV_YEAR="$wizard_default_prev_year"
NASA_SVS_URL_PREVIOUS_YEAR="$wizard_default_prev_url"

EOF
}

#==================================================================================================
# fatal_configuration_error
#
# Closing the application after notifying the user of a fatal configuration error
#==================================================================================================
fatal_configuration_error()
{
    loge " "
    loge "Fatal configuration error: $1"
    loge "    $2"
    loge "Exiting."
    exit 1
}

#==================================================================================================
# configuration_error
#
# Report a configuration error without terminating the application.
#
# Return values:
#       2 => configuration invalid
#==================================================================================================
configuration_error()
{
    loge " "
    loge "Configuration error: $1"
    loge "    $2"
    return 2
}

# --- This is the end, my friend ------------------------------------------------------------------
