# Triad Workspaces

A small GTK4/GJS workspace bar backed by AstalTriad.

## Run

Install `astal-triad` and start Triad first so `$TRIAD_SOCKET` is available.

```sh
meson setup build
meson compile -C build
meson install -C build
triad-workspaces
```
