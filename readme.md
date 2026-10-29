# quickshell cfg

Yes, this is vibecoded shlock. But it's MY vibecoded shlock. :wholesome:

Modular Quickshell desktop shell environment targeting Wayland compositors.

## Architectural Layout

The project separates visual presentation from state management and layout tokens:

quickshell/
├── shell.qml                     # Application entry point; initializes windows and global hotkeys
├── config/                       # Design tokens and global scale definitions
│   ├── qmldir                    # Module registration for Config namespace
│   ├── Metrics.qml               # Display scaling, paddings, margins, layout dimensions
│   ├── Theme.qml                 # Matugen/Material3 palette bindings and semantic colors
│   └── Typography.qml            # Font families, point sizes, weights
├── services/                     # Background state engines and compositor adapters
│   ├── qmldir                    # Module registration for Services namespace
│   ├── CompositorAdapter.qml     # IPC bridge for window management and workspaces
│   ├── HardwareState.qml         # Battery, backlight, and network monitoring
│   ├── MediaState.qml            # MPRIS player tracking, playback, and metadata
│   └── SystemState.qml           # Package updates, idle status, resource monitoring
├── components/                   # Reusable UI primitives
│   ├── qmldir                    # Module registration for Components namespace
│   ├── MarqueeText.qml           # Overflow auto-scrolling label
│   ├── Pill.qml                  # Base visual container with standard borders and padding
│   └── SpringBehavior.qml        # Standardized animation physics and transitions
├── modules/                      # Shell surfaces and functional UI panels
│   ├── bar/                      # Top panel and status bar pills
│   │   ├── BarWindow.qml         # Layer shell bar root container
│   │   ├── AudioPill.qml         # Sink volume indicator and quick mute
│   │   ├── BacklightPill.qml     # Display brightness status
│   │   ├── BatteryPill.qml       # Power level and charging state
│   │   ├── ClockPill.qml         # Time and calendar trigger
│   │   ├── ControlCenterPill.qml # Control center drawer toggle
│   │   ├── IdlePill.qml          # Idle inhibitor toggle
│   │   ├── MprisPill.qml         # Compact bar track display
│   │   ├── NetworkPill.qml       # Connectivity status
│   │   ├── SystemTrayPill.qml    # SNI status notifier items
│   │   ├── UpdatesPill.qml       # Pending package updates
│   │   ├── WindowTitlePill.qml   # Active client title tracker
│   │   └── WorkspacesPill.qml    # Compositor workspace switcher
│   ├── controlcenter/            # Expandable utility panel
│   │   ├── ControlCenterWindow.qml # Root surface and positioning logic
│   │   ├── HardwareSliders.qml   # Audio and brightness sliders
│   │   ├── MprisCard.qml         # Full-sized media controller
│   │   ├── MprisCompactStrip.qml # Dense media controller variant
│   │   ├── MprisSideView.qml     # Side layout configuration
│   │   ├── MprisTopView.qml      # Top layout configuration
│   │   ├── NotificationHistory.qml # Scrollable notification ledger
│   │   ├── PanelTransitions.qml  # Reveal and dismiss spring animations
│   │   └── QuickToggles.qml      # Network, bluetooth, and utility toggles
│   ├── notifications/            # OSD toast notifications
│   │   └── NotificationToast.qml # Transient notification popups
│   └── osd/                      # Flyout indicators
│       └── OsdWindow.qml         # On-screen display for volume and brightness shifts
├── scripts/                      # External helper scripts
│   ├── check_updates.sh          # Package count queries (Arch, AUR, Flatpak)
│   └── update.sh                 # Terminal update launcher
└── tests.sh                      # Notification and markup stress test suite

## Organizational Rules

1. State Isolation: UI components (modules/, components/) must never query IPC or spawn background shell processes directly. All persistent state and external commands route strictly through singletons in services/.
2. Metrics & Tokens: Hardcoded pixel values, fixed margins, and raw hex codes are forbidden in visual modules. Dimensions route through Metrics.scaled(Theme.dimension, scaleFactor) and colors through Theme.*.
3. Lazy Lifecycle: Off-screen drawers, inactive multi-monitor subsurfaces, and hidden popups must be encapsulated in Loader elements to prevent continuous scene-graph layout passes when inactive.
4. Uniform Component Primitives: All bar items derive from components/Pill.qml, inheriting standardized typography, padding, radius, and unified pointer behavior.

## Running & Verification

Run notification and markup test suites:
./tests.sh

Launch shell directly:
quickshell
