// Main layout, spacing, corner, and opacity config, plus per-monitor DPI scaling.
// Edit the tokens at the top to customize the bar and drawer without touching Matugen's Theme.qml.

pragma Singleton
import QtQuick
import Quickshell
import "../services"
import "."

Item {
    id: root
    // --- Bar & module shape ---
    // -1 gives full capsule pills; 0 gives sharp square boxes; 4+ gives rounded boxes.
    readonly property int moduleRadius: -1
    readonly property int moduleBorderWidth: 0
    readonly property color moduleBorderColor: Theme.outline_variant
    // Corner radius for drawers, notification cards, and popups.
    readonly property int cornerRadius: 10

    // --- Bar gaps & sizing (pre-DPI scaling) ---
    readonly property int baseBarHeight: 22
    readonly property int baseModulePadding: 6   // inner left/right padding inside each module
    readonly property int baseModuleGapX: 4      // horizontal gap between bar modules
    readonly property int baseModuleGapY: 0      // top/bottom inset inside the bar (0 = full bar height)
    readonly property int baseBarMarginX: 2      // outer left/right margin at screen edges
    readonly property int baseSpacing: 4         // gap between icon and text inside a module

    // --- Control center dimensions (pre-DPI scaling) ---
    readonly property int baseDrawerWidth: 360
    readonly property int baseDrawerHeight: 600

    // --- Surface & widget opacities (0.0 to 1.0) ---
    readonly property real barOpacity: 0.7
    readonly property real drawerOpacity: 0.85
    readonly property real cardOpacity: 0.65
    readonly property real cardHighOpacity: 0.7
    readonly property real toastOpacity: 0.92
    readonly property real chipOpacity: 0.8
    readonly property real subtleOutlineOpacity: 0.45
    readonly property real trayItemOpacity: 0.5
    readonly property real trayHoverOpacity: 0.25

    function scaleFor(screenObj) {
        if (!screenObj) return 1.0;

        let pxW = screenObj.width || (screenObj.geometry ? screenObj.geometry.width : 1920);
        let pxH = screenObj.height || (screenObj.geometry ? screenObj.geometry.height : 1080);

        let physW = (screenObj.physicalSize && screenObj.physicalSize.width > 0)
            ? screenObj.physicalSize.width
            : (pxW * 0.264583);
        let physH = (screenObj.physicalSize && screenObj.physicalSize.height > 0)
            ? screenObj.physicalSize.height
            : (pxH * 0.264583);

        let diagInches = Math.sqrt(Math.pow(physW, 2) + Math.pow(physH, 2)) / 25.4;
        if (diagInches <= 0 || isNaN(diagInches)) return 1.0;

        let diagPx = Math.sqrt(Math.pow(pxW, 2) + Math.pow(pxH, 2));
        let ppi = diagPx / diagInches;

        let compScale = screenObj.scale || 1.0;
        let rawScale = (ppi / 100.0) / compScale;

        return Math.max(0.85, Math.min(2.4, Math.round(rawScale * 100) / 100));
    }

    readonly property real currentScale: {
        let mon = CompositorAdapter.focusMon;
        let screens = Quickshell.screens;
        for (let i = 0; i < screens.length; i++) {
            if (screens[i] && screens[i].name === mon) return scaleFor(screens[i]);
        }
        return screens.length > 0 ? scaleFor(screens[0]) : 1.0;
    }

    function scaled(value, scale) {
        return Math.round(value * (scale || currentScale));
    }
}
