import GObject from "gi://GObject"
import Gio from "gi://Gio"
import GLib from "gi://GLib"
import Gtk from "gi://Gtk?version=4.0"
import Gdk from "gi://Gdk?version=4.0"
import Astal from "gi://Astal?version=4.0"
import Triad from "gi://AstalTriad"

const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

class Bar extends Astal.Window {
    static {
        GObject.registerClass(this)
    }

    private readonly triad = Triad.get_default()
    private readonly workspaceBox = new Gtk.Box({ spacing: 4 })
    private readonly title = new Gtk.Label({ cssClasses: ["title"] })

    constructor() {
        super({
            visible: true,
            exclusivity: Astal.Exclusivity.EXCLUSIVE,
            anchor: TOP | LEFT | RIGHT,
            cssClasses: ["TriadBar"],
        })

        const root = new Gtk.CenterBox()
        root.set_start_widget(this.workspaceBox)
        root.set_center_widget(this.title)
        this.set_child(root)

        this.rebuild()
        this.triad.connect("workspace-added", () => this.rebuild())
        this.triad.connect("workspace-removed", () => this.rebuild())
        this.triad.connect("notify::focused-workspace", () => this.rebuild())
        this.triad.connect("notify::focused-window", () => this.syncTitle())
        this.triad.connect("notify::connected", () => this.rebuild())
    }

    private clearWorkspaces() {
        let child = this.workspaceBox.get_first_child()
        while (child) {
            const next = child.get_next_sibling()
            this.workspaceBox.remove(child)
            child = next
        }
    }

    private rebuild() {
        this.clearWorkspaces()

        if (!this.triad.connected) {
            this.workspaceBox.append(new Gtk.Label({ label: "Triad unavailable" }))
            this.syncTitle()
            return
        }

        for (const workspace of this.triad.get_workspaces()) {
            const button = new Gtk.Button({
                label: workspace.name || `${workspace.workspaceIndex}`,
            })

            const classes = []
            if (workspace.active) classes.push("active")
            if (workspace.occupied) classes.push("occupied")
            if (workspace.urgent) classes.push("urgent")
            button.cssClasses = classes

            button.connect("clicked", () => workspace.activate())
            this.workspaceBox.append(button)
        }

        this.syncTitle()
    }

    private syncTitle() {
        const win = this.triad.focusedWindow
        this.title.label = win ? `${win.appId} ${win.title}`.trim() : ""
    }
}

export default class App extends Astal.Application {
    static {
        GObject.registerClass(this)
    }

    private bar!: Bar

    constructor() {
        super({
            applicationId: "dev.astal.triad-workspaces",
            flags: Gio.ApplicationFlags.HANDLES_COMMAND_LINE,
        })
    }

    private initCss() {
        const provider = new Gtk.CssProvider()
        provider.load_from_resource("/style.css")

        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default()!,
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_USER,
        )
    }

    vfunc_command_line(commandLine: Gio.ApplicationCommandLine): number {
        if (!commandLine.isRemote) {
            this.initCss()
            this.bar = new Bar()
            this.add_window(this.bar)
        }

        commandLine.done()
        return 0
    }

    static async main(argv: string[]): Promise<number> {
        GLib.set_prgname("triad-workspaces")
        return new App().runAsync(argv)
    }
}
