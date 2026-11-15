// Status bar idle inhibitor toggle.
// Manages systemd-inhibit idle sleep locks without external pkill calls.

import QtQuick
import Quickshell.Io
import "../../config"
import "../../services"
import "../../components"

BarModule {
    id: root

    property bool inhibited: false
    implicitWidth: implicitHeight
    horizontalPadding: 0
    moduleColor: inhibited ? Theme.primary_container : Theme.surface_container_high

    Process {
        id: inhibitor
        command: ["systemd-inhibit", "--what=idle", "--who=quickshell", "--why=Bar inhibitor", "sleep", "infinity"]
    }

    onClicked: {
        root.inhibited = !root.inhibited;
        // Toggling running = false cleanly stops the child process in Quickshell.
        inhibitor.running = root.inhibited;
        Logger.debug("Idle", `Inhibitor ${root.inhibited ? "enabled" : "disabled"}`);
    }

    BarModule.Icon {
        text: root.inhibited ? "" : ""
        color: root.inhibited ? Theme.on_primary_container : Theme.on_surface_variant
        scaleFactor: root.scaleFactor
    }
}
