# Nullgate's Maps - Forever

[![Interface](https://img.shields.io/badge/Interface-16001%20(WoW%20Forever)-0078D7.svg?style=flat-square)](https://github.com/nullgatestudios/NullgatesMaps-Forever)
[![Release](https://img.shields.io/badge/Release-v1.0.7-ffd100.svg?style=flat-square)](https://github.com/nullgatestudios/NullgatesMaps-Forever/releases)
[![License](https://img.shields.io/badge/License-Source--Available-crimson.svg?style=flat-square)](LICENSE.md)
[![Dependencies](https://img.shields.io/badge/Dependencies-Zero%20External-2ea44f.svg?style=flat-square)](https://github.com/nullgatestudios/NullgatesMaps-Forever)
[![Suite](https://img.shields.io/badge/Suite-Nullgate's%20Addon%20Suite-8a2be2.svg?style=flat-square)](https://github.com/nullgatestudios)

**Nullgate's Maps** is a high-performance, modular World Map and Minimap enhancement suite designed specifically for **World of Warcraft: Forever** (Interface 16001).

Engineered to transform the default Blizzard map experience into a clean, modern navigation interface, it pairs a bespoke **Dark Slate & Gold** visual design language with essential exploration features: live World Map cursor and player coordinates, intelligent Fog of War map overlay revealing undiscovered zones, a minimalist square minimap with mouse wheel zoom, minimap HUD coordinates, and seamless profile synchronization with the **Nullgate Addon Suite**.

Runs **100% standalone out of the box** with zero required third-party libraries or addons.

---

## 📑 Table of Contents

- [Key Highlights](#-key-highlights)
- [Feature Showcase](#-feature-showcase)
  - [1. World Map Live Coordinates](#1-world-map-live-coordinates)
  - [2. Fog of War Revealer](#2-fog-of-war-revealer)
  - [3. Minimalist Square Minimap](#3-minimalist-square-minimap)
  - [4. Minimap Coordinates HUD](#4-minimap-coordinates-hud)
  - [5. Native Dark Slate & Gold GUI](#5-native-dark-slate--gold-gui)
  - [6. Master Hub & Profile Sync](#6-master-hub--profile-sync)
- [Interactive Controls & Mouse Shortcuts](#-interactive-controls--mouse-shortcuts)
- [Configuration Guide](#-configuration-guide)
- [Slash Commands Reference](#-slash-commands-reference)
- [Architecture & File Overview](#-architecture--file-overview)
- [Installation Guide](#-installation-guide)
- [Nullgate Addon Suite Ecosystem](#-nullgate-addon-suite-ecosystem)
- [License & Support](#-license--support)

---

## 🌟 Key Highlights

* **Pure Standalone Power**: Zero external dependencies. Self-contained architecture optimized for lightning-fast map opening times with zero frame stutter.
* **Precise World Map Coordinates**: Real-time display of both your player coordinates and cursor coordinates with customizable decimal precision.
* **Fog of War Map Overlay**: Highlights unexplored territories with configurable overlay tint and transparency to assist in zone completion and exploration.
* **Modern Square Minimap**: Sleek, borderless square minimap featuring sharp Dark Slate & Gold borders and clutter-reduction toggles.
* **Minimap Mouse Wheel Zoom**: Effortlessly zoom the minimap in and out using your mouse wheel.
* **Minimap HUD Coordinates**: Compact coordinate readout situated below the minimap.
* **Non-Destructive Profile Capture**: Instant profile synchronization with `NullgatesAddonConfig-Forever` that preserves active settings upon profile creation.

---

## 🎯 Feature Showcase

### 1. World Map Live Coordinates
Never get lost or misjudge an objective location:
- Real-time **Cursor Coordinates** track the mouse position across the active map.
- Real-time **Player Coordinates** track your character's current location within the zone.
- Configurable coordinate anchors, text font, font size, and precision formatting.

### 2. Fog of War Revealer
Plan your exploration routes effortlessly:
- Overlays unexplored map regions with a clean, semi-transparent colored tint.
- Clearly shows paths, roads, and terrain through unrevealed fog of war.
- Configurable overlay color, opacity, and toggleable per-zone behavior.

### 3. Minimalist Square Minimap
Modernize your radar display:
- Converts the circular Blizzard minimap into a sleek, borderless square format.
- Signature Dark Slate & Gold beveled borders.
- **Clutter Elimination**: Options to hide Blizzard default clutter (calendar, clock, zoom buttons, world map button, tracking ring).
- **Mouse Wheel Zoom**: Smooth in and out zooming directly on the minimap frame.

### 4. Minimap Coordinates HUD
Instant positional awareness at a glance:
- Embedded coordinate bar attached neatly to the minimap.
- Updates smoothly with player movement.
- Configurable font styling, background visibility, and positioning.

### 5. Native Dark Slate & Gold GUI
A clean, responsive configuration interface accessible via `/nmaps` or `/maps`:
- Tabbed settings for World Map, Minimap, Coordinates, and Profiles.
- Live sliders for scale, alpha, and coordinate update intervals.
- Integrated color pickers for border accents and fog tinting.

### 6. Master Hub & Profile Sync
Deep integration with `NullgatesAddonConfig-Forever`:
- Seamlessly registers into the BAC master hub sidebar.
- Non-destructive profile creation that clones current settings rather than wiping to factory defaults.
- One-click profile switching across all Nullgate addons.

---

## 🖱️ Interactive Controls & Mouse Shortcuts

| Action | Description |
| :--- | :--- |
| **Mouse Wheel on Minimap** | Zooms the minimap view in and out. |
| **Right-Click Minimap** | Opens the standard Blizzard tracking popup menu. |
| **`/nmaps` or `/maps`** | Opens the graphical configuration panel. |
| **`/nmaps coords`** | Toggles coordinate displays on and off. |
| **`/nmaps fog`** | Toggles the Fog of War map revealer overlay. |

---

## 🛠️ Configuration Guide

Type `/nmaps` or `/maps` to open the options panel:

1. **General / World Map**: Enable/disable world map coordinates, adjust coordinate position and text formatting, and toggle map fading.
2. **Fog of War**: Toggle unexplored map overlays, adjust overlay color tint, and set opacity levels (10%–100%).
3. **Minimap**: Toggle square minimap styling, enable mouse wheel zoom, and customize visibility of default Blizzard minimap icons.
4. **Minimap Coordinates**: Toggle the minimap coordinate HUD, adjust font size, and set position anchors.
5. **Profiles**: Create, copy, delete, and switch configurations with full Nullgate Addon Suite synchronization.

---

## ⌨️ Slash Commands Reference

| Command | Description |
| :--- | :--- |
| `/nmaps` | Opens the graphical configuration panel. |
| `/maps` | Alternative shortcut to open the configuration panel. |
| `/nmaps coords` | Quick-toggles coordinate readouts. |
| `/nmaps fog` | Quick-toggles Fog of War revealer overlay. |
| `/nmaps profile <name>` | Switches active profile or prints current profile name. |

---

## 🏗️ Architecture & File Overview

```
NullgatesMaps-Forever/
├── NullgatesMaps-Forever.toc        # Addon metadata, SavedVariables & manifest
├── Core/
│   ├── Init.lua                       # Addon initialization, lifecycle & event engine
│   ├── Constants.lua                  # Default visual constants, colors & layouts
│   ├── Config.lua                     # Configuration schema, defaults & BAC registration
│   └── ConfigUI.lua                   # Native Dark Slate & Gold options window
├── Locales/
│   └── enUS.lua                       # Localization strings
└── Modules/
    ├── Minimap/
    │   ├── SquareMinimap.lua          # Square styling, clutter hiding & wheel zoom
    │   └── MinimapCoords.lua          # Minimap coordinate display HUD
    └── WorldMap/
        ├── WorldMapCoords.lua         # World Map cursor & player coordinate readouts
        ├── WorldMapFog.lua            # Fog of War revealer overlay logic
        └── WorldMapFogData.lua        # Unexplored territory texture mappings
```

---

## 💾 Installation Guide

1. Download the latest release package from the official [Releases](https://github.com/nullgatestudios/NullgatesMaps-Forever/releases) page.
2. Exit World of Warcraft completely.
3. Extract the downloaded archive (`NullgatesMaps-Forever 1.0.7.zip`).
4. Copy the `NullgatesMaps-Forever` folder into your WoW client AddOns directory:
   ```
   World of Warcraft/_forever_/Interface/AddOns/NullgatesMaps-Forever
   ```
5. Launch World of Warcraft, open your map (`M`), and type `/nmaps` to configure settings.

---

## 🌌 Nullgate Addon Suite Ecosystem

Nullgate's Maps integrates seamlessly with the entire **Nullgate Addon Suite**:

* **[Nullgate's Addon Config](https://github.com/nullgatestudios/NullgatesAddonConfig-Forever)**: Centralized master configuration hub with unified mover mode and cross-addon profile syncing.
* **[Nullgate's Action Bars](https://github.com/nullgatestudios/NullgatesActionBars-Forever)**: Minimalist action bar suite with bags container, totem bars, and cooldown pulse.
* **[Nullgate's Quest Tracker](https://github.com/nullgatestudios/NullgatesQuestTracker-Forever)**: High-performance quest tracker with 360° Wayfinder navigation and interactive quest items.
* **[Nullgate's Unit Toggles](https://github.com/nullgatestudios/NullgatesUnitToggles-Forever)**: Instant Blizzard unit name & nameplate toggle suite with 20 CVar presets.

---

## 📜 License & Support

* **License**: Restricted - Source-Available (All Rights Reserved, No Derivatives). See [LICENSE.md](LICENSE.md) for full terms.
* **Issues & Feedback**: Encounter a bug or have a feature request? Open an issue on our [GitHub Issue Tracker](https://github.com/nullgatestudios/NullgatesMaps-Forever/issues).
* **Author**: Nullgate

