// Status bar network status module.
// Parses active connection SSID and opens nmtui terminal utility on click.

import QtQuick
import "../../config"
import "../../services"
import "../../components"

Pill {
    id: root

    onClicked: HardwareState.runCmd("kitty --class quickshell_nmtui -e nmtui")

    readonly property var netParts: SystemState.netText.trim().split(/\s+/)
    readonly property string netIcon: netParts.length > 0 ? netParts[0] : "󰤨"
    readonly property string netName: netParts.length > 1 ? netParts.slice(1).join(" ") : ""

    Pill.Icon {
        text: root.netIcon
        scaleFactor: root.scaleFactor
    }

    Pill.Label {
        text: root.netName
        visible: text.length > 0
        scaleFactor: root.scaleFactor
    }
}
