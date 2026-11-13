// Hardware state management singleton.
// Uses native PipeWire bindings for audio/mic and brightnessctl for display backlight.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Item {
    id: root

    IpcHandler {
        target: "hw"
        function volUp() { root.adjustVolume(1) }
        function volDown() { root.adjustVolume(-1) }
        function volMute() { root.toggleMute() }
        function briUp() { root.adjustBrightness(1) }
        function briDown() { root.adjustBrightness(-1) }
        function micMute() { root.toggleMicMute() }
        function capsToggle() { root.toggleCaps() }
    }

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    readonly property real volume: (sink && sink.audio) ? Math.max(0.0, Math.min(1.0, sink.audio.volume)) : 0.0
    readonly property bool isMuted: (sink && sink.audio) ? !!sink.audio.muted : false
    readonly property bool isMicMuted: (source && source.audio) ? !!source.audio.muted : false

    property real brightness: 0.5
    property bool isCapsOn: false

    signal osdTriggered(string type, real value, string icon, bool muted)

    function triggerOsd(type, value, icon, muted) {
        root.osdTriggered(type, value, icon, muted);
    }

    readonly property string volumeIcon: {
        if (root.isMuted || root.volume <= 0.0) return "󰖁";
        if (root.volume < 0.34) return "󰕿";
        if (root.volume < 0.67) return "󰖀";
        return "󰕾";
    }

    readonly property string brightnessIcon: {
        if (root.brightness < 0.34) return "󰃞";
        if (root.brightness < 0.67) return "󰃟";
        return "󰃠";
    }

    Component {
        id: cmdComp
        Process {
            onExited: destroy()
        }
    }

    Process {
        id: cmdRunner
        running: false
    }

    function runCmd(cmd) {
        if (!cmd) return;
        let args = Array.isArray(cmd) ? cmd : ["bash", "-c", cmd];
        if (!cmdRunner.running) {
            cmdRunner.command = args;
            cmdRunner.running = true;
            return;
        }
        cmdComp.createObject(root, { command: args, running: true });
    }

    Process {
        id: briProc
        running: false
    }

    Timer {
        id: inputCooldown
        interval: 350
        running: false
    }

    property real lastBri: -1

    Timer {
        id: briSyncTimer
        interval: 16
        running: false
        repeat: false
        onTriggered: {
            if (root.brightness === root.lastBri) return;
            if (briProc.running) return briSyncTimer.restart();
            root.lastBri = root.brightness;
            let pct = Math.max(1, Math.min(100, Math.round(root.brightness * 100)));
            briProc.command = ["brightnessctl", "set", `${pct}%`];
            briProc.running = true;
        }
    }

    function setVolumePercent(val, show = true) {
        if (!sink || !sink.audio) return;
        let clamped = Math.max(0.0, Math.min(1.0, val));
        sink.audio.volume = clamped;
        if (sink.audio.muted && clamped > 0.0) sink.audio.muted = false;
        if (show) root.osdTriggered("volume", clamped, root.volumeIcon, false);
    }

    function adjustVolume(delta, show = true) {
        if (!delta || !sink || !sink.audio) return;
        let cur = Math.round(root.volume * 100);
        let dir = delta > 0 ? 1 : -1;
        let count = Math.max(1, Math.abs(Math.trunc(delta)));

        for (let i = 0; i < count; i++) {
            if (dir > 0) {
                cur = cur < 2 ? 2 : Math.min(100, cur + (cur % 2 !== 0 ? 1 : 2));
            } else {
                cur = cur <= 2 ? 0 : Math.max(0, cur - (cur % 2 !== 0 ? 1 : 2));
            }
        }

        let next = cur / 100.0;
        sink.audio.volume = next;
        if (sink.audio.muted && cur > 0) sink.audio.muted = false;
        if (show) root.osdTriggered("volume", next, root.volumeIcon, sink.audio.muted);
    }

    function toggleMute(show = true) {
        if (!sink || !sink.audio) return;
        sink.audio.muted = !sink.audio.muted;
        if (show) root.osdTriggered("volume", root.volume, root.volumeIcon, sink.audio.muted);
    }

    function setBrightnessPercent(val, show = true) {
        let pct = Math.max(1, Math.min(100, Math.round(val * 100)));
        root.brightness = pct / 100.0;
        inputCooldown.restart();
        briSyncTimer.restart();
        if (show) root.osdTriggered("brightness", root.brightness, root.brightnessIcon, false);
    }

    function adjustBrightness(delta, show = true) {
        if (!delta) return;
        let cur = Math.max(1, Math.min(100, Math.round(root.brightness * 100)));
        let dir = delta > 0 ? 1 : -1;
        let count = Math.max(1, Math.abs(Math.trunc(delta)));

        // Steps by 1% between 1% and 2%, and by 2% across 2%..100% so backlight never hits 0%.
        for (let i = 0; i < count; i++) {
            if (dir > 0) {
                if (cur < 2) cur = 2;
                else if (cur % 2 !== 0) cur = Math.min(100, cur + 1);
                else cur = Math.min(100, cur + 2);
            } else {
                if (cur <= 2) cur = 1;
                else if (cur % 2 !== 0) cur = Math.max(2, cur - 1);
                else cur = Math.max(2, cur - 2);
            }
        }

        root.brightness = cur / 100.0;
        inputCooldown.restart();
        briSyncTimer.restart();
        if (show) root.osdTriggered("brightness", root.brightness, root.brightnessIcon, false);
    }

    function toggleMicMute(show = true) {
        if (!source || !source.audio) return;
        source.audio.muted = !source.audio.muted;
        if (show) root.osdTriggered("microphone", 1.0, source.audio.muted ? "󰍭" : "󰍬", source.audio.muted);
    }

    function toggleCaps() {
        root.isCapsOn = !root.isCapsOn;
        root.osdTriggered("capslock", root.isCapsOn ? 1.0 : 0.0, "󰪛", false);
    }

    property string briFile: ""
    property int briMax: 100

    // Discover the first sysfs backlight device once at startup so FileView watches changes event-driven.
    Process {
        id: briPathProbe
        command: ["bash", "-c", 'd=$(ls -d /sys/class/backlight/* 2>/dev/null | head -n1); if [ -n "$d" ]; then echo "$d/brightness:$(cat "$d/max_brightness" 2>/dev/null || echo 100)"; fi']
        running: true
        stdout: SplitParser {
            onRead: line => {
                let idx = line.lastIndexOf(":");
                if (idx <= 0) return;
                root.briFile = line.slice(0, idx).trim();
                root.briMax = Math.max(1, parseInt(line.slice(idx + 1).trim()) || 100);
            }
        }
    }

    FileView {
        id: briWatcher
        path: root.briFile
        watchChanges: root.briFile.length > 0
        onFileChanged: reload()
        onLoaded: {
            if (inputCooldown.running) return;
            let raw = parseInt(text().trim());
            if (!isNaN(raw)) {
                root.brightness = Math.max(0.01, Math.min(1.0, raw / root.briMax));
                root.lastBri = root.brightness;
            }
        }
    }
}
