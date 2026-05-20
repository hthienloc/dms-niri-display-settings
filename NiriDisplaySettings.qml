import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import "../dms-common"

PluginSettings {
    id: root
    pluginId: "niriDS"

    SettingsCard {
        SectionTitle { text: I18n.tr("Automatic Behaviors") }

        ToggleSetting {
            settingKey: "autoShowOnConnect"
            label: I18n.tr("Auto-show menu on connect")
            description: I18n.tr("Automatically open the display selector when a new monitor is plugged in")
            defaultValue: false
        }

        SelectionSetting {
            settingKey: "profileOnConnect"
            label: I18n.tr("Profile on connect")
            description: I18n.tr("Automatically apply this profile when an external monitor is connected")
            options: [
                { label: I18n.tr("Show Menu"), value: "" },
                { label: I18n.tr("External Only"), value: "external_only" },
                { label: I18n.tr("Extended"), value: "extend" },
                { label: I18n.tr("Internal Only"), value: "internal_only" },
                { label: I18n.tr("Mirror"), value: "mirror" }
            ]
            defaultValue: ""
        }

        ToggleSetting {
            settingKey: "enableFallback"
            label: I18n.tr("Enable safety fallback")
            description: I18n.tr("Automatically re-enable the laptop screen if all external monitors are disconnected")
            defaultValue: true
        }

        StringSetting {
            settingKey: "fallbackDisplay"
            label: I18n.tr("Preferred internal display")
            description: I18n.tr("The name of your laptop display (e.g. eDP-1). Leave empty for auto-detection.")
            placeholder: "eDP-1"
        }
    }

    SettingsCard {
        SectionTitle { text: I18n.tr("Commands & Shortcuts") }

        InfoText {
            text: I18n.tr("You can open, close, or toggle the Niri Display Settings modal using the dms CLI:")
        }

        CopyBox {
            label: I18n.tr("Toggle Modal Command")
            text: "dms ipc call niriDS toggle"
        }

        CopyBox {
            label: I18n.tr("Open Modal Command")
            text: "dms ipc call niriDS open"
        }

        CopyBox {
            label: I18n.tr("Close Modal Command")
            text: "dms ipc call niriDS close"
        }

        CopyBox {
            label: I18n.tr("Apply Profile Command")
            text: "dms ipc call niriDS apply internal_only"
        }

        CopyBox {
            label: I18n.tr("Mirror Display Command")
            text: "dms ipc call niriDS mirror"
        }

        InfoText {
            text: I18n.tr("Valid profiles: internal_only, external_only, extend, mirror")
            font.pixelSize: Theme.fontSizeSmall
            opacity: 0.7
        }

        InfoText {
            text: I18n.tr("To trigger the display selector using Mod+P, add this spawn command to your Niri configuration binds:")
            color: Theme.primary
            font.italic: true
        }

        CopyBox {
            label: I18n.tr("Niri Bind Configuration")
            text: "Mod+P { spawn \"dms\" \"ipc\" \"call\" \"niriDS\" \"toggle\"; }"
        }
    }
}
