// Status bar package update counter.
// Launches update script on click, maps window coordinates reactively,
// and colors the pill based on the averaged health states of Arch, AUR, and Flatpak.

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../config"
import "../../services"
import "../../components"

Pill {
    id: root

    property var barWindowRef: null

    readonly property int avgState: SystemState.averagedState

    // 3 Error Color States:
    // State 0 (whatever):   tertiary_container / tertiary
    // State 1 (noticeable): error_container / on_error_container
    // State 2 (bad bad):    error / on_error
    readonly property color currentPillBg: {
        switch (avgState) {
            case 2: return Theme.error;
            case 1: return Theme.error_container;
            default: return Theme.tertiary_container;
        }
    }

    readonly property color currentPillFg: {
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

    pillColor: currentPillBg
    visible: SystemState.updateCount > 0
    Layout.preferredWidth: visible ? -1 : 0
    hoverEnabled: true

    onClicked: HardwareState.runCmd("nohup setsid kitty --class quickshell_update -e sh -c '$HOME/.config/quickshell/scripts/update.sh' >/dev/null 2>&1 &")

    Pill.Icon {
        text: "󰏔"
        color: root.currentPillFg
        scaleFactor: root.scaleFactor
    }

    Pill.Label {
        text: `${SystemState.updateCount}`
        color: root.currentPillFg
        scaleFactor: root.scaleFactor
    }

    readonly property real windowX: {
        if (!root.barWindowRef || !root.barWindowRef.contentItem) return 0;
        let _dep = root.x + root.width;
        let pt = root.mapToItem(root.barWindowRef.contentItem, 0, 0);
        return pt ? pt.x : 0;
    }

    PopupWindow {
        id: updatePopupWindow
        anchor.window: root.barWindowRef
        anchor.rect.x: root.windowX
        anchor.rect.y: 0
        anchor.rect.width: root.width
        anchor.rect.height: root.height
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        visible: (root.containsMouse || popupHoverArea.containsMouse) && SystemState.updateCount > 0
        color: "transparent"

        implicitWidth: breakdownCard.implicitWidth
        implicitHeight: breakdownCard.implicitHeight + Metrics.scaled(6, root.scaleFactor)

        Rectangle {
            id: breakdownCard
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter

            implicitWidth: breakdownCol.implicitWidth + Metrics.scaled(24, root.scaleFactor)
            implicitHeight: breakdownCol.implicitHeight + Metrics.scaled(16, root.scaleFactor)

            radius: Theme.cornerRadius
            color: Theme.surface_container_high
            border.color: Qt.alpha(root.currentPillBg, 0.9)
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
                        text: `${SystemState.updatesArch}`
                        color: SystemState.updatesArch > 0 ? root.colorForState(SystemState.archState, Theme.primary) : Theme.outline
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
                        text: `${SystemState.updatesAur}`
                        color: SystemState.updatesAur > 0 ? root.colorForState(SystemState.aurState, Theme.tertiary) : Theme.outline
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
                        text: `${SystemState.updatesFlatpak}`
                        color: SystemState.updatesFlatpak > 0 ? root.colorForState(SystemState.flatpakState, Theme.secondary) : Theme.outline
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
