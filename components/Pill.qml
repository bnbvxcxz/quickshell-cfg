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
    property bool clickable: true
    property bool wheelEnabled: true
    property bool interactive: true
    readonly property bool containsMouse: pillMouseArea.containsMouse

    signal clicked()
    signal rightClicked()
    signal middleClicked()
    signal wheelMoved(int steps)

    implicitHeight: Metrics.scaled(Theme.baseBarHeight, scaleFactor)
    implicitWidth: contentLayout.implicitWidth + (horizontalPadding * 2)
    radius: Theme.pillRadius < 0 ? Math.round(implicitHeight / 2) : Metrics.scaled(Theme.pillRadius, scaleFactor)
    color: pillColor
    border.width: Theme.pillBorderWidth
    border.color: Theme.pillBorderColor

    Layout.alignment: Qt.AlignVCenter
    Layout.fillHeight: false
    Layout.topMargin: 0
    Layout.bottomMargin: 0
    Layout.leftMargin: visible ? 1 : 0
    Layout.rightMargin: visible ? 1 : 0

    MouseArea {
        id: pillMouseArea
        anchors.fill: parent
        enabled: pillRoot.interactive && (pillRoot.clickable || pillRoot.wheelEnabled || pillRoot.hoverEnabled)
        cursorShape: (pillRoot.interactive && pillRoot.clickable) ? Qt.PointingHandCursor : Qt.ArrowCursor
        hoverEnabled: pillRoot.hoverEnabled
        acceptedButtons: (pillRoot.interactive && pillRoot.clickable)
            ? (Qt.LeftButton | Qt.RightButton | Qt.MiddleButton)
            : Qt.NoButton

        property int scrollAccumulator: 0

        onClicked: mouse => {
            if (!pillRoot.clickable) return;
            if (mouse.button === Qt.LeftButton) pillRoot.clicked();
            else if (mouse.button === Qt.RightButton) pillRoot.rightClicked();
            else if (mouse.button === Qt.MiddleButton) pillRoot.middleClicked();
        }

        onWheel: wheel => {
            if (!pillRoot.wheelEnabled) {
                wheel.accepted = false;
                return;
            }
            let dy = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x;
            scrollAccumulator += dy;
            while (Math.abs(scrollAccumulator) >= 120) {
                let step = scrollAccumulator > 0 ? 1 : -1;
                pillRoot.wheelMoved(step);
                scrollAccumulator -= (step * 120);
            }
            wheel.accepted = true;
        }
    }

    RowLayout {
        id: contentLayout
        anchors.centerIn: parent
        spacing: Metrics.scaled(Theme.baseSpacing, pillRoot.scaleFactor)
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
