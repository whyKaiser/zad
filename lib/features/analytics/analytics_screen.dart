import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../data/diary_repository.dart';
import '../../data/profile_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/meal.dart';
import '../../theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late Future<List<_DayData>> _weekFuture;
  DiaryRepository? _prevRepo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = context.read<DiaryRepository>();
    if (!identical(_prevRepo, repo)) {
      _prevRepo = repo;
      _weekFuture = _loadWeekData();
    }
  }

  Future<List<_DayData>> _loadWeekData() async {
    final repo = context.read<DiaryRepository>();
    final today = DateTime.now();
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final result = <_DayData>[];
    for (final d in days) {
      List<Meal> meals;
      final isToday = d.year == today.year && d.month == today.month && d.day == today.day;
      if (isToday) {
        meals = repo.todayMeals;
      } else {
        meals = await repo.getMealsForDay(d);
      }
      final cal = meals.fold(0, (acc, m) => acc + m.calories);
      final prot = meals.fold(0, (acc, m) => acc + m.macros.protein);
      final carbs = meals.fold(0, (acc, m) => acc + m.macros.carbs);
      final fat = meals.fold(0, (acc, m) => acc + m.macros.fat);
      result.add(_DayData(date: d, calories: cal, protein: prot, carbs: carbs, fat: fat));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final repo = context.watch<DiaryRepository>();
    final profile = context.watch<ProfileController>().profile;
    final goalCal = profile?.targetCalories ?? repo.goal.calories;
    final goalM = profile?.targetMacros ?? repo.goal.macros;

    // refresh when diary changes
    return FutureBuilder<List<_DayData>>(
      future: _weekFuture,
      builder: (context, snap) {
        final weekData = snap.data ?? [];
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              Text(loc.isAr ? 'إحصائيات الأسبوع' : 'Weekly stats',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.textPrimary))
                  .animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 4),
              Text(loc.isAr ? 'آخر 7 أيام' : 'Last 7 days',
                      style: TextStyle(fontSize: 13, color: c.textSecondary))
                  .animate().fadeIn(delay: 80.ms),
              const SizedBox(height: 24),

              if (snap.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else ...[
                _WeekBarChart(data: weekData, goal: goalCal)
                    .animate().fadeIn(delay: 140.ms, duration: 500.ms),
                const SizedBox(height: 24),

                Row(children: [
                  Expanded(child: _SummaryCard(
                    label: loc.isAr ? 'متوسط السعرات' : 'Avg calories',
                    value: _avg(weekData.map((d) => d.calories).toList()).round().toString(),
                    unit: loc.calorieUnit,
                    color: c.accent,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _SummaryCard(
                    label: loc.isAr ? 'أيام ملتزم' : 'On-target days',
                    value: weekData.where((d) => d.calories > 0 && (d.calories / goalCal) > 0.7).length.toString(),
                    unit: '/ 7',
                    color: c.accent2,
                  )),
                ]).animate().fadeIn(delay: 220.ms),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _SummaryCard(
                    label: loc.isAr ? 'متوسط بروتين' : 'Avg protein',
                    value: _avg(weekData.map((d) => d.protein).toList()).round().toString(),
                    unit: loc.grams,
                    color: c.macroProtein,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _SummaryCard(
                    label: loc.isAr ? 'متوسط كارب' : 'Avg carbs',
                    value: _avg(weekData.map((d) => d.carbs).toList()).round().toString(),
                    unit: loc.grams,
                    color: c.macroCarbs,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _SummaryCard(
                    label: loc.isAr ? 'متوسط دهون' : 'Avg fat',
                    value: _avg(weekData.map((d) => d.fat).toList()).round().toString(),
                    unit: loc.grams,
                    color: c.macroFat,
                  )),
                ]).animate().fadeIn(delay: 280.ms),
                const SizedBox(height: 24),

                Text(loc.isAr ? 'توزيع الماكروز' : 'Macro breakdown',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.textPrimary))
                    .animate().fadeIn(delay: 320.ms),
                const SizedBox(height: 12),
                ...weekData.asMap().entries.map((e) => _MacroRow(
                      data: e.value,
                      goal: goalM,
                      loc: loc,
                      c: c,
                    ).animate().fadeIn(delay: (360 + e.key * 40).ms)),
              ],
            ],
          ),
        );
      },
    );
  }

  double _avg(List<int> vals) {
    if (vals.isEmpty) return 0;
    final nonZero = vals.where((v) => v > 0).toList();
    if (nonZero.isEmpty) return 0;
    return nonZero.reduce((a, b) => a + b) / nonZero.length;
  }
}

class _DayData {
  final DateTime date;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  const _DayData({required this.date, required this.calories, required this.protein, required this.carbs, required this.fat});
}

// ─── Bar Chart ────────────────────────────────────────────────────────────────

class _WeekBarChart extends StatelessWidget {
  final List<_DayData> data;
  final int goal;
  const _WeekBarChart({required this.data, required this.goal});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (data.isEmpty) return const SizedBox.shrink();
    final maxCal = math.max(goal.toDouble(), data.map((d) => d.calories.toDouble()).reduce(math.max));
    final weekdays = AppLocalizations.of(context).isAr
        ? ['أح', 'إث', 'ثل', 'أر', 'خم', 'جم', 'سب']
        : ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((d) {
                final progress = maxCal > 0 ? (d.calories / maxCal).clamp(0.0, 1.0) : 0.0;
                final isToday = d.date.day == today.day && d.date.month == today.month;
                final onTarget = goal > 0 && d.calories > 0 && (d.calories / goal) >= 0.85 && (d.calories / goal) <= 1.1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (d.calories > 0)
                            Text(
                              '${(d.calories / 1000).toStringAsFixed(1)}k',
                              style: TextStyle(fontSize: 9, color: c.textTertiary),
                            ),
                          const SizedBox(height: 2),
                          Flexible(
                            child: FractionallySizedBox(
                              heightFactor: v.clamp(0.03, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: d.calories == 0
                                      ? c.track
                                      : onTarget
                                          ? c.accent2
                                          : isToday
                                              ? c.accent
                                              : c.accent.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(6),
                                  border: isToday ? Border.all(color: c.accent, width: 2) : null,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // goal line label
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Row(children: [
              Container(width: 12, height: 2, color: c.accent.withOpacity(0.5)),
              const SizedBox(width: 6),
              Text('${AppLocalizations.of(context).isAr ? 'الهدف' : 'Goal'} $goal',
                  style: TextStyle(fontSize: 11, color: c.textTertiary)),
            ]),
          ),
          Row(
            children: data.map((d) => Expanded(
              child: Text(
                weekdays[d.date.weekday % 7],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: d.date.day == today.day ? c.accent : c.textSecondary,
                  fontWeight: d.date.day == today.day ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Summary Card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: c.textSecondary)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
              const SizedBox(width: 3),
              Text(unit, style: TextStyle(fontSize: 11, color: c.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Macro Row ────────────────────────────────────────────────────────────────

class _MacroRow extends StatelessWidget {
  final _DayData data;
  final Macros goal;
  final AppLocalizations loc;
  final dynamic c;
  const _MacroRow({required this.data, required this.goal, required this.loc, required this.c});

  @override
  Widget build(BuildContext context) {
    final weekdays = loc.isAr
        ? ['أح', 'إث', 'ثل', 'أر', 'خم', 'جم', 'سب']
        : ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    final day = weekdays[data.date.weekday % 7];

    if (data.calories == 0) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          SizedBox(width: 32, child: Text(day, style: TextStyle(fontSize: 13, color: c.textTertiary))),
          Text(loc.isAr ? 'لا يوجد تسجيل' : 'No log', style: TextStyle(fontSize: 13, color: c.textTertiary)),
        ]),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(children: [
        SizedBox(width: 28, child: Text(day, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary))),
        const SizedBox(width: 8),
        Expanded(child: Column(children: [
          _bar(data.protein, goal.protein, c.macroProtein),
          const SizedBox(height: 4),
          _bar(data.carbs, goal.carbs, c.macroCarbs),
          const SizedBox(height: 4),
          _bar(data.fat, goal.fat, c.macroFat),
        ])),
        const SizedBox(width: 10),
        Text('${data.calories}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.accent)),
        Text(' ${loc.calorieUnit}', style: TextStyle(fontSize: 10, color: c.textTertiary)),
      ]),
    );
  }

  Widget _bar(int val, int goal, Color color) {
    final p = goal > 0 ? (val / goal).clamp(0.0, 1.0) : 0.0;
    return Stack(children: [
      Container(height: 5, decoration: BoxDecoration(color: c.track, borderRadius: BorderRadius.circular(3))),
      FractionallySizedBox(
        widthFactor: p,
        child: Container(height: 5, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      ),
    ]);
  }
}
