namespace AstalTriad {
public class Layout : Object {
    public string kind { get; private set; default = ""; }
    public string id { get; private set; default = ""; }
    public int ordinal { get; private set; default = -1; }
    public string runtime_kind { get; private set; default = ""; }
    public string layout_source { get; private set; default = ""; }
    public string fallback_layout { get; private set; default = ""; }
    public string last_json { get; private set; default = "{}"; }

    internal Layout.from_json(Json.Object obj) {
        sync(obj);
    }

    internal void sync(Json.Object obj) {
        kind = Triad.string_member(obj, "kind");
        id = Triad.string_member(obj, "id");
        ordinal = Triad.int_member(obj, "ordinal", -1);
        runtime_kind = Triad.string_member(obj, "runtime_kind");
        layout_source = Triad.string_member(obj, "layout_source");
        fallback_layout = Triad.string_member(obj, "fallback_layout");
        last_json = Triad.object_json(obj);
    }
}

public class LayoutCycleEntry : Object {
    public string kind { get; private set; default = ""; }
    public string id { get; private set; default = ""; }
    public string fallback_layout { get; private set; default = ""; }
    public string last_json { get; private set; default = "{}"; }

    internal LayoutCycleEntry.from_json(Json.Object obj) {
        sync(obj);
    }

    internal void sync(Json.Object obj) {
        kind = Triad.string_member(obj, "kind");
        id = Triad.string_member(obj, "id");
        fallback_layout = Triad.string_member(obj, "fallback_layout");
        last_json = Triad.object_json(obj);
    }
}
}
