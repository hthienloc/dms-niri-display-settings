# Niri Display Settings

Quickly manage display outputs in the Niri Wayland compositor.

<img src="screenshot.png" width="400" alt="Screenshot">

## Install

```bash
# Install shared components
git clone https://github.com/hthienloc/dms-common ~/.config/DankMaterialShell/plugins/dms-common

# Install this plugin
dms plugins install niriDS
```

## Features

- Display profiles: Internal Only, External Only, Extend
- Manual toggle for each display
- Auto-show or auto-apply profile when monitor plugged in
- Auto-enable laptop screen when external monitors disconnected

## IPC Commands

| Command | Description |
|---------|-------------|
| `open` | Open the display selector |
| `close` | Close the display selector |
| `toggle` | Toggle the display selector |
| `apply <profile>` | Apply a profile: `internal_only`, `external_only`, `extend` |

## Shortcut

```kdl
binds {
    Mod+P { spawn "dms" "ipc" "call" "niriDS" "toggle"; }
}
```

## License

MIT