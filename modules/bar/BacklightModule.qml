// Status bar display brightness module.
// Displays current display backlight level and adjusts on mouse scroll with OSD feedback.

import QtQuick
import "../../config"
import "../../services"
import "../../components"

BarModule {
    id: root

    clickable: false
    wheelEnabled: true

    onWheelMoved: steps => { Logger.debug("Backlight", `Wheel step=${steps}`); HardwareState.adjustBrightness(steps, true); }

    BarModule.Icon {
        text: HardwareState.brightnessIcon
        scaleFactor: root.scaleFactor
    }

    BarModule.Label {
        text: `${Math.round(HardwareState.brightness * 100)}%`
        scaleFactor: root.scaleFactor
    }
}
