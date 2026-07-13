import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../data/diary_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class MonthlyCalendarScreen extends StatefulWidget {
  const MonthlyCalendarScreen({super.key});

  @override
  State<MonthlyCalendarScreen> createState() => _MonthlyCalendarScreenState();
}

class _MonthlyCalendarScreenState extends State<MonthlyCalendarScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _prev() => setState(() => _month = DateTime(_month.year, _month.month - 1));
  void _next() {
    final now = DateTime.now();
    if (_month.year == now.year && _month.month == now.month) return;
    setState(() => _month = DateTime(_month.year, _month.month + 1));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final repo = context.watch<DiaryRepository>();
    final goalCal = repo.goal.calories;

    final months = loc.isAr
        ? ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
           'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر']
        : ['January', 'February', 'March', 'April', 'May', 'June',
           'July', 'August', 'September', 'October', 'November', 'December'];
    final weekdays = loc.isAr
        ? ['أح', 'إث', 'ثل', 'أر', 'خم', 'جم', 'سب']
        : ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

    final daysInMonth = DateUtils.getDaysInMonth(_month.year, _month.month);
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday % 7;
    final today = DateTime.now();

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
                ),
                Expanded(
                  child: Text(
                    '${months[_month.month - 1]} ${_month.year}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  onPressed: _prev,
                  icon: Icon(Icons.chevron_left_rounded, color: c.textPrimary),
                ),
                IconButton(
                  onPressed: _next,
                  icon: Icon(Icons.chevron_right_rounded,
                      color: _month.month == today.month && _month.year == today.year
                          ? c.textTertiary
                          : c.textPrimary),
                ),
              ]),
            ).animate().fadeIn(duration: 300.ms),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: weekdays.map((d) => Expanded(
                  child: Text(d,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textSecondary)),
                )).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemCount: firstWeekday + daysInMonth,
                  itemBuilder: (_, i) {
                    if (i < firstWeekday) return const SizedBox();
                    final day = i - firstWeekday + 1;
                    final date = DateTime(_month.year, _month.month, day);
                    final isFuture = date.isAfter(today);
                    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;

                    // mock logged data — real app: query Firestore
                    final seed = date.day * 13 + date.month * 31;
                    final rng = math.Random(seed);
                    final logged = !isFuture && (isToday ? repo.consumedCalories > 0 : rng.nextBool());
                    final onTarget = logged && (isToday
                        ? repo.consumedCalories > 0 && (repo.consumedCalories / goalCal) > 0.7
                        : rng.nextDouble() > 0.3);

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isFuture
                            ? Colors.transparent
                            : onTarget
                                ? c.accent.withOpacity(0.85)
                                : logged
                                    ? c.accent.withOpacity(0.3)
                                    : c.track.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: isToday ? Border.all(color: c.accent, width: 2) : null,
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                            color: isFuture
                                ? c.textTertiary.withOpacity(0.3)
                                : onTarget
                                    ? c.onAccent
                                    : c.textPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // legend
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _legend(c, c.accent, loc.isAr ? 'ملتزم' : 'On target'),
                const SizedBox(width: 16),
                _legend(c, c.accent.withOpacity(0.3), loc.isAr ? 'مسجّل' : 'Logged'),
                const SizedBox(width: 16),
                _legend(c, c.track.withOpacity(0.5), loc.isAr ? 'لا يوجد' : 'No log'),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(c, Color color, String label) => Row(children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, color: c.textSecondary)),
      ]);
}
