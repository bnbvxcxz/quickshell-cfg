// Audio and backlight slider controls.
// Handles interactive volume and brightness dragging, scrolling, and compact collapse.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"

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

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.sliderHeight
            radius: Theme.cornerRadius
            color: Qt.alpha(Theme.surface_container_high, 0.7)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Math.round(10 * root.scaleFactor)
                anchors.rightMargin: Math.round(10 * root.scaleFactor)
                spacing: Math.round(8 * root.scaleFactor)

                Text {
                    text: HardwareState.isMuted ? "󰖁" : "󰕾"
                    color: HardwareState.isMuted ? Theme.error : Theme.primary
                    font.family: Typography.family
                    font.pixelSize: Typography.size(root.scaleFactor)
                    font.bold: Typography.globalBold
                    font.weight: Typography.globalWeight
                    font.italic: Typography.globalItalic

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: HardwareState.toggleMute(false)
                    }
                }

                Item {
                    id: volTrackContainer
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.round(18 * root.scaleFactor)

                    Rectangle {
                        id: volTrack
                        anchors.centerIn: parent
                        width: parent.width
                        height: Math.max(4, Math.round(6 * root.scaleFactor))
                        radius: height / 2
                        color: Theme.surface_container_lowest

                        Rectangle {
                            width: volTrack.width * Math.max(0.0, Math.min(1.0, HardwareState.volume))
                            height: parent.height
                            radius: height / 2
                            color: HardwareState.isMuted ? Theme.outline : Theme.primary
                        }
                    }

                    Rectangle {
                        readonly property real knobDim: Math.round(12 * root.scaleFactor)
                        x: Math.max(0, Math.min(volTrackContainer.width - width, (volTrackContainer.width * HardwareState.volume) - (width / 2)))
                        anchors.verticalCenter: parent.verticalCenter
                        width: knobDim
                        height: knobDim
                        radius: knobDim / 2
                        color: Theme.primary
                        border.color: Theme.background
                        border.width: 1.5
                    }
                }

                Text {
                    text: HardwareState.isMuted ? "MUTE" : `${Math.round(HardwareState.volume * 100)}%`
                    color: HardwareState.isMuted ? Theme.error : Theme.on_surface_variant
                    font.family: Typography.family
                    font.pixelSize: Typography.sizeSmall(root.scaleFactor)
                    font.bold: Typography.globalBold
                    font.weight: Typography.globalWeight
                    font.italic: Typography.globalItalic
                    Layout.preferredWidth: Math.round(38 * root.scaleFactor)
                    horizontalAlignment: Text.AlignRight
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                preventStealing: true
                property int scrollAccumulator: 0

                function updateFromMouse(mouseX) {
                    let leadOffset = Math.round(32 * root.scaleFactor);
                    let trackWidth = width - Math.round(42 * root.scaleFactor);
                    let pct = Math.max(0.0, Math.min(1.0, (mouseX - leadOffset) / trackWidth));
                    HardwareState.setVolumePercent(pct, false);
                }

                onClicked: mouse => updateFromMouse(mouse.x)
                onPositionChanged: mouse => { if (pressed) updateFromMouse(mouse.x); }

                onWheel: wheel => {
                    scrollAccumulator += wheel.angleDelta.y;
                    let steps = Math.trunc(scrollAccumulator / 120);
                    if (steps !== 0) {
                        HardwareState.adjustVolume(steps, false);
                        scrollAccumulator -= steps * 120;
                    }
                    wheel.accepted = true;
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.sliderHeight
            radius: Theme.cornerRadius
            color: Qt.alpha(Theme.surface_container_high, 0.7)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Math.round(10 * root.scaleFactor)
                anchors.rightMargin: Math.round(10 * root.scaleFactor)
                spacing: Math.round(8 * root.scaleFactor)

                Text {
                    text: "󰃟"
                    color: Theme.primary
                    font.family: Typography.family
                    font.pixelSize: Typography.size(root.scaleFactor)
                    font.bold: Typography.globalBold
                    font.weight: Typography.globalWeight
                    font.italic: Typography.globalItalic
                }

                Item {
                    id: briTrackContainer
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.round(18 * root.scaleFactor)

                    Rectangle {
                        id: briTrack
                        anchors.centerIn: parent
                        width: parent.width
                        height: Math.max(4, Math.round(6 * root.scaleFactor))
                        radius: height / 2
                        color: Theme.surface_container_lowest

                        Rectangle {
                            width: briTrack.width * Math.max(0.0, Math.min(1.0, HardwareState.brightness))
                            height: parent.height
                            radius: height / 2
                            color: Theme.primary
                        }
                    }

                    Rectangle {
                        readonly property real knobDim: Math.round(12 * root.scaleFactor)
                        x: Math.max(0, Math.min(briTrackContainer.width - width, (briTrackContainer.width * HardwareState.brightness) - (width / 2)))
                        anchors.verticalCenter: parent.verticalCenter
                        width: knobDim
                        height: knobDim
                        radius: knobDim / 2
                        color: Theme.primary
                        border.color: Theme.background
                        border.width: 1.5
                    }
                }

                Text {
                    text: `${Math.round(HardwareState.brightness * 100)}%`
                    color: Theme.on_surface_variant
                    font.family: Typography.family
                    font.pixelSize: Typography.sizeSmall(root.scaleFactor)
                    font.bold: Typography.globalBold
                    font.weight: Typography.globalWeight
                    font.italic: Typography.globalItalic
                    Layout.preferredWidth: Math.round(38 * root.scaleFactor)
                    horizontalAlignment: Text.AlignRight
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                preventStealing: true
                property int scrollAccumulator: 0

                function updateFromMouse(mouseX) {
                    let leadOffset = Math.round(32 * root.scaleFactor);
                    let trackWidth = width - Math.round(42 * root.scaleFactor);
                    let pct = Math.max(0.01, Math.min(1.0, (mouseX - leadOffset) / trackWidth));
                    HardwareState.setBrightnessPercent(pct, false);
                }

                onClicked: mouse => updateFromMouse(mouse.x)
                onPositionChanged: mouse => { if (pressed) updateFromMouse(mouse.x); }

                onWheel: wheel => {
                    scrollAccumulator += wheel.angleDelta.y;
                    let steps = Math.trunc(scrollAccumulator / 120);
                    if (steps !== 0) {
                        HardwareState.adjustBrightness(steps, false);
                        scrollAccumulator -= steps * 120;
                    }
                    wheel.accepted = true;
                }
            }
        }
    }
}
