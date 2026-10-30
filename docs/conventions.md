# Quickshell Configuration: Code & Commenting Standards

This document establishes the uniform commenting, architectural, and search conventions across this Quickshell repository. The goal is zero noise: comments must add structural context, explain Wayland/QML edge cases, or provide high-speed `Ctrl+F` navigational anchors.

---

## 1. File Header Specification

Every QML and shell script file must begin with a concise 1–3 line header block explaining its single responsibility, its parent/consumer, and any screen/layer assumptions.

### QML File Header Template
```qml
/**
 * [Component/Module Name]
 * Role: <High-level responsibility>
 * Context: <Where this is loaded (e.g., inside shell.qml Variants, BarWindow, standalone PanelWindow)>
 * Layer: <Overlay | Top | Background | N/A>
 */
```

### Script File Header Template
```bash
#!/usr/bin/env bash
# [Script Name]
# Role: <What data it polls, streams, or updates>
# Invocation: <Quickshell Process / cron / manual>
```

---

## 2. In-Code Commenting Rules: High Signal, Zero Bloat

1. **No Obvious Echoing**:
   - ❌ Bad: `// Set width to 400`
   - ✅ Good: *(Omit comment)*
2. **Explain the "Why", Not the "What"**:
   - Clarify non-obvious workarounds, protocol limits, or math tricks.
   - Example: Why opposing anchors are omitted to permit `SpringAnimation` coordinate transforms under Layer Shell.
3. **Wayland & Layer-Shell Nuances**:
   - Document any behavior dictated by compositor semantics (e.g., Hyprland negative-x geometry, exclusive zones, focus grabs, input regions).

---

## 3. Fast Navigational Anchors (`Ctrl+F` Registry)

To jump straight to key trouble spots without scrolling, use the following standardized tag prefixes:

| Anchor Tag | Target Purpose |
|---|---|
| `// [ANCHOR:SCREEN_LOGIC]` | Multi-head screen geometry, primary check, or output coordinate matching |
| `// [ANCHOR:LAYER_SHELL]` | Wayland layer shell properties (`exclusiveZone`, `keyboardFocus`, namespace) |
| `// [ANCHOR:SPRING_ANIM]` | Spring behaviors, custom easing curves, or transition state targets |
| `// [ANCHOR:HOVER_TRIGGER]`| MouseArea bounds, edge peek triggers, or hover activation zones |
| `// [ANCHOR:IPC_BINDING]` | Service bindings to Hyprland socket, DBus, MPRIS, or shell scripts |
| `// [ANCHOR:WORKAROUND]` | Fixes for upstream Qt/Quickshell/Wayland idiosyncrasies |

---

## 4. Standard File Architecture Overview

```
quickshell-cfg/
├── shell.qml                        # Root entry; instantiates Variants across Quickshell.screens
├── components/                      # Reusable primitives (buttons, pills, springs)
│   ├── Pill.qml
│   ├── SpringBehavior.qml
│   └── qmldir
├── config/                          # Shared theme tokens and geometry metrics
│   ├── Metrics.qml                  # Margins, widths, bar heights, radiuses
│   ├── Theme.qml                    # Color palettes and visual states
│   ├── Typography.qml               # Font definitions and sizes
│   └── qmldir
├── services/                        # System & hardware background monitors
│   ├── CompositorAdapter.qml        # Screen coordinate tracking and active outputs
│   ├── HardwareState.qml            # CPU, RAM, battery, backlight state
│   ├── MediaState.qml               # MPRIS integration
│   ├── SystemState.qml              # Global UI state (e.g. controlCenterOpen)
│   └── qmldir
├── modules/
│   ├── bar/                         # Status bar window and individual status pills
│   │   ├── BarWindow.qml            # PanelWindow instantiated per monitor
│   │   └── *Pill.qml
│   ├── controlcenter/               # Multi-monitor drawer and quick toggle panel
│   │   ├── ControlCenterWindow.qml  # Main panel window with screen-aware geometry
│   │   ├── PanelTransitions.qml     # Spring and drop state transitions
│   │   └── *.qml                    # Sliders, MPRIS views, toggles
│   ├── osd/                         # Volume/brightness on-screen display
│   └── notifications/               # Desktop notification toasts and popups
└── docs/
    └── COMMENTING_STANDARDS.md      # This specification file
```

---

## 5. Screen & Coordinate Convention Reference

Quickshell monitors report absolute compositor coordinates via `screen.x` and `screen.y`:

- **Primary Display**: Evaluated as `screen.x === 0 && screen.y === 0`.
- **Auto-Right Display**: Evaluated as `screen.x > 0`. Control drawer enters from the screen edge and springs into position.
- **Auto-Left Display**: Evaluated as `screen.x < 0`. Control drawer docks upward toward the top bar and drops on left hover.
- **Rule for PanelWindows**: Always leave the opposing edge anchor unset (e.g., do not set both `anchors.left` and `anchors.right`) when an element needs transform-based spring animations.