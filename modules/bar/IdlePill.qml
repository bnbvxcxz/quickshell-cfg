// Status bar idle inhibitor toggle.
// Manages systemd-inhibit idle sleep locks.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../components"

Pill {
    id: root

    property bool inhibited: false
    implicitWidth: implicitHeight
    horizontalPadding: 0
    pillColor: inhibited ? Theme.primary_container : Theme.surface_container_high

    onClicked: {
        root.inhibited = !root.inhibited;
        if (root.inhibited) {
            HardwareState.runCmd("systemd-inhibit --what=idle --who=quickshell --why='Bar inhibitor' sleep infinity &");
        } else {
            HardwareState.runCmd("pkill -f 'sleep infinity'");
        }
    }

    Pill.Icon {
        text: root.inhibited ? "" : ""
        color: root.inhibited ? Theme.on_primary_container : Theme.on_surface_variant
        scaleFactor: root.scaleFactor
    }
}
