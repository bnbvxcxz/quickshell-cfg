// Desktop notification popup toast surface.
// Displays timed floating banners that pause on hover and invoke app focus or actions on click.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../config"
import "../../services"
import "../../components"

PanelWindow {
    id: root

    property var model: NotificationState.toastModel

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notif-toast"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    readonly property real s: Metrics.scaleFor(root.screen)

    anchors {
        top: true
        right: true
    }

    margins {
        top: Metrics.scaled(Theme.baseBarHeight, s) + Math.round(8 * s)
        right: Math.round(12 * s)
    }

    implicitWidth: Math.round(360 * s)
    implicitHeight: col.implicitHeight
    color: "transparent"
    visible: rep.count > 0

    ColumnLayout {
        id: col
        anchors.fill: parent
        spacing: Math.round(6 * root.s)

        Repeater {
            id: rep
            model: root.model

            NotificationCard {
                id: toastCard
                required property var modelData
                required property int index

                Layout.fillWidth: true
                itemData: modelData
                scaleFactor: root.s
                isToast: true

                onCardClicked: {
                    NotificationState.activateNotification(modelData.id, modelData.appName, modelData.desktopEntry);
                }

                onCloseClicked: {
                    NotificationState.dismissToast(modelData.id);
                }

                onActionTriggered: actionId => {
                    NotificationState.invokeAction(modelData.id, actionId);
                }

                Timer {
                    id: dismiss
                    interval: 6000
                    running: !toastCard.hovered
                    onTriggered: NotificationState.dismissToast(toastCard.modelData.id)
                }

                Connections {
                    target: toastCard
                    function onHoveredChanged() {
                        if (!toastCard.hovered) dismiss.restart();
                    }
                }
            }
        }
    }
}
