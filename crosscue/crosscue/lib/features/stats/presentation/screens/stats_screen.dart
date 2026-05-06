import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/crossword_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../domain/models/stats_data.dart';
import '../providers/stats_providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsDataProvider);
    final theme = CrosswordTheme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats'),
        centerTitle: true,
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) => stats.startedCount == 0
            ? const _EmptyStats()
            : _StatsBody(stats: stats, theme: theme),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.stats, required this.theme});

  final StatsData stats;
  final CrosswordTheme theme;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _StreakSection(
          stats: stats,
          theme: theme,
          colorScheme: Theme.of(context).colorScheme,
        ),
        const SizedBox(height: CrosscueSpacing.screenM),
        _TotalsSection(
          stats: stats,
          theme: theme,
          colorScheme: Theme.of(context).colorScheme,
        ),
        const SizedBox(height: CrosscueSpacing.screenM),
        if (stats.hasSolves) ...[
          _TimesSection(
            stats: stats,
            theme: theme,
            colorScheme: Theme.of(context).colorScheme,
          ),
          const SizedBox(height: CrosscueSpacing.screenM),
        ],
        if (_hasPB(stats)) ...[
          _PersonalBestsSection(
            stats: stats,
            theme: theme,
            colorScheme: Theme.of(context).colorScheme,
          ),
          const SizedBox(height: CrosscueSpacing.screenM),
        ],
        _CompletionSection(
          stats: stats,
          theme: theme,
          colorScheme: Theme.of(context).colorScheme,
        ),
        const SizedBox(height: CrosscueSpacing.screenM),
      ],
    );
  }

  static bool _hasPB(StatsData s) =>
      s.personalBest15x15Ms != null ||
      s.personalBest21x21Ms != null ||
      s.personalBestMiniMs != null;
}

// ---------------------------------------------------------------------------
// Streak section
// ---------------------------------------------------------------------------

class _StreakSection extends StatelessWidget {
  const _StreakSection({required this.stats, required this.theme, required this.colorScheme});

  final StatsData stats;
  final CrosswordTheme theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader('Streak', theme: theme),
        const SizedBox(height: CrosscueSpacing.screenXS),
        _StreakCard(
          stats: stats,
          theme: theme,
          colorScheme: colorScheme,
        ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.stats, required this.theme, required this.colorScheme});

  final StatsData stats;
  final CrosswordTheme theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CrosscueSpacing.buttonRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CrosscueSpacing.screenXS),
        child: Row(
          children: [
            Expanded(
              child: _StatCell(
                icon: Icons.local_fire_department_rounded,
                iconColor: colorScheme.error,
                value: '${stats.currentStreak}',
                label: 'Current streak',
                suffix: stats.currentStreak == 1 ? 'day' : 'days',
                theme: theme,
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: CrosscueSpacing.screenXS),
            Expanded(
              child: _StatCell(
                icon: Icons.emoji_events_outlined,
                iconColor: colorScheme.tertiary,
                value: '${stats.longestStreak}',
                label: 'Longest streak',
                suffix: stats.longestStreak == 1 ? 'day' : 'days',
                theme: theme,
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Totals section
// ---------------------------------------------------------------------------

class _TotalsSection extends StatelessWidget {
  const _TotalsSection({required this.stats, required this.theme, required this.colorScheme});

  final StatsData stats;
  final CrosswordTheme theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader('Solves', theme: theme),
        const SizedBox(height: CrosscueSpacing.screenXS),
        _TotalsCard(
          stats: stats,
          theme: theme,
          colorScheme: colorScheme,
        ),
      ],
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.stats, required this.theme, required this.colorScheme});

  final StatsData stats;
  final CrosswordTheme theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CrosscueSpacing.buttonRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CrosscueSpacing.screenXS),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatRow(
              label: 'Total solved',
              value: '${stats.totalSolved}',
              theme: theme,
              colorScheme: colorScheme,
            ),
            const Divider(height: 1),
            _StatRow(
              label: 'Clean solves',
              value: '${stats.cleanSolves}',
              sublabel: stats.totalSolved > 0
                  ? '${(stats.cleanSolves / stats.totalSolved * 100).round()}%'
                  : null,
              theme: theme,
              colorScheme: colorScheme,
            ),
            const Divider(height: 1),
            _StatRow(
              label: 'Solved with help',
              value: '${stats.hintedCheckedSolves}',
              theme: theme,
              colorScheme: colorScheme,
            ),
            const Divider(height: 1),
            _StatRow(
              label: 'Puzzles revealed',
              value: '${stats.revealedCount}',
              theme: theme,
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Times section
// ---------------------------------------------------------------------------

class _TimesSection extends StatelessWidget {
  const _TimesSection({required this.stats, required this.theme, required this.colorScheme});

  final StatsData stats;
  final CrosswordTheme theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader('Times', theme: theme),
        const SizedBox(height: CrosscueSpacing.screenXS),
        _TimesCard(
          stats: stats,
          theme: theme,
          colorScheme: colorScheme,
        ),
      ],
    );
  }
}

class _TimesCard extends StatelessWidget {
  const _TimesCard({required this.stats, required this.theme, required this.colorScheme});

  final StatsData stats;
  final CrosswordTheme theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CrosscueSpacing.buttonRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CrosscueSpacing.screenXS),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (stats.averageElapsedMs != null) ...[
              _StatRow(
                label: 'Average time',
                value: _formatMs(stats.averageElapsedMs!),
                theme: theme,
                colorScheme: colorScheme,
              ),
              const Divider(height: 1),
            ],
            if (stats.sevenDayAverageMs != null)
              _StatRow(
                label: '7-day average',
                value: _formatMs(stats.sevenDayAverageMs!),
                theme: theme,
                colorScheme: colorScheme,
              )
            else
              _StatRow(
                label: '7-day average',
                value: '–',
                sublabel: 'No solves in the last 7 days',
                theme: theme,
                colorScheme: colorScheme,
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Personal bests section
// ---------------------------------------------------------------------------

class _PersonalBestsSection extends StatelessWidget {
  const _PersonalBestsSection({required this.stats, required this.theme, required this.colorScheme});

  final StatsData stats;
  final CrosswordTheme theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader('Personal Bests', theme: theme),
        const SizedBox(height: CrosscueSpacing.screenXS),
        _PersonalBestsCard(
          stats: stats,
          theme: theme,
          colorScheme: colorScheme,
        ),
      ],
    );
  }
}

class _PersonalBestsCard extends StatelessWidget {
  const _PersonalBestsCard({required this.stats, required this.theme, required this.colorScheme});

  final StatsData stats;
  final CrosswordTheme theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    if (stats.personalBestMiniMs != null) {
      rows.add(_StatRow(
        label: 'Mini best',
        value: _formatMs(stats.personalBestMiniMs!),
        theme: theme,
        colorScheme: colorScheme,
      ));
    }
    if (stats.personalBest15x15Ms != null) {
      if (rows.isNotEmpty) rows.add(const Divider(height: 1));
      rows.add(_StatRow(
        label: '15×15 best',
        value: _formatMs(stats.personalBest15x15Ms!),
        theme: theme,
        colorScheme: colorScheme,
      ));
    }
    if (stats.personalBest21x21Ms != null) {
      if (rows.isNotEmpty) rows.add(const Divider(height: 1));
      rows.add(_StatRow(
        label: '21×21 best',
        value: _formatMs(stats.personalBest21x21Ms!),
        theme: theme,
        colorScheme: colorScheme,
      ));
    }
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CrosscueSpacing.buttonRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CrosscueSpacing.screenXS),
        child: Column(children: rows),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Completion section
// ---------------------------------------------------------------------------

class _CompletionSection extends StatelessWidget {
  const _CompletionSection({required this.stats, required this.theme, required this.colorScheme});

  final StatsData stats;
  final CrosswordTheme theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader('Completion', theme: theme),
        const SizedBox(height: CrosscueSpacing.screenXS),
        _CompletionCard(
          stats: stats,
          theme: theme,
          colorScheme: colorScheme,
        ),
      ],
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.stats, required this.theme, required this.colorScheme});

  final StatsData stats;
  final CrosswordTheme theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final pct = (stats.completionRate * 100).round();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CrosscueSpacing.buttonRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CrosscueSpacing.screenXS),
        child: _StatRow(
          label: 'Completion rate',
          value: '$pct%',
          sublabel: '${stats.totalSolved + stats.revealedCount} of ${stats.startedCount} started',
          theme: theme,
          colorScheme: colorScheme,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared sub-widgets
// ---------------------------------------------------------------------------

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.sublabel,
    required this.theme,
    required this.colorScheme,
  });

  final String label;
  final String value;
  final String? sublabel;
  final CrosswordTheme theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (sublabel != null)
                Text(
                  sublabel!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    this.suffix,
    required this.theme,
    required this.colorScheme,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final String? suffix;
  final CrosswordTheme theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        if (suffix != null)
          Text(
            suffix!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label, {required this.theme});

  final String label;
  final CrosswordTheme theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: colorScheme.primary,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyStats extends StatelessWidget {
  const _EmptyStats();

  @override
  Widget build(BuildContext context) {
    final theme = CrosswordTheme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'No stats yet',
            style: theme.textTheme.titleMedium?.copyWith(
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Solve a puzzle to start tracking your stats.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _formatMs(int ms) {
  final total = ms ~/ 1000;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '$m:${s.toString().padLeft(2, '0')}';
}
