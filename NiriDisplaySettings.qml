import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "niriDS"

    SettingsCard {
        StyledText {
            width: parent.width
            text: I18n.tr("Automatic Behaviors")
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Medium
            color: Theme.surfaceText
        }

        SelectionSetting {
            settingKey: "connectionAction"
            label: I18n.tr("When monitor is connected")
            description: I18n.tr("Choose what happens automatically when an external monitor is plugged in")
            options: [
                { label: I18n.tr("Show Menu"), value: "show_menu" },
                { label: I18n.tr("External Only"), value: "external_only" },
                { label: I18n.tr("Extended"), value: "extend" },
                { label: I18n.tr("Internal Only"), value: "internal_only" },
                { label: I18n.tr("Mirror"), value: "mirror" },
                { label: I18n.tr("Do Nothing"), value: "none" }
            ]
            defaultValue: "show_menu"
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
        StyledText {
            width: parent.width
            text: I18n.tr("Commands & Shortcuts")
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Medium
            color: Theme.surfaceText
        }

        StyledText {
            width: parent.width
            text: I18n.tr("You can open, close, or toggle the Niri Display Settings modal using the dms CLI:")
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            wrapMode: Text.WordWrap
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

        StyledText {
            width: parent.width
            text: I18n.tr("Valid profiles: internal_only, external_only, extend, mirror")
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            wrapMode: Text.WordWrap
            opacity: 0.7
        }

        StyledText {
            width: parent.width
            text: I18n.tr("To trigger the display selector using Mod+P, add this spawn command to your Niri configuration binds:")
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.primary
            font.italic: true
            wrapMode: Text.WordWrap
        }

        CopyBox {
            label: I18n.tr("Niri Bind Configuration")
            text: "Mod+P { spawn \"dms\" \"ipc\" \"call\" \"niriDS\" \"toggle\"; }"
        }
    }
}
