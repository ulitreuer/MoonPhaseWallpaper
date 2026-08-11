#!/bin/bash
#
#==============================================================================
#  Project:     MoonPhaseWallpaper
#------------------------------------------------------------------------------
#  File:        image_processing.sh
#  Author:      Uli Treuer
#  Purpose:     Provides image processing and handling for MoonPhaseWallpaper.
#
#  Copyright (c) 2026 Uli Treuer
#  License: MIT
#==============================================================================

#==================================================================================================
# image_processing
#
# Create the final wallpaper image by combining today's large moon image with six smaller images
# from the preceding days.
# Output:
#       $1: the name of the created file
#==================================================================================================
image_processing()
{
local -n wallpaper_name_ref=$1
local i
local rotation
local new_x
local new_y
local new_pos
local y_pos
local text1
local text2
local text3
local text4
local text5
local text6
local text7
local text8
local start end elapsed
local -a rotation_hour_utc
local -a rotation_day_utc
local -a rotation_mon_utc
local -a rotation_year_utc
local utc_hour utc_min utc_sec
local cache_name

    start=$(date +%s.%N)
    logv "In image_processing"

    cd "$imdir" || {
        logv "ERROR: cannot enter $imdir" >&2
        exit 1
    }

    get_cache_name cache_name

    for (( i=0; i<7; i++ )); do
        read -r \
            rotation_day_utc[i] \
            rotation_mon_utc[i] \
            rotation_year_utc[i] \
            utc_hour utc_min utc_sec <<<"$(
                date --utc -d "$i days ago" '+%d %m %Y %H %M %S'
            )"
        rotation_hour_utc+=("$(awk \
            -v h="$utc_hour" \
            -v m="$utc_min" \
            -v s="$utc_sec" \
            'BEGIN { printf "%.8f", h + m/60 + s/3600 }')")

        logd "Day $i"
        logd "Datestamp:      ${rotation_day_utc[i]}-${rotation_mon_utc[i]}-${rotation_year_utc[i]}"
        logd "Rotation Hour:  ${rotation_hour_utc[i]}"
    done

    y_pos=1025
    for (( i=0; i<7; i++ )); do
        rotation=$(calc_moon_rotation \
            "${rotation_day_utc[i]}" \
            "${rotation_mon_utc[i]}" \
            "${rotation_year_utc[i]}" \
            "${rotation_hour_utc[i]}" \
            "${ra[i]}" \
            "${dec[i]}" \
            "${axisA[i]}")
        logd "Rotation Angle: ${rotation}"

        if (( i == 0 )); then
            new_x=1920
            new_y=1080
            new_pos="+0+0"

            # Build the caption strings.
            text1="Date:                ${datestamp[0]}"
            text2="Status Time:         ${timestamp[0]}"
            if [[ "${moonrise[0]}" == "--" || "${moonset[0]}" == "--" ]]; then
                text3="Moonrise:            ${moonrise[0]}"
                text4="Moonset:             ${moonset[0]}"
            elif [[ "${moonset[0]}" < "${moonrise[0]}" ]]; then
                text3="Moonset:             ${moonset[0]}"
                text4="Moonrise:            ${moonrise[0]}"
            else
                text3="Moonrise:            ${moonrise[0]}"
                text4="Moonset:             ${moonset[0]}"
            fi
            text5="Status:              ${moonstatus[0]}"
            text6="Visibility:          ${phase[0]}%"
            text7="Days into Cycle:     ${cycle[0]}"
            text8="Distance from Earth: ${distance[0]} km"
        else
            new_x=267
            new_y=160
            new_pos="+30+0"
            y_pos=$((y_pos-160))

            # build the strings for the image caption
            text1="${datestamp[i]}"
            text2="${timestamp[i]}"
            text3="${phase[i]}%"
            text4="${cycle[i]}"
            text5="${distance[i]} km"
        fi

        if (( i == 0 )); then
            logv "Processing big image $((i+1))"
            logd "Image: $cache_name/${moonimage[i]}"
            # Step 1: resize star background image
            # Step 2: resize downloaded image
            # Step 3: rotate downloaded image according to observer position
            # Step 4: increase brightness of rotated image to 110%
            # Step 5: overlay downloaded and rotated image on top of star background
            # Step 6: create semi-transparent mask with blurred, rounded edges as background for the captions
            # Step 7: overlay the mask on top of the image created so far
            # Step 8: add the captions defined before to the image (inside the rectangle defined by the mask)
            magick \
                stars_background.tif \
                    -resize "${new_x}x${new_y}" \
                \( "$cache_name"/"${moonimage[i]}" \
                    -resize "${new_x}x${new_y}" \
                    -background none \
                    -rotate "$rotation" \
                    +repage \
                    -gravity center \
                    -crop "${new_x}x${new_y}+0+0" \
                    +repage \
                    -modulate 110x100 \
                \) \
                    -gravity northwest \
                    -geometry "$new_pos" \
                    -composite \
                \( -size 1920x1080 xc:none \
                    -fill "#00000080" \
                    -draw "roundrectangle 1560,800 1880,1040 20,20" \
                    -gaussian-blur 10x10 \
                \) \
                -composite \
                -font noto-sans-mono-semicondensed-bold \
                -fill '#ffb600' \
                -pointsize 15 \
                -draw "text 1525,825 '$text1'" \
                -draw "text 1525,850 '$text2'" \
                -draw "text 1525,875 '$text3'" \
                -draw "text 1525,900 '$text4'" \
                -draw "text 1525,925 '$text5'" \
                -draw "text 1525,950 '$text6'" \
                -draw "text 1525,975 '$text7'" \
                -draw "text 1525,1000 '$text8'" \
                final.tif

        else
            logv "Processing small image $((i+1))"
            logd "Image: $cache_name/${moonimage[i]}"
            # Step 1: resize star background image
            # Step 2: resize downloaded image
            # Step 3: rotate downloaded image according to observer position
            # Step 4: increase brightness of rotated image to 110%
            # Step 5: overlay downloaded and rotated image on top of star background
            # Step 6: add the captions defined before to the image
            # Step 7: create a border around the inserted image
            # Step 8: overlay small picture on top of background
            magick final.tif \
                \( \
                    stars_background.tif \
                        -resize "${new_x}x${new_y}" \
                    \( "$cache_name"/"${moonimage[i]}" \
                        -resize "${new_x}x${new_y}" \
                        -background none \
                        -rotate "$rotation" \
                        +repage \
                        -gravity center \
                        -crop "${new_x}x${new_y}+0+0" \
                        +repage \
                        -modulate 110x100 \
                    \) \
                    -gravity northwest \
                    -geometry "$new_pos" \
                    -composite \
                    -font noto-sans-mono-semicondensed-bold \
                    -fill '#ffb600' \
                    -pointsize 10 \
                    -draw "text 7,15 '$text1'" \
                    -draw "text 7,30 '$text2'" \
                    -draw "text 7,45 '$text3'" \
                    -draw "text 7,60 '$text4'" \
                    -draw "text 7,75 '$text5'" \
                    -bordercolor '#222222' \
                    -border 1 \
                \) \
                -geometry "+75+${y_pos}" \
                -composite \
                final.tif
        fi
    done

    # create a unique wallpaper name current including date and time
    create_wallpaper_name wallpaper_name_ref

    # Delete all old wallpapers
     rm -f moon_wallpaper_*.png

    # Convert the final image to PNG to reduce file size.
    magick final.tif $wallpaper_name_ref

    clear_image_dir

    end=$(date +%s.%N)
    elapsed=$(awk "BEGIN { printf \"%.2f\", $end - $start }")
    logd "Completed in ${elapsed} seconds."
    logv "================================================================================"
    logv " "
}


#==================================================================================================
# create_wallpaper_name
#
# Create a unique name for the generated wallpaper created froma basename
# followed by current date and time
#==================================================================================================
create_wallpaper_name()
{
local -n name_ref=$1
local timestamp

    timestamp="$(date '+%Y%m%d_%H%M%S')"
    name_ref="moon_wallpaper_$timestamp.png"
}

# --- This is the end, my friend ------------------------------------------------------------------
