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
        radius: Metrics.cornerRadius - 2
        color: Theme.surface_container_lowest
        clip: true
        Layout.alignment: Qt.AlignVCenter

        Image {
            id: sideImg
            anchors.fill: parent
            source: root.visible ? MediaState.artSource : ""
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
            sourceSize: Qt.size(Math.max(1, Math.round(width * 2)), Math.max(1, Math.round(height * 2)))
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
            onClicked: { Logger.debug("MprisCard", "Side art click -> toggleMode"); root.toggleMode(); }
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

        MarqueeText {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(16 * root.scaleFactor)
            text: MediaState.cleanArtist || ""
            color: Theme.on_surface_variant
            pixelSize: Typography.sizeSmall(root.scaleFactor)
            centerWhenFit: false
        }

        Text {
            text: MediaState.timeSummary
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

        IconButton {
            text: "󰒮"
            pixelSize: Math.round(17 * root.scaleFactor)
            onClicked: MediaState.previous()
        }

        IconButton {
            text: MediaState.isPlaying ? "󰏤" : "󰐊"
            color: MediaState.isPlaying ? Theme.primary : Theme.tertiary
            pixelSize: Math.round(22 * root.scaleFactor)
            onClicked: MediaState.togglePlay()
        }

        IconButton {
            text: "󰒭"
            pixelSize: Math.round(17 * root.scaleFactor)
            onClicked: MediaState.next()
        }
    }
}
