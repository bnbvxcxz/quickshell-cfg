// Reusable Hyprland physics spring preset for Quickshell UI motion.
// Maps animation profile modes to corresponding stiffness and damping curves.

import QtQuick

Item {
    id: root

    property string mode: "default"

    readonly property real stiffnessVal: {
        switch (mode) {
            case "exit": return 6.2;
            case "instant": return 5.5;
            default: return 4.8;
        }
    }

    readonly property real dampingVal: {
        switch (mode) {
            case "exit": return 0.44;
            case "instant": return 0.40;
            default: return 0.36;
        }
    }

    component SpringProp: Behavior {
        property string profile: root.mode
        SpringAnimation {
            spring: root.stiffnessVal
            damping: root.dampingVal
            mass: 1.0
            epsilon: 0.25
        }
    }
}
