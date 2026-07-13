import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/motion.dart';
import '../../data/challenges_data.dart';
import '../../data/daily_tasks_controller.dart';
import '../../data/diary_repository.dart';
import '../../data/points_controller.dart';
import '../../data/water_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/challenge.dart';
import '../../models/rank.dart';
import '../../theme/app_theme.dart';
import 'daily_tasks_screen.dart';

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final tasks = context.watch<DailyTasksController>().tasks;
    final doneTasks = tasks.where((t) => t.isDone).length;
    final todayPts = context.watch<PointsController>().todayTotal();
    final totalPts = context.watch<PointsController>().total;
    final repo = context.watch<DiaryRepository>();
    final water = context.watch<WaterController>();

    final rank = rankFromPoints(totalPts);
    final nextRank = rank.index < Rank.values.length - 1
        ? Rank.values[rank.index + 1]
        : null;

    final underGoal = repo.consumedCalories > 0 &&
        repo.consumedCalories <= repo.goal.calories;

    final challenges = buildChallenges(
      streakDays: repo.streakDays,
      waterCups: water.cups,
      underGoalToday: underGoal,
    );

    // build leaderboard with real "me" entry
    final myEntry = LeaderboardEntry(rank: 0, name: loc.isAr ? 'أنت' : 'You', points: totalPts, isMe: true);
    final sorted = [...kLeaderboard, myEntry]..sort((a, b) => b.points.compareTo(a.points));
    final ranked = [for (int i = 0; i < sorted.length; i++) _RankedEntry(rank: i + 1, entry: sorted[i])];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          // header — نقاط + رانك حقيقيين
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: totalPts),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => Text('$v',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: c.accent)),
                  ),
                  Text(loc.points, style: TextStyle(fontSize: 13, color: c.textSecondary)),
                ]),
                const Spacer(),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Row(children: [
                    Text(rank.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(loc.isAr ? rank.nameAr : rank.nameEn,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary)),
                  ]),
                  const SizedBox(height: 6),
                  if (nextRank != null)
                    Text(
                      loc.isAr
                          ? '${nextRank.minPoints - totalPts} نقطة للـ ${nextRank.nameAr}'
                          : '${nextRank.minPoints - totalPts} pts to ${nextRank.nameEn}',
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
                    ),
                ]),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15, curve: Curves.easeOutCubic),
          const SizedBox(height: 20),

          // daily tasks card
          GestureDetector(
            onTap: () {
              Haptics.select();
              Navigator.push(context, ZadPageRoute(page: const DailyTasksScreen()));
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: c.border),
              ),
              child: Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: c.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.task_alt_rounded, color: c.accent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(loc.isAr ? 'مهام اليوم' : "Today's tasks",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary)),
                  const SizedBox(height: 4),
                  Text(
                    loc.isAr
                        ? '$doneTasks / ${tasks.length} مكتمل · +$todayPts ${loc.points}'
                        : '$doneTasks / ${tasks.length} done · +$todayPts ${loc.points}',
                    style: TextStyle(fontSize: 13, color: c.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: tasks.isEmpty ? 0 : doneTasks / tasks.length,
                      backgroundColor: c.track,
                      valueColor: AlwaysStoppedAnimation(c.accent),
                      minHeight: 4,
                    ),
                  ),
                ])),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: c.textTertiary),
              ]),
            ),
          ).animate().fadeIn(delay: 80.ms),

          Text(loc.activeChallenges,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: c.textPrimary))
              .animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 12),
          ...challenges.asMap().entries.map((e) => _ChallengeCard(challenge: e.value, loc: loc)
              .animate()
              .fadeIn(delay: (200 + e.key * 80).ms, duration: 400.ms)
              .slideX(begin: 0.1, curve: Curves.easeOutCubic)),
          const SizedBox(height: 24),
          Row(children: [
            Text(loc.leaderboard,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: c.textPrimary)),
            const Spacer(),
            Text(loc.weeklyLeague, style: TextStyle(fontSize: 12, color: c.textSecondary)),
          ]).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 12),
          ...ranked.asMap().entries.map((e) => _LeaderRow(ranked: e.value, loc: loc)
              .animate()
              .fadeIn(delay: (360 + e.key * 60).ms, duration: 350.ms)),
        ],
      ),
    );
  }
}

class _RankedEntry {
  final int rank;
  final LeaderboardEntry entry;
  const _RankedEntry({required this.rank, required this.entry});
}

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final AppLocalizations loc;
  const _ChallengeCard({required this.challenge, required this.loc});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final title = loc.isAr ? challenge.titleAr : challenge.titleEn;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: challenge.done ? c.accent.withOpacity(0.06) : c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: challenge.done ? c.accent : c.border, width: challenge.done ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: (challenge.done ? c.accent : c.accent).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(challenge.done ? Icons.check_rounded : challenge.icon,
                  size: 20, color: c.accent),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
                    color: challenge.done ? c.accent : c.textPrimary))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: c.accent2.withOpacity(0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('+${challenge.points} ${loc.points}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c.accent2)),
            ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(children: [
                  Container(height: 8, color: c.track),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: challenge.progress),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => FractionallySizedBox(
                      widthFactor: v,
                      child: Container(height: 8, color: challenge.done ? c.accent2 : c.accent),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 10),
            Text('${challenge.current}/${challenge.target}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.textSecondary)),
          ]),
        ],
      ),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  final _RankedEntry ranked;
  final AppLocalizations loc;
  const _LeaderRow({required this.ranked, required this.loc});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final entry = ranked.entry;
    final highlight = entry.isMe;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: highlight ? c.accent.withOpacity(0.12) : c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: highlight ? c.accent : c.border, width: highlight ? 2 : 1),
      ),
      child: Row(children: [
        SizedBox(
          width: 26,
          child: Text('${ranked.rank}',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ranked.rank <= 3 ? c.accent2 : c.textSecondary)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(entry.isMe ? (loc.isAr ? 'أنت' : 'You') : entry.name,
            style: TextStyle(
                fontSize: 15,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w400,
                color: c.textPrimary))),
        Text('${entry.points}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.accent)),
        const SizedBox(width: 4),
        Text(loc.points, style: TextStyle(fontSize: 11, color: c.textTertiary)),
      ]),
    );
  }
}
