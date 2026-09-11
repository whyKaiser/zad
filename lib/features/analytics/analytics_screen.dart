import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/motion.dart';
import '../../data/diary_repository.dart';
import '../../data/profile_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/meal.dart';
import '../../theme/app_theme.dart';
import 'weekly_report_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late Future<List<_DayData>> _weekFuture;
  DiaryRepository? _prevRepo;
  String _prevSignature = '';

  /// بصمة تتغيّر مع كل تعديل على يوميات اليوم — بها نعرف متى نعيد الجلب
  /// بدل إعادة الجلب مع كل رسم (قراءات Firestore مكلفة) أو عدمه إطلاقاً.
  String _signatureOf(DiaryRepository repo) {
    final now = DateTime.now();
    final sel = repo.selectedDate;
    final viewingToday =
        sel.year == now.year && sel.month == now.month && sel.day == now.day;
    final todayPart = viewingToday
        ? '${repo.todayMeals.length}:${repo.consumedCalories}'
        : 'other';
    return '${now.year}-${now.month}-${now.day}|$todayPart';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = context.watch<DiaryRepository>();
    final sig = _signatureOf(repo);
    if (!identical(_prevRepo, repo) || sig != _prevSignature) {
      _prevRepo = repo;
      _prevSignature = sig;
      _weekFuture = _loadWeekData(repo);
    }
  }

  Future<List<_DayData>> _loadWeekData(DiaryRepository repo) async {
    final today = DateTime.now();
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

    bool isToday(DateTime d) =>
        d.year == today.year && d.month == today.month && d.day == today.day;

    // جلب متوازٍ — 6 نداءات متتابعة كانت تُبطئ فتح الشاشة بلا داعٍ.
    final lists = await Future.wait(days.map((d) async {
      if (isToday(d)) {
        final sel = repo.selectedDate;
        // وجبات اليوم متاحة فوراً فقط إن كانت هي المعروضة حالياً.
        if (sel.year == d.year && sel.month == d.month && sel.day == d.day) {
          return repo.todayMeals;
        }
      }
      return repo.getMealsForDay(d);
    }));

    return [
      for (var i = 0; i < days.length; i++)
        _DayData(
          date: days[i],
          calories: lists[i].fold(0, (acc, m) => acc + m.calories),
          protein: lists[i].fold(0, (acc, m) => acc + m.macros.protein),
          carbs: lists[i].fold(0, (acc, m) => acc + m.macros.carbs),
          fat: lists[i].fold(0, (acc, m) => acc + m.macros.fat),
        ),
    ];
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
                      style: TextStyle(fontSize: 22, letterSpacing: 22 * -0.01, fontWeight: FontWeight.w700, color: c.textPrimary))
                  .animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 4),
              Text(loc.isAr ? 'آخر 7 أيام' : 'Last 7 days',
                      style: TextStyle(fontSize: 13, color: c.textSecondary))
                  .animate().fadeIn(delay: 36.ms),
              const SizedBox(height: 16),

              // مدخل التقرير الذكي — قراءة الأسبوع بالعربي مع نصيحة واحدة
              ZadTap(
                onTap: () {
                  Haptics.select();
                  Navigator.push(context,
                      ZadPageRoute(page: const WeeklyReportScreen()));
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: c.accent.withOpacity(0.35)),
                  ),
                  child: Row(children: [
                    Icon(Icons.insights_rounded, color: c.accent, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(loc.isAr ? 'تقرير الأسبوع الذكي' : 'Smart weekly report',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: c.textPrimary)),
                            const SizedBox(height: 2),
                            Text(
                                loc.isAr
                                    ? 'قراءة لأسبوعك ونصيحة واحدة تنفّذها'
                                    : 'A read on your week and one tip to act on',
                                style: TextStyle(fontSize: 12, color: c.textSecondary)),
                          ]),
                    ),
                    Icon(Icons.chevron_right_rounded, color: c.textTertiary),
                  ]),
                ),
              ).animate().fadeIn(delay: 50.ms),
              const SizedBox(height: 20),

              if (snap.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else ...[
                _WeekBarChart(data: weekData, goal: goalCal)
                    .animate().fadeIn(delay: 63.ms, duration: 500.ms),
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
                ]).animate().fadeIn(delay: 99.ms),
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
                ]).animate().fadeIn(delay: 126.ms),
                const SizedBox(height: 24),

                Text(loc.isAr ? 'توزيع الماكروز' : 'Macro breakdown',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.textPrimary))
                    .animate().fadeIn(delay: 140.ms),
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
                              style: TextStyle(fontSize: 9, letterSpacing: 9 * 0.02, color: c.textTertiary),
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
                  style: TextStyle(fontSize: 11, letterSpacing: 11 * 0.01, color: c.textTertiary)),
            ]),
          ),
          Row(
            children: data.map((d) => Expanded(
              child: Text(
                weekdays[d.date.weekday % 7],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11, letterSpacing: 11 * 0.01,
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
          Text(label, style: TextStyle(fontSize: 11, letterSpacing: 11 * 0.01, color: c.textSecondary)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: TextStyle(fontSize: 22, letterSpacing: 22 * -0.01, fontWeight: FontWeight.w700, color: color)),
              const SizedBox(width: 3),
              Text(unit, style: TextStyle(fontSize: 11, letterSpacing: 11 * 0.01, color: c.textTertiary)),
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
        Text(' ${loc.calorieUnit}', style: TextStyle(fontSize: 10, letterSpacing: 10 * 0.02, color: c.textTertiary)),
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
