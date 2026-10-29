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

    property string activePanelScreen: ""
    property bool panelOpen: false

    onPanelOpenChanged: {
        if (panelOpen) {
            popupToastModel.clear();
        }
    }

    readonly property string currentFocusedMonitorName: (CompositorAdapter.focusedMonitorName !== undefined && CompositorAdapter.focusedMonitorName !== null) ? CompositorAdapter.focusedMonitorName : ""

    onCurrentFocusedMonitorNameChanged: {
        if (panelOpen && currentFocusedMonitorName !== "") {
            activePanelScreen = currentFocusedMonitorName;
        }
    }

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

    Variants {
        model: Quickshell.screens
        delegate: BarWindow {}
    }

    Variants {
        model: Quickshell.screens
        delegate: ControlCenterWindow {
            historyModel: notifHistoryModel
            isTargetScreen: shellRoot.panelOpen && (shellRoot.activePanelScreen === "" || (screen && screen.name === shellRoot.activePanelScreen))
            isAnyPanelOpen: shellRoot.panelOpen
            onRequestClose: shellRoot.panelOpen = false
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: NotificationToast {
            model: popupToastModel
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: OsdWindow {}
    }

    IpcHandler {
        target: "drawer"
        function toggle() {
            shellRoot.panelOpen = !shellRoot.panelOpen;
            if (shellRoot.panelOpen && shellRoot.currentFocusedMonitorName !== "") {
                shellRoot.activePanelScreen = shellRoot.currentFocusedMonitorName;
            }
        }
        function open() {
            shellRoot.panelOpen = true;
            if (shellRoot.currentFocusedMonitorName !== "") {
                shellRoot.activePanelScreen = shellRoot.currentFocusedMonitorName;
            }
        }
        function close() {
            shellRoot.panelOpen = false;
        }
    }

    IpcHandler {
        target: "theme"
        function reload() {
            Quickshell.reload("");
        }
    }

    function togglePanel() {
        shellRoot.panelOpen = !shellRoot.panelOpen;
        if (shellRoot.panelOpen && shellRoot.currentFocusedMonitorName !== "") {
            shellRoot.activePanelScreen = shellRoot.currentFocusedMonitorName;
        }
    }
}
