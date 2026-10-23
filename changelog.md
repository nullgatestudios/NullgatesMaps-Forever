# Changelog

## [1.1.0] - 2026-10-23: Bleakfiber's Maps is now Nullgate's Maps

### Changed
- **New name**: Bleakfiber's Maps is now **Nullgate's Maps**, from **Nullgate Studios**. It is the same addon on the same CurseForge page.
- **A fresh start for the WoW Forever launch**: the addon now lives in the `NullgatesMaps-Forever` folder. Settings from the beta are not carried over, so set the addon up again.
- **Remove the old version**: if you copied your old `Interface` folder over, delete the `BleakfibersMaps-Forever` folder from `Interface\AddOns`. If the old version is still installed, a message offers to disable it.
- **New slash commands**: `/nmaps` opens the settings. The old `/bfm` and `/bleakfibersmaps` commands no longer exist, so please update any macros that use them.
- **Nullgate's Quest Tracker**: the minimap coordinates still step aside when the Quest Tracker's location bar is on.

## [1.0.8] - 2026-10-09

### Changed
- Fixed dropdown symbol glyphs showing as broken rectangular boxes across fonts.

## [1.0.7] - 2026-10-08

### Changed
- Maintenance and update.

## [1.0.6] - 2026-10-08

### Changed
- Non-destructive profile synchronization with BleakfibersAddonConfig: capture current settings on new profile and never overwrite existing profiles.

All notable changes to Bleakfiber's Maps will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.05] - 2026-10-07

### Added
- **Suite Standardization (Bleakfiber Addon Design Guide)**:
  - Full Profile Management system with active profile indicator, instant live switching, profile creation, deletion, copy, and reset.
  - Backwards compatibility auto-migration seamlessly migrating legacy flat SavedVariables into the new profile schema.
  - Unified Movers Contract (`ToggleMovers`, `IsMoversUnlocked`, `ResetMovers`) with registration in `_G.Bleakfibers_MoversRegistry["BleakfibersMaps"]`.
  - Prominent "Toggle Movers" button integrated into the standalone configuration title bar.
  - Master Hub profile and mover callbacks registered with `BleakfibersAddonConfigForever` (`/bac`).
  - New slash commands: `/bfm movers`, `/bfm profile <list|set|create|delete>`, and `/bfm reset`.
  - Standardized automated release packaging via `package.ps1`.

## [1.0.04] - 2026-10-05

### Added
- World Map Fog of War / Map Reveal module with custom overlay tint, opacity, and presets.

## [1.0.03] - 2026-10-05

### Added
- Sub-tab navigation system (General, Minimap, World Map) with improved canvas layout.

## [1.0.02] - 2026-10-05

### Added
- Custom button scaling, coordinate HUD bar, and click-to-drag positioning.

## [1.0.01] - 2026-10-05

### Added
- Initial release of Bleakfiber's Maps - Forever.

