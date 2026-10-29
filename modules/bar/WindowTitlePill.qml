// Status bar active window title indicator.
// Formats active application titles and resolves browser display icons.

import QtQuick
import "../../config"
import "../../services"
import "../../components"

Pill {
    id: root

    readonly property string fullTitle: CompositorAdapter.activeWindowTitle
    visible: fullTitle.length > 0

    readonly property string displayIcon: {
        let t = root.fullTitle;
        if (t.includes("Mozilla Firefox") || t.includes("Waterfox")) return "🌎";
        return "󱂬";
    }

    readonly property string cleanTitle: {
        let t = root.fullTitle;
        if (t.includes(" — Mozilla Firefox")) return t.replace(" — Mozilla Firefox", "");
        if (t.includes(" — Waterfox")) return t.replace(" — Waterfox", "");
        return t;
    }

    Pill.Icon {
        text: root.displayIcon
        scaleFactor: root.scaleFactor
    }

    Pill.Label {
        text: root.cleanTitle
        elide: Text.ElideRight
        width: Math.min(implicitWidth, Metrics.scaled(450, root.scaleFactor))
        scaleFactor: root.scaleFactor
    }
}
