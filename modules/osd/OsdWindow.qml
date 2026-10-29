// Per-monitor on-screen display overlay.
// Displays floating progress feedback for volume and brightness changes driven by spring physics.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../config"
import "../../services"
import "../../components"

PanelWindow {
    id: osdWindow

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    anchors { bottom: true }

    readonly property real s: Metrics.scaleFor(osdWindow.screen)
    readonly property real screenWidth: (osdWindow.screen && osdWindow.screen.geometry) ? osdWindow.screen.geometry.width : (osdWindow.screen ? osdWindow.screen.width : 1920)

    // Dynamic width proportional to screen width, clamped within scaled bounds
    implicitWidth: Math.max(Metrics.scaled(240, s), Math.min(Metrics.scaled(360, s), Math.round(screenWidth * 0.16)))
    implicitHeight: Metrics.scaled(52, s)
    margins.bottom: Metrics.scaled(70, s)
    color: "transparent"

    property string iconText: "󰕾"
    property real progressVal: 0.5
    property bool isMuted: false
    property bool active: false

    readonly property bool hasFill: !isMuted && progressVal > 0.0

    visible: osdBox.opacity > 0.0

    IpcHandler {
        target: "osd"
        function show(jsonStr: string) {
            try {
                let data = JSON.parse(jsonStr);
                if (data.icon !== undefined) osdWindow.iconText = data.icon;
                if (data.value !== undefined) osdWindow.progressVal = Math.max(0.0, Math.min(1.0, data.value));
                if (data.muted !== undefined) osdWindow.isMuted = !!data.muted;

                osdWindow.active = true;
                hideTimer.restart();
            } catch (err) {
                console.warn("[OSD] Parse error:", err);
            }
        }
    }

    Connections {
        target: HardwareState
        function onOsdTriggered(type, value, icon, muted) {
            osdWindow.iconText = icon;
            osdWindow.progressVal = value;
            osdWindow.isMuted = muted;
            osdWindow.active = true;
            hideTimer.restart();
        }
    }

    Timer {
        id: hideTimer
        interval: 1400
        running: false
        onTriggered: osdWindow.active = false
    }

    SpringBehavior {
        id: springPresets
        mode: osdWindow.active ? "instant" : "exit"
    }

    Rectangle {
        id: osdBox
        anchors.fill: parent
        radius: Metrics.scaled(14, osdWindow.s)
        color: Qt.alpha(Theme.surface_container_lowest, 0.82)
        border.color: Qt.alpha(Theme.outline_variant, 0.65)
        border.width: 1

        opacity: osdWindow.active ? 1.0 : 0.0
        scale: osdWindow.active ? 1.0 : 0.88
        transformOrigin: Item.Center

        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        Behavior on scale {
            SpringAnimation {
                spring: springPresets.stiffnessVal
                damping: springPresets.dampingVal
                mass: 1.0
                epsilon: 0.01
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Metrics.scaled(16, osdWindow.s)
            anchors.rightMargin: Metrics.scaled(16, osdWindow.s)
            spacing: Metrics.scaled(12, osdWindow.s)

            Rectangle {
                readonly property int bubbleSize: Metrics.scaled(30, osdWindow.s)
                implicitWidth: bubbleSize
                implicitHeight: bubbleSize
                radius: bubbleSize / 2
                color: osdWindow.isMuted ? Qt.alpha(Theme.error, 0.2) : Qt.alpha(Theme.primary, 0.15)

                Text {
                    anchors.centerIn: parent
                    text: osdWindow.isMuted ? "󰖁" : osdWindow.iconText
                    color: osdWindow.isMuted ? Theme.error : Theme.primary
                    font.family: Typography.family
                    font.pixelSize: Metrics.scaled(15, osdWindow.s)
                    font.weight: Typography.weightRegular
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Metrics.scaled(8, osdWindow.s)

                // Background track
                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Qt.alpha(Theme.surface_container_highest, 0.8)

                    // Colored fill bar: collapses smoothly to 0 width and fades out
                    Rectangle {
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        width: parent.width * Math.max(0.0, Math.min(1.0, osdWindow.progressVal))
                        radius: height / 2
                        color: Theme.primary
                        opacity: osdWindow.hasFill ? 1.0 : 0.0

                        Behavior on width {
                            NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                        }
                        Behavior on opacity {
                            NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }

            Text {
                text: osdWindow.isMuted ? "MUTE" : `${Math.round(osdWindow.progressVal * 100)}%`
                color: osdWindow.isMuted ? Theme.error : Theme.on_surface
                font.family: Typography.family
                font.pixelSize: Typography.size(osdWindow.s)
                font.weight: Typography.weightRegular
                Layout.preferredWidth: Metrics.scaled(42, osdWindow.s)
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
