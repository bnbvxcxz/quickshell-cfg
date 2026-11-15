// Status bar PipeWire audio visualizer module powered by MediaState cava stream.
// Renders scaled frequency bars without spawning duplicate per-monitor cava processes.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../components"

BarModule {
    id: root

    clickable: false
    wheelEnabled: false
    visible: MediaState.isPlaying
    Layout.preferredWidth: visible ? -1 : 0

    Row {
        id: barsRow
        spacing: Math.max(1, Math.round(2 * root.scaleFactor))
        height: root.implicitHeight - Metrics.scaled(8, root.scaleFactor)
        Layout.alignment: Qt.AlignVCenter

        Repeater {
            model: MediaState.cavaBarCount

            Item {
                id: barSlot
                required property int index
                width: Math.max(2, Math.round(2 * root.scaleFactor))
                height: barsRow.height

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: Math.max(Math.max(2, Math.round(2 * root.scaleFactor)), Math.round(barSlot.height * ((MediaState.cavaLevels[barSlot.index] || 0) / 100.0)))
                    radius: Math.max(1, Math.round(width / 2))
                    color: Theme.secondary

                    Behavior on height { NumberAnimation { duration: 40; easing.type: Easing.OutQuad } }
                }
            }
        }
    }
}
