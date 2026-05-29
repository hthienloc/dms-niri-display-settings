import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import qs.Common
import qs.Modals.Common
import qs.Services
import qs.Widgets

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

    property string activeProfile: {
        const dummy = NiriDS.displays ? NiriDS.displays.length : 0;
        const dummyMirror = NiriDS.mirrorRunning;
        const dummyOutputs = NiriDS.rawOutputs;

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
        property real brr: isActive ? outerRadius : (index === 3 ? outerRadius : innerRadius)

        property bool hovered: projMouse.containsMouse

        Canvas {
            id: projBg
            anchors.fill: parent
            antialiasing: true

            property color paintColor: isCardDisabled ? Theme.withAlpha(Theme.secondary, 0.02) : (isActive ? Theme.withAlpha(Theme.primary, 0.18) : (projCard.hovered ? Theme.withAlpha(Theme.primary, 0.1) : Theme.withAlpha(Theme.secondary, 0.04)))
            property color paintBorder: isCardDisabled ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.05) : (isActive ? Theme.primary : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15))

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
                ctx.moveTo(x + projCard.tlr, y);
                ctx.lineTo(x + w - projCard.trr, y);
                ctx.arcTo(x + w, y, x + w, y + projCard.trr, projCard.trr);
                ctx.lineTo(x + w, y + h - projCard.brr);
                ctx.arcTo(x + w, y + h, x + w - projCard.brr, y + h, projCard.brr);
                ctx.lineTo(x + projCard.blr, y + h);
                ctx.arcTo(x, y + h, x, y + h - projCard.blr, projCard.blr);
                ctx.lineTo(x, y + projCard.tlr);
                ctx.arcTo(x, y, x + projCard.tlr, y, projCard.tlr);
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
            visible: projCard.isActive
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
                scale: projCard.isActive ? 1.05 : (projCard.hovered ? 1.15 : 1.0)
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
                text: projCard.desc
                font.pixelSize: Theme.fontSizeSmall - 1
                color: Theme.withAlpha(Theme.surfaceText, 0.6)
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                width: parent.width
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

    component ManualDisplayCard: Item {
        id: manualCard
        property int index: 0
        property var displayData
        property bool isActive: !(displayData && displayData.disabled)
        property bool isOnlyEnabled: {
            const enabledCount = (NiriDS?.displays || []).filter(d => !d.disabled).length;
            return enabledCount === 1 && !displayData?.disabled;
        }
        property bool isLoading: false
        property bool hovered: cardHover.containsMouse

        property int totalCount: NiriDS.displays ? NiriDS.displays.length : 0
        property real innerRadius: 6
        property real outerRadius: Theme.cornerRadius * 1.5

        property bool isOddLayout: totalCount % 2 === 1 && totalCount > 1
        property bool isSpan2: isOddLayout && index === totalCount - 1

        width: isSpan2 ? parent.width : (parent.width - Theme.spacingS) / 2
        height: 140
        opacity: 1.0

        property bool isFirstRow: index < 2
        property bool isLastRow: {
            if (totalCount <= 2) return true;
            if (totalCount % 2 === 0) return index >= totalCount - 2;
            return index === totalCount - 1;
        }
        property bool isLeftCol: index % 2 === 0
        property bool isRightCol: index % 2 === 1 || index === totalCount - 1

        // Active card gets all same rounded corners (outerRadius)
        property real tlr: isActive ? outerRadius : ((isFirstRow && isLeftCol) ? outerRadius : innerRadius)
        property real trr: isActive ? outerRadius : ((isFirstRow && isRightCol) ? outerRadius : innerRadius)
        property real blr: isActive ? outerRadius : ((isLastRow && isLeftCol) ? outerRadius : innerRadius)
        property real brr: isActive ? outerRadius : ((isLastRow && isRightCol) ? outerRadius : innerRadius)

        Canvas {
            id: manualBg
            anchors.fill: parent
            antialiasing: true

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
                ctx.moveTo(x + manualCard.tlr, y);
                ctx.lineTo(x + w - manualCard.trr, y);
                ctx.arcTo(x + w, y, x + w, y + manualCard.trr, manualCard.trr);
                ctx.lineTo(x + w, y + h - manualCard.brr);
                ctx.arcTo(x + w, y + h, x + w - manualCard.brr, y + h, manualCard.brr);
                ctx.lineTo(x + manualCard.blr, y + h);
                ctx.arcTo(x, y + h, x, y + h - manualCard.blr, manualCard.blr);
                ctx.lineTo(x, y + manualCard.tlr);
                ctx.arcTo(x, y, x + manualCard.tlr, y, manualCard.tlr);
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
            color: manualCard.isActive ? Theme.withAlpha(Theme.success, 0.15) : Theme.withAlpha(Theme.error, 0.15)
            border.width: 1
            border.color: manualCard.isActive ? Theme.withAlpha(Theme.success, 0.3) : Theme.withAlpha(Theme.error, 0.3)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.spacingS
            anchors.horizontalCenter: parent.horizontalCenter

            RowLayout {
                anchors.centerIn: parent
                spacing: 4
                
                Rectangle {
                    width: 6; height: 6; radius: 3
                    color: manualCard.isActive ? Theme.success : Theme.error
                }
                
                StyledText {
                    text: manualCard.isActive ? I18n.tr("Active") : I18n.tr("Disabled")
                    font.pixelSize: Theme.fontSizeSmall - 2
                    font.weight: Font.Bold
                    color: manualCard.isActive ? Theme.success : Theme.error
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
            cursorShape: manualCard.isOnlyEnabled || manualCard.isLoading ? Qt.ArrowCursor : Qt.PointingHandCursor
            onPressed: (mouse) => { if (!manualCard.isOnlyEnabled && !manualCard.isLoading) manualRipple.trigger(mouse.x, mouse.y); }
            onClicked: {
                if (!manualCard.isOnlyEnabled && !manualCard.isLoading) {
                    manualCard.isLoading = true;
                    NiriDS.toggleDisable(manualCard.displayData);
                    resetTimer.start();
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
    property int optionCount: NiriDS.displays ? NiriDS.displays.length : 0
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
        const displays = NiriDS?.displays || [];
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

    modalFocusScope.Keys.onPressed: event => {
        function getNextEnabledIndex(current, direction) {
            const displays = NiriDS?.displays || [];
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
                    const item = NiriDS?.displays?.[selectedIndex];
                    const enabledCount = (NiriDS?.displays || []).filter(d => !d.disabled).length;
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
            case Qt.Key_4: NiriDS.apply("internal_only"); root.close(); event.accepted = true; break;
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
                        anchors.fill: parent
                        color: Theme.withAlpha(root.blackColor, 0.6)
                    }
                }

                // Centered Dashboard Card
                StyledRect {
                    id: dashboardCard
                    width: Math.min(1080, parent.width - 40)
                    height: Math.min(mainLayout.implicitHeight + Theme.spacingL * 2, parent.height - 40)
                    anchors.centerIn: parent
                    radius: Theme.cornerRadius * 1.8
                    color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                    border.width: 1
                    border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)

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
                                                onClicked: NiriDS.apply("mirror")
                                            }

                                            ProjectionCard {
                                                index: 3
                                                label: I18n.tr("Internal Only")
                                                desc: I18n.tr("Uses only the built-in laptop screen")
                                                iconName: "laptop"
                                                badgeText: "4"
                                                isActive: root.activeProfile === "internal_only"
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
                                                model: NiriDS.displays
                                                delegate: ManualDisplayCard {
                                                    index: index
                                                    displayData: modelData
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
}
