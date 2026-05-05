# Crosscue — Design Handoff

## Overview

This package contains the complete visual design for Crosscue, a native Android crossword puzzle app built in Flutter. It covers 8 screens, a full design token system, and ready-to-use Flutter theme files.

## About the Design Files

The HTML files in this bundle (`Crosscue Design Review.html`, `Crosscue App Icon.html`) are **high-fidelity design references built in HTML/React**. They are prototypes showing intended look and behavior — not production code to copy directly.

Your task is to **recreate these designs in Flutter** using Material 3 (`useMaterial3: true`), Riverpod for state, and the existing project architecture described in `ARCHITECTURE.md` and `CONVENTIONS.md`. The `app_theme.dart` and `crossword_theme.dart` files in this package are ready to drop into `lib/core/theme/` — use them as your starting point.

## Fidelity

**High-fidelity.** These are pixel-close mockups with final colors, typography, spacing, and component hierarchy. Implement them faithfully. The only expected deltas are:
- Material 3 component defaults (ripple, elevation) — use them where appropriate
- Dynamic color on Android 12+ via `dynamic_color` package — the seed palette is the fallback only
- Exact grid cell sizes vary by puzzle dimensions — see Grid spec below

---

## Design Tokens

See `design_tokens.dart` for the full token set. Key values:

### Colors
| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `primary` | `#1565C0` | `#90CAF9` | Buttons, active states, app bar accent |
| `primaryMid` | `#1E88E5` | `#64B5F6` | In-progress indicators |
| `surface` | `#FFFFFF` | `#121212` | Screen backgrounds |
| `onSurface` | `#1A1A1A` | `#E0E0E0` | Body text |
| `onSurface2` | `#555555` | `#9E9E9E` | Secondary text |
| `onSurface3` | `#999999` | `#616161` | Hint/label text |
| `divider` | `#E8E8E8` | `#2C2C2C` | List separators |
| `cellActive` | `#FDD835` | `#FFD54F` | Active/focused cell |
| `wordHighlight` | `#BBDEFB` | `#1565C0` | Active word background |
| `crossHighlight` | `#E3F2FD` | `#0D47A1` | Crossing word background |
| `gridBlack` | `#111111` | `#1A1A1A` | Blocked squares |
| `gridBorder` | `#BDBDBD` | `#424242` | Cell borders |
| `correct` | `#4CAF50` | `#66BB6A` | Correct state |
| `incorrect` | `#EF5350` | `#EF9A9A` | Incorrect state |
| `primaryContainer` | `#E3F2FD` | `#1565C020` | ClueBar background, chip backgrounds |

### Typography
| Role | Flutter token | Size | Weight | Font |
|------|--------------|------|--------|------|
| Screen title | `titleLarge` | 22px | w500 | Roboto |
| Puzzle title | `titleMedium` | 18px | w600 | Roboto |
| Body / clue text | `bodyMedium` | 14px | w400 | Roboto |
| Small labels | `labelSmall` | 11px | w600 | Roboto |
| Timer | custom | 14–16px | w500 | Roboto Mono |
| Completion time | custom | 52px | w700 | Roboto Mono |
| Cell letters | custom | `cellSize * 0.52` | w700 | Roboto |
| Cell numbers | custom | `cellSize * 0.22` | w600 | Roboto |

### Spacing
- Screen horizontal padding: `16dp`
- App bar height: `56dp` (solve screen: `48dp`)
- Bottom nav height: `60dp`
- Section header padding: `16dp top, 6dp bottom`
- List row padding: `13dp vertical, 16dp horizontal`
- Button border radius: `8–10dp`
- Chip border radius: `20dp`

---

## App Icon

File: `crosscue-icon.svg`

- **Shape**: Rounded square, `rx=22.5%` of size (Material You adaptive icon)
- **Background**: `#0A2A6E` deep navy
- **Grid**: 3×3 crossword fragment, `PAD=66px` on 512px canvas, cell size `127px`
- **Black squares**: `(0,1)` and `(2,2)` — rotationally symmetric
- **Active row**: middle row (row 1) cells filled `#1E88E5`, letters C·U·E in white bold
- **Empty rows**: white cells, no letters
- **Clue numbers**: 1 at (0,0), 2 at (0,2), 3 at (1,0), 4 at (2,0)
- **Outer border**: `rgba(255,255,255,0.55)`, `10px` stroke

For Flutter adaptive icon:
- Foreground layer: the grid mark, white, on transparent
- Background layer: `#0A2A6E`
- Configure in `flutter_native_splash` with `color: '#0A2A6E'`

---

## Screen Specifications

### 01 · Home Screen (`HomeScreen`)
**Route:** `/` (Tab 0)

**Layout:** `Column` → `AppBar` (56dp) + scrollable `ListView` + `FAB` (absolute) + `NavigationBar` (60dp)

**App Bar:**
- Title: "Crosscue" — `titleLarge`, `#1A1A1A`
- Trailing: streak indicator — `🔥` flame icon + count in Roboto Mono 14px `#555555`
- Background: white, bottom border `1px #E8E8E8`
- No elevation

**Content (scrollable):**

1. **Today section header** — `11px`, `w600`, `#999999`, `UPPERCASE`, `letterSpacing 0.1em`, padding `20dp top 16dp horizontal`

2. **Puzzle info block** — padding `16dp horizontal`
   - Title: `18px w600 #1A1A1A` — e.g. "Wednesday, May 6"
   - Source + size + difficulty: `13px #555555` — e.g. "LA Times · 15×15 · Medium"
   - Constructor: `12px #999999`
   - Timer line: `13px #555555`, Roboto Mono for time value — "⏱ 4:23 elapsed"

3. **Primary CTA button** — `margin-bottom 24dp`
   - Background: `#1565C0`, white text `14px w600 letterSpacing 0.4`
   - Height: `46dp`, border radius: `8dp`
   - Label states: `"SOLVE"` (not started) → `"CONTINUE SOLVING"` (in progress) → `"REVIEW"` (completed)

4. **Divider** — `1px #E8E8E8`

5. **Recent section header** — same style as Today header, `16dp top padding`

6. **Recent puzzle list** — flat rows, `Divider` with `indent: 50dp` between items
   - Row padding: `13dp vertical, 16dp horizontal`
   - Status icon: 16px, `width: 20dp`, colors: `✓` green `#4CAF50`, `★` blue `#1565C0`, `◑` `#1E88E5`, `○` `#999999`
   - Title: `14px w500 #1A1A1A`
   - Subtitle: `12px #999999` (source · time · "PB" if personal best)
   - Trailing chevron: `18px #999999`

**FAB:**
- Position: `bottom: 76dp, right: 16dp`
- Size: `52×52dp`, border radius: `16dp`
- Background: `#1565C0`, white `+` icon `26px`
- Shadow: `0 2px 8px rgba(21,101,192,0.35)`
- Action: navigate to `/import`

---

### 02 · Solve Screen — 15×15 (`SolveScreen`)
**Route:** `/solve/:puzzleId`

**Layout:** `Column` → `AppBar` (48dp) + `ClueBar` + `CrosswordGrid` (full width) + `CluePanel` (flex) + `Keyboard`

**App Bar (compact, 48dp):**
- Leading: back arrow `←` `22px`
- Center: source name `15px w500`
- Trailing: timer `14px Roboto Mono #555555 letterSpacing 1` + overflow `⋮`
- No elevation, bottom border `1px #E8E8E8`
- Tapping timer toggles pause

**ClueBar:**
- Background: `#E3F2FD` (primaryContainer)
- Bottom border: `1.5px #BBDEFB`
- Padding: `9dp vertical, 12dp horizontal`
- Direction prefix: `"↔"` (across) or `"↕"` (down) — `12px w700 #1565C0`
- Clue number: `"14A"` — `12px w700 #1565C0`
- Clue text: `13px #1A1A1A lineHeight 1.35`
- Tapping ClueBar toggles direction

**Grid (`CrosswordGrid` / `CustomPainter`):**
- Width: `screenWidth` (full bleed, no padding)
- Cell size: `floor(screenWidth / puzzleWidth)` — e.g. `390 ÷ 15 = 26dp`
- Grid height: `cellSize * puzzleHeight`
- Outer border: `2px #1A1A1A`
- Cell borders: `0.5px #BDBDBD`

Cell states:
| State | Background |
|-------|-----------|
| Black | `#111111` |
| Empty | `#FFFFFF` |
| Active cursor | `#FDD835` |
| Active word | `#BBDEFB` |
| Cross word | `#E3F2FD` |
| Checked correct | `#4CAF50` 20% tint |
| Checked incorrect | `#EF5350` 20% tint |
| Revealed | `#FFF9C4` |

Cell content:
- Letter: centered, `cellSize * 0.52` px, `w700`, `#1A1A1A`
- Clue number: top-left `1.5dp` inset, `cellSize * 0.22` px, `w600`, `#555555`
- Active cursor: letter color `#1A1A1A` (no color change on yellow bg)

**CluePanel:**
- Two equal columns: ACROSS (left) + DOWN (right), separated by `1px #E8E8E8`
- Header: `10px w700 #999999 UPPERCASE letterSpacing 0.1em`, padding `7dp top 10dp horizontal`
- Clue row: `3dp vertical, 10dp horizontal`
  - Number: `10px w600 #999999`, `width: 14dp`
  - Text: `11px #555555 lineHeight 1.3`
  - Active clue bg: word = `#BBDEFB`, cross = `#E3F2FD`
  - Active clue text: `#1565C0 w600`
- Auto-scroll to keep active clue visible (`ScrollController.animateTo`, `150ms easeOut`)

**Custom Keyboard:**
- Background: `#ECEFF1`
- Padding: `6dp top, 4dp horizontal, 8dp bottom`
- Row gap: `4dp` between rows, `3dp` between keys
- Standard key: `height 36dp, flex 1, maxWidth 32dp`, white bg, `5dp` radius, `12px w500 #1A1A1A`, shadow `0 1px 1px rgba(0,0,0,0.15)`
- `⌫` key: `38dp wide`, `#B0BEC5` bg, white text
- `✓` key (Check Word): `38dp wide`, `#1565C0` bg, white text
- Three rows: QWERTYUIOP / ASDFGHJKL / ⌫ZXCVBNM✓

---

### 03 · Solve Screen — 5×5 (`SolveScreen`, small puzzle)

Same structure as 15×15 with these differences:
- Cell size: `390 ÷ 5 = 78dp` — large, comfortable touch targets
- CluePanel: more height available, `13px` text, `6dp` row padding, `14dp` horizontal padding
- Keyboard: slightly taller keys (`40dp`), larger font (`13px`)
- Clue numbers in cells: larger (`cellSize * 0.22 ≈ 17px`)
- Letters in cells: larger (`cellSize * 0.52 ≈ 40px`)

---

### 04 · Archive Screen (`ArchiveScreen`)
**Route:** `/archive` (Tab 1)

**Layout:** `Column` → `AppBar` + filter chips + sort bar + `ListView` + `NavigationBar`

**App Bar:**
- Title: "Archive"
- Trailing: import `⊕` icon in `#1565C0`

**Filter chips (horizontal scroll):**
- Padding: `10dp all, 16dp horizontal`
- Bottom border: `1px #E8E8E8`
- Chips: "All" (active) / "In Progress" / "Completed" / "Not Started"
- Active chip: bg `#E3F2FD`, text `#1565C0 w600`, border `#BBDEFB`
- Inactive chip: transparent bg, text `#999999`, border `#E8E8E8`
- Chip padding: `5dp vertical, 14dp horizontal`, border radius `20dp`

**Sort bar:**
- Padding: `8dp vertical, 16dp horizontal`
- Left: `"N puzzles"` in `12px #999999`
- Right: `"Sort: Date ↓"` in `12px #1565C0 w500`

**List rows:**
- Padding: `13dp vertical, 16dp horizontal`
- Status icon: `18px`, `width: 22dp`
  - `○` not started: `#999999`
  - `◑` in progress: `#1E88E5`
  - `✓` completed: `#4CAF50`
  - `★` personal best: `#1565C0`
- Title: `14px w500 #1A1A1A`
- Subtitle: `12px #999999` (source · size)
- Status note: `12px w500` in status color (e.g. "In progress · 4:23")
- Trailing: `›` `18px #999999`
- Divider: `1px #E8E8E8`, `indent: 52dp`

**Long-press:** show delete confirmation dialog (see `topic-17 §17`)

---

### 05 · Stats Screen (`StatsScreen`)
**Route:** `/stats` (Tab 2)

**Layout:** `Column` → `AppBar` + scrollable content + `NavigationBar`
**Style:** Fully flat — no cards, no elevation. Sections separated by `1px #E8E8E8` dividers.

**Streak section:**
- Two columns separated by `1px #E8E8E8 divider`
- Padding: `20dp top, 16dp all`
- Label: `11px w600 #999999 UPPERCASE`, `marginBottom 6dp`
- Value: `40px w700 #1A1A1A letterSpacing -1`
- Sub: `12px #999999 marginTop 4dp` ("days")

**Solve times section:**
- Padding: `16dp all`, bottom border `1px #E8E8E8`
- Header: `11px w600 #999999 UPPERCASE marginBottom 14dp`
- Three equal columns separated by `1px #E8E8E8`
- Value: `24px w700 Roboto Mono #1A1A1A letterSpacing -0.5`
- Label: `11px w600 #1565C0 marginTop 3dp`
- Sub: `10px #999999`

**Totals section:**
- Padding: `16dp all`, bottom border `1px #E8E8E8`
- Three equal columns
- Value: `28px w700 #1A1A1A letterSpacing -0.5`
- Label: `11px #999999 UPPERCASE letterSpacing 0.06em marginTop 4dp`

**Difficulty bars section:**
- Only rendered when ≥3 puzzles have difficulty metadata
- Padding: `16dp all`
- Header: `11px w600 #999999 UPPERCASE marginBottom 14dp`
- Each row: label `72dp right-aligned 12px #555555` + bar track `#E8E8E8 h8 r4` + fill + pct `12px #999999`
- Colors: Easy `#4CAF50`, Medium `#1565C0`, Hard `#FF9800`, Themeless `#999999`
- Row margin bottom: `10dp`

---

### 06 · Settings Screen (`SettingsScreen`)
**Route:** `/settings` (Tab 3)

**Layout:** `Column` → `AppBar` + scrollable `ListView` + `NavigationBar`
**Style:** Flat list — no card containers. Section labels above groups, `1px` dividers between rows.

**Section headers:** `11px w600 #999999 UPPERCASE letterSpacing 0.1em`, padding `16dp top, 16dp horizontal, 6dp bottom`

**Rows:**
- Padding: `14dp vertical, 16dp horizontal`
- Label: `15px #1A1A1A`
- Subtitle: `12px #999999 marginTop 2dp`
- Toggle: `44×24dp`, border radius `12dp`, thumb `20×20dp`, on: `#1565C0`, off: `#E8E8E8`
- Navigation rows: trailing `›` `18px #999999`
- Value rows: trailing `13px #999999`
- Divider between rows: `1px #E8E8E8 indent: 16dp`

**Sections:**
1. **Appearance** — Theme (system/light/dark), Colorblind mode (toggle, default off)
2. **Gameplay** — Haptics (toggle, default on), Sounds (toggle, default off), Skip filled cells (toggle, default off), Keyboard layout (nav row)
3. **Notifications** — Puzzle reminder (toggle + time row), Streak reminder (toggle + time row)
4. **Privacy & Data** — Crash reporting (toggle, default off, opt-in only), Export data (nav), Import data (nav), Delete all data (nav, trailing text `"Delete ›"` in `#EF5350`)
5. **Help** — How to play (nav), About Crosscue (nav, sub: version)

---

### 07 · Onboarding Screen (`OnboardingScreen`)
**Route:** `/onboarding` (full page, no shell)

**Layout:** `Column` → progress row + mock grid (flex 1) + instruction sheet

**Background:** `#0A2A6E` deep navy (full screen)

**Progress row:**
- Padding: `12dp vertical, 16dp horizontal`
- Progress dots: `8dp` circles `rgba(255,255,255,0.3)`, active: `20×8dp` pill `#FDD835`
- Skip: trailing `14px w500 rgba(255,255,255,0.65)`

**Mock grid:** `CrosswordGrid` component, `size=5`, `screenWidth=390` — same renderer as real puzzle. Full-width, centered vertically.

Mock grid structure:
```
Row 0: A  C  E  .  .    (. = black)
Row 1: L  O  .  T  E
Row 2: .  N  D  .  .
Row 3: G  E  .  P  S
Row 4: .  R  Y  E  .
```
Black squares: (0,3),(0,4),(1,2),(2,0),(2,3),(2,4),(3,2),(4,0),(4,4)

Active cell: (1,1) = "O" — cursor (yellow)
Active across word: (1,0)–(1,1) = "LO" (blue)
Cross word: (0,1)–(2,1) = "CON" (pale blue)

**Instruction sheet (bottom):**
- Background: white, border radius `20dp top`
- Drag handle: `36×4dp #E8E8E8 centered marginBottom 16dp`
- Step label: `11px w600 #1565C0 UPPERCASE letterSpacing 0.08em`
- Step title: `20px w700 #1A1A1A lineHeight 1.25 marginBottom 8dp`
- Step body: `14px #555555 lineHeight 1.5 marginBottom 20dp`
- CTA: `#1565C0` filled button, `14px w600 letterSpacing 0.3`, height `48dp`, radius `10dp`

**Three steps:**
1. "Tap a cell to focus it" / "Then type a letter. The cursor advances to the next empty cell automatically."
2. "Tap the focused cell again" / "This switches direction between Across and Down."
3. "Use Check or Reveal anytime" / "Find them in the ⋮ menu while solving." (timed 3s or tap Next)

**After step 3:**
- Title: "You're ready to solve!"
- Body: "Import a puzzle file to get started."
- CTA: "Import your first puzzle" → `/import`
- Secondary: "Maybe later" text button → `/`

---

### 08 · Completion Sheet
**Trigger:** `DraggableScrollableSheet` auto-shown when `PuzzleStatus` → `solved` / `solvedWithHelp` / `revealed`

**Background (behind sheet):** `rgba(10,42,110,0.88)` overlay on the completed grid

**Sheet:**
- Background: white, border radius `20dp top`
- Drag handle: `36×4dp`
- Solve label: `14px w600 #1A1A1A` — values per `topic-11`: "Clean solve" / "Solved with checks" / "Solved with hints" / "Puzzle revealed"
- Time: `52px w700 Roboto Mono #1A1A1A letterSpacing -2`
- PB line (clean solves only): `13px w500 #4CAF50` — "↑ New personal best — prev. X:XX"
- Divider
- Streak row: `🔥` icon + `15px w600 #1A1A1A` — "N-day streak"
- Divider

**Actions:**
1. "Share result" — outlined button `border 1px #E8E8E8`, `14px #555555`
   - Hidden if `completion_type == revealed`
2. "View filled grid" — text button `13px #999999`
3. "Next puzzle" — `#1565C0` filled button, `15px w600`

---

## Bottom Navigation Bar

4 tabs, `60dp` height, white bg, `1px #E8E8E8` top border.

Each tab: icon (24×24 SVG) + label (`11px`, active: `w600 #1565C0`, inactive: `w400 #999999`)

| Tab | Icon | Active state |
|-----|------|-------------|
| Today | 2×2 grid squares | 3 filled squares, 1 outlined |
| Archive | Calendar outline | Date cell filled |
| Stats | 3 ascending bars | All bars filled |
| Settings | 8-tooth gear | Filled gear, center hole punched via `evenodd` |

Icon style: `24×24`, filled shapes for active, outlined `1.8px stroke` for inactive, `strokeLinecap: round`.

---

## Navigation Bar Icons — SVG Specs

### Today
Active: 3 filled `7×7 rx1.5` squares at (3,3), (14,3), (3,14) + outlined square at (14,14)
Inactive: 4 outlined `7×7 rx1.5` squares

### Archive
Outlined rect `18×17 rx2` at (3,4) + horizontal line at y=9 + tick marks at x=8,16

### Stats
Three filled rects: `4×8 rx1` at x=4,y=13 / `4×13 rx1` at x=10,y=8 / `4×18 rx1` at x=16,y=3

### Settings (Gear)
8-tooth polygon: `r_outer=9.5`, `r_inner=7.2`, center hole `r=3.2`
Built via JS loop, rendered as SVG `path` with `fillRule="evenodd"`.

---

## Animations

| Event | Animation | Duration | Easing |
|-------|-----------|----------|--------|
| Letter entry | Scale `0.7→1.0` + fade in | 80ms | easeOut |
| Backspace | Scale `1.0→0.7` + fade out | 60ms | easeIn |
| Cell focus | Color fade to active | 150ms | easeOut |
| Direction toggle | Word highlight cross-fade | 200ms | easeInOut |
| Check correct | Card flip to green | 400ms | easeInOut |
| Check incorrect | Horizontal shake ±4dp ×3 + flip to red | 200ms | — |
| Reveal | Card flip to revealed yellow | 400ms | easeInOut |
| Word complete | Soft green pulse on word cells | 300ms | — |
| Puzzle complete | Grid wave flash (500ms) → confetti (800ms) → sheet slide up | — | — |
| Completion sheet | Slide up from bottom | 350ms | easeOut |

Use `flutter_animate` package for all micro-interactions. Respect `MediaQuery.of(context).disableAnimations`.

---

## Haptics

| Event | Flutter call |
|-------|-------------|
| Letter entry | `HapticFeedback.lightImpact()` |
| Backspace | `HapticFeedback.selectionClick()` |
| Direction toggle | `HapticFeedback.selectionClick()` |
| Word completion | `HapticFeedback.mediumImpact()` |
| Puzzle completion | 3-pulse via `vibration` package: light→medium→heavy |
| Check incorrect | `HapticFeedback.vibrate()` |

Gate all haptics on `hapticsEnabledProvider`.

---

## Files in This Package

| File | Description |
|------|-------------|
| `README.md` | This document |
| `Crosscue Design Review.html` | Hi-fi screen mockups — all 8 screens with annotations |
| `Crosscue App Icon.html` | 3 icon concepts + size previews |
| `crosscue-icon.svg` | Final production app icon (512×512) |
| `design_tokens.dart` | All color, typography and spacing tokens as Dart constants |
| `app_theme.dart` | Drop-in Flutter `ThemeData` for light + dark mode |
| `crossword_theme.dart` | `CrosswordTheme` extension with grid-specific color tokens |

---

## Implementation Checklist

- [ ] Drop `design_tokens.dart`, `app_theme.dart`, `crossword_theme.dart` into `lib/core/theme/`
- [ ] Update `app.dart` to use `AppTheme.light()` and `AppTheme.dark()`
- [ ] Copy `crosscue-icon.svg` to `assets/images/`, run `flutter_native_splash:create`
- [ ] Implement `BottomNav` with SVG gear icon (see Settings spec above)
- [ ] `CrosswordGrid` (`CustomPainter`): full-width, `cellSize = screenWidth / puzzleWidth`
- [ ] `ClueBar`: direction prefix, tappable to `toggleDirection`
- [ ] `CompletionStatsSheet`: `DraggableScrollableSheet`, conditional PB line, share hidden on revealed
- [ ] `OnboardingScreen`: const 5×5 mock grid, 3-step card overlay, ends with import CTA
- [ ] `ArchiveScreen`: flat list, filter chips, sort bar, long-press delete
- [ ] `StatsScreen`: flat sections, Roboto Mono times, difficulty chart gated on ≥3 data points
- [ ] `SettingsScreen`: flat list, no cards, delete row in red
- [ ] All animations via `flutter_animate`, gated on `disableAnimations`
- [ ] All haptics gated on `hapticsEnabledProvider`
