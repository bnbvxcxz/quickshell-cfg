// Status bar system tray container.
// Dynamically renders StatusNotifierItem icons with click activation and scale metrics.

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import "../../config"
import "../../components"

Pill {
    id: root

    visible: trayRepeater.count > 0
    Layout.preferredWidth: visible ? -1 : 0
    clip: true

    RowLayout {
        spacing: Metrics.scaled(Theme.baseSpacing, root.scaleFactor)

        Repeater {
            id: trayRepeater
            model: SystemTray.items.values

            Rectangle {
                id: itemContainer
                required property var modelData

                implicitHeight: root.implicitHeight - Metrics.scaled(4, root.scaleFactor)
                implicitWidth: implicitHeight
                radius: implicitHeight / 2

                color: itemMouse.containsMouse
                ? Qt.alpha(Theme.primary, 0.25)
                : Qt.alpha(Theme.surface_container_highest, 0.5)

                Behavior on color { ColorAnimation { duration: 100 } }

                Image {
                    anchors.centerIn: parent
                    width: Math.max(16, Math.round(root.implicitHeight - Metrics.scaled(6, root.scaleFactor)))
                    height: width
                    sourceSize: Qt.size(width * 2, width * 2)
                    source: parent.modelData.icon
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) itemContainer.modelData.activate();
                        else itemContainer.modelData.secondaryActivate();
                    }
                }
            }
        }
    }
}
