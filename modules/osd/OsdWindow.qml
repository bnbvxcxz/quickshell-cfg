// Per-monitor on-screen display overlay.
// Displays floating progress feedback for volume and brightness changes.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../config"
import "../../services"
import "../../components"

PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    anchors { bottom: true }

    readonly property real s: Metrics.scaleFor(root.screen)
    readonly property real sW: (root.screen && root.screen.geometry) ? root.screen.geometry.width : (root.screen ? root.screen.width : 1920)

    implicitWidth: Math.max(Metrics.scaled(240, s), Math.min(Metrics.scaled(360, s), Math.round(sW * 0.16)))
    implicitHeight: Metrics.scaled(52, s)
    margins.bottom: Metrics.scaled(70, s)
    color: "transparent"

    property string type: "volume"
    property string ico: "󰕾"
    property real prg: 0.5
    property bool isMute: false
    property bool act: false

    readonly property bool hasFill: !isMute && prg > 0.0

    visible: box.opacity > 0.0

    Connections {
        target: HardwareState
        function onOsdTriggered(t, val, i, m) {
            root.type = t;
            root.ico = i;
            root.prg = val;
            root.isMute = m;
            root.act = true;
            hide.restart();
            Logger.debug("OSD", `Triggered ${t} val=${val} muted=${m}`);
        }
    }

    Timer {
        id: hide
        interval: 1400
        running: false
        onTriggered: root.act = false
    }

    SpringBehavior {
        id: sprg
        mode: root.act ? "instant" : "exit"
    }

    Rectangle {
        id: box
        anchors.fill: parent
        radius: Metrics.scaled(14, root.s)
        color: Qt.alpha(Theme.surface_container_lowest, 0.82)
        border.color: Qt.alpha(Theme.outline_variant, 0.65)
        border.width: 1

        opacity: root.act ? 1.0 : 0.0
        scale: root.act ? 1.0 : 0.88
        transformOrigin: Item.Center

        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on scale { SpringAnimation { spring: sprg.stiffnessVal; damping: sprg.dampingVal; mass: 1.0; epsilon: 0.01 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Metrics.scaled(16, root.s)
            anchors.rightMargin: Metrics.scaled(16, root.s)
            spacing: Metrics.scaled(12, root.s)

            Rectangle {
                readonly property int bSize: Metrics.scaled(30, root.s)
                implicitWidth: bSize
                implicitHeight: bSize
                radius: bSize / 2
                color: (root.isMute && root.type !== "capslock") ? Qt.alpha(Theme.error, 0.2) : Qt.alpha(Theme.primary, 0.15)

                Text {
                    anchors.centerIn: parent
                    text: (root.isMute && root.type !== "capslock") ? "󰖁" : root.ico
                    color: (root.isMute && root.type !== "capslock") ? Theme.error : Theme.primary
                    font.family: Typography.family
                    font.pixelSize: Metrics.scaled(15, root.s)
                    font.weight: Typography.weightRegular
                }
            }

            Item {
                visible: root.type !== "capslock"
                Layout.fillWidth: true
                Layout.preferredHeight: Metrics.scaled(8, root.s)

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Qt.alpha(Theme.surface_container_highest, 0.8)

                    Rectangle {
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        width: parent.width * Math.max(0.0, Math.min(1.0, root.prg))
                        radius: height / 2
                        color: Theme.primary
                        opacity: root.hasFill ? 1.0 : 0.0

                        Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                    }
                }
            }

            Text {
                text: {
                    if (root.type === "capslock") return root.prg > 0 ? "CAPS ON" : "CAPS OFF";
                    if (root.isMute) return "MUTE";
                    return `${Math.round(root.prg * 100)}%`;
                }
                color: (root.isMute || (root.type === "capslock" && root.prg === 0)) ? Theme.error : Theme.on_surface
                font.family: Typography.family
                font.pixelSize: Typography.size(root.s)
                font.weight: Typography.weightRegular

                Layout.fillWidth: root.type === "capslock"
                Layout.preferredWidth: root.type === "capslock" ? -1 : Metrics.scaled(42, root.s)
                horizontalAlignment: root.type === "capslock" ? Text.AlignLeft : Text.AlignRight
            }
        }
    }
}
