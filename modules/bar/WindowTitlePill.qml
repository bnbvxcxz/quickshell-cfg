// Status bar active window title indicator.
// Enforces character and pixel width caps so long titles never overflow into side modules.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../components"

Pill {
    id: root

    clickable: false
    wheelEnabled: false
    property int maxChars: 96
    property real maxPixelWidth: Metrics.scaled(560, root.scaleFactor)

    readonly property string fullTitle: CompositorAdapter.activeWinTitle
    visible: fullTitle.length > 0

    readonly property string displayIcon: {
        let t = root.fullTitle;
        if (t.includes("Mozilla Firefox") || t.includes("Waterfox")) return "🌎";
        return "󱂬";
    }

    readonly property string cleanTitle: {
        let t = root.fullTitle
            .replace(/\s*[—–-]\s*(Mozilla Firefox|Waterfox|Google Chrome|Chromium|Brave)\s*$/i, "")
            .trim();
        if (t.length === 0) t = root.fullTitle.trim();
        if (t.length > root.maxChars) return t.slice(0, root.maxChars - 1).replace(/\s+$/, "") + "…";
        return t;
    }

    Pill.Icon {
        text: root.displayIcon
        scaleFactor: root.scaleFactor
    }

    Pill.Label {
        text: root.cleanTitle
        elide: Text.ElideRight
        width: Math.min(implicitWidth, Math.max(Metrics.scaled(120, root.scaleFactor), root.maxPixelWidth))
        Layout.maximumWidth: Math.max(Metrics.scaled(120, root.scaleFactor), root.maxPixelWidth)
        scaleFactor: root.scaleFactor
    }
}
