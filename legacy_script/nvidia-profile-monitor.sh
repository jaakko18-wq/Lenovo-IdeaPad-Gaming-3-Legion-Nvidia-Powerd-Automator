#!/bin/bash

# Listen for power profile changes
gdbus monitor --system --dest net.hadess.PowerProfiles --object-path /net/hadess/PowerProfiles | \
while read -r line; do
    if [[ "$line" == *"ActiveProfile"* ]]; then
        # Get the new profile
        PROFILE=$(powerprofilesctl get)
        
        # Match icons and text to Lenovo style
        case "$PROFILE" in
            "performance")
                ICON="power-profile-performance-symbolic"
                TEXT="Performance Mode"
                ;;
            "balanced")
                ICON="power-profile-balanced-symbolic"
                TEXT="Balanced Mode"
                ;;
            "quiet"|"power-saver")
                ICON="power-profile-power-saver-symbolic"
                TEXT="Quiet Mode"
                ;;
            *)
                ICON="preferences-system-power"
                TEXT="Profile: $PROFILE"
                ;;
        esac

        # Show KDE OSD
        qdbus6 org.kde.plasmashell /org/kde/osdService showText "$ICON" "$TEXT"

        # Delay and restart
        sleep 1.5
        sudo /usr/bin/systemctl restart nvidia-powerd.service
    fi
done
