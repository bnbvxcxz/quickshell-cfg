# quickshell cfg

Yes, this is vibecoded shlock. But it's MY vibecoded shlock. :wholesome:

## Quick Start
Launch shell directly:
```sh
quickshell
```

Run notification, markup, and bar pill test suites:
```sh
./tests.sh
```

## Dependencies
**Core**
- `quickshell` (with Qt6 Wayland / `qt6-wayland`)
- `hyprland` or `niri` (compositor backend selected automatically)
- `pipewire` + `pipewire-pulse` (`pactl`, `wpctl`)
- `brightnessctl` (backlight control)
- `networkmanager` (`nmcli` for Wi-Fi status & `nmtui`)
- A Nerd Font (default fallback: `ttf-jetbrains-mono-nerd`)

**Optional / Module-Specific**
- `cava` (CLI binary required for `CavaPill`)
- `matugen` (dynamic wallpaper color generation into `config/Theme.qml`)
- `pavucontrol` (audio pill click target)
- `kitty` (terminal launcher for `nmtui` and `update.sh`)
- `pacman-contrib` (`checkupdates`), `yay`, `flatpak` (for `UpdatesPill` and `scripts/update.sh`)
- `libnotify` (`notify-send` for `tests.sh`)

## Customization
- **Bar Layout (`modules/bar/BarWindow.qml`)**: Top-level bar configuration works like Waybar's module lists—add, remove, or reorder `*Pill` components inside `leftBarRow` or `rightBarRow` without touching backend services.
- **Compositors (`services/CompositorAdapter.qml` + `services/backends/`)**: `CompositorAdapter.qml` acts as a stable ABI and uses a `Loader` to instantiate only the active compositor backend (`HyprlandBackend.qml` or `NiriBackend.qml`). Adding Sway, MangoWC, or River means dropping a new backend file into `services/backends/` that implements the same 5 properties and 4 methods.
- **Theming & Shapes (`config/Theme.qml`)**: Matugen-ready color tokens, surface opacities (`barOpacity`, `drawerOpacity`, `cardOpacity`, `toastOpacity`), and module geometry (`pillRadius: -1` for capsules or `>= 0` for sharp boxes, `pillBorderWidth`, `pillBorderColor`).
- **Animations (`components/SpringBehavior.qml`)**: Centralized spring stiffness/damping presets shared across bar entrance, workspace indicator, and drawer transitions.
- **Docs**: See [docs/architecture.md](docs/architecture.md) and [docs/conventions.md](docs/conventions.md).

## Credits & Related Projects
- Heavily inspired by and modeled after [Waybar](https://github.com/Alexays/Waybar) (module ergonomics, compositor IPC patterns, and audio visualizer ideas).
- Built with [Quickshell](https://quickshell.org/), [Matugen](https://github.com/InioX/matugen), [Hyprland](https://hyprland.org/), [Niri](https://github.com/YaLTeR/niri), and [cava](https://github.com/karlstav/cava).
