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

    Component {
        id: procComp
        Process {
            onExited: destroy()
        }
    }

    function runAction(args) {
        if (!root.socketPath) return;
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
                } catch(e) { Logger.warn("Niri", "Event parse error: " + e); }
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

    function applyWorkspaces(list) {
        if (!Array.isArray(list)) return;
        let mapped = [];
        for (let i = 0; i < list.length; i++) {
            let w = list[i];
            let id = w.idx !== undefined ? w.idx : (w.id || (i + 1));
            mapped.push({
                id: id,
                windows: w.active_window_id ? 1 : 0,
                output: w.output || "",
                isFocused: !!w.is_focused
            });
            if (w.is_focused) {
                root.activeWsId = id;
                if (w.output) root.focusMon = w.output;
            }
        }
        mapped.sort((a, b) => a.id - b.id);
        root.workspaces = mapped;
    }

    Process {
        id: initOutputs
        command: ["niri", "msg", "-j", "outputs"]
        running: root.socketPath.length > 0
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.outputs = JSON.parse(this.text); } catch(e) {}
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
            }
        }

        parser: SplitParser {
            onRead: line => {
                if (!line || line.trim().length === 0) return;
                try {
                    let ev = JSON.parse(line);
                    if (ev.WorkspacesChanged && ev.WorkspacesChanged.workspaces) {
                        root.applyWorkspaces(ev.WorkspacesChanged.workspaces);
                    } else if (ev.WorkspaceActivated) {
                        let id = ev.WorkspaceActivated.id;
                        if (id !== undefined) root.activeWsId = id;
                    } else if (ev.WindowFocusChanged) {
                        if (ev.WindowFocusChanged.id === null) {
                            root.activeWinTitle = "";
                            root.activeTop = null;
                        }
                    } else if (ev.WindowsChanged && ev.WindowsChanged.windows) {
                        let wins = ev.WindowsChanged.windows;
                        for (let i = 0; i < wins.length; i++) {
                            if (wins[i].is_focused) {
                                root.activeWinTitle = wins[i].title || "";
                                root.activeTop = { address: String(wins[i].id), title: root.activeWinTitle };
                                break;
                            }
                        }
                    } else if (ev.WindowOpenedOrChanged && ev.WindowOpenedOrChanged.window) {
                        let w = ev.WindowOpenedOrChanged.window;
                        if (w.is_focused) {
                            root.activeWinTitle = w.title || "";
                            root.activeTop = { address: String(w.id), title: root.activeWinTitle };
                        }
                    }
                } catch(e) {}
            }
        }
    }
}
