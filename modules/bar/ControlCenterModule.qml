// Status bar trigger button for the Control Center drawer.
// Toggles the drawer open state and reflects active panel status.

import QtQuick
import "../../config"
import "../../services"
import "../../components"

BarModule {
    id: root

    property string screenName: ""
    readonly property bool isOpen: NotificationState.panelOpen

    implicitWidth: implicitHeight
    horizontalPadding: 0
    moduleColor: isOpen ? Theme.primary : Theme.surface_container_high

    onClicked: { Logger.debug("ControlCenter", `Bar button clicked on ${root.screenName}`); NotificationState.toggleRequested(root.screenName); }

    BarModule.Icon {
        text: root.isOpen ? "󰅀" : "󰍜"
        color: root.isOpen ? Theme.on_primary : Theme.primary
        scaleFactor: root.scaleFactor
    }
}
