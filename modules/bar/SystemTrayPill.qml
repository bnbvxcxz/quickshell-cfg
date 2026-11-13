// Status bar system tray container.
// Renders StatusNotifierItem icons with click/wheel actions and a native Matugen DBus menu popup.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import "../../config"
import "../../components"

Pill {
    id: root

    property var barWindowRef: null
    interactive: false
    visible: trayRepeater.count > 0
    Layout.preferredWidth: visible ? -1 : 0
    clip: true

    property var activeItem: null
    property Item activeAnchor: null
    property bool menuOpen: false

    function toggleMenu(item, anchorItem) {
        if (root.menuOpen && root.activeItem === item) {
            root.menuOpen = false;
            return;
        }
        root.activeItem = item;
        root.activeAnchor = anchorItem;
        root.menuOpen = true;
    }

    QsMenuOpener {
        id: menuOpener
        menu: (root.activeItem && root.activeItem.hasMenu) ? root.activeItem.menu : null
    }

    PopupWindow {
        id: trayMenuPopup
        visible: root.menuOpen && root.barWindowRef !== null && root.activeAnchor !== null && menuOpener.children.values.length > 0
        anchor.window: root.barWindowRef
        anchor.item: root.activeAnchor
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        grabFocus: true
        color: "transparent"

        onVisibleChanged: {
            if (!visible) root.menuOpen = false;
        }

        readonly property real s: root.scaleFactor
        implicitWidth: Math.max(Math.round(160 * s), Math.min(Math.round(280 * s), menuCol.implicitWidth + Math.round(16 * s)))
        implicitHeight: menuCol.implicitHeight + Math.round(12 * s)

        Rectangle {
            anchors.fill: parent
            radius: Theme.cornerRadius
            color: Qt.alpha(Theme.surface, Theme.toastOpacity)
            border.color: Qt.alpha(Theme.outline_variant, Theme.subtleOutlineOpacity)
            border.width: 1

            ColumnLayout {
                id: menuCol
                anchors.fill: parent
                anchors.margins: Math.round(6 * trayMenuPopup.s)
                spacing: Math.round(2 * trayMenuPopup.s)

                Repeater {
                    model: menuOpener.children

                    Item {
                        id: entryRow
                        required property QsMenuEntry modelData
                        Layout.fillWidth: true
                        implicitHeight: modelData.isSeparator ? Math.round(7 * trayMenuPopup.s) : Math.round(26 * trayMenuPopup.s)
                        implicitWidth: modelData.isSeparator ? 80 : (entryLabel.implicitWidth + Math.round(28 * trayMenuPopup.s))

                        Rectangle {
                            visible: entryRow.modelData.isSeparator
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: Qt.alpha(Theme.outline_variant, Theme.subtleOutlineOpacity)
                        }

                        Rectangle {
                            visible: !entryRow.modelData.isSeparator
                            anchors.fill: parent
                            radius: Math.round(6 * trayMenuPopup.s)
                            color: entryMouse.containsMouse && entryRow.modelData.enabled ? Qt.alpha(Theme.primary, Theme.trayHoverOpacity) : "transparent"

                            Text {
                                id: entryLabel
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: Math.round(8 * trayMenuPopup.s)
                                anchors.rightMargin: Math.round(8 * trayMenuPopup.s)
                                text: entryRow.modelData.text || ""
                                elide: Text.ElideRight
                                color: entryRow.modelData.enabled ? Theme.on_surface : Theme.outline
                                font.family: Typography.family
                                font.pixelSize: Typography.sizeSmall(trayMenuPopup.s)
                                font.bold: Typography.globalBold
                                font.weight: Typography.globalWeight
                                font.italic: Typography.globalItalic
                            }

                            MouseArea {
                                id: entryMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: entryRow.modelData.enabled
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    entryRow.modelData.triggered();
                                    root.menuOpen = false;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

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
                radius: Theme.pillRadius < 0 ? Math.round(implicitHeight / 2) : Math.max(2, Metrics.scaled(Theme.pillRadius, root.scaleFactor) - 2)

                color: itemMouse.containsMouse ? Qt.alpha(Theme.primary, Theme.trayHoverOpacity) : Qt.alpha(Theme.surface_container_highest, Theme.trayItemOpacity)
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
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                    onClicked: mouse => {
                        let item = itemContainer.modelData;
                        let canMenu = !!(item.hasMenu && item.menu);

                        if (mouse.button === Qt.LeftButton) {
                            if (item.onlyMenu && canMenu) root.toggleMenu(item, itemContainer);
                            else item.activate();
                        } else if (mouse.button === Qt.RightButton) {
                            if (canMenu) root.toggleMenu(item, itemContainer);
                            else item.secondaryActivate();
                        } else if (mouse.button === Qt.MiddleButton) {
                            item.secondaryActivate();
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
