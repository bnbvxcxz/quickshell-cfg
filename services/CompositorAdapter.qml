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
    // [ANCHOR:SAFE_MONITOR_STRING]
    readonly property string focusedMonitorName: (Hyprland.focusedMonitor && typeof Hyprland.focusedMonitor.name === "string") ? Hyprland.focusedMonitor.name : ""
    readonly property var activeToplevel: Hyprland.activeToplevel
    // [ANCHOR:SAFE_TITLE_STRING]
    readonly property string activeWindowTitle: (activeToplevel && typeof activeToplevel.title === "string") ? activeToplevel.title : ""
    readonly property var monitors: (Hyprland.monitors && Hyprland.monitors.values) ? Hyprland.monitors.values : []

    function dispatchWorkspace(id) {
        Hyprland.dispatch(`workspace ${id}`);
    }

    // [ANCHOR:SCREEN_LOGIC]
    function resolveMode(monName) {
        if (!monName) return 0;
        let mons = CompositorAdapter.monitors;
        if (mons && mons.length > 0) {
            for (let i = 0; i < mons.length; i++) {
                let m = mons[i];
                if (m && m.name === monName) {
                    if (m.x < 0) return 2; // auto-left (-x)
                    if (m.x > 0) return 1; // auto-right (+x)
                    return 0;              // 0x0 reference
                }
            }
        }
        return 0;
    }
}
