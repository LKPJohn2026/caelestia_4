pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.I18n
import qs.services as E4 // caelestia4: keep

// caelestia4 ADAPTER: Nmcli (network) for the Caelestia bar status icon, network popout, password dialog and the
// Wi-Fi quick toggle. Wi-Fi state comes from end-4's Network service, so there is ONE `nmcli monitor` (end-4's)
// instead of two. end-4's WifiAccessPoint has the same properties as Caelestia's AccessPoint (ssid, bssid,
// strength, frequency, active, security, isSecure), so the list is passed through as is.
// What end-4's service doesn't do is added here as one-off nmcli calls (no polling): wired devices, connecting with
// a result callback / password check, saved-profile lookup and forgetting a network. They refresh when end-4's
// monitor reports a change. Upstream Caelestia's own 1.8k-line implementation was replaced (2026-10-11).
// The Nexus control centre (network pages) needs more of upstream's API: saved profiles with their security, IPv4
// settings, auto-connect, hidden networks and device details. Those are one-off nmcli / sysfs reads made when a page
// asks for them, with upstream's names and result shapes ({ success, output, error, exitCode }).
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
    property var wifiDevices: []
    readonly property var activeEthernet: ethernetDevices.find(d => d.connected) ?? null
    readonly property bool hasAvailableEthernet: ethernetDevices.some(d => d.state !== "unavailable")

    // ---------------------------------------------------------------- Nexus (filled on request)
    // SSIDs of the saved Wi-Fi profiles and their key management (lower-case SSID -> "wpa-psk" / "sae" / "" ...)
    property list<string> savedConnectionSsids: []
    property var savedConnectionSecurity: ({})
    property var wirelessDeviceDetails: null
    property var ethernetDeviceDetails: null
    property string ethernetDataUsage: ""
    property string ethernetSpeed: ""

    function findNetwork(ssid: string): var {
        return root.networks.find(n => n.ssid === ssid) ?? null;
    }

    // SSID of the profile being activated, from the device list (refreshed on every nmcli monitor event)
    function connectingSsid(): string {
        const dev = root.wifiDevices.find(d => d.state.startsWith("connecting"));
        return dev ? dev.connection : (root.pendingConnection?.ssid ?? "");
    }

    function getEthernetInterfaces(callback: var): void {
        refresh.restart();
        callback?.(root.ethernetDevices);
    }

    // Reads the SSID and security of every saved Wi-Fi profile (the profile name can differ from its SSID)
    function loadSavedConnections(callback: var): void {
        root.run(["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"], (code, out) => {
            const names = code !== 0 ? [] : out.trim().split("\n").filter(l => l.length > 0).map(l => {
                const i = l.lastIndexOf(":");
                return {
                    name: l.slice(0, i).replace(/\\:/g, ":"),
                    type: l.slice(i + 1)
                };
            }).filter(c => c.type === "802-11-wireless").map(c => c.name);
            const ssids = [];
            const security = {};
            let left = names.length;
            const finish = () => {
                root.savedConnectionSsids = ssids;
                root.savedConnectionSecurity = security;
                callback?.(ssids);
            };
            if (left === 0)
                return finish();
            for (const name of names)
                root.run(["nmcli", "-t", "-f", "802-11-wireless.ssid,802-11-wireless-security.key-mgmt", "connection", "show", "id", name], (c, o) => {
                    let ssid = "", keyMgmt = "";
                    for (const line of o.trim().split("\n")) {
                        const i = line.indexOf(":");
                        const key = line.slice(0, i), value = line.slice(i + 1).trim();
                        if (key === "802-11-wireless.ssid")
                            ssid = value;
                        else if (key === "802-11-wireless-security.key-mgmt")
                            keyMgmt = value;
                    }
                    if (c === 0 && ssid && !ssids.some(s => s.toLowerCase() === ssid.toLowerCase())) {
                        ssids.push(ssid);
                        security[ssid.toLowerCase()] = keyMgmt;
                    }
                    if (--left === 0)
                        finish();
                });
        });
    }

    function securityLabel(keyMgmt: string): string {
        switch ((keyMgmt || "").trim().toLowerCase()) {
        case "":
        case "none":
            return Tr.trCtx("Open", "wifi security type");
        case "sae":
            return "WPA3";
        case "wpa-psk":
            return "WPA2";
        case "wpa-eap":
        case "wpa-eap-suite-b-192":
            return Tr.tr("Enterprise");
        case "owe":
            return Tr.tr("Enhanced Open");
        case "ieee8021x":
            return "802.1X";
        default:
            return keyMgmt.trim();
        }
    }

    function savedSecurityFor(ssid: string): string {
        return ssid ? (root.savedConnectionSecurity[ssid.toLowerCase().trim()] || "") : "";
    }

    // Creates a profile for an SSID typed by hand (hidden: NetworkManager probes for it) and connects to it
    function addHiddenNetwork(ssid: string, password: string, security: string, hidden: bool, callback: var): void {
        if (!ssid) {
            callback?.(root.result(-1, "", "No SSID specified"));
            return;
        }
        const add = ["nmcli", "connection", "add", "type", "wifi", "con-name", ssid, "ifname", "*", "ssid", ssid, "802-11-wireless.hidden", hidden ? "yes" : "no"];
        if (security && security !== "none")
            add.push("802-11-wireless-security.key-mgmt", "wpa-psk", "802-11-wireless-security.psk", password);
        // Drop a stale profile with the same name first (the delete fails harmlessly when there is none)
        root.run(["nmcli", "connection", "delete", "id", ssid], () => {
            root.run(add, (code, out, err) => {
                if (code !== 0)
                    return callback?.(root.result(code, out, err));
                root.run(["nmcli", "connection", "up", "id", ssid], (c, o, e) => {
                    root.afterChange();
                    root.loadSavedConnections(null);
                    callback?.(root.result(c, o, e));
                });
            });
        });
    }

    // Auto-connect off also stops NetworkManager reusing the stored password (psk-flags 2 = always ask), as upstream
    function setAutoconnect(connectionName: string, enabled: bool, callback: var): void {
        const base = ["nmcli", "connection", "modify", "id", connectionName, "connection.autoconnect", enabled ? "yes" : "no"];
        const withPsk = enabled ? [...base, "802-11-wireless-security.psk-flags", "0"] : [...base, "802-11-wireless-security.psk-flags", "2", "802-11-wireless-security.psk", ""];
        root.run(withPsk, (code, out, err) => {
            // Open networks have no security setting: retry with the auto-connect change alone
            if (code !== 0 && /802-11-wireless-security|not a valid property|invalid/i.test(err))
                return root.run(base, (c, o, e) => callback?.(root.result(c, o, e)));
            callback?.(root.result(code, out, err));
        });
    }

    // { method: "auto" | "auto-dns" | "manual", address, gateway, dns ("a, b"), ignoreAutoDns, autoconnect } or null
    function getIpv4Config(connectionName: string, callback: var): void {
        if (!connectionName) {
            callback?.(null);
            return;
        }
        root.run(["nmcli", "-t", "-f", "ipv4.method,ipv4.addresses,ipv4.gateway,ipv4.dns,ipv4.ignore-auto-dns,connection.autoconnect", "connection", "show", "id", connectionName], (code, out) => {
            if (code !== 0)
                return callback?.(null);
            const cfg = {
                method: "auto",
                address: "",
                gateway: "",
                dns: "",
                ignoreAutoDns: false,
                autoconnect: true
            };
            for (const line of out.trim().split("\n")) {
                const i = line.indexOf(":");
                if (i < 0)
                    continue;
                const key = line.slice(0, i).trim(), value = line.slice(i + 1).trim();
                if (key === "ipv4.ignore-auto-dns")
                    cfg.ignoreAutoDns = value === "yes";
                else if (key === "connection.autoconnect")
                    cfg.autoconnect = value !== "no";
                if (value === "" || value === "--")
                    continue;
                if (key === "ipv4.method")
                    cfg.method = value;
                else if (key === "ipv4.addresses")
                    cfg.address = value.split(",")[0].trim();
                else if (key === "ipv4.gateway")
                    cfg.gateway = value;
                else if (key === "ipv4.dns")
                    cfg.dns = value.split(/[;,]/).map(d => d.trim()).filter(d => d.length > 0).join(", ");
            }
            // DHCP addressing with custom DNS only
            if (cfg.method === "auto" && cfg.ignoreAutoDns)
                cfg.method = "auto-dns";
            callback?.(cfg);
        });
    }

    // Writes the IPv4 settings and re-activates the profile so they apply now
    function setIpv4Config(connectionName: string, config: var, callback: var): void {
        if (!connectionName) {
            callback?.(root.result(-1, "", "No connection specified"));
            return;
        }
        const dns = (config.dns ?? "").split(",").map(d => d.trim()).filter(d => d.length > 0).join(" ");
        const cmd = ["nmcli", "connection", "modify", "id", connectionName];
        if (config.method === "manual")
            cmd.push("ipv4.method", "manual", "ipv4.addresses", config.address ?? "", "ipv4.gateway", config.gateway ?? "", "ipv4.dns", dns, "ipv4.ignore-auto-dns", "yes");
        else if (config.method === "auto-dns")
            cmd.push("ipv4.method", "auto", "ipv4.addresses", "", "ipv4.gateway", "", "ipv4.dns", dns, "ipv4.ignore-auto-dns", "yes");
        else
            cmd.push("ipv4.method", "auto", "ipv4.addresses", "", "ipv4.gateway", "", "ipv4.dns", "", "ipv4.ignore-auto-dns", "no");
        root.run(cmd, (code, out, err) => {
            if (code !== 0)
                return callback?.(root.result(code, out, err));
            root.run(["nmcli", "connection", "up", "id", connectionName], (c, o, e) => {
                root.afterChange();
                callback?.(root.result(c, o, e));
            });
        });
    }

    // IP, gateway, DNS, subnet mask and MAC of a device ("" = the connected Wi-Fi device)
    function getWirelessDeviceDetails(interfaceName: string, callback: var): void {
        const iface = interfaceName || root.wifiDevices.find(d => d.connected)?.iface;
        if (!iface) {
            callback?.(null);
            return;
        }
        root.deviceDetails(iface, details => {
            root.wirelessDeviceDetails = details;
            callback?.(details);
        });
    }

    function getEthernetDeviceDetails(interfaceName: string, callback: var): void {
        const iface = interfaceName || root.activeEthernet?.iface;
        if (!iface) {
            callback?.(null);
            return;
        }
        root.deviceDetails(iface, details => {
            // A failed read (nmcli busy while toggling) keeps the previous details so the page doesn't blink
            if (details)
                root.ethernetDeviceDetails = details;
            callback?.(root.ethernetDeviceDetails);
        });
    }

    // Link speed from sysfs (nmcli doesn't show it)
    function getEthernetSpeed(interfaceName: string): void {
        if (!interfaceName) {
            root.ethernetSpeed = "";
            return;
        }
        root.run(["cat", `/sys/class/net/${interfaceName}/speed`], (code, out) => {
            const mbit = parseInt(out.trim(), 10);
            if (code !== 0 || isNaN(mbit) || mbit <= 0)
                root.ethernetSpeed = "";
            else if (mbit >= 1000)
                root.ethernetSpeed = Tr.tr("%1 Gbps").arg(Number.isInteger(mbit / 1000) ? mbit / 1000 : (mbit / 1000).toFixed(1));
            else
                root.ethernetSpeed = Tr.tr("%1 Mbps").arg(mbit);
        });
    }

    // Bytes received + sent since boot (sysfs counters)
    function getEthernetDataUsage(interfaceName: string, callback: var): void {
        if (!interfaceName)
            return callback?.("");
        root.run(["cat", `/sys/class/net/${interfaceName}/statistics/rx_bytes`, `/sys/class/net/${interfaceName}/statistics/tx_bytes`], (code, out) => {
            const nums = out.trim().split("\n").map(n => parseInt(n, 10)).filter(n => !isNaN(n));
            const human = nums.length < 2 ? "" : Units.formatBytes(nums[0] + nums[1]);
            if (human)
                root.ethernetDataUsage = human;
            callback?.(human);
        });
    }

    function deviceDetails(iface: string, done: var): void {
        root.run(["nmcli", "-t", "device", "show", iface], (code, out) => {
            if (code !== 0 || !out)
                return done(null);
            const details = {
                ipAddress: "",
                gateway: "",
                dns: [],
                subnet: "",
                macAddress: "",
                speed: ""
            };
            for (const line of out.trim().split("\n")) {
                const i = line.indexOf(":");
                const key = line.slice(0, i).trim(), value = line.slice(i + 1).trim().replace(/\\:/g, ":");
                if (key.startsWith("IP4.ADDRESS")) {
                    const [ip, cidr] = value.split("/");
                    details.ipAddress = ip || "";
                    details.subnet = cidr ? root.cidrToSubnetMask(cidr) : "";
                } else if (key === "IP4.GATEWAY" && value !== "--") {
                    details.gateway = value;
                } else if (key.startsWith("IP4.DNS") && value && value !== "--") {
                    details.dns.push(value);
                } else if (key === "GENERAL.HWADDR") {
                    details.macAddress = value;
                }
            }
            done(details);
        });
    }

    function cidrToSubnetMask(cidr: string): string {
        const n = parseInt(cidr, 10);
        if (isNaN(n) || n < 0 || n > 32)
            return "";
        const mask = n === 0 ? 0 : (0xffffffff << (32 - n)) >>> 0;
        return [24, 16, 8, 0].map(s => (mask >>> s) & 0xff).join(".");
    }

    function result(code: int, out: string, err: string): var {
        return {
            success: code === 0,
            output: out ?? "",
            error: code === 0 ? "" : (err ?? "").trim(),
            exitCode: code
        };
    }

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
        if (!ssid)
            return false;
        const lower = ssid.toLowerCase().trim();
        return root.active?.ssid?.toLowerCase().trim() === lower || [...root.savedSsids, ...root.savedConnectionSsids].some(s => s.toLowerCase().trim() === lower);
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
        root.run(["nmcli", "connection", "delete", "id", ssid], (code, out, err) => {
            root.afterChange();
            root.loadSavedConnections(null);
            callback?.(root.result(code, out, err));
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
                const devices = text.trim().split("\n").map(l => l.split(":")).map(f => ({
                            iface: f[0],
                            interface: f[0],
                            type: f[1],
                            state: f[2] ?? "",
                            connection: f[3] ?? "",
                            connected: (f[2] ?? "").startsWith("connected")
                        }));
                root.ethernetDevices = devices.filter(d => d.type === "ethernet");
                root.wifiDevices = devices.filter(d => d.type === "wifi");
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
