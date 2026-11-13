// Status bar volume module.
// Tracks default sink state, percentage, scroll adjustment, and audio mixer launcher.

import QtQuick
import "../../config"
import "../../services"
import "../../components"

Pill {
    id: root

    onClicked: HardwareState.runCmd("pavucontrol")
    onRightClicked: HardwareState.toggleMute(true)
    onMiddleClicked: HardwareState.toggleMute(false)
    onWheelMoved: steps => HardwareState.adjustVolume(steps, true)

    readonly property color fgColor: HardwareState.isMuted ? Theme.error : Theme.primary

    Pill.Icon {
        text: HardwareState.volumeIcon
        color: root.fgColor
        scaleFactor: root.scaleFactor
    }

    Pill.Label {
        text: HardwareState.isMuted ? "Muted" : `${Math.round(HardwareState.volume * 100)}%`
        color: root.fgColor
        scaleFactor: root.scaleFactor
    }
}
