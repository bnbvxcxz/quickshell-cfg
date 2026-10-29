// Status bar trigger button for the Control Center drawer.
// Toggles the drawer open state via IPC and reflects active panel status.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../components"

Pill {
    id: root

    readonly property bool isOpen: (typeof shellRoot !== "undefined") ? shellRoot.panelOpen : false

    implicitWidth: implicitHeight
    horizontalPadding: 0
    pillColor: isOpen ? Theme.primary : Theme.surface_container_high

    onClicked: {
        if (typeof shellRoot !== "undefined") {
            shellRoot.togglePanel();
        } else {
            HardwareState.runCmd("quickshell ipc call drawer toggle");
        }
    }

    Pill.Icon {
        text: root.isOpen ? "󰅀" : "󰍜"
        color: root.isOpen ? Theme.on_primary : Theme.primary
        scaleFactor: root.scaleFactor
    }
}
