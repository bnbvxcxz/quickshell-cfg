// Central leveled logger singleton for services and UI modules.
// Supports error, warn, info, and debug levels via QUICKSHELL_LOG_LEVEL or IPC.

pragma Singleton
import QtQuick
import Quickshell

QtObject {
    id: root

    // 0: error, 1: warn, 2: info, 3: debug
    property int level: {
        let env = (Quickshell.env("QUICKSHELL_LOG_LEVEL") || "").toLowerCase();
        if (env === "error") return 0;
        if (env === "warn") return 1;
        if (env === "debug") return 3;
        return 2;
    }

    function setLevel(name) {
        let k = String(name || "").toLowerCase().trim();
        if (k === "error" || k === "0") level = 0;
        else if (k === "warn" || k === "1") level = 1;
        else if (k === "info" || k === "2") level = 2;
        else if (k === "debug" || k === "3") level = 3;
        info("Logger", `Log level set to ${levelName()}`);
    }

    function levelName() {
        if (level === 0) return "error";
        if (level === 1) return "warn";
        if (level === 3) return "debug";
        return "info";
    }

    function stamp() {
        return Qt.formatDateTime(new Date(), "HH:mm:ss.zzz");
    }

    function error(tag, msg) {
        if (level >= 0) console.error(`[${stamp()}] [${tag}] ${msg}`);
    }

    function warn(tag, msg) {
        if (level >= 1) console.warn(`[${stamp()}] [${tag}] ${msg}`);
    }

    function info(tag, msg) {
        if (level >= 2) console.info(`[${stamp()}] [${tag}] ${msg}`);
    }

    function debug(tag, msg) {
        if (level >= 3) console.debug(`[${stamp()}] [${tag}] ${msg}`);
    }
}
