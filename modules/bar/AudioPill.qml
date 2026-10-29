// Status bar volume module.
// Displays audio mute state, percentage, and handles volume scrolling and control launcher.

import QtQuick
import "../../config"
import "../../services"
import "../../components"

Pill {
    id: root

    onClicked: HardwareState.runCmd("pavucontrol")
    onMiddleClicked: HardwareState.toggleMute(false)
    onWheelMoved: steps => HardwareState.adjustVolume(steps, false)

    Pill.Icon {
        text: HardwareState.isMuted ? "󰖁" : "󰕾"
        color: HardwareState.isMuted ? Theme.error : Theme.primary
        scaleFactor: root.scaleFactor
    }

    Pill.Label {
        text: HardwareState.isMuted ? "Muted" : `${Math.round(HardwareState.volume * 100)}%`
        color: HardwareState.isMuted ? Theme.error : Theme.primary
        scaleFactor: root.scaleFactor
    }
}
