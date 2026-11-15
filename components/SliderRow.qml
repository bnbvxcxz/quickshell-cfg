// Reusable interactive slider row for volume and backlight controls.
// Supports click/drag positioning, wheel stepping, and icon click actions.

import QtQuick
import QtQuick.Layouts
import "../config"

Rectangle {
    id: root

    property string icon: ""
    property real value: 0.0
    property string label: ""
    property bool muted: false
    property real minValue: 0.0
    property real scaleFactor: 1.0
    property int sliderHeight: Math.round(34 * scaleFactor)

    signal valueDragged(real pct)
    signal stepped(int delta)
    signal iconClicked()

    Layout.fillWidth: true
    Layout.preferredHeight: sliderHeight
    radius: Metrics.cornerRadius
    color: Qt.alpha(Theme.surface_container_high, Metrics.cardHighOpacity)

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Math.round(10 * root.scaleFactor)
        anchors.rightMargin: Math.round(10 * root.scaleFactor)
        spacing: Math.round(8 * root.scaleFactor)

        Text {
            text: root.icon
            color: root.muted ? Theme.error : Theme.primary
            font.family: Typography.family
            font.pixelSize: Typography.size(root.scaleFactor)
            font.bold: Typography.globalBold
            font.weight: Typography.globalWeight
            font.italic: Typography.globalItalic

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.iconClicked()
            }
        }

        Item {
            id: trackBox
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(18 * root.scaleFactor)

            Rectangle {
                id: track
                anchors.centerIn: parent
                width: parent.width
                height: Math.max(4, Math.round(6 * root.scaleFactor))
                radius: height / 2
                color: Theme.surface_container_lowest

                Rectangle {
                    width: track.width * Math.max(0.0, Math.min(1.0, root.value))
                    height: parent.height
                    radius: height / 2
                    color: root.muted ? Theme.outline : Theme.primary
                }
            }

            Rectangle {
                readonly property real knobDim: Math.round(12 * root.scaleFactor)
                x: Math.max(0, Math.min(trackBox.width - width, (trackBox.width * root.value) - (width / 2)))
                anchors.verticalCenter: parent.verticalCenter
                width: knobDim
                height: knobDim
                radius: knobDim / 2
                color: root.muted ? Theme.outline : Theme.primary
                border.color: Theme.background
                border.width: 1.5
            }
        }

        Text {
            text: root.label
            color: root.muted ? Theme.error : Theme.on_surface_variant
            font.family: Typography.family
            font.pixelSize: Typography.sizeSmall(root.scaleFactor)
            font.bold: Typography.globalBold
            font.weight: Typography.globalWeight
            font.italic: Typography.globalItalic
            Layout.preferredWidth: Math.round(38 * root.scaleFactor)
            horizontalAlignment: Text.AlignRight
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        property int scrollAcc: 0

        function emitFromX(mx) {
            let localX = mapToItem(trackBox, mx, 0).x;
            let pct = Math.max(root.minValue, Math.min(1.0, localX / Math.max(1, trackBox.width)));
            root.valueDragged(pct);
        }

        onClicked: mouse => emitFromX(mouse.x)
        onPositionChanged: mouse => { if (pressed) emitFromX(mouse.x); }

        onWheel: wheel => {
            scrollAcc += wheel.angleDelta.y;
            let steps = Math.trunc(scrollAcc / 120);
            if (steps !== 0) {
                root.stepped(steps);
                scrollAcc -= steps * 120;
            }
            wheel.accepted = true;
        }
    }
}
