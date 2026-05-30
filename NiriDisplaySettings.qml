import QtQuick
import QtQuick.Layouts
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

        ToggleSetting {
            settingKey: "disableInternalOption"
            label: I18n.tr("Disable internal display option")
            description: I18n.tr("Remove the internal display option and the 'Internal Only' profile selection from both UIs")
            defaultValue: false
        }

        ToggleSetting {
            settingKey: "showDisplayProfiles"
            label: I18n.tr("Show display profiles")
            description: I18n.tr("Show saved display configuration profiles under the manual controls section")
            defaultValue: false
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
            text: I18n.tr("Interface Settings")
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Medium
            color: Theme.surfaceText
        }

        // --- Backdrop Dim Setting Row ---
        Column {
            id: dimSettingRow
            width: parent.width
            spacing: Theme.spacingS

            function loadValue() {
                dimSlider.loadValue();
            }

            RowLayout {
                width: parent.width
                spacing: Theme.spacingM

                DankIcon {
                    name: "palette"
                    size: 22
                    Layout.alignment: Qt.AlignVCenter
                    opacity: 0.8
                }

                Column {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: Theme.spacingXXS
                    StyledText {
                        text: I18n.tr("Backdrop Dim")
                        width: parent.width
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                    }
                    StyledText {
                        text: I18n.tr("Choose the backdrop overlay dim level for the fullscreen settings modal")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        width: parent.width
                        wrapMode: Text.WordWrap
                    }
                }

                Rectangle {
                    id: dimResetBtn
                    width: 32; height: 32
                    radius: Theme.cornerRadius
                    Layout.alignment: Qt.AlignVCenter
                    color: dimResetMa.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                    border.color: dimResetMa.containsMouse ? Theme.primary : Theme.outline
                    border.width: 1
                    opacity: dimSlider.value !== dimSlider.defaultValue ? (dimResetMa.containsMouse ? 1.0 : 0.9) : 0.0
                    visible: opacity > 0
                    scale: dimResetMa.containsMouse ? 1.1 : 1.0
                    
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on opacity { NumberAnimation { duration: 250 } }
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                    DankRipple { 
                        id: dimRip
                        anchors.fill: parent
                        cornerRadius: parent.radius
                        rippleColor: Theme.primary 
                    }

                    DankIcon {
                        name: "restart_alt"
                        size: 18
                        anchors.centerIn: parent
                        color: dimResetMa.containsMouse ? Theme.primary : Theme.surfaceVariantText
                        rotation: dimResetMa.containsMouse ? 90 : 0
                        Behavior on rotation { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: dimResetMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            dimResetAnim.restart();
                            root.saveValue(dimSlider.settingKey, dimSlider.defaultValue / 100);
                        }
                        onPressed: (m) => dimRip.trigger(m.x, m.y)
                    }
                }
            }

            NumberAnimation {
                id: dimResetAnim
                target: dimSlider
                property: "value"
                to: dimSlider.defaultValue
                duration: 300
                easing.type: Easing.OutCubic
            }

            DankSlider {
                id: dimSlider
                property int defaultValue: 20
                property string settingKey: "backdropDim"
                width: parent.width
                minimum: 0
                maximum: 100
                step: 1
                unit: "%"
                
                function loadValue() {
                    const savedVal = root.loadValue(settingKey, defaultValue / 100);
                    value = Math.round(parseFloat(savedVal) * 100);
                }
                Component.onCompleted: loadValue()
                onSliderValueChanged: newValue => {
                    value = newValue;
                    root.saveValue(settingKey, newValue / 100);
                }
            }
        }

        // --- UI Transparency Setting Row ---
        Column {
            id: transSettingRow
            width: parent.width
            spacing: Theme.spacingS

            function loadValue() {
                transSlider.loadValue();
            }

            RowLayout {
                width: parent.width
                spacing: Theme.spacingM

                DankIcon {
                    name: "opacity"
                    size: 22
                    Layout.alignment: Qt.AlignVCenter
                    opacity: 0.8
                }

                Column {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: Theme.spacingXXS
                    StyledText {
                        text: I18n.tr("UI Transparency")
                        width: parent.width
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                    }
                    StyledText {
                        text: I18n.tr("Choose the UI transparency level for the settings modal cards")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        width: parent.width
                        wrapMode: Text.WordWrap
                    }
                }

                Rectangle {
                    id: transResetBtn
                    width: 32; height: 32
                    radius: Theme.cornerRadius
                    Layout.alignment: Qt.AlignVCenter
                    color: transResetMa.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                    border.color: transResetMa.containsMouse ? Theme.primary : Theme.outline
                    border.width: 1
                    opacity: transSlider.value !== transSlider.defaultValue ? (transResetMa.containsMouse ? 1.0 : 0.9) : 0.0
                    visible: opacity > 0
                    scale: transResetMa.containsMouse ? 1.1 : 1.0
                    
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on opacity { NumberAnimation { duration: 250 } }
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                    DankRipple { 
                        id: transRip
                        anchors.fill: parent
                        cornerRadius: parent.radius
                        rippleColor: Theme.primary 
                    }

                    DankIcon {
                        name: "restart_alt"
                        size: 18
                        anchors.centerIn: parent
                        color: transResetMa.containsMouse ? Theme.primary : Theme.surfaceVariantText
                        rotation: transResetMa.containsMouse ? 90 : 0
                        Behavior on rotation { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: transResetMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            transResetAnim.restart();
                            root.saveValue(transSlider.settingKey, transSlider.defaultValue / 100);
                        }
                        onPressed: (m) => transRip.trigger(m.x, m.y)
                    }
                }
            }

            NumberAnimation {
                id: transResetAnim
                target: transSlider
                property: "value"
                to: transSlider.defaultValue
                duration: 300
                easing.type: Easing.OutCubic
            }

            DankSlider {
                id: transSlider
                property int defaultValue: 50
                property string settingKey: "uiTransparency"
                width: parent.width
                minimum: 0
                maximum: 100
                step: 1
                unit: "%"
                
                function loadValue() {
                    const savedVal = root.loadValue(settingKey, defaultValue / 100);
                    value = Math.round(parseFloat(savedVal) * 100);
                }
                Component.onCompleted: loadValue()
                onSliderValueChanged: newValue => {
                    value = newValue;
                    root.saveValue(settingKey, newValue / 100);
                }
            }
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
