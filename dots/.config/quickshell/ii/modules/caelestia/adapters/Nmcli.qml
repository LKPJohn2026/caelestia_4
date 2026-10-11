pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services as E4 // caelestia4: keep

// caelestia4 ADAPTER: Nmcli (network) for the Caelestia bar status icon, network popout, password dialog and the
// Wi-Fi quick toggle. Wi-Fi state comes from end-4's Network service, so there is ONE `nmcli monitor` (end-4's)
// instead of two. end-4's WifiAccessPoint has the same properties as Caelestia's AccessPoint (ssid, bssid,
// strength, frequency, active, security, isSecure), so the list is passed through as is.
// What end-4's service doesn't do is added here as one-off nmcli calls (no polling): wired devices, connecting with
// a result callback / password check, saved-profile lookup and forgetting a network. They refresh when end-4's
// monitor reports a change. Upstream Caelestia's own 1.8k-line implementation was replaced (2026-10-11).
Singleton {
    id: root

    // ---------------------------------------------------------------- Wi-Fi (end-4 Network)
    readonly property bool wifiEnabled: E4.Network.wifiEnabled
    readonly property bool scanning: E4.Network.wifiScanning
    readonly property var networks: E4.Network.wifiNetworks
    readonly property var active: E4.Network.active

    // Set while a connection attempt runs: { ssid, bssid }
    property var pendingConnection: null
    // Kept for the Caelestia callers that stop them when a password is needed (no polling here)
    readonly property Timer connectionCheckTimer: Timer {}
    readonly property Timer immediateCheckTimer: Timer {
        property int checkCount: 0
    }

    // ---------------------------------------------------------------- wired + saved profiles (own one-off calls)
    property list<string> savedSsids: []
    property var ethernetDevices: []
    readonly property var activeEthernet: ethernetDevices.find(d => d.connected) ?? null

    function enableWifi(enabled: bool, callback: var): void {
        E4.Network.enableWifi(enabled);
        callback?.();
    }

    function toggleWifi(callback: var): void {
        E4.Network.toggleWifi();
        callback?.();
    }

    function rescanWifi(): void {
        E4.Network.rescanWifi();
    }

    function disconnectFromNetwork(): void {
        E4.Network.disconnectWifiNetwork();
    }

    function hasSavedProfile(ssid: string): bool {
        return root.savedSsids.includes(ssid);
    }

    // callback({ success, needsPassword, error })
    function connectToNetwork(ssid: string, password: string, bssid: string, callback: var): void {
        let cmd;
        if (password && password.length > 0)
            cmd = ["nmcli", "device", "wifi", "connect", ssid, "password", password];
        else if (root.hasSavedProfile(ssid))
            cmd = ["nmcli", "connection", "up", "id", ssid];
        else
            cmd = ["nmcli", "device", "wifi", "connect", ssid];
        if (bssid && bssid.length > 0 && cmd[2] === "wifi")
            cmd.push("bssid", bssid);

        root.pendingConnection = {
            ssid,
            bssid
        };
        root.run(cmd, (code, out, err) => {
            root.pendingConnection = null;
            const needsPassword = code !== 0 && /secrets were required|password|802-11-wireless-security/i.test(err);
            root.afterChange();
            callback?.({
                success: code === 0,
                needsPassword,
                error: code === 0 ? "" : err.trim()
            });
        });
    }

    // Try without a password first (saved profile / open network); report needsPassword if secrets are missing
    function connectToNetworkWithPasswordCheck(ssid: string, isSecure: bool, callback: var, bssid: string): void {
        root.connectToNetwork(ssid, "", bssid, callback);
    }

    function forgetNetwork(ssid: string, callback: var): void {
        root.run(["nmcli", "connection", "delete", "id", ssid], code => {
            root.afterChange();
            callback?.({
                success: code === 0
            });
        });
    }

    function connectEthernet(connectionName: string, interfaceName: string, callback: var): void {
        const cmd = connectionName ? ["nmcli", "connection", "up", "id", connectionName] : ["nmcli", "device", "connect", interfaceName];
        root.run(cmd, code => {
            root.afterChange();
            callback?.({
                success: code === 0
            });
        });
    }

    function disconnectEthernet(connectionName: string, callback: var): void {
        root.run(["nmcli", "connection", "down", "id", connectionName], code => {
            root.afterChange();
            callback?.({
                success: code === 0
            });
        });
    }

    // Refresh the Wi-Fi list (end-4) and our wired / saved lists after something changed
    function afterChange(): void {
        E4.Network.rescanWifi();
        refresh.restart();
    }

    // ---------------------------------------------------------------- plumbing
    function run(command: var, done: var): void {
        const proc = cmdComp.createObject(root, {
            command,
            done
        });
        proc.running = true;
    }

    Component {
        id: cmdComp

        Process {
            property var done
            environment: ({
                    LANG: "C",
                    LC_ALL: "C"
                })
            stdout: StdioCollector {
                id: out
            }
            stderr: StdioCollector {
                id: err
            }
            onExited: code => {
                done?.(code, out.text, err.text);
                destroy();
            }
        }
    }

    // end-4's `nmcli monitor` updates these when anything changes: refresh wired devices and saved profiles then
    Connections {
        target: E4.Network

        function onEthernetChanged(): void {
            refresh.restart();
        }
        function onWifiStatusChanged(): void {
            refresh.restart();
        }
        function onNetworkNameChanged(): void {
            refresh.restart();
        }
    }

    Timer {
        id: refresh

        interval: 300
        running: true
        onTriggered: {
            devicesProc.running = true;
            savedProc.running = true;
        }
    }

    Process {
        id: devicesProc

        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device"]
        environment: ({
                LANG: "C",
                LC_ALL: "C"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                root.ethernetDevices = text.trim().split("\n").map(l => l.split(":")).filter(f => f[1] === "ethernet").map(f => ({
                            iface: f[0],
                            type: f[1],
                            state: f[2],
                            connection: f[3] ?? "",
                            connected: (f[2] ?? "").startsWith("connected")
                        }));
            }
        }
    }

    Process {
        id: savedProc

        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.savedSsids = text.trim().split("\n").map(l => {
                    // NAME may contain escaped colons ("\:"); TYPE is the last field
                    const i = l.lastIndexOf(":");
                    return {
                        name: l.slice(0, i).replace(/\\:/g, ":"),
                        type: l.slice(i + 1)
                    };
                }).filter(c => c.type === "802-11-wireless").map(c => c.name);
            }
        }
    }
}
