namespace AstalTriad {
public class Window : Object {
    public signal void removed();

    public uint id { get; private set; }
    public int pid { get; private set; default = -1; }
    public uint parent_id { get; private set; }
    public string title { get; private set; default = ""; }
    public string app_id { get; private set; default = ""; }
    public uint tag_id { get; private set; }
    public int workspace_index { get; private set; default = -1; }
    public string output_name { get; private set; default = ""; }
    public int column_index { get; private set; default = -1; }
    public int window_index { get; private set; default = -1; }
    public bool focused { get; private set; }
    public bool floating { get; private set; }
    public bool maximized { get; private set; }
    public bool minimized { get; private set; }
    public bool fullscreen { get; private set; }
    public bool sticky { get; private set; }
    public bool overlay { get; private set; }
    public bool unmanaged_global { get; private set; }
    public uint fullscreen_output { get; private set; }
    public double width_proportion { get; private set; }
    public double height_proportion { get; private set; }
    public int actual_width { get; private set; }
    public int actual_height { get; private set; }
    public int floating_x { get; private set; }
    public int floating_y { get; private set; }
    public int floating_width { get; private set; }
    public int floating_height { get; private set; }
    public bool keyboard_shortcuts_inhibit { get; private set; }
    public string idle_inhibit { get; private set; default = "none"; }
    public bool terminal { get; private set; }
    public bool allow_swallow { get; private set; }
    public uint swallowed_by { get; private set; }
    public uint swallowing { get; private set; }
    public string last_json { get; private set; default = "{}"; }

    internal Window(uint id) {
        this.id = id;
    }

    internal void sync(Json.Object obj) {
        id = Triad.uint_member(obj, "id");
        pid = Triad.int_member(obj, "pid", -1);
        parent_id = Triad.uint_member(obj, "parent_id");
        title = Triad.string_member(obj, "title");
        app_id = Triad.string_member(obj, "app_id");
        tag_id = Triad.uint_member(obj, "tag_id");
        workspace_index = Triad.int_member(obj, "workspace_idx", -1);
        output_name = Triad.string_member(obj, "output");

        if (obj.has_member("position") && obj.get_member("position").get_node_type() == Json.NodeType.OBJECT) {
            var position = obj.get_object_member("position");
            column_index = Triad.int_member(position, "column_idx", -1);
            window_index = Triad.int_member(position, "window_idx", -1);
        }

        focused = Triad.bool_member(obj, "is_focused");
        floating = Triad.bool_member(obj, "is_floating");
        maximized = Triad.bool_member(obj, "is_maximized");
        minimized = Triad.bool_member(obj, "is_minimized");
        fullscreen = Triad.bool_member(obj, "is_fullscreen");
        sticky = Triad.bool_member(obj, "is_sticky");
        overlay = Triad.bool_member(obj, "is_overlay");
        unmanaged_global = Triad.bool_member(obj, "is_unmanaged_global");
        fullscreen_output = Triad.uint_member(obj, "fullscreen_output");
        width_proportion = Triad.double_member(obj, "width_proportion");
        height_proportion = Triad.double_member(obj, "height_proportion");
        keyboard_shortcuts_inhibit = Triad.bool_member(obj, "keyboard_shortcuts_inhibit");
        idle_inhibit = Triad.string_member(obj, "idle_inhibit", "none");
        terminal = Triad.bool_member(obj, "is_terminal");
        allow_swallow = Triad.bool_member(obj, "allow_swallow");
        swallowed_by = Triad.uint_member(obj, "swallowed_by");
        swallowing = Triad.uint_member(obj, "swallowing");

        if (obj.has_member("actual_size") && obj.get_member("actual_size").get_node_type() == Json.NodeType.OBJECT) {
            var size = obj.get_object_member("actual_size");
            actual_width = Triad.int_member(size, "width");
            actual_height = Triad.int_member(size, "height");
        }

        if (obj.has_member("floating_geometry") && obj.get_member("floating_geometry").get_node_type() == Json.NodeType.OBJECT) {
            var geometry = obj.get_object_member("floating_geometry");
            floating_x = Triad.int_member(geometry, "x");
            floating_y = Triad.int_member(geometry, "y");
            floating_width = Triad.int_member(geometry, "width");
            floating_height = Triad.int_member(geometry, "height");
        }
        last_json = Json.to_string(new Json.Node.alloc().init_object(obj), false);
    }

    public void focus() {
        Triad.get_default().focus_window(id);
    }

    public void close() {
        Triad.get_default().close_window(id);
    }
}
}
