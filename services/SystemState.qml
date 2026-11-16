// System environment state monitor.
// Uses native UPower (battery) and Quickshell.Networking (Wi-Fi/Ethernet), plus check_updates.sh.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.UPower
import "../config"
import "."

Item {
    id: root

    function simulateBattery(pct, status) {
        batTestActive = true;
        Logger.debug("System", `Simulate battery pct=${pct} status=${status || "Discharging"}`);
        setBatteryState(parseInt(pct) || 0, status || "Discharging");
    }

    function simulateWifi(ssid, signal) {
        netTestActive = true;
        Logger.debug("System", `Simulate wifi ssid=${ssid} signal=${signal}`);
        setWifiState(ssid, parseInt(signal) || 0);
    }

    function simulateEthernet(ip) {
        netTestActive = true;
        netIcon = "󰈀";
        netName = ip || "10.0.0.2/24";
        netTxt = `󰈀   ${netName}`;
        Logger.debug("System", `Simulate ethernet ip=${netName}`);
    }

    function simulateUpdates(arch, aur, flatpak) {
        updArch = parseInt(arch) || 0;
        totArch = 800;
        updAur = parseInt(aur) || 0;
        totAur = 50;
        updFlatpak = parseInt(flatpak) || 0;
        totFlatpak = 20;
        Logger.debug("System", `Simulate updates arch=${updArch} aur=${updAur} flatpak=${updFlatpak}`);
    }

    function resetSimulation() {
        batTestActive = false;
        netTestActive = false;
        Logger.debug("System", "Reset simulation to live state");
        syncUPower();
        syncNetwork();
        refreshUpdates();
    }

    property int updArch: 0
    property int totArch: 1
    property int updAur: 0
    property int totAur: 1
    property int updFlatpak: 0
    property int totFlatpak: 1

    readonly property int updCount: updArch + updAur + updFlatpak
    readonly property real archRatio: updArch / Math.max(1, totArch)
    readonly property real aurRatio: updAur / Math.max(1, totAur)
    readonly property real flatpakRatio: updFlatpak / Math.max(1, totFlatpak)

    readonly property int archState: {
        if (updArch === 0) return 0;
        if (archRatio >= 0.05) return 2;
        if (archRatio >= 0.02) return 1;
        return 0;
    }

    readonly property int aurState: {
        if (updAur === 0) return 0;
        if (aurRatio >= 0.15) return 2;
        if (aurRatio >= 0.05) return 1;
        return 0;
    }

    readonly property int flatpakState: {
        if (updFlatpak === 0) return 0;
        if (flatpakRatio >= 0.40) return 2;
        if (flatpakRatio >= 0.20) return 1;
        return 0;
    }

    readonly property int avgState: {
        if (updCount === 0) return 0;
        let avg = (archState + aurState + flatpakState) / 3.0;
        if (avg >= 1.34) return 2;
        if (avg >= 0.67) return 1;
        return 0;
    }

    property bool batTestActive: false
    property bool batPresent: false
    property int batPct: 100
    property string batStatus: "Discharging"
    property string batIco: "󰁹"
    property string batCap: "100%"
    readonly property bool isBatCharging: batStatus === "Charging" || batStatus === "Full"

    property bool netTestActive: false
    property string netIcon: "󰤭"
    property string netName: "disconnected"
    property string netTxt: "󰤭   disconnected"

    readonly property var batDev: UPower.displayDevice

    function syncUPower() {
        if (root.batTestActive) return;
        if (!batDev || !batDev.ready || !batDev.isPresent || !batDev.isLaptopBattery) {
            root.batPresent = false;
            return;
        }

        let pct = batDev.percentage <= 1.0 ? Math.round(batDev.percentage * 100) : Math.round(batDev.percentage);
        let st = "Discharging";
        if (batDev.state === UPowerDeviceState.Charging) st = "Charging";
        else if (batDev.state === UPowerDeviceState.FullyCharged) st = "Full";

        setBatteryState(pct, st);
    }

    Connections {
        target: root.batDev || null
        function onPercentageChanged() { root.syncUPower() }
        function onStateChanged() { root.syncUPower() }
        function onReadyChanged() { root.syncUPower() }
        function onIsPresentChanged() { root.syncUPower() }
    }

    function syncNetwork() {
        if (root.netTestActive) return;
        let devs = (Networking.devices && Networking.devices.values) ? Networking.devices.values : [];

        // Prefer active wired link if connected, otherwise active Wi-Fi network.
        for (let i = 0; i < devs.length; i++) {
            let d = devs[i];
            if (d && d.type === DeviceType.Wired && d.connected) {
                let nextName = d.name || "Ethernet";
                if (root.netName !== nextName || root.netIcon !== "󰈀") {
                    Logger.debug("System", `Network -> wired (${nextName})`);
                }
                root.netIcon = "󰈀";
                root.netName = nextName;
                root.netTxt = `󰈀   ${root.netName}`;
                return;
            }
        }

        for (let i = 0; i < devs.length; i++) {
            let d = devs[i];
            if (!d || d.type !== DeviceType.Wifi || !d.connected) continue;
            let nets = (d.networks && d.networks.values) ? d.networks.values : [];
            for (let j = 0; j < nets.length; j++) {
                let n = nets[j];
                if (n && n.connected) {
                    let sig = n.signalStrength <= 1.0 ? Math.round(n.signalStrength * 100) : Math.round(n.signalStrength);
                    setWifiState(n.name || "wifi", sig);
                    return;
                }
            }
            setWifiState(d.name || "wifi", 80);
            return;
        }

        setWifiState("disconnected", 0);
    }

    Connections {
        target: Networking.devices || null
        function onValuesChanged() { root.syncNetwork() }
    }

    Repeater {
        model: Networking.devices ? Networking.devices.values : []
        Item {
            required property var modelData
            Connections {
                target: modelData || null
                function onConnectedChanged() { root.syncNetwork() }
            }
            Component.onCompleted: root.syncNetwork()
        }
    }

    Component.onCompleted: {
        syncUPower();
        syncNetwork();
    }

    function setBatteryState(cap, stat) {
        let clamped = Math.max(0, Math.min(100, cap));
        if (!root.batPresent || root.batPct !== clamped || root.batStatus !== stat) {
            Logger.debug("System", `Battery -> ${clamped}% (${stat})`);
        }
        root.batPresent = true;
        root.batPct = clamped;
        root.batStatus = stat;
        root.batCap = `${clamped}%`;

        if (stat === "Charging" || stat === "Full") {
            let chg = ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"];
            root.batIco = chg[Math.min(9, Math.floor(clamped / 10))];
            return;
        }

        let icons = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"];
        root.batIco = icons[Math.min(9, Math.floor(clamped / 10))];
    }

    function setWifiState(ssid, sig) {
        let clean = String(ssid || "").trim();
        if (!clean || clean === "disconnected" || sig <= 0) {
            if (root.netName !== "disconnected") Logger.debug("System", "Network -> disconnected");
            root.netIcon = "󰤭";
            root.netName = "disconnected";
            root.netTxt = "󰤭   disconnected";
            return;
        }

        let ico = "󰤟";
        if (sig >= 75) ico = "󰤨";
        else if (sig >= 50) ico = "󰤥";
        else if (sig >= 25) ico = "󰤢";

        if (root.netName !== clean || root.netIcon !== ico) {
            Logger.debug("System", `Network -> wifi (${clean}, ${sig}%)`);
        }
        root.netIcon = ico;
        root.netName = clean;
        root.netTxt = `${ico}   ${clean}`;
    }

    function refreshUpdates() {
        if (!updProc.running) {
            Logger.debug("System", "Refreshing package updates");
            updProc.running = true;
        }
    }

    Process {
        id: updProc
        command: [Commands.checkUpdatesScript]
        running: true
        stdout: SplitParser {
            onRead: d => {
                let p = d.trim().split(":");
                if (p.length < 6) return;

                root.updArch = parseInt(p[0]) || 0;
                root.totArch = parseInt(p[1]) || 1;
                root.updAur = parseInt(p[2]) || 0;
                root.totAur = parseInt(p[3]) || 1;
                root.updFlatpak = parseInt(p[4]) || 0;
                root.totFlatpak = parseInt(p[5]) || 1;
                Logger.debug("System", `Updates arch=${root.updArch} aur=${root.updAur} flatpak=${root.updFlatpak}`);
            }
        }
        onExited: (code, status) => {
            if (code !== 0) Logger.warn("System", `check_updates.sh exited with code ${code}`);
        }
    }

    Timer {
        interval: 1800000
        running: true
        repeat: true
        onTriggered: root.refreshUpdates()
    }
}
