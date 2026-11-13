// Status bar idle inhibitor toggle.
// Manages systemd-inhibit idle sleep locks without external pkill calls.

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../config"
import "../../services"
import "../../components"

Pill {
    id: root

    property bool inhibited: false
    implicitWidth: implicitHeight
    horizontalPadding: 0
    pillColor: inhibited ? Theme.primary_container : Theme.surface_container_high

    Process {
        id: inhibitor
        command: ["systemd-inhibit", "--what=idle", "--who=quickshell", "--why=Bar inhibitor", "sleep", "infinity"]
    }

    onClicked: {
        root.inhibited = !root.inhibited;
        // Toggling running = false cleanly stops the child process in Quickshell.
        inhibitor.running = root.inhibited;
    }

    Pill.Icon {
        text: root.inhibited ? "" : ""
        color: root.inhibited ? Theme.on_primary_container : Theme.on_surface_variant
        scaleFactor: root.scaleFactor
    }
}
