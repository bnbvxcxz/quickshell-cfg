// Scrolling marquee text component.
// Horizontally scrolls overflow text on timer when content exceeds boundary width.

import QtQuick
import QtQuick.Layouts
import "../config"

Item {
    id: root

    property string text: ""
    property color color: Theme.on_surface
    property int pixelSize: Typography.size(1.0)
    property bool bold: Typography.globalBold
    property bool italic: Typography.globalItalic
    property bool centerWhenFit: true

    implicitWidth: textElement.implicitWidth
    implicitHeight: textElement.implicitHeight
    clip: true

    readonly property bool overflows: textElement.implicitWidth > root.width
    readonly property real overflowDistance: Math.max(0, textElement.implicitWidth - root.width)

    Text {
        id: textElement
        text: root.text || ""
        color: root.color
        font.family: Typography.family
        font.pixelSize: root.pixelSize
        font.bold: root.bold
        font.italic: root.italic

        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: (!root.overflows && root.centerWhenFit) ? parent.horizontalCenter : undefined
        x: (!root.overflows && !root.centerWhenFit) ? 0 : (root.overflows ? scrollAnim.currentX : 0)

        Item {
            id: scrollAnim
            property real currentX: 0

            SequentialAnimation on currentX {
                running: root.overflows
                loops: Animation.Infinite

                PauseAnimation { duration: 1500 }
                NumberAnimation {
                    to: -root.overflowDistance
                    duration: Math.max(1000, root.overflowDistance * 25)
                    easing.type: Easing.InOutQuad
                }
                PauseAnimation { duration: 1500 }
                NumberAnimation {
                    to: 0
                    duration: Math.max(1000, root.overflowDistance * 25)
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
}
