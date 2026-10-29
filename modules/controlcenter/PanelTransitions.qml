// Spring-based drawer transition coordinator.
// Animates margin offsets for entering and exiting the screen surface.

import QtQuick
import "../../config"
import "../../components"

Item {
    id: transitions

    property var panelWindow: null
    property int screenMode: 0
    property bool isOpen: false
    property real scaleFactor: 1.0

    readonly property real drawerWidth: Metrics.scaled(Theme.baseDrawerWidth, scaleFactor)
    readonly property real drawerHeight: Metrics.scaled(Theme.baseDrawerHeight, scaleFactor)

    property real currentMarginX: targetMarginX
    property real currentMarginY: targetMarginY

    readonly property real targetMarginX: {
        if (isOpen) return 8;
        return -drawerWidth - 8;
    }

    readonly property real targetMarginY: {
        if (isOpen) return 26;
        if (screenMode === 2) return -drawerHeight - 26;
        return 26;
    }

    SpringBehavior {
        id: springPresets
        mode: isOpen ? "default" : "exit"
    }

    Behavior on currentMarginX {
        SpringAnimation {
            spring: springPresets.stiffnessVal
            damping: springPresets.dampingVal
            mass: 1.0
            epsilon: 0.5
        }
    }

    Behavior on currentMarginY {
        SpringAnimation {
            spring: springPresets.stiffnessVal
            damping: springPresets.dampingVal
            mass: 1.0
            epsilon: 0.5
        }
    }

    Binding {
        target: panelWindow
        property: (transitions.screenMode === 0) ? "margins.right" : "margins.left"
        value: transitions.currentMarginX
        when: transitions.panelWindow !== null
    }

    Binding {
        target: panelWindow
        property: "margins.top"
        value: transitions.currentMarginY
        when: transitions.panelWindow !== null
    }
}
