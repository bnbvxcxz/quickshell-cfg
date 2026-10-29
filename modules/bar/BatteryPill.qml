// Status bar battery indicator.
// Displays battery percentage and charging state icons.

import QtQuick
import "../../config"
import "../../services"
import "../../components"

Pill {
    id: root

    Pill.Icon {
        text: SystemState.batIcon
        scaleFactor: root.scaleFactor
    }

    Pill.Label {
        text: SystemState.batCapacity
        scaleFactor: root.scaleFactor
    }
}
