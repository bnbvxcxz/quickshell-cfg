# Code & Commenting Conventions

## 1. File Headers
- Start each file with 1–2 lines explaining what it does.
- No ASCII banners, divider lines, or author blocks.

## 2. Comments
- Explain *why* something is written a certain way (race conditions, Qt layout quirks, IPC timing) instead of restating the code.
- In larger files, brief comments on major sections or state transitions are good so it's easy to scan.
- Don't use numbered step comments (`// 1. Do X`) or `Note:` / `Fix:` prefixes.

## 3. Structure & Theming
- Keep local variable names short (`buf`, `idx`, `norm`, `nid`).
- Return early on edge cases instead of nesting `if/else` blocks.
- Keep state and IPC in `services/`, config/tokens in `config/`, reusable UI parts in `components/`, and actual surfaces in `modules/`. Swapping or restyling a bar module shouldn't require touching `services/`.
- **Theming goes through `config/`**: `Theme.qml` is reserved for Matugen's color palette. All layout, gap, corner, border, and opacity tokens (`moduleRadius`, `baseModuleGapX`, `baseModuleGapY`, `cornerRadius`, `*Opacity`) belong in `Metrics.qml` so wallpaper reloads never wipe out layout tweaks.
- **Per-monitor scaling**: Derive pixel sizes with `Metrics.scaleFor(screen)` and `Metrics.scaled()` instead of hardcoding monitor names or pixel dimensions.
