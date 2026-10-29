// Status bar display brightness pill.
// Displays current display backlight level and adjusts on mouse scroll.

import QtQuick
import "../../config"
import "../../services"
import "../../components"

Pill {
    id: root

    onWheelMoved: steps => HardwareState.adjustBrightness(steps, false)

    Pill.Icon {
        text: "󰃟"
        scaleFactor: root.scaleFactor
    }

    Pill.Label {
        text: `${Math.round(HardwareState.brightness * 100)}%`
        scaleFactor: root.scaleFactor
    }
}
