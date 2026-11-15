// Status bar battery indicator.
// Displays battery percentage and charging icons with color-coded health thresholds.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../components"

BarModule {
    id: root

    clickable: false
    wheelEnabled: false
    visible: SystemState.batPresent
    Layout.preferredWidth: visible ? -1 : 0

    readonly property int pct: SystemState.batPct
    readonly property bool charging: SystemState.isBatCharging

    moduleColor: {
        if (!charging && pct <= 15) return Theme.error_container;
        if (charging) return Theme.primary_container;
        return Theme.surface_container_high;
    }

    readonly property color statusColor: {
        if (charging) return Theme.on_primary_container;
        if (pct <= 15) return Theme.on_error_container;
        if (pct <= 30) return Theme.error;
        if (pct <= 60) return Theme.tertiary;
        return Theme.primary;
    }

    BarModule.Icon {
        text: SystemState.batIco
        color: root.statusColor
        scaleFactor: root.scaleFactor

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    BarModule.Label {
        text: SystemState.batCap
        color: root.statusColor
        scaleFactor: root.scaleFactor

        Behavior on color { ColorAnimation { duration: 150 } }
    }
}
