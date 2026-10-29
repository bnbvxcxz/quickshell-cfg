// Workspace switcher indicator with spring physics.
// Dynamically maps compositor workspaces and tracks active focus with centralized typography tokens.

import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../config"
import "../../services"
import "../../components"

Rectangle {
    id: root

    property real scaleFactor: 1.0
    property color activeBg: Theme.secondary
    property color activeFg: Theme.on_secondary
    property color inactiveFg: Theme.secondary

    // Match master Pill geometry and radius
    implicitHeight: Metrics.scaled(Theme.baseBarHeight, scaleFactor)
    implicitWidth: wsRow.implicitWidth
    radius: Math.round(implicitHeight / 2)
    color: Theme.surface_container_low

    Layout.alignment: Qt.AlignVCenter
    Layout.fillHeight: false
    Layout.topMargin: 0
    Layout.bottomMargin: 0
    Layout.leftMargin: 1
    Layout.rightMargin: 1

    property Item activeItem: null

    function updateActiveTarget() {
        if (!Hyprland.focusedWorkspace) return;
        let targetId = Hyprland.focusedWorkspace.id;
        for (let i = 0; i < wsRepeater.count; i++) {
            let child = wsRepeater.itemAt(i);
            if (child && child.wsId === targetId) {
                root.activeItem = child;
                return;
            }
        }
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() { root.updateActiveTarget() }
    }

    SpringBehavior { id: springPresets; mode: "default" }

    Rectangle {
        id: activeIndicator
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        radius: root.radius
        color: root.activeBg
        visible: root.activeItem !== null
        z: 0

        readonly property real targetX: root.activeItem ? root.activeItem.x : 0
        readonly property real targetWidth: root.activeItem ? root.activeItem.width : 0

        x: targetX
        width: targetWidth

        Behavior on x {
            SpringAnimation {
                spring: springPresets.stiffnessVal
                damping: springPresets.dampingVal
                mass: 1.0
                epsilon: 0.25
            }
        }

        Behavior on width {
            SpringAnimation {
                spring: springPresets.stiffnessVal + 0.4
                damping: springPresets.dampingVal + 0.04
                mass: 1.0
                epsilon: 0.25
            }
        }
    }

    Row {
        id: wsRow
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 0
        z: 1

        Repeater {
            id: wsRepeater
            model: {
                if (!Hyprland.workspaces) return [];
                let list = Hyprland.workspaces.values.slice();
                return list.sort((a, b) => a.id - b.id);
            }

            onCountChanged: Qt.callLater(root.updateActiveTarget)

            Item {
                id: wsBtn
                required property var modelData
                readonly property int wsId: modelData.id
                property bool isActive: Hyprland.focusedWorkspace && (Hyprland.focusedWorkspace.id === wsId)
                property bool isOccupied: modelData.windows > 0

                readonly property int hPad: Math.round(8 * root.scaleFactor)
                width: wsText.implicitWidth + (hPad * 2)
                anchors.top: parent.top
                anchors.bottom: parent.bottom

                Text {
                    id: wsText
                    anchors.centerIn: parent
                    text: wsBtn.wsId
                    color: {
                        if (wsBtn.isActive) return root.activeFg;
                        if (wsBtn.isOccupied) return root.inactiveFg;
                        return Theme.on_surface_variant;
                    }
                    font.family: Typography.family
                    font.pixelSize: Typography.size(root.scaleFactor)
                    font.weight: wsBtn.isActive ? Typography.weightMedium : Typography.weightRegular

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: CompositorAdapter.dispatchWorkspace(wsBtn.wsId)
                }

                Component.onCompleted: {
                    if (wsBtn.isActive) root.activeItem = wsBtn;
                }
            }
        }
    }
}
