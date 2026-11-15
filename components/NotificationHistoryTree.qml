// Expandable grouped message accordion for stacked notifications in history.
// Displays reverse-chronological message bodies and timestamps.

import QtQuick
import QtQuick.Layouts
import "../config"

ColumnLayout {
    id: root

    property var treeItems: ([])
    property real scaleFactor: 1.0
    property var formatMarkupFn: null

    Layout.fillWidth: true
    spacing: Math.round(6 * scaleFactor)

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Qt.alpha(Theme.outline_variant, 0.3)
    }

    Repeater {
        model: root.treeItems

        ColumnLayout {
            id: treeRow
            required property var modelData
            required property int index
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: `• Message #${root.treeItems.length - treeRow.index}`
                    color: Theme.tertiary
                    font.family: Typography.family
                    font.pixelSize: Math.max(8, Typography.sizeSmall(root.scaleFactor) - 1)
                    font.bold: Typography.globalBold
                    font.weight: Typography.globalWeight
                    font.italic: Typography.globalItalic
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: treeRow.modelData.time || ""
                    color: Theme.outline
                    font.family: Typography.family
                    font.pixelSize: Math.max(8, Typography.sizeSmall(root.scaleFactor) - 2)
                    font.bold: Typography.globalBold
                    font.weight: Typography.globalWeight
                    font.italic: Typography.globalItalic
                }
            }

            Text {
                text: root.formatMarkupFn ? root.formatMarkupFn(treeRow.modelData.body || "") : (treeRow.modelData.body || "")
                textFormat: Text.StyledText
                linkColor: Theme.primary
                color: Theme.on_surface
                font.family: Typography.family
                font.pixelSize: Typography.sizeSmall(root.scaleFactor)
                font.bold: Typography.globalBold
                font.weight: Typography.globalWeight
                font.italic: Typography.globalItalic
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                Layout.leftMargin: Math.round(8 * root.scaleFactor)
                onLinkActivated: link => Qt.openUrlExternally(link)
            }
        }
    }
}
