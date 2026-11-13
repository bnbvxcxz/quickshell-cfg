// Status bar display brightness pill.
// Displays current display backlight level and adjusts on mouse scroll with OSD feedback.

import QtQuick
import "../../config"
import "../../services"
import "../../components"

Pill {
    id: root

    clickable: false
    wheelEnabled: true

    onWheelMoved: steps => HardwareState.adjustBrightness(steps, true)

    Pill.Icon {
        text: HardwareState.brightnessIcon
        scaleFactor: root.scaleFactor
    }

    Pill.Label {
        text: `${Math.round(HardwareState.brightness * 100)}%`
        scaleFactor: root.scaleFactor
    }
}
