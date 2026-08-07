#==============================================================================
#  Project:     MoonPhaseWallpaper
#------------------------------------------------------------------------------
#  File:        astronomy.awk
#  Author:      Uli Treuer
#  Purpose:     Provides common astronomical AWK functions used by multiple
#               Bash functions.
#
#  Copyright (c) 2026 Uli Treuer
#  License: MIT
#==============================================================================

###############################################################################
# calc_julian_date
# Calculate the Julian Date (JD)
###############################################################################
function calc_julian_date(hour,day,month,year,     A,B)
{
    if (month <= 2) {
        year--
        month += 12
    }

    A = int(year/100)
    B = 2 - A + int(A/4)

    return int(365.25*(year+4716)) + int(30.6001*(month+1)) + day + B - 1524.5 + hour/24.0
}

###############################################################################
# calc_greenwich_mean_sidereal_time
# Calculate the Greenwich Mean Sidereal Time (GMST)
###############################################################################
function calc_greenwich_mean_sidereal_time(JD,     tmp,T)
{
    T = (JD-2451545.0)/36525.0
    tmp = 280.46061837 + 360.98564736629*(JD-2451545.0) + 0.000387933*T*T - T*T*T/38710000.0

    return normalize360(tmp)
}

###############################################################################
# calc_local_sidereal_time
# Calculate the Local Sidereal Time (LST)
###############################################################################
function calc_local_sidereal_time(GMST,longitude)
{
    return normalize360(GMST + longitude)
}

###############################################################################
# calc_hour_angle
# Calculate the Hour Angle (H)
###############################################################################
function calc_hour_angle(LST,ra)
{
    return normalize180(LST - ra * 15.0)
}

###############################################################################
# calc_altitude
# Calculate the Altitude
###############################################################################
function calc_altitude(lat,dec,H,      s)
{
    s = sin(deg2rad(lat))*sin(deg2rad(dec)) + cos(deg2rad(lat))*cos(deg2rad(dec))*cos(deg2rad(H))

    # guard against tiny floating-point errors
    if (s > 1)  s = 1
    if (s < -1) s = -1

    return rad2deg(atan2(s, sqrt(1 - s*s)))
}

###############################################################################
# calc_parallactic_angle
# Calculate the Parallactic Angle
###############################################################################
function calc_parallactic_angle(lat,dec,H,      Hrad,decrad,latrad,qloc)
{
    Hrad = deg2rad(H)
    decrad = deg2rad(dec)
    latrad = deg2rad(lat)

    qloc = atan2(sin(Hrad), (sin(latrad) / cos(latrad)) * cos(decrad) - sin(decrad) * cos(Hrad))

    return rad2deg(qloc)
}

###############################################################################
# linear_interpolation
# Determine the minute at which the Moon crosses the horizon
# by linearly interpolating between two consecutive altitude values.
###############################################################################
function linear_interpolation(a1,a2,i,      f,x,hh,mm)
{
    f = a1/(a1-a2)
    x = (i-1)+f

    hh = int(x)
    mm = int((x-hh)*60+0.5)

    if(mm==60){
        hh++
        mm=0
    }

    return hh*60 + mm
}

###############################################################################
# Mathematical helper functions
###############################################################################

function deg2rad(x)
{
    return x * pi / 180.0
}

function rad2deg(x)
{
    return x * 180.0 / pi
}

###############################################################################
# Angle normalization
###############################################################################

function normalize360(angle)
{
    while (angle < 0)
        angle += 360

    while (angle >= 360)
        angle -= 360

    return angle
}

function normalize180(angle)
{
    angle = normalize360(angle)

    if (angle > 180)
        angle -= 360

    return angle
}

###############################################################################
# Helper functions supporting the parsing of NASA mooninfo records.
###############################################################################

function month_to_number(mon)
{
    return (mon=="Jan" ? 1 :
            mon=="Feb" ? 2 :
            mon=="Mar" ? 3 :
            mon=="Apr" ? 4 :
            mon=="May" ? 5 :
            mon=="Jun" ? 6 :
            mon=="Jul" ? 7 :
            mon=="Aug" ? 8 :
            mon=="Sep" ? 9 :
            mon=="Oct" ? 10 :
            mon=="Nov" ? 11 :
            mon=="Dec" ? 12 : 0)
}

###############################################################################
# Parse the current NASA mooninfo record.
#
# Sets the following global variables:
#
#   day, month, year, hour
#   phase, age, dist
#   ra, dec
###############################################################################
function parse_moon_record(      time)
{
    gsub(/ +/, " ")

    day  = $1
    mon  = $2
    year = $3

    split($4, time, ":")

    hour = time[1] + 0

    phase = $6 + 0
    age   = $7 + 0
    dist  = $9 + 0

    ra  = $10 + 0
    dec = $11 + 0

    month = month_to_number(mon)
}

# --- This is the end, my friend ------------------------------------------------------------------
