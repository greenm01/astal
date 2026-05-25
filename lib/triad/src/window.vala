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
