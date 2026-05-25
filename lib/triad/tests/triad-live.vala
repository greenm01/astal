namespace AstalTriadLiveTest {
static string? socket_path;
static bool live_checked;
static bool live_available;
static string? live_skip_reason;

static string? live_socket_path() {
    var explicit_path = Environment.get_variable("TRIAD_SOCKET");
    if (explicit_path != null && explicit_path.length > 0 && FileUtils.test(explicit_path, FileTest.EXISTS)) {
        return explicit_path;
    }

    var runtime_dir = Environment.get_user_runtime_dir();
    if (runtime_dir == null || runtime_dir.length == 0) {
        return null;
    }

    var path = Path.build_filename(runtime_dir, "triad.sock");
    if (!FileUtils.test(path, FileTest.EXISTS)) {
        return null;
    }
    return path;
}

static bool ensure_live_session() {
    if (live_checked) {
        if (!live_available) {
            Test.skip(live_skip_reason ?? "No live Triad IPC session is available.");
        }
        return live_available;
    }

    live_checked = true;

    socket_path = live_socket_path();
    if (socket_path == null) {
        live_skip_reason = "No live Triad IPC socket path detected.";
        Test.skip(live_skip_reason);
        return false;
    }

    try {
        var triad = new AstalTriad.Triad.for_test_path(socket_path);
        var reply = triad.request("capabilities");
        if (!reply.contains("\"ok\":true") || !reply.contains("\"type\":\"capabilities\"")) {
            live_skip_reason = "No live Triad IPC session responded to a capabilities request.";
            Test.skip(live_skip_reason);
            return false;
        }
    } catch (Error err) {
        live_skip_reason = "No live Triad IPC session responded to a capabilities request: " + err.message;
        Test.skip(live_skip_reason);
        return false;
    }

    live_available = true;
    return true;
}

static void handle_request(AstalTriad.Triad triad, string request) {
    try {
        triad.handle_reply_for_test(triad.request(request));
    } catch (Error err) {
        stderr.printf("live request %s failed: %s\n", request, err.message);
        assert_not_reached();
    }
}

static bool has_special_request(AstalTriad.Triad triad, string name) {
    foreach (var command in triad.special_requests) {
        if (command.name == name) {
            return true;
        }
    }
    return false;
}

static bool ok_reply(string reply) {
    return reply.contains("\"ok\":true");
}

static void test_live_requests() {
    if (!ensure_live_session()) {
        return;
    }

    var triad = new AstalTriad.Triad.for_test_path(socket_path);
    handle_request(triad, "capabilities");
    handle_request(triad, "state");
    handle_request(triad, "layout-state");
    handle_request(triad, "commands");

    assert(triad.has_capability("event_stream"));
    assert(triad.has_capability("state"));
    assert(triad.workspaces.length() > 0);
    assert(triad.outputs.length() > 0);
    assert(triad.layouts.length() > 0);
    assert(triad.layout_cycle.length > 0);
    assert(triad.commands.length() > 0);
    assert(triad.has_command("focus-window"));
    assert(triad.has_command("switch-keyboard-layout"));
    assert(has_special_request(triad, "event-stream"));
    assert(has_special_request(triad, "dispatch-binding"));
}

static void test_live_event_stream() {
    if (!ensure_live_session()) {
        return;
    }

    var triad = new AstalTriad.Triad.for_test_path(socket_path);
    triad.connect_event_stream_for_test();

    var loop = new MainLoop();
    var timeout_hit = false;

    Timeout.add(20, () => {
        if (triad.connected && triad.workspaces.length() > 0 && triad.outputs.length() > 0 && triad.layouts.length() > 0) {
            loop.quit();
            return Source.REMOVE;
        }
        return Source.CONTINUE;
    });

    Timeout.add(3000, () => {
        timeout_hit = true;
        loop.quit();
        return Source.REMOVE;
    });

    loop.run();
    assert(!timeout_hit);
    assert(triad.focused_workspace != null);
}

static void test_live_current_target_actions() {
    if (!ensure_live_session()) {
        return;
    }

    var triad = new AstalTriad.Triad.for_test_path(socket_path);
    handle_request(triad, "state");

    try {
        if (triad.active_workspace_index > 0) {
            var reply = triad.action("focus-workspace", "{\"workspace_idx\":%d}".printf(triad.active_workspace_index));
            assert(ok_reply(reply));
        }

        if (triad.active_tag > 0) {
            var reply = triad.action("focus-tag", "{\"tag\":%u}".printf(triad.active_tag));
            assert(ok_reply(reply));
        }

        if (triad.focused_window != null) {
            var reply = triad.action("focus-window", "{\"id\":%u}".printf(triad.focused_window.id));
            assert(ok_reply(reply));
        }

        if (triad.focused_workspace != null && triad.focused_workspace.layout.length > 0) {
            var reply = triad.request(
                "set-layout",
                "{\"layout\":\"%s\",\"target\":{\"tag\":%u}}".printf(
                    triad.focused_workspace.layout,
                    triad.focused_workspace.tag_id
                )
            );
            assert(ok_reply(reply));
        }

        if (triad.current_keyboard_layout_index >= 0) {
            var reply = triad.action(
                "switch-keyboard-layout",
                "{\"layout\":%d}".printf(triad.current_keyboard_layout_index)
            );
            assert(ok_reply(reply));
        }
    } catch (Error err) {
        stderr.printf("live current-target action failed: %s\n", err.message);
        assert_not_reached();
    }
}

public static int main(string[] args) {
    Test.init(ref args);
    Test.add_func("/astal-triad/live-requests", test_live_requests);
    Test.add_func("/astal-triad/live-event-stream", test_live_event_stream);
    Test.add_func("/astal-triad/live-current-target-actions", test_live_current_target_actions);
    return Test.run();
}
}
