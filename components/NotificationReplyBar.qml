// Inline reply input bar for notifications with hasInlineReply.
// Submits text on Enter or send button click and exposes active focus state.

import QtQuick
import QtQuick.Layouts
import "../config"

RowLayout {
    id: root

    property string placeholder: "Reply..."
    property real scaleFactor: 1.0
    readonly property bool inputFocused: replyInput.activeFocus

    signal replySent(string text)

    function clear() {
        replyInput.text = "";
    }

    function submit() {
        let txt = replyInput.text.trim();
        if (!txt) return;
        replyInput.text = "";
        root.replySent(txt);
    }

    Layout.fillWidth: true
    spacing: Math.round(6 * scaleFactor)

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.round(28 * root.scaleFactor)
        radius: Math.max(4, Metrics.cornerRadius - 4)
        color: Qt.alpha(Theme.surface_container_lowest, 0.8)
        border.color: replyInput.activeFocus ? Theme.primary : Qt.alpha(Theme.outline_variant, Metrics.subtleOutlineOpacity)
        border.width: 1
        clip: true

        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Math.round(8 * root.scaleFactor)
            anchors.rightMargin: Math.round(8 * root.scaleFactor)
            text: root.placeholder || "Reply..."
            color: Theme.outline
            font.family: Typography.family
            font.pixelSize: Typography.sizeSmall(root.scaleFactor)
            elide: Text.ElideRight
            visible: replyInput.text.length === 0
        }

        TextInput {
            id: replyInput
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Math.round(8 * root.scaleFactor)
            anchors.rightMargin: Math.round(8 * root.scaleFactor)
            color: Theme.on_surface
            selectionColor: Theme.primary
            selectedTextColor: Theme.on_primary
            font.family: Typography.family
            font.pixelSize: Typography.sizeSmall(root.scaleFactor)
            clip: true
            onAccepted: root.submit()
        }
    }

    Rectangle {
        readonly property int btnH: Math.round(28 * root.scaleFactor)
        implicitWidth: sendTxt.implicitWidth + Math.round(14 * root.scaleFactor)
        implicitHeight: btnH
        radius: Math.max(4, Metrics.cornerRadius - 4)
        color: sendMouse.containsMouse ? Theme.primary : Qt.alpha(Theme.primary_container, 0.85)

        Text {
            id: sendTxt
            anchors.centerIn: parent
            text: "󰒊"
            color: sendMouse.containsMouse ? Theme.on_primary : Theme.on_primary_container
            font.family: Typography.family
            font.pixelSize: Typography.sizeSmall(root.scaleFactor)
            font.bold: Typography.globalBold
        }

        MouseArea {
            id: sendMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.submit()
        }
    }
}
