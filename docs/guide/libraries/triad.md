# Triad

Library for monitoring and controlling
[Triad](https://github.com/greenm01/triad) through its native IPC socket.

## Usage

Triad exposes workspaces, windows, outputs, focused state, and common shell
actions through `$TRIAD_SOCKET`.

### Library

:::code-group

```js [<i class="devicon-javascript-plain"></i> JavaScript]
import Triad from "gi://AstalTriad"

const triad = Triad.get_default()

for (const workspace of triad.get_workspaces()) {
    print(`${workspace.workspaceIndex}: ${workspace.name}`)
}
```

```py [<i class="devicon-python-plain"></i> Python]
from gi.repository import AstalTriad as Triad

triad = Triad.get_default()

for workspace in triad.get_workspaces():
    print(workspace.get_name())
```

```lua [<i class="devicon-lua-plain"></i> Lua]
local Triad = require("lgi").require("AstalTriad")

local triad = Triad.get_default()

for _, workspace in ipairs(triad.workspaces) do
    print(workspace.name)
end
```

```vala [<i class="devicon-vala-plain"></i> Vala]
var triad = AstalTriad.get_default();

foreach (var workspace in triad.workspaces) {
    print("%s\n", workspace.name);
}
```

:::

## Installation

1. install dependencies

    :::code-group

    ```sh [<i class="devicon-archlinux-plain"></i> Arch]
    sudo pacman -Syu meson vala json-glib gobject-introspection
    ```

    ```sh [<i class="devicon-fedora-plain"></i> Fedora]
    sudo dnf install meson vala json-glib-devel gobject-introspection-devel
    ```

    ```sh [<i class="devicon-ubuntu-plain"></i> Ubuntu]
    sudo apt install meson valac libjson-glib-dev gobject-introspection
    ```

    :::

2. clone repo

    ```sh
    git clone https://github.com/aylur/astal.git
    cd astal/lib/triad
    ```

3. install

    ```sh
    meson setup build
    meson install -C build
    ```
