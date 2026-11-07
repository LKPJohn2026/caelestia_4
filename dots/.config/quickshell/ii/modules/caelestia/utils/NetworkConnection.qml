pragma Singleton

import QtQuick
import Quickshell
import Caelestia.I18n
import qs.modules.caelestia.adapters

/**
 * NetworkConnection
 *
 * Centralized utility for network connection logic. Provides a single source of truth
 * for connecting to wireless networks, eliminating code duplication across
 * controlcenter components and bar popouts.
 *
 * Usage:
 * ```qml
 * import qs.utils
 *
 * // With Session object (controlcenter)
 * NetworkConnection.handleConnect(network, session);
 *
 * // Without Session object (bar popouts) - provide password dialog callback
 * NetworkConnection.handleConnect(network, null, (network) => {
 *     // Show password dialog
 *     root.passwordNetwork = network;
 *     root.showPasswordDialog = true;
 * });
 * ```
 */
QtObject {
    id: root

    /**
     * Handle network connection with automatic disconnection if needed.
     * If there's an active network different from the target, disconnects first,
     * then connects to the target network.
     *
     * @param network The network object to connect to (must have ssid property)
     * @param session Optional Session object (for controlcenter - must have network property with showPasswordDialog and pendingNetwork)
     * @param onPasswordNeeded Optional callback function(network) called when password is needed (for bar popouts)
     */
    function handleConnect(network, session, onPasswordNeeded): void {
        if (!network) {
            return;
        }

        // caelestia4: before leaving the current network, which the setup may need. The saved list isn't refreshed by itself,
        // and one made in the editor is what "connect again" comes back with
        if (root.needsSetup(network)) {
            Nmcli.loadSavedConnections(() => {
                if (root.needsSetup(network))
                    root.openEnterpriseSetup(network.ssid);
                else
                    root.handleConnect(network, session, onPasswordNeeded);
            });
            return;
        }

        if (Nmcli.active && Nmcli.active.ssid !== network.ssid) {
            Nmcli.disconnectFromNetwork();
            Qt.callLater(() => {
                root.connectToNetwork(network, session, onPasswordNeeded);
            });
        } else {
            root.connectToNetwork(network, session, onPasswordNeeded);
        }
    }

    /**
     * Connect to a wireless network.
     * Handles both secured and open networks, checks for saved profiles,
     * and shows password dialog if needed.
     *
     * @param network The network object to connect to (must have ssid, isSecure, bssid properties)
     * @param session Optional Session object (for controlcenter - must have network property with showPasswordDialog and pendingNetwork)
     * @param onPasswordNeeded Optional callback function(network) called when password is needed (for bar popouts)
     */
    function connectToNetwork(network, session, onPasswordNeeded): void {
        if (!network) {
            return;
        }

        if (network.isSecure) {
            const hasSavedProfile = Nmcli.hasSavedProfile(network.ssid);

            if (hasSavedProfile) {
                Nmcli.connectToNetwork(network.ssid, "", network.bssid, null);
            } else {
                // Use password check with callback
                Nmcli.connectToNetworkWithPasswordCheck(network.ssid, network.isSecure, result => {
                    if (result.needsPassword) {
                        // Clear pending connection if exists
                        if (Nmcli.pendingConnection) {
                            Nmcli.connectionCheckTimer.stop();
                            Nmcli.immediateCheckTimer.stop();
                            Nmcli.immediateCheckTimer.checkCount = 0;
                            Nmcli.pendingConnection = null;
                        }

                        // Handle password dialog - use session if available, otherwise use callback
                        if (session && session.network) {
                            session.network.showPasswordDialog = true;
                            session.network.pendingNetwork = network;
                        } else if (onPasswordNeeded) {
                            onPasswordNeeded(network);
                        }
                    }
                }, network.bssid);
            }
        } else {
            Nmcli.connectToNetwork(network.ssid, "", network.bssid, null);
        }
    }

    // WPA-Enterprise (eduroam, a company's) needs a sign-in method and a user, which a password prompt can't ask for. Once
    // set up in the editor it has a saved profile and connects like any other
    function needsSetup(network): bool {
        const security = network?.security ?? "";
        return (security.includes("802.1X") || security.includes("WPA-EAP")) && !Nmcli.hasSavedProfile(network.ssid);
    }

    function openEnterpriseSetup(ssid: string): void {
        const script = 'if command -v nm-connection-editor >/dev/null; then notify-send -a Shell -- "$1" "$2"; exec uwsm-app -- nm-connection-editor --create --type=802-11-wireless; fi; notify-send -a Shell -- "$1" "$3"';
        Quickshell.execDetached(["bash", "-c", script, "_",
            Tr.tr("%1 needs a sign-in").arg(ssid),
            Tr.tr("Set it up in the window that opens, then connect again here"),
            Tr.tr("Set it up with nmtui in a terminal, or install nm-connection-editor, then connect again here")]);
    }

    /**
     * Connect to a wireless network with a provided password.
     * Used by password dialogs when the user has already entered a password.
     *
     * @param network The network object to connect to (must have ssid, bssid properties)
     * @param password The password to use for connection
     * @param onResult Optional callback function(result) called with connection result
     */
    function connectWithPassword(network, password, onResult): void {
        if (!network) {
            return;
        }

        Nmcli.connectToNetwork(network.ssid, password || "", network.bssid || "", onResult || null);
    }
}
