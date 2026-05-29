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

    component ProjectionCard: StyledRect {
        id: projCard
        property string label
        property string desc
        property string iconName
        property string badgeText
        property bool isActive: false
        property bool isCardDisabled: false
        signal clicked()

        width: (parent.width - Theme.spacingL) / 2
        height: 140
        radius: Theme.cornerRadius * 1.5
        color: isCardDisabled ? Theme.withAlpha(Theme.surfaceVariant, 0.02) : (isActive ? roseActivePillBg : roseCardBg)
        border.width: isActive ? 2 : 1
        border.color: isCardDisabled ? Theme.withAlpha(Theme.surfaceVariant, 0.08) : (isActive ? roseAccent : Theme.withAlpha(roseAccent, 0.15))
        opacity: isCardDisabled ? 0.45 : 1.0

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        // Badge in Top-Right
        Rectangle {
            width: 20
            height: 20
            radius: 10
            color: Theme.withAlpha(roseTextDark, 0.06)
            anchors.top: parent.top
            anchors.topMargin: Theme.spacingM
            anchors.right: parent.right
            anchors.rightMargin: Theme.spacingM

            StyledText {
                text: projCard.badgeText
                font.pixelSize: Theme.fontSizeSmall - 1
                font.weight: Font.Bold
                color: Theme.withAlpha(roseTextDark, 0.6)
                anchors.centerIn: parent
            }
        }

        // Active Badge in Top-Left
        Rectangle {
            visible: projCard.isActive
            height: 20
            width: 52
            radius: 10
            color: roseActivePillBg
            border.width: 1
            border.color: Theme.withAlpha(roseAccent, 0.3)
            anchors.top: parent.top
            anchors.topMargin: Theme.spacingM
            anchors.left: parent.left
            anchors.leftMargin: Theme.spacingM

            StyledText {
                text: I18n.tr("Active")
                font.pixelSize: Theme.fontSizeSmall - 2
                font.weight: Font.Bold
                color: roseAccent
                anchors.centerIn: parent
            }
        }

        Column {
            anchors.centerIn: parent
            width: parent.width - Theme.spacingL * 2
            spacing: Theme.spacingXS

            DankIcon {
                name: projCard.iconName
                size: 32
                color: projCard.isActive ? roseAccent : roseTextDark
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                text: projCard.label
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Bold
                color: roseTextDark
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
            }

            StyledText {
                text: projCard.desc
                font.pixelSize: Theme.fontSizeSmall - 1
                color: Theme.withAlpha(roseTextDark, 0.6)
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
            onClicked: if (!projCard.isCardDisabled) projCard.clicked()
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

    property bool isFullScreen: false
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
            implicitHeight: root.isFullScreen ? root.screenHeight : (mainColumn.implicitHeight + Theme.spacingL * 2)
            width: root.isFullScreen ? root.screenWidth : root.modalWidth

            Column {
                id: mainColumn
                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingL
                visible: !root.isFullScreen

                // Premium Header Card matching DankKDEConnect
                StyledRect {
                    width: parent.width
                    height: 72
                    radius: Theme.cornerRadius
                    color: root.cardColor
                    border.width: 1
                    border.color: root.cardBorderColor


                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingM
                        spacing: Theme.spacingM

                        Rectangle {
                            width: 42
                            height: 42
                            radius: 21
                            color: Theme.withAlpha(Theme.primary, 0.2)
                            
                            DankIcon {
                                name: "monitor"
                                size: 22
                                color: Theme.primary
                                anchors.centerIn: parent
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            
                            StyledText {
                                Layout.fillWidth: true
                                text: I18n.tr("Display Settings")
                                font.bold: true
                                font.pixelSize: Theme.fontSizeLarge
                                color: Theme.surfaceText
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: root.optionCount + " " + I18n.tr("displays detected")
                                font.pixelSize: Theme.fontSizeSmall - 1
                                color: Theme.primary
                                opacity: 0.8
                            }
                        }

                        Item {
                            width: 38
                            height: 38
                            Layout.alignment: Qt.AlignVCenter

                            MouseArea {
                                id: refreshArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NiriDS.setDisplays()
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: Theme.cornerRadius
                                color: refreshArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.15) : Theme.withAlpha(Theme.surfaceContainer, 0.4)
                                border.width: 1
                                border.color: Theme.withAlpha(Theme.primary, refreshArea.containsMouse ? 0.3 : 0.15)
                                
                                Behavior on color { ColorAnimation { duration: 200 } }
                                Behavior on border.color { ColorAnimation { duration: 200 } }
                            }

                            DankIcon {
                                name: "refresh"
                                size: 20
                                color: refreshArea.containsMouse ? Theme.primary : Theme.surfaceText
                                anchors.centerIn: parent
                                scale: refreshArea.containsMouse ? 1.15 : 1.0

                                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                            }
                        }

                        Item {
                            width: 38
                            height: 38
                            Layout.alignment: Qt.AlignVCenter

                            MouseArea {
                                id: fsToggleArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.fullscreenRequested()
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: Theme.cornerRadius
                                color: fsToggleArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.15) : Theme.withAlpha(Theme.surfaceContainer, 0.4)
                                border.width: 1
                                border.color: Theme.withAlpha(Theme.primary, fsToggleArea.containsMouse ? 0.3 : 0.15)
                                
                                Behavior on color { ColorAnimation { duration: 200 } }
                                Behavior on border.color { ColorAnimation { duration: 200 } }
                            }

                            DankIcon {
                                name: "fullscreen"
                                size: 20
                                color: fsToggleArea.containsMouse ? Theme.primary : Theme.surfaceText
                                anchors.centerIn: parent
                                scale: fsToggleArea.containsMouse ? 1.15 : 1.0

                                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                            }
                        }
                    }
                }

                // Section 1: Display Profiles in a Premium Card
                StyledRect {
                    id: profileSection
                    width: parent.width
                    height: profileCol.implicitHeight + Theme.spacingM * 2
                    radius: Theme.cornerRadius
                    color: root.cardColor
                    border.width: 1
                    border.color: root.cardBorderColor


                    Column {
                        id: profileCol
                        width: parent.width - Theme.spacingM * 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: Theme.spacingM
                        spacing: Theme.spacingM

                        RowLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            spacing: Theme.spacingXS
                            width: parent.width

                            DankIcon {
                                name: "grid_view"
                                size: 16
                                color: Theme.surfaceText
                            }

                            StyledText {
                                text: I18n.tr("Project")
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Bold
                                color: Theme.surfaceText
                                Layout.fillWidth: true
                            }
                        }

                        Column {
                            id: profileLayout
                            width: parent.width
                            spacing: 4

                            ShortcutCard {
                                width: parent.width
                                iconName: "tv"
                                label: I18n.tr("External Only")
                                shortcut: "1"
                                disabled: !root.hasExternal
                                isActive: root.activeProfile === "external_only"
                                isFirst: true
                                onClicked: { NiriDS.apply("external_only"); root.close(); }
                            }
                            ShortcutCard {
                                width: parent.width
                                iconName: "picture_in_picture"
                                label: I18n.tr("Extended")
                                shortcut: "2"
                                disabled: !root.hasExternal
                                isActive: root.activeProfile === "extend"
                                onClicked: { NiriDS.apply("extend"); root.close(); }
                            }
                            ShortcutCard {
                                width: parent.width
                                iconName: "screen_share"
                                label: I18n.tr("Mirror")
                                shortcut: "3"
                                disabled: !root.hasExternal
                                isActive: root.activeProfile === "mirror"
                                onClicked: { NiriDS.apply("mirror"); root.close(); }
                            }
                            ShortcutCard {
                                width: parent.width
                                iconName: "computer"
                                label: I18n.tr("Internal Only")
                                shortcut: "4"
                                isActive: root.activeProfile === "internal_only"
                                isLast: true
                                onClicked: { NiriDS.apply("internal_only"); root.close(); }
                            }
                        }
                    }
                }

                // Section 2: Manual Output Toggles in a Premium Card
                StyledRect {
                    id: manualSection
                    width: parent.width
                    height: manualCol.implicitHeight + Theme.spacingM * 2
                    visible: root.optionCount > 0
                    radius: Theme.cornerRadius
                    color: root.cardColor
                    border.width: 1
                    border.color: root.cardBorderColor


                    Column {
                        id: manualCol
                        width: parent.width - Theme.spacingM * 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: Theme.spacingM
                        spacing: Theme.spacingM

                        RowLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            spacing: Theme.spacingXS
                            width: parent.width

                            DankIcon {
                                name: "tune"
                                size: 16
                                color: Theme.surfaceText
                            }

                            StyledText {
                                text: I18n.tr("Manual Control")
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Bold
                                color: Theme.surfaceText
                                Layout.fillWidth: true
                            }
                        }

                        Column {
                            id: manualLayout
                            width: parent.width
                            spacing: Theme.spacingS

                            DankListView {
                                width: parent.width
                                spacing: Theme.spacingS
                                height: (60 * root.optionCount) + Theme.spacingS
                                
                                model: ScriptModel { 
                                    id: dispModel
                                    values: NiriDS.displays 
                                }

                                Connections {
                                    target: NiriDS
                                    function onDisplaysChanged() {
                                        dispModel.values = [...NiriDS.displays];
                                    }
                                }

                                delegate: Rectangle {
                                    width: parent.width
                                    implicitHeight: 60
                                    radius: Theme.cornerRadius
                                    color: isOnlyEnabled && !modelData?.disabled ?
                                        Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.04) :
                                        (selectedIndex === index ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : (itemHover.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.08)))
                                    opacity: isOnlyEnabled && !modelData?.disabled ? 0.5 : 1.0
                                    border.color: selectedIndex === index ? Theme.primary : "transparent"
                                    border.width: selectedIndex === index ? 1 : 0

                                    property bool isOnlyEnabled: {
                                        const enabledCount = (NiriDS?.displays || []).filter(d => !d.disabled).length;
                                        return enabledCount === 1 && !(modelData?.disabled);
                                    }

                                    DankIcon {
                                        id: iIcon
                                        name: (modelData && modelData.name && NiriDS.isInternalName(modelData.name)) ? "computer" : "tv"
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
                                        anchors.right: statusDot.left
                                        anchors.rightMargin: Theme.spacingM
                                        anchors.verticalCenter: parent.verticalCenter
                                        elide: Text.ElideRight
                                    }

                                    StatusDot {
                                        id: statusDot
                                        active: !(modelData && modelData.disabled)
                                        anchors.right: parent.right
                                        anchors.rightMargin: Theme.spacingL
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    MouseArea {
                                        id: itemHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: isOnlyEnabled ? Qt.ArrowCursor : Qt.PointingHandCursor
                                        onClicked: {
                                            if (!isOnlyEnabled) NiriDS.toggleDisable(modelData)
                                        }
                                    }
                                }
                            }
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

            // Full Screen Wrapper (Dashboard UI)
            Item {
                anchors.fill: parent
                visible: root.isFullScreen

                // Dark blurred glassmorphic overlay for full screen background
                Rectangle {
                    anchors.fill: parent
                    color: Theme.withAlpha(root.blackColor, 0.6)
                }

                // Centered Dashboard Card
                StyledRect {
                    id: dashboardCard
                    width: Math.min(1080, parent.width - 40)
                    height: Math.min(mainLayout.implicitHeight + Theme.spacingL * 2, parent.height - 40)
                    anchors.centerIn: parent
                    radius: Theme.cornerRadius * 1.8
                    color: root.roseBg
                    border.width: 1
                    border.color: Theme.withAlpha(root.roseAccent, 0.15)


                    // Content layout of the Dashboard Card
                    ColumnLayout {
                        id: mainLayout
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: Theme.spacingL
                        spacing: Theme.spacingL

                        // 1. Dashboard Header
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
                                        radius: 19
                                        color: fsHeaderRefreshArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.15) : "transparent"
                                        border.width: 1
                                        border.color: Theme.withAlpha(Theme.primary, fsHeaderRefreshArea.containsMouse ? 0.3 : 0.15)
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                    
                                    DankRipple { id: fsHeaderRefreshRipple; anchors.fill: parent; cornerRadius: 19; rippleColor: Theme.primary }

                                    DankIcon {
                                        name: "refresh"
                                        size: 18
                                        color: Theme.primary
                                        anchors.centerIn: parent
                                        RotationAnimation on rotation {
                                            loops: Animation.Infinite
                                            from: 0; to: 360
                                            duration: 600
                                            running: fsHeaderRefreshBtnItem.isLoading
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingL * 1.5

                            // 2. Projection Modes Section
                            ColumnLayout {
                                Layout.alignment: Qt.AlignTop
                                Layout.preferredWidth: 400
                                spacing: Theme.spacingM

                                StyledText {
                                    text: I18n.tr("Projection Modes")
                                    font.bold: true
                                    font.pixelSize: Theme.fontSizeMedium + 2
                                    color: root.roseTextDark
                                }

                                Grid {
                                    columns: 2
                                    spacing: Theme.spacingM
                                    width: parent.width
                                    Layout.fillWidth: true

                                    ProjectionCard {
                                        label: I18n.tr("External Only")
                                        desc: I18n.tr("Uses only connected monitor(s)")
                                        iconName: "tv"
                                        badgeText: "1"
                                        isActive: root.activeProfile === "external_only"
                                        isCardDisabled: !root.hasExternal
                                        onClicked: NiriDS.apply("external_only")
                                    }

                                    ProjectionCard {
                                        label: I18n.tr("Extended Desktop")
                                        desc: I18n.tr("Desktop spans across multiple monitors")
                                        iconName: "picture_in_picture"
                                        badgeText: "2"
                                        isActive: root.activeProfile === "extend"
                                        isCardDisabled: !root.hasExternal
                                        onClicked: NiriDS.apply("extend")
                                    }

                                    ProjectionCard {
                                        label: I18n.tr("Mirror Displays")
                                        desc: I18n.tr("Shows the same content on all monitors")
                                        iconName: "screen_share"
                                        badgeText: "3"
                                        isActive: root.activeProfile === "mirror"
                                        isCardDisabled: !root.hasExternal
                                        onClicked: NiriDS.apply("mirror")
                                    }

                                    ProjectionCard {
                                        label: I18n.tr("Internal Only")
                                        desc: I18n.tr("Uses only the built-in laptop screen")
                                        iconName: "laptop"
                                        badgeText: "4"
                                        isActive: root.activeProfile === "internal_only"
                                        onClicked: NiriDS.apply("internal_only")
                                    }
                                }
                            }

                            // 3. Display Management Section
                            ColumnLayout {
                                Layout.alignment: Qt.AlignTop
                                Layout.fillWidth: true
                                spacing: Theme.spacingM

                            StyledText {
                                text: I18n.tr("Display Management")
                                font.bold: true
                                font.pixelSize: Theme.fontSizeMedium + 2
                                color: root.roseTextDark
                            }

                                Column {
                                    width: parent.width; spacing: 4

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
                                                    ? Theme.withAlpha(root.roseAccent, 0.18)
                                                    : manualItem.hovered
                                                        ? Theme.withAlpha(root.roseAccent, 0.1)
                                                        : Theme.withAlpha(root.roseTextDark, 0.04))
                                                
                                                property color paintBorder: manualItem.isOnlyEnabled ? Theme.withAlpha(root.roseTextDark, 0.05) : (manualItem.isOutputActive
                                                    ? Theme.withAlpha(root.roseAccent, 0.6)
                                                    : manualItem.hovered
                                                        ? Theme.withAlpha(root.roseAccent, 0.4)
                                                        : Theme.withAlpha(root.roseTextDark, 0.15))

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

                                            DankRipple { id: pRip; anchors.fill: parent; cornerRadius: cardBg.tlrAnim; rippleColor: root.roseAccent }

                                            DankIcon {
                                                id: iIcon
                                                name: (modelData && modelData.name && NiriDS.isInternalName(modelData.name)) ? "computer" : "tv"
                                                size: Theme.iconSize - 4
                                                color: root.roseTextDark
                                                anchors.left: parent.left
                                                anchors.leftMargin: Theme.spacingM
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            StyledText {
                                                text: modelData ? (modelData.friendlyName || "Unknown") : "Unknown"
                                                font.pixelSize: Theme.fontSizeSmall
                                                color: root.roseTextDark
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
        }
    }
}
