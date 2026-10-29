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
            radius: Theme.cornerRadius - 2
            color: Theme.surface_container_lowest
            clip: true

            Image {
                id: topImg
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
                font.pixelSize: Math.round(28 * root.scaleFactor)
                font.bold: Typography.globalBold
                font.italic: Typography.globalItalic
                visible: topImg.status !== Image.Ready || MediaState.artSource === ""
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleMode()
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

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Math.round(6 * root.scaleFactor)

        Text {
            text: MediaState.cleanArtist || ""
            color: Theme.on_surface_variant
            font.family: Typography.family
            font.pixelSize: Typography.sizeSmall(root.scaleFactor)
            font.bold: Typography.globalBold
            font.italic: Typography.globalItalic
            elide: Text.ElideRight
        }

        Text {
            text: "•"
            color: Theme.outline
            font.family: Typography.family
            font.pixelSize: Typography.sizeSmall(root.scaleFactor)
            font.bold: Typography.globalBold
            font.italic: Typography.globalItalic
        }

        Text {
            text: MediaState.trackLen > 0 ? (MediaState.formatTime(MediaState.trackPos) + " / " + MediaState.formatTime(MediaState.trackLen)) : "--:--"
            color: Theme.outline
            font.family: Typography.family
            font.pixelSize: Typography.sizeSmall(root.scaleFactor)
            font.bold: Typography.globalBold
            font.italic: Typography.globalItalic
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Math.round(24 * root.scaleFactor)
        Layout.bottomMargin: Math.round(2 * root.scaleFactor)

        Text {
            text: "󰒮"
            color: Theme.primary
            font.family: Typography.family
            font.pixelSize: Math.round(18 * root.scaleFactor)
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
            font.pixelSize: Math.round(20 * root.scaleFactor)
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
            font.pixelSize: Math.round(18 * root.scaleFactor)
            font.bold: Typography.globalBold
            font.italic: Typography.globalItalic
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: MediaState.next()
            }
        }

        Text {
            property string loopVal: (MediaState.activePlayer && MediaState.activePlayer.loopStatus) ? String(MediaState.activePlayer.loopStatus) : "None"
            text: (loopVal.indexOf("Track") !== -1) ? "󰑘" : "󰑖"
            color: (loopVal !== "None" && loopVal !== "0") ? Theme.primary : Theme.outline
            font.family: Typography.family
            font.pixelSize: Math.round(15 * root.scaleFactor)
            font.bold: Typography.globalBold
            font.italic: Typography.globalItalic
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: MediaState.cycleLoop()
            }
        }
    }
}
