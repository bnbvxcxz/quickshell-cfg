// Status bar volume module.
// Tracks default sink state, percentage, scroll adjustment, and audio mixer launcher.

import QtQuick
import "../../config"
import "../../services"
import "../../components"

BarModule {
    id: root

    onClicked: { Logger.debug("Audio", "Click -> open mixer"); HardwareState.runCmd(Commands.mixer); }
    onRightClicked: { Logger.debug("Audio", "Right click -> toggle mute (OSD)"); HardwareState.toggleMute(true); }
    onMiddleClicked: { Logger.debug("Audio", "Middle click -> toggle mute"); HardwareState.toggleMute(false); }
    onWheelMoved: steps => { Logger.debug("Audio", `Wheel step=${steps}`); HardwareState.adjustVolume(steps, true); }

    readonly property color fgColor: HardwareState.isMuted ? Theme.error : Theme.primary

    BarModule.Icon {
        text: HardwareState.volumeIcon
        color: root.fgColor
        scaleFactor: root.scaleFactor
    }

    BarModule.Label {
        text: HardwareState.isMuted ? "Muted" : `${Math.round(HardwareState.volume * 100)}%`
        color: root.fgColor
        scaleFactor: root.scaleFactor
    }
}
