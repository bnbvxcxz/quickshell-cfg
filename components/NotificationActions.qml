// Notification action button grid (2 per row, 50/50 split).
// Supports optional action icons and elides long button labels cleanly.

import QtQuick
import QtQuick.Layouts
import "../config"

ColumnLayout {
    id: root

    property var actionItems: ([])
    property real scaleFactor: 1.0
    property bool isToast: false

    signal actionTriggered(string actionId)

    readonly property var actionRows: {
        let items = root.actionItems;
        if (!items || items.length === 0) return [];
        let rows = [];
        for (let i = 0; i < items.length; i += 2) {
            rows.push(items.slice(i, i + 2));
        }
        return rows;
    }

    Layout.fillWidth: true
    spacing: Math.round(6 * scaleFactor)

    Repeater {
        model: root.actionRows

        RowLayout {
            id: actRowWrap
            required property var modelData
            Layout.fillWidth: true
            spacing: Math.round(6 * root.scaleFactor)

            Repeater {
                model: actRowWrap.modelData

                Rectangle {
                    id: actChip
                    required property var modelData
                    readonly property int chipH: Math.round((root.isToast ? 24 : 26) * root.scaleFactor)

                    Layout.preferredHeight: chipH
                    Layout.preferredWidth: 0
                    Layout.fillWidth: true
                    clip: true
                    radius: Math.round(chipH / 2)
                    color: actMouse.containsMouse ? Theme.primary : Qt.alpha(Theme.surface_container_highest, Metrics.chipOpacity)
                    border.color: actMouse.containsMouse ? Theme.primary : Qt.alpha(Theme.outline_variant, Metrics.subtleOutlineOpacity)
                    border.width: 1

                    RowLayout {
                        id: actRow
                        anchors.centerIn: parent
                        spacing: Math.round(4 * root.scaleFactor)

                        Image {
                            readonly property int icoDim: Math.round(12 * root.scaleFactor)
                            Layout.preferredWidth: icoDim
                            Layout.preferredHeight: icoDim
                            source: modelData.icon || ""
                            visible: source !== "" && status === Image.Ready
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }

                        Text {
                            text: modelData.text || "Action"
                            elide: Text.ElideRight
                            Layout.maximumWidth: Math.max(24, actChip.width - Math.round(16 * root.scaleFactor))
                            color: actMouse.containsMouse ? Theme.on_primary : Theme.primary
                            font.family: Typography.family
                            font.pixelSize: Typography.sizeSmall(root.scaleFactor)
                            font.bold: Typography.globalBold
                            font.weight: Typography.globalWeight
                            font.italic: Typography.globalItalic
                        }
                    }

                    MouseArea {
                        id: actMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.actionTriggered(modelData.actionId || "")
                    }
                }
            }
        }
    }
}
