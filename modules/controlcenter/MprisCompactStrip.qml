// Compact media strip for scrolled control center states.
// Displays play/pause state and current track timer with expand trigger.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"

RowLayout {
    id: root

    signal requestExpand()
    property real scaleFactor: 1.0

    readonly property string timeString: MediaState.trackLen > 0
    ? (MediaState.formatTime(MediaState.trackPos) + " / " + MediaState.formatTime(MediaState.trackLen))
    : (MediaState.isPlaying ? MediaState.formatTime(MediaState.trackPos) : "--:--")

    anchors.fill: parent
    anchors.leftMargin: Math.round(12 * scaleFactor)
    anchors.rightMargin: Math.round(12 * scaleFactor)
    spacing: Math.round(8 * scaleFactor)

    MouseArea {
        Layout.fillWidth: true
        Layout.fillHeight: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.requestExpand()

        RowLayout {
            anchors.fill: parent
            spacing: Math.round(8 * root.scaleFactor)

            Text {
                text: MediaState.isPlaying ? "󰏤" : "󰐊"
                color: Theme.primary
                font.family: Typography.family
                font.pixelSize: Typography.sizeSmall(root.scaleFactor)
                font.bold: Typography.globalBold
                font.weight: Typography.globalWeight
                font.italic: Typography.globalItalic
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: root.timeString
                color: Theme.on_surface
                font.family: Typography.family
                font.pixelSize: Typography.sizeSmall(root.scaleFactor)
                font.bold: Typography.globalBold
                font.weight: Typography.globalWeight
                font.italic: Typography.globalItalic
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    Text {
        text: "󰅀"
        color: Theme.on_surface_variant
        font.family: Typography.family
        font.pixelSize: Typography.sizeSmall(root.scaleFactor)
        font.bold: Typography.globalBold
        font.weight: Typography.globalWeight
        font.italic: Typography.globalItalic
        Layout.alignment: Qt.AlignVCenter

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.requestExpand()
        }
    }
}
