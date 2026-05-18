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

- **Prevent Black-Screen Lockouts** - Instantly re-enables laptop screen if the external monitor is unplugged in *External Only* mode
- **Windows-Style Profiles** - Switch between *Internal Only*, *External Only*, or *Extended (Dual Display)* modes
- **Manual Output Control** - Easily toggle specific displays on or off from a list

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

## Roadmap / TODO

- [ ] **Custom Profiles:** Create, name, and save custom multi-monitor arrangements beyond the standard presets.
- [ ] **Advanced Controls:** Add UI selectors for resolution, refresh rate, orientation, and fractional scaling.
- [ ] **EDID Auto-Load:** Detect specific monitor combinations (e.g., home vs. office) and automatically apply saved profiles.
- [ ] **Visual Layout Sandbox:** A drag-and-drop workspace UI to position screens relative to each other.
- [ ] **Notification Alerts:** Rich system notifications when displays are toggled or fallback triggers.

## License

MIT
