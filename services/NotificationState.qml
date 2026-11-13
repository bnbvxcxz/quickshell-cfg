// Notification daemon state and action dispatcher singleton.
// Manages notification history, toast queues, Do Not Disturb, action invocation, and focus activation.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "."

Item {
    id: root

    property ListModel histModel: ListModel {}
    property ListModel toastModel: ListModel {}

    property var notifMap: ({})
    property var actionMap: ({})

    property bool panelOpen: false
    property bool dnd: false
    signal toggleRequested()
    property bool srvActive: false

    onPanelOpenChanged: {
        if (panelOpen) toastModel.clear();
    }

    function toggleDnd() {
        dnd = !dnd;
    }

    function clearToasts() {
        toastModel.clear();
    }

    function clearHistory() {
        for (let k in notifMap) {
            let n = notifMap[k];
            if (n && typeof n.dismiss === "function") {
                try { n.dismiss(); } catch(e) {}
            }
        }
        notifMap = ({});
        actionMap = ({});
        histModel.clear();
        toastModel.clear();
    }

    function removeToastById(nid) {
        for (let i = 0; i < toastModel.count; i++) {
            if (toastModel.get(i).id === nid) {
                toastModel.remove(i);
                return;
            }
        }
    }

    function removeHistoryById(nid) {
        for (let i = 0; i < histModel.count; i++) {
            if (histModel.get(i).id === nid) {
                histModel.remove(i);
                break;
            }
        }
        removeToastById(nid);
        delete notifMap[nid];
        delete actionMap[nid];
    }

    function dismissToast(nid) {
        removeToastById(nid);
    }

    function dismissHistory(nid) {
        let n = notifMap[nid];
        if (n && typeof n.dismiss === "function") {
            try { n.dismiss(); } catch(e) {}
        }
        removeHistoryById(nid);
    }

    function invokeAction(nid, actId) {
        let acts = actionMap[nid] || [];
        let invoked = false;

        for (let i = 0; i < acts.length; i++) {
            let a = acts[i];
            if (!a) continue;
            let id = a.identifier !== undefined ? a.identifier : (a.id !== undefined ? a.id : `act_${i}`);
            if (String(id) === String(actId) && typeof a.invoke === "function") {
                try {
                    a.invoke();
                    invoked = true;
                } catch(e) {}
                break;
            }
        }

        let n = notifMap[nid];
        let app = n ? (n.appName || "") : "";
        let entry = n ? (n.desktopEntry || "") : "";

        CompositorAdapter.focusApp(app, entry);
        // Remove locally without calling n.dismiss() so DBus ActionInvoked is not raced.
        removeHistoryById(nid);
        return invoked;
    }

    function activateNotification(nid, appName, desktopEntry) {
        let acts = actionMap[nid] || [];

        // Discord and Electron clients emit a "default" DBus action that jumps to the target channel.
        for (let i = 0; i < acts.length; i++) {
            let a = acts[i];
            if (!a) continue;
            let id = String(a.identifier !== undefined ? a.identifier : (a.id !== undefined ? a.id : "")).toLowerCase();
            if ((id === "default" || id === "activate" || acts.length === 1) && typeof a.invoke === "function") {
                try { a.invoke(); } catch(e) {}
                break;
            }
        }

        let n = notifMap[nid];
        let app = appName || (n ? n.appName : "");
        let entry = desktopEntry || (n ? n.desktopEntry : "");

        CompositorAdapter.focusApp(app, entry);
        removeToastById(nid);
    }

    property NotificationServer server: NotificationServer {
        id: notifSrv
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        persistenceSupported: true
        keepOnReload: true

        onNotification: n => {
            if (!root.srvActive) {
                root.srvActive = true;
                console.info("[Notifications] Notification server active and receiving events.");
            }
            n.tracked = true;

            let nid = n.id;
            let app = n.appName || "System";
            let entry = n.desktopEntry || "";
            let sum = n.summary || "Notification";
            let body = n.body || "";
            let ts = Qt.formatTime(new Date(), "h:mm:ss AP");

            let rawActs = [];
            let serActs = [];

            if (n.actions) {
                let list = n.actions.values ? n.actions.values : n.actions;
                let len = list.length !== undefined ? list.length : (list.count || 0);
                for (let i = 0; i < len; i++) {
                    let a = list.get ? list.get(i) : list[i];
                    if (!a) continue;
                    let aid = String(a.identifier !== undefined ? a.identifier : (a.id !== undefined ? a.id : `act_${i}`));
                    let txt = String(a.text || a.label || "Action");
                    rawActs.push(a);
                    if (aid.toLowerCase() !== "default") {
                        serActs.push({ actionId: aid, text: txt });
                    }
                }
            }

            root.notifMap[nid] = n;
            root.actionMap[nid] = rawActs;

            if (root.histModel.count > 0) {
                let first = root.histModel.get(0);
                if (first.appName === app && (first.summary === sum || app === "blueman" || app === "Bluetooth")) {
                    let oldId = first.id;
                    if (oldId !== nid) {
                        delete root.notifMap[oldId];
                        delete root.actionMap[oldId];
                    }

                    let c = (first.repeatCount || 1) + 1;
                    let tree = [];

                    try { tree = JSON.parse(first.historyTree || "[]"); }
                    catch(e) { tree = []; }

                    if (tree.length === 0) tree.push({ body: first.body, time: first.timestamp || ts });
                    tree.unshift({ body: body, time: ts });

                    root.histModel.setProperty(0, "id", nid);
                    root.histModel.setProperty(0, "repeatCount", c);
                    root.histModel.setProperty(0, "body", body);
                    root.histModel.setProperty(0, "timestamp", ts);
                    root.histModel.setProperty(0, "historyTree", JSON.stringify(tree));
                    root.histModel.setProperty(0, "actionsJson", JSON.stringify(serActs));
                    return;
                }
            }

            let initTree = [{ body: body, time: ts }];
            let urgStr = "normal";
            if (n.urgency !== undefined) {
                let u = String(n.urgency).toLowerCase();
                if (u.includes("critical") || u === "2") urgStr = "critical";
                else if (u.includes("low") || u === "0") urgStr = "low";
            }

            let item = {
                id: nid,
                summary: sum,
                body: body,
                appName: app,
                desktopEntry: entry,
                timestamp: ts,
                urgency: urgStr,
                repeatCount: 1,
                historyTree: JSON.stringify(initTree),
                actionsJson: JSON.stringify(serActs)
            };

            root.histModel.insert(0, item);
            if (!root.panelOpen && !root.dnd) root.toastModel.insert(0, item);
        }
    }
}
