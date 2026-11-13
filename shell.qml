//@ pragma UseQApplication
//@ pragma Env QT_LOGGING_RULES=qt.qpa.services.warning=false
// Quickshell application entry point.
// Instantiates multi-screen variants, coordinates drawer state, and exposes IPC command targets.

import QtQuick
import Quickshell
import Quickshell.Io
import "./services"
import "./modules/bar"
import "./modules/controlcenter"
import "./modules/notifications"
import "./modules/osd"

Scope {
    id: shellRoot

    property string actScr: (Quickshell.screens.length > 0 && Quickshell.screens[0].name) ? Quickshell.screens[0].name : "eDP-1"
    property string prevScr: actScr
    property bool panelOpen: false

    onPanelOpenChanged: {
        NotificationState.panelOpen = panelOpen;
    }

    Connections {
        target: NotificationState
        function onToggleRequested() { shellRoot.togglePanel(); }
    }

    readonly property var actWin: CompositorAdapter.activeTop
    property string lastWinAddr: ""

    onActWinChanged: {
        if (!actWin) return;
        let addr = actWin.address || "";
        if (panelOpen && lastWinAddr !== "" && addr !== lastWinAddr) panelOpen = false;
        lastWinAddr = addr;
    }

    readonly property string focMon: CompositorAdapter.focusMon

    onFocMonChanged: {
        if (!panelOpen || focMon === "" || focMon === actScr) return;
        prevScr = actScr;
        actScr = focMon;
    }

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
            historyModel: NotificationState.histModel
            isTargetScreen: shellRoot.panelOpen && (modelData !== null && modelData.name === shellRoot.actScr)
            isAnyPanelOpen: shellRoot.panelOpen
            activeScreenName: shellRoot.actScr
            previousScreenName: shellRoot.prevScr
            onRequestClose: shellRoot.panelOpen = false
            onTriggerOpenOnThisScreen: {
                if (modelData && modelData.name) {
                    shellRoot.prevScr = shellRoot.actScr;
                    shellRoot.actScr = modelData.name;
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
            model: NotificationState.toastModel
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: OsdWindow {
            required property var modelData
            screen: modelData
        }
    }

    IpcHandler {
        target: "drawer"
        function toggle() { shellRoot.togglePanel(); }
        function open() {
            let tgt = CompositorAdapter.focusMon;
            if (!tgt && Quickshell.screens.length > 0) tgt = Quickshell.screens[0].name;
            shellRoot.prevScr = shellRoot.actScr ? shellRoot.actScr : tgt;
            shellRoot.actScr = tgt;
            shellRoot.panelOpen = true;
        }
        function close() { shellRoot.panelOpen = false; }
    }

    IpcHandler {
        target: "osd"
        function show(jsonStr: string) {
            try {
                let d = JSON.parse(jsonStr);
                let val = d.value !== undefined ? d.value : 0.5;
                HardwareState.osdTriggered(d.type || "volume", val, d.icon || HardwareState.volumeIcon, !!d.muted);
            } catch (err) {
                console.warn("[OSD] Parse error:", err);
            }
        }
    }

    IpcHandler {
        target: "dnd"
        function toggle() { NotificationState.toggleDnd(); }
        function on() { NotificationState.dnd = true; }
        function off() { NotificationState.dnd = false; }
    }

    IpcHandler {
        target: "updates"
        function refresh() { SystemState.refreshUpdates(); }
    }

    IpcHandler {
        target: "theme"
        function reload() { Quickshell.reload(""); }
    }

    function togglePanel() {
        if (shellRoot.panelOpen) return shellRoot.panelOpen = false;

        let tgt = CompositorAdapter.focusMon;
        if (!tgt && Quickshell.screens.length > 0) tgt = Quickshell.screens[0].name;
        shellRoot.prevScr = shellRoot.actScr ? shellRoot.actScr : tgt;
        shellRoot.actScr = tgt;
        shellRoot.panelOpen = true;
    }
}
