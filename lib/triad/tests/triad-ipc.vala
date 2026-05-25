namespace AstalTriadTest {
const string LAYOUT_EVENT = """
{"triad":{"version":1,"event":"layout-state-changed","state":{"version":7,"active_tag":2,"active_workspace_idx":2,"workspaces":[{"tag_id":2,"workspace_idx":2,"name":"web","output":"HDMI-A-1","layout":"deck","layout_kind":"custom","runtime_kind":"scroller","layout_source":"configured","fallback_layout":"scroller","is_configured":true,"is_active":true,"is_output_visible":true,"is_urgent":false,"occupied":true,"focused_window_id":42,"master_count":1,"master_split_ratio":0.6,"viewport":{"target_x":1.5,"current_x":1.0,"target_y":0.0,"current_y":0.0}},{"tag_id":1,"workspace_idx":1,"name":"term","output":"DP-1","layout":"scroller","layout_kind":"core","runtime_kind":"scroller","layout_source":"default","fallback_layout":"","is_configured":true,"is_active":false,"is_output_visible":false,"is_urgent":false,"occupied":true,"focused_window_id":10,"master_count":1,"master_split_ratio":0.5,"viewport":{"target_x":0.0,"current_x":0.0,"target_y":0.0,"current_y":0.0}}]}}}
""";

const string STATE_EVENT = """
{"triad":{"version":1,"event":"state-changed","state":{"version":7,"capabilities":{"event_stream":true,"keyboard_layout":true,"monitor_power":true},"overview":{"is_open":true,"selected_window_id":42},"layout":{"version":7,"active_tag":2,"active_workspace_idx":2,"workspaces":[{"tag_id":2,"workspace_idx":2,"name":"web","output":"HDMI-A-1","layout":"deck","layout_kind":"custom","runtime_kind":"scroller","layout_source":"configured","fallback_layout":"scroller","is_configured":true,"is_active":true,"is_output_visible":true,"is_urgent":false,"occupied":true,"focused_window_id":42,"master_count":1,"master_split_ratio":0.6,"viewport":{"target_x":1.5,"current_x":1.0,"target_y":0.0,"current_y":0.0}},{"tag_id":1,"workspace_idx":1,"name":"term","output":"DP-1","layout":"scroller","layout_kind":"core","runtime_kind":"scroller","layout_source":"default","fallback_layout":"","is_configured":true,"is_active":false,"is_output_visible":false,"is_urgent":false,"occupied":true,"focused_window_id":10,"master_count":1,"master_split_ratio":0.5,"viewport":{"target_x":0.0,"current_x":0.0,"target_y":0.0,"current_y":0.0}}]},"keyboard_layouts":["us","de"],"current_keyboard_layout_idx":1,"outputs":[{"id":3,"name":"HDMI-A-1","connected":true,"is_primary":true,"refresh_rate":60000,"physical_width":600,"physical_height":340,"scale":2.0,"transform":"90","geometry":{"x":1920,"y":0,"width":2560,"height":1440}},{"id":1,"name":"DP-1","connected":true,"is_primary":false,"refresh_rate":60000,"physical_width":500,"physical_height":280,"scale":1.0,"transform":"Normal","geometry":{"x":0,"y":0,"width":1920,"height":1080}}],"windows":[{"id":42,"pid":100,"parent_id":9,"title":"Browser","app_id":"firefox","tag_id":2,"workspace_idx":2,"output":"HDMI-A-1","position":{"column_idx":1,"window_idx":1},"is_focused":true,"is_floating":false,"is_maximized":false,"is_minimized":false,"is_sticky":false,"is_overlay":false,"is_unmanaged_global":false,"is_fullscreen":false,"fullscreen_output":null,"width_proportion":0.5,"height_proportion":1.0,"actual_size":{"width":1200,"height":800},"floating_geometry":{"x":10,"y":20,"width":300,"height":200},"keyboard_shortcuts_inhibit":false,"idle_inhibit":"focused","is_terminal":false,"allow_swallow":true,"swallowed_by":null,"swallowing":null},{"id":10,"pid":101,"parent_id":null,"title":"Terminal","app_id":"foot","tag_id":1,"workspace_idx":1,"output":"DP-1","position":{"column_idx":1,"window_idx":1},"is_focused":false,"is_floating":false,"is_maximized":false,"is_minimized":false,"is_sticky":false,"is_overlay":false,"is_unmanaged_global":false,"is_fullscreen":false,"fullscreen_output":null,"width_proportion":1.0,"height_proportion":1.0,"actual_size":{"width":900,"height":700},"floating_geometry":{"x":0,"y":0,"width":0,"height":0},"keyboard_shortcuts_inhibit":false,"idle_inhibit":"none","is_terminal":true,"allow_swallow":false,"swallowed_by":null,"swallowing":null}]}}}
""";

const string WINDOW_UPDATE_EVENT = """
{"triad":{"version":1,"event":"window-changed","window":{"id":42,"pid":100,"parent_id":9,"title":"Browser Updated","app_id":"firefox","tag_id":2,"workspace_idx":2,"output":"HDMI-A-1","position":{"column_idx":1,"window_idx":1},"is_focused":true,"is_floating":true,"is_maximized":false,"is_minimized":false,"is_sticky":false,"is_overlay":false,"is_unmanaged_global":false,"is_fullscreen":false,"fullscreen_output":null,"width_proportion":0.5,"height_proportion":1.0,"actual_size":{"width":1200,"height":800},"floating_geometry":{"x":10,"y":20,"width":300,"height":200},"keyboard_shortcuts_inhibit":false,"idle_inhibit":"focused","is_terminal":false,"allow_swallow":true,"swallowed_by":null,"swallowing":null}}}
""";

const string STALE_STATE_EVENT = """
{"triad":{"version":1,"event":"state-changed","state":{"version":8,"capabilities":{"event_stream":true},"overview":{"is_open":false,"selected_window_id":null},"layout":{"version":8,"active_tag":1,"active_workspace_idx":1,"workspaces":[{"tag_id":1,"workspace_idx":1,"name":"term","output":"DP-1","layout":"scroller","layout_kind":"core","runtime_kind":"scroller","layout_source":"default","fallback_layout":"","is_configured":true,"is_active":true,"is_output_visible":true,"is_urgent":false,"occupied":true,"focused_window_id":10,"master_count":1,"master_split_ratio":0.5,"viewport":{"target_x":0.0,"current_x":0.0,"target_y":0.0,"current_y":0.0}}]},"keyboard_layouts":["us"],"current_keyboard_layout_idx":0,"outputs":[{"id":1,"name":"DP-1","connected":true,"is_primary":true,"refresh_rate":60000,"physical_width":500,"physical_height":280,"scale":1.0,"transform":"Normal","geometry":{"x":0,"y":0,"width":1920,"height":1080}}],"windows":[{"id":10,"pid":101,"parent_id":null,"title":"Terminal","app_id":"foot","tag_id":1,"workspace_idx":1,"output":"DP-1","position":{"column_idx":1,"window_idx":1},"is_focused":true,"is_floating":false,"is_maximized":false,"is_minimized":false,"is_sticky":false,"is_overlay":false,"is_unmanaged_global":false,"is_fullscreen":false,"fullscreen_output":null,"width_proportion":1.0,"height_proportion":1.0,"actual_size":{"width":900,"height":700},"floating_geometry":{"x":0,"y":0,"width":0,"height":0},"keyboard_shortcuts_inhibit":false,"idle_inhibit":"none","is_terminal":true,"allow_swallow":false,"swallowed_by":null,"swallowing":null}]}}}
""";

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
    } catch (Error err) {
        assert_not_reached();
    }
}

static void test_state_sync() {
    var triad = new AstalTriad.Triad.for_test();

    try {
        triad.handle_reply_for_test(LAYOUT_EVENT.strip());
        triad.handle_reply_for_test(STATE_EVENT.strip());
    } catch (Error err) {
        assert_not_reached();
    }

    var workspaces = triad.workspaces;
    assert(workspaces.length() == 2);
    assert(workspaces.nth_data(0).tag_id == 2);
    assert(workspaces.nth_data(1).tag_id == 1);
    assert(workspaces.nth_data(0).current_viewport_x == 1.0);

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
        triad.handle_reply_for_test(WINDOW_UPDATE_EVENT.strip());
        triad.handle_reply_for_test(STALE_STATE_EVENT.strip());
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
