//@ pragma UseQApplication
//@ pragma Env QT_LOGGING_RULES=qt.qpa.services.warning=false;qt.qpa.wayland.textinput=false
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
        function onToggleRequested(screenName) { shellRoot.togglePanel(screenName); }
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
        function toggle() { shellRoot.togglePanel(""); }
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
                Logger.warn("OSD", "Parse error: " + err);
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
        target: "hw"
        function volUp() { HardwareState.adjustVolume(1); }
        function volDown() { HardwareState.adjustVolume(-1); }
        function volMute() { HardwareState.toggleMute(); }
        function briUp() { HardwareState.adjustBrightness(1); }
        function briDown() { HardwareState.adjustBrightness(-1); }
        function micMute() { HardwareState.toggleMicMute(); }
        function capsToggle() { HardwareState.toggleCaps(); }
    }

    IpcHandler {
        target: "test"
        function battery(pct: string, status: string) { SystemState.simulateBattery(pct, status); }
        function wifi(ssid: string, signal: string) { SystemState.simulateWifi(ssid, signal); }
        function ethernet(ip: string) { SystemState.simulateEthernet(ip); }
        function updates(arch: string, aur: string, flatpak: string) { SystemState.simulateUpdates(arch, aur, flatpak); }
        function reset() { SystemState.resetSimulation(); }
    }

    IpcHandler {
        target: "log"
        function level(lvl: string) { Logger.setLevel(lvl); }
    }

    IpcHandler {
        target: "theme"
        function reload() { Quickshell.reload(""); }
    }

    function togglePanel(targetScreen) {
        let tgt = targetScreen || CompositorAdapter.focusMon;
        if (!tgt && Quickshell.screens.length > 0) tgt = Quickshell.screens[0].name;

        if (shellRoot.panelOpen) {
            if (targetScreen && tgt && tgt !== shellRoot.actScr) {
                shellRoot.prevScr = shellRoot.actScr;
                shellRoot.actScr = tgt;
                Logger.debug("Drawer", `Switched to ${tgt} (prev=${shellRoot.prevScr})`);
                return;
            }
            shellRoot.panelOpen = false;
            Logger.debug("Drawer", `Closed (was on ${shellRoot.actScr})`);
            return;
        }

        shellRoot.prevScr = shellRoot.actScr ? shellRoot.actScr : tgt;
        shellRoot.actScr = tgt;
        shellRoot.panelOpen = true;
        Logger.debug("Drawer", `Opened on ${tgt} (prev=${shellRoot.prevScr})`);
    }
}
