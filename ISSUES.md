# Issues & Enhancements — Crosscue

Bugs and enhancement requests that fall outside the current sprint scope.
Agents should read this file before starting any sprint to check for items
that should be pulled into the current or upcoming sprint.

Status key: 🐛 Bug · ✨ Enhancement · 💡 Idea · ✅ Done · ❌ Won't Fix

---

## Open

| # | Type | Title | Sprint Target | Notes |
|---|------|-------|---------------|-------|
| 1 | ✨ | Long-press grid cell → contextual Check menu | Sprint 6 | See detail below |

---

## Detail

### #1 — Long-press grid cell → contextual Check menu

**Type:** Enhancement  
**Reported:** 2026-05-04  
**Target:** Sprint 6 (can pull into earlier sprint if time allows)

**Description:**  
Long-pressing any white (non-black) cell in the crossword grid should show a
contextual popup menu anchored near the tapped cell. This gives quick access
to check/reveal actions without reaching up to the `⋮` AppBar menu.

**Menu items:**
- Check letter
- Check word
- ─── (divider)
- Reveal letter
- Reveal word

> Reveal puzzle is intentionally omitted from this menu — it is a
> high-impact action that belongs in the AppBar menu with its confirmation
> dialog (topic-11).

**Implementation notes:**
- Detect long-press in `CrosswordGrid` via `GestureDetector.onLongPressStart`
  (use `onLongPressStart` to get the local position for menu anchoring).
- Convert the long-press position to `(row, col)` using the same hit-test math
  as `onTapDown`.
- Move focus to the long-pressed cell first, then show the menu so the menu
  always acts on the correct cell.
- Use `showMenu<_CheckRevealOption>()` with a `RelativeRect` derived from the
  tap position to anchor the menu near the cell.
- Call the same `SolveNotifier` methods (`checkCell`, `checkWord`, etc.) that
  the AppBar menu already uses.
- Key file: `crossword_grid.dart` — add long-press handler alongside the
  existing `onTapDown` handler.

---

## Closed

_Nothing closed yet._
