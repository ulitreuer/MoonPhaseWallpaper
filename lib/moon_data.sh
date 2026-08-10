#!/bin/bash
#
#==============================================================================
#  Project:     MoonPhaseWallpaper
#------------------------------------------------------------------------------
#  File:        moon_data.sh
#  Author:      Uli Treuer
#  Purpose:     Downloads and extracts moon data information from the NASA
#               web page for MoonPhaseWallpaper.
#
#  Copyright (c) 2026 Uli Treuer
#  License: MIT
#==============================================================================

#==================================================================================================
# read_moon_info
#
# Download the NASA moon information files for the current and previous year.
#==================================================================================================
read_moon_info()
{
local start end elapsed
local year
local mooninfo_name
local mooninfo_local
local mooninfo_url


    start=$(date +%s.%N)
    logv "In read_moon_info"

    for year in "${!nasa_url[@]}"; do
        mooninfo_name="mooninfo_$year.txt"
        mooninfo_local="$ddir/$mooninfo_name"

        logd "Mooninfo ($year):  $mooninfo_name"

        if [[ ! -e "$mooninfo_local" ]]; then
            mooninfo_url="${nasa_url[$year]}/$mooninfo_name"
            logv "downloading... $mooninfo_url"
            curl -L -o "$mooninfo_local" "$mooninfo_url" 2> /dev/null
        fi

        # The following creates indexed arrays with the year in the name:
        #   moondata_2025
        #   moondata_2026
        declare -n moondata="moondata_$year"
        mapfile -t moondata < "$mooninfo_local"
    done

    end=$(date +%s.%N)
    elapsed=$(awk "BEGIN { printf \"%.2f\", $end - $start }")
    logd "Function completed in ${elapsed} seconds."
    logv "================================================================================"
    logv " "
}


#==================================================================================================
# calculate_moon_metadata
#
# Calculate metadata for the next seven wallpaper images.
#==================================================================================================
calculate_moon_metadata()
{
local i
local selected_year
local num
local line_index
local raw_line1 raw_line2
local phase_loc
local dist_loc
local ra_loc
local dec_loc
local axisA_loc
local cycle_loc
local minute
local first_hour
local start end elapsed
local MOON_EVENT_LOOKBACK_HOURS=3   # calculate three hours into previous day to catch events near midnight
                                    # sufficient to detect all observed midnight crossings
readonly MOON_EVENT_LOOKBACK_HOURS
local selected_day
local selected_hour
local edge_day
local edge_hour
local next_year

    start=$(date +%s.%N)
    logv "In calculate_moon_metadata"
    for (( i=0; i<7; i++ )); do
        logv "Day $((i+1)) of 7"
        # date and time (in local time zone)
        datestamp+=("$(date -d "$i days ago" '+%d-%b-%Y')")
        timestamp+=("$(date -d "$i days ago" '+%H:%M')") # current local time
        logd "datestamp:     ${datestamp[i]}"
        logd "timestamp:     ${timestamp[i]}"

        minute="$(date --utc -d "$i days ago" '+%M')"

        selected_year=$(date --utc -d "$i days ago" +"%Y")
        calculate_hour_of_year "$i" num

        # read the corresponding line from the mooninfo file (1 line per hour of the year)
        line_index=$num     # mapfile uses zero-based indexing:
                            # index 0 = header
                            # index 1 = 01 Jan 00:00 UTC (moon.0001.tif)
                            # index 2 = 01 Jan 01:00 UTC (moon.0002.tif)
                            # ...

        declare -n moondata="moondata_$selected_year"
        raw_line1="${moondata[$line_index]}"

        # deal with an 'edge case': last hour of the year
        # Avoid trying to access a line in moondata which does not exist
        selected_day=$(date --utc -d "$i days ago" +%d-%m)
        selected_hour=$(date --utc -d "$i days ago" +%H)
        edge_day="31-12"
        edge_hour="23"

        if [[ $selected_day == $edge_day && $selected_hour == $edge_hour ]]; then
            next_year=$((selected_year + 1))

            declare -n moondata2="moondata_$next_year"
            raw_line2="${moondata2[1]}"
        else
            raw_line2="${moondata[$((line_index+1))]}"
        fi

        logd "Line index:    $line_index"
        logd "Raw Line:      $raw_line1"
        logd "Raw Line:      $raw_line2"

        interpolate_moondata_lines \
            "$raw_line1" \
            "$raw_line2" \
            "$minute" \
            phase_loc \
            dist_loc \
            ra_loc \
            dec_loc \
            axisA_loc \
            cycle_loc

            logd "phase_loc: $phase_loc"
            logd "dist_loc: $dist_loc"
            logd "ra_loc: $ra_loc"
            logd "dec_loc: $dec_loc"
            logd "axisA_loc: $axisA_loc"
            logd "cycle_loc: $cycle_loc"

        # Phase: illumination in %
        phase+=("$(printf "%.2f" "$phase_loc")")
        # distance: distance between earth and moon in km
        distance+=("$(printf "%.0f" "$dist_loc")")
        # RA: Right Ascension
        ra+=("$ra_loc")
        # DEC: Declination
        dec+=("$dec_loc")
        # AxisA: lunar north pole orientation
        axisA+=("$axisA_loc")
        # time into moon cycle
        cycle+=("$cycle_loc")

        if (( i == 0 )); then
            # first hour of this UTC day in the NASA file
            utc_doy=$(date --utc -d "$i days ago" +%j)
            first_hour=$(( (10#$utc_doy - 1) * 24 ))
            daily_data=""

            first_hour=$((first_hour-MOON_EVENT_LOOKBACK_HOURS))

            for ((hour=0; hour<24+MOON_EVENT_LOOKBACK_HOURS; hour++)); do
                line_index=$((first_hour+hour+1))
                daily_data+="${moondata[$line_index]}"$'\n'
            done
            result=$(
                calc_moonrise_set \
                    "$daily_data" \
                    "$selected_year" \
                    "$(date --utc -d "$i days ago" +"%H")" \
                    "$MOON_EVENT_LOOKBACK_HOURS"
            )

            IFS="|" read -r rise_minutes set_minutes status <<< "$result"

            # Convert UTC minutes since midnight to Unix timestamp
            rise_epoch=$(date -u -d "$(date -u +%F) 00:00 UTC +${rise_minutes} minutes" +%s)

            # Format that timestamp in the local timezone
            rise=$(date -d "@$rise_epoch" +"%H:%M")

            if [[ $rise_minutes -eq 0 ]]; then
                rise="--"
            fi
            moonrise+=("$rise")

            # Convert UTC minutes since midnight to Unix timestamp
            set_epoch=$(date -u -d "$(date -u +%F) 00:00 UTC +${set_minutes} minutes" +%s)

            # Format that timestamp in the local timezone
            set=$(date -d "@$set_epoch" +"%H:%M")

            if [[ $set_minutes -eq 0 ]]; then
                set="--"
            fi
            moonset+=("$set")

            moonstatus+=("$status")

            logd "--------------------------------------------"
            logd " "
            logd "Moonrise:      $rise"
            logd "Moonset:       $set"
            logd "Moonstatus:    $status"
        fi
        logv "--------------------------------------------"
        logv " "
    done
    end=$(date +%s.%N)
    elapsed=$(awk "BEGIN { printf \"%.2f\", $end - $start }")
    logd "Completed in ${elapsed} seconds."
    logv "================================================================================"
    logv " "
}

#==================================================================================================
# interpolate_moondata_lines
#
# Interpolate the NASA moondata between two consecutive line of the moondata file
# (passed as the first 2 arguments to the function) based on the number of minutes
# which have passed since the full hour. The interpolated values are returned to the calling
# function by reference.
#==================================================================================================
interpolate_moondata_lines()
{
local raw_line1="$1"
local raw_line2="$2"
local minute="$3"
local -n phase_interp_ref="$4"
local -n distance_interp_ref="$5"
local -n ra_interp_ref="$6"
local -n dec_interp_ref="$7"
local -n axisA_interp_ref="$8"
local -n cycle_interp_ref="$9"

local phase1 phase2
local distance1 distance2
local ra1 ra2
local dec1 dec2
local axisA1 axisA2
local age1 age2

    # parse the 2 individual lines
    parse_moondata_line "$raw_line1" phase1 distance1 ra1 dec1 axisA1 age1
    parse_moondata_line "$raw_line2" phase2 distance2 ra2 dec2 axisA2 age2

    # Interpolate the different values.
    # The interpolation method depends on the charateristics of the corresponding
    # values and their discontinuities
    phase_interp_ref=$(interpolate_scalar "$phase1" "$phase2" "$minute")
    distance_interp_ref=$(interpolate_scalar "$distance1" "$distance2" "$minute")
    ra_interp_ref=$(interpolate_ra "$ra1" "$ra2" "$minute")
    dec_interp_ref=$(interpolate_scalar "$dec1" "$dec2" "$minute")
    axisA_interp_ref=$(interpolate_axisA "$axisA1" "$axisA2" "$minute")
    cycle_interp_ref=$(interpolate_age "$age1" "$age2" "$minute")
}

#==================================================================================================
# parse_moondata_line
#
# Parse the relevant values from one line of the NASA moondata file.
# The extracted values are returned to the calling function by reference.
# #==================================================================================================
parse_moondata_line()
{
local raw_line="$1"
local -n phase_ref="$2"
local -n distance_ref="$3"
local -n ra_ref="$4"
local -n dec_ref="$5"
local -n axisA_ref="$6"
local -n age_ref="$7"

    # remove duplicate spaces as separators (if any) from the line
    # separate line elements into an array using ' ' as a separator
    read -ra linearray <<< "$(tr -s ' ' <<< "$raw_line")"

    # Phase: illumination in % (array element at index 5)
    phase_ref="${linearray[5]}"
    # distance: distance between earth and moon in km (array element at index 8)
    distance_ref="${linearray[8]}"
    # RA: Right Ascension (array element at index 9)
    ra_ref="${linearray[9]}"
    # DEC: Declination (array element at index 10)
    dec_ref="${linearray[10]}"
    # AxisA: lunar north pole orientation (array element at index 15)
    axisA_ref="${linearray[15]}"
    # Age: days in moon cycle so far (array element at index 6)
    age_ref=${linearray[6]}
}

#==================================================================================================
# interpolate_scalar
#
# Linear interpolation of 2 scalar values.
# The function assumes that the values are from a time series 60 minutes apart,
# and the argument minutes describes the number of minutes after the first value.
# Note: no data validation as the data is read from a static file.
#==================================================================================================
interpolate_scalar()
{
local val1="$1"
local val2="$2"
local minute="$3"

    awk \
        -v val1="$val1" \
        -v val2="$val2" \
        -v minute="$minute" '
    BEGIN {
        val1 += 0
        val2 += 0
        minute += 0

        fraction = minute / 60.0

        average = val1 + fraction * (val2 - val1)
        printf "%.4f\n", average
    }'

}

#==================================================================================================
# interpolate_age
#
# Linear interpolation of 2 age parameters from the moondata file. The age parameter describes
# the number of days since the beginning of the current lunar cycle.
# The function assumes that the values are from a time series 60 minutes apart,
# and the argument minutes describes the number of minutes after the first value.
# Note: no data validation as the data is read from a static file.
#
# The age parameter has a discontinuity at the end of each lunar cycle:
# [0..cycle length] => [0..cycle length] => ... (jumps cycle length => 0)
# #==================================================================================================
interpolate_age()
{
    local val1="$1"
    local val2="$2"
    local minute="$3"

    awk \
        -v val1="$val1" \
        -v val2="$val2" \
        -v minute="$minute" '
    BEGIN {
        val1 += 0
        val2 += 0
        minute += 0

        fraction = minute / 60.0

        if (val2 < val1) {
            cycle_length = val1 + val2
            val2 += cycle_length
        }

        average = val1 + fraction * (val2 - val1)

        if (cycle_length > 0 && average >= cycle_length)
            average -= cycle_length

        average *= 24 * 60 * 60

        d = int(average / 86400.0)
        h = int((average - d * 86400) / 3600)
        m = int((average - d * 86400 - h * 3600) / 60)

        printf "%2dd %2dh %2dm\n", d, h, m
    }'
}

#==================================================================================================
# interpolate_ra
#
# Linear interpolation of 2 ra parameters from the moondata file. The ra parameter describes
# the Right Ascension of the moon as read from the NASA moondata file.
# The function assumes that the values are from a time series 60 minutes apart,
# and the argument minutes describes the number of minutes after the first value.
# Note: no data validation as the data is read from a static file.
#
# The ra parameter has discontinuities as follows:
# [0..24] => [0..24] => [0..24] (jumps 24 => 0)
#==================================================================================================
interpolate_ra()
{
local val1="$1"
local val2="$2"
local minute="$3"

    awk \
        -v val1="$val1" \
        -v val2="$val2" \
        -v minute="$minute" '
    BEGIN {
        val1 += 0
        val2 += 0
        minute += 0

        fraction = minute / 60.0

        delta = val2 - val1

        if (delta > 12)
            delta -= 24
        else if (delta < -12)
            delta += 24

        average = val1 + fraction * delta

        if (average < 0)
            average += 24
        else if (average >= 24)
            average -= 24

        printf "%.4f\n", average
    }'
}

#==================================================================================================
# interpolate_axisA
#
# Linear interpolation of 2 axisA parameters from the moondata file. The axisA parameter describes
# the lunar north pole orientation as read from the NASA moondata file.
# The function assumes that the values are from a time series 60 minutes apart,
# and the argument minutes describes the number of minutes after the first value.
# Note: no data validation as the data is read from a static file.
#
# The axisA parameter has discontinuities as follows:
# [..360] => [0..~22] => [~22..0] => [360..~337] => [~337..360] => [0..~22] ...
# (jumps 360 => 0 and 0 => 360)
#==================================================================================================
interpolate_axisA()
{
local val1="$1"
local val2="$2"
local minute="$3"

    awk \
        -v val1="$val1" \
        -v val2="$val2" \
        -v minute="$minute" '
    BEGIN {
        val1 += 0
        val2 += 0
        minute += 0

        fraction = minute / 60.0

        delta = val2 - val1

        if (delta > 180)
            delta -= 360
        else if (delta < -180)
            delta += 360

        average = val1 + fraction * delta

        if (average < 0)
            average += 360
        else if (average >= 360)
            average -= 360

        printf "%.4f\n", average
    }'
}

#==================================================================================================
# calculate_hour_of_year
#
# Calculate the current hour of the year (either for current day or several days ago).
#==================================================================================================
calculate_hour_of_year()
{
local days_ago=$1
local -n num_ref=$2
local utc_doy utc_hour

    # calculate hour of the year
    utc_doy=$(date --utc -d "$days_ago days ago" +%j)
    utc_hour=$(date --utc -d "$days_ago days ago" +%H)
    num_ref=$(( (10#$utc_doy - 1) * 24 + 10#$utc_hour + 1 ))
    logd "Hour of Year:  $num_ref"
}

# --- This is the end, my friend ------------------------------------------------------------------
