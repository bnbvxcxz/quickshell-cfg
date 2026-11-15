// Desktop notification popup toast surface.
// Displays timed floating banners that pause per-card on hover, support inline replies, and swipe away individually.

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
    WlrLayershell.keyboardFocus: NotificationState.hasToastInlineReply ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    readonly property real s: Metrics.scaleFor(root.screen)

    anchors {
        top: true
        right: true
    }

    margins {
        top: Metrics.scaled(Metrics.baseBarHeight, s) + Math.round(8 * s)
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

                readonly property bool autoDismiss: modelData.expireTimeout !== 0
                readonly property int timeoutMs: (modelData.expireTimeout !== undefined && modelData.expireTimeout > 0)
                    ? Math.round(modelData.expireTimeout * 1000)
                    : 6000
                readonly property bool paused: toastCard.hovered || toastCard.swiping || toastCard.replyFocused

                Layout.fillWidth: true
                itemData: modelData
                scaleFactor: root.s
                isToast: true

                onCardClicked: {
                    Logger.debug("NotifToast", `Clicked #${modelData.id} (${modelData.appName})`);
                    NotificationState.activateNotification(modelData.id, modelData.appName, modelData.desktopEntry);
                }

                onCloseClicked: {
                    Logger.debug("NotifToast", `Dismissed #${modelData.id}`);
                    NotificationState.dismissToast(modelData.id);
                }

                onActionTriggered: actionId => {
                    Logger.debug("NotifToast", `Action #${modelData.id}: ${actionId}`);
                    NotificationState.invokeAction(modelData.id, actionId);
                }

                onInlineReplySent: text => {
                    Logger.debug("NotifToast", `Inline reply #${modelData.id}`);
                    NotificationState.sendInlineReply(modelData.id, text);
                }

                Timer {
                    id: dismiss
                    interval: toastCard.timeoutMs
                    running: toastCard.autoDismiss && !toastCard.paused
                    onTriggered: { Logger.debug("NotifToast", `Timeout #${toastCard.modelData.id}`); NotificationState.dismissToast(toastCard.modelData.id); }
                }

                onPausedChanged: {
                    if (!paused && autoDismiss) dismiss.restart();
                }
            }
        }
    }
}
