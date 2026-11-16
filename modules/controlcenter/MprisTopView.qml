// Vertical media player banner layout.
// Displays centered cover art banner, track metadata, and bottom playback controls.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../components"

ColumnLayout {
    id: root

    property real scaleFactor: 1.0
    property real artRatio: 1.77
    signal toggleMode()

    readonly property real bannerH: Math.round(90 * scaleFactor)

    anchors.fill: parent
    anchors.margins: Math.round(8 * scaleFactor)
    spacing: Math.round(4 * scaleFactor)

    Item {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredHeight: root.bannerH
        Layout.preferredWidth: Math.max(Math.round(90 * root.scaleFactor), Math.min(Math.round(280 * root.scaleFactor), root.bannerH * root.artRatio))

        Rectangle {
            anchors.fill: parent
            radius: Metrics.cornerRadius - 2
            color: Theme.surface_container_lowest
            clip: true

            Image {
                id: topImg
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
                font.pixelSize: Math.round(28 * root.scaleFactor)
                font.bold: Typography.globalBold
                font.italic: Typography.globalItalic
                visible: topImg.status !== Image.Ready || MediaState.artSource === ""
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { Logger.debug("MprisCard", "Top art click -> toggleMode"); root.toggleMode(); }
            }
        }
    }

    MarqueeText {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.round(18 * root.scaleFactor)
        text: MediaState.cleanTitle !== "" ? MediaState.cleanTitle : "No Media Active"
        color: Theme.on_surface
        pixelSize: Typography.size(root.scaleFactor)
        centerWhenFit: true
    }

    MarqueeText {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.round(16 * root.scaleFactor)
        readonly property string timeStr: MediaState.timeSummary
        text: MediaState.cleanArtist ? `${MediaState.cleanArtist}  •  ${timeStr}` : timeStr
        color: Theme.on_surface_variant
        pixelSize: Typography.sizeSmall(root.scaleFactor)
        centerWhenFit: true
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Math.round(20 * root.scaleFactor)
        Layout.bottomMargin: Math.round(2 * root.scaleFactor)

        IconButton {
            text: "󰒟"
            opacity: MediaState.canShuffle ? 1.0 : 0.4
            color: MediaState.isShuffled ? Theme.primary : Theme.outline
            pixelSize: Math.round(15 * root.scaleFactor)
            onClicked: MediaState.toggleShuffle()
        }

        IconButton {
            text: "󰒮"
            pixelSize: Math.round(18 * root.scaleFactor)
            onClicked: MediaState.previous()
        }

        IconButton {
            text: MediaState.isPlaying ? "󰏤" : "󰐊"
            color: MediaState.isPlaying ? Theme.primary : Theme.tertiary
            pixelSize: Math.round(20 * root.scaleFactor)
            onClicked: MediaState.togglePlay()
        }

        IconButton {
            text: "󰒭"
            pixelSize: Math.round(18 * root.scaleFactor)
            onClicked: MediaState.next()
        }

        IconButton {
            text: MediaState.loopMode === 1 ? "󰑘" : "󰑖"
            opacity: MediaState.canLoop ? 1.0 : 0.4
            color: MediaState.loopMode === 1 ? Theme.tertiary : (MediaState.loopMode === 2 ? Theme.primary : Theme.outline)
            pixelSize: Math.round(15 * root.scaleFactor)
            onClicked: MediaState.cycleLoop()
        }
    }
}
