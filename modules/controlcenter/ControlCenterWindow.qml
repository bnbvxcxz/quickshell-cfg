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
    readonly property real drawerWidth: Metrics.scaled(Metrics.baseDrawerWidth, s)
    readonly property real drawerHeight: Metrics.scaled(Metrics.baseDrawerHeight, s)
    readonly property real baseMargin: Metrics.scaled(8, s)
    readonly property real topMargin: Metrics.scaled(Metrics.baseBarHeight + 4, s)

    readonly property int screenMode: CompositorAdapter.resolveMode(root.screen ? root.screen.name : "")
    readonly property int activeScreenMode: CompositorAdapter.resolveMode(activeScreenName)
    readonly property int prevScreenMode: CompositorAdapter.resolveMode(previousScreenName)

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-control-center"
    WlrLayershell.keyboardFocus: (root.isTargetScreen && NotificationState.hasInlineReply) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        left: root.screenMode !== 0
        right: root.screenMode === 0
    }

    // Extend window to the screen edge so panelBox slides completely off-screen without clipping.
    implicitWidth: drawerWidth + baseMargin
    implicitHeight: drawerHeight + topMargin
    color: "transparent"
    visible: false

    margins.top: 0
    margins.left: 0
    margins.right: 0

    SpringBehavior {
        id: springPreset
        mode: root.isTargetScreen ? "instant" : "exit"
    }

    readonly property real openX: root.screenMode === 0 ? 0 : root.baseMargin
    readonly property real closedX: root.screenMode === 0 ? (root.drawerWidth + root.baseMargin) : (-root.drawerWidth - root.baseMargin)

    SpringAnimation {
        id: animDrop
        target: panelBox
        property: "y"
        to: root.topMargin
        spring: springPreset.stiffnessVal
        damping: springPreset.dampingVal
        mass: 1.0
        epsilon: 0.5
        onFinished: {
            if (root.isTargetScreen) Logger.debug("ControlCenter", `${root.screen ? root.screen.name : "?"} settled open (drop, mode=${screenMode})`);
        }
    }

    SpringAnimation {
        id: animJump
        target: panelBox
        property: "y"
        to: -root.drawerHeight - root.topMargin
        spring: springPreset.stiffnessVal
        damping: springPreset.dampingVal
        mass: 1.0
        epsilon: 1.0
        onFinished: {
            if (!root.isTargetScreen) {
                root.visible = false;
                Logger.debug("ControlCenter", `${root.screen ? root.screen.name : "?"} settled closed (jump, mode=${screenMode})`);
            }
        }
    }

    SpringAnimation {
        id: animSlideIn
        target: panelBox
        property: "x"
        to: root.openX
        spring: springPreset.stiffnessVal
        damping: springPreset.dampingVal
        mass: 1.0
        epsilon: 0.5
        onFinished: {
            if (root.isTargetScreen) Logger.debug("ControlCenter", `${root.screen ? root.screen.name : "?"} settled open (slide, mode=${screenMode})`);
        }
    }

    SpringAnimation {
        id: animSlideOut
        target: panelBox
        property: "x"
        to: root.closedX
        spring: springPreset.stiffnessVal
        damping: springPreset.dampingVal
        mass: 1.0
        epsilon: 1.0
        onFinished: {
            if (!root.isTargetScreen) {
                root.visible = false;
                Logger.debug("ControlCenter", `${root.screen ? root.screen.name : "?"} settled closed (slide, mode=${screenMode})`);
            }
        }
    }

    function stopAllAnimations() {
        animDrop.stop();
        animJump.stop();
        animSlideIn.stop();
        animSlideOut.stop();
    }

    onIsTargetScreenChanged: {
        Logger.debug("ControlCenter", `${root.screen ? root.screen.name : "?"} target=${isTargetScreen} mode=${screenMode}`);
        stopAllAnimations();

        if (!isTargetScreen) {
            isExpandedMode = false;

            if (screenMode === 2 || (screenMode === 0 && isAnyPanelOpen && activeScreenMode === 2)) {
                panelBox.x = root.openX;
                return animJump.start();
            }

            panelBox.y = root.topMargin;
            return animSlideOut.start();
        }

        let wasVisible = root.visible;
        let useDrop = (screenMode === 2) || (screenMode === 0 && previousScreenName !== "" && previousScreenName !== (root.screen ? root.screen.name : "") && prevScreenMode === 2);

        if (useDrop) {
            panelBox.x = root.openX;
            if (!wasVisible) panelBox.y = -root.drawerHeight - root.topMargin;
            root.visible = true;
            animDrop.start();
            return;
        }

        panelBox.y = root.topMargin;
        if (!wasVisible) panelBox.x = root.closedX;
        root.visible = true;
        animSlideIn.start();
    }

    Rectangle {
        id: panelBox
        width: root.drawerWidth
        height: root.drawerHeight
        x: root.closedX
        y: root.screenMode === 2 ? (-root.drawerHeight - root.topMargin) : root.topMargin
        radius: Metrics.cornerRadius
        color: Qt.alpha(Theme.background, Metrics.drawerOpacity)
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
            active: true
            asynchronous: true

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
