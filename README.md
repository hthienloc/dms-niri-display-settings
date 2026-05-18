# Niri Display Settings

Quickly manage, toggle, and configure display outputs in the Niri Wayland compositor.

<img src="screenshot.png" width="400" alt="Screenshot">

## Install

**Required:** This plugin requires [dms-common](https://github.com/hthienloc/dms-common) to be installed.

```bash
# 1. Install shared components
git clone https://github.com/hthienloc/dms-common ~/.config/DankMaterialShell/plugins/dms-common

# 2. Install this plugin
dms plugins install niriDS
```

Or manually:
```bash
git clone https://github.com/hthienloc/dms-niri-display-settings ~/.config/DankMaterialShell/plugins/niriDS
```

## Features

- **Windows-Style Profiles** - Switch between Laptop Screen Only, External Screen Only, or Extend (Dual display) instantly
- **Automatic Fallback** - Safely reactivates your laptop display if all external monitors are unplugged, preventing black screens
- **Manual Control** - Sleek vertical listing with live green/grey status badges to toggle individual outputs
- **Material Styling** - Adaptive color tokens that respect the active shell theme dynamically
- **Keyboard Friendly** - Fully accessible using Arrow keys, Tab, Enter, and Escape

Use `dms ipc call niriDS <command>` to control the display selector.

| Command | Description |
|---------|-------------|
| `open` | Open the display settings modal |
| `close` | Close the display settings modal |
| `toggle` | Toggle the display settings modal |
| `apply <profile>` | Apply a profile: `internal_only`, `external_only`, `extend` |

### Automatic Detection

The plugin includes a robust polling-based detection system that:
1. **Auto-shows** the menu when a new monitor is plugged in (if enabled in settings).
2. **Auto-falls back** to the laptop screen when all external monitors are unplugged (if enabled).

### Keybinding example (Niri)

```kdl
binds {
    Mod+P { spawn "dms" "ipc" "call" "niriDS" "toggle"; }
}
```

## Requirements

- DankMaterialShell >= 0.6.2
- Niri Wayland compositor

## License

MIT
