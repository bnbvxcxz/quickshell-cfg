// Status bar clock module.
// Displays current date and localized 12-hour time via native SystemClock.

import QtQuick
import Quickshell
import "../../config"
import "../../components"

Pill {
    id: root

    clickable: false
    wheelEnabled: false

    SystemClock {
        id: sysClock
        precision: SystemClock.Minutes
    }

    Pill.Icon {
        text: "󰥔"
        scaleFactor: root.scaleFactor
    }

    Pill.Label {
        text: Qt.formatDateTime(sysClock.date, "ddd, MMM d - h:mm AP")
        scaleFactor: root.scaleFactor
    }
}
