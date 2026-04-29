# EzroUI

A lightweight World of Warcraft UI overhaul AddOn built on the Ace3 framework.

**Author:** Ezr0  
**Version:** 1.0.1  
**Supported Clients:** The War Within (TWW) · Midnight (11.2+)

---

## Overview

EzroUI replaces and enhances many of the default World of Warcraft UI elements with clean, highly configurable alternatives. It is built around a modular design, allowing each feature to be enabled or disabled independently through an in-game configuration panel.

---

## Features

| Module | Description |
|---|---|
| **Unit Frames** | Custom player, target, focus, and boss frames with health/power bars, auras, absorb overlays, and Clique support |
| **Cast Bars** | Restyled cast bars for player, target, focus, and boss units; supports Empowered casts |
| **Resource Bars** | Primary and secondary power bars with automatic resource detection; full Death Knight rune support |
| **Icon Viewers** | Three configurable icon viewer rows (Essential Cooldowns, Utility Cooldowns, Buff Icons) with skinning, proc glows, aura overrides, and keybind display |
| **Custom Icons** | Pin any spell or item icon to a viewer slot |
| **Custom Buffs** | Track specific buffs/debuffs with custom icons |
| **Icon Customization** | Per-icon size, position, and visual tweaks |
| **Absorb Bars** | Shield/absorb overlay bars overlaid on unit frame health bars |
| **Minimap** | Restyled minimap with configurable border, clock, FPS counter, and zone text |
| **Action Bars** | Action bar restyling with button glow effects |
| **Buff/Debuff Frames** | Restyled default buff and debuff frames |
| **Tooltips** | Enhanced unit tooltips — class-coloured borders and names, spec, guild, realm, health, power, M+ score, and PvP rating |
| **Chat** | Chat frame restyling |
| **Character Panel** | Enhanced character panel showing item level, sockets, enchants, and durability at a glance |
| **Quality of Life** | Miscellaneous improvements: hide the bags bar, show spell/item IDs in tooltips, raid buff tracking |
| **Auto UI Scale** | Automatically calculates and applies a pixel-perfect UI scale for your monitor resolution |

---

## Installation

1. Download the latest release from the [Releases](../../releases) page.
2. Extract the `EzroUI` folder into your AddOns directory:
   ```
   World of Warcraft/_retail_/Interface/AddOns/EzroUI
   ```
3. Launch the game and enable **EzroUI** in the AddOns list on the character selection screen.

---

## Usage

- **Open configuration:** Left-click the minimap icon, or type `/ezroui` in chat.
- **Move frames:** Use the in-game Edit Mode or the Nudge tool available in the configuration panel.
- **Profile management:** Export your current profile as a shareable string or import a profile string from the configuration panel under **Import / Export**.

---

## Libraries

EzroUI bundles the following libraries (no separate installation required):

- **Ace3** — AceAddon, AceDB, AceEvent, AceConsole, AceHook, AceLocale, AceGUI, AceConfig, AceSerializer, AceDBOptions
- **LibSharedMedia-3.0** — custom fonts, textures, and sounds
- **LibDeflate** — data compression for profile import/export
- **LibCustomGlow-1.0** — custom glow effects on icons
- **LibButtonGlow-1.0** — standard button glow effects
- **LibDualSpec-1.0** — per-spec profile switching
- **LibDBIcon-1.0** — minimap broker icon
- **LibDataBroker-1.1** — data broker support
- **LibActionButton-1.0** — action button enhancements
- **LibKeyBound-1.0** — keybind display on action buttons
- **LibWindow-1.1** — movable/resizable frame helper
- **TaintLess** — taint mitigation patches

---

## Screenshots

| Before | After |
|---|---|
| ![Before](docs/before.png) | ![After](docs/after.png) |

---

## License

See [LICENSE](LICENSE) if present, or contact the author for usage terms.
