// Quick action toggle buttons.
// Provides animated toggles for network, bluetooth, audio mute, DND, and DND states.

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../config"
import "../../services"

RowLayout {
    id: root

    property bool isCompact: false
    property real scaleFactor: 1.0
    property bool wifiOn: true
    property bool btOn: true

    spacing: Math.round(6 * scaleFactor)

    onVisibleChanged: { if (visible && !radioProbe.running) radioProbe.running = true; }

    Process {
        id: radioProbe
        command: ["bash", "-c", "w=$(nmcli radio wifi 2>/dev/null); b=$(rfkill -n -o SOFT list bluetooth 2>/dev/null | head -n1); echo \"${w:-enabled}:${b:-unblocked}\""]
        running: true
        stdout: SplitParser {
            onRead: line => {
                let p = line.trim().split(":");
                if (p.length >= 2) {
                    root.wifiOn = (p[0].trim() === "enabled");
                    root.btOn = (p[1].trim() === "unblocked");
                }
            }
        }
    }

    Repeater {
        model: [
            { icon: "󰤨", onCmd: "nmcli radio wifi on", offCmd: "nmcli radio wifi off", kind: "wifi" },
            { icon: "󰂯", onCmd: "rfkill unblock bluetooth", offCmd: "rfkill block bluetooth", kind: "bt" },
            { icon: "󰕾", kind: "mute" },
            { icon: "󰂛", kind: "dnd" }
        ]

        Rectangle {
            id: btn
            required property var modelData

            readonly property bool toggled: {
                if (modelData.kind === "mute") return !HardwareState.isMuted;
                if (modelData.kind === "dnd") return NotificationState.dnd;
                if (modelData.kind === "wifi") return root.wifiOn;
                if (modelData.kind === "bt") return root.btOn;
                return false;
            }

            Layout.fillWidth: true
            Layout.preferredHeight: root.isCompact ? Math.round(24 * root.scaleFactor) : Math.round(32 * root.scaleFactor)
            radius: Metrics.cornerRadius

            color: toggled ? Theme.primary : Qt.alpha(Theme.surface_container_high, Metrics.cardHighOpacity)
            border.color: toggled ? Theme.primary : Qt.alpha(Theme.outline_variant, Metrics.subtleOutlineOpacity)
            border.width: 1

            Behavior on Layout.preferredHeight {
                NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
            }
            Behavior on color { ColorAnimation { duration: 140 } }

            Text {
                anchors.centerIn: parent
                text: {
                    if (btn.modelData.kind === "mute") return HardwareState.isMuted ? "󰖁" : "󰕾";
                    if (btn.modelData.kind === "dnd") return NotificationState.dnd ? "󰂛" : "󰂚";
                    return btn.modelData.icon;
                }
                color: btn.toggled ? Theme.on_primary : Theme.primary
                font.family: Typography.family
                font.pixelSize: root.isCompact ? Typography.sizeSmall(root.scaleFactor) : Typography.size(root.scaleFactor)
                font.weight: Typography.weightRegular
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    let k = btn.modelData.kind;
                    if (k === "mute") { Logger.debug("QuickToggles", "Toggled mute"); return HardwareState.toggleMute(false); }
                    if (k === "dnd") { NotificationState.toggleDnd(); Logger.debug("QuickToggles", `Toggled DND=${NotificationState.dnd}`); return; }
                    if (k === "wifi") {
                        root.wifiOn = !root.wifiOn;
                        Logger.debug("QuickToggles", `Toggled Wi-Fi=${root.wifiOn}`);
                        return HardwareState.runCmd(root.wifiOn ? btn.modelData.onCmd : btn.modelData.offCmd);
                    }
                    if (k === "bt") {
                        root.btOn = !root.btOn;
                        Logger.debug("QuickToggles", `Toggled Bluetooth=${root.btOn}`);
                        return HardwareState.runCmd(root.btOn ? btn.modelData.onCmd : btn.modelData.offCmd);
                    }
                }
            }
        }
    }
}
