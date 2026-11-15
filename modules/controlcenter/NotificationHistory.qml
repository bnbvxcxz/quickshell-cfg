// Scrollable notification center history list.
// Renders grouped notification cards with action execution, inline replies, swipe-to-dismiss, and scroll gestures.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../components"

Item {
    id: root

    property var model: NotificationState.histModel
    property real scaleFactor: 1.0
    property bool isExpanded: false

    signal scrollExpandRequested()
    signal scrollCollapseRequested()

    property real wheelAcc: 0

    Timer {
        id: decay
        interval: 140
        running: Math.abs(root.wheelAcc) > 0
        repeat: true
        onTriggered: {
            root.wheelAcc *= 0.5;
            if (Math.abs(root.wheelAcc) < 15) root.wheelAcc = 0;
        }
    }

    onIsExpandedChanged: {
        if (!isExpanded) list.contentY = 0;
    }

    function handleWheel(e) {
        let dy = e.angleDelta.y !== 0 ? e.angleDelta.y : e.pixelDelta.y;
        if (dy === 0) {
            e.accepted = false;
            return;
        }

        // Scrolling down anywhere in the notification section enters compact mode.
        if (!root.isExpanded && dy < 0) {
            e.accepted = true;
            root.wheelAcc += Math.abs(dy);
            if (root.wheelAcc >= 100) {
                root.scrollExpandRequested();
                root.wheelAcc = 0;
            }
            decay.restart();
            return;
        }

        // Scrolling up while already at the top of the list exits compact mode.
        if (root.isExpanded && dy > 0 && list.contentY <= 1) {
            e.accepted = true;
            root.wheelAcc += dy;
            if (root.wheelAcc >= 100) {
                root.scrollCollapseRequested();
                root.wheelAcc = 0;
            }
            decay.restart();
            return;
        }

        if (root.isExpanded) {
            root.wheelAcc = 0;
            let maxY = Math.max(0, list.contentHeight - list.height);
            if (maxY > 0) {
                let deltaPx = e.pixelDelta.y !== 0 ? e.pixelDelta.y : (e.angleDelta.y * 0.55);
                list.contentY = Math.max(0, Math.min(maxY, list.contentY - deltaPx));
                e.accepted = true;
                return;
            }
        }

        root.wheelAcc = 0;
        e.accepted = false;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Math.round(6 * root.scaleFactor)

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Math.round(4 * root.scaleFactor)
            Layout.rightMargin: Math.round(4 * root.scaleFactor)
            Layout.topMargin: Math.round(2 * root.scaleFactor)
            Layout.bottomMargin: Math.round(2 * root.scaleFactor)

            Text {
                text: "Notifications"
                color: Theme.on_surface
                font.family: Typography.family
                font.pixelSize: Typography.size(root.scaleFactor) + 1
                font.bold: Typography.globalBold
                font.weight: Typography.globalWeight
                font.italic: Typography.globalItalic
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: clearText.implicitWidth + Math.round(16 * root.scaleFactor)
                implicitHeight: Math.round(22 * root.scaleFactor)
                radius: Math.round(6 * root.scaleFactor)
                color: clearMouse.containsMouse ? Theme.surface_container_highest : Qt.alpha(Theme.surface_container_high, 0.6)
                border.color: Qt.alpha(Theme.outline_variant, 0.5)
                border.width: 1
                visible: list.count > 0

                Text {
                    id: clearText
                    anchors.centerIn: parent
                    text: "Clear All"
                    color: Theme.primary
                    font.family: Typography.family
                    font.pixelSize: Typography.sizeSmall(root.scaleFactor)
                    font.bold: Typography.globalBold
                    font.weight: Typography.globalWeight
                    font.italic: Typography.globalItalic
                }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { Logger.debug("NotifHistory", "Clear All clicked"); NotificationState.clearHistory(); }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Text {
                anchors.centerIn: parent
                text: "No Notifications"
                color: Qt.alpha(Theme.outline, 0.6)
                font.family: Typography.family
                font.pixelSize: Typography.size(root.scaleFactor)
                font.bold: Typography.globalBold
                font.weight: Typography.globalWeight
                font.italic: Typography.globalItalic
                visible: list.count === 0
            }

            ListView {
                id: list
                anchors.fill: parent
                clip: true
                spacing: Math.round(6 * root.scaleFactor)
                model: root.model
                interactive: root.isExpanded
                boundsBehavior: Flickable.StopAtBounds

                WheelHandler {
                    target: null
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: e => root.handleWheel(e)
                }

                delegate: NotificationCard {
                    id: histCard
                    required property var modelData
                    required property int index

                    width: list.width
                    itemData: modelData
                    scaleFactor: root.scaleFactor
                    isToast: false

                    onCardClicked: {
                        Logger.debug("NotifHistory", `Clicked #${modelData.id} (${modelData.appName})`);
                        NotificationState.activateNotification(modelData.id, modelData.appName, modelData.desktopEntry);
                        if (modelData.repeatCount > 1) {
                            histCard.expanded = !histCard.expanded;
                        }
                    }

                    onCloseClicked: {
                        Logger.debug("NotifHistory", `Dismissed #${modelData.id}`);
                        NotificationState.dismissHistory(modelData.id);
                    }

                    onActionTriggered: actionId => {
                        Logger.debug("NotifHistory", `Action #${modelData.id}: ${actionId}`);
                        NotificationState.invokeAction(modelData.id, actionId);
                    }

                    onInlineReplySent: text => {
                        Logger.debug("NotifHistory", `Inline reply #${modelData.id}`);
                        NotificationState.sendInlineReply(modelData.id, text);
                    }
                }
            }
        }
    }
}
