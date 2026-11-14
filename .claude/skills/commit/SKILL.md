---
name: commit
description: Create a git commit in this repo. Use whenever committing changes. Enforces a one-line Conventional Commits message with no body, trailers, or AI attribution.
---

# Commit

1. Run `.\scripts\ciq.ps1 build` first; do not commit a non-compiling tree.
2. `git status` and `git diff --staged` — stage only files related to the change. Never stage `bin/`, keys (`*.der`, `developer_key*`) or `.env*`.
3. Commit with exactly one line:

   ```
   <type>(<optional scope>): <imperative summary, lowercase, no trailing period>
   ```

   - Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `build`, `ci`, `perf`, `style`.
   - Scope (optional): `view`, `delegate`, `model`, `resources`, `manifest`, `scripts`, `vscode`, `docs`.
   - Max ~72 characters.
   - **No body, no blank line, no trailers** — no `Co-Authored-By`, no `Generated with`, no `Signed-off-by`, no emoji.

   Use `git commit -m "<message>"` with a single `-m`.

Examples:

```
feat(view): show heart rate on main screen
fix(delegate): exit app on back button
docs: add team setup steps to quickstart
```

4. Do not push, amend, or rewrite history unless the user asks.
