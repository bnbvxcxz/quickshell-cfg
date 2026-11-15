// Notification daemon state and action dispatcher singleton.
// Manages notification history, toast queues, Do Not Disturb, inline replies, and action invocation.

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
    signal toggleRequested(string screenName)
    property bool srvActive: false

    readonly property bool hasInlineReply: {
        for (let i = 0; i < histModel.count; i++) {
            if (histModel.get(i).hasInlineReply) return true;
        }
        return false;
    }

    readonly property bool hasToastInlineReply: {
        for (let i = 0; i < toastModel.count; i++) {
            if (toastModel.get(i).hasInlineReply) return true;
        }
        return false;
    }

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
        if (n && n.resident) {
            removeToastById(nid);
            return invoked;
        }
        // Remove locally without calling n.dismiss() so DBus ActionInvoked is not raced.
        removeHistoryById(nid);
        return invoked;
    }

    function sendInlineReply(nid, replyText) {
        let txt = String(replyText || "").trim();
        if (!txt) return false;

        let n = notifMap[nid];
        if (!n || typeof n.sendInlineReply !== "function") return false;

        let sent = false;
        try {
            n.sendInlineReply(txt);
            sent = true;
        } catch(e) {}

        if (n.resident) {
            removeToastById(nid);
            return sent;
        }
        removeHistoryById(nid);
        return sent;
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

    function extractActions(n) {
        let rawActs = [];
        let serActs = [];
        if (!n || !n.actions) return { raw: rawActs, ser: serActs };

        let actIcons = !!n.hasActionIcons;
        let list = n.actions;
        if (list[0] === undefined && list.length === undefined && list.values !== undefined) {
            list = list.values;
        }
        let len = 0;
        if (list.length !== undefined) len = list.length;
        else if (list.count !== undefined) len = list.count;
        else {
            while (list[len] !== undefined) len++;
        }
        for (let i = 0; i < len; i++) {
            let a = (typeof list.get === "function") ? list.get(i) : list[i];
            if (!a) continue;
            let aid = String(a.identifier !== undefined ? a.identifier : (a.id !== undefined ? a.id : `act_${i}`));
            let txt = String(a.text || a.label || aid || "Action");
            let ico = actIcons ? Quickshell.iconPath(aid, true) : "";
            rawActs.push(a);
            if (aid.toLowerCase() !== "default") {
                serActs.push({ actionId: aid, text: txt, icon: ico });
            }
        }
        return { raw: rawActs, ser: serActs };
    }

    function syncNotificationActions(nid, n) {
        let extracted = extractActions(n);
        if (extracted.raw.length === 0) return;
        root.actionMap[nid] = extracted.raw;
        let actsJson = JSON.stringify(extracted.ser);

        for (let i = 0; i < root.histModel.count; i++) {
            if (root.histModel.get(i).id === nid) {
                root.histModel.setProperty(i, "actionsJson", actsJson);
                break;
            }
        }
        for (let i = 0; i < root.toastModel.count; i++) {
            if (root.toastModel.get(i).id === nid) {
                root.toastModel.setProperty(i, "actionsJson", actsJson);
                break;
            }
        }
    }

    property NotificationServer server: NotificationServer {
        id: notifSrv
        actionsSupported: true
        actionIconsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        imageSupported: true
        inlineReplySupported: true
        persistenceSupported: true
        keepOnReload: true

        onNotification: n => {
            if (!root.srvActive) {
                root.srvActive = true;
                Logger.info("Notifications", "Notification server active and receiving events.");
            }
            n.tracked = true;

            let nid = n.id;
            let app = n.appName || "System";
            let entry = n.desktopEntry || "";
            let sum = n.summary || "Notification";
            let body = n.body || "";
            let ts = Qt.formatTime(new Date(), "h:mm:ss AP");
            let appIco = n.appIcon ? Quickshell.iconPath(n.appIcon, true) : "";
            let img = n.image || "";
            let actIcons = !!n.hasActionIcons;
            let hasReply = !!n.hasInlineReply;
            let replyHint = n.inlineReplyPlaceholder || "Reply...";
            let isRes = !!n.resident;
            let isTrans = !!n.transient;
            let expSec = (n.expireTimeout !== undefined && n.expireTimeout !== null) ? Number(n.expireTimeout) : -1;
            let prog = (n.hints && n.hints.value !== undefined && n.hints.value !== null)
                ? Math.max(0, Math.min(100, Number(n.hints.value)))
                : -1;

            let extracted = root.extractActions(n);
            let rawActs = extracted.raw;
            let serActs = extracted.ser;

            if (n.actionsChanged && typeof n.actionsChanged.connect === "function") {
                n.actionsChanged.connect(() => root.syncNotificationActions(nid, n));
            }
            if (rawActs.length === 0) Qt.callLater(() => root.syncNotificationActions(nid, n));

            root.notifMap[nid] = n;
            root.actionMap[nid] = rawActs;

            if (n.closed && typeof n.closed.connect === "function") {
                n.closed.connect(() => root.removeToastById(nid));
            }

            let urgStr = "normal";
            if (n.urgency !== undefined) {
                let u = String(n.urgency).toLowerCase();
                if (u.includes("critical") || u === "2") urgStr = "critical";
                else if (u.includes("low") || u === "0") urgStr = "low";
            }

            let actsJson = JSON.stringify(serActs);

            if (!isTrans && root.histModel.count > 0) {
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

                    let treeJson = JSON.stringify(tree);
                    root.histModel.setProperty(0, "id", nid);
                    root.histModel.setProperty(0, "repeatCount", c);
                    root.histModel.setProperty(0, "body", body);
                    root.histModel.setProperty(0, "timestamp", ts);
                    root.histModel.setProperty(0, "appIcon", appIco);
                    root.histModel.setProperty(0, "image", img);
                    root.histModel.setProperty(0, "hasInlineReply", hasReply);
                    root.histModel.setProperty(0, "inlineReplyPlaceholder", replyHint);
                    root.histModel.setProperty(0, "resident", isRes);
                    root.histModel.setProperty(0, "expireTimeout", expSec);
                    root.histModel.setProperty(0, "progress", prog);
                    root.histModel.setProperty(0, "historyTree", treeJson);
                    root.histModel.setProperty(0, "actionsJson", actsJson);

                    // Keep any visible toast in sync when grouped into the latest history entry.
                    for (let i = 0; i < root.toastModel.count; i++) {
                        if (root.toastModel.get(i).id === oldId) {
                            root.toastModel.setProperty(i, "id", nid);
                            root.toastModel.setProperty(i, "repeatCount", c);
                            root.toastModel.setProperty(i, "body", body);
                            root.toastModel.setProperty(i, "timestamp", ts);
                            root.toastModel.setProperty(i, "appIcon", appIco);
                            root.toastModel.setProperty(i, "image", img);
                            root.toastModel.setProperty(i, "hasInlineReply", hasReply);
                            root.toastModel.setProperty(i, "inlineReplyPlaceholder", replyHint);
                            root.toastModel.setProperty(i, "resident", isRes);
                            root.toastModel.setProperty(i, "expireTimeout", expSec);
                            root.toastModel.setProperty(i, "progress", prog);
                            root.toastModel.setProperty(i, "historyTree", treeJson);
                            root.toastModel.setProperty(i, "actionsJson", actsJson);
                            return;
                        }
                    }
                    return;
                }
            }

            let initTree = [{ body: body, time: ts }];
            let item = {
                id: nid,
                summary: sum,
                body: body,
                appName: app,
                desktopEntry: entry,
                appIcon: appIco,
                image: img,
                timestamp: ts,
                urgency: urgStr,
                repeatCount: 1,
                hasInlineReply: hasReply,
                inlineReplyPlaceholder: replyHint,
                resident: isRes,
                expireTimeout: expSec,
                progress: prog,
                historyTree: JSON.stringify(initTree),
                actionsJson: actsJson
            };

            Logger.debug("Notifications", `Received #${nid} from ${app} (actions=${serActs.length}, reply=${hasReply})`);
            if (!isTrans) root.histModel.insert(0, item);
            if (!root.panelOpen && !root.dnd) root.toastModel.insert(0, item);
        }
    }
}
