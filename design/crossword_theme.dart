// crossword_theme.dart
// Drop into lib/core/theme/crossword_theme.dart
// Provides grid-specific color tokens as a ThemeExtension.
// Access via: Theme.of(context).extension<CrosswordTheme>()!

import 'package:flutter/material.dart';
import 'design_tokens.dart';

@immutable
class CrosswordTheme extends ThemeExtension<CrosswordTheme> {
  const CrosswordTheme({
    required this.cellActive,
    required this.wordHighlight,
    required this.crossHighlight,
    required this.gridBlack,
    required this.gridEmpty,
    required this.gridBorder,
    required this.gridOuterBorder,
    required this.cellText,
    required this.cellNumber,
    required this.stateCorrect,
    required this.stateIncorrect,
    required this.stateRevealed,
    required this.clueBarBg,
    required this.clueBarBorder,
    required this.clueBarDirection,
    required this.clueBarText,
    required this.activeClueBg,
    required this.crossClueBg,
    required this.keyboardBg,
    required this.keyDefault,
    required this.keySpecial,
    required this.keyCheck,
  });

  // ── Grid cell backgrounds ──────────────────────────────────────────────────
  /// Yellow — the focused cursor cell.
  final Color cellActive;

  /// Light blue — all cells in the active (across or down) word.
  final Color wordHighlight;

  /// Pale blue — cells in the crossing (perpendicular) word.
  final Color crossHighlight;

  /// Near-black — blocked/filled squares.
  final Color gridBlack;

  /// White/dark — empty cell background.
  final Color gridEmpty;

  // ── Grid borders ───────────────────────────────────────────────────────────
  /// Between cells — 0.5px.
  final Color gridBorder;

  /// Outer grid border — 2px.
  final Color gridOuterBorder;

  // ── Cell content ───────────────────────────────────────────────────────────
  /// User-entered letter color.
  final Color cellText;

  /// Clue number color (top-left of cell).
  final Color cellNumber;

  // ── Check / reveal states ─────────────────────────────────────────────────
  /// Green tint — checked correct cell.
  final Color stateCorrect;

  /// Red tint — checked incorrect cell.
  final Color stateIncorrect;

  /// Pale yellow — revealed cell background.
  final Color stateRevealed;

  // ── ClueBar ────────────────────────────────────────────────────────────────
  /// ClueBar background (primaryContainer equivalent).
  final Color clueBarBg;

  /// ClueBar bottom border.
  final Color clueBarBorder;

  /// Direction arrow color (↔ / ↕) and clue number.
  final Color clueBarDirection;

  /// Clue text color in ClueBar.
  final Color clueBarText;

  // ── Clue panel active rows ─────────────────────────────────────────────────
  /// Active across clue highlight in clue panel.
  final Color activeClueBg;

  /// Active cross clue highlight in clue panel.
  final Color crossClueBg;

  // ── Custom keyboard ────────────────────────────────────────────────────────
  final Color keyboardBg;
  final Color keyDefault;
  final Color keySpecial;   // ⌫ delete key
  final Color keyCheck;     // ✓ check key (primary blue)

  // ── Factory constructors ──────────────────────────────────────────────────

  /// Build from a [ColorScheme]. Pass the scheme from AppTheme.
  factory CrosswordTheme.of(ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;
    return CrosswordTheme(
      cellActive:       isLight ? CrosscueColors.cellActiveLight  : CrosscueColors.cellActiveDark,
      wordHighlight:    isLight ? CrosscueColors.wordHLLight       : CrosscueColors.wordHLDark,
      crossHighlight:   isLight ? CrosscueColors.crossHLLight      : CrosscueColors.crossHLDark,
      gridBlack:        isLight ? CrosscueColors.gridBlackLight    : CrosscueColors.gridBlackDark,
      gridEmpty:        isLight ? CrosscueColors.gridEmptyLight    : CrosscueColors.gridEmptyDark,
      gridBorder:       isLight ? CrosscueColors.gridBorderLight   : CrosscueColors.gridBorderDark,
      gridOuterBorder:  isLight ? CrosscueColors.onSurface1Light   : CrosscueColors.onSurface1Dark,
      cellText:         isLight ? CrosscueColors.onSurface1Light   : CrosscueColors.onSurface1Dark,
      cellNumber:       isLight ? CrosscueColors.onSurface2Light   : CrosscueColors.onSurface2Dark,
      stateCorrect:     isLight ? CrosscueColors.correctLight.withOpacity(0.20)   : CrosscueColors.correctDark.withOpacity(0.20),
      stateIncorrect:   isLight ? CrosscueColors.incorrectLight.withOpacity(0.20) : CrosscueColors.incorrectDark.withOpacity(0.20),
      stateRevealed:    isLight ? CrosscueColors.revealedLight     : CrosscueColors.revealedDark,
      clueBarBg:        isLight ? CrosscueColors.primaryContLight  : CrosscueColors.primaryContDark,
      clueBarBorder:    isLight ? CrosscueColors.wordHLLight       : CrosscueColors.wordHLDark,
      clueBarDirection: isLight ? CrosscueColors.primary           : CrosscueColors.primaryLight,
      clueBarText:      isLight ? CrosscueColors.onSurface1Light   : CrosscueColors.onSurface1Dark,
      activeClueBg:     isLight ? CrosscueColors.wordHLLight       : CrosscueColors.wordHLDark,
      crossClueBg:      isLight ? CrosscueColors.crossHLLight      : CrosscueColors.crossHLDark,
      keyboardBg:       const Color(0xFFECEFF1),
      keyDefault:       CrosscueColors.surfaceLight,
      keySpecial:       const Color(0xFFB0BEC5),
      keyCheck:         isLight ? CrosscueColors.primary           : CrosscueColors.primaryLight,
    );
  }

  // ── ThemeExtension overrides ───────────────────────────────────────────────

  @override
  CrosswordTheme copyWith({
    Color? cellActive,
    Color? wordHighlight,
    Color? crossHighlight,
    Color? gridBlack,
    Color? gridEmpty,
    Color? gridBorder,
    Color? gridOuterBorder,
    Color? cellText,
    Color? cellNumber,
    Color? stateCorrect,
    Color? stateIncorrect,
    Color? stateRevealed,
    Color? clueBarBg,
    Color? clueBarBorder,
    Color? clueBarDirection,
    Color? clueBarText,
    Color? activeClueBg,
    Color? crossClueBg,
    Color? keyboardBg,
    Color? keyDefault,
    Color? keySpecial,
    Color? keyCheck,
  }) {
    return CrosswordTheme(
      cellActive:       cellActive      ?? this.cellActive,
      wordHighlight:    wordHighlight   ?? this.wordHighlight,
      crossHighlight:   crossHighlight  ?? this.crossHighlight,
      gridBlack:        gridBlack       ?? this.gridBlack,
      gridEmpty:        gridEmpty       ?? this.gridEmpty,
      gridBorder:       gridBorder      ?? this.gridBorder,
      gridOuterBorder:  gridOuterBorder ?? this.gridOuterBorder,
      cellText:         cellText        ?? this.cellText,
      cellNumber:       cellNumber      ?? this.cellNumber,
      stateCorrect:     stateCorrect    ?? this.stateCorrect,
      stateIncorrect:   stateIncorrect  ?? this.stateIncorrect,
      stateRevealed:    stateRevealed   ?? this.stateRevealed,
      clueBarBg:        clueBarBg       ?? this.clueBarBg,
      clueBarBorder:    clueBarBorder   ?? this.clueBarBorder,
      clueBarDirection: clueBarDirection ?? this.clueBarDirection,
      clueBarText:      clueBarText     ?? this.clueBarText,
      activeClueBg:     activeClueBg    ?? this.activeClueBg,
      crossClueBg:      crossClueBg     ?? this.crossClueBg,
      keyboardBg:       keyboardBg      ?? this.keyboardBg,
      keyDefault:       keyDefault      ?? this.keyDefault,
      keySpecial:       keySpecial      ?? this.keySpecial,
      keyCheck:         keyCheck        ?? this.keyCheck,
    );
  }

  @override
  CrosswordTheme lerp(CrosswordTheme? other, double t) {
    if (other is! CrosswordTheme) return this;
    return CrosswordTheme(
      cellActive:       Color.lerp(cellActive, other.cellActive, t)!,
      wordHighlight:    Color.lerp(wordHighlight, other.wordHighlight, t)!,
      crossHighlight:   Color.lerp(crossHighlight, other.crossHighlight, t)!,
      gridBlack:        Color.lerp(gridBlack, other.gridBlack, t)!,
      gridEmpty:        Color.lerp(gridEmpty, other.gridEmpty, t)!,
      gridBorder:       Color.lerp(gridBorder, other.gridBorder, t)!,
      gridOuterBorder:  Color.lerp(gridOuterBorder, other.gridOuterBorder, t)!,
      cellText:         Color.lerp(cellText, other.cellText, t)!,
      cellNumber:       Color.lerp(cellNumber, other.cellNumber, t)!,
      stateCorrect:     Color.lerp(stateCorrect, other.stateCorrect, t)!,
      stateIncorrect:   Color.lerp(stateIncorrect, other.stateIncorrect, t)!,
      stateRevealed:    Color.lerp(stateRevealed, other.stateRevealed, t)!,
      clueBarBg:        Color.lerp(clueBarBg, other.clueBarBg, t)!,
      clueBarBorder:    Color.lerp(clueBarBorder, other.clueBarBorder, t)!,
      clueBarDirection: Color.lerp(clueBarDirection, other.clueBarDirection, t)!,
      clueBarText:      Color.lerp(clueBarText, other.clueBarText, t)!,
      activeClueBg:     Color.lerp(activeClueBg, other.activeClueBg, t)!,
      crossClueBg:      Color.lerp(crossClueBg, other.crossClueBg, t)!,
      keyboardBg:       Color.lerp(keyboardBg, other.keyboardBg, t)!,
      keyDefault:       Color.lerp(keyDefault, other.keyDefault, t)!,
      keySpecial:       Color.lerp(keySpecial, other.keySpecial, t)!,
      keyCheck:         Color.lerp(keyCheck, other.keyCheck, t)!,
    );
  }
}

/// Convenience extension — read CrosswordTheme from any BuildContext.
extension CrosswordThemeX on BuildContext {
  CrosswordTheme get cw => Theme.of(this).extension<CrosswordTheme>()!;
}

/// Usage example in a widget:
///
/// ```dart
/// final cw = context.cw;
///
/// // In CustomPainter.paint():
/// paint.color = cw.cellActive;          // focused cell
/// paint.color = cw.wordHighlight;       // active word cells
/// paint.color = cw.gridBlack;           // blocked squares
///
/// // In ClueBar widget:
/// Container(
///   color: cw.clueBarBg,
///   child: Text(clueText, style: TextStyle(color: cw.clueBarText)),
/// )
/// ```
