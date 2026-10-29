// Slide-out Control Center surface.
// Manages drawer layout, monitor attachment, scroll-to-expand states, and child widgets.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../config"
import "../../services"
import "."

PanelWindow {
    id: root

    signal requestClose()

    property var historyModel: null
    property bool isTargetScreen: false
    property bool isAnyPanelOpen: false
    property bool isExpandedMode: false

    readonly property real s: Metrics.scaleFor(root.screen)
    readonly property int screenMode: {
        if (!root.screen) return 0;
        let mons = CompositorAdapter.monitors;
        if (mons.length <= 1) return 0;

        for (let i = 0; i < mons.length; i++) {
            let m = mons[i];
            if (m.name === root.screen.name) {
                if (m.x > 0) return 1;
                if (m.x < 0) return 2;
                return 0;
            }
        }
        return 0;
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-control-center"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        left: root.screenMode !== 0
        right: root.screenMode === 0
    }

    implicitWidth: Metrics.scaled(Theme.baseDrawerWidth, root.s)
    implicitHeight: Metrics.scaled(Theme.baseDrawerHeight, root.s)
    color: "transparent"
    visible: isTargetScreen || (trans.currentMarginX > -implicitWidth)

    PanelTransitions {
        id: trans
        panelWindow: root
        screenMode: root.screenMode
        isOpen: root.isTargetScreen
        scaleFactor: root.s
    }

    onIsTargetScreenChanged: {
        if (!isTargetScreen) isExpandedMode = false;
    }

    Rectangle {
        id: panelBox
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: Qt.alpha(Theme.background, 0.85)
        border.color: Qt.alpha(Theme.outline_variant, 0.8)
        border.width: 1

        Loader {
            id: contentLoader
            anchors.fill: parent
            anchors.margins: Math.round(10 * root.s)
            active: root.isTargetScreen || (trans.currentMarginX > -root.implicitWidth)

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

                        onScrollExpandRequested: {
                            root.isExpandedMode = true;
                        }
                        onScrollCollapseRequested: {
                            root.isExpandedMode = false;
                        }
                    }
                }
            }
        }
    }
}
