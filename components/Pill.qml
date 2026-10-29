// Universal pill container and text/icon primitive definitions.
// Standardizes spacing, alignment, and inherits centralized typography settings automatically.

import QtQuick
import QtQuick.Layouts
import "../config"

Rectangle {
    id: pillRoot

    default property alias data: contentLayout.data
        property color pillColor: Theme.surface_container_high
        property real scaleFactor: 1.0
        property int horizontalPadding: Metrics.scaled(Theme.basePillPadding, scaleFactor)

        property bool hoverEnabled: false
        readonly property bool containsMouse: pillMouseArea.containsMouse

        signal clicked()
        signal rightClicked()
        signal middleClicked()
        signal wheelMoved(int steps)

        // Master uniform pill dimensions
        implicitHeight: Metrics.scaled(Theme.baseBarHeight, scaleFactor)
        implicitWidth: contentLayout.implicitWidth + (horizontalPadding * 2)
        radius: Math.round(implicitHeight / 2)
        color: pillColor

        Layout.alignment: Qt.AlignVCenter
        Layout.fillHeight: false
        Layout.topMargin: 0
        Layout.bottomMargin: 0
        Layout.leftMargin: 1
        Layout.rightMargin: 1

        RowLayout {
            id: contentLayout
            anchors.centerIn: parent
            spacing: Metrics.scaled(Theme.baseSpacing, pillRoot.scaleFactor)
        }

        MouseArea {
            id: pillMouseArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: pillRoot.hoverEnabled
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

            property int scrollAccumulator: 0

            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton) pillRoot.clicked();
                else if (mouse.button === Qt.RightButton) pillRoot.rightClicked();
                else if (mouse.button === Qt.MiddleButton) pillRoot.middleClicked();
            }

            onWheel: wheel => {
                scrollAccumulator += wheel.angleDelta.y;
                while (Math.abs(scrollAccumulator) >= 120) {
                    let step = scrollAccumulator > 0 ? 1 : -1;
                    pillRoot.wheelMoved(step);
                    scrollAccumulator -= (step * 120);
                }
            }
        }

        component Label: Text {
            property real scaleFactor: 1.0
            color: Theme.primary
            font.family: Typography.family
            font.pixelSize: Typography.size(scaleFactor)
            font.bold: Typography.globalBold
            font.italic: Typography.globalItalic
            font.weight: Typography.globalWeight
            Layout.alignment: Qt.AlignVCenter
        }

        component Icon: Text {
            property real scaleFactor: 1.0
            color: Theme.primary
            font.family: Typography.family
            font.pixelSize: Typography.size(scaleFactor)
            font.bold: Typography.globalBold
            font.italic: Typography.globalItalic
            font.weight: Typography.globalWeight
            Layout.alignment: Qt.AlignVCenter
        }
}
