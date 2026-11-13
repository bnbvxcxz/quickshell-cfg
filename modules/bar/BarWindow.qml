// Main status bar layer surface.
// Arranges modular left, center, and right pills with per-screen scaling and spring entrance.

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

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-bar"

    anchors {
        top: true
        left: true
        right: true
    }

    readonly property real screenScale: Metrics.scaleFor(barWindow.screen)
    readonly property int fullHeight: Metrics.scaled(Theme.baseBarHeight, screenScale)

    implicitHeight: fullHeight
    WlrLayershell.exclusiveZone: fullHeight
    color: Qt.alpha(Theme.background, Theme.barOpacity)

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

    readonly property bool isPrimaryScreen: barWindow.screen ? (barWindow.screen.x === 0 && barWindow.screen.y === 0) : true
    readonly property color activeWsBg: isPrimaryScreen ? Theme.secondary : Theme.tertiary
    readonly property color activeWsFg: isPrimaryScreen ? Theme.on_secondary : Theme.on_tertiary
    readonly property color inactiveWsFg: isPrimaryScreen ? Theme.secondary : Theme.tertiary

    readonly property real availTitleWidth: {
        let closestSide = Math.max(leftBarRow.width, rightBarRow.width);
        let pillGap = Metrics.scaled(48, barWindow.screenScale);
        let free = barWindow.width - (closestSide * 2) - (pillGap * 2);
        return Math.max(Metrics.scaled(120, barWindow.screenScale), free);
    }

    Item {
        anchors.fill: parent

        RowLayout {
            id: leftBarRow
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
            CavaPill { scaleFactor: barWindow.screenScale }
        }

        WindowTitlePill {
            anchors.centerIn: parent
            scaleFactor: barWindow.screenScale
            maxPixelWidth: barWindow.availTitleWidth
        }

        RowLayout {
            id: rightBarRow
            anchors.right: parent.right
            anchors.rightMargin: Metrics.scaled(2, barWindow.screenScale)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Metrics.scaled(2, barWindow.screenScale)

            UpdatesPill {
                scaleFactor: barWindow.screenScale
                barWindowRef: barWindow
            }
            SystemTrayPill {
                scaleFactor: barWindow.screenScale
                barWindowRef: barWindow
            }
            AudioPill { scaleFactor: barWindow.screenScale }
            BatteryPill { scaleFactor: barWindow.screenScale }
            NetworkPill { scaleFactor: barWindow.screenScale }
            BacklightPill { scaleFactor: barWindow.screenScale }
            ControlCenterPill { scaleFactor: barWindow.screenScale }
        }
    }
}
