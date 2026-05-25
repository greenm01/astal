namespace AstalTriadTest {
static int removed_workspaces = 0;
static int removed_windows = 0;
static int removed_outputs = 0;

static void on_workspace_removed(uint tag_id) {
    removed_workspaces++;
}

static void on_window_removed(uint id) {
    removed_windows++;
}

static void on_output_removed(uint id) {
    removed_outputs++;
}

static string fixture(string name) {
    var dir = Environment.get_variable("ASTAL_TRIAD_TEST_FIXTURES");
    assert(dir != null);

    try {
        string contents;
        FileUtils.get_contents(Path.build_filename(dir, name), out contents);
        return contents.strip();
    } catch (Error err) {
        assert_not_reached();
    }
}

static Json.Object triad_payload(string line) {
    try {
        var parser = new Json.Parser();
        parser.load_from_data(line);
        return parser.get_root().get_object().get_object_member("triad");
    } catch (Error err) {
        assert_not_reached();
    }
}

static void test_request_payloads() {
    var triad = new AstalTriad.Triad.for_test();

    try {
        var stream = triad_payload(triad.request_payload_for_test("event-stream", "{\"events\":[\"state\",\"layout\",\"window\"]}"));
        assert(stream.get_string_member("request") == "event-stream");
        assert(stream.get_array_member("events").get_string_element(0) == "state");
        assert(stream.get_array_member("events").get_string_element(1) == "layout");
        assert(stream.get_array_member("events").get_string_element(2) == "window");

        var focus = triad_payload(triad.action_payload_for_test("focus-workspace", "{\"workspace_idx\":3}"));
        assert(focus.get_string_member("request") == "action");
        assert(focus.get_string_member("action") == "focus-workspace");
        assert(focus.get_int_member("workspace_idx") == 3);

        var layout = triad_payload(triad.request_payload_for_test("set-layout", "{\"layout\":\"deck\",\"target\":{\"tag\":2}}"));
        assert(layout.get_string_member("request") == "set-layout");
        assert(layout.get_string_member("layout") == "deck");
        assert(layout.get_object_member("target").get_int_member("tag") == 2);

        var keyboard = triad_payload(triad.switch_keyboard_layout_payload_for_test("next"));
        assert(keyboard.get_string_member("action") == "switch-keyboard-layout");
        assert(keyboard.get_string_member("layout") == "next");

        var keyboard_index = triad_payload(triad.switch_keyboard_layout_index_payload_for_test(1));
        assert(keyboard_index.get_int_member("layout") == 1);

        var output = triad_payload(triad.output_action_payload_for_test("focus-output", "DP-1"));
        assert(output.get_string_member("action") == "focus-output");
        assert(output.get_string_member("output") == "DP-1");

        var spawn = triad_payload(triad.spawn_payload_for_test({"foot", "--app-id", "demo"}));
        assert(spawn.get_string_member("action") == "spawn");
        assert(spawn.get_array_member("argv").get_string_element(2) == "demo");

        var screenshot = triad_payload(triad.screenshot_payload_for_test("/tmp/shot.png", false, true, false));
        assert(screenshot.get_string_member("path") == "/tmp/shot.png");
        assert(!screenshot.get_boolean_member("show_pointer"));
        assert(screenshot.get_boolean_member("write_to_disk"));
        assert(!screenshot.get_boolean_member("copy_to_clipboard"));
    } catch (Error err) {
        assert_not_reached();
    }
}

static void test_state_sync() {
    var triad = new AstalTriad.Triad.for_test();

    try {
        triad.handle_reply_for_test(fixture("layout-state-event.json"));
        triad.handle_reply_for_test(fixture("state-event.json"));
        triad.handle_reply_for_test(fixture("commands-reply.json"));
    } catch (Error err) {
        assert_not_reached();
    }

    assert(triad.layouts.length() == 2);
    assert(triad.layouts.nth_data(1).id == "deck");
    assert(triad.layout_cycle.length == 2);
    assert(triad.layout_cycle[1] == "deck");
    assert(triad.layout_cycle_entries.length() == 2);
    assert(triad.layout_cycle_entries.nth_data(1).fallback_layout == "scroller");
    assert(triad.commands.length() == 3);
    assert(triad.commands.nth_data(2).aliases[0] == "toggle-fullscreen");
    assert(triad.special_requests.length() == 2);
    assert(triad.special_requests.nth_data(1).special);
    assert(triad.commands_json.contains("\"switch-keyboard-layout\""));

    var workspaces = triad.workspaces;
    assert(workspaces.length() == 2);
    assert(workspaces.nth_data(0).tag_id == 2);
    assert(workspaces.nth_data(1).tag_id == 1);
    assert(workspaces.nth_data(0).current_viewport_x == 1.0);
    assert(workspaces.nth_data(0).columns_json.contains("\"windows\":[42]"));

    var outputs = triad.outputs;
    assert(outputs.nth_data(0).name == "HDMI-A-1");
    assert(outputs.nth_data(0).physical_width == 600);
    assert(outputs.nth_data(0).transform == "90");

    var windows = triad.windows;
    assert(windows.nth_data(0).id == 42);
    assert(windows.nth_data(0).idle_inhibit == "focused");
    assert(windows.nth_data(0).actual_width == 1200);
    assert(triad.focused_window.id == 42);
    assert(triad.overview_open);
    assert(triad.overview_selected_window_id == 42);
    assert(triad.current_keyboard_layout_index == 1);
    assert(triad.keyboard_layouts[1] == "de");
    assert(triad.capabilities_json.contains("\"monitor_power\":true"));

    removed_workspaces = 0;
    removed_windows = 0;
    removed_outputs = 0;
    triad.workspace_removed.connect(on_workspace_removed);
    triad.window_removed.connect(on_window_removed);
    triad.output_removed.connect(on_output_removed);

    try {
        triad.handle_reply_for_test(fixture("window-changed-event.json"));
        triad.handle_reply_for_test(fixture("stale-state-event.json"));
        triad.handle_reply_for_test("{\"triad\":{\"version\":1,\"type\":\"focused-window\",\"window\":null}}");
    } catch (Error err) {
        assert_not_reached();
    }

    assert(triad.get_window(42) == null);
    assert(triad.get_window(10).focused);
    assert(triad.workspaces.length() == 1);
    assert(triad.windows.length() == 1);
    assert(triad.outputs.length() == 1);
    assert(removed_workspaces == 1);
    assert(removed_windows == 1);
    assert(removed_outputs == 1);
    assert(!triad.overview_open);
    assert(triad.current_keyboard_layout_index == 0);
    assert(triad.focused_window == null);
}

public static int main(string[] args) {
    Test.init(ref args);
    Test.add_func("/astal-triad/request-payloads", test_request_payloads);
    Test.add_func("/astal-triad/state-sync", test_state_sync);
    return Test.run();
}
}
