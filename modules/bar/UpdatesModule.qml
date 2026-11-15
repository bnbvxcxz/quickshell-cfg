// Status bar package update counter.
// Launches update script on click and displays per-source breakdown popup on hover.

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../config"
import "../../services"
import "../../components"

BarModule {
    id: root

    property var barWindowRef: null

    readonly property int avgState: SystemState.avgState

    readonly property color currentModBg: {
        switch (avgState) {
            case 2: return Theme.error;
            case 1: return Theme.error_container;
            default: return Theme.tertiary_container;
        }
    }

    readonly property color currentModFg: {
        switch (avgState) {
            case 2: return Theme.on_error;
            case 1: return Theme.on_error_container;
            default: return Theme.tertiary;
        }
    }

    function colorForState(stateVal, fallbackColor) {
        switch (stateVal) {
            case 2: return Theme.error;
            case 1: return Theme.on_error_container;
            default: return fallbackColor;
        }
    }

    moduleColor: currentModBg
    visible: SystemState.updCount > 0
    Layout.preferredWidth: visible ? -1 : 0
    hoverEnabled: true

    onClicked: { Logger.debug("Updates", `Click -> launch updater (${SystemState.updCount} pending)`); HardwareState.runCmd(`nohup setsid ${Commands.terminal} --class quickshell_update -e "${Commands.updateScript}" >/dev/null 2>&1 &`); }

    BarModule.Icon {
        text: "󰏔"
        color: root.currentModFg
        scaleFactor: root.scaleFactor
    }

    BarModule.Label {
        text: `${SystemState.updCount}`
        color: root.currentModFg
        scaleFactor: root.scaleFactor
    }

    PopupWindow {
        id: updatePopupWindow
        anchor.window: root.barWindowRef
        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        visible: (root.containsMouse || popupHoverArea.containsMouse) && SystemState.updCount > 0
        color: "transparent"

        implicitWidth: breakdownCard.implicitWidth
        implicitHeight: breakdownCard.implicitHeight + Metrics.scaled(6, root.scaleFactor)

        Rectangle {
            id: breakdownCard
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter

            implicitWidth: breakdownCol.implicitWidth + Metrics.scaled(24, root.scaleFactor)
            implicitHeight: breakdownCol.implicitHeight + Metrics.scaled(16, root.scaleFactor)

            radius: Metrics.cornerRadius
            color: Theme.surface_container_high
            border.color: Qt.alpha(root.currentModBg, 0.9)
            border.width: 1

            MouseArea {
                id: popupHoverArea
                anchors.fill: parent
                hoverEnabled: true
            }

            ColumnLayout {
                id: breakdownCol
                anchors.centerIn: parent
                spacing: Metrics.scaled(4, root.scaleFactor)

                RowLayout {
                    spacing: Metrics.scaled(18, root.scaleFactor)
                    Text {
                        text: "arch:"
                        color: Theme.on_surface_variant
                        font.family: Typography.family
                        font.pixelSize: Typography.sizeSmall(root.scaleFactor)
                        font.bold: Typography.globalBold
                        font.weight: Typography.globalWeight
                        font.italic: Typography.globalItalic
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: `${SystemState.updArch}`
                        color: SystemState.updArch > 0 ? root.colorForState(SystemState.archState, Theme.primary) : Theme.outline
                        font.family: Typography.family
                        font.pixelSize: Typography.sizeSmall(root.scaleFactor)
                        font.bold: Typography.globalBold
                        font.weight: Typography.globalWeight
                        font.italic: Typography.globalItalic
                    }
                }

                RowLayout {
                    spacing: Metrics.scaled(18, root.scaleFactor)
                    Text {
                        text: "aur:"
                        color: Theme.on_surface_variant
                        font.family: Typography.family
                        font.pixelSize: Typography.sizeSmall(root.scaleFactor)
                        font.bold: Typography.globalBold
                        font.weight: Typography.globalWeight
                        font.italic: Typography.globalItalic
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: `${SystemState.updAur}`
                        color: SystemState.updAur > 0 ? root.colorForState(SystemState.aurState, Theme.tertiary) : Theme.outline
                        font.family: Typography.family
                        font.pixelSize: Typography.sizeSmall(root.scaleFactor)
                        font.bold: Typography.globalBold
                        font.weight: Typography.globalWeight
                        font.italic: Typography.globalItalic
                    }
                }

                RowLayout {
                    spacing: Metrics.scaled(18, root.scaleFactor)
                    Text {
                        text: "flatpak:"
                        color: Theme.on_surface_variant
                        font.family: Typography.family
                        font.pixelSize: Typography.sizeSmall(root.scaleFactor)
                        font.bold: Typography.globalBold
                        font.weight: Typography.globalWeight
                        font.italic: Typography.globalItalic
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: `${SystemState.updFlatpak}`
                        color: SystemState.updFlatpak > 0 ? root.colorForState(SystemState.flatpakState, Theme.secondary) : Theme.outline
                        font.family: Typography.family
                        font.pixelSize: Typography.sizeSmall(root.scaleFactor)
                        font.bold: Typography.globalBold
                        font.weight: Typography.globalWeight
                        font.italic: Typography.globalItalic
                    }
                }
            }
        }
    }
}
