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

## Problem Solved & Features

- **Prevent Black-Screen Lockouts (Unplug Fallback)**: If you are in *External Only* mode and physically unplug your external monitor, the plugin instantly and automatically re-enables your laptop screen so you are never left with a dead black display.
- **Windows-Style Profiles**: Instantly switch between *Internal Only*, *External Only*, or *Extended (Dual Display)* modes via a clean selector.
- **Manual Output Control**: Easily toggle specific displays on or off from a manual list.

## IPC Commands

Use `dms ipc call niriDS <command>` to control the display selector.

| Command | Description |
|---------|-------------|
| `open` | Open the display settings modal |
| `close` | Close the display settings modal |
| `toggle` | Toggle the display settings modal |
| `apply <profile>` | Apply a profile: `internal_only`, `external_only`, `extend` |

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
