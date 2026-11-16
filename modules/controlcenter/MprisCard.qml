// Media player card container.
// Switches between compact strip, banner top view, and side thumbnail view, with multi-socket selector.

import QtQuick
import "../../components"
import QtQuick.Layouts
import "../../config"
import "../../services"
import "."

Rectangle {
    id: deckRoot

    signal requestExpand()

    property bool isScrolledCompact: false
    property bool manualTopMode: false
    property real scaleFactor: 1.0

    readonly property bool hasMultiPlayers: MediaState.validPlayers.length > 1
    readonly property int switcherH: (hasMultiPlayers && !isScrolledCompact) ? Math.round(24 * scaleFactor) : 0

    Layout.fillWidth: true
    radius: Metrics.cornerRadius
    color: Theme.surface_container_high
    clip: true

    Image {
        id: probe
        source: MediaState.artSource
        visible: false
        asynchronous: true
        sourceSize: Qt.size(256, 256)
        cache: true
    }

    readonly property real artRatio: {
        if (probe.implicitWidth > 0 && probe.implicitHeight > 0) {
            return probe.implicitWidth / probe.implicitHeight;
        }
        return 1.0;
    }

    readonly property bool isWide: artRatio > 1.25
    readonly property bool useTopMode: manualTopMode ? !isWide : isWide

    readonly property int targetHeight: {
        if (!MediaState.hasMedia) return 0;
        if (isScrolledCompact) return Math.round(34 * scaleFactor);
        let baseH = useTopMode ? Math.round(198 * scaleFactor) : Math.round(92 * scaleFactor);
        return baseH + switcherH;
    }

    implicitHeight: targetHeight
    Layout.preferredHeight: targetHeight
    Layout.maximumHeight: targetHeight

    Behavior on Layout.preferredHeight {
        NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
    }
    Behavior on Layout.maximumHeight {
        NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
    }
    Behavior on implicitHeight {
        NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
    }

    MprisCompactStrip {
        visible: MediaState.hasMedia && deckRoot.isScrolledCompact
        scaleFactor: deckRoot.scaleFactor
        onRequestExpand: deckRoot.requestExpand()
    }

    // Exposed socket selector bar shown whenever 2+ MPRIS players are active.
    RowLayout {
        id: socketBar
        visible: MediaState.hasMedia && deckRoot.hasMultiPlayers && !deckRoot.isScrolledCompact
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Math.round(6 * deckRoot.scaleFactor)
        anchors.leftMargin: Math.round(8 * deckRoot.scaleFactor)
        anchors.rightMargin: Math.round(8 * deckRoot.scaleFactor)
        height: Math.round(18 * deckRoot.scaleFactor)
        spacing: Math.round(4 * deckRoot.scaleFactor)
        z: 2

        Repeater {
            model: MediaState.validPlayers

            Rectangle {
                required property var modelData
                readonly property string pName: (modelData && modelData.identity) ? modelData.identity : "Player"
                readonly property bool isSelected: MediaState.activePlayer && (MediaState.activePlayer.identity === pName)

                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Math.round(6 * deckRoot.scaleFactor)
                color: isSelected ? Theme.primary : Qt.alpha(Theme.surface_container_highest, 0.65)

                Text {
                    anchors.centerIn: parent
                    width: parent.width - Math.round(8 * deckRoot.scaleFactor)
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: pName
                    color: isSelected ? Theme.on_primary : Theme.on_surface_variant
                    font.family: Typography.family
                    font.pixelSize: Math.max(8, Typography.sizeSmall(deckRoot.scaleFactor) - 1)
                    font.bold: Typography.globalBold
                    font.italic: Typography.globalItalic
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { Logger.debug("MprisCard", `Selected player: ${pName}`); MediaState.selectPlayer(pName); }
                }
            }
        }
    }

    Item {
        anchors.top: socketBar.visible ? socketBar.bottom : parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        MprisSideView {
            visible: MediaState.hasMedia && !deckRoot.isScrolledCompact && !deckRoot.useTopMode
            scaleFactor: deckRoot.scaleFactor
            artRatio: deckRoot.artRatio
            onToggleMode: deckRoot.manualTopMode = !deckRoot.manualTopMode
        }

        MprisTopView {
            visible: MediaState.hasMedia && !deckRoot.isScrolledCompact && deckRoot.useTopMode
            scaleFactor: deckRoot.scaleFactor
            artRatio: deckRoot.artRatio
            onToggleMode: deckRoot.manualTopMode = !deckRoot.manualTopMode
        }
    }
}
