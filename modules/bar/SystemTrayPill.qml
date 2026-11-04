// Status bar system tray container.
// Dynamically renders StatusNotifierItem icons with click activation, context menus, and scale metrics.

import QtQuick
import QtQuick.Layouts
import Quickshell
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

               // Native context menu popup anchor
                QsMenuAnchor {
                    id: menuAnchor
                    menu: itemContainer.modelData.hasMenu ? itemContainer.modelData.menu : null
                    anchor.item: itemContainer
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                    onClicked: mouse => {
                        // Left click ALWAYS activates (required for Discord and Electron apps)
                        if (mouse.button === Qt.LeftButton) {
                            itemContainer.modelData.activate();
                        } 
                        // Right click opens the DBus menu if it exists, otherwise falls back
                        else if (mouse.button === Qt.RightButton) {
                            if (itemContainer.modelData.hasMenu) {
                                menuAnchor.open();
                            } else {
                                itemContainer.modelData.secondaryActivate();
                            }
                        } 
                        // Middle click executes secondary action (e.g. mute toggle on audio apps)
                        else if (mouse.button === Qt.MiddleButton) {
                            itemContainer.modelData.secondaryActivate();
                        }
                    }

                    onWheel: wheel => {
                        let delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x;
                        itemContainer.modelData.scroll(delta, wheel.angleDelta.y === 0);
                    }
                }
            }
        }
    }
}