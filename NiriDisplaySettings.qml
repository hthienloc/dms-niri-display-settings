import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import "./dms-common"

PluginSettings {
    id: root
    pluginId: "niriDS"

    SettingsCard {
        id: autoBehaviorsSection
        SectionTitle { 
            text: I18n.tr("Automatic Behaviors")
            icon: "auto_awesome" 
            showReset: connectionAction.isDirty || enableFallback.isDirty || fallbackDisplay.isDirty || bgOpacity.isDirty
            onResetClicked: {
                connectionAction.resetToDefault();
                enableFallback.resetToDefault();
                fallbackDisplay.resetToDefault();
                bgOpacity.resetToDefault();
            }
        }

        Item {
            width: parent.width
            height: connectionAction.implicitHeight

            HoverHandler {
                id: connectionActionHover
            }

            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: -12
                anchors.rightMargin: -12
                anchors.topMargin: -6
                anchors.bottomMargin: -6
                radius: Theme.cornerRadius
                color: connectionActionHover.hovered ? Theme.withAlpha(Theme.primary, 0.08) : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            SelectionSettingPlus {
                id: connectionAction
                width: parent.width
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
        }

        Separator {}

        Item {
            width: parent.width
            height: enableFallback.height

            HoverHandler {
                id: enableFallbackHover
            }

            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: -12
                anchors.rightMargin: -12
                anchors.topMargin: -6
                anchors.bottomMargin: -6
                radius: Theme.cornerRadius
                color: enableFallbackHover.hovered ? Theme.withAlpha(Theme.primary, 0.08) : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            ToggleSettingPlus {
                id: enableFallback
                width: parent.width
                settingKey: "enableFallback"
                label: I18n.tr("Enable safety fallback")
                description: I18n.tr("Automatically re-enable the laptop screen if all external monitors are disconnected")
                defaultValue: true
            }
        }

        Separator {}

        Item {
            width: parent.width
            height: fallbackDisplay.implicitHeight

            HoverHandler {
                id: fallbackDisplayHover
            }

            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: -12
                anchors.rightMargin: -12
                anchors.topMargin: -6
                anchors.bottomMargin: -6
                radius: Theme.cornerRadius
                color: fallbackDisplayHover.hovered ? Theme.withAlpha(Theme.primary, 0.08) : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            StringSettingPlus {
                id: fallbackDisplay
                width: parent.width
                settingKey: "fallbackDisplay"
                label: I18n.tr("Preferred internal display")
                description: I18n.tr("The name of your laptop display (e.g. eDP-1). Leave empty for auto-detection.")
                placeholder: "eDP-1"
                defaultValue: ""
            }
        }

        Separator {}

        SliderSettingPlus {
            id: bgOpacity
            settingKey: "bgOpacity"
            label: I18n.tr("Modal Background Opacity")
            description: I18n.tr("Adjust the background dimming opacity when the display settings modal is open")
            minimum: 0
            maximum: 100
            defaultValue: 50
            unit: "%"
            previewType: "opacity"
        }
    }

    SettingsCard {
        SectionTitle {
            id: ipcTitle
            text: I18n.tr("IPC Commands")
            icon: "terminal"
            collapsible: true
            isExpanded: false
            settingKey: "ipcCommandsExpanded"
        }

        Column {
            width: parent.width
            spacing: Theme.spacingM
            visible: ipcTitle.isExpanded

            CopyBox {
                label: I18n.tr("Toggle Modal")
                text: "dms ipc call niriDS toggle"
            }

            CopyBox {
                label: I18n.tr("Open Modal")
                text: "dms ipc call niriDS open"
            }

            CopyBox {
                label: I18n.tr("Close Modal")
                text: "dms ipc call niriDS close"
            }

            CopyBox {
                label: I18n.tr("Apply: Internal Only")
                text: "dms ipc call niriDS apply internal_only"
            }

            CopyBox {
                label: I18n.tr("Apply: External Only")
                text: "dms ipc call niriDS apply external_only"
            }

            CopyBox {
                label: I18n.tr("Apply: Extend Displays")
                text: "dms ipc call niriDS apply extend"
            }

            CopyBox {
                label: I18n.tr("Apply: Mirror Displays")
                text: "dms ipc call niriDS apply mirror"
            }

            Separator { opacity: 0.1 }

            CopyBox {
                label: I18n.tr("Niri Binding Configuration")
                text: "Mod+P { spawn \"dms\" \"ipc\" \"call\" \"niriDS\" \"toggle\"; }"
            }
        }
    }

    SettingsCard {
        SectionTitle { 
            id: usageTitle
            text: I18n.tr("Usage Guide")
            icon: "menu_book" 
            collapsible: true
            settingKey: "usageGuideExpanded"
        }

        UsageGuide {
            expanded: usageTitle.isExpanded
            items: [
                I18n.tr("Activate the display selector via the <b>Control Center</b> or configured <b>keybindings</b>."),
                I18n.tr("Use the <b>IPC commands</b> above to automate display switching.")
            ]
        }
    }

    PluginAbout {
        repoUrl: "https://github.com/hthienloc/dms-niri-display-settings"
    }

}
