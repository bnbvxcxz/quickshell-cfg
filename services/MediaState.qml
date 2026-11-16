// MPRIS media player aggregator singleton.
// Tracks all exposed sockets, prioritizes the most recently active player, and manages playback controls.

pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell.Services.Mpris
import "."

Item {
    id: root

    property string pinId: ""
    property var activeOrder: ([])
    property int trackPos: 0
    property int trackLen: 0
    property int cavaBarCount: 12
    property var cavaLevels: ([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
    readonly property var ignoredHosts: ["twitter.com", "x.com", "tiktok.com", "instagram.com", "facebook.com", "threads.net", "bsky.app", "reddit.com", "snapchat.com"]


    function isIgnored(p) {
        if (!p) return true;
        let id = String((p.identity || "") + " " + (p.desktopEntry || "")).toLowerCase();
        if (id.includes("discord") || id.includes("waterfox")) return true;

        let url = (p.metadata && p.metadata["xesam:url"]) ? String(p.metadata["xesam:url"]).toLowerCase() : "";
        let meta = String((p.trackTitle || "") + " " + (p.trackArtist || "") + " " + (p.trackAlbum || "")).toLowerCase();
        for (let i = 0; i < ignoredHosts.length; i++) {
            if (url.includes(ignoredHosts[i]) || meta.includes(ignoredHosts[i])) return true;
        }
        return /\b(tiktok|twitter|instagram)\b/.test(id) || /\b(on x|on twitter|on tiktok)\b/.test(meta);
    }

    function hasValidTrack(p) {
        return !!p;
    }

    function promotePlayer(id) {
        let key = String(id || "").trim();
        if (!key) return;
        let next = [key];
        for (let i = 0; i < activeOrder.length; i++) {
            if (activeOrder[i] !== key) next.push(activeOrder[i]);
        }
        activeOrder = next;
        pinId = key;
        Logger.debug("Media", `Promoted player: ${key}`);
    }

    function selectPlayer(id) {
        promotePlayer(id);
        syncTimers();
    }

    readonly property var validPlayers: {
        if (!Mpris.players || !Mpris.players.values) return [];
        let vals = Mpris.players.values;
        let res = [];
        for (let i = 0; i < vals.length; i++) {
            if (!isIgnored(vals[i]) && hasValidTrack(vals[i])) res.push(vals[i]);
        }
        return res;
    }

    // Watch all non-ignored sockets so the latest player to start or change tracks takes priority.
    Repeater {
        model: Mpris.players ? Mpris.players.values : []

        Item {
            required property var modelData
            readonly property string pId: (modelData && modelData.identity) ? modelData.identity : ""

            Connections {
                target: modelData || null
                function onPlaybackStateChanged() {
                    if (!modelData || root.isIgnored(modelData)) return;
                    if (modelData.playbackState === MprisPlaybackState.Playing) {
                        root.promotePlayer(pId);
                        return;
                    }
                    // When the pinned player pauses or stops, yield focus to any other playing socket.
                    if (root.pinId === pId) {
                        let vals = root.validPlayers;
                        for (let i = 0; i < vals.length; i++) {
                            if (vals[i].identity !== pId && vals[i].playbackState === MprisPlaybackState.Playing) {
                                root.promotePlayer(vals[i].identity);
                                return;
                            }
                        }
                    }
                }
                function onTrackTitleChanged() {
                    if (!modelData || root.isIgnored(modelData)) {
                        if (root.pinId === pId) root.pinId = "";
                    }
                }
            }

            Component.onCompleted: {
                if (modelData && !root.isIgnored(modelData) && modelData.playbackState === MprisPlaybackState.Playing) {
                    root.promotePlayer(pId);
                }
            }
        }
    }

    readonly property var activePlayer: {
        let vals = root.validPlayers;
        if (vals.length === 0) return null;

        // Respect the most recently active/pinned socket if it is still valid.
        if (root.pinId !== "") {
            for (let i = 0; i < vals.length; i++) {
                if (vals[i].identity === root.pinId) return vals[i];
            }
        }

        // Fall back to the most recent playing socket in activeOrder.
        for (let j = 0; j < root.activeOrder.length; j++) {
            let id = root.activeOrder[j];
            for (let i = 0; i < vals.length; i++) {
                if (vals[i].identity === id && vals[i].playbackState === MprisPlaybackState.Playing) return vals[i];
            }
        }

        // Any currently playing socket, then first valid socket.
        for (let i = 0; i < vals.length; i++) {
            if (vals[i].playbackState === MprisPlaybackState.Playing) return vals[i];
        }

        return vals[0];
    }

    readonly property bool hasMedia: activePlayer !== null
    readonly property bool isPlaying: activePlayer !== null && activePlayer.playbackState === MprisPlaybackState.Playing
    readonly property bool canShuffle: !!(activePlayer && activePlayer.shuffleSupported)
    readonly property bool canLoop: !!(activePlayer && activePlayer.loopSupported)
    readonly property bool isShuffled: !!(activePlayer && activePlayer.shuffle)
    // 0: None, 1: Track (single), 2: Playlist
    readonly property int loopMode: {
        if (!activePlayer) return 0;
        if (activePlayer.loopState === MprisLoopState.Track) return 1;
        if (activePlayer.loopState === MprisLoopState.Playlist) return 2;
        return 0;
    }

    function formatArtist(raw) {
        let str = String(raw || "").trim();
        if (str.length === 0) return "Media";
        if (str.toLowerCase() === "spotify") return "Spotify";
        return str.replace(/\b\w/g, c => c.toUpperCase());
    }

    readonly property string rawTitle: activePlayer ? String(activePlayer.trackTitle || "") : ""
    readonly property string cleanTitle: {
        let t = rawTitle.replace(/^\(\d+\)\s*/, "").replace(/\s*-\s*YouTube\s*$/i, "").trim();
        if (t.length > 0) return t;
        return activePlayer ? String(activePlayer.identity || "Idle") : "";
    }

    readonly property string cleanArtist: {
        if (!activePlayer) return "";
        let a = String(activePlayer.trackArtist || "").trim();
        if (!a && activePlayer.metadata) a = String(activePlayer.metadata["xesam:albumArtist"] || activePlayer.metadata["xesam:artist"] || "").trim();
        return formatArtist(a ? a : activePlayer.identity);
    }

    readonly property string cleanAlbum: {
        if (!activePlayer) return "";
        let alb = String(activePlayer.trackAlbum || "").trim();
        if (!alb && activePlayer.metadata) alb = String(activePlayer.metadata["xesam:album"] || "").trim();
        return alb;
    }

    readonly property string displayString: {
        if (!cleanTitle) return "";
        return cleanTitle + (cleanArtist ? (" - " + cleanArtist) : "");
    }

    readonly property string artSource: {
        if (!activePlayer) return "";
        let raw = "";

        if (activePlayer.metadata) raw = activePlayer.metadata["mpris:artUrl"] || activePlayer.metadata["artUrl"] || "";
        if (!raw) raw = activePlayer.trackArtUrl || activePlayer.artUrl || "";
        if (!raw) return "";

        if (raw.indexOf("file://") === 0) {
            try { return decodeURIComponent(raw); } catch(e) { return raw; }
        }

        if (raw.indexOf("/") === 0) return "file://" + raw;
        return raw;
    }

    function togglePlay() {
        if (!activePlayer) return;
        promotePlayer(activePlayer.identity || "");
        Logger.debug("Media", `Toggle play/pause -> ${activePlayer.identity || "player"}`);
        activePlayer.togglePlaying();
    }

    function next() {
        if (!activePlayer || !activePlayer.canGoNext) return;
        Logger.debug("Media", `Next track -> ${activePlayer.identity || "player"}`);
        activePlayer.next();
    }

    function previous() {
        if (!activePlayer || !activePlayer.canGoPrevious) return;
        Logger.debug("Media", `Previous track -> ${activePlayer.identity || "player"}`);
        activePlayer.previous();
    }

    function toggleShuffle() {
        if (!activePlayer || !activePlayer.canControl || !canShuffle) return;
        activePlayer.shuffle = !activePlayer.shuffle;
        Logger.debug("Media", `Shuffle -> ${activePlayer.shuffle}`);
    }

    function cycleLoop() {
        if (!activePlayer || !activePlayer.canControl || !canLoop) return;
        if (activePlayer.loopState === MprisLoopState.None) activePlayer.loopState = MprisLoopState.Playlist;
        else if (activePlayer.loopState === MprisLoopState.Playlist) activePlayer.loopState = MprisLoopState.Track;
        else activePlayer.loopState = MprisLoopState.None;
        Logger.debug("Media", `Loop -> ${activePlayer.loopState}`);
    }

    function syncTimers() {
        if (!activePlayer) {
            trackPos = 0;
            trackLen = 0;
            return;
        }

        let rLen = 0;
        if (activePlayer.metadata && activePlayer.metadata["mpris:length"]) rLen = activePlayer.metadata["mpris:length"];
        else if (activePlayer.length) rLen = activePlayer.length;

        trackLen = rLen > 100000 ? Math.floor(rLen / 1000000) : Math.floor(rLen);

        let rPos = activePlayer.position || 0;
        let sec = rPos > 100000 ? Math.floor(rPos / 1000000) : Math.floor(rPos);
        trackPos = (sec > 0 && (trackLen === 0 || sec <= trackLen)) ? sec : 0;
    }

    Connections {
        target: root.activePlayer || null
        function onPositionChanged() { root.syncTimers() }
        function onLengthChanged() { root.syncTimers() }
        function onPlaybackStateChanged() { root.syncTimers() }
        function onMetadataChanged() { root.syncTimers() }
    }

    Timer {
        id: posTimer
        interval: 1000
        running: root.isPlaying
        repeat: true
        onTriggered: {
            if (root.trackLen > 0 && root.trackPos < root.trackLen) return root.trackPos += 1;
            root.syncTimers();
        }
    }

    readonly property string timeSummary: trackLen > 0
        ? (formatTime(trackPos) + " / " + formatTime(trackLen))
        : (isPlaying ? formatTime(trackPos) : "--:--")

    function formatTime(sec) {
        if (isNaN(sec) || sec <= 0) return "0:00";
        let m = Math.floor(sec / 60);
        let s = Math.floor(sec % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    // Single shared cava instance across all monitor bars.
    Process {
        id: cavaProc
        command: [
            "bash", "-c",
            `exec stdbuf -oL cava -p <(cat <<'EOF'
[general]
bars = ${root.cavaBarCount}
framerate = 30
autosens = 1
sleep_timer = 0
[input]
method = pulse
source = auto
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 100
EOF
) 2>/dev/null`
        ]
        running: root.isPlaying
        stdout: SplitParser {
            onRead: line => {
                let parts = line.trim().split(";").filter(v => v.length > 0);
                if (parts.length === 0) return;
                let next = [];
                for (let i = 0; i < root.cavaBarCount; i++) {
                    let v = i < parts.length ? (parseInt(parts[i]) || 0) : 0;
                    next.push(Math.max(0, Math.min(100, v)));
                }
                root.cavaLevels = next;
            }
        }
    }
}
