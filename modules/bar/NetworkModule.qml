// Status bar network indicator (Ethernet or Wi-Fi).
// Displays active connection glyph and SSID/interface, opening nmtui on click.

import QtQuick
import "../../config"
import "../../services"
import "../../components"

BarModule {
    id: root

    onClicked: { Logger.debug("Network", `Click -> open ${Commands.netManager}`); HardwareState.runCmd([Commands.terminal, "--class", "quickshell_nmtui", "-e", Commands.netManager]); }

    BarModule.Icon {
        text: SystemState.netIcon
        scaleFactor: root.scaleFactor
    }

    BarModule.Label {
        text: SystemState.netName
        scaleFactor: root.scaleFactor
    }
}
