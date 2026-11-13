# Architecture Overview

This configuration separates **state/IPC logic** (`services/`), **design tokens** (`config/`), **reusable UI primitives** (`components/`), and **visual surfaces** (`modules/`). Top-level bar composition stays as simple as a Waybar config—drop in, remove, or reorder `*Pill` modules in `BarWindow.qml`—while `Theme.qml` and `SpringBehavior.qml` give full control over theming (capsules vs. boxes, Matugen palettes) and spring animations. Everything scales dynamically per monitor on install.

## Directory Layout

### Root
- `shell.qml` — Entry point (`//@ pragma UseQApplication` for tray menus). Instantiates per-screen `Variants` for the bar, control center, notification toasts, and OSD, owns `NotificationServer` (`actionsSupported`, `bodySupported`, `bodyMarkupSupported`, `persistenceSupported`) and `ListModel` stores, and exposes IPC targets (`drawer`, `dnd`, `osd`, `updates`, `theme`).
- `tests.sh` — Stress-test script for notifications (`./tests.sh notifs`), bar pill states (`./tests.sh pills`), or both (`./tests.sh`).

### `config/` (Design Tokens & Scaling)
- `Theme.qml` — Matugen-compatible Material 3 color palette, surface opacities (`barOpacity`, `drawerOpacity`, `cardOpacity`, `toastOpacity`, etc.), and shape tokens (`pillRadius: -1` for capsule pills or `>= 0` for boxes, `pillBorderWidth`, `pillBorderColor`, `cornerRadius`, `baseBarHeight`, `baseDrawerWidth`).
- `Metrics.qml` — Computes per-screen DPI/PPI scale factors (`scaleFor(screen)`) from physical dimensions and compositor scale, exposing `scaled(val, scale)` so all surfaces adapt to any monitor.
- `Typography.qml` — Inherits `Qt.application.font` with `Theme.fontFamily` fallback and provides `size()`, `sizeSmall()`, and `sizeLarge()`.

### `services/` (State, ABI, & IPC Singletons)
- `CompositorAdapter.qml` — Stable compositor ABI facade (`activeWsId`, `focusMon`, `activeTop`, `activeWinTitle`, `workspaces`, `dispatchWorkspace()`, `stepWorkspace()`, `focusApp()`, `resolveMode()`). Uses a `Loader` to instantiate only the active backend from `services/backends/`.
- `services/backends/` — Pluggable compositor implementations (`HyprlandBackend.qml` for Hyprland Lua/legacy IPC; `NiriBackend.qml` for `$NIRI_SOCKET` `EventStream` + `niri msg action`). New compositors (Sway, MangoWC, River) only need a matching backend file here.
- `HardwareState.qml` — Tracks default PipeWire/PulseAudio sink volume, mute state, mic mute, capslock OSD (`capsToggle`), and `brightnessctl` backlight level. Uses `pactl subscribe` for instant external sync, a 16ms on-demand `syncTimer`, and an `inputCooldown` guard. Exposes IPC target `hw`.
- `SystemState.qml` — Polls Arch/AUR/Flatpak updates (`scripts/check_updates.sh`), battery capacity/charging state, and Wi-Fi signal strength / Ethernet IP. Exposes IPC target `test` for simulating states.
- `MediaState.qml` — Aggregates MPRIS players (filtering out duplicate Waterfox, Discord, and social media URLs/posts), yields focus to playing sockets on pause, and exposes `validPlayers` + `selectPlayer()`.
- `NotificationState.qml` — Lightweight shared drawer & Do Not Disturb (`panelOpen`, `dnd`) singleton.

### `components/` (Reusable UI Primitives)
- `Pill.qml` — Universal bar module container reading `Theme.pillRadius`, `Theme.pillBorderWidth`, and `Theme.pillBorderColor`, with `Pill.Icon`, `Pill.Label`, `clickable`/`wheelEnabled`/`interactive` flags, and wheel accumulator.
- `MarqueeText.qml` — Auto-scrolling text label when content exceeds container width.
- `SpringBehavior.qml` — Reusable Hyprland-style spring stiffness/damping presets (`default`, `instant`, `exit`).

### `modules/` (Visual Surfaces)
- `modules/bar/` — `BarWindow.qml` arranges left (`ClockPill`, `WorkspacesPill`, `IdlePill`, `MprisPill`, `CavaPill`), center (`WindowTitlePill`), and right (`UpdatesPill`, `SystemTrayPill`, `AudioPill`, `BatteryPill`, `NetworkPill`, `BacklightPill`, `ControlCenterPill`) modules (`PrivacyPill.qml` is also included as an optional drop-in pill).
- `modules/controlcenter/` — `ControlCenterWindow.qml` manages per-monitor edge anchoring and slide/drop animations, hosting `QuickToggles.qml` (including DND), `HardwareSliders.qml`, `MprisCard.qml`, and `NotificationHistory.qml`.
- `modules/notifications/` — `NotificationToast.qml` renders floating top-right banners that pause dismissal on hover and focus the source app on click.
- `modules/osd/` — `OsdWindow.qml` renders the bottom-center volume, brightness, mic, and capslock overlay.

### `scripts/`
- `check_updates.sh` — Parallelized Arch, AUR, and Flatpak update counter with a 30-minute `/tmp` cache.
- `update.sh` — Interactive updater (`yay` + `flatpak update`) that clears the cache and calls `quickshell ipc call updates refresh`.

## IPC Reference
- `quickshell ipc call drawer toggle|open|close`
- `quickshell ipc call dnd toggle|on|off`
- `quickshell ipc call hw volUp|volDown|volMute|briUp|briDown|micMute|capsToggle`
- `quickshell ipc call osd show '{"type":"volume","value":0.5,"icon":"󰕾","muted":false}'`
- `quickshell ipc call updates refresh`
- `quickshell ipc call test battery|wifi|ethernet|updates|reset`
- `quickshell ipc call theme reload`
