import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../data/activity_controller.dart';
import '../../data/diary_repository.dart';
import '../../data/profile_controller.dart';
import '../../data/water_controller.dart';
import '../../data/weight_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_profile.dart';
import '../../services/weekly_coach_service.dart';
import '../../theme/app_theme.dart';

/// تقرير أسبوعي: أرقام حقيقية + قراءة مدرّب بالعربي ونصيحة واحدة.
class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  final _coach = WeeklyCoachService();

  WeekSummary? _week;
  CoachReport? _report;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _build());
  }

  @override
  void dispose() {
    _coach.close();
    super.dispose();
  }

  String _goalLabel(GoalType? g) => switch (g) {
        GoalType.lose => 'إنقاص وزن',
        GoalType.gain => 'زيادة وزن',
        _ => 'محافظة',
      };

  Future<void> _build() async {
    final repo = context.read<DiaryRepository>();
    final profile = context.read<ProfileController>().profile;
    final activity = context.read<ActivityController>();
    final weights = context.read<WeightController>();
    final water = context.read<WaterController>();

    final today = DateTime.now();
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

    try {
      final lists = await Future.wait(days.map(repo.getMealsForDay));
      final goalCal = profile?.targetCalories ?? repo.goal.calories;
      final goalProt = profile?.targetMacros.protein ?? repo.goal.macros.protein;

      final dayCals = <int>[];
      final dayProts = <int>[];
      for (final meals in lists) {
        dayCals.add(meals.fold(0, (a, m) => a + m.calories));
        dayProts.add(meals.fold(0, (a, m) => a + m.macros.protein));
      }
      final logged = dayCals.where((c) => c > 0).toList();
      final loggedProts = <int>[
        for (var i = 0; i < dayCals.length; i++)
          if (dayCals[i] > 0) dayProts[i]
      ];

      int avg(List<int> xs) =>
          xs.isEmpty ? 0 : (xs.reduce((a, b) => a + b) / xs.length).round();

      // تغيّر الوزن خلال الأسبوع
      final weekAgo = today.subtract(const Duration(days: 7));
      final recent = weights.entries.where((e) => e.date.isAfter(weekAgo)).toList();
      final change = recent.length >= 2 ? recent.last.kg - recent.first.kg : null;

      final workouts =
          days.fold<int>(0, (acc, d) => acc + activity.forDay(d).length);

      final week = WeekSummary(
        daysLogged: logged.length,
        avgCalories: avg(logged),
        goalCalories: goalCal,
        avgProtein: avg(loggedProts),
        goalProtein: goalProt,
        daysOnTarget:
            goalCal > 0 ? logged.where((c) => c >= goalCal * 0.8 && c <= goalCal * 1.1).length : 0,
        streak: repo.streakDays,
        waterAvgCups: water.cups,
        workouts: workouts,
        weightChangeKg: change,
        goalLabel: _goalLabel(profile?.goal),
      );

      if (!mounted) return;
      setState(() => _week = week);

      final report = await _coach.generate(week);
      if (!mounted) return;
      setState(() {
        _report = report;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final w = _week;
    final r = _report;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(children: [
              IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
              ),
              Text(loc.isAr ? 'تقرير الأسبوع' : 'Weekly report',
                  style: TextStyle(
                      fontSize: 20, letterSpacing: 20 * -0.01, fontWeight: FontWeight.w600, color: c.textPrimary)),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                // بطاقة المدرّب
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: c.accent.withOpacity(0.35)),
                  ),
                  child: _loading
                      ? Column(children: [
                          CircularProgressIndicator(color: c.accent),
                          const SizedBox(height: 14),
                          Text(loc.isAr ? 'أراجع أسبوعك…' : 'Reviewing your week…',
                              style: TextStyle(fontSize: 14, color: c.textSecondary)),
                        ])
                      : r == null
                          ? Text(
                              loc.isAr
                                  ? 'ما قدرت أجهّز التقرير الآن.'
                                  : 'Could not build the report right now.',
                              style: TextStyle(fontSize: 14, color: c.textSecondary))
                          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Icon(Icons.insights_rounded, size: 20, color: c.accent),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(r.headline,
                                      style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: c.textPrimary)),
                                ),
                              ]),
                              const SizedBox(height: 12),
                              Text(r.body,
                                  style: TextStyle(
                                      fontSize: 14, height: 1.8, color: c.textSecondary)),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: c.accent.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.lightbulb_outline_rounded,
                                          size: 18, color: c.accent),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(r.tip,
                                            style: TextStyle(
                                                fontSize: 13.5,
                                                height: 1.7,
                                                fontWeight: FontWeight.w500,
                                                color: c.textPrimary)),
                                      ),
                                    ]),
                              ),
                            ]),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic),

                if (w != null) ...[
                  const SizedBox(height: 20),
                  Text(loc.isAr ? 'أرقام الأسبوع' : 'The numbers',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600, color: c.textPrimary)),
                  const SizedBox(height: 12),
                  Row(children: [
                    _stat(c, '${w.daysLogged}/7', loc.isAr ? 'أيام مسجّلة' : 'days logged'),
                    const SizedBox(width: 10),
                    _stat(c, '${w.avgCalories}', loc.isAr ? 'متوسط السعرات' : 'avg calories'),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    _stat(c, '${w.avgProtein}غ', loc.isAr ? 'متوسط البروتين' : 'avg protein'),
                    const SizedBox(width: 10),
                    _stat(c, '${w.workouts}', loc.isAr ? 'تمارين' : 'workouts'),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    _stat(c, '${w.daysOnTarget}', loc.isAr ? 'أيام ضمن الهدف' : 'on target'),
                    const SizedBox(width: 10),
                    _stat(
                      c,
                      w.weightChangeKg == null
                          ? '—'
                          : '${w.weightChangeKg! > 0 ? '+' : ''}${w.weightChangeKg!.toStringAsFixed(1)}',
                      loc.isAr ? 'تغيّر الوزن (كجم)' : 'weight change (kg)',
                    ),
                  ]),
                  const SizedBox(height: 18),
                  Text(
                    loc.isAr
                        ? 'الأرقام من تسجيلك أنت. قراءة المدرّب استرشادية وليست نصيحة طبية.'
                        : 'Numbers come from your own logs. Coach notes are guidance, not medical advice.',
                    style: TextStyle(fontSize: 11, letterSpacing: 11 * 0.01, height: 1.6, color: c.textTertiary),
                  ),
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _stat(dynamic c, String value, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20, letterSpacing: 20 * -0.01, fontWeight: FontWeight.w700, color: c.accent)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, letterSpacing: 11 * 0.01, color: c.textSecondary)),
          ]),
        ),
      );
}
