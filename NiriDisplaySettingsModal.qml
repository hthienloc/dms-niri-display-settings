import QtQuick
import Quickshell
import qs.Common
import qs.Modals.Common
import qs.Services
import qs.Widgets
import "../dms-common"

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
        NiriDS.setDisplays();
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
        Qt.callLater(() => {
            if (modalFocusScope) modalFocusScope.forceActiveFocus();
        });
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
            case Qt.Key_1: NiriDS.apply("external_only"); root.close(); event.accepted = true; break;
            case Qt.Key_2: NiriDS.apply("extend"); root.close(); event.accepted = true; break;
            case Qt.Key_3: NiriDS.apply("internal_only"); root.close(); event.accepted = true; break;
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

                HeaderRow {
                    title: I18n.tr("Display Settings")
                    onCloseClicked: () => close()
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
                    ShortcutCard {
                        iconName: "tv"
                        label: I18n.tr("External Only")
                        shortcut: "1"
                        onClicked: { NiriDS.apply("external_only"); root.close(); }
                    }
                    ShortcutCard {
                        iconName: "grid_view"
                        label: I18n.tr("Extended")
                        shortcut: "2"
                        onClicked: { NiriDS.apply("extend"); root.close(); }
                    }
                    ShortcutCard {
                        iconName: "computer"
                        label: I18n.tr("Internal Only")
                        shortcut: "3"
                        onClicked: { NiriDS.apply("internal_only"); root.close(); }
                    }
                }

                // Section 2: Manual Output Toggles
                Column {
                    width: parent.width
                    spacing: Theme.spacingS
                    visible: true 

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
                        height: (60 * root.optionCount) + Theme.spacingS
                        
                        // Using ScriptModel which worked before
                        model: ScriptModel { 
                            id: dispModel
                            values: NiriDS.displays 
                        }

                        Connections {
                            target: NiriDS
                            function onDisplaysChanged() { 
                                dispModel.values = [...NiriDS.displays]; 
                                console.log("[NiriDS UI] List refreshed with count:", dispModel.values.length);
                            }
                        }

                        delegate: Rectangle {
                            width: parent.width
                            height: 60
                            radius: Theme.cornerRadius
                            color: selectedIndex === index ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : (itemHover.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.08))
                            border.color: selectedIndex === index ? Theme.primary : "transparent"
                            border.width: selectedIndex === index ? 1 : 0

                            DankIcon {
                                id: iIcon
                                name: (modelData && modelData.name && (modelData.name.toLowerCase().startsWith("edp") || modelData.name.toLowerCase().startsWith("lvds"))) ? "computer" : "tv"
                                size: Theme.iconSize
                                color: Theme.surfaceText
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.spacingL
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: modelData ? (modelData.friendlyName || "Unknown") : "Unknown"
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceText
                                font.weight: Font.Medium
                                anchors.left: iIcon.right
                                anchors.leftMargin: Theme.spacingL
                                anchors.right: iStatus.left
                                anchors.rightMargin: Theme.spacingL
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                            }

                            StatusDot {
                                active: !(modelData && modelData.disabled)
                                anchors.right: parent.right
                                anchors.rightMargin: Theme.spacingL
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            MouseArea {
                                id: itemHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NiriDS.toggleDisable(modelData)
                            }
                        }
                    }

                    StyledText {
                        text: I18n.tr("No displays detected...")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceText
                        opacity: 0.4
                        visible: root.optionCount === 0
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }
}
