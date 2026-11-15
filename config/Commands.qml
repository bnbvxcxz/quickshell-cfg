// Central external commands and resolved script paths.
// Keeps app launchers and script paths configurable in one place.

pragma Singleton
import QtQuick

QtObject {
    id: root

    readonly property string terminal: "kitty"
    readonly property string mixer: "pavucontrol"

    readonly property string scriptsDir: Qt.resolvedUrl("../scripts").toString().replace(/^file:\/\//, "")
    readonly property string checkUpdatesScript: scriptsDir + "/check_updates.sh"
    readonly property string updateScript: scriptsDir + "/update.sh"
}
