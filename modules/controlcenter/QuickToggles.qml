// Quick action toggle buttons.
// Provides animated toggles for network, bluetooth, audio mute, and lock states.

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../config"
import "../../services"

RowLayout {
    id: root

    property bool isCompact: false
    property real scaleFactor: 1.0
    spacing: Math.round(6 * scaleFactor)

    function runCmd(cmd) {
        if (!cmd) return;
        cmdRunner.command = ["bash", "-c", cmd];
        cmdRunner.running = true;
    }

    Process {
        id: cmdRunner
        running: false
    }

    Repeater {
        model: [
            { icon: "󰤨", onCmd: "nmcli radio wifi on", offCmd: "nmcli radio wifi off", active: true },
            { icon: "󰂯", onCmd: "rfkill unblock bluetooth", offCmd: "rfkill block bluetooth", active: true },
            { icon: "󰕾", isMuteBtn: true },
            { icon: "", onCmd: "hyprlock", offCmd: "", active: false }
        ]

        Rectangle {
            id: btn
            required property var modelData

            property bool toggled: modelData.isMuteBtn ? !HardwareState.isMuted : (modelData.active ?? false)

            Layout.fillWidth: true
            Layout.preferredHeight: root.isCompact ? Math.round(24 * root.scaleFactor) : Math.round(32 * root.scaleFactor)
            radius: Theme.cornerRadius

            color: toggled ? Theme.primary : Qt.alpha(Theme.surface_container_high, 0.7)
            border.color: toggled ? Theme.primary : Qt.alpha(Theme.outline_variant, 0.4)
            border.width: 1

            Behavior on Layout.preferredHeight {
                NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
            }
            Behavior on color { ColorAnimation { duration: 140 } }

            Text {
                anchors.centerIn: parent
                text: btn.modelData.isMuteBtn ? (HardwareState.isMuted ? "󰖁" : "󰕾") : btn.modelData.icon
                color: btn.toggled ? Theme.on_primary : Theme.primary
                font.family: Typography.family
                font.pixelSize: root.isCompact ? Typography.sizeSmall(root.scaleFactor) : Typography.size(root.scaleFactor)
                font.weight: Typography.weightRegular
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (btn.modelData.icon === "") {
                        root.runCmd(btn.modelData.onCmd);
                        return;
                    }
                    if (btn.modelData.isMuteBtn) {
                        HardwareState.toggleMute(false);
                        return;
                    }
                    btn.toggled = !btn.toggled;
                    root.runCmd(btn.toggled ? btn.modelData.onCmd : btn.modelData.offCmd);
                }
            }
        }
    }
}
