namespace AstalTriadSocketTest {
class StubServer : Object {
    public string path { get; construct set; }
    private SocketListener listener;
    private Thread<void> thread;
    private string fixtures;

    public StubServer(string path, string fixtures) throws Error {
        Object(path: path);
        this.fixtures = fixtures;
        listener = new SocketListener();
        listener.add_address(
            new UnixSocketAddress(path),
            SocketType.STREAM,
            SocketProtocol.DEFAULT,
            null,
            null
        );
        thread = new Thread<void>("astal-triad-socket-listener", accept_loop);
    }

    ~StubServer() {
        listener.close();
    }

    private void accept_loop() {
        while (true) {
            try {
                var conn = listener.accept(null);
                handle_client(conn);
            } catch (Error err) {
                return;
            }
        }
    }

    private string fixture(string name) {
        try {
            string contents;
            FileUtils.get_contents(Path.build_filename(fixtures, name), out contents);
            return contents.strip();
        } catch (Error err) {
            assert_not_reached();
        }
    }

    private void handle_client(SocketConnection conn) {
        try {
            var input = new DataInputStream(conn.input_stream);
            var output = new DataOutputStream(conn.output_stream);
            var line = input.read_line(null);
            if (line == null) {
                conn.close(null);
                return;
            }

            if (line.contains("\"request\":\"event-stream\"")) {
                output.put_string("{\"ok\":true,\"triad\":{\"version\":1,\"type\":\"ack\"}}\n", null);
                output.put_string(fixture("layout-state-event.json") + "\n", null);
                output.put_string(fixture("state-event.json") + "\n", null);
                output.flush(null);
                Thread.usleep(200000);
            } else if (line.contains("\"request\":\"commands\"")) {
                output.put_string(fixture("commands-reply.json") + "\n", null);
                output.flush(null);
            } else {
                output.put_string("{\"ok\":false,\"error\":\"unexpected request\"}\n", null);
                output.flush(null);
            }
            conn.close(null);
        } catch (Error err) {
            assert_not_reached();
        }
    }
}

static void test_request_reply() {
    var fixtures = Environment.get_variable("ASTAL_TRIAD_TEST_FIXTURES");
    assert(fixtures != null);
    var path = Path.build_filename(Environment.get_tmp_dir(), "astal-triad-socket-request.sock");
    FileUtils.unlink(path);

    StubServer server;
    try {
        server = new StubServer(path, fixtures);
    } catch (Error err) {
        Test.skip("unix socket bind unavailable: " + err.message);
        return;
    }

    try {
        var triad = new AstalTriad.Triad.for_test_path(path);
        var reply = triad.request("commands");
        assert(reply.contains("\"type\":\"commands\""));
        triad.handle_reply_for_test(reply);
        assert(triad.commands.length() == 3);
        server = null;
    } catch (Error err) {
        stderr.printf("socket request test failed: %s\n", err.message);
        assert_not_reached();
    }
    FileUtils.unlink(path);
}

static void test_event_stream_initial_events() {
    var fixtures = Environment.get_variable("ASTAL_TRIAD_TEST_FIXTURES");
    assert(fixtures != null);
    var path = Path.build_filename(Environment.get_tmp_dir(), "astal-triad-socket-stream.sock");
    FileUtils.unlink(path);

    StubServer server;
    try {
        server = new StubServer(path, fixtures);
    } catch (Error err) {
        Test.skip("unix socket bind unavailable: " + err.message);
        return;
    }

    var triad = new AstalTriad.Triad.for_test_path(path);
    triad.connect_event_stream_for_test();

    var loop = new MainLoop();
    Timeout.add(250, () => {
        assert(triad.connected);
        assert(triad.workspaces.length() == 2);
        assert(triad.windows.length() == 2);
        assert(triad.layouts.length() == 2);
        loop.quit();
        return Source.REMOVE;
    });
    loop.run();
    server = null;
    FileUtils.unlink(path);
}

public static int main(string[] args) {
    Test.init(ref args);
    Test.add_func("/astal-triad/socket-request-reply", test_request_reply);
    Test.add_func("/astal-triad/socket-event-stream-initial-events", test_event_stream_initial_events);
    return Test.run();
}
}
