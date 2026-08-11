# Changelog

All notable changes to this project will be documented in this file.

The format is inspired by [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to Semantic Versioning.

---
## [1.2.2] - 2026-08-11

### Changed

- Failed downloads of moon images are detected more reliably. After a download failure, up to two additional download attempts are made before exiting with an error.


## [1.2.1] - 2026-08-10

### Fixed

- Added the missing upgrade instruction to run the Configuration Wizard when updating an existing installation to v1.2.0.

## [1.2.0] - 2026-08-10

### Added

- Interpolation between consecutive hours of NASA moon data to improve the accuracy of moon position and related information when the script is run more frequently than once per hour.
- Support for flexible NASA year/URL configuration entries, allowing multiple years to be maintained in the configuration file.
- Automatic migration of version 1 configuration files to the new version 2 format when using the Configuration Wizard.

### Changed

- Updated the configuration file format to version 2.
- NASA moon data sources are now selected automatically based on the required year.
- The Configuration Wizard preserves existing NASA data source entries when they are compatible with the current configuration format.
- Added handling for interpolation across the end-of-year boundary.

## [1.1.1] - 2026-08-08

### Changed

- Removed the obsolete command-line parameter `-f`, simplifying the command-line interface.

## [1.1.0] - 2026-08-07

### Changed

- Wallpaper updates can now be configured at shorter intervals to better reflect the continuously changing observer-dependent Moon orientation. Downloaded Moon images are cached, so the required download volume remains unchanged.

## [1.0.3] - 2026-08-07

### Changed

- Improved observer-dependent Moon orientation by calculating the apparent rotation using the current UTC time instead of the beginning of the NASA image hour.

## [1.0.2] - 2026-08-04

### Changed

- Improved handling when the configured display is temporarily unavailable (for example when using a KVM switch).

## [1.0.1] - 2026-08-03

### Changed

- Generate unique wallpaper filenames to avoid KDE image caching.
- Increase margins around wallpaper elements to avoid overlap with desktop panels.

## [1.0.0] - 2026-08-02

First public release of MoonPhaseWallpaper.

### Added

- Automatic KDE Plasma wallpaper generation using NASA Moon imagery

- Interactive Configuration Wizard

- User-specific configuration management

- Support for KDE Plasma Activities

- Automatic hourly wallpaper updates using an optional systemd user timer

- Installation script for dependency checking and setup

- Comprehensive project documentation (README.md, INSTALL.md)

- MIT License

### Changed

- Refactored the application into modular Bash components

- Separated KDE Plasma JavaScript into dedicated source files

- Improved astronomy calculations and code reuse

- Improved runtime logging and diagnostics

- Simplified configuration validation by separating syntax validation from runtime state

- Improved installation workflow with automated setup

### Fixed

- Correct handling of moonrise and moonset edge cases around midnight

- Improved startup reliability after KDE Plasma login

- Configuration Wizard now recovers gracefully from invalid configuration files

- Correct handling of user-specific configuration files in Git repositories
