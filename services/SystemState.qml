// System environment state monitor.
// Aggregates pending package updates, power metrics, and network interfaces.

pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: root

    property int updatesArch: 0
    property int totalArch: 1
    property int updatesAur: 0
    property int totalAur: 1
    property int updatesFlatpak: 0
    property int totalFlatpak: 1

    readonly property int updateCount: updatesArch + updatesAur + updatesFlatpak

    // Raw Outdated Ratios per source
    readonly property real archRatio: updatesArch / Math.max(1, totalArch)
    readonly property real aurRatio: updatesAur / Math.max(1, totalAur)
    readonly property real flatpakRatio: updatesFlatpak / Math.max(1, totalFlatpak)

    // Sane threshold percentages per source:
    // Arch Repos (core system): 2% is noticeable (~20+ pkgs), 5% is bad bad (~50+ pkgs)
    readonly property int archState: {
        if (updatesArch === 0) return 0;
        if (archRatio >= 0.05) return 2;
        if (archRatio >= 0.02) return 1;
        return 0;
    }

    // AUR (user tools): 5% is noticeable, 15% is bad bad
    readonly property int aurState: {
        if (updatesAur === 0) return 0;
        if (aurRatio >= 0.15) return 2;
        if (aurRatio >= 0.05) return 1;
        return 0;
    }

    // Flatpaks (bundled apps): 20% is noticeable, 40% is bad bad
    readonly property int flatpakState: {
        if (updatesFlatpak === 0) return 0;
        if (flatpakRatio >= 0.40) return 2;
        if (flatpakRatio >= 0.20) return 1;
        return 0;
    }

    // Active color tier derived from the average of all 3 states (0 = low, 1 = noticeable, 2 = critical)
    readonly property int averagedState: {
        if (updateCount === 0) return 0;
        let avg = (archState + aurState + flatpakState) / 3.0;
        if (avg >= 1.34) return 2;      // bad bad
        if (avg >= 0.67) return 1;      // noticeable
        return 0;                       // whatever
    }

    property string batIcon: "󰂀"
    property string batCapacity: "100%"
    property string netText: "󰈀   connecting"

    Process {
        id: updateProc
        command: ["bash", "-c", "$HOME/.config/quickshell/scripts/check_updates.sh"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let p = data.trim().split(":");
                if (p.length >= 6) {
                    root.updatesArch = parseInt(p[0]) || 0;
                    root.totalArch = parseInt(p[1]) || 1;
                    root.updatesAur = parseInt(p[2]) || 0;
                    root.totalAur = parseInt(p[3]) || 1;
                    root.updatesFlatpak = parseInt(p[4]) || 0;
                    root.totalFlatpak = parseInt(p[5]) || 1;
                }
            }
        }
    }

    Timer {
        interval: 1800000
        running: true
        repeat: true
        onTriggered: updateProc.running = true
    }

    Process {
        id: batProc
        command: [
            "bash", "-c",
            "echo $(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1):$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1)"
        ]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let line = data.trim();
                if (!line.includes(":")) return;
                let parts = line.split(":");
                let cap = parseInt(parts[0]) || 0;
                let status = parts[1] || "";

                root.batCapacity = `${cap}%`;
                if (status === "Charging") {
                    root.batIcon = "󰂄";
                } else {
                    let icons = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"];
                    let idx = Math.min(9, Math.max(0, Math.floor(cap / 10)));
                    root.batIcon = icons[idx];
                }
            }
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: batProc.running = true
    }

    Process {
        id: netProc
        command: [
            "bash", "-c",
            "iface=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $5; exit}'); if [ -z \"$iface\" ]; then echo '󰤭   disconnected'; elif [[ \"$iface\" == wl* ]]; then ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2); echo \"󰤨   ${ssid:-wifi}\"; else ipcidr=$(ip -4 addr show \"$iface\" 2>/dev/null | grep -oP '(?<=inet\\s)\\d+(\\.\\d+){3}/\\d+'); echo \"󰈀   ${ipcidr:-ethernet}\"; fi"
        ]
        running: true
        stdout: SplitParser {
            onRead: out => {
                if (out.trim().length > 0) root.netText = out.trim();
            }
        }
    }

    Timer {
        interval: 12000
        running: true
        repeat: true
        onTriggered: netProc.running = true
    }
}
