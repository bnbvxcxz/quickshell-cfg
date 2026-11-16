// Status bar system tray container.
// Renders StatusNotifierItem icons with click/wheel actions and a native Matugen DBus menu popup.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import "../../config"
import "../../components"
import "../../services"

BarModule {
    id: root

    property var barWindowRef: null
    interactive: false
    visible: trayRepeater.count > 0
    Layout.preferredWidth: visible ? -1 : 0
    clip: true

    property var activeItem: null
    property Item activeAnchor: null
    property bool menuOpen: false
    property double menuClosedAt: 0
    property var menuStack: ([])

    function toggleMenu(item, anchorItem) {
        if (root.menuOpen && root.activeItem === item) {
            root.menuOpen = false;
            Logger.debug("Tray", `Closed menu for ${item.id || "item"}`);
            return;
        }
        // PopupWindow grabFocus dismisses right before onClicked fires; keep closed on 2nd click.
        if (root.activeItem === item && (Date.now() - root.menuClosedAt) < 250) {
            Logger.debug("Tray", `Suppressed reopen after grab-dismiss for ${item.id || "item"}`);
            return;
        }
        root.activeItem = item;
        root.activeAnchor = anchorItem;
        root.menuStack = [];
        root.menuOpen = true;
        Logger.debug("Tray", `Opened menu for ${item.id || "item"}`);
    }

    function pushSubmenu(entry) {
        if (!entry || !entry.hasChildren) return;
        let next = root.menuStack.slice();
        next.push(entry);
        root.menuStack = next;
    }

    function popSubmenu() {
        if (root.menuStack.length === 0) return;
        let next = root.menuStack.slice();
        next.pop();
        root.menuStack = next;
    }

    QsMenuOpener {
        id: menuOpener
        menu: {
            if (root.menuStack.length > 0) return root.menuStack[root.menuStack.length - 1];
            return (root.activeItem && root.activeItem.hasMenu) ? root.activeItem.menu : null;
        }
    }

    // Overlay backdrop keeps the menu popup above Overlay-layer drawers and catches outside clicks.
    PanelWindow {
        id: trayBackdrop
        visible: root.menuOpen && root.barWindowRef !== null && root.activeAnchor !== null && menuOpener.children.values.length > 0
        screen: root.barWindowRef ? root.barWindowRef.screen : null
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-tray-backdrop"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: {
                Logger.debug("Tray", "Backdrop click -> close menu");
                root.menuOpen = false;
            }
        }
    }

    PopupWindow {
        id: trayMenuPopup
        visible: trayBackdrop.visible
        anchor.window: trayBackdrop
        anchor.rect: {
            if (!root.barWindowRef || !root.activeAnchor) return Qt.rect(0, 0, 1, 1);
            let pt = root.barWindowRef.contentItem.mapFromItem(root.activeAnchor, 0, 0);
            return Qt.rect(Math.round(pt.x), Math.round(pt.y), Math.round(root.activeAnchor.width), Math.round(root.activeAnchor.height));
        }
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Right
        anchor.adjustment: PopupAdjustment.Slide
        grabFocus: true
        color: "transparent"

        onVisibleChanged: {
            if (!visible) {
                root.menuOpen = false;
                root.menuStack = [];
                root.menuClosedAt = Date.now();
            }
        }

        readonly property real s: root.scaleFactor
        implicitWidth: Math.max(Math.round(160 * s), Math.min(Math.round(280 * s), menuCol.implicitWidth + Math.round(12 * s)))
        implicitHeight: menuCol.implicitHeight + Math.round(10 * s)

        Rectangle {
            anchors.fill: parent
            radius: Metrics.cornerRadius
            color: Qt.alpha(Theme.surface, Metrics.toastOpacity)
            border.color: Qt.alpha(Theme.outline_variant, Metrics.subtleOutlineOpacity)
            border.width: 1

            ColumnLayout {
                id: menuCol
                anchors.fill: parent
                anchors.margins: Math.round(5 * trayMenuPopup.s)
                spacing: Math.max(1, Math.round(1 * trayMenuPopup.s))

                Rectangle {
                    visible: root.menuStack.length > 0
                    Layout.fillWidth: true
                    implicitHeight: Math.round(22 * trayMenuPopup.s)
                    radius: Math.round(6 * trayMenuPopup.s)
                    color: backMouse.containsMouse ? Qt.alpha(Theme.primary, Metrics.trayHoverOpacity) : "transparent"

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: Math.round(8 * trayMenuPopup.s)
                        anchors.rightMargin: Math.round(8 * trayMenuPopup.s)
                        text: "󰅁  Back"
                        color: Theme.primary
                        font.family: Typography.family
                        font.pixelSize: Typography.sizeSmall(trayMenuPopup.s)
                        font.bold: Typography.globalBold
                        font.weight: Typography.weightMedium
                        font.italic: Typography.globalItalic
                    }

                    MouseArea {
                        id: backMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.popSubmenu()
                    }
                }

                Repeater {
                    model: menuOpener.children

                    Item {
                        id: entryRow
                        required property QsMenuEntry modelData
                        Layout.fillWidth: true
                        implicitHeight: modelData.isSeparator ? Math.round(5 * trayMenuPopup.s) : Math.round(22 * trayMenuPopup.s)
                        implicitWidth: modelData.isSeparator ? 80 : (entryContent.implicitWidth + Math.round(16 * trayMenuPopup.s))

                        Rectangle {
                            visible: entryRow.modelData.isSeparator
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: Qt.alpha(Theme.outline_variant, Metrics.subtleOutlineOpacity)
                        }

                        Rectangle {
                            visible: !entryRow.modelData.isSeparator
                            anchors.fill: parent
                            radius: Math.round(6 * trayMenuPopup.s)
                            color: entryMouse.containsMouse && entryRow.modelData.enabled ? Qt.alpha(Theme.primary, Metrics.trayHoverOpacity) : "transparent"

                            RowLayout {
                                id: entryContent
                                anchors.fill: parent
                                anchors.leftMargin: Math.round(8 * trayMenuPopup.s)
                                anchors.rightMargin: Math.round(8 * trayMenuPopup.s)
                                spacing: Math.round(6 * trayMenuPopup.s)

                                Text {
                                    visible: entryRow.modelData.buttonType !== QsMenuButtonType.None
                                    text: {
                                        if (entryRow.modelData.buttonType === QsMenuButtonType.RadioButton) {
                                            return entryRow.modelData.checkState === Qt.Checked ? "󰄯" : "󰄰";
                                        }
                                        return entryRow.modelData.checkState === Qt.Checked ? "󰄬" : " ";
                                    }
                                    color: entryRow.modelData.enabled ? Theme.primary : Theme.outline
                                    font.family: Typography.family
                                    font.pixelSize: Typography.sizeSmall(trayMenuPopup.s)
                                }

                                Text {
                                    id: entryLabel
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    text: entryRow.modelData.text || ""
                                    elide: Text.ElideRight
                                    color: entryRow.modelData.enabled ? Theme.on_surface : Theme.outline
                                    font.family: Typography.family
                                    font.pixelSize: Typography.sizeSmall(trayMenuPopup.s)
                                    font.bold: Typography.globalBold
                                    font.weight: Typography.globalWeight
                                    font.italic: Typography.globalItalic
                                }

                                Text {
                                    visible: !!entryRow.modelData.hasChildren
                                    text: "󰅂"
                                    color: entryRow.modelData.enabled ? Theme.on_surface_variant : Theme.outline
                                    font.family: Typography.family
                                    font.pixelSize: Typography.sizeSmall(trayMenuPopup.s)
                                }
                            }

                            MouseArea {
                                id: entryMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: entryRow.modelData.enabled
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    if (entryRow.modelData.hasChildren) {
                                        Logger.debug("Tray", `Open submenu: ${entryRow.modelData.text}`);
                                        root.pushSubmenu(entryRow.modelData);
                                        return;
                                    }
                                    Logger.debug("Tray", `Menu item triggered: ${entryRow.modelData.text}`);
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
        spacing: Metrics.scaled(Metrics.baseSpacing, root.scaleFactor)

        Repeater {
            id: trayRepeater
            model: SystemTray.items.values

            Rectangle {
                id: itemContainer
                required property var modelData

                implicitHeight: root.implicitHeight - Metrics.scaled(4, root.scaleFactor)
                implicitWidth: implicitHeight
                radius: Metrics.moduleRadius < 0 ? Math.round(implicitHeight / 2) : Math.max(2, Metrics.scaled(Metrics.moduleRadius, root.scaleFactor) - 2)

                color: itemMouse.containsMouse ? Qt.alpha(Theme.primary, Metrics.trayHoverOpacity) : Qt.alpha(Theme.surface_container_highest, Metrics.trayItemOpacity)
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
                            else { Logger.debug("Tray", `Left click activate: ${item.id || "item"}`); item.activate(); }
                        } else if (mouse.button === Qt.RightButton) {
                            if (canMenu) root.toggleMenu(item, itemContainer);
                            else { Logger.debug("Tray", `Right click secondaryActivate: ${item.id || "item"}`); item.secondaryActivate(); }
                        } else if (mouse.button === Qt.MiddleButton) {
                            Logger.debug("Tray", `Middle click secondaryActivate: ${item.id || "item"}`);
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
