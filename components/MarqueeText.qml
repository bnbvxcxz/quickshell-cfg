// Scrolling marquee text component.
// Horizontally scrolls overflow text at a calm linear pace like an iPod and resets to start.

import QtQuick
import "../config"

Item {
    id: root

    property string text: ""
    property color color: Theme.on_surface
    property int pixelSize: Typography.size(1.0)
    property bool bold: Typography.globalBold
    property bool italic: Typography.globalItalic
    property bool centerWhenFit: true

    readonly property real textW: Math.ceil(textElement.paintedWidth > 0 ? textElement.paintedWidth : textElement.implicitWidth)
    implicitWidth: textW
    implicitHeight: textElement.implicitHeight
    clip: true

    readonly property bool overflows: textW > root.width
    readonly property real overflowDistance: Math.max(0, textW - root.width)

    onOverflowsChanged: { if (!overflows) scrollAnim.currentX = 0; }

    Text {
        id: textElement
        text: root.text || ""
        color: root.color
        font.family: Typography.family
        font.pixelSize: root.pixelSize
        font.bold: root.bold
        font.italic: root.italic

        anchors.verticalCenter: parent.verticalCenter
        x: root.overflows ? scrollAnim.currentX : (root.centerWhenFit ? Math.round((root.width - root.textW) / 2) : 0)

        Item {
            id: scrollAnim
            property real currentX: 0

            SequentialAnimation on currentX {
                running: root.visible && root.overflows
                loops: Animation.Infinite
                onRunningChanged: { if (!running) scrollAnim.currentX = 0; }

                PauseAnimation { duration: 2000 }
                NumberAnimation {
                    from: 0
                    to: -root.overflowDistance
                    duration: Math.max(2000, Math.round(root.overflowDistance * 42))
                    easing.type: Easing.Linear
                }
                PauseAnimation { duration: 1500 }
                PropertyAction { value: 0 }
            }
        }
    }
}
