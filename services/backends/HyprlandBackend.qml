// Hyprland compositor IPC backend.
// Implements the CompositorAdapter ABI using Hyprland Lua/legacy dispatchers and systeminfo probing.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Item {
    id: root

    readonly property int activeWsId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    readonly property string focusMon: (Hyprland.focusedMonitor && typeof Hyprland.focusedMonitor.name === "string") ? Hyprland.focusedMonitor.name : ""
    readonly property var activeTop: Hyprland.activeToplevel
    readonly property string activeWinTitle: (activeTop && typeof activeTop.title === "string") ? activeTop.title : ""
    readonly property var monitors: (Hyprland.monitors && Hyprland.monitors.values) ? Hyprland.monitors.values : []

    readonly property var workspaces: {
        if (!Hyprland.workspaces || !Hyprland.workspaces.values) return [];
        return Hyprland.workspaces.values.slice().sort((a, b) => a.id - b.id);
    }

    property bool useLuaDispatch: false

    // Read-only systeminfo query detects Hyprland 0.55+ Lua config mode ("configProvider: lua").
    Process {
        id: sysInfoProbe
        command: ["hyprctl", "systeminfo"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (/configProvider:\s*lua/i.test(this.text)) root.useLuaDispatch = true;
            }
        }
    }

    Component {
        id: procComp
        Process {
            onExited: destroy()
        }
    }

    function runHyprctl(dispatcher, arg) {
        if (!dispatcher) return;
        let cmd = (arg !== undefined && arg !== null && String(arg).length > 0)
            ? ["hyprctl", "dispatch", String(dispatcher), String(arg)]
            : ["hyprctl", "dispatch", String(dispatcher)];
        procComp.createObject(root, { command: cmd, running: true });
    }

    function runLuaDispatch(expr) {
        procComp.createObject(root, {
            command: ["hyprctl", "dispatch", expr],
            running: true
        });
    }

    function dispatchWorkspace(id) {
        if (id === undefined || id === null) return;
        if (root.useLuaDispatch) {
            return runLuaDispatch(`hl.dsp.focus({ workspace = "${id}" })`);
        }
        runHyprctl("workspace", String(id));
    }

    function stepWorkspace(dir) {
        if (!dir) return;
        let target = dir > 0 ? "m+1" : "m-1";
        if (root.useLuaDispatch) {
            return runLuaDispatch(`hl.dsp.focus({ workspace = "${target}" })`);
        }
        runHyprctl("workspace", target);
    }

    function focusApp(appName, desktopEntry) {
        let raw = String(desktopEntry || appName || "").trim();
        if (!raw) return;

        let parts = raw.split(".");
        let base = parts[parts.length - 1].replace(/[^a-zA-Z0-9_-]/g, "");
        if (!base) return;

        let regex = `class:(?i)^(.*${base}.*)$`;
        if (root.useLuaDispatch) {
            return runLuaDispatch(`hl.dsp.focus({ window = "${regex}" })`);
        }
        runHyprctl("focuswindow", regex);
    }

    function resolveMode(n) {
        if (!n) return 0;
        let mons = root.monitors;
        if (!mons || mons.length === 0) return 0;

        for (let i = 0; i < mons.length; i++) {
            let m = mons[i];
            if (!m || m.name !== n) continue;
            if (m.x < 0) return 2;
            if (m.x > 0) return 1;
            return 0;
        }
        return 0;
    }
}
