namespace AstalTriad {
public class Output : Object {
    public signal void removed();

    public uint id { get; private set; }
    public string name { get; private set; default = ""; }
    public bool primary { get; private set; }
    public bool connected { get; private set; default = true; }
    public int x { get; private set; }
    public int y { get; private set; }
    public int width { get; private set; }
    public int height { get; private set; }
    public int physical_width { get; private set; }
    public int physical_height { get; private set; }
    public double scale { get; private set; default = 1; }
    public int refresh_rate { get; private set; }
    public string transform { get; private set; default = "Normal"; }
    public bool focused { get; internal set; }
    public Workspace? active_workspace { get; internal set; }
    public string last_json { get; private set; default = "{}"; }

    internal Output(uint id) {
        this.id = id;
    }

    internal void sync(Json.Object obj) {
        id = Triad.uint_member(obj, "id");
        name = Triad.string_member(obj, "name");
        primary = Triad.bool_member(obj, "is_primary");
        connected = Triad.bool_member(obj, "connected", true);
        physical_width = Triad.int_member(obj, "physical_width");
        physical_height = Triad.int_member(obj, "physical_height");
        scale = Triad.double_member(obj, "scale", 1);
        refresh_rate = Triad.int_member(obj, "refresh_rate");
        transform = Triad.string_member(obj, "transform", "Normal");

        if (obj.has_member("geometry") && obj.get_member("geometry").get_node_type() == Json.NodeType.OBJECT) {
            var geometry = obj.get_object_member("geometry");
            x = Triad.int_member(geometry, "x");
            y = Triad.int_member(geometry, "y");
            width = Triad.int_member(geometry, "width");
            height = Triad.int_member(geometry, "height");
        }

        last_json = Json.to_string(new Json.Node.alloc().init_object(obj), false);
    }
}
}
