import 'package:flutter/material.dart';

import 'package:crosscue/core/theme/crossword_theme.dart';
import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:crosscue/core/domain/models/clue.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/features/solve/presentation/notifiers/solve_state.dart';

/// Two-column scrollable clue panel (Sprint 10).
///
/// Design spec:
/// - Two equal columns: ACROSS (left) + DOWN (right), 1px divider between.
/// - Header: 10px w700 #999999 UPPERCASE letterSpacing 0.1em, 7dp top / 10dp H padding.
/// - Clue row: fixed 42dp height, tappable.
///   - Number: 10px w600 #999999, width 18dp.
///   - Text: 14px #555555 lineHeight 1.3.
///   - Active clue bg: word = #BBDEFB, cross = #E3F2FD.
///   - Active clue text: #1565C0 w600.
/// - Auto-scroll active clue into view (150ms easeOut).
class CluePanel extends StatefulWidget {
  const CluePanel({
    super.key,
    required this.solveState,
    required this.onClueTap,
  });

  final SolveState solveState;
  final ValueChanged<Clue> onClueTap;

  @override
  State<CluePanel> createState() => _CluePanelState();
}

class _CluePanelState extends State<CluePanel> {
  final _acrossController = ScrollController();
  final _downController = ScrollController();

  @override
  void dispose() {
    _acrossController.dispose();
    _downController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CluePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Scroll active clue into view when focus changes.
    final state = widget.solveState;
    final oldState = oldWidget.solveState;
    if (state.focus != oldState.focus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollActiveIntoView(state);
      });
    }
  }

  void _scrollActiveIntoView(SolveState state) {
    final acrossClues = widget.solveState.puzzle.clues
        .where((c) => c.direction == Direction.across)
        .toList();
    final downClues = widget.solveState.puzzle.clues
        .where((c) => c.direction == Direction.down)
        .toList();

    final activeClue = state.activeClue;
    final crossClue = state.crossClue;

    if (activeClue != null) {
      final ctrl = activeClue.direction == Direction.across
          ? _acrossController
          : _downController;
      final clues =
          activeClue.direction == Direction.across ? acrossClues : downClues;
      _scrollToClue(ctrl, clues, activeClue);
    }
    if (crossClue != null) {
      final ctrl = crossClue.direction == Direction.across
          ? _acrossController
          : _downController;
      final clues =
          crossClue.direction == Direction.across ? acrossClues : downClues;
      _scrollToClue(ctrl, clues, crossClue);
    }
  }

  void _scrollToClue(
    ScrollController ctrl,
    List<Clue> clues,
    Clue target,
  ) {
    if (!ctrl.hasClients) return;
    const rowH = _kRowH;
    const headerH = _kHeaderH;
    final idx = clues.indexWhere((c) => c.number == target.number);
    if (idx < 0) return;
    final viewportH = ctrl.position.viewportDimension;
    final centeredOffset = headerH + idx * rowH - (viewportH - rowH) / 2;
    final offset = centeredOffset.clamp(
      0.0,
      ctrl.position.maxScrollExtent,
    );
    ctrl.animateTo(
      offset,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.solveState;
    final xwTheme =
        Theme.of(context).extension<CrosswordTheme>() ?? CrosswordTheme.light();

    final acrossClues = state.puzzle.clues
        .where((c) => c.direction == Direction.across)
        .toList();
    final downClues =
        state.puzzle.clues.where((c) => c.direction == Direction.down).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final panelHeight = constraints.maxHeight.clamp(
          0.0,
          _kHeaderH + _kRowH * 5,
        );
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: panelHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ACROSS column
                Expanded(
                  child: _ClueColumn(
                    header: 'Across',
                    clues: acrossClues,
                    activeClue: state.activeClue,
                    crossClue: state.crossClue,
                    controller: _acrossController,
                    xwTheme: xwTheme,
                    onClueTap: widget.onClueTap,
                  ),
                ),

                // Divider
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Theme.of(context).dividerColor,
                ),

                // DOWN column
                Expanded(
                  child: _ClueColumn(
                    header: 'Down',
                    clues: downClues,
                    activeClue: state.activeClue,
                    crossClue: state.crossClue,
                    controller: _downController,
                    xwTheme: xwTheme,
                    onClueTap: widget.onClueTap,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Row / header heights used for scroll offset math.
const double _kHeaderH = 28.0; // 7dp top + ~10dp text + 11dp bottom ~= 28
const double _kRowPadH = 10.0;
const double _kRowH = 42.0;

class _ClueColumn extends StatelessWidget {
  const _ClueColumn({
    required this.header,
    required this.clues,
    required this.activeClue,
    required this.crossClue,
    required this.controller,
    required this.xwTheme,
    required this.onClueTap,
  });

  final String header;
  final List<Clue> clues;
  final Clue? activeClue;
  final Clue? crossClue;
  final ScrollController controller;
  final CrosswordTheme xwTheme;
  final ValueChanged<Clue> onClueTap;

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: CrosscueColors.onSurface3Light, // #999999
      letterSpacing: 1.0,
      height: 1.2,
    );

    return ListView.builder(
      controller: controller,
      padding: EdgeInsets.zero,
      itemCount: clues.length + 1, // +1 for header
      itemBuilder: (ctx, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              _kRowPadH,
              7,
              _kRowPadH,
              4,
            ),
            child: Text(header.toUpperCase(), style: headerStyle),
          );
        }
        final clue = clues[i - 1];
        final isActive = activeClue?.number == clue.number &&
            activeClue?.direction == clue.direction;
        final isCross = crossClue?.number == clue.number &&
            crossClue?.direction == clue.direction;

        Color? rowBg;
        if (isActive) {
          rowBg = xwTheme.activeClueBg;
        } else if (isCross) {
          rowBg = xwTheme.crossClueBg;
        }

        final numStyle = TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isActive || isCross
              ? xwTheme.clueBarDirection
              : CrosscueColors.onSurface3Light, // #999999 per spec
          height: 1.3,
        );
        final textStyle = TextStyle(
          fontSize: 14,
          fontWeight: isActive || isCross ? FontWeight.w600 : FontWeight.w400,
          color: isActive || isCross
              ? xwTheme.clueBarDirection
              : xwTheme.cellNumber,
          height: 1.3,
        );

        return SizedBox(
          height: _kRowH,
          child: Material(
            color: rowBg ?? Colors.transparent,
            child: InkWell(
              onTap: () => onClueTap(clue),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: _kRowPadH,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 18,
                      child: Text('${clue.number}', style: numStyle),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        clue.text,
                        style: textStyle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
