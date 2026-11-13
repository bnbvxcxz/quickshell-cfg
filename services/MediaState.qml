// MPRIS media player aggregator singleton.
// Tracks all exposed sockets, prioritizes the most recently active player, and manages playback controls.

pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell.Services.Mpris

Item {
    id: root

    property string pinId: ""
    property var activeOrder: ([])
    property int trackPos: 0
    property int trackLen: 0


    function isIgnored(p) {
        if (!p) return true;
        let id = String((p.identity || "") + " " + (p.desktopEntry || "")).toLowerCase();
        if (id.includes("discord") || id.includes("waterfox")) return true;

        let url = (p.metadata && p.metadata["xesam:url"]) ? String(p.metadata["xesam:url"]).toLowerCase() : "";
        let meta = String((p.trackTitle || "") + " " + (p.trackArtist || "") + " " + (p.trackAlbum || "")).toLowerCase();
        const hosts = ["twitter.com", "x.com", "tiktok.com", "instagram.com", "facebook.com", "threads.net", "bsky.app", "reddit.com", "snapchat.com"];
        for (let i = 0; i < hosts.length; i++) {
            if (url.includes(hosts[i]) || meta.includes(hosts[i])) return true;
        }
        return /\b(tiktok|twitter|instagram)\b/.test(id) || /\b(on x|on twitter|on tiktok)\b/.test(meta);
    }

    function hasValidTrack(p) {
        if (!p) return false;
        let t = String(p.trackTitle || "").trim();
        return t.length > 0 && p.playbackState !== MprisPlaybackState.Stopped;
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

    readonly property bool hasMedia: activePlayer !== null && cleanTitle.length > 0
    readonly property bool isPlaying: activePlayer !== null && activePlayer.playbackState === MprisPlaybackState.Playing

    function formatArtist(raw) {
        let str = String(raw || "").trim();
        if (str.length === 0) return "Media";
        if (str.toLowerCase() === "spotify") return "Spotify";
        return str.replace(/\b\w/g, c => c.toUpperCase());
    }

    readonly property string rawTitle: activePlayer ? String(activePlayer.trackTitle || "") : ""
    readonly property string cleanTitle: {
        let t = rawTitle.replace(/^\(\d+\)\s*/, "");
        return t.replace(/\s*-\s*YouTube\s*$/i, "").trim();
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
        activePlayer.togglePlaying();
    }

    function next() {
        if (activePlayer && activePlayer.canGoNext) activePlayer.next();
    }

    function previous() {
        if (activePlayer && activePlayer.canGoPrevious) activePlayer.previous();
    }

    function cycleLoop() {
        if (!activePlayer || !activePlayer.canControl) return;
        let cur = String(activePlayer.loopStatus || "None");

        if (cur.indexOf("None") !== -1 || cur === "0") activePlayer.loopStatus = "Playlist";
        else if (cur.indexOf("Playlist") !== -1 || cur === "1") activePlayer.loopStatus = "Track";
        else activePlayer.loopStatus = "None";
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

    function formatTime(sec) {
        if (isNaN(sec) || sec <= 0) return "0:00";
        let m = Math.floor(sec / 60);
        let s = Math.floor(sec % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }
}
