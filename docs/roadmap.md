# Roadmap

Planned additions that fit into the existing `services/` / `config/` / `components/` / `modules/` layout.

## 1. Backend-Agnostic Wallpaper Switcher (`matugen` / `wallust`)
Replace external wallpaper scripts with a built-in picker that works with either `matugen` or `wallust`:
- `services/WallpaperState.qml` for directory scanning, thumbnail caching, backend detection, and `awww`/`swww` or `hyprpaper`/`swaybg` wallpaper setting.
- Keep `config/Theme.qml` as the shared palette contract so both templates emit the same color names, then run `quickshell ipc call theme reload`.
- Add `modules/wallpaper/` and `IpcHandler { target: "wallpaper" }`.

## 2. Built-In Screenshot Tool (Replacing `grimblast`)
Replace `grimblast` with a native Quickshell overlay for region, window, and monitor capture:
- Use `Quickshell.Wayland.ScreencopyView` with `CompositorAdapter` window/output geometry for click-to-select window or drag-to-select region.
- Pipe the crop through `grim -g` + `wl-copy` / `satty` (or save to `~/Pictures/Screenshots/`), then send a notification.
- Add `IpcHandler { target: "screenshot" }` (`region`, `window`, `screen`) for compositor keybinds.
