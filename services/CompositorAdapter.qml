// Compositor abstraction layer.
// Decouples window manager IPC calls from UI components.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
    id: root

    readonly property var activeWorkspace: Hyprland.focusedWorkspace
    readonly property int activeWorkspaceId: activeWorkspace ? activeWorkspace.id : 1
    readonly property string focusedMonitorName: (Hyprland.focusedMonitor && Hyprland.focusedMonitor.name) ? Hyprland.focusedMonitor.name : ""
    readonly property var activeToplevel: Hyprland.activeToplevel
    readonly property string activeWindowTitle: (activeToplevel && activeToplevel.title) ? activeToplevel.title : ""
    readonly property var monitors: (Hyprland.monitors && Hyprland.monitors.values) ? Hyprland.monitors.values : []

    function dispatchWorkspace(id) {
        Hyprland.dispatch(`workspace ${id}`);
    }

    function isScreenPrimary(screenObj) {
        if (!screenObj || !screenObj.name) return true;
        let mons = root.monitors;
        if (!mons || mons.length === 0) return true;

        for (let i = 0; i < mons.length; i++) {
            let m = mons[i];
            if (m && m.name === screenObj.name) {
                return (m.x === 0 && m.y === 0);
            }
        }
        return true;
    }
}
