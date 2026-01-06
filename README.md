# Linux Lenovo-IdeaPad-Gaming-3 & Legion Nvidia Powerd Automator
This project automates the nvidia-powerd.service restart on Arch Linux when switching power profiles (e.g., via Fn+Q) or when connecting a charger. It features clean KDE Plasma 6 OSD notifications.

🔍 Why this project? (The Problem)

On many Lenovo laptops (like IdeaPad Gaming or Legion), the Nvidia GPU's Power Management (TDP) can get stuck. For example, the GPU might be capped at 60W even when it should reach 85W or higher in Performance mode.

This usually happens when switching between Balanced, Quiet, and Performance modes. The nvidia-powerd service fails to update the power limits correctly, leaving you with lower performance than expected. Restarting the nvidia-powerd service manually fixes this and unlocks the full TDP, and this project automates that process.

⚠️ Disclaimer

Use at your own risk. This software is provided "as is", without warranty of any kind. The author is not responsible for any damage to your hardware, data loss, or system instability caused by these scripts. Always review the code before running it on your system.

🌟 Features

-Fn+Q Support: Detects hardware-level profile switches and optimizes the Nvidia service immediately.

-Charger Detection: Automatically restarts the service when AC power is connected.

-KDE Plasma 6 OSD: Visual confirmation on screen using native icons (Quiet, Balanced, Performance).

-Full Automation: Runs in the background without password prompts.

🛠 Requirements

1. Kernel Driver: Lenovolegionlinux

   Enables Fn+Q and profile management on Linux.

   Arch Linux install:
   
         yay -S lenovo-legion-module-dkms-git
         yay -S lenovolegionlinux-git
   or

         sudo pacman -S lenovolegionlinux-dkms
         sudo pacman -S lenovolegionlinux

    Desktop Environment: KDE Plasma 6.

    Background Services: power-profiles-daemon (standard in KDE).

    Tools: qt6-declarative (provides the qdbus6 command).

🚀 Installation
1. # Lenovo IdeaPad Gaming 3 - Nvidia Powerd Automator

This project provides an automated fix for **Lenovo IdeaPad Gaming 3** (specifically tested on **15ACH6**) and similar Lenovo laptops running Linux. It ensures that your NVIDIA GPU reaches its full power limit (TGP) when switching power profiles.

## The Problem
When you switch power profiles using **Fn+Q** (e.g., to Performance Mode), the NVIDIA GPU often remains locked at a lower power limit (e.g., **60W**) instead of its maximum potential (**85W**). 

This happens because the `nvidia-powerd.service` (responsible for NVIDIA Dynamic Boost) does not always detect the hardware profile change in real-time on Linux.

## The Solution versio 2
This tool implements a lightweight, event-driven fix using a **systemd path unit**. 
- It monitors the system file `/sys/firmware/acpi/platform_profile` for changes.
- When you press **Fn+Q**, the system detects the modification instantly.
- It automatically restarts the `nvidia-powerd.service` after a 2-second delay to ensure the new power limit is applied.

**Why this is better than a background script:**
- **Zero CPU usage:** It doesn't run in a loop; it only "wakes up" when the profile file is actually modified.
- **Native Integration:** It uses standard Linux systemd units.

## Installation

1. **Clone the repository:**

         git clone [https://github.com/jaakko18-wq/Lenovo-IdeaPad-Gaming-3-Legion-Nvidia-Powerd-Automator.git](https://github.com/jaakko18-wq/Lenovo-IdeaPad-Gaming-3-Legion-Nvidia-Powerd-Automator.git)
         cd Lenovo-IdeaPad-Gaming-3-Legion-Nvidia-Powerd-Automator

Run the installer:

    sudo chmod +x install.sh
    sudo ./install.sh

Uninstallation

If you wish to remove the automation:

      sudo chmod +x uninstall.sh
      sudo ./uninstall.sh

Requirements

   A Lenovo laptop using lenovolegionlinux or standard ACPI profiles.

   NVIDIA proprietary drivers.

   nvidia-powerd.service (Common on modern distros like Ubuntu, Arch, CachyOS, etc.).

Verification

To verify it works, switch profiles with Fn+Q and check the service status:
Bash

      systemctl status nvidia-powerd.service

You should see that the service restarted a few seconds ago. You can also verify the power limit using nvidia-smi.

or this versio 1 

1. Configure Sudoers (Passwordless Restart) To allow the script to restart the service without a password, you need to create a rule. On some systems, you must switch to the root user first to access the sudoers directory.

         # Switch to root user
         su

         # Create the rule using nano (replace 'yourusername' with your actual username)
         EDITOR=nano visudo -f /etc/sudoers.d/nvidia-restart

Inside the file, add:

      yourusername ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nvidia-powerd.service

Save (Ctrl+O, Enter) and Exit (Ctrl+X). Then type exit to leave the root shell.

2. Create the Monitoring Script

This script listens to the D-Bus for profile changes.

    mkdir -p ~/.local/bin
    nano ~/.local/bin/nvidia-profile-monitor.sh

Paste the following:

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

    

Apply permissions:

    chmod +x ~/.local/bin/nvidia-profile-monitor.sh

3. Setup Auto-start (Systemd)

Create a user service to start the script upon login.
Bash

    mkdir -p ~/.config/systemd/user/
    nano ~/.config/systemd/user/nvidia-profile-monitor.service

Paste the following:

    [Unit]
    Description=Nvidia Powerd Restart on Profile Change
    After=graphical-session.target

    [Service]
    ExecStart=%h/.local/bin/nvidia-profile-monitor.sh
    Restart=always

    [Install]
    WantedBy=default.target

Enable and start:
    
    systemctl --user enable --now nvidia-profile-monitor.service

4. AC Adapter (Udev) Automation

Create a udev rule to handle charger connection:

    sudo nano /etc/udev/rules.d/99-nvidia-power-ac.rules

Paste the following:

    SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="/usr/bin/systemd-run --no-block /usr/bin/bash -c 'sleep 5; /usr/bin/systemctl restart nvidia-powerd.service'"

Reload rules:

    sudo udevadm control --reload-rules

🔍 Testing

1. Press Fn+Q: An OSD should appear in the center of the screen.

2. Plug in your charger: The service will restart in the background after a 5s delay.

3. Check status:    systemctl --user status nvidia-profile-monitor.service
