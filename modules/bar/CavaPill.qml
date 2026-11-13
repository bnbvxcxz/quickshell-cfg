// Status bar PipeWire audio visualizer pill powered by cava.
// Spawns cava with line-buffered stdout only while media is playing and renders scaled frequency bars.

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../config"
import "../../services"
import "../../components"

Pill {
    id: root

    clickable: false
    wheelEnabled: false
    visible: MediaState.isPlaying
    Layout.preferredWidth: visible ? -1 : 0

    property int barCount: 12
    property var levels: ([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])

    Process {
        id: cavaProc
        command: [
            "bash", "-c",
            `cat <<'EOF' > /tmp/quickshell-cava.conf
[general]
bars = ${root.barCount}
framerate = 30
autosens = 1
sleep_timer = 0
[input]
method = pulse
source = auto
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 100
EOF
exec stdbuf -oL cava -p /tmp/quickshell-cava.conf 2>/dev/null`
        ]
        running: MediaState.isPlaying
        stdout: SplitParser {
            onRead: line => {
                let parts = line.trim().split(";").filter(s => s.length > 0);
                if (parts.length === 0) return;
                let next = [];
                for (let i = 0; i < root.barCount; i++) {
                    let v = i < parts.length ? (parseInt(parts[i]) || 0) : 0;
                    next.push(Math.max(0, Math.min(100, v)));
                }
                root.levels = next;
            }
        }
    }

    Row {
        id: barsRow
        spacing: Math.max(1, Math.round(2 * root.scaleFactor))
        height: root.implicitHeight - Metrics.scaled(8, root.scaleFactor)
        Layout.alignment: Qt.AlignVCenter

        Repeater {
            model: root.barCount

            Item {
                id: barSlot
                required property int index
                width: Math.max(2, Math.round(2 * root.scaleFactor))
                height: barsRow.height

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: Math.max(Math.max(2, Math.round(2 * root.scaleFactor)), Math.round(barSlot.height * ((root.levels[barSlot.index] || 0) / 100.0)))
                    radius: Math.max(1, Math.round(width / 2))
                    color: Theme.secondary

                    Behavior on height { NumberAnimation { duration: 40; easing.type: Easing.OutQuad } }
                }
            }
        }
    }
}
