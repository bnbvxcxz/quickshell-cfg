// Status bar compact media timer pill.
// Displays play/pause status and current playback time against total duration.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../components"

Pill {
    id: root

    readonly property string timeString: MediaState.trackLen > 0
    ? (MediaState.formatTime(MediaState.trackPos) + " / " + MediaState.formatTime(MediaState.trackLen))
    : (MediaState.isPlaying ? MediaState.formatTime(MediaState.trackPos) : "--:--")

    visible: MediaState.hasMedia
    Layout.preferredWidth: visible ? -1 : 0
    onClicked: MediaState.togglePlay()

    Pill.Icon {
        text: MediaState.isPlaying ? "󰏤" : "󰐊"
        color: Theme.secondary
        scaleFactor: root.scaleFactor
    }

    Pill.Label {
        text: root.timeString
        color: Theme.secondary
        scaleFactor: root.scaleFactor
    }
}
