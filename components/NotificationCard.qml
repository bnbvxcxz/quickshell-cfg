// Reusable notification card component for toasts and history list items.
// Composes swipe-to-dismiss, per-card hover, markup/images/progress, history tree, actions, and inline reply.

import QtQuick
import QtQuick.Layouts
import "../config"

Item {
    id: card

    required property var itemData
    property real scaleFactor: 1.0
    property bool isToast: false
    property bool expanded: false

    signal cardClicked()
    signal closeClicked()
    signal actionTriggered(string actionId)
    signal inlineReplySent(string text)

    property real swipeX: 0
    property real swipeStartX: 0
    property bool dismissing: false
    property int trackedId: -1

    readonly property bool hovered: cardHover.hovered || closeMouse.containsMouse || replyBar.inputFocused
    readonly property bool swiping: swipeDrag.active || dismissing
    readonly property bool replyFocused: replyBar.inputFocused

    onItemDataChanged: {
        let nid = (itemData && itemData.id !== undefined) ? Number(itemData.id) : -1;
        if (nid !== trackedId) {
            trackedId = nid;
            dismissing = false;
            swipeX = 0;
            if (replyBar) replyBar.clear();
        }
    }

    function finishSwipe() {
        let thresh = Math.max(60, card.width * 0.35);
        if (Math.abs(card.swipeX) >= thresh) {
            card.dismissing = true;
            swipeOutAnim.to = card.swipeX >= 0 ? (card.width + 24) : -(card.width + 24);
            swipeOutAnim.start();
            return;
        }
        card.swipeX = 0;
    }

    function formatMarkup(raw) {
        if (!raw) return "";
        let s = String(raw);
        s = s.replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, "");
        s = s.replace(/<span\b/gi, "<font").replace(/<\/span>/gi, "</font>");
        s = s.replace(/&(?!amp;|lt;|gt;|quot;|apos;|#)/g, "&amp;");
        s = s.replace(/\r?\n/g, "<br/>");
        return s;
    }

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

    implicitHeight: cardBody.implicitHeight

    Behavior on swipeX {
        enabled: !swipeDrag.active && !card.dismissing
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    NumberAnimation {
        id: swipeOutAnim
        target: card
        property: "swipeX"
        duration: 160
        easing.type: Easing.OutCubic
        onFinished: {
            if (card.dismissing) card.closeClicked();
        }
    }

    Rectangle {
        id: cardBody
        x: card.swipeX
        width: card.width
        height: implicitHeight
        implicitHeight: cardContent.implicitHeight + Math.round((card.isToast ? 20 : 16) * card.scaleFactor)
        radius: Metrics.cornerRadius
        opacity: Math.max(0.0, 1.0 - Math.min(0.9, Math.abs(card.swipeX) / Math.max(1, card.width * 0.85)))

        color: card.hovered
            ? (card.isToast ? Qt.alpha(Theme.surface_container, Metrics.toastOpacity) : Qt.alpha(Theme.surface_container_high, Metrics.cardOpacity))
            : (card.isToast ? Qt.alpha(Theme.surface, Metrics.toastOpacity) : Qt.alpha(Theme.surface_container, Metrics.cardOpacity))

        border.color: {
            if (card.itemData && card.itemData.urgency === "critical") return Theme.error;
            if (card.hovered || card.isToast) return Theme.primary;
            return Qt.alpha(Theme.outline_variant, 0.7);
        }
        border.width: 1

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        HoverHandler {
            id: cardHover
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        }

        DragHandler {
            id: swipeDrag
            target: null
            xAxis.enabled: true
            yAxis.enabled: false
            dragThreshold: 8
            onActiveChanged: {
                if (active) card.swipeStartX = card.swipeX;
                else card.finishSwipe();
            }
            onTranslationChanged: {
                if (active) card.swipeX = card.swipeStartX + translation.x;
            }
        }

        MouseArea {
            id: cardMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            z: -1

            onClicked: mouse => {
                if (card.swiping) return;
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
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Math.round((card.isToast ? 12 : 10) * card.scaleFactor)
            spacing: Math.round((card.isToast ? 8 : 6) * card.scaleFactor)

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(8 * card.scaleFactor)

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    Layout.preferredWidth: 0
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Math.round(6 * card.scaleFactor)

                        Image {
                            readonly property int icoDim: Math.round(14 * card.scaleFactor)
                            Layout.preferredWidth: icoDim
                            Layout.preferredHeight: icoDim
                            source: (card.itemData && card.itemData.appIcon) ? card.itemData.appIcon : ""
                            visible: source !== "" && status === Image.Ready
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            asynchronous: true
                        }

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
                            textFormat: Text.StyledText
                            color: Theme.primary
                            font.family: Typography.family
                            font.pixelSize: Typography.size(card.scaleFactor) + 1
                            font.bold: Typography.globalBold
                            font.weight: Typography.globalWeight
                            font.italic: Typography.globalItalic
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
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
                        visible: !card.isToast && text.length > 0
                        text: (card.itemData && card.itemData.summary) ? card.formatMarkup(card.itemData.summary) : ""
                        textFormat: Text.StyledText
                        color: Theme.primary
                        font.family: Typography.family
                        font.pixelSize: Typography.size(card.scaleFactor)
                        font.bold: Typography.globalBold
                        font.weight: Typography.globalWeight
                        font.italic: Typography.globalItalic
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        spacing: Math.round(8 * card.scaleFactor)
                        visible: !card.expanded && (bodyText.text.length > 0 || notifImg.visible)

                        Rectangle {
                            readonly property int imgDim: Math.round((card.isToast ? 44 : 38) * card.scaleFactor)
                            Layout.preferredWidth: imgDim
                            Layout.preferredHeight: imgDim
                            Layout.alignment: Qt.AlignTop
                            radius: Math.max(4, Metrics.cornerRadius - 4)
                            color: Theme.surface_container_highest
                            clip: true
                            visible: notifImg.visible

                            Image {
                                id: notifImg
                                anchors.fill: parent
                                source: (card.itemData && card.itemData.image) ? card.itemData.image : ""
                                visible: source !== "" && status === Image.Ready
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                                asynchronous: true
                            }
                        }

                        Text {
                            id: bodyText
                            text: (card.itemData && card.itemData.body) ? card.formatMarkup(card.itemData.body) : ""
                            textFormat: Text.StyledText
                            linkColor: Theme.primary
                            color: Theme.on_surface_variant
                            font.family: Typography.family
                            font.pixelSize: card.isToast ? Typography.size(card.scaleFactor) : Typography.sizeSmall(card.scaleFactor)
                            font.bold: Typography.globalBold
                            font.weight: Typography.globalWeight
                            font.italic: Typography.globalItalic
                            wrapMode: Text.Wrap
                            maximumLineCount: 4
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            visible: text.length > 0
                            onLinkActivated: link => Qt.openUrlExternally(link)
                        }
                    }
                }

                Rectangle {
                    readonly property int btnDim: Math.round((card.isToast ? 22 : 20) * card.scaleFactor)
                    Layout.preferredWidth: btnDim
                    Layout.preferredHeight: btnDim
                    Layout.minimumWidth: btnDim
                    implicitWidth: btnDim
                    implicitHeight: btnDim
                    radius: btnDim / 2
                    color: closeMouse.containsMouse ? Theme.error : Qt.alpha(Theme.surface_container_highest, 0.7)
                    border.color: Qt.alpha(Theme.outline_variant, Metrics.subtleOutlineOpacity)
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

            Rectangle {
                visible: card.itemData && card.itemData.progress !== undefined && card.itemData.progress >= 0
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(4, Math.round(5 * card.scaleFactor))
                radius: height / 2
                color: Qt.alpha(Theme.surface_container_highest, 0.8)

                Rectangle {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    width: parent.width * Math.max(0.0, Math.min(1.0, ((card.itemData && card.itemData.progress !== undefined) ? card.itemData.progress : 0) / 100.0))
                    radius: height / 2
                    color: Theme.primary
                    Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                }
            }

            NotificationHistoryTree {
                visible: !card.isToast && card.expanded && card.treeItems.length > 0
                treeItems: card.treeItems
                scaleFactor: card.scaleFactor
                formatMarkupFn: card.formatMarkup
            }

            NotificationActions {
                visible: card.actionItems.length > 0
                actionItems: card.actionItems
                scaleFactor: card.scaleFactor
                isToast: card.isToast
                onActionTriggered: actionId => card.actionTriggered(actionId)
            }

            NotificationReplyBar {
                id: replyBar
                visible: !!(card.itemData && card.itemData.hasInlineReply)
                placeholder: (card.itemData && card.itemData.inlineReplyPlaceholder) ? card.itemData.inlineReplyPlaceholder : "Reply..."
                scaleFactor: card.scaleFactor
                onReplySent: text => card.inlineReplySent(text)
            }
        }
    }
}
