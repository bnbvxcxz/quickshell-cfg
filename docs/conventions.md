# Code & Commenting Standards

## 1. File Headers
- Open each file with 1–2 lines describing its purpose.
- No ASCII banners, divider lines, or author blocks.

## 2. Comments
- **State why, not what**: Omit comments that restate the code (`// loop over files`, `// init vars`). If the syntax is clear, leave it uncommented.
- **Document edge cases**: Only comment on non-obvious constraints—race conditions, upstream quirks, IPC timing, or performance bottlenecks.
- **No section labels**: Don't divide functions with numbered steps (`// 1. Handle Escape`) or prefix comments with `Note:` / `Fix:`. Extract a helper function instead.

## 3. Structure & Naming
- **Short local names**: Use concise names in local scopes (`buf`, `idx`, `norm`, `cwd`) over drawn-out identifiers (`candidateSearchBuffer`).
- **Guard clauses**: Return early on edge cases at the top of functions rather than nesting `if/else` blocks.
