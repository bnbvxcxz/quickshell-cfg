// Reusable notification card component for toasts and history list items.
// Supports grouped message accordion trees, action chips, and click-to-focus activation.

import QtQuick
import QtQuick.Layouts
import "../config"

Rectangle {
    id: card

    required property var itemData
    property real scaleFactor: 1.0
    property bool isToast: false
    property bool expanded: false

    signal cardClicked()
    signal closeClicked()
    signal actionTriggered(string actionId)

    HoverHandler { id: cardHover }
    readonly property bool hovered: cardHover.hovered || cardMouse.containsMouse || closeMouse.containsMouse

    readonly property var treeItems: {
        if (!itemData || !itemData.historyTree) return [];
        try { return JSON.parse(itemData.historyTree); }
        catch(e) { return []; }
    }

    readonly property var actionItems: {
        if (!itemData) return [];
        if (itemData.actionsJson) {
            try { return JSON.parse(itemData.actionsJson); }
            catch(e) { return []; }
        }
        let a = itemData.actions;
        if (!a) return [];
        if (Array.isArray(a)) return a;

        let res = [];
        for (let i = 0; i < (a.count || 0); i++) res.push(a.get(i));
        return res;
    }

    implicitHeight: cardContent.implicitHeight + Math.round((isToast ? 20 : 16) * scaleFactor)
    radius: Theme.cornerRadius

    color: isToast ? Qt.alpha(Theme.surface, Theme.toastOpacity) : Qt.alpha(Theme.surface_container, Theme.cardOpacity)
    border.color: (itemData && itemData.urgency === "critical")
        ? Theme.error
        : (isToast ? Theme.primary : Qt.alpha(Theme.outline_variant, 0.7))
    border.width: 1

    MouseArea {
        id: cardMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        z: -1

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                if (!card.isToast && card.itemData && card.itemData.repeatCount > 1) {
                    card.expanded = !card.expanded;
                    return;
                }
                card.closeClicked();
                return;
            }
            card.cardClicked();
        }
    }

    ColumnLayout {
        id: cardContent
        anchors.fill: parent
        anchors.margins: Math.round((card.isToast ? 12 : 10) * card.scaleFactor)
        spacing: Math.round((card.isToast ? 8 : 6) * card.scaleFactor)

        RowLayout {
            Layout.fillWidth: true
            spacing: Math.round(8 * card.scaleFactor)

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Math.round(6 * card.scaleFactor)

                    Text {
                        text: card.itemData && card.itemData.appName
                            ? (card.isToast ? (card.itemData.appName + " •") : card.itemData.appName)
                            : (card.isToast ? "System •" : "System")
                        color: Theme.secondary
                        font.family: Typography.family
                        font.pixelSize: Typography.sizeSmall(card.scaleFactor)
                        font.bold: Typography.globalBold
                        font.weight: Typography.globalWeight
                        font.italic: Typography.globalItalic
                    }

                    Text {
                        visible: card.isToast
                        text: (card.itemData && card.itemData.summary) ? card.itemData.summary : "Notification"
                        color: Theme.primary
                        font.family: Typography.family
                        font.pixelSize: Typography.size(card.scaleFactor) + 1
                        font.bold: Typography.globalBold
                        font.weight: Typography.globalWeight
                        font.italic: Typography.globalItalic
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        visible: !card.isToast && card.itemData && card.itemData.repeatCount > 1
                        implicitWidth: repeatTxt.implicitWidth + Math.round(10 * card.scaleFactor)
                        implicitHeight: Math.round(18 * card.scaleFactor)
                        radius: Math.round(9 * card.scaleFactor)
                        color: Qt.alpha(Theme.tertiary_container, 0.8)

                        Text {
                            id: repeatTxt
                            anchors.centerIn: parent
                            text: card.itemData ? `${card.itemData.repeatCount}` : "1"
                            color: Theme.on_tertiary_container
                            font.family: Typography.family
                            font.pixelSize: Math.max(8, Typography.sizeSmall(card.scaleFactor) - 1)
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

                    Item {
                        visible: !card.isToast
                        Layout.fillWidth: true
                    }

                    Text {
                        visible: !card.isToast && card.itemData && card.itemData.repeatCount > 1
                        text: card.expanded ? "󰅃" : "󰅀"
                        color: Theme.on_surface_variant
                        font.family: Typography.family
                        font.pixelSize: Typography.sizeSmall(card.scaleFactor)
                        font.bold: Typography.globalBold
                        font.weight: Typography.globalWeight
                        font.italic: Typography.globalItalic

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: card.expanded = !card.expanded
                        }
                    }
                }

                Text {
                    visible: !card.isToast
                    text: (card.itemData && card.itemData.summary) ? card.itemData.summary : ""
                    color: Theme.primary
                    font.family: Typography.family
                    font.pixelSize: Typography.size(card.scaleFactor)
                    font.bold: Typography.globalBold
                    font.weight: Typography.globalWeight
                    font.italic: Typography.globalItalic
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: (card.itemData && card.itemData.body) ? card.itemData.body : ""
                    color: Theme.on_surface_variant
                    font.family: Typography.family
                    font.pixelSize: card.isToast ? Typography.size(card.scaleFactor) : Typography.sizeSmall(card.scaleFactor)
                    font.bold: Typography.globalBold
                    font.weight: Typography.globalWeight
                    font.italic: Typography.globalItalic
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    visible: !card.expanded && text.length > 0
                }
            }

            Rectangle {
                readonly property int btnDim: Math.round((card.isToast ? 22 : 20) * card.scaleFactor)
                implicitWidth: btnDim
                implicitHeight: btnDim
                radius: btnDim / 2
                color: closeMouse.containsMouse ? Theme.error : Qt.alpha(Theme.surface_container_highest, 0.7)
                border.color: Qt.alpha(Theme.outline_variant, Theme.subtleOutlineOpacity)
                border.width: 1
                Layout.alignment: Qt.AlignTop

                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    color: closeMouse.containsMouse ? Theme.on_error : Theme.on_surface_variant
                    font.family: Typography.family
                    font.pixelSize: Math.round((card.isToast ? 12 : 11) * card.scaleFactor)
                    font.bold: Typography.globalBold
                    font.weight: Typography.globalWeight
                    font.italic: Typography.globalItalic
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.closeClicked()
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Math.round(6 * card.scaleFactor)
            visible: !card.isToast && card.expanded && card.treeItems.length > 0

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
                            font.pixelSize: Math.max(8, Typography.sizeSmall(card.scaleFactor) - 1)
                            font.bold: Typography.globalBold
                            font.italic: Typography.globalItalic
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: treeRow.modelData.time || ""
                            color: Theme.outline
                            font.family: Typography.family
                            font.pixelSize: Math.max(8, Typography.sizeSmall(card.scaleFactor) - 2)
                        }
                    }

                    Text {
                        text: treeRow.modelData.body || ""
                        color: Theme.on_surface
                        font.family: Typography.family
                        font.pixelSize: Typography.sizeSmall(card.scaleFactor)
                        textFormat: Text.PlainText
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                        Layout.leftMargin: Math.round(8 * card.scaleFactor)
                    }
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: Math.round(6 * card.scaleFactor)
            visible: card.actionItems.length > 0

            Repeater {
                model: card.actionItems

                Rectangle {
                    required property var modelData
                    readonly property int chipH: Math.round((card.isToast ? 24 : 26) * card.scaleFactor)
                    implicitHeight: chipH
                    implicitWidth: actTxt.implicitWidth + Math.round((card.isToast ? 16 : 18) * card.scaleFactor)
                    radius: Math.round(chipH / 2)
                    color: actMouse.containsMouse ? Theme.primary : Qt.alpha(Theme.surface_container_highest, Theme.chipOpacity)
                    border.color: actMouse.containsMouse ? Theme.primary : Qt.alpha(Theme.outline_variant, Theme.subtleOutlineOpacity)
                    border.width: 1

                    Text {
                        id: actTxt
                        anchors.centerIn: parent
                        text: modelData.text || "Action"
                        color: actMouse.containsMouse ? Theme.on_primary : Theme.primary
                        font.family: Typography.family
                        font.pixelSize: Typography.sizeSmall(card.scaleFactor)
                        font.bold: Typography.globalBold
                        font.weight: Typography.globalWeight
                        font.italic: Typography.globalItalic
                    }

                    MouseArea {
                        id: actMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.actionTriggered(modelData.actionId || "")
                    }
                }
            }
        }
    }
}
