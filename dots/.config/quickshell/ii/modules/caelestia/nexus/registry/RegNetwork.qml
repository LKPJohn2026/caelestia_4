import QtQuick
import Caelestia.I18n
import qs.modules.caelestia.adapters

// caelestia4: Nexus registry entries for the "network" page (merged by Registry.qml). See RegPanels.qml for the format.
// Most rows on the Network pages show live device state (Wi-Fi on/off, networks, VPN connection): those are not
// settings. Their entry points are "x:" ids with a route and a title only, so search finds them and lands on the row
// (pages/network/ActionMark.qml)
QtObject {
    // caelestia4: "x:network.ethernet" is only listed while an ethernet device is available: the Ethernet section
    // (common/EthernetSection.qml) sits in a Loader that is inactive otherwise, so a search hit or a route to it
    // would land on nothing
    readonly property var entries: Object.assign(Nmcli.hasAvailableEthernet ? {
            // Network (pages/NetworkPage.qml)
            "x:network.ethernet": {
                route: "network",
                title: Tr.mark("Ethernet"),
                keywords: [Tr.mark("ethernet"), Tr.mark("wired"), Tr.mark("cable"), Tr.mark("lan"), Tr.mark("network")]
            }
        } : {}, {
            "x:network.wifi": {
                route: "network",
                title: Tr.mark("Wi-Fi"),
                keywords: [Tr.mark("wifi"), Tr.mark("wi-fi"), Tr.mark("wireless"), Tr.mark("wlan"), Tr.mark("internet"), Tr.mark("turn off wifi")]
            },
            "x:network.addNetwork": {
                route: "network",
                title: Tr.mark("Add network"),
                keywords: [Tr.mark("wifi"), Tr.mark("hidden network"), Tr.mark("ssid"), Tr.mark("connect"), Tr.mark("manual"), Tr.mark("join")]
            },
            "x:network.vpn": {
                route: "network",
                title: Tr.mark("VPN"),
                keywords: [Tr.mark("vpn"), Tr.mark("wireguard"), Tr.mark("tailscale"), Tr.mark("warp"), Tr.mark("netbird"), Tr.mark("tunnel"), Tr.mark("connect")]
            },
            "x:network.addVpn": {
                route: "network",
                title: Tr.mark("Add provider"),
                keywords: [Tr.mark("vpn"), Tr.mark("provider"), Tr.mark("wireguard"), Tr.mark("tailscale"), Tr.mark("warp"), Tr.mark("netbird"), Tr.mark("add vpn")]
            },
            "c:nexus.maxNetworksShown": {
                route: "network",
                section: Tr.mark("Network list"),
                title: Tr.mark("Networks shown"),
                desc: Tr.mark("How many Wi-Fi networks this page lists before “Show all networks”"),
                keywords: [Tr.mark("wifi"), Tr.mark("networks"), Tr.mark("list"), Tr.mark("limit"), Tr.mark("count"), Tr.mark("show all")],
                type: "int",
                min: 1,
                max: 20,
                step: 1
            },
            // caelestia4: moved here from Services > Polling (owner decision): stored in ms, shown in seconds
            "c:nexus.networkRescanInterval": {
                route: "network",
                section: Tr.mark("Network list"),
                title: Tr.mark("Wi-Fi rescan"),
                desc: Tr.mark("How often the Wi-Fi list looks for new networks. Lower uses more power"),
                keywords: [Tr.mark("wifi"), Tr.mark("wi-fi"), Tr.mark("wireless"), Tr.mark("network"), Tr.mark("scan"), Tr.mark("rescan"), Tr.mark("interval"), Tr.mark("refresh")],
                type: "int",
                unit: "s",
                scale: 0.001,
                min: 5000,
                max: 120000,
                step: 5000
            },

            // Network > All networks (pages/network/AllNetworksPage.qml)
            "x:network.allNetworks": {
                route: "network/all",
                title: Tr.mark("All networks"),
                keywords: [Tr.mark("wifi"), Tr.mark("networks"), Tr.mark("scan"), Tr.mark("filter"), Tr.mark("5 ghz"), Tr.mark("2.4 ghz"), Tr.mark("show all")]
            },

            // Network > Saved networks (pages/network/SavedNetworksPage.qml)
            "x:network.savedNetworks": {
                route: "network/saved",
                title: Tr.mark("Saved networks"),
                keywords: [Tr.mark("wifi"), Tr.mark("saved"), Tr.mark("known"), Tr.mark("forget"), Tr.mark("profiles"), Tr.mark("remembered")]
            }
        })

    // caelestia4: options edited through the VPN editor (Network > VPN, pages/network/AddVpnPage.qml, via the VPN
    // adapter) and by the VPN connection itself (`enabled` follows the connection, for auto-connect at login). They are
    // listed here so tools/nexus-coverage.py counts them, but kept out of `entries` on purpose: a registry entry on a
    // route makes the page's "Reset page" reset it, which would delete every VPN provider and disconnect state. Move
    // them into `entries` once the registry can mark an entry as not resettable
    readonly property var editedElsewhere: ({
            "c:utilities.vpn.provider": {
                route: "network/vpn",
                title: Tr.mark("VPN providers"),
                keywords: [Tr.mark("vpn"), Tr.mark("provider"), Tr.mark("wireguard"), Tr.mark("tailscale"), Tr.mark("warp"), Tr.mark("netbird")],
                type: "list"
            },
            "c:utilities.vpn.selectedProvider": {
                route: "network/vpn",
                title: Tr.mark("Selected VPN provider"),
                keywords: [Tr.mark("vpn"), Tr.mark("provider"), Tr.mark("selected")],
                type: "string"
            },
            "c:utilities.vpn.enabled": {
                route: "network/vpn",
                title: Tr.mark("Connect VPN at login"),
                keywords: [Tr.mark("vpn"), Tr.mark("auto connect"), Tr.mark("login")],
                type: "bool"
            }
        })
}
