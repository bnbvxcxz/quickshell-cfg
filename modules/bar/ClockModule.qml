// Status bar clock module.
// Displays current date and localized 12-hour time via native SystemClock.

import QtQuick
import Quickshell
import "../../config"
import "../../components"

BarModule {
    id: root

    clickable: false
    wheelEnabled: false

    SystemClock {
        id: sysClock
        precision: SystemClock.Minutes
    }

    BarModule.Icon {
        text: "󰥔"
        scaleFactor: root.scaleFactor
    }

    BarModule.Label {
        text: Qt.formatDateTime(sysClock.date, "ddd, MMM d - h:mm AP")
        scaleFactor: root.scaleFactor
    }
}
