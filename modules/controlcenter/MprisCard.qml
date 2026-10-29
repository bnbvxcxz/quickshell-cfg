// Media player card container.
// Switches between compact strip, banner top view, and side thumbnail view modes.

import QtQuick
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

    Layout.fillWidth: true
    radius: Theme.cornerRadius
    color: Theme.surface_container_high
    clip: true

    Image {
        id: probe
        source: MediaState.artSource
        visible: false
        asynchronous: true
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
        return useTopMode ? Math.round(198 * scaleFactor) : Math.round(92 * scaleFactor);
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
