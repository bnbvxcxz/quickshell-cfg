// Audio and backlight slider controls.
// Composes SliderRow instances for volume and brightness with compact collapse.

import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

Item {
    id: root

    property bool isCompact: false
    property real scaleFactor: 1.0

    readonly property int sliderHeight: Math.round(34 * scaleFactor)
    readonly property int totalHeight: (sliderHeight * 2) + Math.round(6 * scaleFactor)

    Layout.fillWidth: true
    Layout.preferredHeight: isCompact ? 0 : totalHeight
    Layout.maximumHeight: isCompact ? 0 : totalHeight
    clip: true
    opacity: isCompact ? 0.0 : 1.0

    Behavior on Layout.preferredHeight { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
    Behavior on Layout.maximumHeight { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
    Behavior on opacity { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

    ColumnLayout {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Math.round(6 * root.scaleFactor)

        SliderRow {
            icon: HardwareState.volumeIcon
            value: HardwareState.volume
            label: HardwareState.isMuted ? "MUTE" : `${Math.round(HardwareState.volume * 100)}%`
            muted: HardwareState.isMuted
            minValue: 0.0
            scaleFactor: root.scaleFactor
            sliderHeight: root.sliderHeight
            onIconClicked: HardwareState.toggleMute(false)
            onValueDragged: pct => HardwareState.setVolumePercent(pct, false)
            onStepped: delta => HardwareState.adjustVolume(delta, false)
        }

        SliderRow {
            icon: HardwareState.brightnessIcon
            value: HardwareState.brightness
            label: `${Math.round(HardwareState.brightness * 100)}%`
            muted: false
            minValue: 0.01
            scaleFactor: root.scaleFactor
            sliderHeight: root.sliderHeight
            onValueDragged: pct => HardwareState.setBrightnessPercent(pct, false)
            onStepped: delta => HardwareState.adjustBrightness(delta, false)
        }
    }
}
