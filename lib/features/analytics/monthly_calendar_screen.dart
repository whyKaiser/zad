import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/dates.dart';
import '../../data/diary_repository.dart';
import '../../data/profile_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// تقويم التغذية — كل مربّع يعكس تسجيلاً حقيقياً من اليوميات.
class MonthlyCalendarScreen extends StatefulWidget {
  const MonthlyCalendarScreen({super.key});

  @override
  State<MonthlyCalendarScreen> createState() => _MonthlyCalendarScreenState();
}

class _MonthlyCalendarScreenState extends State<MonthlyCalendarScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  /// سعرات كل يوم في الشهر المعروض: dayKey → سعرات.
  Map<String, int> _calories = const {};
  bool _loading = true;
  String _loadedSignature = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMonth();
  }

  Future<void> _loadMonth() async {
    final repo = context.read<DiaryRepository>();
    final signature = '${_month.year}-${_month.month}|${identityHashCode(repo)}';
    if (signature == _loadedSignature) return;
    _loadedSignature = signature;

    setState(() => _loading = true);
    final last = DateTime(_month.year, _month.month + 1, 0); // آخر يوم بالشهر
    try {
      final data = await repo.getCaloriesForRange(
        DateTime(_month.year, _month.month, 1),
        last,
      );
      if (!mounted) return;
      setState(() {
        _calories = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _calories = const {};
        _loading = false;
      });
    }
  }

  void _prev() {
    setState(() => _month = DateTime(_month.year, _month.month - 1));
    _loadMonth();
  }

  void _next() {
    final now = DateTime.now();
    if (_month.year == now.year && _month.month == now.month) return;
    setState(() => _month = DateTime(_month.year, _month.month + 1));
    _loadMonth();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final repo = context.watch<DiaryRepository>();
    final profile = context.watch<ProfileController>().profile;
    final goalCal = profile?.targetCalories ?? repo.goal.calories;

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
    final atCurrentMonth = _month.year == today.year && _month.month == today.month;

    final loggedDays = _calories.values.where((v) => v > 0).length;
    final onTargetDays = goalCal > 0
        ? _calories.values.where((v) => v > 0 && v / goalCal > 0.7).length
        : 0;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(children: [
                IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
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
                  tooltip: AppLocalizations.of(context).isAr ? 'الشهر السابق' : 'Previous month',
                  onPressed: _prev,
                  icon: Icon(Icons.chevron_left_rounded, color: c.textPrimary),
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context).isAr ? 'الشهر التالي' : 'Next month',
                  onPressed: atCurrentMonth ? null : _next,
                  icon: Icon(Icons.chevron_right_rounded,
                      color: atCurrentMonth ? c.textTertiary : c.textPrimary),
                ),
              ]),
            ).animate().fadeIn(duration: 300.ms),

            // ملخّص الشهر — أرقام حقيقية من اليوميات
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.border),
                ),
                child: Row(children: [
                  _stat(c, '$loggedDays', loc.isAr ? 'يوم مسجّل' : 'days logged'),
                  Container(width: 1, height: 28, color: c.border),
                  _stat(c, '$onTargetDays', loc.isAr ? 'يوم ملتزم' : 'on target'),
                ]),
              ),
            ),
            const SizedBox(height: 14),

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
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: c.accent))
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          final isFuture =
                              date.isAfter(DateTime(today.year, today.month, today.day));
                          final dayIsToday = isSameDay(date, today);

                          final cal = _calories[dayKey(date)] ?? 0;
                          final logged = cal > 0;
                          final onTarget = logged && goalCal > 0 && cal / goalCal > 0.7;

                          return Tooltip(
                            message: logged ? '$cal ${loc.calorieUnit}' : '',
                            triggerMode: TooltipTriggerMode.tap,
                            child: AnimatedContainer(
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
                                border: dayIsToday
                                    ? Border.all(color: c.accent, width: 2)
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  '$day',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                        dayIsToday ? FontWeight.w700 : FontWeight.w400,
                                    color: isFuture
                                        ? c.textTertiary.withOpacity(0.3)
                                        : onTarget
                                            ? c.onAccent
                                            : c.textPrimary,
                                  ),
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

  Widget _stat(dynamic c, String value, String label) => Expanded(
        child: Column(children: [
          Text(value,
              style: TextStyle(fontSize: 20, letterSpacing: 20 * -0.01, fontWeight: FontWeight.w700, color: c.accent)),
          Text(label, style: TextStyle(fontSize: 11, letterSpacing: 11 * 0.01, color: c.textSecondary)),
        ]),
      );

  Widget _legend(dynamic c, Color color, String label) => Row(children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: TextStyle(fontSize: 11, letterSpacing: 11 * 0.01, color: c.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]);
}
