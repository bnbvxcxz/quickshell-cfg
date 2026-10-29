// Scrollable notification center history list.
// Displays queued notifications with action triggers, accordion tree expansion, and dismissals.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"

Item {
    id: notifRoot

    property var model: null
    property real scaleFactor: 1.0
    property bool isExpanded: false

    signal scrollExpandRequested()
    signal scrollCollapseRequested()

    readonly property bool isAtTop: notifListView.contentY <= 0

    ColumnLayout {
        anchors.fill: parent
        spacing: Math.round(6 * notifRoot.scaleFactor)

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Math.round(4 * notifRoot.scaleFactor)
            Layout.rightMargin: Math.round(4 * notifRoot.scaleFactor)
            Layout.topMargin: Math.round(2 * notifRoot.scaleFactor)
            Layout.bottomMargin: Math.round(2 * notifRoot.scaleFactor)

            Text {
                text: "Notifications"
                color: Theme.on_surface
                font.family: Typography.family
                font.pixelSize: Typography.size(notifRoot.scaleFactor) + 1
                font.bold: Typography.globalBold
                font.weight: Typography.globalWeight
                font.italic: Typography.globalItalic
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: clearText.implicitWidth + Math.round(16 * notifRoot.scaleFactor)
                implicitHeight: Math.round(22 * notifRoot.scaleFactor)
                radius: Math.round(6 * notifRoot.scaleFactor)
                color: clearMouse.containsMouse ? Theme.surface_container_highest : Qt.alpha(Theme.surface_container_high, 0.6)
                border.color: Qt.alpha(Theme.outline_variant, 0.5)
                border.width: 1
                visible: notifRoot.model && notifRoot.model.count > 0

                Text {
                    id: clearText
                    anchors.centerIn: parent
                    text: "Clear All"
                    color: Theme.primary
                    font.family: Typography.family
                    font.pixelSize: Typography.sizeSmall(notifRoot.scaleFactor)
                    font.bold: Typography.globalBold
                    font.weight: Typography.globalWeight
                    font.italic: Typography.globalItalic
                }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (notifRoot.model) notifRoot.model.clear()
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
                font.pixelSize: Typography.size(notifRoot.scaleFactor)
                font.bold: Typography.globalBold
                font.weight: Typography.globalWeight
                font.italic: Typography.globalItalic
                visible: !notifRoot.model || notifRoot.model.count === 0
            }

            ListView {
                id: notifListView
                anchors.fill: parent
                clip: true
                spacing: Math.round(6 * notifRoot.scaleFactor)
                model: notifRoot.model
                boundsBehavior: Flickable.StopAtBounds

                property real scrollAccumulator: 0

                Timer {
                    id: momentumDecay
                    interval: 60
                    running: Math.abs(notifListView.scrollAccumulator) > 0
                    repeat: true
                    onTriggered: {
                        notifListView.scrollAccumulator *= 0.5;
                        if (Math.abs(notifListView.scrollAccumulator) < 15) {
                            notifListView.scrollAccumulator = 0;
                        }
                    }
                }

                WheelHandler {
                    target: notifListView
                    onWheel: event => {
                        let dy = event.angleDelta.y;

                        if (!notifRoot.isExpanded && dy < 0) {
                            notifListView.scrollAccumulator += Math.abs(dy);
                            if (notifListView.scrollAccumulator >= 360) {
                                notifRoot.scrollExpandRequested();
                                notifListView.scrollAccumulator = 0;
                            }
                            momentumDecay.restart();
                        } else if (notifRoot.isExpanded && dy > 0 && notifRoot.isAtTop) {
                            notifListView.scrollAccumulator += dy;
                            if (notifListView.scrollAccumulator >= 760) {
                                notifRoot.scrollCollapseRequested();
                                notifListView.scrollAccumulator = 0;
                            }
                            momentumDecay.restart();
                        } else {
                            notifListView.scrollAccumulator = 0;
                        }
                    }
                }

                delegate: Rectangle {
                    id: card
                    required property var modelData
                    required property int index

                    property bool expanded: false

                    readonly property var treeItems: {
                        try {
                            return JSON.parse(card.modelData.historyTree || "[]");
                        } catch(e) {
                            return [];
                        }
                    }

                    width: notifListView.width
                    implicitHeight: cardContent.implicitHeight + Math.round(16 * notifRoot.scaleFactor)
                    radius: Theme.cornerRadius

                    color: Qt.alpha(Theme.surface_container, 0.65)
                    border.color: (card.modelData.urgency === "critical") ? Theme.error : Qt.alpha(Theme.outline_variant, 0.7)
                    border.width: 1

                    ColumnLayout {
                        id: cardContent
                        anchors.fill: parent
                        anchors.margins: Math.round(10 * notifRoot.scaleFactor)
                        spacing: Math.round(6 * notifRoot.scaleFactor)

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Math.round(8 * notifRoot.scaleFactor)

                            Text {
                                text: card.modelData.appName || "System"
                                color: Theme.secondary
                                font.family: Typography.family
                                font.pixelSize: Typography.sizeSmall(notifRoot.scaleFactor)
                                font.bold: Typography.globalBold
                                font.weight: Typography.globalWeight
                                font.italic: Typography.globalItalic
                            }

                            Rectangle {
                                visible: card.modelData.repeatCount > 1
                                implicitWidth: repeatText.implicitWidth + Math.round(10 * notifRoot.scaleFactor)
                                implicitHeight: Math.round(18 * notifRoot.scaleFactor)
                                radius: Math.round(9 * notifRoot.scaleFactor)
                                color: Qt.alpha(Theme.tertiary_container, 0.8)

                                Text {
                                    id: repeatText
                                    anchors.centerIn: parent
                                    text: `${card.modelData.repeatCount}`
                                    color: Theme.on_tertiary_container
                                    font.family: Typography.family
                                    font.pixelSize: Math.max(8, Typography.sizeSmall(notifRoot.scaleFactor) - 1)
                                    font.bold: Typography.globalBold
                                    font.weight: Typography.globalWeight
                                    font.italic: Typography.globalItalic
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: card.expanded = !card.expanded
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: card.expanded ? "󰅃" : "󰅀"
                                color: Theme.on_surface_variant
                                font.family: Typography.family
                                font.pixelSize: Typography.sizeSmall(notifRoot.scaleFactor)
                                font.bold: Typography.globalBold
                                font.weight: Typography.globalWeight
                                font.italic: Typography.globalItalic
                                visible: card.modelData.repeatCount > 1

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: card.expanded = !card.expanded
                                }
                            }

                            Rectangle {
                                implicitWidth: Math.round(20 * notifRoot.scaleFactor)
                                implicitHeight: Math.round(20 * notifRoot.scaleFactor)
                                radius: implicitWidth / 2
                                color: closeMouse.containsMouse ? Theme.error : Qt.alpha(Theme.surface_container_highest, 0.7)
                                border.color: Qt.alpha(Theme.outline_variant, 0.4)
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅖"
                                    color: closeMouse.containsMouse ? Theme.on_error : Theme.on_surface_variant
                                    font.family: Typography.family
                                    font.pixelSize: Math.round(11 * notifRoot.scaleFactor)
                                    font.bold: Typography.globalBold
                                    font.weight: Typography.globalWeight
                                    font.italic: Typography.globalItalic
                                }

                                MouseArea {
                                    id: closeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (notifRoot.model) notifRoot.model.remove(card.index)
                                }
                            }
                        }

                        Text {
                            text: card.modelData.summary || ""
                            color: Theme.primary
                            font.family: Typography.family
                            font.pixelSize: Typography.size(notifRoot.scaleFactor)
                            font.bold: Typography.globalBold
                            font.weight: Typography.globalWeight
                            font.italic: Typography.globalItalic
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: card.modelData.body || ""
                            color: Theme.on_surface_variant
                            font.family: Typography.family
                            font.pixelSize: Typography.sizeSmall(notifRoot.scaleFactor)
                            font.bold: Typography.globalBold
                            font.weight: Typography.globalWeight
                            font.italic: Typography.globalItalic
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            visible: !card.expanded && text.length > 0
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Math.round(6 * notifRoot.scaleFactor)
                            visible: card.expanded && card.treeItems.length > 0

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: Qt.alpha(Theme.outline_variant, 0.3)
                            }

                            Repeater {
                                model: card.treeItems

                                ColumnLayout {
                                    id: treeRow
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    spacing: 2

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: `• Message #${card.treeItems.length - treeRow.index}`
                                            color: Theme.tertiary
                                            font.family: Typography.family
                                            font.pixelSize: Math.max(8, Typography.sizeSmall(notifRoot.scaleFactor) - 1)
                                            font.bold: Typography.globalBold
                                            font.italic: Typography.globalItalic
                                        }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: treeRow.modelData.time || ""
                                            color: Theme.outline
                                            font.family: Typography.family
                                            font.pixelSize: Math.max(8, Typography.sizeSmall(notifRoot.scaleFactor) - 2)
                                        }
                                    }

                                    Text {
                                        text: treeRow.modelData.body || ""
                                        color: Theme.on_surface
                                        font.family: Typography.family
                                        font.pixelSize: Typography.sizeSmall(notifRoot.scaleFactor)
                                        wrapMode: Text.Wrap
                                        Layout.fillWidth: true
                                        Layout.leftMargin: Math.round(8 * notifRoot.scaleFactor)
                                    }
                                }
                            }
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: Math.round(6 * notifRoot.scaleFactor)
                            visible: card.modelActions.length > 0

                            Repeater {
                                model: card.modelActions

                                Rectangle {
                                    implicitHeight: Math.round(26 * notifRoot.scaleFactor)
                                    implicitWidth: actText.implicitWidth + Math.round(18 * notifRoot.scaleFactor)
                                    radius: Math.round(13 * notifRoot.scaleFactor)
                                    color: actMouse.containsMouse ? Theme.primary : Qt.alpha(Theme.surface_container_highest, 0.8)
                                    border.color: actMouse.containsMouse ? Theme.primary : Qt.alpha(Theme.outline_variant, 0.4)
                                    border.width: 1

                                    Text {
                                        id: actText
                                        anchors.centerIn: parent
                                        text: modelData.text || "Action"
                                        color: actMouse.containsMouse ? Theme.on_primary : Theme.primary
                                        font.family: Typography.family
                                        font.pixelSize: Typography.sizeSmall(notifRoot.scaleFactor)
                                        font.bold: Typography.globalBold
                                        font.weight: Typography.globalWeight
                                        font.italic: Typography.globalItalic
                                    }

                                    MouseArea {
                                        id: actMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (modelData.actionObj && modelData.actionObj.invoke) {
                                                modelData.actionObj.invoke();
                                            }
                                            if (notifRoot.model) notifRoot.model.remove(card.index);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    readonly property var modelActions: {
                        if (!card.modelData.actions) return [];
                        if (Array.isArray(card.modelData.actions)) return card.modelData.actions;
                        let list = [];
                        for (let i = 0; i < card.modelData.actions.count; i++) {
                            list.push(card.modelData.actions.get(i));
                        }
                        return list;
                    }

                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.expanded = !card.expanded
                    }
                }
            }
        }
    }
}
