// Slide-out Control Center surface.
// Manages drawer layout, monitor attachment, scroll-to-expand states, and child widgets.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../config"
import "../../services"
import "../../components"
import "."

PanelWindow {
    id: root

    signal requestClose()
    signal triggerOpenOnThisScreen()

    property var historyModel: null
    property bool isTargetScreen: false
    property bool isAnyPanelOpen: false
    property string activeScreenName: ""
    property string previousScreenName: ""
    property bool isExpandedMode: false

    readonly property real s: Metrics.scaleFor(root.screen)
    readonly property real drawerWidth: Metrics.scaled(Theme.baseDrawerWidth, s)
    readonly property real drawerHeight: Metrics.scaled(Theme.baseDrawerHeight, s)
    readonly property real baseMargin: Metrics.scaled(8, s)
    readonly property real topMargin: Metrics.scaled(26, s)

    readonly property int screenMode: CompositorAdapter.resolveMode(root.screen ? root.screen.name : "")
    readonly property int activeScreenMode: CompositorAdapter.resolveMode(activeScreenName)
    readonly property int prevScreenMode: CompositorAdapter.resolveMode(previousScreenName)

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-control-center"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        left: root.screenMode !== 0
        right: root.screenMode === 0
    }

    implicitWidth: drawerWidth
    implicitHeight: drawerHeight
    color: "transparent"
    visible: false

    margins.top: root.screenMode === 2 ? (-root.drawerHeight - root.topMargin) : root.topMargin
    margins.left: root.screenMode !== 0 ? (root.screenMode === 2 ? root.baseMargin : (-root.drawerWidth - root.baseMargin)) : 0
    margins.right: root.screenMode === 0 ? (-root.drawerWidth - root.baseMargin) : 0

    SpringBehavior {
        id: springPreset
        mode: root.isTargetScreen ? (root.screenMode === 1 ? "instant" : "default") : "exit"
    }

    SpringAnimation {
        id: animDrop
        target: root
        property: "margins.top"
        to: root.topMargin
        spring: springPreset.stiffnessVal
        damping: springPreset.dampingVal
        mass: 1.0
        epsilon: 0.5
    }

    SpringAnimation {
        id: animJump
        target: root
        property: "margins.top"
        to: -root.drawerHeight - root.topMargin
        spring: springPreset.stiffnessVal
        damping: springPreset.dampingVal
        mass: 1.0
        epsilon: 0.5
        onFinished: {
            if (!root.isTargetScreen) root.visible = false;
        }
    }

    SpringAnimation {
        id: animSlideIn
        target: root
        property: root.screenMode === 0 ? "margins.right" : "margins.left"
        to: root.baseMargin
        spring: springPreset.stiffnessVal
        damping: springPreset.dampingVal
        mass: 1.0
        epsilon: 0.5
    }

    SpringAnimation {
        id: animSlideOut
        target: root
        property: root.screenMode === 0 ? "margins.right" : "margins.left"
        to: -root.drawerWidth - root.baseMargin
        spring: springPreset.stiffnessVal
        damping: springPreset.dampingVal
        mass: 1.0
        epsilon: 0.5
        onFinished: {
            if (!root.isTargetScreen) root.visible = false;
        }
    }

    function stopAllAnimations() {
        animDrop.stop();
        animJump.stop();
        animSlideIn.stop();
        animSlideOut.stop();
    }

    onIsTargetScreenChanged: {
        stopAllAnimations();

        if (!isTargetScreen) {
            isExpandedMode = false;

            if (screenMode === 2) {
                root.margins.left = root.baseMargin;
                return animJump.start();
            }
            if (screenMode === 0 && isAnyPanelOpen && activeScreenMode === 2) {
                root.margins.right = root.baseMargin;
                return animJump.start();
            }

            root.margins.top = root.topMargin;
            return animSlideOut.start();
        }

        root.visible = true;

        if (screenMode === 2) {
            root.margins.left = root.baseMargin;
            root.margins.top = -root.drawerHeight - root.topMargin;
            return animDrop.start();
        }

        if (screenMode === 0 && previousScreenName !== "" && previousScreenName !== (root.screen ? root.screen.name : "") && prevScreenMode === 2) {
            root.margins.right = root.baseMargin;
            root.margins.top = -root.drawerHeight - root.topMargin;
            return animDrop.start();
        }

        root.margins.top = root.topMargin;
        if (screenMode === 0) root.margins.right = -root.drawerWidth - root.baseMargin;
        else root.margins.left = -root.drawerWidth - root.baseMargin;

        animSlideIn.start();
    }

    Rectangle {
        id: panelBox
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: Qt.alpha(Theme.background, Theme.drawerOpacity)
        border.color: Qt.alpha(Theme.outline_variant, 0.8)
        border.width: 1

        MouseArea {
            id: autoLeftHoverTrigger
            enabled: root.screenMode === 2 && !root.isTargetScreen && root.isAnyPanelOpen
            anchors {
                top: parent.top
                left: parent.left
            }
            width: Math.round(24 * root.s)
            height: root.implicitHeight
            hoverEnabled: true
            onEntered: root.triggerOpenOnThisScreen()
        }

        Loader {
            id: contentLoader
            anchors.fill: parent
            anchors.margins: Math.round(10 * root.s)
            active: root.visible

            sourceComponent: ColumnLayout {
                spacing: root.isExpandedMode ? Math.round(4 * root.s) : Math.round(8 * root.s)

                Behavior on spacing {
                    NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
                }

                QuickToggles {
                    Layout.fillWidth: true
                    isCompact: root.isExpandedMode
                    scaleFactor: root.s
                }

                HardwareSliders {
                    isCompact: root.isExpandedMode
                    scaleFactor: root.s
                }

                MprisCard {
                    id: mprisCardInstance
                    isScrolledCompact: root.isExpandedMode
                    scaleFactor: root.s
                    onRequestExpand: root.isExpandedMode = false
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    NotificationHistory {
                        id: notifHistory
                        anchors.fill: parent
                        model: root.historyModel
                        scaleFactor: root.s
                        isExpanded: root.isExpandedMode

                        onScrollExpandRequested: root.isExpandedMode = true
                        onScrollCollapseRequested: root.isExpandedMode = false
                    }
                }
            }
        }
    }
}
