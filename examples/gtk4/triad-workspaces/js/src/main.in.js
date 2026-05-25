#!@GJS@ -m

import GLib from "gi://GLib"
import Gio from "gi://Gio"

const resource = Gio.Resource.load("@PKGDATADIR@/data.gresource")
Gio.resources_register(resource)

const { default: App } = await import("resource:///index.js")

App.main([GLib.get_prgname(), ...ARGV])
