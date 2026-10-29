// Horizontal media player view.
// Renders square cover art, marquee metadata, and aligned control buttons.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../components"

RowLayout {
    id: root

    property real scaleFactor: 1.0
    property real artRatio: 1.0
    signal toggleMode()

    readonly property real boxH: Math.round(68 * scaleFactor)

    anchors.fill: parent
    anchors.margins: Math.round(10 * scaleFactor)
    spacing: Math.round(12 * scaleFactor)

    Rectangle {
        Layout.preferredHeight: root.boxH
        Layout.preferredWidth: Math.max(Math.round(50 * root.scaleFactor), Math.min(Math.round(100 * root.scaleFactor), root.boxH * root.artRatio))
        radius: Theme.cornerRadius - 2
        color: Theme.surface_container_lowest
        clip: true
        Layout.alignment: Qt.AlignVCenter

        Image {
            id: sideImg
            anchors.fill: parent
            source: MediaState.artSource
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
            cache: true
            visible: status === Image.Ready && source !== ""
        }

        Text {
            anchors.centerIn: parent
            text: "󰎆"
            color: Theme.secondary
            font.family: Typography.family
            font.pixelSize: Math.round(26 * root.scaleFactor)
            font.bold: Typography.globalBold
            font.italic: Typography.globalItalic
            visible: sideImg.status !== Image.Ready || MediaState.artSource === ""
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleMode()
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        spacing: 2

        MarqueeText {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(20 * root.scaleFactor)
            text: MediaState.cleanTitle !== "" ? MediaState.cleanTitle : "No Media Active"
            color: Theme.on_surface
            pixelSize: Typography.size(root.scaleFactor)
            centerWhenFit: false
        }

        Text {
            Layout.fillWidth: true
            text: MediaState.cleanArtist || ""
            color: Theme.on_surface_variant
            font.family: Typography.family
            font.pixelSize: Typography.sizeSmall(root.scaleFactor)
            font.bold: Typography.globalBold
            font.italic: Typography.globalItalic
            elide: Text.ElideRight
        }

        Text {
            text: MediaState.trackLen > 0 ? (MediaState.formatTime(MediaState.trackPos) + " / " + MediaState.formatTime(MediaState.trackLen)) : "--:--"
            color: Theme.outline
            font.family: Typography.family
            font.pixelSize: Math.max(8, Typography.sizeSmall(root.scaleFactor) - 1)
            font.bold: Typography.globalBold
            font.italic: Typography.globalItalic
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignVCenter
        spacing: Math.round(10 * root.scaleFactor)

        Text {
            text: "󰒮"
            color: Theme.primary
            font.family: Typography.family
            font.pixelSize: Math.round(17 * root.scaleFactor)
            font.bold: Typography.globalBold
            font.italic: Typography.globalItalic
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: MediaState.previous()
            }
        }

        Text {
            text: MediaState.isPlaying ? "󰏤" : "󰐊"
            color: Theme.primary
            font.family: Typography.family
            font.pixelSize: Math.round(22 * root.scaleFactor)
            font.bold: Typography.globalBold
            font.italic: Typography.globalItalic
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: MediaState.togglePlay()
            }
        }

        Text {
            text: "󰒭"
            color: Theme.primary
            font.family: Typography.family
            font.pixelSize: Math.round(17 * root.scaleFactor)
            font.bold: Typography.globalBold
            font.italic: Typography.globalItalic
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: MediaState.next()
            }
        }
    }
}
