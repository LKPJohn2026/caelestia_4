#!/usr/bin/env python3
"""caelestia4: StatusNotifierWatcher (system tray registry) as its own user service (caelestia4-sni-watcher).

Before, kded6's statusnotifierwatcher module held org.kde.StatusNotifierWatcher; that module ships with
plasma-workspace, which goes away with Plasma. The watcher has to outlive the shell (the tray host): apps register
their items once (Electron apps such as Claude never re-register), so when Quickshell restarts it reads the list back
from here. Items are dropped when their owner leaves the bus.

Spec: freedesktop.org StatusNotifierItem / KDE's org.kde.StatusNotifierWatcher.
  RegisterStatusNotifierItem(s): a bus name ("org.foo" / ":1.23", item at /StatusNotifierItem) or an object path
    (the item lives at that path on the caller's connection; libappindicator does this). Stored as "name/path".
  RegisterStatusNotifierHost(s): the shell. Properties: RegisteredStatusNotifierItems, IsStatusNotifierHostRegistered,
  ProtocolVersion.
"""
import signal
import sys

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib  # noqa: E402

NAME = "org.kde.StatusNotifierWatcher"
PATH = "/StatusNotifierWatcher"
XML = """
<node>
  <interface name="org.kde.StatusNotifierWatcher">
    <method name="RegisterStatusNotifierItem"><arg name="service" type="s" direction="in"/></method>
    <method name="RegisterStatusNotifierHost"><arg name="service" type="s" direction="in"/></method>
    <property name="RegisteredStatusNotifierItems" type="as" access="read"/>
    <property name="IsStatusNotifierHostRegistered" type="b" access="read"/>
    <property name="ProtocolVersion" type="i" access="read"/>
    <signal name="StatusNotifierItemRegistered"><arg type="s"/></signal>
    <signal name="StatusNotifierItemUnregistered"><arg type="s"/></signal>
    <signal name="StatusNotifierHostRegistered"/>
    <signal name="StatusNotifierHostUnregistered"/>
  </interface>
</node>
"""

items: list[str] = []  # "busname/objectpath", in registration order
hosts: set[str] = set()  # unique bus names of the hosts
conn: Gio.DBusConnection | None = None


def emit(signal_name: str, params: GLib.Variant | None = None) -> None:
    conn.emit_signal(None, PATH, NAME, signal_name, params)


def properties_changed(*names: str) -> None:
    changed = {n: get_property(n) for n in names}
    conn.emit_signal(None, PATH, "org.freedesktop.DBus.Properties", "PropertiesChanged",
                     GLib.Variant("(sa{sv}as)", (NAME, changed, [])))


def get_property(name: str) -> GLib.Variant | None:
    if name == "RegisteredStatusNotifierItems":
        return GLib.Variant("as", items)
    if name == "IsStatusNotifierHostRegistered":
        return GLib.Variant("b", bool(hosts))
    if name == "ProtocolVersion":
        return GLib.Variant("i", 0)
    return None


def owner_of(name: str) -> str | None:
    """Unique name (":1.x") owning a bus name, or None when nobody does."""
    if name.startswith(":"):
        return name
    try:
        reply = conn.call_sync("org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus",
                               "GetNameOwner", GLib.Variant("(s)", (name,)), GLib.VariantType("(s)"),
                               Gio.DBusCallFlags.NONE, -1, None)
        return reply.unpack()[0]
    except GLib.Error:
        return None


def register_item(sender: str, service: str) -> None:
    if service.startswith("/"):
        name, path = sender, service
    else:
        name, path = service, "/StatusNotifierItem"
    if owner_of(name) is None:
        return
    item = f"{name}{path}"
    if item in items:
        return
    items.append(item)
    emit("StatusNotifierItemRegistered", GLib.Variant("(s)", (item,)))
    properties_changed("RegisteredStatusNotifierItems")


def register_host(sender: str, service: str) -> None:
    owner = owner_of(service) or sender
    first = not hosts
    hosts.add(owner)
    if first:
        emit("StatusNotifierHostRegistered")
        properties_changed("IsStatusNotifierHostRegistered")


def on_method_call(_conn, sender, _path, _iface, method, params, invocation) -> None:
    (service,) = params.unpack()
    if method == "RegisterStatusNotifierItem":
        register_item(sender, service)
    elif method == "RegisterStatusNotifierHost":
        register_host(sender, service)
    invocation.return_value(None)


def on_get_property(_conn, _sender, _path, _iface, name):
    return get_property(name)


def on_name_owner_changed(_conn, _sender, _path, _iface, _signal, params) -> None:
    name, _old, new = params.unpack()
    if new:
        return
    # A name went away: drop its items (registered by that name or by the unique name that owned it)
    gone = [i for i in items if i.split("/", 1)[0] == name]
    for item in gone:
        items.remove(item)
        emit("StatusNotifierItemUnregistered", GLib.Variant("(s)", (item,)))
    if gone:
        properties_changed("RegisteredStatusNotifierItems")
    if name in hosts:
        hosts.discard(name)
        if not hosts:
            emit("StatusNotifierHostUnregistered")
            properties_changed("IsStatusNotifierHostRegistered")


def on_bus_acquired(connection: Gio.DBusConnection, _name: str) -> None:
    global conn
    conn = connection
    node = Gio.DBusNodeInfo.new_for_xml(XML)
    connection.register_object(PATH, node.interfaces[0], on_method_call, on_get_property, None)
    connection.signal_subscribe("org.freedesktop.DBus", "org.freedesktop.DBus", "NameOwnerChanged",
                                "/org/freedesktop/DBus", None, Gio.DBusSignalFlags.NONE, on_name_owner_changed)


exit_code = 0


def on_name_lost(_conn, _name) -> None:
    # Another watcher has the name (Quickshell takes it when there is none): fail, so systemd shows it and retries
    global exit_code
    print(f"lost {NAME}: another watcher owns it (start this before the shell)", file=sys.stderr)
    exit_code = 1
    loop.quit()


loop = GLib.MainLoop()
try:
    gi.require_version("GLibUnix", "2.0")
    from gi.repository import GLibUnix  # noqa: E402

    unix_signal_add = GLibUnix.signal_add
except (ImportError, ValueError):
    unix_signal_add = GLib.unix_signal_add
for sig in (signal.SIGTERM, signal.SIGINT):
    unix_signal_add(GLib.PRIORITY_DEFAULT, sig, loop.quit)
Gio.bus_own_name(Gio.BusType.SESSION, NAME, Gio.BusNameOwnerFlags.NONE, on_bus_acquired,
                 lambda *_: print(f"owns {NAME}", flush=True), on_name_lost)
loop.run()
sys.exit(exit_code)
