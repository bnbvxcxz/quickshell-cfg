// Reusable interactive icon glyph button.
// Standardizes typography, color transitions, and pointer cursor for bar and control center icons.

import QtQuick
import "../config"

Text {
    id: root

    property real scaleFactor: 1.0
    property real pixelSize: Typography.size(scaleFactor)

    signal clicked()

    color: Theme.primary
    font.family: Typography.family
    font.pixelSize: pixelSize
    font.bold: Typography.globalBold
    font.italic: Typography.globalItalic

    Behavior on color { ColorAnimation { duration: 120 } }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
