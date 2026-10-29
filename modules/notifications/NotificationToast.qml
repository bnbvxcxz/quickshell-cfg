// Desktop notification popup toast surface.
// Displays timed floating banners that pause while hovered and support wrapped action chips.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../config"
import "../../services"

PanelWindow {
    id: toastRoot

    property var model: null

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notif-toast"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    readonly property real s: Metrics.scaleFor(toastRoot.screen)

    anchors {
        top: true
        right: true
    }

    margins {
        top: Metrics.scaled(Theme.baseBarHeight, s) + Math.round(8 * s)
        right: Math.round(12 * s)
    }

    implicitWidth: Math.round(360 * s)
    implicitHeight: toastCol.implicitHeight
    color: "transparent"
    visible: toastRepeater.count > 0

    ColumnLayout {
        id: toastCol
        anchors.fill: parent
        spacing: Math.round(6 * toastRoot.s)

        Repeater {
            id: toastRepeater
            model: toastRoot.model

            Rectangle {
                id: toastCard
                required property var modelData
                required property int index

                Layout.fillWidth: true
                implicitHeight: toastContent.implicitHeight + Math.round(20 * toastRoot.s)
                radius: Theme.cornerRadius

                color: Qt.alpha(Theme.surface, 0.92)
                border.color: Theme.primary
                border.width: 1

                // Hover detector to keep toast alive while pointer is over it
                readonly property bool isHovered: toastCardMouse.containsMouse || toastCloseMouse.containsMouse

                MouseArea {
                    id: toastCardMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    z: -1

                    onClicked: {
                        if (typeof shellRoot !== "undefined") {
                            shellRoot.togglePanel();
                        }
                        if (toastRoot.model) toastRoot.model.remove(toastCard.index);
                    }
                }

                ColumnLayout {
                    id: toastContent
                    anchors.fill: parent
                    anchors.margins: Math.round(12 * toastRoot.s)
                    spacing: Math.round(8 * toastRoot.s)

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Math.round(8 * toastRoot.s)

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                spacing: 4

                                Text {
                                    text: (toastCard.modelData.appName ? (toastCard.modelData.appName + " •") : "System •")
                                    color: Theme.secondary
                                    font.family: Typography.family
                                    font.pixelSize: Typography.sizeSmall(toastRoot.s)
                                    font.bold: Typography.globalBold
                                    font.weight: Typography.globalWeight
                                    font.italic: Typography.globalItalic
                                }

                                Text {
                                    text: toastCard.modelData.summary || "Notification"
                                    color: Theme.primary
                                    font.family: Typography.family
                                    font.pixelSize: Typography.size(toastRoot.s) + 1
                                    font.bold: Typography.globalBold
                                    font.weight: Typography.globalWeight
                                    font.italic: Typography.globalItalic
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            Text {
                                text: toastCard.modelData.body || ""
                                color: Theme.on_surface_variant
                                font.family: Typography.family
                                font.pixelSize: Typography.size(toastRoot.s)
                                font.bold: Typography.globalBold
                                font.weight: Typography.globalWeight
                                font.italic: Typography.globalItalic
                                wrapMode: Text.Wrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                visible: text.length > 0
                            }
                        }

                        Rectangle {
                            implicitWidth: Math.round(22 * toastRoot.s)
                            implicitHeight: Math.round(22 * toastRoot.s)
                            radius: implicitWidth / 2
                            color: toastCloseMouse.containsMouse ? Theme.error : Qt.alpha(Theme.surface_container_highest, 0.7)
                            border.color: Qt.alpha(Theme.outline_variant, 0.4)
                            border.width: 1
                            Layout.alignment: Qt.AlignTop

                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"
                                color: toastCloseMouse.containsMouse ? Theme.on_error : Theme.on_surface_variant
                                font.family: Typography.family
                                font.pixelSize: Math.round(12 * toastRoot.s)
                                font.bold: Typography.globalBold
                                font.weight: Typography.globalWeight
                                font.italic: Typography.globalItalic
                            }

                            MouseArea {
                                id: toastCloseMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (toastRoot.model) toastRoot.model.remove(toastCard.index)
                            }
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: Math.round(6 * toastRoot.s)
                        visible: toastCard.toastActions.length > 0

                        Repeater {
                            model: toastCard.toastActions

                            Rectangle {
                                implicitHeight: Math.round(24 * toastRoot.s)
                                implicitWidth: toastActText.implicitWidth + Math.round(16 * toastRoot.s)
                                radius: Math.round(12 * toastRoot.s)
                                color: toastActMouse.containsMouse ? Theme.primary : Qt.alpha(Theme.surface_container_highest, 0.8)
                                border.color: toastActMouse.containsMouse ? Theme.primary : Qt.alpha(Theme.outline_variant, 0.4)
                                border.width: 1

                                Text {
                                    id: toastActText
                                    anchors.centerIn: parent
                                    text: modelData.text || "Action"
                                    color: toastActMouse.containsMouse ? Theme.on_primary : Theme.primary
                                    font.family: Typography.family
                                    font.pixelSize: Typography.sizeSmall(toastRoot.s)
                                    font.bold: Typography.globalBold
                                    font.weight: Typography.globalWeight
                                    font.italic: Typography.globalItalic
                                }

                                MouseArea {
                                    id: toastActMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.actionObj && modelData.actionObj.invoke) {
                                            modelData.actionObj.invoke();
                                        }
                                        if (toastRoot.model) toastRoot.model.remove(toastCard.index);
                                    }
                                }
                            }
                        }
                    }
                }

                readonly property var toastActions: {
                    if (!toastCard.modelData.actions) return [];
                    if (Array.isArray(toastCard.modelData.actions)) return toastCard.modelData.actions;
                    let list = [];
                    for (let i = 0; i < toastCard.modelData.actions.count; i++) {
                        list.push(toastCard.modelData.actions.get(i));
                    }
                    return list;
                }

                // Auto-dismiss countdown timer: pauses whenever hovered, restarts on exit
                Timer {
                    id: dismissTimer
                    interval: 6000
                    running: !toastCard.isHovered
                    repeat: false
                    onTriggered: {
                        if (!toastRoot.model) return;
                        for (let i = 0; i < toastRoot.model.count; i++) {
                            if (toastRoot.model.get(i).id === toastCard.modelData.id) {
                                toastRoot.model.remove(i);
                                break;
                            }
                        }
                    }
                }

                Connections {
                    target: toastCard
                    function onIsHoveredChanged() {
                        if (!toastCard.isHovered) {
                            dismissTimer.restart();
                        }
                    }
                }
            }
        }
    }
}
