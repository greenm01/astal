namespace AstalTriad {
public Triad get_default() {
    return Triad.get_default();
}

public class Triad : Object {
    private static Triad _instance;

    public static Triad get_default() {
        if (_instance == null) {
            _instance = new Triad();
        }

        return _instance;
    }

    private HashTable<uint, Workspace> _workspaces =
        new HashTable<uint, Workspace>((i) => i, (a, b) => a == b);
    private HashTable<uint, Window> _windows =
        new HashTable<uint, Window>((i) => i, (a, b) => a == b);
    private HashTable<uint, Output> _outputs =
        new HashTable<uint, Output>((i) => i, (a, b) => a == b);

    private SocketConnection event_conn;
    private DataInputStream event_stream;
    private uint reconnect_source;

    public string socket_path { get; private set; }
    public bool connected { get; private set; }
    public List<weak Workspace> workspaces { owned get { return _workspaces.get_values(); } }
    public List<weak Window> windows { owned get { return _windows.get_values(); } }
    public List<weak Output> outputs { owned get { return _outputs.get_values(); } }
    public Workspace? focused_workspace { get; private set; }
    public Window? focused_window { get; private set; }
    public Output? focused_output { get; private set; }
    public uint active_tag { get; private set; }
    public int active_workspace_index { get; private set; default = -1; }
    public bool overview_open { get; private set; }

    public signal void raw_event(string name, string json);
    public signal void workspace_added(Workspace workspace);
    public signal void workspace_removed(uint tag_id);
    public signal void window_added(Window window);
    public signal void window_removed(uint id);
    public signal void output_added(Output output);
    public signal void output_removed(uint id);
    public signal void disconnected();

    private Triad() {
        socket_path = default_socket_path();
        connect_event_stream();
    }

    public Workspace? get_workspace(uint tag_id) {
        return _workspaces.get(tag_id);
    }

    public Workspace? get_workspace_by_index(int workspace_index) {
        foreach (var workspace in workspaces) {
            if (workspace.workspace_index == workspace_index) {
                return workspace;
            }
        }
        return null;
    }

    public Window? get_window(uint id) {
        return _windows.get(id);
    }

    public Output? get_output(uint id) {
        return _outputs.get(id);
    }

    public Output? get_output_by_name(string name) {
        foreach (var output in outputs) {
            if (output.name == name) {
                return output;
            }
        }
        return null;
    }

    public string request(string name, string payload_json = "{}") throws Error {
        var payload = build_request(name, payload_json);
        return send_node(payload);
    }

    public async string request_async(string name, string payload_json = "{}") throws Error {
        var payload = build_request(name, payload_json);
        return yield send_payload_async(Json.to_string(payload, false));
    }

    public string action(string name, string payload_json = "{}") throws Error {
        var payload = build_request("action", payload_json);
        var triad = payload.get_object().get_object_member("triad");
        triad.set_string_member("action", name);
        return send_string(Json.to_string(payload, false));
    }

    public async string action_async(string name, string payload_json = "{}") throws Error {
        var payload = build_request("action", payload_json);
        var triad = payload.get_object().get_object_member("triad");
        triad.set_string_member("action", name);
        return yield send_payload_async(Json.to_string(payload, false));
    }

    public void refresh() {
        request_async.begin("state", "{}", (_, res) => {
                try {
                    handle_reply(request_async.end(res));
                } catch (Error err) {
                    critical(err.message);
                }
            });
    }

    public void focus_workspace(int workspace_index) {
        action_async.begin("focus-workspace", @"{\"workspace_idx\":$workspace_index}");
    }

    public void focus_tag(uint tag_id) {
        action_async.begin("focus-tag", @"{\"tag\":$tag_id}");
    }

    public void focus_window(uint id) {
        action_async.begin("focus-window", @"{\"id\":$id}");
    }

    public void close_window(uint id = 0) {
        if (id == 0) {
            action_async.begin("close-window");
        } else {
            action_async.begin("close-window", @"{\"id\":$id}");
        }
    }

    public void switch_layout() {
        request_async.begin("switch-layout");
    }

    public void set_layout(string layout_id, uint tag_id = 0) {
        var payload = @"{\"layout\":\"$(escape_json_string(layout_id))\"";
        if (tag_id > 0) {
            payload += @",\"tag\":$tag_id";
        }
        payload += "}";
        request_async.begin("set-layout", payload);
    }

    public void toggle_overview() {
        action_async.begin("toggle-overview");
    }

    internal static string string_member(Json.Object obj, string name, string fallback = "") {
        if (!obj.has_member(name) || obj.get_member(name).get_node_type() == Json.NodeType.NULL) {
            return fallback;
        }
        return obj.get_string_member(name);
    }

    internal static bool bool_member(Json.Object obj, string name, bool fallback = false) {
        if (!obj.has_member(name) || obj.get_member(name).get_node_type() == Json.NodeType.NULL) {
            return fallback;
        }
        return obj.get_boolean_member(name);
    }

    internal static int int_member(Json.Object obj, string name, int fallback = 0) {
        if (!obj.has_member(name) || obj.get_member(name).get_node_type() == Json.NodeType.NULL) {
            return fallback;
        }
        return (int)obj.get_int_member(name);
    }

    internal static uint uint_member(Json.Object obj, string name, uint fallback = 0) {
        if (!obj.has_member(name) || obj.get_member(name).get_node_type() == Json.NodeType.NULL) {
            return fallback;
        }
        return (uint)obj.get_int_member(name);
    }

    internal static double double_member(Json.Object obj, string name, double fallback = 0) {
        if (!obj.has_member(name) || obj.get_member(name).get_node_type() == Json.NodeType.NULL) {
            return fallback;
        }
        return obj.get_double_member(name);
    }

    private static string default_socket_path() {
        var explicit_path = Environment.get_variable("TRIAD_SOCKET");
        if (explicit_path != null && explicit_path.length > 0) {
            return explicit_path;
        }

        var runtime_dir = Environment.get_user_runtime_dir();
        if (runtime_dir != null && runtime_dir.length > 0) {
            return Path.build_filename(runtime_dir, "triad.sock");
        }

        return "/tmp/triad.sock";
    }

    private static string escape_json_string(string text) {
        var encoded = Json.to_string(new Json.Node.alloc().init_string(text), false);
        return encoded.substring(1, encoded.length - 2);
    }

    private Json.Node build_request(string name, string payload_json) throws Error {
        var root = new Json.Node(Json.NodeType.OBJECT);
        var root_obj = new Json.Object();
        var triad = new Json.Object();

        triad.set_int_member("version", 1);
        triad.set_string_member("request", name);

        var parser = new Json.Parser();
        parser.load_from_data(payload_json);
        var payload = parser.get_root();
        if (payload.get_node_type() == Json.NodeType.OBJECT) {
            var obj = payload.get_object();
            foreach (var member in obj.get_members()) {
                triad.set_member(member, obj.get_member(member).copy());
            }
        }

        root_obj.set_object_member("triad", triad);
        root.set_object(root_obj);
        return root;
    }

    private string send_node(Json.Node payload) throws Error {
        return send_string(Json.to_string(payload, false));
    }

    private string send_string(string payload) throws Error {
        var conn = new SocketClient().connect(new UnixSocketAddress(socket_path), null);
        var ostream = new DataOutputStream(conn.output_stream);
        ostream.put_string(payload + "\n", null);
        ostream.flush(null);

        var stream = new DataInputStream(conn.input_stream);
        var line = stream.read_line(null);
        conn.close(null);
        return line ?? "";
    }

    private async string send_payload_async(string payload) throws Error {
        var conn = yield new SocketClient().connect_async(new UnixSocketAddress(socket_path), null);
        var ostream = new DataOutputStream(conn.output_stream);
        ostream.put_string(payload + "\n", null);
        yield ostream.flush_async(Priority.DEFAULT, null);

        var stream = new DataInputStream(conn.input_stream);
        var line = yield stream.read_line_async(Priority.DEFAULT, null);
        conn.close(null);
        return line ?? "";
    }

    private void connect_event_stream() {
        if (connected) {
            return;
        }

        try {
            event_conn = new SocketClient().connect(new UnixSocketAddress(socket_path), null);
            event_stream = new DataInputStream(event_conn.input_stream);

            var ostream = new DataOutputStream(event_conn.output_stream);
            ostream.put_string(
                "{\"triad\":{\"version\":1,\"request\":\"event-stream\",\"events\":[\"state\",\"layout\",\"window\"]}}\n",
                null
            );
            ostream.flush(null);

            connected = true;
            notify_property("connected");
            watch_event_stream();
        } catch (Error err) {
            schedule_reconnect();
        }
    }

    private void watch_event_stream() {
        event_stream.read_line_async.begin(Priority.DEFAULT, null, (_, res) => {
                try {
                    var line = event_stream.read_line_async.end(res);
                    if (line == null) {
                        mark_disconnected();
                        return;
                    }
                    handle_reply(line);
                    watch_event_stream();
                } catch (Error err) {
                    mark_disconnected();
                }
            });
    }

    private void mark_disconnected() {
        if (event_conn != null) {
            try {
                event_conn.close(null);
            } catch (Error err) {
                critical(err.message);
            }
        }

        event_conn = null;
        event_stream = null;
        if (connected) {
            connected = false;
            notify_property("connected");
            disconnected();
        }
        schedule_reconnect();
    }

    private void schedule_reconnect() {
        if (reconnect_source != 0) {
            return;
        }

        reconnect_source = Timeout.add_seconds(2, () => {
                reconnect_source = 0;
                connect_event_stream();
                return Source.REMOVE;
            });
    }

    private void handle_reply(string line) throws Error {
        if (line.strip().length == 0) {
            return;
        }

        var parser = new Json.Parser();
        parser.load_from_data(line);
        var root = parser.get_root();
        if (root.get_node_type() != Json.NodeType.OBJECT) {
            return;
        }

        var obj = root.get_object();
        if (!obj.has_member("triad")) {
            return;
        }

        var triad = obj.get_object_member("triad");
        var event_name = string_member(triad, "event");
        var type_name = string_member(triad, "type");
        var name = event_name.length > 0 ? event_name : type_name;
        if (name.length == 0 || name == "ack") {
            return;
        }

        raw_event(name, line);

        switch (name) {
            case "state":
            case "state-changed":
                if (triad.has_member("state")) {
                    handle_state(triad.get_object_member("state"));
                }
                break;
            case "layout-state":
            case "layout-state-changed":
                if (triad.has_member("state")) {
                    handle_layout_state(triad.get_object_member("state"));
                }
                break;
            case "workspaces":
                if (triad.has_member("workspaces")) {
                    sync_workspaces(triad.get_array_member("workspaces"));
                    update_derived_state();
                }
                break;
            case "outputs":
                if (triad.has_member("outputs")) {
                    sync_outputs(triad.get_array_member("outputs"));
                    update_derived_state();
                }
                break;
            case "windows":
                if (triad.has_member("windows")) {
                    sync_windows(triad.get_array_member("windows"));
                    update_derived_state();
                }
                break;
            case "focused-window":
                if (triad.has_member("window") &&
                    triad.get_member("window").get_node_type() == Json.NodeType.OBJECT) {
                    sync_window(triad.get_object_member("window"));
                    update_derived_state();
                }
                break;
            case "overview-state":
                if (triad.has_member("overview")) {
                    handle_overview(triad.get_object_member("overview"));
                }
                break;
            case "window-changed":
                if (triad.has_member("window")) {
                    sync_window(triad.get_object_member("window"));
                    update_derived_state();
                }
                break;
            default:
                break;
        }
    }

    private void handle_state(Json.Object state) {
        if (state.has_member("layout")) {
            handle_layout_state(state.get_object_member("layout"));
        }
        if (state.has_member("outputs")) {
            sync_outputs(state.get_array_member("outputs"));
        }
        if (state.has_member("windows")) {
            sync_windows(state.get_array_member("windows"));
        }
        if (state.has_member("overview")) {
            handle_overview(state.get_object_member("overview"));
        }
        update_derived_state();
    }

    private void handle_layout_state(Json.Object state) {
        active_tag = uint_member(state, "active_tag");
        active_workspace_index = int_member(state, "active_workspace_idx", -1);
        notify_property("active-tag");
        notify_property("active-workspace-index");

        if (state.has_member("workspaces")) {
            sync_workspaces(state.get_array_member("workspaces"));
        }
        update_derived_state();
    }

    private void handle_overview(Json.Object overview) {
        overview_open = bool_member(overview, "is_open");
        notify_property("overview-open");
    }

    private void sync_workspaces(Json.Array array) {
        var seen = new HashTable<uint, bool>((i) => i, (a, b) => a == b);

        foreach (var node in array.get_elements()) {
            if (node.get_node_type() != Json.NodeType.OBJECT) {
                continue;
            }

            var obj = node.get_object();
            var tag_id = uint_member(obj, "tag_id");
            if (tag_id == 0) {
                continue;
            }
            seen.insert(tag_id, true);
            var workspace = _workspaces.get(tag_id);
            if (workspace == null) {
                workspace = new Workspace(tag_id);
                _workspaces.insert(tag_id, workspace);
                workspace_added(workspace);
                notify_property("workspaces");
            }
            workspace.sync(obj);
        }

        var stale = new List<uint>();
        foreach (var workspace in workspaces) {
            if (!seen.contains(workspace.tag_id)) {
                stale.append(workspace.tag_id);
            }
        }
        foreach (var tag_id in stale) {
            var workspace = _workspaces.get(tag_id);
            if (workspace != null) {
                workspace.removed();
            }
            _workspaces.remove(tag_id);
            workspace_removed(tag_id);
            notify_property("workspaces");
        }
    }

    private void sync_windows(Json.Array array) {
        var seen = new HashTable<uint, bool>((i) => i, (a, b) => a == b);

        foreach (var node in array.get_elements()) {
            if (node.get_node_type() != Json.NodeType.OBJECT) {
                continue;
            }

            var id = sync_window(node.get_object());
            if (id > 0) {
                seen.insert(id, true);
            }
        }

        var stale = new List<uint>();
        foreach (var window in windows) {
            if (!seen.contains(window.id)) {
                stale.append(window.id);
            }
        }
        foreach (var id in stale) {
            var window = _windows.get(id);
            if (window != null) {
                window.removed();
            }
            _windows.remove(id);
            window_removed(id);
            notify_property("windows");
        }
    }

    private uint sync_window(Json.Object obj) {
        var id = uint_member(obj, "id");
        if (id == 0) {
            return 0;
        }

        var window = _windows.get(id);
        if (window == null) {
            window = new Window(id);
            _windows.insert(id, window);
            window_added(window);
            notify_property("windows");
        }
        window.sync(obj);
        return id;
    }

    private void sync_outputs(Json.Array array) {
        var seen = new HashTable<uint, bool>((i) => i, (a, b) => a == b);

        foreach (var node in array.get_elements()) {
            if (node.get_node_type() != Json.NodeType.OBJECT) {
                continue;
            }

            var obj = node.get_object();
            var id = uint_member(obj, "id");
            if (id == 0) {
                continue;
            }
            seen.insert(id, true);
            var output = _outputs.get(id);
            if (output == null) {
                output = new Output(id);
                _outputs.insert(id, output);
                output_added(output);
                notify_property("outputs");
            }
            output.sync(obj);
        }

        var stale = new List<uint>();
        foreach (var output in outputs) {
            if (!seen.contains(output.id)) {
                stale.append(output.id);
            }
        }
        foreach (var id in stale) {
            var output = _outputs.get(id);
            if (output != null) {
                output.removed();
            }
            _outputs.remove(id);
            output_removed(id);
            notify_property("outputs");
        }
    }

    private void update_derived_state() {
        focused_workspace = get_workspace(active_tag);
        focused_window = null;
        focused_output = null;

        foreach (var window in windows) {
            if (window.focused) {
                focused_window = window;
                break;
            }
        }

        foreach (var output in outputs) {
            output.focused = focused_workspace != null &&
                output.name == focused_workspace.output_name;
            output.active_workspace = null;
            foreach (var workspace in workspaces) {
                if (workspace.output_visible && workspace.output_name == output.name) {
                    output.active_workspace = workspace;
                    break;
                }
            }
            if (output.focused) {
                focused_output = output;
            }
        }

        notify_property("focused-workspace");
        notify_property("focused-window");
        notify_property("focused-output");
    }
}
}
