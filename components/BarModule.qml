// Universal bar module container and text/icon primitive definitions.
// Standardizes box/capsule geometry, spacing, alignment, and centralized typography.

import QtQuick
import QtQuick.Layouts
import "../config"

Rectangle {
    id: modRoot

    default property alias data: contentLayout.data
    property color moduleColor: Theme.surface_container_high
    property real scaleFactor: 1.0
    property int horizontalPadding: Metrics.scaled(Metrics.baseModulePadding, scaleFactor)

    property bool hoverEnabled: false
    property bool clickable: true
    property bool wheelEnabled: true
    property bool interactive: true
    readonly property bool containsMouse: modMouseArea.containsMouse

    signal clicked()
    signal rightClicked()
    signal middleClicked()
    signal wheelMoved(int steps)

    implicitHeight: Math.max(12, Metrics.scaled(Metrics.baseBarHeight - (Metrics.baseModuleGapY * 2), scaleFactor))
    implicitWidth: contentLayout.implicitWidth + (horizontalPadding * 2)
    radius: Metrics.moduleRadius < 0 ? Math.round(implicitHeight / 2) : Metrics.scaled(Metrics.moduleRadius, scaleFactor)
    color: moduleColor
    border.width: Metrics.moduleBorderWidth
    border.color: Metrics.moduleBorderColor

    Layout.alignment: Qt.AlignVCenter
    Layout.fillHeight: false
    Layout.topMargin: Metrics.scaled(Metrics.baseModuleGapY, scaleFactor)
    Layout.bottomMargin: Metrics.scaled(Metrics.baseModuleGapY, scaleFactor)
    Layout.leftMargin: visible ? 1 : 0
    Layout.rightMargin: visible ? 1 : 0

    MouseArea {
        id: modMouseArea
        anchors.fill: parent
        enabled: modRoot.interactive && (modRoot.clickable || modRoot.wheelEnabled || modRoot.hoverEnabled)
        cursorShape: (modRoot.interactive && modRoot.clickable) ? Qt.PointingHandCursor : Qt.ArrowCursor
        hoverEnabled: modRoot.hoverEnabled
        acceptedButtons: (modRoot.interactive && modRoot.clickable)
            ? (Qt.LeftButton | Qt.RightButton | Qt.MiddleButton)
            : Qt.NoButton

        property int scrollAccumulator: 0

        onClicked: mouse => {
            if (!modRoot.clickable) return;
            if (mouse.button === Qt.LeftButton) modRoot.clicked();
            else if (mouse.button === Qt.RightButton) modRoot.rightClicked();
            else if (mouse.button === Qt.MiddleButton) modRoot.middleClicked();
        }

        onWheel: wheel => {
            if (!modRoot.wheelEnabled) {
                wheel.accepted = false;
                return;
            }
            let dy = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x;
            scrollAccumulator += dy;
            while (Math.abs(scrollAccumulator) >= 120) {
                let step = scrollAccumulator > 0 ? 1 : -1;
                modRoot.wheelMoved(step);
                scrollAccumulator -= (step * 120);
            }
            wheel.accepted = true;
        }
    }

    RowLayout {
        id: contentLayout
        anchors.centerIn: parent
        spacing: Metrics.scaled(Metrics.baseSpacing, modRoot.scaleFactor)
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
