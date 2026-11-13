# Code & Commenting Standards

## 1. File Headers
- Open each file with 1–2 lines describing its purpose.
- No ASCII banners, divider lines, or author blocks.

## 2. Comments
- **State why and clarify structure**: Omit trivial comments that restate syntax (`// loop over files`, `// init vars`), but do add brief, practical comments on major sections, state transitions, and multi-step flows in larger files so contributors can follow the architecture quickly.
- **Document edge cases**: Comment on non-obvious constraints—race conditions, upstream quirks, IPC timing, coordinate mapping, or performance choices.
- **No section banners or numbered steps**: Don't divide functions with numbered steps (`// 1. Handle Escape`) or prefix comments with `Note:` / `Fix:`. Extract a helper function or use a concise descriptive comment instead.

## 3. Structure, Modularity, & Scaling
- **Short local names**: Use concise names in local scopes (`buf`, `idx`, `norm`, `cwd`) over drawn-out identifiers (`candidateSearchBuffer`).
- **Guard clauses**: Return early on edge cases at the top of functions rather than nesting `if/else` blocks.
- **Strict layer separation**: Keep state and IPC logic inside `services/` singletons, design tokens in `config/`, reusable primitives in `components/`, and visual layouts in `modules/`. Adding, removing, or reskinning a bar pill or control center widget must never require editing `services/`.
- **Token-driven theming**: Route surface colors, corner radii (`pillRadius`, `cornerRadius`), borders (`pillBorderWidth`), and opacities through `Theme.qml` so switching between capsule pills and sharp boxes—or swapping Matugen palettes—takes a single token edit.
- **Drop-in per-monitor scaling**: Never hardcode pixel dimensions or monitor names for layout sizing; derive sizes from `Metrics.scaleFor(screen)` and `Metrics.scaled()` so the shell adapts dynamically to any display or host.
