namespace AstalTriad {
public class Workspace : Object {
    public signal void removed();

    public uint tag_id { get; private set; }
    public int workspace_index { get; private set; default = -1; }
    public string name { get; private set; default = ""; }
    public string output_name { get; private set; default = ""; }
    public string layout { get; private set; default = ""; }
    public string layout_kind { get; private set; default = ""; }
    public string runtime_kind { get; private set; default = ""; }
    public string layout_source { get; private set; default = ""; }
    public string fallback_layout { get; private set; default = ""; }
    public bool configured { get; private set; }
    public bool active { get; private set; }
    public bool output_visible { get; private set; }
    public bool occupied { get; private set; }
    public bool urgent { get; private set; }
    public uint focused_window_id { get; private set; }
    public int master_count { get; private set; }
    public double master_split_ratio { get; private set; }
    public double target_viewport_x { get; private set; }
    public double current_viewport_x { get; private set; }
    public double target_viewport_y { get; private set; }
    public double current_viewport_y { get; private set; }
    public string last_json { get; private set; default = "{}"; }

    internal Workspace(uint tag_id) {
        this.tag_id = tag_id;
    }

    internal void sync(Json.Object obj) {
        tag_id = Triad.uint_member(obj, "tag_id");
        workspace_index = Triad.int_member(obj, "workspace_idx", -1);
        name = Triad.string_member(obj, "name");
        output_name = Triad.string_member(obj, "output");
        layout = Triad.string_member(obj, "layout");
        layout_kind = Triad.string_member(obj, "layout_kind");
        runtime_kind = Triad.string_member(obj, "runtime_kind");
        layout_source = Triad.string_member(obj, "layout_source");
        fallback_layout = Triad.string_member(obj, "fallback_layout");
        configured = Triad.bool_member(obj, "is_configured");
        active = Triad.bool_member(obj, "is_active");
        output_visible = Triad.bool_member(obj, "is_output_visible");
        occupied = Triad.bool_member(obj, "occupied");
        urgent = Triad.bool_member(obj, "is_urgent");
        focused_window_id = Triad.uint_member(obj, "focused_window_id");
        master_count = Triad.int_member(obj, "master_count");
        master_split_ratio = Triad.double_member(obj, "master_split_ratio");
        if (obj.has_member("viewport") && obj.get_member("viewport").get_node_type() == Json.NodeType.OBJECT) {
            var viewport = obj.get_object_member("viewport");
            target_viewport_x = Triad.double_member(viewport, "target_x");
            current_viewport_x = Triad.double_member(viewport, "current_x");
            target_viewport_y = Triad.double_member(viewport, "target_y");
            current_viewport_y = Triad.double_member(viewport, "current_y");
        }
        last_json = Json.to_string(new Json.Node.alloc().init_object(obj), false);
    }

    public void activate() {
        Triad.get_default().focus_workspace(workspace_index);
    }

    public void set_layout_id(string layout_id) {
        Triad.get_default().set_layout(layout_id, tag_id);
    }
}
}
