// Central dynamic scaling and UI geometry constants.
// Computes layout scaling from physical display dimensions and compositor scale.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "."

Item {
    id: root

    readonly property real baseResolutionHeight: 1200.0

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

    readonly property real currentScale: scaleFor(Hyprland.focusedMonitor)

    readonly property int barHeight: Math.round(Theme.baseBarHeight * currentScale)
    readonly property int pillRadius: Math.round(barHeight / 2)
    readonly property int pillPadding: Math.round(Theme.basePillPadding * currentScale)
    readonly property int pillSpacing: Math.round(Theme.baseSpacing * currentScale)
    readonly property int trayIconSize: Math.max(16, Math.round(barHeight - (5 * currentScale)))

    readonly property int drawerWidth: Math.round(Theme.baseDrawerWidth * currentScale)
    readonly property int drawerHeight: Math.round(Theme.baseDrawerHeight * currentScale)

    function scaled(value, scale) {
        return Math.round(value * (scale || currentScale));
    }
}
