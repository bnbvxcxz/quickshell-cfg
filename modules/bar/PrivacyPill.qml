// Status bar PipeWire privacy indicator (optional drop-in module).
// Uses native Pipewire.nodes to detect active microphone and screen-share capture streams.

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import "../../config"
import "../../components"

Pill {
    id: root

    clickable: false
    wheelEnabled: false

    readonly property bool hasMic: {
        let vals = (Pipewire.nodes && Pipewire.nodes.values) ? Pipewire.nodes.values : [];
        for (let i = 0; i < vals.length; i++) {
            let n = vals[i];
            if (n && n.isStream && !n.isSink && n.audio !== null) return true;
        }
        return false;
    }

    readonly property bool hasScreen: {
        let vals = (Pipewire.nodes && Pipewire.nodes.values) ? Pipewire.nodes.values : [];
        for (let i = 0; i < vals.length; i++) {
            let n = vals[i];
            if (n && n.isStream && !n.isSink && n.audio === null) return true;
        }
        return false;
    }

    visible: hasMic || hasScreen
    Layout.preferredWidth: visible ? -1 : 0
    pillColor: Theme.error_container

    Pill.Icon {
        visible: root.hasMic
        text: "󰍬"
        color: Theme.on_error_container
        scaleFactor: root.scaleFactor
    }

    Pill.Icon {
        visible: root.hasScreen
        text: "󰹑"
        color: Theme.on_error_container
        scaleFactor: root.scaleFactor
    }
}
