#!/bin/bash
#
#==============================================================================
#  Project:     MoonPhaseWallpaper
#------------------------------------------------------------------------------
#  File:        read_calculate_moon_data.sh
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

    start=$(date +%s.%N)
    logv "In read_moon_info"
    # "$url_for_this_year/mooninfo_$year.txt" (only if it does not exist locally)
    mooninfo_name_this_year=mooninfo_"$this_year".txt
    mooninfo_this_year="$ddir/$mooninfo_name_this_year"
    logd "Mooninfo (this year):  $mooninfo_this_year"
    if [[ ! -e "$mooninfo_this_year" ]]; then # local file does not exist
        logv "downloading..."
        mooninfo_URL="$url_for_this_year/$mooninfo_name_this_year"
        curl -L -o "$mooninfo_this_year" "$mooninfo_URL" 2> /dev/null
    fi

    # do the same for previous year
    mooninfo_name_prev_year=mooninfo_"$prev_year".txt
    mooninfo_prev_year="$ddir/$mooninfo_name_prev_year"
    logd "Mooninfo (prev year):  $mooninfo_prev_year"
    if [[ ! -e "$mooninfo_prev_year" ]]; then # local file does not exist
        logv "downloading..."
        mooninfo_URL="$url_for_prev_year/$mooninfo_name_prev_year"
        curl -L -o "$mooninfo_prev_year" "$mooninfo_URL" 2> /dev/null
    fi

    # load the files
    mapfile -t moondata_this_year < "$mooninfo_this_year"
    mapfile -t moondata_prev_year < "$mooninfo_prev_year"
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
local raw_line
local age age1
local t d h m
local tmp
local first_hour
local start end elapsed
local MOON_EVENT_LOOKBACK_HOURS=3   # calculate three hours into previous day to catch events near midnight
                                    # sufficient to detect all observed midnight crossings
readonly MOON_EVENT_LOOKBACK_HOURS

    start=$(date +%s.%N)
    logv "In calculate_moon_metadata"
    for (( i=0; i<7; i++ )); do
        logv "Day $((i+1)) of 7"
        # date and time (in local time zone)
        datestamp+=("$(date -d "$i days ago" '+%d-%b-%Y')")
        timestamp+=("$(date -d "$i days ago" '+%H:00')") # always ends with ':00' as there is one picture per hour.
        logd "datestamp:     ${datestamp[i]}"
        logd "timestamp:     ${timestamp[i]}"

        selected_year=$(date --utc -d "$i days ago" +"%Y")
        calculate_hour_of_year "$i" num

        # read the corresponding line from the mooninfo file (1 line per hour of the year)
        line_index=$num     # mapfile uses zero-based indexing:
                            # index 0 = header
                            # index 1 = 01 Jan 00:00 UTC (moon.0001.tif)
                            # index 2 = 01 Jan 01:00 UTC (moon.0002.tif)
                            # ...
        if [[ "$selected_year" -eq "$this_year" ]]; then
            raw_line="${moondata_this_year[$line_index]}"
        else
            raw_line="${moondata_prev_year[$line_index]}"
        fi
        logd "Line index:    $line_index"
        logd "Raw Line:      $raw_line"

        # remove duplicate spaces as separators (if any) from the line
        # separate line elements into an array using ' ' as a separator
        read -ra linearray <<< "$(tr -s ' ' <<< "$raw_line")"

        # Phase: illumination in % (array element at index 5)
        phase+=("${linearray[5]}")
        # distance: distance between earth and moon in km (array element at index 8)
        distance+=("${linearray[8]}")

        # RA: Right Ascension (array element at index 9)
        ra+=("${linearray[9]}")
        # DEC: Declination (array element at index 10)
        dec+=("${linearray[10]}")
        # AxisA: lunar north pole orientation (array element at index 15)
        axisA+=("${linearray[15]}")

        # Age: days in moon cycle so far (array element at index 6)
        age1=${linearray[6]}
        # Age is provided in days with 3 decimals. Remove the '.' from the string (which is
        # equivalent to multiplying the number by 1000) to allow calculations in the shell.
        age="${age1//.}"

        # convert age to total seconds (t), days (d), hours (h) and minutes (m)
        # divide by 1000 due to multiplying age by 1000 before
        # 10#$age ensures that even is age has a leading 0 (which causes bash to interpret
        # it as an octal number / base-8) age is forced to be interpreted as base-10 explicitly.
        t=$((10#"$age"*24*60*60/1000))
        d=$((t/86400))
        h=$((t/3600%24))
        m=$((t/60%60))
        # create a nice string
        tmp="${d}d ${h}h ${m}m"
        cycle+=("${tmp}")
        if (( i == 0 )); then
            # first hour of this UTC day in the NASA file
            utc_doy=$(date --utc -d "$i days ago" +%j)
            first_hour=$(( (10#$utc_doy - 1) * 24 ))
            daily_data=""

            first_hour=$((first_hour-MOON_EVENT_LOOKBACK_HOURS))

            for ((hour=0; hour<24+MOON_EVENT_LOOKBACK_HOURS; hour++)); do
                line_index=$((first_hour+hour+1))

                if [[ "$selected_year" -eq "$this_year" ]]; then
                    daily_data+="${moondata_this_year[$line_index]}"$'\n'
                else
                    daily_data+="${moondata_prev_year[$line_index]}"$'\n'
                fi
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
