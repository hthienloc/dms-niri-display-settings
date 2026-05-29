import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Widgets

Item {
    id: card
    property string iconName
    property string label
    property string shortcut
    property bool disabled: false
    property bool isActive: false
    property bool isFirst: false
    property bool isLast: false
    property bool hovered: mouseArea.containsMouse && !disabled

    signal clicked()

    height: 44

    Canvas {
        id: cardBg
        anchors.fill: parent
        property real innerRadius: 6
        property real outerRadius: 12
        
        property real tlr: card.isActive ? 21.5 : (card.isFirst ? outerRadius : innerRadius)
        property real trr: card.isActive ? 21.5 : (card.isFirst ? outerRadius : innerRadius)
        property real blr: card.isActive ? 21.5 : (card.isLast ? outerRadius : innerRadius)
        property real brr: card.isActive ? 21.5 : (card.isLast ? outerRadius : innerRadius)

        property real tlrAnim: tlr; Behavior on tlrAnim { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
        property real trrAnim: trr; Behavior on trrAnim { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
        property real blrAnim: blr; Behavior on blrAnim { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
        property real brrAnim: brr; Behavior on brrAnim { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }

        property color paintColor: card.disabled ? "transparent" : (card.isActive
            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.18)
            : card.hovered
                ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1)
                : Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.04))
        
        property color paintBorder: card.disabled ? Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.05) : (card.isActive
            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.6)
            : card.hovered
                ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4)
                : Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.15))

        onTlrAnimChanged: requestPaint()
        onTrrAnimChanged: requestPaint()
        onBlrAnimChanged: requestPaint()
        onBrrAnimChanged: requestPaint()
        onPaintColorChanged: requestPaint()
        onPaintBorderChanged: requestPaint()

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
            opacity: card.hovered ? 0.05 : 0; Behavior on opacity { NumberAnimation { duration: 150 } } 
        }
    }

    DankRipple { id: pRip; anchors.fill: parent; cornerRadius: cardBg.tlrAnim; rippleColor: Theme.primary }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: Theme.spacingS

        DankIcon {
            name: card.iconName
            size: 18
            color: card.disabled ? Theme.withAlpha(Theme.surfaceText, 0.4) : (card.isActive ? Theme.primary : Theme.surfaceVariantText)
            Layout.alignment: Qt.AlignVCenter
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        StyledText {
            text: card.label
            font.pixelSize: Theme.fontSizeSmall
            font.weight: card.isActive ? Font.Bold : Font.Normal
            color: card.disabled ? Theme.withAlpha(Theme.surfaceText, 0.4) : (card.isActive ? Theme.primary : Theme.surfaceText)
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        DankIcon { 
            name: "check_circle"; size: 16; color: Theme.primary
            scale: card.isActive ? 1.0 : 0.0
            opacity: card.isActive ? 1.0 : 0.0
            visible: card.isActive
            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        Rectangle {
            width: shortcutText.implicitWidth + Theme.spacingM
            height: shortcutText.implicitHeight + Theme.spacingS - 2
            radius: Theme.cornerRadius / 2
            color: card.hovered ? Theme.withAlpha(Theme.primary, 0.25) : Theme.withAlpha(Theme.surfaceVariant, 0.4)
            border.width: 1
            border.color: card.hovered ? Theme.withAlpha(Theme.primary, 0.4) : Theme.withAlpha(Theme.surfaceVariant, 0.2)
            Layout.alignment: Qt.AlignVCenter
            visible: card.shortcut !== "" && !card.isActive

            Behavior on color { ColorAnimation { duration: 150 } }

            StyledText {
                id: shortcutText
                text: card.shortcut
                font.pixelSize: Theme.fontSizeSmall - 1
                font.weight: Font.DemiBold
                color: card.hovered ? Theme.primary : Theme.surfaceText
                opacity: 0.8
                anchors.centerIn: parent
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: !card.disabled
        cursorShape: card.disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: {
            if (!card.disabled) {
                card.clicked();
            }
        }
        onPressed: (m) => pRip.trigger(m.x, m.y)
    }
}
