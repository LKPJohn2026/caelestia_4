#!/usr/bin/env python3
"""caelestia4: pick a file in the desktop's Open dialog (the FileChooser portal: Wormhole here, GTK's as the fallback)
and print its path. Replaces kdialog --getopenfilename, which went with Plasma (switchwall.sh: Nexus > Wallpaper &
style > use the system file dialog). Usage: pick-file.py [START_DIR] [TITLE]; exits 1 when cancelled."""
import os
import sys

# GTK only uses the portal by itself inside a sandbox; ask for it, so the dialog is the session's (Wormhole)
os.environ.setdefault("GDK_DEBUG", "portals")

import gi  # noqa: E402

gi.require_version("Gtk", "4.0")
from gi.repository import Gio, GLib, Gtk  # noqa: E402

start = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else ".")
title = sys.argv[2] if len(sys.argv) > 2 else "Choose a file"

Gtk.init()
media = Gtk.FileFilter(name="Images and videos")
media.add_mime_type("image/*")
media.add_mime_type("video/*")
anything = Gtk.FileFilter(name="All files")
anything.add_pattern("*")
filters = Gio.ListStore.new(Gtk.FileFilter)
filters.append(media)
filters.append(anything)

dialog = Gtk.FileDialog(title=title, initial_folder=Gio.File.new_for_path(start), filters=filters,
                        default_filter=media, modal=True)
loop = GLib.MainLoop()
picked = []


def done(d, result):
    try:
        f = d.open_finish(result)
        if f is not None and f.get_path():
            picked.append(f.get_path())
    except GLib.Error:
        pass  # cancelled
    loop.quit()


dialog.open(None, None, done)
loop.run()
if not picked:
    sys.exit(1)
print(picked[0])
