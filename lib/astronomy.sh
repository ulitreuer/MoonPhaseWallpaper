#!/bin/bash
#
#==============================================================================
#  Project:     MoonPhaseWallpaper
#------------------------------------------------------------------------------
#  File:        astronomy.sh
#  Author:      Uli Treuer
#  Purpose:     Provides astronomical calculations for MoonPhaseWallpaper.
#
#  Copyright (c) 2026 Uli Treuer
#  License: MIT
#==============================================================================

#==================================================================================================
# calc_moon_rotation
#
# Calculate the apparent orientation of the Moon for the configured observer location.
#
# Input:
#   $1  day
#   $2  month
#   $3  year
#   $4  hour (fractional, UTC)
#   $5  Right Ascension (hours)
#   $6  Declination (degrees)
#   $7  AxisA (degrees from NASA file)
#
# Output:
#   Rotation angle for ImageMagick
#==================================================================================================
calc_moon_rotation()
{
    local day="$1"
    local month="$2"
    local year="$3"
    local hour="$4"
    local ra="$5"
    local dec="$6"
    local axis="$7"
    local latitude longitude

    # Get observer location as defined by configuration.
    conf_get_observer_data latitude longitude

    awk \
        -i "$AWK_ASTRONOMY" \
        -v year="$year" \
        -v month="$month" \
        -v day="$day" \
        -v hour="$hour" \
        -v ra="$ra" \
        -v dec="$dec" \
        -v axis="$axis" \
        -v lat="$latitude" \
        -v lon="$longitude" '

    BEGIN {

        pi = atan2(0,-1)

        ###################################################################
        # Julian Date (JD)
        ###################################################################
        JD = calc_julian_date(hour,day,month,year)

        ###################################################################
        # Greenwich Mean Sidereal Time (GMST)
        ###################################################################
        GMST = calc_greenwich_mean_sidereal_time(JD)

        ###################################################################
        # Local Sidereal Time (LST)
        ###################################################################
        LST = calc_local_sidereal_time(GMST,lon)

        ###################################################################
        # Hour Angle
        ###################################################################
        H = calc_hour_angle(LST,ra)

        ###################################################################
        # Parallactic Angle
        ###################################################################
        q = calc_parallactic_angle(lat,dec,H)

        ###################################################################
        # Apparent Moon orientation
        #
        # P = AxisA from NASA
        # q = parallactic angle
        ###################################################################

        #
        # Apparent orientation of the lunar disk.
        #
        # AxisA is NASAs Position Angle (P) of the Moons north pole,
        # measured from celestial north.
        #
        # q is the observers parallactic angle.
        #
        # The apparent orientation of the Moon is:
        #
        #     P - q
        #
        # ImageMagick uses positive angles as counter-clockwise,
        # therefore the returned value is negated.
        rotation = axis - q

        rotation = normalize360(rotation)

        ###################################################################
        # ImageMagick:
        #
        # positive = counter-clockwise
        # negative = clockwise
        ###################################################################

        printf "%.2f\n", -rotation
    }'
}

#==================================================================================================
# calc_moonrise_set
#
# Calculates moonrise, moonset and current horizon status.
#
# Input:
#   $1  moondata for the current day
#   $2  year
#   $3  current UTC hour
#
# Output (stdout):
#
#   moonrise|moonset|status
#
# Example (moonrise and moonset are calculated in minutes after midnight):
#
#   744|900|Above horizon
#
# NOTE:
# This function evaluates the 24 UTC hours of the requested day.
# Moonrise and moonset events occurring shortly after midnight UTC are detected
# by extending the calculation window into the previous day.
#==================================================================================================
calc_moonrise_set()
{
    local data="$1"
    local year="$2"
    local current_hour="$3"
    local lookback_hours="$4"
    local latitude longitude

    # Get observer location as defined by configuration.
    conf_get_observer_data latitude longitude

    awk \
        -i "$AWK_ASTRONOMY" \
        -v year="$year" \
        -v lat="$latitude" \
        -v lon="$longitude" \
        -v lookback_hours="$lookback_hours" \
        -v current="$current_hour" '

    BEGIN{
        pi=atan2(0,-1)
        current += 0
    }

    {
        parse_moon_record()

        line_index = NR + 0

        ###################################################################
        # Julian Date (JD)
        ###################################################################
        JD = calc_julian_date(hour,day,month,year)

        ###################################################################
        # Greenwich Mean Sidereal Time (GMST)
        ###################################################################
        GMST = calc_greenwich_mean_sidereal_time(JD)

        ###################################################################
        # Local Sidereal Time (LST)
        ###################################################################
        LST = calc_local_sidereal_time(GMST,lon)

        ###################################################################
        # Hour Angle
        ###################################################################
        H = calc_hour_angle(LST,ra)

        ###################################################################
        # Altitude
        ###################################################################
        altitude[hour] = calc_altitude(lat,dec,H)
        altitude_index[line_index] = calc_altitude(lat,dec,H)
    }

    END{

        rise_minutes=0
        set_minutes=0

        if(altitude[current]>=0)
            status="Above horizon"
        else
            status="Below horizon"

        for(i=2;i<24+lookback_hours;i++){

            a1=altitude_index[i-1]
            a2=altitude_index[i]

            if(a1<0 && a2>=0){
                rise_minutes = linear_interpolation(a1,a2,i-lookback_hours-1)
            }

            if(a1>=0 && a2<0){
                set_minutes = linear_interpolation(a1,a2,i-lookback_hours-1)
            }
        }

        printf "%d|%d|%s\n", rise_minutes, set_minutes, status

    }' <<< "$data"
}

# --- This is the end, my friend ------------------------------------------------------------------
