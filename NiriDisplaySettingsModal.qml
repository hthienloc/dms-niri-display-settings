import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Common
import qs.Modals.Common
import qs.Services
import qs.Widgets

DankModal {
    id: root

    layerNamespace: "dms:plugins:niriDS"
    keepPopoutsOpen: true

    property int selectedIndex: 0
    property int optionCount: NiriDS.displays ? NiriDS.displays.length : 0
    property rect parentBounds: Qt.rect(0, 0, 0, 0)

    function openCentered() {
        parentBounds = Qt.rect(0, 0, 0, 0);
        backgroundOpacity = 0.5;
        open();
    }

    shouldBeVisible: false
    modalWidth: 400
    modalHeight: (typeof contentLoader !== 'undefined' && contentLoader && contentLoader.item) ? contentLoader.item.implicitHeight : 450
    enableShadow: true
    positioning: parentBounds.width > 0 ? "custom" : "center"

    customPosition: {
        if (parentBounds.width > 0) {
            const centerX = parentBounds.x + (parentBounds.width - modalWidth) / 2;
            const centerY = parentBounds.y + (parentBounds.height - modalHeight) / 2;
            return Qt.point(centerX, centerY);
        }
        return Qt.point(0, 0);
    }

    onBackgroundClicked: () => close()
    onOpened: () => {
        selectedIndex = 0;
        Qt.callLater(() => modalFocusScope.forceActiveFocus());
    }

    modalFocusScope.Keys.onPressed: event => {
        switch (event.key) {
            case Qt.Key_Up:
            case Qt.Key_Backtab:
                selectedIndex = (selectedIndex - 1 + optionCount) % (optionCount || 1);
                event.accepted = true;
                break;
            case Qt.Key_Down:
            case Qt.Key_Tab:
                selectedIndex = (selectedIndex + 1) % (optionCount || 1);
                event.accepted = true;
                break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
                if (optionCount > 0) NiriDS.toggleDisable(NiriDS.displays[selectedIndex]);
                event.accepted = true;
                break;
            case Qt.Key_1: NiriDS.apply("internal_only"); root.close(); event.accepted = true; break;
            case Qt.Key_2: NiriDS.apply("external_only"); root.close(); event.accepted = true; break;
            case Qt.Key_3: NiriDS.apply("extend"); root.close(); event.accepted = true; break;
        }
    }

    content: Component {
        Item {
            implicitHeight: mainColumn.implicitHeight + Theme.spacingL * 2
            width: root.modalWidth

            Column {
                id: mainColumn
                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingL

                // Header
                Item {
                    width: parent.width
                    height: Math.max(headerText.implicitHeight, closeButton.implicitHeight)

                    StyledText {
                        id: headerText
                        text: I18n.tr("Display Settings")
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.surfaceText
                        font.weight: Font.Medium
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    DankActionButton {
                        id: closeButton
                        iconName: "close"
                        iconSize: Theme.iconSize - 4
                        iconColor: Theme.surfaceText
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: () => close()
                    }
                }

                // Section 1: Display Profiles
                Column {
                    width: parent.width
                    spacing: Theme.spacingS

                    StyledText {
                        text: I18n.tr("Project")
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                        font.weight: Font.Medium
                        opacity: 0.6
                        bottomPadding: Theme.spacingS
                    }

                    component ProfileItem: Rectangle {
                        property string profileName
                        property string label
                        property string icon

                        width: parent.width
                        height: 60
                        radius: Theme.cornerRadius
                        color: hoverM.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.08)
                        border.color: hoverM.containsMouse ? Theme.primary : "transparent"
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingL
                            spacing: Theme.spacingL

                            DankIcon {
                                name: icon
                                size: Theme.iconSize
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: label
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceText
                                font.weight: Font.Medium
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: hoverM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                NiriDS.apply(profileName);
                                root.close();
                            }
                        }
                    }

                    ProfileItem { profileName: "internal_only"; label: I18n.tr("PC screen only"); icon: "computer" }
                    ProfileItem { profileName: "extend"; label: I18n.tr("Extend"); icon: "grid_view" }
                    ProfileItem { profileName: "external_only"; label: I18n.tr("Second screen only"); icon: "tv" }
                }

                // Section 2: Manual Output Toggles
                Column {
                    width: parent.width
                    spacing: Theme.spacingS
                    visible: root.optionCount > 0

                    StyledText {
                        text: I18n.tr("Manual Control")
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                        font.weight: Font.Medium
                        opacity: 0.6
                        topPadding: Theme.spacingM
                        bottomPadding: Theme.spacingS
                    }

                    DankListView {
                        width: parent.width
                        spacing: Theme.spacingS
                        height: (50 * root.optionCount) + Theme.spacingS
                        model: ScriptModel { 
                            id: displayModel
                            values: NiriDS.displays 
                        }

                        Connections {
                            target: NiriDS
                            function onDisplaysChanged() { displayModel.values = NiriDS.displays; }
                        }

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            width: parent.width
                            height: 50
                            radius: Theme.cornerRadius

                            color: selectedIndex === index ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : (hoverArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.08))
                            border.color: selectedIndex === index ? Theme.primary : "transparent"
                            border.width: selectedIndex === index ? 1 : 0

                            DankIcon {
                                id: dispIcon
                                name: NiriDS.isInternal(modelData) ? "computer" : "tv"
                                size: Theme.iconSize
                                color: Theme.surfaceText
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.spacingM
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: {
                                    const name = modelData.name || "Unknown";
                                    const model = modelData.model || "";
                                    const isInternal = NiriDS.isInternal(modelData);
                                    return (model ? model : name) + (isInternal ? " (" + I18n.tr("Laptop") + ")" : "");
                                }
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceText
                                font.weight: Font.Medium
                                anchors.left: dispIcon.right
                                anchors.leftMargin: Theme.spacingM
                                anchors.right: statusDot.left
                                anchors.rightMargin: Theme.spacingM
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                id: statusDot
                                anchors.right: parent.right
                                anchors.rightMargin: Theme.spacingM
                                anchors.verticalCenter: parent.verticalCenter
                                width: 8
                                height: 8
                                radius: 4
                                color: modelData.disabled ? Theme.surfaceVariant : "#4CAF50"
                            }

                            MouseArea {
                                id: hoverArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NiriDS.toggleDisable(modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
