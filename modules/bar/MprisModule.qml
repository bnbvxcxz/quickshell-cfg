// Status bar compact media timer module.
// Displays play/pause status and current playback time against total duration.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../components"

BarModule {
    id: root

    readonly property string timeStr: MediaState.trackLen > 0
        ? (MediaState.formatTime(MediaState.trackPos) + " / " + MediaState.formatTime(MediaState.trackLen))
        : (MediaState.isPlaying ? MediaState.formatTime(MediaState.trackPos) : "--:--")

    visible: MediaState.hasMedia
    Layout.preferredWidth: visible ? -1 : 0

    onClicked: { Logger.debug("Mpris", "Bar click -> togglePlay"); MediaState.togglePlay(); }
    onRightClicked: { Logger.debug("Mpris", "Bar right click -> next"); MediaState.next(); }
    onMiddleClicked: { Logger.debug("Mpris", "Bar middle click -> previous"); MediaState.previous(); }
    onWheelMoved: steps => {
        Logger.debug("Mpris", `Bar wheel step=${steps}`);
        if (steps > 0) MediaState.next();
        else MediaState.previous();
    }

    BarModule.Icon {
        text: MediaState.isPlaying ? "󰏤" : "󰐊"
        color: Theme.secondary
        scaleFactor: root.scaleFactor
    }

    BarModule.Label {
        text: root.timeStr
        color: Theme.secondary
        scaleFactor: root.scaleFactor
    }
}
