// Central typography configuration.
// Exposes scalable font metrics, weights, and unified font style rules.

pragma Singleton
import QtQuick
import "."

Item {
    id: root

    readonly property font systemFont: Qt.application.font
    readonly property string family: systemFont.family !== "" ? systemFont.family : Theme.fontFamily

    readonly property real baseSize: systemFont.pixelSize > 0
    ? systemFont.pixelSize
    : (systemFont.pointSize > 0 ? (systemFont.pointSize * 1.333) : Theme.fontSize)

    property bool globalBold: true
    property bool globalItalic: false
    property int globalWeight: globalBold ? 700 : 400

    // Standardized weights that respect the master bold flag
    readonly property int weightRegular: globalBold ? 700 : 400
    readonly property int weightMedium: globalBold ? 700 : 500
    readonly property int weightBold: 700

    function size(scale: real): int {
        let s = (scale !== undefined && !isNaN(scale) && scale > 0) ? scale : Metrics.currentScale;
        return Math.round(baseSize * s);
    }

    function sizeSmall(scale: real): int {
        let s = (scale !== undefined && !isNaN(scale) && scale > 0) ? scale : Metrics.currentScale;
        return Math.max(8, Math.round((baseSize - 1.5) * s));
    }

    function sizeLarge(scale: real): int {
        let s = (scale !== undefined && !isNaN(scale) && scale > 0) ? scale : Metrics.currentScale;
        return Math.round((baseSize + 2) * s);
    }
}
