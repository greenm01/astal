namespace AstalTriad {
public class Command : Object {
    public string name { get; private set; default = ""; }
    public string usage { get; private set; default = ""; }
    public string arg_shape { get; private set; default = ""; }
    public string description { get; private set; default = ""; }
    public bool special { get; private set; }
    public string[] aliases { get; private set; default = {}; }
    public string last_json { get; private set; default = "{}"; }

    internal Command.from_json(Json.Object obj, bool special = false) {
        this.special = special;
        sync(obj);
    }

    internal void sync(Json.Object obj) {
        name = Triad.string_member(obj, "name");
        usage = Triad.string_member(obj, "usage");
        arg_shape = Triad.string_member(obj, "arg_shape");
        description = Triad.string_member(obj, "description");

        string[] values = {};
        if (obj.has_member("aliases") &&
            obj.get_member("aliases").get_node_type() == Json.NodeType.ARRAY) {
            foreach (var node in obj.get_array_member("aliases").get_elements()) {
                if (node.get_node_type() == Json.NodeType.VALUE) {
                    values += node.get_string();
                }
            }
        }
        aliases = values;
        last_json = Triad.object_json(obj);
    }
}
}
