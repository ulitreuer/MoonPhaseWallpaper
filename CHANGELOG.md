# Changelog

All notable changes to this project will be documented in this file.

The format is inspired by [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to Semantic Versioning.

---
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
