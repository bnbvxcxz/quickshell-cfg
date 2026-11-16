// Niri Wayland compositor IPC backend.
// Implements the CompositorAdapter ABI using $NIRI_SOCKET EventStream and niri msg actions.

import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: root

    readonly property string socketPath: Quickshell.env("NIRI_SOCKET") || ""

    property int activeWsId: 1
    property string focusMon: ""
    property var activeTop: null
    property string activeWinTitle: ""
    property var workspaces: ([])
    property var outputs: ({})
    property var windowsById: ({})

    Component {
        id: procComp
        Process {
            onExited: destroy()
        }
    }

    function runAction(args) {
        if (!root.socketPath) return;
        Logger.debug("Niri", `Action: ${args.join(" ")}`);
        procComp.createObject(root, {
            command: ["niri", "msg", "action"].concat(args),
            running: true
        });
    }

    function dispatchWorkspace(id) {
        if (id === undefined || id === null) return;
        runAction(["focus-workspace", String(id)]);
    }

    function stepWorkspace(dir) {
        if (!dir) return;
        runAction([dir > 0 ? "focus-workspace-down" : "focus-workspace-up"]);
    }

    property string pendingFocusBase: ""

    Process {
        id: focusWinProc
        command: ["niri", "msg", "-j", "windows"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let base = root.pendingFocusBase;
                if (!base) return;
                root.pendingFocusBase = "";
                try {
                    let wins = JSON.parse(this.text);
                    for (let i = 0; i < wins.length; i++) {
                        let appId = String(wins[i].app_id || "").toLowerCase();
                        if (appId.includes(base)) {
                            root.runAction(["focus-window", "--id", String(wins[i].id)]);
                            break;
                        }
                    }
                } catch(e) { Logger.warn("Niri", "Windows parse error: " + e); }
            }
        }
    }

    function focusApp(appName, desktopEntry) {
        if (!root.socketPath) return;
        let raw = String(desktopEntry || appName || "").trim().toLowerCase();
        if (!raw) return;
        let parts = raw.split(".");
        let base = parts[parts.length - 1].replace(/[^a-z0-9_-]/g, "");
        if (!base) return;

        Logger.debug("Niri", `focusApp: ${base}`);
        root.pendingFocusBase = base;
        if (!focusWinProc.running) focusWinProc.running = true;
    }

    function resolveMode(name) {
        if (!name || !outputs[name]) return 0;
        let x = outputs[name].logical ? outputs[name].logical.x : 0;
        if (x < 0) return 2;
        if (x > 0) return 1;
        return 0;
    }

    function setFocusedWindow(w) {
        if (!w) {
            root.activeWinTitle = "";
            root.activeTop = null;
            return;
        }
        root.activeWinTitle = w.title || "";
        root.activeTop = { address: String(w.id), title: root.activeWinTitle };
    }

    function applyWindows(list) {
        if (!Array.isArray(list)) return;
        let map = {};
        let focused = null;
        for (let i = 0; i < list.length; i++) {
            let w = list[i];
            map[String(w.id)] = w;
            if (w.is_focused) focused = w;
        }
        root.windowsById = map;
        setFocusedWindow(focused);
    }

    function applyWindowOpenedOrChanged(w) {
        if (!w || w.id === undefined) return;
        let key = String(w.id);
        let map = root.windowsById;
        map[key] = w;
        root.windowsById = map;
        if (w.is_focused || (root.activeTop && root.activeTop.address === key)) {
            setFocusedWindow(w);
        }
    }

    function applyWindowClosed(id) {
        if (id === undefined || id === null) return;
        let key = String(id);
        let map = root.windowsById;
        delete map[key];
        root.windowsById = map;
        if (root.activeTop && root.activeTop.address === key) {
            setFocusedWindow(null);
        }
    }

    function applyWorkspaces(list) {
        if (!Array.isArray(list)) return;
        let prevWs = root.activeWsId;
        let prevMon = root.focusMon;
        let mapped = [];
        for (let i = 0; i < list.length; i++) {
            let w = list[i];
            let idx = w.idx !== undefined ? w.idx : (w.id || (i + 1));
            let nid = w.id !== undefined ? w.id : idx;
            mapped.push({
                id: idx,
                niriId: nid,
                windows: w.active_window_id ? 1 : 0,
                output: w.output || "",
                isActive: !!w.is_active,
                isFocused: !!w.is_focused
            });
            if (w.is_focused) {
                root.activeWsId = idx;
                if (w.output) root.focusMon = w.output;
            }
        }
        mapped.sort((a, b) => a.id !== b.id ? a.id - b.id : a.output.localeCompare(b.output));
        root.workspaces = mapped;
        if (root.activeWsId !== prevWs || root.focusMon !== prevMon) {
            Logger.debug("Niri", `WorkspacesChanged: count=${mapped.length} focused=${root.activeWsId}${root.focusMon ? " (" + root.focusMon + ")" : ""}`);
        }
    }

    function handleWorkspaceActivated(ev) {
        let nid = ev.id;
        if (nid === undefined) return;
        let foc = !!ev.focused;
        let cur = root.workspaces;
        let hit = null;

        for (let i = 0; i < cur.length; i++) {
            if (cur[i].niriId === nid) { hit = cur[i]; break; }
        }
        if (!hit) {
            Logger.debug("Niri", `WorkspaceActivated: unknown niriId=${nid} focused=${foc}`);
            return;
        }

        // WorkspaceActivated carries Niri's internal u64 id, not the 1-based output idx.
        let next = [];
        for (let i = 0; i < cur.length; i++) {
            let item = cur[i];
            let sameOut = hit.output && item.output === hit.output;
            next.push({
                id: item.id,
                niriId: item.niriId,
                windows: item.windows,
                output: item.output,
                isActive: sameOut ? (item.niriId === nid) : item.isActive,
                isFocused: foc ? (item.niriId === nid) : item.isFocused
            });
        }
        root.workspaces = next;
        if (foc) {
            root.activeWsId = hit.id;
            if (hit.output) root.focusMon = hit.output;
        }
        Logger.debug("Niri", `WorkspaceActivated: niriId=${nid} idx=${hit.id} focused=${foc} output=${hit.output || "?"}`);
    }

    function handleActiveWindowChanged(ev) {
        let nid = ev.workspace_id;
        if (nid === undefined) return;
        let hasWin = ev.active_window_id !== null && ev.active_window_id !== undefined;
        let cur = root.workspaces;
        let changed = false;
        let next = [];
        for (let i = 0; i < cur.length; i++) {
            let item = cur[i];
            if (item.niriId === nid && (item.windows > 0) !== hasWin) {
                changed = true;
                next.push({
                    id: item.id,
                    niriId: item.niriId,
                    windows: hasWin ? 1 : 0,
                    output: item.output,
                    isActive: item.isActive,
                    isFocused: item.isFocused
                });
            } else {
                next.push(item);
            }
        }
        // Only reassign workspaces when occupancy flips so intra-workspace focus never rebuilds the bar.
        if (changed) root.workspaces = next;
    }

    Process {
        id: initOutputs
        command: ["niri", "msg", "-j", "outputs"]
        running: root.socketPath.length > 0
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.outputs = JSON.parse(this.text);
                    Logger.debug("Niri", `Loaded ${Object.keys(root.outputs).length} outputs`);
                } catch(e) { Logger.warn("Niri", "Outputs parse error: " + e); }
            }
        }
    }

    Socket {
        id: niriStream
        path: root.socketPath
        connected: root.socketPath.length > 0

        onConnectedChanged: {
            if (connected) {
                Logger.info("Niri", "Connected to NIRI_SOCKET EventStream");
                write("\"EventStream\"\n");
                flush();
                return;
            }
            Logger.warn("Niri", "Disconnected from NIRI_SOCKET EventStream");
        }

        onError: err => Logger.warn("Niri", "Socket error: " + err)

        parser: SplitParser {
            onRead: line => {
                if (!line || line.trim().length === 0) return;
                try {
                    let ev = JSON.parse(line);
                    if (ev.WorkspacesChanged && ev.WorkspacesChanged.workspaces) {
                        root.applyWorkspaces(ev.WorkspacesChanged.workspaces);
                    } else if (ev.WorkspaceActivated) {
                        root.handleWorkspaceActivated(ev.WorkspaceActivated);
                    } else if (ev.WorkspaceActiveWindowChanged) {
                        root.handleActiveWindowChanged(ev.WorkspaceActiveWindowChanged);
                    } else if (ev.WindowFocusChanged) {
                        let wid = ev.WindowFocusChanged.id;
                        root.setFocusedWindow(wid === null || wid === undefined ? null : root.windowsById[String(wid)]);
                    } else if (ev.WindowsChanged && ev.WindowsChanged.windows) {
                        root.applyWindows(ev.WindowsChanged.windows);
                    } else if (ev.WindowOpenedOrChanged && ev.WindowOpenedOrChanged.window) {
                        root.applyWindowOpenedOrChanged(ev.WindowOpenedOrChanged.window);
                    } else if (ev.WindowClosed) {
                        root.applyWindowClosed(ev.WindowClosed.id);
                    }
                } catch(e) { Logger.warn("Niri", "Stream parse error: " + e); }
            }
        }
    }
}
