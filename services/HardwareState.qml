
// Hardware state management singleton.
// Interfaces with PulseAudio/PipeWire and brightnessctl with debounced OSD triggers.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    IpcHandler {
        target: "hw"
        function volUp()   { root.adjustVolume(1) }
        function volDown() { root.adjustVolume(-1) }
        function volMute() { root.toggleMute() }
        function briUp()   { root.adjustBrightness(1) }
        function briDown() { root.adjustBrightness(-1) }
        function micMute() { root.toggleMicMute() }
        function capsToggle() { root.toggleCaps() }
    }

    property real volume: 0.5
    property bool isMuted: false
    property real brightness: 0.5
    property bool isCapsOn: false

    signal osdTriggered(string type, real value, string icon, bool muted)

    Process {
        id: cmdRunner
        running: false
    }

    function runCmd(cmd) {
        cmdRunner.command = Array.isArray(cmd) ? cmd : ["bash", "-c", cmd];
        cmdRunner.running = true;
    }

    Process {
        id: volProc
        running: false
    }

    Process {
        id: briProc
        running: false
    }

    property real _lastAppliedVolume: -1
    property real _lastAppliedBrightness: -1

    // Safely syncs hardware state at 60Hz without interrupting active processes
    Timer {
        id: hardwareSyncTimer
        interval: 16
        running: true
        repeat: true
        onTriggered: {
            if (root.volume !== _lastAppliedVolume && !volProc.running) {
                _lastAppliedVolume = root.volume;
                volProc.command = ["pactl", "set-sink-volume", "@DEFAULT_SINK@", `${Math.round(root.volume * 100)}%`];
                volProc.running = true;
            }
            if (root.brightness !== _lastAppliedBrightness && !briProc.running) {
                _lastAppliedBrightness = root.brightness;
                briProc.command = ["brightnessctl", "set", `${Math.round(root.brightness * 100)}%`];
                briProc.running = true;
            }
        }
    }

    function setVolumePercent(val, showOsd = true) {
        root.volume = Math.max(0.0, Math.min(1.0, val));
        root.isMuted = false;
        inputCooldown.restart();
        if (showOsd) root.osdTriggered("volume", root.volume, "弊", false);
    }

    function adjustVolume(delta, showOsd = true) {
        let step = delta > 0 ? 0.02 : -0.02;
        root.volume = Math.max(0.0, Math.min(1.0, root.volume + step));
        root.isMuted = false;
        inputCooldown.restart();
        if (showOsd) root.osdTriggered("volume", root.volume, "弊", false);
    }

    function toggleMute(showOsd = true) {
        root.isMuted = !root.isMuted;
        inputCooldown.restart();
        _lastAppliedVolume = -1; // Force a re-sync on the next scroll

        if (volProc.running) volProc.running = false;
        volProc.command = ["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"];
        volProc.running = true;

        if (showOsd) root.osdTriggered("volume", root.volume, root.isMuted ? "磨" : "弊", root.isMuted);
    }

    function setBrightnessPercent(val, showOsd = true) {
        root.brightness = Math.max(0.01, Math.min(1.0, val));
        inputCooldown.restart();
        if (showOsd) root.osdTriggered("brightness", root.brightness, "Α", false);
    }

    function adjustBrightness(delta, showOsd = true) {
        let step = delta > 0 ? 0.02 : -0.02;
        root.brightness = Math.max(0.01, Math.min(1.0, root.brightness + step));
        inputCooldown.restart();
        if (showOsd) root.osdTriggered("brightness", root.brightness, "Α", false);
    }
    
    property bool isMicMuted: false

    function toggleMicMute(showOsd = true) {
        root.isMicMuted = !root.isMicMuted;

        root.runCmd(["pactl", "set-source-mute", "@DEFAULT_SOURCE@", "toggle"]);

        if (showOsd) {
            root.osdTriggered("microphone", 1.0, root.isMicMuted ? "󰍭" : "󰍬", root.isMicMuted);
        }
    }

    function toggleCaps() {
        root.isCapsOn = !root.isCapsOn;
        root.osdTriggered("capslock", root.isCapsOn ? 1.0 : 0.0, "󰪛", false);
    }

    Process {
        id: volQuery
        command: ["bash", "-c", "pactl get-sink-volume @DEFAULT_SINK@ | head -n1 | awk '{print $5}' | tr -d '%'; pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}'"]
        running: true
        stdout: SplitParser {
            property var lines: []
            onRead: line => {
                lines.push(line.trim());
                if (lines.length >= 2) {
                    if (!inputCooldown.running) {
                        root.volume = (parseInt(lines[0]) || 0) / 100.0;
                        root.isMuted = (lines[1] === "yes");
                    }
                    lines = [];
                }
            }
        }
    }

    Process {
        id: briQuery
        command: ["brightnessctl", "-m"]
        running: true
        stdout: SplitParser {
            onRead: out => {
                let parts = out.trim().split(",");
                if (parts.length >= 4 && !inputCooldown.running) {
                    let val = parseInt(parts[3]) || 0;
                    root.brightness = val / 100.0;
                }
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            if (!inputCooldown.running) {
                if (!volProc.running) volQuery.running = true;
                if (!briProc.running) briQuery.running = true;
            }
        }
    }
}
