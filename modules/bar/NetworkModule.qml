// Status bar network status module.
// Displays Wi-Fi signal or Ethernet icon and opens nmtui on click.

import QtQuick
import "../../config"
import "../../services"
import "../../components"

BarModule {
    id: root

    onClicked: { Logger.debug("Network", "Click -> open nmtui"); HardwareState.runCmd([Commands.terminal, "--class", "quickshell_nmtui", "-e", "nmtui"]); }

    readonly property bool isDisconnected: SystemState.netName === "disconnected"
    readonly property color netColor: isDisconnected ? Theme.error : Theme.primary

    BarModule.Icon {
        text: SystemState.netIcon
        color: root.netColor
        scaleFactor: root.scaleFactor
    }

    BarModule.Label {
        text: SystemState.netName
        color: root.netColor
        visible: text.length > 0
        scaleFactor: root.scaleFactor
    }
}
