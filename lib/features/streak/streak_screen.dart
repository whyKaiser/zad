import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../data/diary_repository.dart';
import '../../data/points_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/rank.dart';
import '../../theme/app_theme.dart';

class StreakScreen extends StatelessWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final repo = context.watch<DiaryRepository>();
    final streak = repo.streakDays;
    final points = context.watch<PointsController>().total;
    final rank = rankFromPoints(points);
    final nextRank = rank.index < Rank.values.length - 1
        ? Rank.values[rank.index + 1]
        : null;
    final rankProgress = nextRank != null
        ? ((points - rank.minPoints) / (nextRank.minPoints - rank.minPoints)).clamp(0.0, 1.0)
        : 1.0;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Row(children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
              ),
              Text(loc.isAr ? 'الستريك والرانك' : 'Streak & Rank',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: c.textPrimary)),
            ]).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 20),

            // streak card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: c.border),
              ),
              child: Column(
                children: [
                  Icon(Icons.local_fire_department_rounded, size: 48, color: c.accent2),
                  const SizedBox(height: 8),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: streak.toDouble()),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => Text('${v.round()}',
                        style: TextStyle(fontSize: 56, fontWeight: FontWeight.w800, color: c.textPrimary, height: 1)),
                  ),
                  Text(loc.isAr ? 'يوم متتالي' : 'day streak',
                      style: TextStyle(fontSize: 16, color: c.textSecondary)),
                  const SizedBox(height: 16),
                  _streakCalendar(c, streak),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 500.ms).slideY(begin: 0.15),
            const SizedBox(height: 16),

            // rank card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(rank.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(loc.isAr ? rank.nameAr : rank.nameEn,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.textPrimary)),
                      Text('$points ${loc.points}',
                          style: TextStyle(fontSize: 13, color: c.textSecondary)),
                    ]),
                  ]),
                  const SizedBox(height: 16),
                  if (nextRank != null) ...[
                    Row(children: [
                      Text(loc.isAr ? 'إلى ${nextRank.nameAr}' : 'To ${nextRank.nameEn}',
                          style: TextStyle(fontSize: 12, color: c.textSecondary)),
                      const Spacer(),
                      Text('${nextRank.minPoints - points} ${loc.points}',
                          style: TextStyle(fontSize: 12, color: c.accent)),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(children: [
                        Container(height: 8, color: c.track),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: rankProgress),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => FractionallySizedBox(
                            widthFactor: v,
                            child: Container(height: 8, color: c.accent),
                          ),
                        ),
                      ]),
                    ),
                  ] else
                    Text(loc.isAr ? '🎉 وصلت للقمة!' : '🎉 Max rank!',
                        style: TextStyle(fontSize: 14, color: c.accent2)),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            const SizedBox(height: 20),

            // all ranks
            Text(loc.isAr ? 'جميع الرانكات' : 'All ranks',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.textPrimary))
                .animate().fadeIn(delay: 280.ms),
            const SizedBox(height: 12),
            ...Rank.values.asMap().entries.map((e) {
              final r = e.value;
              final isCurrentRank = r == rank;
              final unlocked = points >= r.minPoints;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isCurrentRank ? c.accent.withOpacity(0.1) : c.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isCurrentRank ? c.accent : c.border,
                    width: isCurrentRank ? 2 : 1,
                  ),
                ),
                child: Row(children: [
                  Text(r.emoji, style: TextStyle(fontSize: 22, color: unlocked ? null : c.textTertiary.withOpacity(0.4))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(loc.isAr ? r.nameAr : r.nameEn,
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: unlocked ? c.textPrimary : c.textTertiary,
                        )),
                    Text('${r.minPoints}+ ${loc.points}',
                        style: TextStyle(fontSize: 11, color: c.textTertiary)),
                  ])),
                  if (isCurrentRank)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: c.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(loc.isAr ? 'أنت هنا' : 'You',
                          style: TextStyle(fontSize: 10, color: c.onAccent, fontWeight: FontWeight.w600)),
                    )
                  else if (!unlocked)
                    Icon(Icons.lock_outline_rounded, size: 16, color: c.textTertiary),
                ]),
              ).animate().fadeIn(delay: (300 + e.key * 40).ms);
            }),
          ],
        ),
      ),
    );
  }

  Widget _streakCalendar(c, int streak) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(14, (i) {
        final daysAgo = 13 - i;
        final active = daysAgo < streak;
        final isToday = daysAgo == 0;
        return Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: active ? c.accent2 : c.track,
            borderRadius: BorderRadius.circular(4),
            border: isToday ? Border.all(color: c.accent, width: 2) : null,
          ),
        );
      }),
    );
  }
}
