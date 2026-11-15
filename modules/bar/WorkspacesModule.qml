// Workspace switcher indicator with spring physics.
// Maps compositor workspaces, supports click-to-focus, and steps workspaces on wheel scroll.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../components"

Rectangle {
    id: root

    property real scaleFactor: 1.0
    property color activeBg: Theme.secondary
    property color activeFg: Theme.on_secondary
    property color inactiveFg: Theme.secondary

    implicitHeight: Metrics.scaled(Metrics.baseBarHeight, scaleFactor)
    implicitWidth: wsRow.implicitWidth
    radius: Metrics.moduleRadius < 0 ? Math.round(implicitHeight / 2) : Metrics.scaled(Metrics.moduleRadius, scaleFactor)
    color: Theme.surface_container_low
    border.width: Metrics.moduleBorderWidth
    border.color: Metrics.moduleBorderColor

    Layout.alignment: Qt.AlignVCenter
    Layout.fillHeight: false
    Layout.topMargin: 0
    Layout.bottomMargin: 0
    Layout.leftMargin: 1
    Layout.rightMargin: 1

    property Item activeItem: null
    property int scrollAcc: 0

    function updateActiveTarget() {
        let targetId = CompositorAdapter.activeWsId;
        for (let i = 0; i < wsRepeater.count; i++) {
            let child = wsRepeater.itemAt(i);
            if (child && child.wsId === targetId) {
                root.activeItem = child;
                return;
            }
        }
    }

    function handleWheel(wheel) {
        let delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x;
        root.scrollAcc += delta;
        while (Math.abs(root.scrollAcc) >= 120) {
            // Scroll up steps left (-1); scroll down steps right (+1).
            let dir = root.scrollAcc > 0 ? -1 : 1;
            root.stepRelative(dir);
            root.scrollAcc -= (root.scrollAcc > 0 ? 120 : -120);
        }
        wheel.accepted = true;
    }

    function stepRelative(dir) {
        let list = CompositorAdapter.workspaces;
        if (!list || list.length <= 1) return CompositorAdapter.stepWorkspace(dir);

        let curId = CompositorAdapter.activeWsId;
        let idx = -1;
        for (let i = 0; i < list.length; i++) {
            if (list[i].id === curId) {
                idx = i;
                break;
            }
        }

        if (idx === -1) return CompositorAdapter.stepWorkspace(dir);
        let nextIdx = (idx + dir + list.length) % list.length;
        Logger.debug("Workspaces", `Step relative dir=${dir} -> ${list[nextIdx].id}`);
        CompositorAdapter.dispatchWorkspace(list[nextIdx].id);
    }

    Connections {
        target: CompositorAdapter
        function onActiveWsIdChanged() { root.updateActiveTarget() }
        function onWorkspacesChanged() { Qt.callLater(root.updateActiveTarget) }
    }

    SpringBehavior { id: springPresets; mode: "default" }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => root.handleWheel(wheel)
    }

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
            model: CompositorAdapter.workspaces

            onCountChanged: Qt.callLater(root.updateActiveTarget)

            Item {
                id: wsBtn
                required property var modelData
                readonly property int wsId: modelData.id
                property bool isActive: CompositorAdapter.activeWsId === wsId
                property bool isOccupied: modelData.windows > 0

                readonly property int hPad: Math.round(8 * root.scaleFactor)
                width: wsText.implicitWidth + (hPad * 2)
                height: wsRow.height

                Text {
                    id: wsText
                    anchors.centerIn: parent
                    text: String(wsBtn.wsId)
                    color: {
                        if (wsBtn.isActive) return root.activeFg;
                        if (wsBtn.isOccupied) return root.inactiveFg;
                        return Theme.on_surface_variant;
                    }
                    font.family: Typography.family
                    font.pixelSize: Typography.size(root.scaleFactor)
                    font.bold: Typography.globalBold
                    font.weight: wsBtn.isActive ? Typography.weightBold : Typography.globalWeight
                    font.italic: Typography.globalItalic

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { Logger.debug("Workspaces", `Click -> workspace ${wsBtn.wsId}`); CompositorAdapter.dispatchWorkspace(wsBtn.wsId); }
                    onWheel: wheel => root.handleWheel(wheel)
                }

                Component.onCompleted: {
                    if (wsBtn.isActive) root.activeItem = wsBtn;
                }
            }
        }
    }
}
