#!/bin/bash
#
#==============================================================================
#  Project:     MoonPhaseWallpaper
#------------------------------------------------------------------------------
#  File:        configuration_wizard.sh
#  Author:      Uli Treuer
#  Purpose:     Manages the configuration dialog with the user.
#
#  Copyright (c) 2026 Uli Treuer
#  License: MIT
#==============================================================================


#==================================================================================================
# configure_application
#
# Run the configuration wizard to configure the application with user-specific settings.
# Use applicable values from a previous configuration as defaults.
#==================================================================================================
configure_application()
{
    # try to read the configuration file (if it exists) so that the values from a previous
    # configuration can be used as default values for the current configuration run.
    # If the configuration file does not exist or cannot be read, then read_configuration
    # automatically tries to read the default configuration file and use the values from
    # that file as default values.
    # We are not providing defaults for Activity or Screen as the system configuration
    # may have changed since the previous configuration
    # (e.g. new or less screens, activities deleted, ...).
    wizard_config_exists=false
    if read_configuration; then
        wizard_config_exists=true
    elif ! read_default_configuration; then
        fatal_configuration_error \
            "Configuration files are missing or corrupt:" \
            "$configfile $configfile_default"
    fi

    wizard_default_latitude="$OBSERVER_LATITUDE"
    wizard_default_longitude="$OBSERVER_LONGITUDE"

    choose_activity
    choose_screen
    enter_observer_location
    configuration_summary

}

#==================================================================================================
# choose_activity
#
# Shows the list of all Activities (names and IDs) on the screen and asks to select the target
# activity for the generated wallpaper to be displayed on.
#==================================================================================================
choose_activity()
{
local i
local num_activities
local selection
local act_name
declare -A activity_map
declare -a activity_names

    create_activity_map activity_map num_activities
    i=0
    while IFS= read -r act_name; do
        ((++i))
        activity_names[i]="$act_name"
    done < <(printf '%s\n' "${!activity_map[@]}" | sort)

    if [[ $num_activities -eq 1 ]]; then # nothing to select for the user
        selection=1
        echo " "
        echo " MoonPhaseWallpaper Configuration: Activity Selection"
        echo " ===================================================="
        echo " "
        echo " Found 1 Activity:"
        echo " "
        printf "      %-23s\n" "$i" "${activity_names[$selection]}"
        echo " "
        echo " Using this Activity."
        sleep 2
    else
        while true; do
            clear
            echo " "
            echo " MoonPhaseWallpaper Configuration: Activity Selection"
            echo " ===================================================="
            echo " "
            echo " Select the Activity where the generated wallpaper should be displayed:"
            echo " "
            printf "     %-2s %-23s %s\n" "#" "Activity Name" "Activity ID"

            for ((i=1; i<=num_activities; i++)); do
                act_name="${activity_names[i]}"
                printf "    %2d) %-23s %s\n" "$i" "${activity_names[$i]}" "${activity_map[$act_name]}"
            done

            echo " "
            read -rp " Selection: " selection

            if [[ $selection =~ ^[1-9][0-9]*$ ]]; then
                if [[ $selection -le $num_activities ]]; then
                    break
                fi
            fi
            echo " Please enter a number between 1 and $num_activities."
            sleep 2
        done
    fi

    wizard_activity_name="${activity_names[$selection]}"
    wizard_activity_id="${activity_map[$wizard_activity_name]}"
    echo " Selected Activity:"
    echo "     $wizard_activity_name"
}

#==================================================================================================
# choose_screen
#
# Shows the list of all screen IDs on the screen and asks to select the target screen for the
# generated wallpaper to be displayed on.
#==================================================================================================
choose_screen()
{
local num_screens
local selection

    get_num_screens num_screens

    if [[ $num_screens -eq 1 ]]; then # nothing to select for the user
        selection=1
        echo " "
        echo " MoonPhaseWallpaper Configuration: Screen Selection"
        echo " =================================================="
        echo " "
        echo " Selected Activity:"
        echo "     $wizard_activity_name"
        echo " "
        echo " -------------------------------------------------------------------------------"
        echo " "
        echo " Found 1 Screen. Using this Screen."
        echo " "
        sleep 2
    else
        while true; do
            clear
            echo " "
            echo " MoonPhaseWallpaper Configuration: Screen Selection"
            echo " =================================================="
            echo " "
            echo " Selected Activity:"
            echo "     $wizard_activity_name"
            echo " "
            echo " -------------------------------------------------------------------------------"
            echo " "
            echo " Select the screen where the generated wallpaper should be displayed:"
            echo " "

            for ((i=0; i<num_screens; i++)); do
                printf "    %2d) Screen %2d\n" "$((i+1))" "$((i+1))"
            done

            echo " "
            read -rp " Selection: " selection

            if [[ $selection =~ ^[1-9][0-9]*$ ]]; then
                if [[ $selection -le $num_screens ]]; then
                    break
                fi
            fi
            echo " Please enter a number between 1 and $num_screens."
            sleep 2
        done
    fi

    wizard_screen=$((selection-1))
    echo " Selected Screen:"
    echo "     Screen $wizard_screen"
}

#==================================================================================================
# enter_observer_location
#
# Ask the user to provide latitude and longitude of the Observer location.
#==================================================================================================
enter_observer_location()
{
local lat lon extra
readonly DEFAULT_LAT="$wizard_default_latitude"
readonly DEFAULT_LON="$wizard_default_longitude"

    while true; do
        clear
        echo " "
        echo " MoonPhaseWallpaper Configuration: Observer Location"
        echo " ==================================================="
        echo " "
        echo " Selected Activity:"
        echo "     $wizard_activity_name"
        echo " Selected Screen:"
        echo "     Screen $((wizard_screen+1))"
        echo " "
        echo " -------------------------------------------------------------------------------"
        echo " "
        echo " Enter Observer location (decimal degrees)"
        if $wizard_config_exists; then
            echo " Default: from previous configuration"
        else
            echo " Default: Freiburg (Germany)"
        fi
        echo " "
        read -rp " Enter Latitude Longitude (Enter for default [$DEFAULT_LAT $DEFAULT_LON]): " lat lon extra

        # User just pressed Enter -> use defaults
        if [[ -z $lat ]]; then
            lat="$DEFAULT_LAT"
            lon="$DEFAULT_LON"
            break
        fi

        if [[ -z $extra ]] && validate_observer_location "$lat" "$lon"; then
            break
        fi

        echo " Please enter latitude (-90..90) and longitude (-180..180),"
        echo " or press <Enter> to use the defaults."
        sleep 2
    done

    wizard_latitude=$lat
    wizard_longitude=$lon
    echo " Observer Location:"
    echo "     Latitude:  $wizard_latitude"
    echo "     Longitude: $wizard_longitude"
}

#==================================================================================================
# configuration_summary
#
# Shows a configuration summary (all selected values) and ask the user whether to write the
# configuration
#==================================================================================================
configuration_summary()
{
local answer

    while true; do
        clear
        echo " "
        echo " MoonPhaseWallpaper: Configuration Summary"
        echo " ========================================="
        echo " "
        echo " Activity:"
        echo "     $wizard_activity_name"
        echo " Screen:"
        echo "     Screen $((wizard_screen+1))"
        echo " Observer Location:"
        echo "     Latitude:  $wizard_latitude"
        echo "     Longitude: $wizard_longitude"
        echo " "
        echo " -------------------------------------------------------------------------------"
        echo " "
        read -rp  " Write configuration to configuration file? [Y/n]: " answer

        # User just pressed Enter -> use defaults
        if [[ -z $answer ]]; then
            answer="y"
            break
        fi
        if [[ $answer =~ ^[YyNn]$ ]]; then
            answer=${answer,,}    # Convert to lowercase
            break
        fi

        echo " Please enter exactly one of these characters: Y, y, N, or n."
        sleep 2
    done

    if [[ $answer == y ]]; then
        echo " "
        echo " Saving configuration..."
        conf_write_configuration
        echo " "
        echo " Configuration saved successfully."
        echo " "
        echo " -------------------------------------------------------------------------------"
        echo " "
        echo " Note:"
        echo " The NASA download URLs are stored in"
        echo "     $configfile"
        echo " These URLs must be updated once per year at the beginning of the year."
        echo " Instructions are included in the configuration file."
    else
        echo " Configuration was not saved."
        echo " "
        echo " -------------------------------------------------------------------------------"
    fi
    echo " "
    echo " Note:"
    echo " You can rerun the configuration wizard at any time by running"
    echo "     moon_wallpaper.sh -c"
    echo " "
    echo " -------------------------------------------------------------------------------"
    echo " "
}

# --- This is the end, my friend ------------------------------------------------------------------
