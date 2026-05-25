# Triad Workspaces

A small GTK4/GJS workspace bar using AstalTriad.

## Run

Install `astal-triad` and start Triad. The example uses `$TRIAD_SOCKET` when it
is set, and otherwise falls back to `$XDG_RUNTIME_DIR/triad.sock`.

```sh
meson setup build
meson compile -C build
meson install -C build
triad-workspaces
```
