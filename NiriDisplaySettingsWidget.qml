import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import qs.Services

PluginComponent {
    id: root

    popoutWidth: 320
    popoutHeight: 0

    // --- CC Support ---
    ccWidgetIcon: "computer"
    ccWidgetPrimaryText: "Display Settings"
    ccWidgetSecondaryText: {
        switch (root.activeProfile) {
            case "internal_only": return "Internal Only";
            case "external_only": return "External Only";
            case "extend": return "Extended";
            case "mirror": return "Mirror";
            default: return NiriDS.displays.length + " displays";
        }
    }
    ccWidgetIsActive: root.activeProfile !== "internal_only" && root.activeProfile !== ""
    ccDetailHeight: 480

    ccDetailContent: Component {
        ScrollView {
            anchors.fill: parent
            clip: false
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff
            
            Loader {
                width: parent.width
                sourceComponent: niriWidgetContent
                readonly property bool inCC: true
            }
        }
    }

    // --- Popout Content ---
    popoutContent: Component {
        PopoutComponent {
            id: popoutContainer
            headerText: ""
            detailsText: ""
            showCloseButton: false
            
            Loader {
                width: parent.width
                sourceComponent: niriWidgetContent
                readonly property bool inCC: false
            }
        }
    }

    readonly property bool hasExternal: {
        const raw = NiriDS.rawOutputs || {};
        return Object.keys(raw).some(n => n && !NiriDS.isInternalName(n));
    }

    readonly property string activeProfile: {
        const list = NiriDS.displays || [];
        if (list.length === 0) return "";
        const internal = list.filter(d => NiriDS.isInternal(d));
        const external = list.filter(d => !NiriDS.isInternal(d));
        
        const anyInternalEnabled = internal.some(d => !d.disabled);
        const anyExternalEnabled = external.some(d => !d.disabled);
        
        if (anyInternalEnabled && !anyExternalEnabled) {
            return "internal_only";
        }
        if (!anyInternalEnabled && anyExternalEnabled) {
            return "external_only";
        }
        if (anyInternalEnabled && anyExternalEnabled) {
            return NiriDS.mirrorRunning ? "mirror" : "extend";
        }
        return "";
    }

    readonly property int optionCount: NiriDS.displays ? NiriDS.displays.length : 0

    Component {
        id: niriWidgetContent
        Column {
            id: mainCol; width: parent.width; spacing: Theme.spacingM
            readonly property bool inCC: (parent && parent.inCC) || false
            padding: inCC ? 16 : 0
            topPadding: 0
            bottomPadding: inCC ? 16 : 2

            // Premium Header Card (with Refresh but NO Fullscreen button)
            StyledRect {
                width: parent.width - (mainCol.inCC ? 32 : 0)
                anchors.horizontalCenter: parent.horizontalCenter
                height: 72
                radius: Theme.cornerRadius
                color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                border.width: 1
                border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                

                RowLayout {
                    anchors.fill: parent; anchors.margins: Theme.spacingM; spacing: Theme.spacingM
                    Rectangle {
                        width: 36; height: 36; radius: 18; color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2)
                        DankIcon {
                            name: "monitor"
                            size: 18
                            color: Theme.primary
                            anchors.centerIn: parent
                        }
                    }

                    Column {
                        Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; spacing: 0
                        StyledText {
                            text: I18n.tr("Display Settings")
                            font.bold: true; font.pixelSize: Theme.fontSizeMedium; color: Theme.surfaceText
                        }
                        StyledText {
                            text: root.optionCount + " " + I18n.tr("displays detected")
                            font.pixelSize: Theme.fontSizeSmall - 1; color: Theme.primary; opacity: 0.8
                        }
                    }

                    Item {
                        id: refreshBtnItem
                        width: 38; height: 38
                        Layout.alignment: Qt.AlignVCenter
                        scale: refreshArea.pressed ? 0.9 : (refreshArea.containsMouse ? 1.1 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                        property bool isLoading: false

                        Timer {
                            id: loadingTimer
                            interval: 600
                            onTriggered: refreshBtnItem.isLoading = false
                        }

                        MouseArea {
                            id: refreshArea
                            anchors.fill: parent
                            hoverEnabled: !refreshBtnItem.isLoading
                            enabled: !refreshBtnItem.isLoading
                            cursorShape: refreshBtnItem.isLoading ? Qt.ArrowCursor : Qt.PointingHandCursor
                            onPressed: (mouse) => refreshRipple.trigger(mouse.x, mouse.y)
                            onClicked: {
                                refreshBtnItem.isLoading = true;
                                loadingTimer.start();
                                NiriDS.setDisplays();
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.cornerRadius
                            color: refreshArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.4)
                            border.width: 1
                            border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, refreshArea.containsMouse ? 0.3 : 0.15)
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                        }

                        DankIcon {
                            id: refreshIcon
                            name: refreshBtnItem.isLoading ? "cached" : "refresh"
                            size: 20
                            color: Theme.primary
                            anchors.centerIn: parent

                            SequentialAnimation {
                                id: hoverSpinAnim
                                running: refreshArea.containsMouse && !refreshBtnItem.isLoading
                                onStopped: refreshIcon.rotation = 0
                                NumberAnimation { target: refreshIcon; property: "rotation"; from: 0; to: 45; duration: 200; easing.type: Easing.OutQuad }
                                NumberAnimation { target: refreshIcon; property: "rotation"; from: 45; to: -45; duration: 400; easing.type: Easing.InOutQuad }
                                NumberAnimation { target: refreshIcon; property: "rotation"; from: -45; to: 0; duration: 200; easing.type: Easing.InQuad }
                            }

                            RotationAnimation on rotation {
                                from: 0
                                to: 360
                                duration: 1000
                                loops: Animation.Infinite; running: refreshBtnItem.isLoading
                                onStopped: refreshIcon.rotation = 0
                            }
                        }

                        DankRipple {
                            id: refreshRipple
                            rippleColor: Theme.primary
                            cornerRadius: Theme.cornerRadius
                            anchors.fill: parent
                        }
                    }
                }
            }

            // Section 1: Display Profiles (Projection Modes)
            StyledRect {
                id: profileSection
                width: parent.width - (mainCol.inCC ? 32 : 0)
                anchors.horizontalCenter: parent.horizontalCenter
                height: profileCol.implicitHeight + Theme.spacingM * 2
                radius: Theme.cornerRadius
                color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                border.width: 1
                border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)


                Column {
                    id: profileCol
                    anchors.fill: parent; anchors.margins: Theme.spacingM
                    spacing: Theme.spacingS

                    RowLayout {
                        anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: 4; anchors.rightMargin: 4
                        spacing: Theme.spacingXS; width: parent.width
                        DankIcon { name: "grid_view"; size: 14; color: Theme.surfaceText }
                        StyledText { text: I18n.tr("Project Modes"); font.pixelSize: Theme.fontSizeSmall; font.weight: Font.Bold; color: Theme.surfaceText; Layout.fillWidth: true }
                    }

                    Column {
                        id: profileLayout; width: parent.width; spacing: 4
                        
                        ShortcutCard {
                            width: parent.width
                            iconName: "tv"
                            label: I18n.tr("External Only")
                            shortcut: "1"
                            disabled: !root.hasExternal
                            isActive: root.activeProfile === "external_only"
                            isFirst: true
                            onClicked: { NiriDS.apply("external_only"); }
                        }
                        ShortcutCard {
                            width: parent.width
                            iconName: "picture_in_picture"
                            label: I18n.tr("Extended")
                            shortcut: "2"
                            disabled: !root.hasExternal
                            isActive: root.activeProfile === "extend"
                            onClicked: { NiriDS.apply("extend"); }
                        }
                        ShortcutCard {
                            width: parent.width
                            iconName: "screen_share"
                            label: I18n.tr("Mirror")
                            shortcut: "3"
                            disabled: !root.hasExternal
                            isActive: root.activeProfile === "mirror"
                            onClicked: { NiriDS.apply("mirror"); }
                        }
                        ShortcutCard {
                            width: parent.width
                            iconName: "computer"
                            label: I18n.tr("Internal Only")
                            shortcut: "4"
                            isActive: root.activeProfile === "internal_only"
                            isLast: true
                            onClicked: { NiriDS.apply("internal_only"); }
                        }
                    }
                }
            }

            // Section 2: Manual Output Toggles
            StyledRect {
                id: manualSection
                width: parent.width - (mainCol.inCC ? 32 : 0)
                anchors.horizontalCenter: parent.horizontalCenter
                height: manualCol.implicitHeight + Theme.spacingM * 2
                visible: root.optionCount > 0
                radius: Theme.cornerRadius
                color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                border.width: 1
                border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)


                Column {
                    id: manualCol
                    anchors.fill: parent; anchors.margins: Theme.spacingM
                    spacing: Theme.spacingS

                    RowLayout {
                        anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: 4; anchors.rightMargin: 4
                        spacing: Theme.spacingXS; width: parent.width
                        DankIcon { name: "tune"; size: 14; color: Theme.surfaceText }
                        StyledText { text: I18n.tr("Manual Control"); font.pixelSize: Theme.fontSizeSmall; font.weight: Font.Bold; color: Theme.surfaceText; Layout.fillWidth: true }
                    }

                    Column {
                        id: manualLayout; width: parent.width; spacing: 4

                        Repeater {
                            model: NiriDS.displays
                            delegate: Item {
                                id: manualItem
                                width: parent.width
                                implicitHeight: 48
                                opacity: isOnlyEnabled && !modelData?.disabled ? 0.5 : 1.0

                                property bool isOnlyEnabled: {
                                    const enabledCount = (NiriDS?.displays || []).filter(d => !d.disabled).length;
                                    return enabledCount === 1 && !(modelData?.disabled);
                                }
                                property bool isOutputActive: !(modelData && modelData.disabled)
                                property bool hovered: itemHover.containsMouse

                                Canvas {
                                    id: cardBg
                                    anchors.fill: parent
                                    property real innerRadius: 6
                                    property real outerRadius: 12
                                    property bool isFirst: index === 0
                                    property bool isLast: index === NiriDS.displays.length - 1
                                    
                                    property real tlr: manualItem.isOutputActive ? 24 : (isFirst ? outerRadius : innerRadius)
                                    property real trr: manualItem.isOutputActive ? 24 : (isFirst ? outerRadius : innerRadius)
                                    property real blr: manualItem.isOutputActive ? 24 : (isLast ? outerRadius : innerRadius)
                                    property real brr: manualItem.isOutputActive ? 24 : (isLast ? outerRadius : innerRadius)

                                    property real tlrAnim: tlr; Behavior on tlrAnim { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                                    property real trrAnim: trr; Behavior on trrAnim { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                                    property real blrAnim: blr; Behavior on blrAnim { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                                    property real brrAnim: brr; Behavior on brrAnim { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }

                                    property color paintColor: manualItem.isOnlyEnabled ? "transparent" : (manualItem.isOutputActive
                                        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.18)
                                        : manualItem.hovered
                                            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1)
                                            : Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.04))
                                    
                                    property color paintBorder: manualItem.isOnlyEnabled ? Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.05) : (manualItem.isOutputActive
                                        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.6)
                                        : manualItem.hovered
                                            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4)
                                            : Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.15))

                                    onTlrAnimChanged: if (width > 0) requestPaint()
                                    onTrrAnimChanged: if (width > 0) requestPaint()
                                    onBlrAnimChanged: if (width > 0) requestPaint()
                                    onBrrAnimChanged: if (width > 0) requestPaint()
                                    onPaintColorChanged: if (width > 0) requestPaint()
                                    onPaintBorderChanged: if (width > 0) requestPaint()

                                    onPaint: {
                                        var ctx = getContext("2d");
                                        var x = 1, y = 1;
                                        var w = width - 2, h = height - 2;
                                        
                                        ctx.reset();
                                        ctx.beginPath();
                                        ctx.moveTo(x + tlrAnim, y);
                                        ctx.lineTo(x + w - trrAnim, y);
                                        ctx.arcTo(x + w, y, x + w, y + trrAnim, trrAnim);
                                        ctx.lineTo(x + w, y + h - brrAnim);
                                        ctx.arcTo(x + w, y + h, x + w - brrAnim, y + h, brrAnim);
                                        ctx.lineTo(x + blrAnim, y + h);
                                        ctx.arcTo(x, y + h, x, y + h - blrAnim, blrAnim);
                                        ctx.lineTo(x, y + tlrAnim);
                                        ctx.arcTo(x, y, x + tlrAnim, y, tlrAnim);
                                        ctx.closePath();
                                        
                                        ctx.fillStyle = paintColor.toString();
                                        ctx.fill();
                                        ctx.strokeStyle = paintBorder.toString();
                                        ctx.lineWidth = 1;
                                        ctx.stroke();
                                    }

                                    Rectangle { 
                                        anchors.fill: parent; radius: parent.tlrAnim; color: "white"
                                        anchors.margins: 0.5
                                        opacity: manualItem.hovered && !manualItem.isOnlyEnabled ? 0.05 : 0; Behavior on opacity { NumberAnimation { duration: 150 } } 
                                    }
                                }

                                DankRipple { id: pRip; anchors.fill: parent; cornerRadius: cardBg.tlrAnim; rippleColor: Theme.primary }

                                DankIcon {
                                    id: iIcon
                                    name: (modelData && modelData.name && NiriDS.isInternalName(modelData.name)) ? "computer" : "tv"
                                    size: Theme.iconSize - 4
                                    color: Theme.surfaceText
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.spacingM
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    text: modelData ? (modelData.friendlyName || "Unknown") : "Unknown"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceText
                                    font.weight: Font.Medium
                                    anchors.left: iIcon.right
                                    anchors.leftMargin: Theme.spacingM
                                    anchors.right: statusIconContainer.left
                                    anchors.rightMargin: Theme.spacingM
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight
                                }

                                Item {
                                    id: statusIconContainer
                                    width: 16
                                    height: 16
                                    anchors.right: parent.right
                                    anchors.rightMargin: Theme.spacingM
                                    anchors.verticalCenter: parent.verticalCenter

                                    Rectangle {
                                        id: statusDotRect
                                        width: 8; height: 8; radius: 4
                                        anchors.centerIn: parent
                                        color: manualItem.isOutputActive ? Theme.success : Theme.error
                                        Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.OutExpo } }
                                        visible: !manualItem.isLoading
                                    }

                                    DankIcon {
                                        name: "cached"
                                        size: 14
                                        color: Theme.surfaceVariant
                                        anchors.centerIn: parent
                                        visible: manualItem.isLoading
                                        RotationAnimation on rotation {
                                            loops: Animation.Infinite
                                            from: 0; to: 360
                                            duration: 600
                                            running: manualItem.isLoading
                                        }
                                    }
                                }

                                property bool isLoading: false

                                MouseArea {
                                    id: itemHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: manualItem.isOnlyEnabled || manualItem.isLoading ? Qt.ArrowCursor : Qt.PointingHandCursor
                                    onPressed: (mouse) => { if (!manualItem.isLoading) pRip.trigger(mouse.x, mouse.y); }
                                    onClicked: {
                                        if (!manualItem.isOnlyEnabled && !manualItem.isLoading) {
                                            manualItem.isLoading = true;
                                            NiriDS.toggleDisable(modelData);
                                            // Reset loading state after a timeout just in case it fails or the array replacement takes time
                                            resetTimer.start();
                                        }
                                    }
                                }
                                
                                Timer {
                                    id: resetTimer
                                    interval: 1000
                                    onTriggered: manualItem.isLoading = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}