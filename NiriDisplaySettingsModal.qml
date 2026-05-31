import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import Quickshell
import qs.Common
import qs.Modals.Common
import qs.Services
import qs.Widgets
import qs.Modules.Settings.DisplayConfig

DankModal {
    id: root

    layerNamespace: "dms:plugins:niriDS"
    keepPopoutsOpen: true



    readonly property bool isDarkTheme: (Theme.surface.r * 0.299 + Theme.surface.g * 0.587 + Theme.surface.b * 0.114) < 0.5

    // Helper base colors to ensure proper color object coercion in Theme.withAlpha
    readonly property color whiteColor: "#ffffff"
    readonly property color blackColor: "#000000"
    readonly property color roseBgBase: "#F3E8E6"
    readonly property color roseCardBgBase: "#FCF5F3"
    readonly property color roseActivePillBgBase: "#F5DFDE"
    readonly property color roseGreenPillBgBase: "#E8F5E9"

    readonly property color cardColor: isDarkTheme ? Theme.withAlpha(whiteColor, 0.08) : Theme.withAlpha(Theme.surfaceContainerHigh, 0.6)
    readonly property color cardBorderColor: isDarkTheme ? Theme.withAlpha(whiteColor, 0.12) : Theme.withAlpha(Theme.primary, 0.15)

    // Rose/maroon screenshot theme definitions
    readonly property color roseBg: Theme.withAlpha(roseBgBase, 0.85)
    readonly property color roseCardBg: Theme.withAlpha(roseCardBgBase, 0.6)
    readonly property color roseTextDark: "#2A1A1C"
    readonly property color roseAccent: "#A25E6A"
    readonly property color roseAccentAlpha: "#1FA25E6A"
    readonly property color roseActivePillBg: Theme.withAlpha(roseActivePillBgBase, 0.75)
    readonly property color roseGreenDot: "#4CAF50"
    readonly property color roseGreenPillBg: Theme.withAlpha(roseGreenPillBgBase, 0.7)

    readonly property string activeProfile: NiriDS.activeProfile

    property var pluginData: ({})
    readonly property bool disableInternalOption: {
        const val = pluginData ? pluginData.disableInternalOption : undefined;
        if (val !== undefined) return val === true || val === "true";
        const raw = SettingsData.getPluginSetting("niriDS", "disableInternalOption", false);
        return raw === true || raw === "true";
    }
    readonly property bool showDisplayProfiles: {
        const val = pluginData ? pluginData.showDisplayProfiles : undefined;
        if (val !== undefined) return val === true || val === "true";
        const raw = SettingsData.getPluginSetting("niriDS", "showDisplayProfiles", false);
        return raw === true || raw === "true";
    }

    readonly property real backdropDim: {
        const _ = SettingsData.pluginSettings;
        const val = pluginData ? pluginData.backdropDim : undefined;
        if (val !== undefined) return parseFloat(val);
        const raw = SettingsData.getPluginSetting("niriDS", "backdropDim", 0.2);
        return parseFloat(raw);
    }

    readonly property real uiTransparency: {
        const _ = SettingsData.pluginSettings;
        const val = pluginData ? pluginData.uiTransparency : undefined;
        if (val !== undefined) return parseFloat(val);
        const raw = SettingsData.getPluginSetting("niriDS", "uiTransparency", 0.5);
        return parseFloat(raw);
    }
    readonly property var displayProfilesList: {
        const profiles = DisplayConfigState.validatedProfiles || {};
        const list = [];
        const keys = Object.keys(profiles);
        for (const id of keys) {
            const p = profiles[id];
            if (p && typeof p === "object" && p.name && p.id) {
                list.push(p);
            }
        }
        list.sort((a, b) => (b.updatedAt || 0) - (a.updatedAt || 0));
        return list;
    }
    readonly property var filteredDisplays: {
        const list = NiriDS.displays || [];
        if (disableInternalOption) {
            return list.filter(d => !NiriDS.isInternal(d));
        }
        return list;
    }

    onVisibleChanged: {
        if (visible) {
            NiriDS.detectFocusedOutput();
            NiriDS.setDisplays();
        }
    }

    onShouldBeVisibleChanged: {
        if (shouldBeVisible) {
            NiriDS.detectFocusedOutput();
            NiriDS.setDisplays();
        }
    }

    component ProjectionCard: Item {
        id: projCard
        property int index: 0
        property string label
        property string desc
        property string iconName
        property string badgeText
        property bool isActive: false
        property bool isCardDisabled: false
        signal clicked()

        width: (parent.width - Theme.spacingS) / 2
        height: 140
        opacity: isCardDisabled ? 0.45 : 1.0

        // Dynamic Corner Logic (Active button has all same rounded corners)
        property real innerRadius: 6
        property real outerRadius: Theme.cornerRadius * 1.5

        property real tlr: isActive ? outerRadius : (index === 0 ? outerRadius : innerRadius)
        property real trr: isActive ? outerRadius : (index === 1 ? outerRadius : innerRadius)
        property real blr: isActive ? outerRadius : (index === 2 ? outerRadius : innerRadius)
        property real brr: isActive ? outerRadius : ((index === 3 || (index === 2 && root.disableInternalOption)) ? outerRadius : innerRadius)

        property bool hovered: projMouse.containsMouse

        Canvas {
            id: projBg
            anchors.fill: parent
            antialiasing: true

            property real tlr: projCard.tlr
            property real trr: projCard.trr
            property real blr: projCard.blr
            property real brr: projCard.brr

            onTlrChanged: requestPaint()
            onTrrChanged: requestPaint()
            onBlrChanged: requestPaint()
            onBrrChanged: requestPaint()

            property color targetColor: isCardDisabled ? Theme.withAlpha(Theme.secondary, 0.02) : (isActive ? (projCard.hovered ? Theme.withAlpha(Theme.primary, 0.24) : Theme.withAlpha(Theme.primary, 0.18)) : (projCard.hovered ? Theme.withAlpha(Theme.primary, 0.1) : Theme.withAlpha(Theme.secondary, 0.04)))
            property color paintColor: targetColor
            Behavior on paintColor { ColorAnimation { duration: 250 } }
            
            property color targetBorder: isCardDisabled ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.05) : (isActive ? Theme.primary : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15))
            property color paintBorder: targetBorder
            Behavior on paintBorder { ColorAnimation { duration: 250 } }

            onPaintColorChanged: requestPaint()
            onPaintBorderChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d");
                var x = 1, y = 1;
                var w = width - 2, h = height - 2;

                ctx.reset();
                ctx.beginPath();
                ctx.moveTo(x + tlr, y);
                ctx.lineTo(x + w - trr, y);
                ctx.arcTo(x + w, y, x + w, y + trr, trr);
                ctx.lineTo(x + w, y + h - brr);
                ctx.arcTo(x + w, y + h, x + w - brr, y + h, brr);
                ctx.lineTo(x + blr, y + h);
                ctx.arcTo(x, y + h, x, y + h - blr, blr);
                ctx.lineTo(x, y + tlr);
                ctx.arcTo(x, y, x + tlr, y, tlr);
                ctx.closePath();

                ctx.fillStyle = paintColor.toString();
                ctx.fill();
                ctx.strokeStyle = paintBorder.toString();
                ctx.lineWidth = isActive ? 2 : 1;
                ctx.stroke();
            }
        }

        // Ripple Effect
        DankRipple { id: projRipple; anchors.fill: parent; cornerRadius: projCard.tlr; rippleColor: Theme.primary }

        // Badge in Top-Right
        Rectangle {
            width: 20
            height: 20
            radius: 10
            color: Theme.withAlpha(Theme.surfaceText, 0.06)
            anchors.top: parent.top
            anchors.topMargin: Theme.spacingM
            anchors.right: parent.right
            anchors.rightMargin: Theme.spacingM

            StyledText {
                text: projCard.badgeText
                font.pixelSize: Theme.fontSizeSmall - 1
                font.weight: Font.Bold
                color: Theme.withAlpha(Theme.surfaceText, 0.6)
                anchors.centerIn: parent
            }
        }

        // Active Badge in Bottom-Center
        Rectangle {
            visible: projCard.isActive && projCard.index !== 2
            height: 20
            width: 52
            radius: 10
            color: Theme.withAlpha(Theme.primary, 0.2)
            border.width: 1
            border.color: Theme.withAlpha(Theme.primary, 0.3)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.spacingS
            anchors.horizontalCenter: parent.horizontalCenter

            StyledText {
                text: I18n.tr("Active")
                font.pixelSize: Theme.fontSizeSmall - 2
                font.weight: Font.Bold
                color: Theme.primary
                anchors.centerIn: parent
            }
        }

        Column {
            anchors.top: parent.top
            anchors.topMargin: Theme.spacingM
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - Theme.spacingL * 2
            spacing: Theme.spacingXS

            DankIcon {
                id: projIcon
                name: projCard.iconName
                size: 32
                color: projCard.isActive ? Theme.primary : Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
                scale: projCard.isActive ? (projCard.hovered ? 1.15 : 1.05) : (projCard.hovered ? 1.15 : 1.0)
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: 250 } }
            }

            StyledText {
                text: projCard.label
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Bold
                color: projCard.isActive ? Theme.primary : Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
            }

            StyledText {
                visible: !(projCard.index === 2 && NiriDS.mirrorSourceFriendly && NiriDS.mirrorTargetFriendly)
                text: projCard.desc
                font.pixelSize: Theme.fontSizeSmall - 1
                color: Theme.withAlpha(Theme.surfaceText, 0.6)
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                width: parent.width
            }

            // Mirror Routing Chip (replaces description for Mirror card)
            Rectangle {
                visible: projCard.index === 2 && !!(NiriDS.mirrorSourceFriendly && NiriDS.mirrorTargetFriendly)
                width: Math.min(parent.width - Theme.spacingS * 2, mirrorRouteLayout.implicitWidth + 24)
                height: mirrorRouteLayout.implicitHeight + 8
                radius: 10
                color: projCard.isActive ? Theme.withAlpha(Theme.success, 0.15) : Theme.withAlpha(Theme.surfaceText, 0.06)
                border.width: 1
                border.color: projCard.isActive ? Theme.withAlpha(Theme.success, 0.3) : Theme.withAlpha(Theme.surfaceText, 0.12)
                anchors.horizontalCenter: parent.horizontalCenter

                RowLayout {
                    id: mirrorRouteLayout
                    width: parent.width - 24
                    anchors.centerIn: parent
                    spacing: 6
                    
                    Rectangle {
                        width: 6; height: 6; radius: 3
                        color: projCard.isActive ? Theme.success : Theme.surfaceVariantText
                        Layout.alignment: Qt.AlignVCenter
                    }
                    
                    StyledText {
                        id: mirrorRouteText
                        text: NiriDS.mirrorSourceFriendly + " ⇒ " + NiriDS.mirrorTargetFriendly
                        font.pixelSize: Theme.fontSizeSmall - 2
                        font.weight: Font.Bold
                        color: projCard.isActive ? Theme.success : Theme.surfaceVariantText
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }

        MouseArea {
            id: projMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: projCard.isCardDisabled ? Qt.ArrowCursor : Qt.PointingHandCursor
            onPressed: (mouse) => { if (!projCard.isCardDisabled) projRipple.trigger(mouse.x, mouse.y); }
            onClicked: if (!projCard.isCardDisabled) projCard.clicked()
        }
    }

    component ProfileCard: Item {
        id: profCard
        property int cardIndex: 0
        property string label
        property string iconName: "display_settings"
        property bool isActive: false
        signal clicked()

        property int totalCount: root.displayProfilesList ? root.displayProfilesList.length + 1 : 1
        property real innerRadius: 6
        property real outerRadius: Theme.cornerRadius * 1.5

        property bool isOddLayout: totalCount % 2 === 1 && totalCount > 1
        property bool isSpan2: isOddLayout && cardIndex === 0

        width: isSpan2 ? parent.width : (parent.width - Theme.spacingS) / 2
        height: 54
        
        property bool hovered: profMouse.containsMouse

        property int row: {
            if (totalCount === 1) return 0;
            if (isOddLayout) {
                return cardIndex === 0 ? 0 : Math.floor((cardIndex - 1) / 2) + 1;
            } else {
                return Math.floor(cardIndex / 2);
            }
        }
        property int col: {
            if (totalCount === 1) return 0;
            if (isSpan2) return 0;
            if (isOddLayout) {
                return cardIndex === 0 ? 0 : (cardIndex - 1) % 2;
            } else {
                return cardIndex % 2;
            }
        }
        property int totalRows: {
            if (totalCount === 1) return 1;
            if (isOddLayout) {
                return Math.floor((totalCount - 1) / 2) + 1;
            } else {
                return Math.ceil(totalCount / 2);
            }
        }

        property bool isFirstRow: row === 0
        property bool isLastRow: row === totalRows - 1
        property bool isLeftCol: col === 0
        property bool isRightCol: col === 1 || isSpan2

        // Active card gets all same rounded corners (outerRadius)
        property real tlr: isActive ? outerRadius : ((isFirstRow && isLeftCol) ? outerRadius : innerRadius)
        property real trr: isActive ? outerRadius : ((isFirstRow && isRightCol) ? outerRadius : innerRadius)
        property real blr: isActive ? outerRadius : ((isLastRow && isLeftCol) ? outerRadius : innerRadius)
        property real brr: isActive ? outerRadius : ((isLastRow && isRightCol) ? outerRadius : innerRadius)

        Canvas {
            id: profBg
            anchors.fill: parent
            antialiasing: true

            property real tlr: profCard.tlr
            Behavior on tlr { NumberAnimation { duration: 250 } }
            property real trr: profCard.trr
            Behavior on trr { NumberAnimation { duration: 250 } }
            property real blr: profCard.blr
            Behavior on blr { NumberAnimation { duration: 250 } }
            property real brr: profCard.brr
            Behavior on brr { NumberAnimation { duration: 250 } }

            onTlrChanged: requestPaint()
            onTrrChanged: requestPaint()
            onBlrChanged: requestPaint()
            onBrrChanged: requestPaint()

            property bool isCardActive: profCard.isActive
            onIsCardActiveChanged: requestPaint()

            property color targetColor: isCardActive ? (profCard.hovered ? Theme.withAlpha(Theme.primary, 0.24) : Theme.withAlpha(Theme.primary, 0.18)) : (profCard.hovered ? Theme.withAlpha(Theme.primary, 0.1) : Theme.withAlpha(Theme.secondary, 0.04))
            property color paintColor: targetColor
            Behavior on paintColor { ColorAnimation { duration: 250 } }

            property color targetBorder: isCardActive ? Theme.primary : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
            property color paintBorder: targetBorder
            Behavior on paintBorder { ColorAnimation { duration: 250 } }

            onPaintColorChanged: requestPaint()
            onPaintBorderChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d");
                var x = 1, y = 1;
                var w = width - 2, h = height - 2;

                ctx.reset();
                ctx.beginPath();
                ctx.moveTo(x + tlr, y);
                ctx.lineTo(x + w - trr, y);
                ctx.arcTo(x + w, y, x + w, y + trr, trr);
                ctx.lineTo(x + w, y + h - brr);
                ctx.arcTo(x + w, y + h, x + w - brr, y + h, brr);
                ctx.lineTo(x + blr, y + h);
                ctx.arcTo(x, y + h, x, y + h - blr, blr);
                ctx.lineTo(x, y + tlr);
                ctx.arcTo(x, y, x + tlr, y, tlr);
                ctx.closePath();

                ctx.fillStyle = paintColor.toString();
                ctx.fill();
                ctx.strokeStyle = paintBorder.toString();
                ctx.lineWidth = isCardActive ? 2 : 1;
                ctx.stroke();
            }
        }

        DankRipple { id: profRipple; anchors.fill: parent; cornerRadius: profCard.tlr; rippleColor: Theme.primary }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacingM
            anchors.rightMargin: Theme.spacingM
            spacing: Theme.spacingS

            DankIcon {
                name: profCard.iconName
                size: 18
                color: profCard.isActive ? Theme.primary : (profCard.hovered ? Theme.primary : Theme.surfaceText)
                Layout.alignment: Qt.AlignVCenter
                scale: profCard.hovered ? 1.15 : 1.0
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: 250 } }
            }

            StyledText {
                text: profCard.label
                font.pixelSize: Theme.fontSizeSmall
                font.weight: profCard.isActive ? Font.Bold : Font.Normal
                color: profCard.isActive ? Theme.primary : Theme.surfaceText
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                elide: Text.ElideRight
                Behavior on color { ColorAnimation { duration: 250 } }
            }

            DankIcon { 
                name: "check_circle"
                size: 16
                color: Theme.primary
                Layout.alignment: Qt.AlignVCenter
                opacity: profCard.isActive ? 1.0 : 0.0
                scale: profCard.isActive ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 250 } }
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            }
        }

        MouseArea {
            id: profMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: profCard.clicked()
            onPressed: (m) => profRipple.trigger(m.x, m.y)
        }
    }

    component ManualDisplayCard: Item {
        id: manualCard
        property int cardIndex: 0
        property var displayData
        property bool isActive: !(displayData && displayData.disabled)
        property bool isOnlyEnabled: {
            const enabledCount = (root.filteredDisplays || []).filter(d => !d.disabled).length;
            return enabledCount === 1 && !displayData?.disabled;
        }
        property bool isLoading: false
        property bool hovered: cardHover.containsMouse
        // Signal emitted on right-click or press-and-hold to open the advanced panel
        signal requestCustomization(var displayData)

        property int totalCount: root.filteredDisplays ? root.filteredDisplays.length : 0
        property real innerRadius: 6
        property real outerRadius: Theme.cornerRadius * 1.5

        property bool isOddLayout: totalCount % 2 === 1 && totalCount > 1
        property bool isSpan2: isOddLayout && cardIndex === totalCount - 1

        width: isSpan2 ? parent.width : (parent.width - Theme.spacingS) / 2
        height: 140
        opacity: 1.0

        property bool isFirstRow: cardIndex < 2
        property bool isLastRow: {
            if (totalCount <= 2) return true;
            if (totalCount % 2 === 0) return cardIndex >= totalCount - 2;
            return cardIndex === totalCount - 1;
        }
        property bool isLeftCol: cardIndex % 2 === 0
        property bool isRightCol: cardIndex % 2 === 1 || cardIndex === totalCount - 1

        // Active card gets all same rounded corners (outerRadius)
        property real tlr: isActive ? outerRadius : ((isFirstRow && isLeftCol) ? outerRadius : innerRadius)
        property real trr: isActive ? outerRadius : ((isFirstRow && isRightCol) ? outerRadius : innerRadius)
        property real blr: isActive ? outerRadius : ((isLastRow && isLeftCol) ? outerRadius : innerRadius)
        property real brr: isActive ? outerRadius : ((isLastRow && isRightCol) ? outerRadius : innerRadius)

        Canvas {
            id: manualBg
            anchors.fill: parent
            antialiasing: true

            property real tlr: manualCard.tlr
            property real trr: manualCard.trr
            property real blr: manualCard.blr
            property real brr: manualCard.brr

            onTlrChanged: requestPaint()
            onTrrChanged: requestPaint()
            onBlrChanged: requestPaint()
            onBrrChanged: requestPaint()

            property color paintColor: isActive ? Theme.withAlpha(Theme.primary, 0.18) : (manualCard.hovered ? Theme.withAlpha(Theme.primary, 0.1) : Theme.withAlpha(Theme.secondary, 0.04))
            property color paintBorder: isActive ? Theme.primary : (manualCard.hovered ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4) : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15))

            onPaintColorChanged: requestPaint()
            onPaintBorderChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d");
                var x = 1, y = 1;
                var w = width - 2, h = height - 2;

                ctx.reset();
                ctx.beginPath();
                ctx.moveTo(x + tlr, y);
                ctx.lineTo(x + w - trr, y);
                ctx.arcTo(x + w, y, x + w, y + trr, trr);
                ctx.lineTo(x + w, y + h - brr);
                ctx.arcTo(x + w, y + h, x + w - brr, y + h, brr);
                ctx.lineTo(x + blr, y + h);
                ctx.arcTo(x, y + h, x, y + h - blr, blr);
                ctx.lineTo(x, y + tlr);
                ctx.arcTo(x, y, x + tlr, y, tlr);
                ctx.closePath();

                ctx.fillStyle = paintColor.toString();
                ctx.fill();
                ctx.strokeStyle = paintBorder.toString();
                ctx.lineWidth = isActive ? 2 : 1;
                ctx.stroke();
            }
        }

        // Ripple Effect
        DankRipple { id: manualRipple; anchors.fill: parent; cornerRadius: manualCard.tlr; rippleColor: Theme.primary }

        // Status Badge in Bottom-Center (Active/Disabled)
        Rectangle {
            height: 20
            width: 72
            radius: 10
            color: manualCard.isActive ? Theme.withAlpha(Theme.success, 0.15) : Theme.error
            border.width: 1
            border.color: manualCard.isActive ? Theme.withAlpha(Theme.success, 0.3) : Theme.error
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.spacingS
            anchors.horizontalCenter: parent.horizontalCenter

            RowLayout {
                anchors.centerIn: parent
                spacing: 4
                
                Rectangle {
                    width: 6; height: 6; radius: 3
                    color: manualCard.isActive ? Theme.success : "#ffffff"
                }
                
                StyledText {
                    text: manualCard.isActive ? I18n.tr("Active") : I18n.tr("Disabled")
                    font.pixelSize: Theme.fontSizeSmall - 2
                    font.weight: Font.Bold
                    color: manualCard.isActive ? Theme.success : "#ffffff"
                }
            }
        }

        // Content (Icon and Label)
        Column {
            anchors.top: parent.top
            anchors.topMargin: Theme.spacingM
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - Theme.spacingL * 2
            spacing: Theme.spacingXS
            opacity: manualCard.isActive ? 1.0 : 0.6

            DankIcon {
                id: manualIcon
                name: (manualCard.displayData && manualCard.displayData.name && NiriDS.isInternalName(manualCard.displayData.name)) ? "computer" : "tv"
                size: 32
                color: manualCard.isActive ? Theme.primary : Theme.surfaceVariantText
                filled: false
                anchors.horizontalCenter: parent.horizontalCenter
                scale: manualCard.isActive ? 1.05 : (manualCard.hovered ? 1.15 : 1.0)
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: 250 } }
            }

            StyledText {
                text: manualCard.displayData ? (manualCard.displayData.friendlyName || "Unknown") : "Unknown"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Bold
                color: manualCard.isActive ? Theme.primary : Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                width: parent.width
            }
        }

        // Loading Overlay
        Rectangle {
            anchors.fill: parent
            radius: manualCard.tlr
            color: Theme.withAlpha(Theme.surfaceContainerHigh, 0.7)
            visible: manualCard.isLoading

            DankIcon {
                name: "cached"
                size: 24
                color: Theme.primary
                anchors.centerIn: parent
                RotationAnimation on rotation {
                    loops: Animation.Infinite
                    from: 0; to: 360
                    duration: 600
                    running: manualCard.isLoading
                }
            }
        }

        MouseArea {
            id: cardHover
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: manualCard.isOnlyEnabled || manualCard.isLoading ? Qt.ArrowCursor : Qt.PointingHandCursor
            onPressed: (mouse) => { if (!manualCard.isOnlyEnabled && !manualCard.isLoading) manualRipple.trigger(mouse.x, mouse.y); }
            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    manualCard.requestCustomization(manualCard.displayData);
                } else if (mouse.button === Qt.LeftButton) {
                    if (!manualCard.isOnlyEnabled && !manualCard.isLoading) {
                        manualCard.isLoading = true;
                        NiriDS.toggleDisable(manualCard.displayData);
                        resetTimer.start();
                    }
                }
            }
            onPressAndHold: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    manualCard.requestCustomization(manualCard.displayData);
                }
            }
        }

        Timer {
            id: resetTimer
            interval: 1000
            onTriggered: manualCard.isLoading = false
        }
    }

    component DropdownSelector: Item {
        id: dropdown
        property string label
        property string currentText
        property var options: []
        property int currentIndex: 0
        signal optionSelected(int index)

        width: parent.width
        height: 38

        RowLayout {
            anchors.fill: parent
            spacing: Theme.spacingM

            StyledText {
                text: dropdown.label
                font.pixelSize: Theme.fontSizeMedium - 1
                color: roseTextDark
                Layout.fillWidth: true
            }

            Rectangle {
                id: dropdownBtn
                Layout.preferredWidth: 220
                height: 36
                radius: Theme.cornerRadius
                color: dropdownBtnMouse.containsMouse ? Theme.withAlpha(roseAccent, 0.15) : roseCardBg
                border.width: 1
                border.color: dropdownBtnMouse.containsMouse ? roseAccent : Theme.withAlpha(roseTextDark, 0.15)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingM
                    anchors.rightMargin: Theme.spacingM
                    spacing: Theme.spacingS

                    StyledText {
                        text: dropdown.currentText
                        font.pixelSize: Theme.fontSizeMedium - 1
                        color: roseTextDark
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    DankIcon {
                        name: "arrow_drop_down"
                        size: 18
                        color: roseTextDark
                        opacity: 0.7
                    }
                }

                MouseArea {
                    id: dropdownBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        menu.open()
                    }
                }

                Menu {
                    id: menu
                    y: dropdownBtn.height + 4
                    width: dropdownBtn.width
                    
                    background: Rectangle {
                        implicitWidth: dropdownBtn.width
                        color: root.roseCardBg
                        border.color: Theme.withAlpha(root.roseAccent, 0.25)
                        border.width: 1
                        radius: Theme.cornerRadius
                    }

                    Repeater {
                        model: dropdown.options
                        delegate: MenuItem {
                            id: menuItem
                            width: dropdownBtn.width
                            height: 34
                            text: modelData
                            
                            contentItem: StyledText {
                                text: menuItem.text
                                font.pixelSize: Theme.fontSizeMedium - 1
                                color: menuItem.highlighted ? root.roseAccent : root.roseTextDark
                                font.weight: menuItem.highlighted ? Font.DemiBold : Font.Normal
                                verticalAlignment: Text.AlignVCenter
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.spacingM
                            }

                            background: Rectangle {
                                implicitWidth: dropdownBtn.width
                                implicitHeight: 34
                                color: menuItem.highlighted ? Theme.withAlpha(root.roseAccent, 0.1) : "transparent"
                                Behavior on color { ColorAnimation { duration: 100 } }
                            }

                            onTriggered: {
                                dropdown.optionSelected(index)
                            }
                        }
                    }
                }
            }
        }
    }

    property bool isFullScreen: true
    signal fullscreenRequested()
    signal windowedRequested()
    property int resIndex: 0
    property int profileIndex: 0
    property int rateIndex: 0
    property real brightnessValue: 0.8
    property int selectedIndex: 0
    property var activeCustomizationDisplay: null
    property int optionCount: root.filteredDisplays ? root.filteredDisplays.length : 0
    property rect parentBounds: Qt.rect(0, 0, 0, 0)
    property bool hasExternal: {
        const raw = NiriDS.rawOutputs || {};
        const names = Object.keys(raw);
        return names.some(n => n && !NiriDS.isInternalName(n));
    }

    function openCentered() {
        parentBounds = Qt.rect(0, 0, 0, 0);
        backgroundOpacity = 0.5;
        open();
        NiriDS.setDisplays();
    }

    shouldBeVisible: false
    modalWidth: isFullScreen ? screenWidth : 400
    modalHeight: isFullScreen ? screenHeight : ((typeof contentLoader !== 'undefined' && contentLoader && contentLoader.item) ? contentLoader.item.implicitHeight : 450)
    enableShadow: !isFullScreen
    positioning: isFullScreen ? "center" : (parentBounds.width > 0 ? "custom" : "center")

    customPosition: {
        if (!isFullScreen && parentBounds.width > 0) {
            const centerX = parentBounds.x + (parentBounds.width - modalWidth) / 2;
            const centerY = parentBounds.y + (parentBounds.height - modalHeight) / 2;
            return Qt.point(centerX, centerY);
        }
        return Qt.point(0, 0);
    }

    onBackgroundClicked: () => close()
    onOpened: () => {
        const displays = root.filteredDisplays || [];
        const enabledCount = displays.filter(d => !d.disabled).length;
        
        let firstSelectable = 0;
        for (let i = 0; i < displays.length; i++) {
            const isLast = enabledCount === 1 && !displays[i].disabled;
            if (!isLast) {
                firstSelectable = i;
                break;
            }
        }
        selectedIndex = firstSelectable;
        Qt.callLater(() => {
            if (modalFocusScope) modalFocusScope.forceActiveFocus();
        });
    }

    onDialogClosed: () => {
        activeCustomizationDisplay = null;
    }

    modalFocusScope.Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape && customizationOverlay.active) {
            root.activeCustomizationDisplay = null;
            event.accepted = true;
            return;
        }

        function getNextEnabledIndex(current, direction) {
            const displays = root.filteredDisplays || [];
            let count = 0;
            let index = current;
            
            while (count < optionCount) {
                index = (index + direction + optionCount) % optionCount;
                const item = displays[index];
                const isLast = displays.filter(d => !d.disabled).length === 1 && !item.disabled;
                if (!isLast) return index;
                count++;
            }
            return current;
        }

        switch (event.key) {
            case Qt.Key_Up:
            case Qt.Key_Backtab:
                selectedIndex = getNextEnabledIndex(selectedIndex, -1);
                event.accepted = true;
                break;
            case Qt.Key_Down:
            case Qt.Key_Tab:
                selectedIndex = getNextEnabledIndex(selectedIndex, 1);
                event.accepted = true;
                break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
                if (optionCount > 0) {
                    const item = root.filteredDisplays?.[selectedIndex];
                    const enabledCount = (root.filteredDisplays || []).filter(d => !d.disabled).length;
                    const isLast = enabledCount === 1 && !item?.disabled;
                    if (!isLast) NiriDS.toggleDisable(item);
                }
                event.accepted = true;
                break;
            case Qt.Key_1: 
                if (hasExternal) { NiriDS.apply("external_only"); root.close(); }
                event.accepted = true; 
                break;
            case Qt.Key_2: 
                if (hasExternal) { NiriDS.apply("extend"); root.close(); }
                event.accepted = true; 
                break;
            case Qt.Key_3:
                if (hasExternal) { NiriDS.apply("mirror"); root.close(); }
                event.accepted = true; break;
            case Qt.Key_4: 
                if (!root.disableInternalOption) { NiriDS.apply("internal_only"); root.close(); }
                event.accepted = true; 
                break;
        }
    }

    content: Component {
        Item {
            implicitHeight: root.screenHeight
            width: root.screenWidth

            // Full Screen Wrapper (Dashboard UI)
            Item {
                anchors.fill: parent

                // Dark blurred glassmorphic overlay for full screen background
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.close()

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width * 1.5
                        height: parent.height * 1.5
                        color: Theme.withAlpha(root.blackColor, root.backdropDim)
                    }
                }

                // Centered Dashboard Card
                StyledRect {
                    id: dashboardCard
                    width: Math.min(1080, parent.width - 40)
                    height: Math.min(mainLayout.implicitHeight + Theme.spacingL * 2, parent.height - 40)
                    Behavior on height { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                    anchors.centerIn: parent
                    radius: Theme.cornerRadius * 1.8
                    color: Theme.withAlpha(Theme.surfaceContainerHigh, root.uiTransparency)
                    border.width: 1
                    border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                    clip: true

                    // Intercept clicks inside the dashboard card so they don't bubble up to close the modal
                    MouseArea {
                        anchors.fill: parent
                    }

                    ColumnLayout {
                        id: mainLayout
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: Theme.spacingL
                        spacing: Theme.spacingL

                        opacity: customizationOverlay.active ? 0.0 : 1.0
                        enabled: !customizationOverlay.active
                        Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

                        // 1. Dashboard Header (same style as CC widget header)
                        StyledRect {
                            Layout.fillWidth: true
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

                                // Refresh Button
                                Item {
                                    id: fsHeaderRefreshBtnItem
                                    width: 38; height: 38
                                    Layout.alignment: Qt.AlignVCenter
                                    scale: fsHeaderRefreshArea.pressed ? 0.9 : (fsHeaderRefreshArea.containsMouse ? 1.1 : 1.0)
                                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                                    property bool isLoading: false

                                    Timer {
                                        id: fsHeaderLoadingTimer
                                        interval: 600
                                        onTriggered: fsHeaderRefreshBtnItem.isLoading = false
                                    }

                                    MouseArea {
                                        id: fsHeaderRefreshArea
                                        anchors.fill: parent
                                        hoverEnabled: !fsHeaderRefreshBtnItem.isLoading
                                        enabled: !fsHeaderRefreshBtnItem.isLoading
                                        cursorShape: fsHeaderRefreshBtnItem.isLoading ? Qt.ArrowCursor : Qt.PointingHandCursor
                                        onPressed: (mouse) => fsHeaderRefreshRipple.trigger(mouse.x, mouse.y)
                                        onClicked: {
                                            fsHeaderRefreshBtnItem.isLoading = true;
                                            fsHeaderLoadingTimer.start();
                                            NiriDS.setDisplays();
                                        }
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Theme.cornerRadius
                                        color: fsHeaderRefreshArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.4)
                                        border.width: 1
                                        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, fsHeaderRefreshArea.containsMouse ? 0.3 : 0.15)
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        Behavior on border.color { ColorAnimation { duration: 150 } }
                                    }
                                    
                                    DankRipple { id: fsHeaderRefreshRipple; anchors.fill: parent; cornerRadius: Theme.cornerRadius; rippleColor: Theme.primary }

                                    DankIcon {
                                        id: refreshIcon
                                        name: fsHeaderRefreshBtnItem.isLoading ? "cached" : "refresh"
                                        size: 18
                                        color: Theme.primary
                                        anchors.centerIn: parent

                                        SequentialAnimation {
                                            id: hoverSpinAnim
                                            running: fsHeaderRefreshArea.containsMouse && !fsHeaderRefreshBtnItem.isLoading
                                            onStopped: refreshIcon.rotation = 0
                                            NumberAnimation { target: refreshIcon; property: "rotation"; from: 0; to: 45; duration: 200; easing.type: Easing.OutQuad }
                                            NumberAnimation { target: refreshIcon; property: "rotation"; from: 45; to: -45; duration: 400; easing.type: Easing.InOutQuad }
                                            NumberAnimation { target: refreshIcon; property: "rotation"; from: -45; to: 0; duration: 200; easing.type: Easing.InQuad }
                                        }

                                        RotationAnimation on rotation {
                                            from: 0
                                            to: 360
                                            duration: 1000
                                            loops: Animation.Infinite; running: fsHeaderRefreshBtnItem.isLoading
                                            onStopped: refreshIcon.rotation = 0
                                        }
                                    }
                                }
                            }
                        }

                        // 2. Main Content Columns
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingL

                            // Left Column: Projection Modes
                            ColumnLayout {
                                Layout.alignment: Qt.AlignTop
                                Layout.fillWidth: true
                                spacing: Theme.spacingM

                                // Container similar to CC widget for project
                                StyledRect {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: projCol.implicitHeight + Theme.spacingM * 2
                                    radius: Theme.cornerRadius
                                    color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                                    border.width: 1
                                    border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)

                                    Column {
                                        id: projCol
                                        anchors.top: parent.top
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.margins: Theme.spacingM
                                        spacing: Theme.spacingS

                                        RowLayout {
                                            width: parent.width
                                            spacing: Theme.spacingXS
                                            DankIcon { name: "grid_view"; size: 14; color: Theme.surfaceText }
                                            StyledText { text: I18n.tr("Project Modes"); font.pixelSize: Theme.fontSizeSmall; font.weight: Font.Bold; color: Theme.surfaceText; Layout.fillWidth: true }
                                        }

                                        Flow {
                                            id: projFlow
                                            width: parent.width
                                            height: childrenRect.height
                                            spacing: Theme.spacingS

                                            ProjectionCard {
                                                index: 0
                                                label: I18n.tr("External Only")
                                                desc: I18n.tr("Uses only connected monitor(s)")
                                                iconName: "tv"
                                                badgeText: "1"
                                                isActive: root.activeProfile === "external_only"
                                                isCardDisabled: !root.hasExternal
                                                onClicked: NiriDS.apply("external_only")
                                            }

                                            ProjectionCard {
                                                index: 1
                                                label: I18n.tr("Extended Desktop")
                                                desc: I18n.tr("Desktop spans across multiple monitors")
                                                iconName: "picture_in_picture"
                                                badgeText: "2"
                                                isActive: root.activeProfile === "extend"
                                                isCardDisabled: !root.hasExternal
                                                onClicked: NiriDS.apply("extend")
                                            }

                                            ProjectionCard {
                                                index: 2
                                                label: I18n.tr("Mirror Displays")
                                                desc: I18n.tr("Shows the same content on all monitors")
                                                iconName: "screen_share"
                                                badgeText: "3"
                                                isActive: root.activeProfile === "mirror"
                                                isCardDisabled: !root.hasExternal
                                                width: root.disableInternalOption ? parent.width : (parent.width - Theme.spacingS) / 2
                                                onClicked: NiriDS.apply("mirror")
                                            }

                                            ProjectionCard {
                                                index: 3
                                                label: I18n.tr("Internal Only")
                                                desc: I18n.tr("Uses only the built-in laptop screen")
                                                iconName: "laptop"
                                                badgeText: "4"
                                                isActive: root.activeProfile === "internal_only"
                                                visible: !root.disableInternalOption
                                                onClicked: NiriDS.apply("internal_only")
                                            }
                                        }
                                    }
                                }
                            }

                            // Right Column: Manual Control
                            ColumnLayout {
                                Layout.alignment: Qt.AlignTop
                                Layout.fillWidth: true
                                spacing: Theme.spacingM

                                // Container similar to CC widget for manual controls
                                StyledRect {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: manualCol.implicitHeight + Theme.spacingM * 2
                                    radius: Theme.cornerRadius
                                    color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                                    border.width: 1
                                    border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)

                                    Column {
                                        id: manualCol
                                        anchors.top: parent.top
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.margins: Theme.spacingM
                                        spacing: Theme.spacingS

                                        RowLayout {
                                            width: parent.width
                                            spacing: Theme.spacingXS
                                            DankIcon { name: "settings"; size: 14; color: Theme.surfaceText }
                                            StyledText { text: I18n.tr("Manual Control"); font.pixelSize: Theme.fontSizeSmall; font.weight: Font.Bold; color: Theme.surfaceText; Layout.fillWidth: true }
                                        }

                                        Flow {
                                            id: manualFlow
                                            width: parent.width
                                            height: childrenRect.height
                                            spacing: Theme.spacingS

                                            Repeater {
                                                model: root.filteredDisplays
                                                delegate: ManualDisplayCard {
                                                    cardIndex: index
                                                    displayData: modelData
                                                    onRequestCustomization: (d) => { root.activeCustomizationDisplay = d; }
                                                }
                                            }
                                        }
                                    }
                                }

                                // Display Profiles Section (Below Manual Control)
                                StyledRect {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: dmsProfilesCol.implicitHeight + Theme.spacingM * 2
                                    visible: root.showDisplayProfiles
                                    radius: Theme.cornerRadius
                                    color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                                    border.width: 1
                                    border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)

                                    Column {
                                        id: dmsProfilesCol
                                        anchors.top: parent.top
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.margins: Theme.spacingM
                                        spacing: Theme.spacingS

                                        RowLayout {
                                            width: parent.width
                                            spacing: Theme.spacingXS
                                            DankIcon { name: "display_settings"; size: 14; color: Theme.surfaceText }
                                            StyledText { text: I18n.tr("Display Profiles"); font.pixelSize: Theme.fontSizeSmall; font.weight: Font.Bold; color: Theme.surfaceText; Layout.fillWidth: true }
                                        }

                                        Flow {
                                            id: dmsProfilesFlow
                                            width: parent.width
                                            height: childrenRect.height
                                            spacing: Theme.spacingS

                                            ProfileCard {
                                                cardIndex: 0
                                                label: I18n.tr("Auto Select")
                                                iconName: "brightness_auto"
                                                isActive: SettingsData.displayProfileAutoSelect
                                                onClicked: {
                                                    SettingsData.displayProfileAutoSelect = true;
                                                    SettingsData.saveSettings();
                                                    if (DisplayConfigState.matchedProfile) {
                                                        DisplayConfigState.activateProfile(DisplayConfigState.matchedProfile);
                                                    }
                                                }
                                            }

                                            Repeater {
                                                model: root.displayProfilesList
                                                delegate: ProfileCard {
                                                    cardIndex: index + 1
                                                    label: modelData.name
                                                    iconName: "display_settings"
                                                    isActive: !SettingsData.displayProfileAutoSelect && (SettingsData.getActiveDisplayProfile("niri") === modelData.id || DisplayConfigState.matchedProfile === modelData.id)
                                                    onClicked: {
                                                        SettingsData.displayProfileAutoSelect = false;
                                                        SettingsData.saveSettings();
                                                        DisplayConfigState.activateProfile(modelData.id);
                                                    }
                                                }
                                            }
                                        }

                                        StyledText {
                                            text: I18n.tr("No profiles configured")
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: Theme.surfaceVariantText
                                            font.italic: true
                                            width: parent.width
                                            horizontalAlignment: Text.AlignHCenter
                                            visible: root.displayProfilesList.length === 0
                                        }
                                    }
                                }
                            }
                        }
                    } // Close mainLayout early so customizationOverlay is a direct sibling of mainLayout inside dashboardCard

                    // Customization Panel Overlay
                    StyledRect {
                        id: customizationOverlay
                        x: 0
                        width: parent.width
                        height: parent.height
                        radius: parent.radius
                        color: "transparent"
                        border.width: 0
                        z: 10
                        clip: true

                        property bool active: root.activeCustomizationDisplay !== null
                        property var displayData: root.activeCustomizationDisplay

                        y: active ? 0 : -customizationOverlay.height
                        Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

                        visible: active || y > -customizationOverlay.height

                        // Inner rounded card — this clips correctly to the parent's radius
                        Rectangle {
                            anchors.fill: parent
                            radius: customizationOverlay.radius
                            color: "transparent"
                            border.width: 0
                            border.color: "transparent"
                            clip: true
                        }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                            }

                            function getRawTransform(tVal) {
                                const transformMap = {
                                    "Normal": "normal",
                                    "90": "90",
                                    "180": "180",
                                    "270": "270",
                                    "Flipped": "flipped",
                                    "Flipped90": "flipped-90",
                                    "Flipped180": "flipped-180",
                                    "Flipped270": "flipped-270"
                                };
                                return transformMap[tVal] || "normal";
                            }

                            function applySetting(key, val) {
                                if (!displayData) return;
                                const name = displayData.name;
                                const config = {};
                                if (key === "mode") config.mode = val;
                                else if (key === "scale") config.scale = parseFloat(val);
                                else if (key === "transform") config.transform = getRawTransform(val);
                                else if (key === "vrr") config.vrr = (val !== I18n.tr("Off"));

                                NiriService.applyOutputConfig(name, config, (success, msg) => {
                                    if (success) {
                                        const baseOutputs = DisplayConfigState.outputs;
                                        const outputsCopy = JSON.parse(JSON.stringify(baseOutputs || {}));

                                        if (outputsCopy[name]) {
                                            if (key === "mode") {
                                                const idx = outputsCopy[name].modes.findIndex(m => DisplayConfigState.formatMode(m) === val);
                                                if (idx >= 0) outputsCopy[name].current_mode = idx;
                                            } else if (key === "scale") {
                                                if (!outputsCopy[name].logical) outputsCopy[name].logical = {};
                                                outputsCopy[name].logical.scale = parseFloat(val);
                                            } else if (key === "transform") {
                                                if (!outputsCopy[name].logical) outputsCopy[name].logical = {};
                                                outputsCopy[name].logical.transform = val;
                                            } else if (key === "vrr") {
                                                outputsCopy[name].vrr_enabled = (val !== I18n.tr("Off"));
                                            }
                                        }

                                        const identifier = DisplayConfigState.getNiriOutputIdentifier(NiriDS.rawOutputs[name], name);
                                        if (key === "vrr") {
                                            const vrrOnDemand = (val === I18n.tr("On-Demand"));
                                            SettingsData.setNiriOutputSetting(identifier, "vrrOnDemand", vrrOnDemand);
                                            SettingsData.saveSettings();
                                        }

                                        NiriService.generateOutputsConfig(outputsCopy);
                                        NiriDS.setDisplays();
                                    }
                                });
                            }

                            property var modesList: {
                                if (!displayData || !NiriDS.rawOutputs || !NiriDS.rawOutputs[displayData.name])
                                    return [];
                                const raw = NiriDS.rawOutputs[displayData.name];
                                const rawModes = raw.modes || [];
                                const sortedModes = [...rawModes];
                                sortedModes.sort((a, b) => {
                                    if (a.width !== b.width) return b.width - a.width;
                                    if (a.height !== b.height) return b.height - a.height;
                                    return (b.refresh_rate || 0) - (a.refresh_rate || 0);
                                });
                                return sortedModes;
                            }

                            property var modeOptions: {
                                const opts = [];
                                for (let i = 0; i < modesList.length; i++) {
                                    const formatted = DisplayConfigState.formatMode(modesList[i]);
                                    if (!opts.includes(formatted)) {
                                        opts.push(formatted);
                                    }
                                }
                                return opts;
                            }

                            property string currentModeString: {
                                // Niri JSON uses 'is_current', fallback to 'current'
                                const currentMode = modesList.find(m => m.is_current || m.current);
                                return currentMode ? DisplayConfigState.formatMode(currentMode) : (modeOptions.length > 0 ? modeOptions[0] : "");
                            }

                            // Advanced Configuration Header Card (same style as fullscreen UI header)
                            StyledRect {
                                id: overlayHeaderCard
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: Theme.spacingL
                                height: 72
                                radius: Theme.cornerRadius
                                color: Theme.withAlpha(Theme.surfaceContainerHigh, root.uiTransparency)
                                border.width: 1
                                border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingM
                                    spacing: Theme.spacingM

                                    // Display icon badge
                                    Rectangle {
                                        width: 36; height: 36; radius: 18
                                        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2)
                                        DankIcon {
                                            name: (customizationOverlay.displayData && NiriDS.isInternalName(customizationOverlay.displayData.name)) ? "computer" : "tv"
                                            size: 18; color: Theme.primary; anchors.centerIn: parent
                                        }
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 0

                                        StyledText {
                                            text: customizationOverlay.displayData ? customizationOverlay.displayData.friendlyName : ""
                                            font.bold: true
                                            font.pixelSize: Theme.fontSizeMedium
                                            color: Theme.surfaceText
                                        }

                                        StyledText {
                                            text: customizationOverlay.displayData ? (I18n.tr("Advanced Configuration") + " · " + customizationOverlay.displayData.name) : ""
                                            font.pixelSize: Theme.fontSizeSmall - 1
                                            color: Theme.primary
                                            opacity: 0.8
                                        }
                                    }

                                    // Close button
                                    Item {
                                        id: overlayCloseBtn
                                        width: 38; height: 38
                                        Layout.alignment: Qt.AlignVCenter
                                        scale: closeMouse.pressed ? 0.88 : (closeMouse.containsMouse ? 1.1 : 1.0)
                                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: Theme.cornerRadius
                                            color: closeMouse.containsMouse ? Qt.rgba(229/255, 57/255, 53/255, 0.15) : Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.4)
                                            border.width: 1
                                            border.color: closeMouse.containsMouse ? Qt.rgba(229/255, 57/255, 53/255, 0.3) : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                                            Behavior on color { ColorAnimation { duration: 500 } }
                                            Behavior on border.color { ColorAnimation { duration: 500 } }
                                        }

                                        DankIcon {
                                            name: "close"
                                            size: 18
                                            color: closeMouse.containsMouse ? "#e53935" : Theme.primary
                                            rotation: closeMouse.containsMouse ? 360 : 0
                                            anchors.centerIn: parent

                                            Behavior on rotation {
                                                NumberAnimation { duration: 750; easing.type: Easing.OutCubic }
                                            }
                                            Behavior on color {
                                                ColorAnimation { duration: 500 }
                                            }
                                        }

                                        MouseArea {
                                            id: closeMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.activeCustomizationDisplay = null
                                        }

                                        DankRipple {
                                            anchors.fill: parent
                                            cornerRadius: Theme.cornerRadius
                                            rippleColor: closeMouse.containsMouse ? "#e53935" : Theme.primary
                                        }
                                    }
                                }
                            }

                            Flickable {
                                anchors.top: overlayHeaderCard.bottom
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: Theme.spacingL
                                anchors.rightMargin: Theme.spacingL
                                anchors.topMargin: Theme.spacingM
                                anchors.bottomMargin: Theme.spacingS
                                contentHeight: contentCol.implicitHeight
                                clip: true
                                flickableDirection: Flickable.VerticalFlick
                                boundsBehavior: Flickable.StopAtBounds

                                ColumnLayout {
                                    id: contentCol
                                    width: parent.width
                                    spacing: Theme.spacingS

                                    // ── Resolution & Refresh Rate ──────────────────────
                                    StyledRect {
                                        Layout.fillWidth: true
                                        height: resModeCol.implicitHeight + Theme.spacingM * 2
                                        radius: Theme.cornerRadius
                                        color: Theme.withAlpha(Theme.surfaceContainer, 0.5)
                                        border.width: 1
                                        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)

                                        ColumnLayout {
                                            id: resModeCol
                                            anchors { fill: parent; margins: Theme.spacingM }
                                            spacing: Theme.spacingS

                                            RowLayout {
                                                spacing: Theme.spacingXS
                                                DankIcon { name: "aspect_ratio"; size: 14; color: Theme.primary }
                                                StyledText {
                                                    text: I18n.tr("Resolution & Refresh Rate")
                                                    font.pixelSize: Theme.fontSizeSmall
                                                    font.weight: Font.DemiBold
                                                    color: Theme.primary
                                                    Layout.fillWidth: true
                                                }
                                            }

                                            NiriDankDropdown {
                                                id: resDropdown
                                                Layout.fillWidth: true
                                                dropdownWidth: parent.width
                                                currentValue: customizationOverlay.currentModeString
                                                options: customizationOverlay.modeOptions
                                                onValueChanged: (val) => { customizationOverlay.applySetting("mode", val); }
                                            }
                                        }
                                    }

                                    // ── Scale & Transform ──────────────────────────────
                                    StyledRect {
                                        Layout.fillWidth: true
                                        height: scaleTransformCol.implicitHeight + Theme.spacingM * 2
                                        radius: Theme.cornerRadius
                                        color: Theme.withAlpha(Theme.surfaceContainer, 0.5)
                                        border.width: 1
                                        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)

                                        ColumnLayout {
                                            id: scaleTransformCol
                                            anchors { fill: parent; margins: Theme.spacingM }
                                            spacing: Theme.spacingS

                                            RowLayout {
                                                spacing: Theme.spacingXS
                                                DankIcon { name: "open_with"; size: 14; color: Theme.primary }
                                                StyledText {
                                                    text: I18n.tr("Scale & Transform")
                                                    font.pixelSize: Theme.fontSizeSmall
                                                    font.weight: Font.DemiBold
                                                    color: Theme.primary
                                                    Layout.fillWidth: true
                                                }
                                            }

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: Theme.spacingM

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: Theme.spacingXS
                                                    StyledText {
                                                        text: I18n.tr("Scale")
                                                        font.pixelSize: Theme.fontSizeSmall
                                                        color: Theme.surfaceVariantText
                                                    }
                                                    NiriDankDropdown {
                                                        id: scaleDrop
                                                        Layout.fillWidth: true
                                                        dropdownWidth: parent.width
                                                        property var scaleOptions: ["0.5", "0.75", "1", "1.25", "1.5", "1.75", "2", "2.25", "2.5", "2.75", "3"]
                                                        currentValue: {
                                                            if (!customizationOverlay.displayData) return "1";
                                                            const raw = NiriDS.rawOutputs[customizationOverlay.displayData.name];
                                                            const scale = (raw && raw.logical) ? (raw.logical.scale || 1.0) : 1.0;
                                                            // Match against option strings exactly
                                                            const str = parseFloat(scale.toFixed(2)).toString();
                                                            return scaleOptions.includes(str) ? str : str;
                                                        }
                                                        options: scaleOptions
                                                        onValueChanged: (val) => { customizationOverlay.applySetting("scale", val); }
                                                    }
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: Theme.spacingXS
                                                    StyledText {
                                                        text: I18n.tr("Transform")
                                                        font.pixelSize: Theme.fontSizeSmall
                                                        color: Theme.surfaceVariantText
                                                    }
                                                    NiriDankDropdown {
                                                        id: transformDrop
                                                        Layout.fillWidth: true
                                                        dropdownWidth: parent.width
                                                        currentValue: {
                                                            if (!customizationOverlay.displayData) return I18n.tr("Normal");
                                                            const raw = NiriDS.rawOutputs[customizationOverlay.displayData.name];
                                                            const transform = (raw && raw.logical) ? (raw.logical.transform || "Normal") : "Normal";
                                                            const t = transform === "normal" ? "Normal" : transform;
                                                            return DisplayConfigState.getTransformLabel(t);
                                                        }
                                                        options: [I18n.tr("Normal"), I18n.tr("90°"), I18n.tr("180°"), I18n.tr("270°"), I18n.tr("Flipped"), I18n.tr("Flipped 90°"), I18n.tr("Flipped 180°"), I18n.tr("Flipped 270°")]
                                                        onValueChanged: (val) => { customizationOverlay.applySetting("transform", val); }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // ── VRR ───────────────────────────────────────────
                                    StyledRect {
                                        Layout.fillWidth: true
                                        height: vrrCol.implicitHeight + Theme.spacingM * 2
                                        radius: Theme.cornerRadius
                                        color: Theme.withAlpha(Theme.surfaceContainer, 0.5)
                                        border.width: 1
                                        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)

                                        ColumnLayout {
                                            id: vrrCol
                                            anchors { fill: parent; margins: Theme.spacingM }
                                            spacing: Theme.spacingS

                                            RowLayout {
                                                spacing: Theme.spacingXS
                                                DankIcon { name: "speed"; size: 14; color: Theme.primary }
                                                StyledText {
                                                    text: I18n.tr("Variable Refresh Rate")
                                                    font.pixelSize: Theme.fontSizeSmall
                                                    font.weight: Font.DemiBold
                                                    color: Theme.primary
                                                    Layout.fillWidth: true
                                                }
                                            }

                                            NiriDankDropdown {
                                                id: vrrDrop
                                                Layout.fillWidth: true
                                                dropdownWidth: parent.width
                                                currentValue: {
                                                    if (!customizationOverlay.displayData) return I18n.tr("Off");
                                                    const name = customizationOverlay.displayData.name;
                                                    const identifier = DisplayConfigState.getNiriOutputIdentifier(NiriDS.rawOutputs[name], name);
                                                    const niriSettings = SettingsData.getNiriOutputSettings(identifier);
                                                    if (niriSettings && niriSettings.vrrOnDemand) return I18n.tr("On-Demand");
                                                    const raw = NiriDS.rawOutputs[name];
                                                    const vrrEnabled = raw && (raw.vrr_enabled || raw.variable_refresh_rate === "enabled" || raw.variable_refresh_rate === "on");
                                                    return vrrEnabled ? I18n.tr("On") : I18n.tr("Off");
                                                }
                                                options: [I18n.tr("Off"), I18n.tr("On"), I18n.tr("On-Demand")]
                                                onValueChanged: (val) => { customizationOverlay.applySetting("vrr", val); }
                                            }
                                        }
                                    }

                                    // ── Layout ────────────────────────────────────────
                                    StyledRect {
                                        Layout.fillWidth: true
                                        height: 56
                                        radius: Theme.cornerRadius
                                        color: Theme.withAlpha(Theme.surfaceContainer, 0.5)
                                        border.width: 1
                                        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)

                                        RowLayout {
                                            anchors { fill: parent; leftMargin: Theme.spacingM; rightMargin: Theme.spacingM }
                                            spacing: Theme.spacingS

                                            DankIcon { name: "view_column"; size: 16; color: Theme.surfaceText }

                                            StyledText {
                                                text: I18n.tr("Center Single Column")
                                                font.pixelSize: Theme.fontSizeMedium - 1
                                                font.weight: Font.Medium
                                                color: Theme.surfaceText
                                                Layout.fillWidth: true
                                            }

                                            DankToggle {
                                                id: centerSingleColumnToggle
                                                checked: {
                                                    if (!customizationOverlay.displayData) return false;
                                                    const name = customizationOverlay.displayData.name;
                                                    const identifier = DisplayConfigState.getNiriOutputIdentifier(NiriDS.rawOutputs[name], name);
                                                    const niriSettings = SettingsData.getNiriOutputSettings(identifier);
                                                    return (niriSettings && niriSettings.layout && niriSettings.layout.alwaysCenterSingleColumn) ?? false;
                                                }
                                                onToggled: (checked) => {
                                                    if (!customizationOverlay.displayData) return;
                                                    const name = customizationOverlay.displayData.name;
                                                    const identifier = DisplayConfigState.getNiriOutputIdentifier(NiriDS.rawOutputs[name], name);
                                                    const niriSettings = SettingsData.getNiriOutputSettings(identifier) || {};
                                                    const layout = niriSettings.layout || {};
                                                    if (checked) layout.alwaysCenterSingleColumn = true;
                                                    else delete layout.alwaysCenterSingleColumn;
                                                    niriSettings.layout = Object.keys(layout).length > 0 ? layout : null;
                                                    SettingsData.setNiriOutputSetting(identifier, "layout", niriSettings.layout);
                                                    SettingsData.saveSettings();
                                                    NiriService.generateOutputsConfig(DisplayConfigState.outputs);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                    }
                }
            }
        }
    }
}

