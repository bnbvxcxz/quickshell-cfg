// MPRIS media player aggregator singleton.
// Manages player discovery, track metadata sanitation, artwork resolution, and playback controls.

pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell.Services.Mpris

Item {
    id: root

    property string pinnedPlayerId: ""
    property int trackPos: 0
    property int trackLen: 0

    function isIgnored(p) {
        if (!p) return true;
        let id = String((p.identity || "") + " " + (p.desktopEntry || "")).toLowerCase();
        return id.includes("firefox") ||
        id.includes("waterfox") ||
        id.includes("chromium") ||
        id.includes("chrome") ||
        id.includes("brave") ||
        id.includes("discord");
    }

    function hasValidTrack(p) {
        if (!p) return false;
        let t = String(p.trackTitle || "").trim();
        return t.length > 0 && p.playbackState !== MprisPlaybackState.Stopped;
    }

    readonly property var activePlayer: {
        if (!Mpris.players || Mpris.players.values.length === 0) return null;
        let list = Mpris.players.values;

        for (let i = 0; i < list.length; i++) {
            let p = list[i];
            if (!isIgnored(p) && hasValidTrack(p) && p.playbackState === MprisPlaybackState.Playing) return p;
        }

        if (root.pinnedPlayerId !== "") {
            for (let i = 0; i < list.length; i++) {
                let p = list[i];
                if (!isIgnored(p) && p.identity === root.pinnedPlayerId && hasValidTrack(p)) return p;
            }
        }

        for (let i = 0; i < list.length; i++) {
            let p = list[i];
            if (!isIgnored(p) && hasValidTrack(p)) return p;
        }

        return null;
    }

    readonly property bool hasMedia: activePlayer !== null && cleanTitle.length > 0
    readonly property bool isPlaying: activePlayer !== null && activePlayer.playbackState === MprisPlaybackState.Playing

    function formatArtist(raw) {
        let str = String(raw || "").trim();
        if (str.length === 0) return "Media";
        let lower = str.toLowerCase();
        if (lower === "spotify") return "Spotify";
        return str.replace(/\b\w/g, c => c.toUpperCase());
    }

    readonly property string rawTitle: activePlayer ? String(activePlayer.trackTitle || "") : ""
    readonly property string cleanTitle: {
        let t = rawTitle.replace(/^\(\d+\)\s*/, "");
        return t.replace(/\s*-\s*YouTube\s*$/i, "").trim();
    }

    readonly property string cleanArtist: {
        if (!activePlayer) return "";
        let artist = String(activePlayer.trackArtist || "").trim();
        if (!artist && activePlayer.metadata) {
            artist = String(activePlayer.metadata["xesam:albumArtist"] || activePlayer.metadata["xesam:artist"] || "").trim();
        }
        return formatArtist(artist ? artist : activePlayer.identity);
    }

    readonly property string cleanAlbum: {
        if (!activePlayer) return "";
        let alb = String(activePlayer.trackAlbum || "").trim();
        if (!alb && activePlayer.metadata) {
            alb = String(activePlayer.metadata["xesam:album"] || "").trim();
        }
        return alb;
    }

    readonly property string displayString: {
        if (!cleanTitle) return "";
        return cleanTitle + (cleanArtist ? (" - " + cleanArtist) : "");
    }

    readonly property string compactDisplayString: {
        if (!cleanTitle) return "No Media Active";
        let str = cleanTitle;
        if (cleanArtist) str += " • " + cleanArtist;
        if (cleanAlbum && cleanAlbum !== cleanTitle) str += " [" + cleanAlbum + "]";
        return str;
    }

    readonly property string artSource: {
        if (!activePlayer) return "";
        let raw = "";
        if (activePlayer.metadata) {
            raw = activePlayer.metadata["mpris:artUrl"] || activePlayer.metadata["artUrl"] || "";
        }
        if (!raw) {
            raw = activePlayer.trackArtUrl || activePlayer.artUrl || "";
        }
        if (!raw) return "";

        if (raw.indexOf("file://") === 0) {
            try { return decodeURIComponent(raw); } catch(e) { return raw; }
        } else if (raw.indexOf("/") === 0) {
            return "file://" + raw;
        }
        return raw;
    }

    function togglePlay() {
        if (activePlayer) {
            pinnedPlayerId = activePlayer.identity || "";
            activePlayer.togglePlaying();
        }
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

        let rawLen = 0;
        if (activePlayer.metadata && activePlayer.metadata["mpris:length"]) {
            rawLen = activePlayer.metadata["mpris:length"];
        } else if (activePlayer.length) {
            rawLen = activePlayer.length;
        }
        trackLen = rawLen > 100000 ? Math.floor(rawLen / 1000000) : Math.floor(rawLen);

        let rawPos = activePlayer.position || 0;
        let sec = rawPos > 100000 ? Math.floor(rawPos / 1000000) : Math.floor(rawPos);
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
            if (root.trackLen > 0 && root.trackPos < root.trackLen) {
                root.trackPos += 1;
            } else {
                root.syncTimers();
            }
        }
    }

    function formatTime(sec) {
        if (isNaN(sec) || sec <= 0) return "0:00";
        let m = Math.floor(sec / 60);
        let s = Math.floor(sec % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }
}
