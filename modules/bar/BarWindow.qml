// Main status bar layer surface.
// Arranges modular left, center, and right modules with per-screen scaling and spring entrance.

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
    readonly property int fullHeight: Metrics.scaled(Metrics.baseBarHeight, screenScale)

    implicitHeight: fullHeight
    WlrLayershell.exclusiveZone: fullHeight
    color: Qt.alpha(Theme.background, Metrics.barOpacity)

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
        let modGap = Metrics.scaled(48, barWindow.screenScale);
        let free = barWindow.width - (closestSide * 2) - (modGap * 2);
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

            ClockModule { scaleFactor: barWindow.screenScale }

            WorkspacesModule {
                scaleFactor: barWindow.screenScale
                activeBg: barWindow.activeWsBg
                activeFg: barWindow.activeWsFg
                inactiveFg: barWindow.inactiveWsFg
            }

            IdleModule { scaleFactor: barWindow.screenScale }
            MprisModule { scaleFactor: barWindow.screenScale }
            CavaModule { scaleFactor: barWindow.screenScale }
        }

        WindowTitleModule {
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

            UpdatesModule {
                scaleFactor: barWindow.screenScale
                barWindowRef: barWindow
            }
            SystemTrayModule {
                scaleFactor: barWindow.screenScale
                barWindowRef: barWindow
            }
            AudioModule { scaleFactor: barWindow.screenScale }
            BatteryModule { scaleFactor: barWindow.screenScale }
            NetworkModule { scaleFactor: barWindow.screenScale }
            BacklightModule { scaleFactor: barWindow.screenScale }
            ControlCenterModule { scaleFactor: barWindow.screenScale; screenName: barWindow.screen ? barWindow.screen.name : "" }
        }
    }
}
