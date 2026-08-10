# Installation

## 1. Requirements

MoonPhaseWallpaper has been developed and tested on

- Fedora Linux 44
- KDE Plasma 6.7
- Wayland

Other Linux distributions running KDE Plasma 6.x may also work but have not been tested.

MoonPhaseWallpaper is designed to be installed in a user account without requiring root privileges during normal operation. The application stores its configuration and runtime data in user-specific directories and can be executed either manually or automatically using a user-level systemd timer.

## 2. Install dependencies

Package names shown below are valid for Fedora Linux.

Install the required runtime packages:

```bash
sudo dnf install \
    git \
    ImageMagick \
    curl \
    gawk \
    qt6-qttools
```

## 3. Choose and create an installation directory

MoonPhaseWallpaper can be installed into any directory within your home directory.

The installation directory is referenced later by the optional `systemd` service template and therefore should not be moved after installation.

Create the installation directory and navigate to it:

```bash
mkdir -p ~/Projects
cd ~/Projects
```

## 4. Clone the repository

Clone the repository:

```bash
git clone https://github.com/ulitreuer/MoonPhaseWallpaper.git
cd MoonPhaseWallpaper
```

## 5. Run the installer

From the project directory, execute:

```bash
./install.sh
```

The installer will:

- verify that it is running from a valid MoonPhaseWallpaper project directory,
- create the required runtime directories,
- verify that all required software dependencies are installed,
- optionally install and enable the user-specific `systemd` timer.

If any required dependency is missing, the installer reports the missing software and terminates without making changes.

## 6. Configure MoonPhaseWallpaper

After the installation has completed successfully, start the Configuration Wizard:

```bash
./moon_wallpaper.sh -c
```

The Configuration Wizard creates the user configuration file during the first run. On subsequent runs, the existing configuration is loaded and can be modified.

## 7. Verify the installation

In the installation directory, run:

```bash
./moon_wallpaper.sh
```

The wallpaper on the configured KDE Activity and screen should be updated.

To verify that the timer is active:

```bash
systemctl --user status moon_wallpaper.timer
```

To inspect recent runs:

```bash
journalctl --user -u moon_wallpaper.service
```

**Congratulations!**

MoonPhaseWallpaper is now installed and ready to use.

You can update the wallpaper manually by running

```bash
./moon_wallpaper.sh
```

or automatically every hour using the user `systemd` timer.

## 8. Changing the update interval

To change the wallpaper update interval, simply run the installer again:

```bash
cd ~/Projects/MoonPhaseWallpaper
./install.sh
```

In the final installation step, you can reconfigure the optional systemd timer and choose a new update interval between 5 and 60 minutes.

## 9. Updating

To update MoonPhaseWallpaper:

```bash
cd ~/Projects/MoonPhaseWallpaper
git pull
./install.sh
./moon_wallpaper.sh -c
```

Running the installer again is always safe. It verifies the installation and updates the optional systemd integration, including the wallpaper update interval if required.

Running the Configuration Wizard will update your configuration to the latest version while keeping your existing settings. Failing to run the Configuration Wizard after an update will cause the script to fail.

## 10. Uninstallation

To completely remove MoonPhaseWallpaper:

1. Stop and disable the systemd timer:

```bash
systemctl --user disable --now moon_wallpaper.timer
```

2. Remove the installed systemd files:

```bash
rm ~/.config/systemd/user/moon_wallpaper.service
rm ~/.config/systemd/user/moon_wallpaper.timer
systemctl --user daemon-reload
```

3. Delete the MoonPhaseWallpaper project directory:

```bash
rm -rf ~/Projects/MoonPhaseWallpaper
```
