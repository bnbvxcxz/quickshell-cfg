// Status bar clock module.
// Displays current date and localized 12-hour time.

import QtQuick
import "../../config"
import "../../components"

Pill {
    id: root

    Pill.Icon {
        text: "󰥔"
        scaleFactor: root.scaleFactor
    }

    Pill.Label {
        text: clock.timeString
        scaleFactor: root.scaleFactor
    }

    Timer {
        id: clock
        interval: 1000
        running: true
        repeat: true
        property string timeString: Qt.formatDateTime(new Date(), "ddd, MMM d - h:mm AP")
        onTriggered: timeString = Qt.formatDateTime(new Date(), "ddd, MMM d - h:mm AP")
    }
}
