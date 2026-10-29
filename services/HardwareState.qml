// Hardware state management singleton.
// Interfaces with PulseAudio/PipeWire and brightnessctl with debounced OSD triggers.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property real volume: 0.5
    property bool isMuted: false
    property real brightness: 0.5

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

    Timer {
        id: inputCooldown
        interval: 350
        running: false
    }

    function setVolumePercent(val, showOsd = true) {
        let clamped = Math.max(0.0, Math.min(1.0, val));
        root.volume = clamped;
        root.isMuted = false;
        inputCooldown.restart();

        if (volProc.running) volProc.running = false;
        volProc.command = ["pactl", "set-sink-volume", "@DEFAULT_SINK@", `${Math.round(clamped * 100)}%`];
        volProc.running = true;

        if (showOsd) {
            root.osdTriggered("volume", clamped, "󰕾", false);
        }
    }

    function adjustVolume(delta, showOsd = true) {
        let step = delta > 0 ? 0.02 : -0.02;
        let target = Math.max(0.0, Math.min(1.0, root.volume + step));
        root.volume = target;
        root.isMuted = false;
        inputCooldown.restart();

        if (volProc.running) volProc.running = false;
        volProc.command = ["pactl", "set-sink-volume", "@DEFAULT_SINK@", `${Math.round(target * 100)}%`];
        volProc.running = true;

        if (showOsd) {
            root.osdTriggered("volume", target, "󰕾", false);
        }
    }

    function toggleMute(showOsd = true) {
        root.isMuted = !root.isMuted;
        inputCooldown.restart();

        if (volProc.running) volProc.running = false;
        volProc.command = ["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"];
        volProc.running = true;

        if (showOsd) {
            root.osdTriggered("volume", root.volume, root.isMuted ? "󰖁" : "󰕾", root.isMuted);
        }
    }

    Process {
        id: briProc
        running: false
    }

    function setBrightnessPercent(val, showOsd = true) {
        let clamped = Math.max(0.01, Math.min(1.0, val));
        root.brightness = clamped;
        inputCooldown.restart();

        if (briProc.running) briProc.running = false;
        briProc.command = ["brightnessctl", "set", `${Math.round(clamped * 100)}%`];
        briProc.running = true;

        if (showOsd) {
            root.osdTriggered("brightness", clamped, "󰃟", false);
        }
    }

    function adjustBrightness(delta, showOsd = true) {
        let step = delta > 0 ? 0.02 : -0.02;
        let target = Math.max(0.01, Math.min(1.0, root.brightness + step));
        root.brightness = target;
        inputCooldown.restart();

        if (briProc.running) briProc.running = false;
        briProc.command = ["brightnessctl", "set", `${Math.round(target * 100)}%`];
        briProc.running = true;

        if (showOsd) {
            root.osdTriggered("brightness", target, "󰃟", false);
        }
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
