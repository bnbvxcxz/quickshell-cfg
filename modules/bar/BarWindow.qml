// Main status bar layer surface.
// Provides startup spring entrance physics and arranges bar modules across display screens.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../config"
import "../../services"
import "../../components"
import "."

PanelWindow {
    id: barWindow

    // [ANCHOR:WAYLAND_LAYER]
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-bar"

    anchors {
        top: true
        left: true
        right: true
    }

    readonly property real screenScale: Metrics.scaleFor(barWindow.screen)
    readonly property int fullHeight: Metrics.scaled(Theme.baseBarHeight, screenScale)

    // Explicit implicitHeight for WlrLayershell compliance
    implicitHeight: fullHeight
    WlrLayershell.exclusiveZone: fullHeight

    color: Qt.alpha(Theme.background, 0.7)

    // [ANCHOR:BAR_SPRING_ENTRANCE]
    property bool appeared: false
    margins.top: appeared ? 0 : -fullHeight

    SpringBehavior { id: springPresets; mode: "default" }

    Behavior on margins.top {
        SpringAnimation {
            spring: springPresets.stiffnessVal
            damping: springPresets.dampingVal
            mass: 1.0
            epsilon: 0.5
        }
    }

    Component.onCompleted: appeared = true

    // [ANCHOR:SCREEN_LOGIC]
    readonly property bool isPrimaryScreen: barWindow.screen ? (barWindow.screen.x === 0 && barWindow.screen.y === 0) : true
    readonly property color activeWsBg: isPrimaryScreen ? Theme.secondary : Theme.tertiary
    readonly property color activeWsFg: isPrimaryScreen ? Theme.on_secondary : Theme.on_tertiary
    readonly property color inactiveWsFg: isPrimaryScreen ? Theme.secondary : Theme.tertiary

    Item {
        anchors.fill: parent

        RowLayout {
            anchors.left: parent.left
            anchors.leftMargin: Metrics.scaled(2, barWindow.screenScale)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Metrics.scaled(2, barWindow.screenScale)

            ClockPill { scaleFactor: barWindow.screenScale }

            WorkspacesPill {
                scaleFactor: barWindow.screenScale
                activeBg: barWindow.activeWsBg
                activeFg: barWindow.activeWsFg
                inactiveFg: barWindow.inactiveWsFg
            }

            IdlePill { scaleFactor: barWindow.screenScale }

            MprisPill { scaleFactor: barWindow.screenScale }
        }

        WindowTitlePill {
            anchors.centerIn: parent
            scaleFactor: barWindow.screenScale
        }

        RowLayout {
            anchors.right: parent.right
            anchors.rightMargin: Metrics.scaled(2, barWindow.screenScale)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Metrics.scaled(2, barWindow.screenScale)

            UpdatesPill {
                scaleFactor: barWindow.screenScale
                barWindowRef: barWindow
            }
            SystemTrayPill { scaleFactor: barWindow.screenScale }
            AudioPill { scaleFactor: barWindow.screenScale }
            BatteryPill { scaleFactor: barWindow.screenScale }
            NetworkPill { scaleFactor: barWindow.screenScale }
            BacklightPill { scaleFactor: barWindow.screenScale }
            ControlCenterPill { scaleFactor: barWindow.screenScale }
        }
    }
}
