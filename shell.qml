// Quickshell application entry point.
// Instantiates multi-screen variants, registers notification servers, and exposes IPC command targets.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "./services"
import "./modules/bar"
import "./modules/controlcenter"
import "./modules/notifications"
import "./modules/osd"

Scope {
    id: shellRoot

    ListModel { id: notifHistoryModel }
    ListModel { id: popupToastModel }

    // [ANCHOR:TARGET_SCREEN_STATE]
    property string activePanelScreen: (Quickshell.screens.length > 0 && Quickshell.screens[0].name) ? Quickshell.screens[0].name : "eDP-1"
    property string previousPanelScreen: activePanelScreen
    property bool panelOpen: false

    onPanelOpenChanged: {
        if (panelOpen) {
            popupToastModel.clear();
        }
    }

    // [ANCHOR:DISMISS_ON_WINDOW_FOCUS]
    readonly property var activeWindow: CompositorAdapter.activeToplevel
    property string lastActiveWindowAddress: ""
    onActiveWindowChanged: {
        if (!activeWindow) return;
        let addr = activeWindow.address || "";
        if (panelOpen && lastActiveWindowAddress !== "" && addr !== lastActiveWindowAddress) {
            panelOpen = false;
        }
        lastActiveWindowAddress = addr;
    }

    // [ANCHOR:MONITOR_TRACKING]
    readonly property string focusedMon: CompositorAdapter.focusedMonitorName
    onFocusedMonChanged: {
        if (panelOpen && focusedMon !== "" && focusedMon !== activePanelScreen) {
            previousPanelScreen = activePanelScreen;
            activePanelScreen = focusedMon;
        }
    }

    property NotificationServer server: NotificationServer {
        id: notifServer

        onNotification: notif => {
            let app = notif.appName || "System";
            let sum = notif.summary || "Notification";
            let body = notif.body || "";
            let timeStr = Qt.formatTime(new Date(), "h:mm:ss AP");

            let actList = [];
            if (notif.actions) {
                for (let i = 0; i < notif.actions.length; i++) {
                    let a = notif.actions[i];
                    actList.push({
                        actionId: a.id || a.identifier || ("act_" + i),
                                 text: a.text || a.label || "Action",
                                 actionObj: a
                    });
                }
            }

            if (notifHistoryModel.count > 0) {
                let first = notifHistoryModel.get(0);
                if (first.appName === app && (first.summary === sum || app === "blueman" || app === "Bluetooth")) {
                    let newCount = (first.repeatCount || 1) + 1;

                    let tree = [];
                    try {
                        tree = JSON.parse(first.historyTree || "[]");
                    } catch(e) {
                        tree = [];
                    }
                    if (tree.length === 0) {
                        tree.push({ body: first.body, time: first.timestamp || timeStr });
                    }
                    tree.unshift({ body: body, time: timeStr });

                    notifHistoryModel.setProperty(0, "repeatCount", newCount);
                    notifHistoryModel.setProperty(0, "body", body);
                    notifHistoryModel.setProperty(0, "historyTree", JSON.stringify(tree));
                    return;
                }
            }

            let initialTree = [{ body: body, time: timeStr }];

            let item = {
                id: notif.id,
                summary: sum,
                body: body,
                appName: app,
                timestamp: timeStr,
                urgency: notif.urgency ? String(notif.urgency) : "normal",
                repeatCount: 1,
                historyTree: JSON.stringify(initialTree),
                actions: actList
            };

            notifHistoryModel.insert(0, item);

            if (!shellRoot.panelOpen) {
                popupToastModel.insert(0, item);
            }
        }
    }

    // [ANCHOR:SCREEN_VARIANTS]
    Variants {
        model: Quickshell.screens
        delegate: BarWindow {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: ControlCenterWindow {
            required property var modelData
            screen: modelData
            historyModel: notifHistoryModel
            isTargetScreen: shellRoot.panelOpen && (modelData !== null && modelData.name === shellRoot.activePanelScreen)
            isAnyPanelOpen: shellRoot.panelOpen
            activeScreenName: shellRoot.activePanelScreen
            previousScreenName: shellRoot.previousPanelScreen
            onRequestClose: shellRoot.panelOpen = false
            onTriggerOpenOnThisScreen: {
                if (modelData && modelData.name) {
                    shellRoot.previousPanelScreen = shellRoot.activePanelScreen;
                    shellRoot.activePanelScreen = modelData.name;
                }
                shellRoot.panelOpen = true;
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: NotificationToast {
            required property var modelData
            screen: modelData
            model: popupToastModel
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: OsdWindow {
            required property var modelData
            screen: modelData
        }
    }

    // [ANCHOR:GLOBAL_IPC]
    IpcHandler {
        target: "drawer"
        function toggle() {
            if (!shellRoot.panelOpen) {
                let target = CompositorAdapter.focusedMonitorName;
                if (!target && Quickshell.screens.length > 0) target = Quickshell.screens[0].name;
                shellRoot.previousPanelScreen = shellRoot.activePanelScreen ? shellRoot.activePanelScreen : target;
                shellRoot.activePanelScreen = target;
                shellRoot.panelOpen = true;
            } else {
                shellRoot.panelOpen = false;
            }
        }
        function open() {
            let target = CompositorAdapter.focusedMonitorName;
            if (!target && Quickshell.screens.length > 0) target = Quickshell.screens[0].name;
            shellRoot.previousPanelScreen = shellRoot.activePanelScreen ? shellRoot.activePanelScreen : target;
            shellRoot.activePanelScreen = target;
            shellRoot.panelOpen = true;
        }
        function close() {
            shellRoot.panelOpen = false;
        }
    }

    IpcHandler {
        target: "osd"
        function show(jsonStr: string) {
            try {
                let data = JSON.parse(jsonStr);
                HardwareState.triggerOsd(data.type || "volume", data.value || 0.5, data.icon || "󰕾", !!data.muted);
            } catch (err) {
                console.warn("[OSD] Parse error:", err);
            }
        }
    }

    IpcHandler {
        target: "theme"
        function reload() {
            Quickshell.reload("");
        }
    }

    function togglePanel() {
        if (!shellRoot.panelOpen) {
            let target = CompositorAdapter.focusedMonitorName;
            if (!target && Quickshell.screens.length > 0) target = Quickshell.screens[0].name;
            shellRoot.previousPanelScreen = shellRoot.activePanelScreen ? shellRoot.activePanelScreen : target;
            shellRoot.activePanelScreen = target;
            shellRoot.panelOpen = true;
        } else {
            shellRoot.panelOpen = false;
        }
    }
}
