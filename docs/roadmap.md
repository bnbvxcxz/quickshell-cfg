# Feature Roadmap

Planned built-in additions designed to keep the shell self-contained while preserving the existing `services/` / `config/` / `components/` / `modules/` separation.

## 1. Notification Action Buttons (Revisit)
- **Goal**: Revisit action chip rendering in `components/NotificationCard.qml` (`Flow` inside `ColumnLayout`) so DBus `NotificationAction` buttons render reliably across all clients (both `notify-send --action` and desktop apps) without layout collapse.

## 2. Backend-Agnostic Wallpaper Switcher (`matugen` / `wallust`)
- **Goal**: Replace external wallpaper picker scripts with an in-shell selector that works identically whether the user generates palettes with `matugen` or `wallust`.
- **Architecture**:
  - Add a `services/WallpaperState.qml` singleton (directory scan, thumbnail cache, backend auto-detection checking `matugen` vs. `wallust`, and `awww`/`swww` or `hyprpaper`/`swaybg` application).
  - Keep `config/Theme.qml` as the single target contract so both a `matugen` template and a `wallust` template emit the exact same Material/semantic token names, followed by `quickshell ipc call theme reload`.
  - Expose a `modules/wallpaper/` picker surface and an `IpcHandler { target: "wallpaper" }` for keybind toggling.

## 3. Built-In Screenshot Tool (Replacing `grimblast`)
- **Goal**: Replace `grimblast` with a native Quickshell overlay (similar to DankShell's screenshotter) supporting region, window, and monitor capture, clipboard copy, and file saving.
- **Architecture**:
  - Use `Quickshell.Wayland.ScreencopyView` (frozen per-monitor overlay layer) combined with `CompositorAdapter` window/output geometry for click-to-select window or drag-to-select region.
  - Pipe the selected crop through `grim -g` + `wl-copy` / `satty` (or save directly to `~/Pictures/Screenshots/`), then trigger an in-shell notification.
  - Expose `IpcHandler { target: "screenshot" }` (`region`, `window`, `screen`) so Hyprland/Niri keybinds map cleanly without external wrapper scripts.
