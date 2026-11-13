// Compositor ABI facade.
// Dynamically loads only the active compositor backend (Niri, Hyprland, etc.) via Loader.

pragma Singleton
import QtQuick
import Quickshell

Item {
    id: root

    readonly property string compositor: {
        if (Quickshell.env("NIRI_SOCKET")) return "niri";
        return "hyprland";
    }

    Loader {
        id: backendLoader
        source: Qt.resolvedUrl(`backends/${root.compositor === "niri" ? "NiriBackend.qml" : "HyprlandBackend.qml"}`)
    }

    readonly property var backend: backendLoader.item

    readonly property int activeWsId: backend ? backend.activeWsId : 1
    readonly property string focusMon: backend ? backend.focusMon : ""
    readonly property var activeTop: backend ? backend.activeTop : null
    readonly property string activeWinTitle: backend ? backend.activeWinTitle : ""
    readonly property var workspaces: backend ? backend.workspaces : []

    function dispatchWorkspace(id) { if (backend) backend.dispatchWorkspace(id); }
    function stepWorkspace(dir) { if (backend) backend.stepWorkspace(dir); }
    function focusApp(appName, desktopEntry) { if (backend) backend.focusApp(appName, desktopEntry); }
    function resolveMode(name) { return backend ? backend.resolveMode(name) : 0; }
}
