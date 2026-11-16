# quickshell cfg

Yes, this is vibecoded shlock. But it's MY vibecoded shlock. :wholesome:

## Quick Start
```sh
quickshell
```

With debug logging:
```sh
QUICKSHELL_LOG_LEVEL=debug quickshell
```

Run the notification and bar module tests:
```sh
./tests.sh
```

## Dependencies
Core:
- `quickshell` (with `qt6-wayland`)
- `hyprland` or `niri`
- `pipewire` + `pipewire-pulse` (`pactl`, `wpctl`)
- `brightnessctl`
- `networkmanager` (`nmcli`, `nmtui`)
- A Nerd Font (fallback: `JetBrainsMono NFP`)

Optional:
- `cava` (`MediaState` / `CavaModule`)
- `matugen` (writes `config/Theme.qml`)
- `pavucontrol` (audio module click)
- `kitty` (`nmtui` and `scripts/update.sh`)
- `pacman-contrib` (`checkupdates`), `yay`, `flatpak` (`UpdatesModule`)
- `libnotify` (`notify-send` for `tests.sh`)

## Customization & Features
- **Theming & Layout (`config/Metrics.qml` + `config/Theme.qml`)**: `config/Metrics.qml` is the main place to tweak how the shell looks—`moduleRadius` (`-1` for pills, `0` for square boxes, `4+` for rounded boxes), `baseModuleGapX`, `baseModuleGapY`, `baseBarMarginX`, `baseModulePadding`, borders, and opacities. `config/Theme.qml` is just Material 3 colors so Matugen can overwrite it on wallpaper changes without touching your layout settings.
- **Commands & Paths (`config/Commands.qml`)**: Centralizes `terminal`, `mixer`, `netManager`, and `Qt.resolvedUrl`-resolved script paths.
- **Bar Modules (`modules/bar/BarWindow.qml`)**: Add, remove, or reorder `*Module` items in `leftBarRow` or `rightBarRow` like Waybar. `SystemTrayModule` supports left/right/middle click and 2nd-right-click popup close; `CavaModule` shares a single `cava` process from `MediaState` across all monitors; `MediaState` keeps idle MPRIS sockets visible until closed.
- **Notifications (`components/NotificationCard.qml` + `services/NotificationState.qml`)**: Supports 2-per-row action buttons, action icons, inline replies, markup/hyperlinks, images, progress bars, grouped message history, per-card hover pause, and horizontal swipe-to-dismiss.
- **Compositors (`services/CompositorAdapter.qml` + `services/backends/`)**: `CompositorAdapter` picks `HyprlandBackend.qml` or `NiriBackend.qml` automatically. Supporting another compositor just means dropping a new backend file in `services/backends/`.
- **Animations & Logging**: Shared spring presets live in `components/SpringBehavior.qml`. `services/Logger.qml` provides `error`/`warn`/`info`/`debug` levels (switchable at runtime with `quickshell ipc call log level debug`).
- **Docs**: [docs/architecture.md](docs/architecture.md), [docs/conventions.md](docs/conventions.md), [docs/roadmap.md](docs/roadmap.md).

## Credits
- Modeled after [Waybar](https://github.com/Alexays/Waybar).
- Built with [Quickshell](https://quickshell.org/), [Matugen](https://github.com/InioX/matugen), [Hyprland](https://hyprland.org/), [Niri](https://github.com/YaLTeR/niri), and [cava](https://github.com/karlstav/cava).
