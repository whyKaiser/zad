import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/dates.dart';
import '../../core/motion.dart';
import '../../core/undo.dart';
import '../../data/activity_controller.dart';
import '../../data/diary_repository.dart';
import '../../data/points_controller.dart';
import '../../data/profile_controller.dart';
import '../../data/water_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/meal.dart';
import '../../models/rank.dart';
import '../../theme/app_theme.dart';
import '../activity/activity_screen.dart';
import '../add_meal/add_meal_screen.dart';
import '../profile/profile_screen.dart';
import '../streak/streak_screen.dart';
import 'widgets/calorie_ring.dart';
import 'widgets/macro_ring.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final repo = context.watch<DiaryRepository>();
    final profile = context.watch<ProfileController>().profile;
    final consumed = repo.consumedMacros;

    final baseGoal = profile?.targetCalories ?? repo.goal.calories;
    final goalMacros = profile?.targetMacros ?? repo.goal.macros;
    final consumedCal = repo.consumedCalories;
    // النشاط يُضاف للميزانية فقط في اليوم الحالي.
    final viewingToday = isToday(repo.selectedDate);
    final burned = viewingToday ? context.watch<ActivityController>().burnedToday : 0;
    final goalCalories = baseGoal + burned;
    final remaining = (goalCalories - consumedCal).clamp(0, goalCalories);
    final name = profile?.name ?? repo.userName;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _TopBar(name: name, streak: repo.streakDays),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, curve: Curves.easeOutCubic),
          const SizedBox(height: 12),
          _DateStrip(
            selected: repo.selectedDate,
            onSelect: (d) => context.read<DiaryRepository>().selectDate(d),
          ).animate().fadeIn(delay: 27.ms, duration: 350.ms),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _GlassCard(
              child: Column(
                children: [
                  CalorieRing(
                    remaining: remaining,
                    consumed: consumedCal,
                    goal: goalCalories,
                  ),
                  const SizedBox(height: 20),
                  MacroRingsRow(
                    consumed: consumed,
                    target: goalMacros,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 54.ms, duration: 500.ms).slideY(begin: 0.15, curve: Curves.easeOutCubic),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _StreakRankCard(streak: repo.streakDays),
          ).animate().fadeIn(delay: 81.ms, duration: 400.ms),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _WaterCard(),
          ).animate().fadeIn(delay: 90.ms, duration: 400.ms),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _ActivityCard(),
          ).animate().fadeIn(delay: 104.ms, duration: 400.ms),
          const SizedBox(height: 20),
          ..._buildMealSections(context, c, loc, repo),
        ],
      ),
    );
  }

  List<Widget> _buildMealSections(BuildContext context, c, AppLocalizations loc, DiaryRepository repo) {
    final widgets = <Widget>[];
    var delay = 90;
    for (final type in MealType.values) {
      final meals = repo.todayMeals.where((m) => m.type == type).toList();
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _MealSection(type: type, meals: meals, loc: loc, c: c),
        ).animate().fadeIn(delay: delay.ms, duration: 350.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic),
      );
      widgets.add(const SizedBox(height: 12));
      delay += 26;
    }
    return widgets;
  }
}

// ─── Date Strip ──────────────────────────────────────────────────────────────

class _DateStrip extends StatefulWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  const _DateStrip({required this.selected, required this.onSelect});

  @override
  State<_DateStrip> createState() => _DateStripState();
}

class _DateStripState extends State<_DateStrip> {
  static const _days = 30;
  late final ScrollController _scroll;
  late final List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _dates = List.generate(_days, (i) => today.subtract(Duration(days: _days - 1 - i)));
    _scroll = ScrollController();
    // اليوم آخر عنصر. إزاحة ثابتة محسوبة يدوياً تخطئ العرض وتنكسر مع RTL،
    // فنقفز لنهاية المحتوى بعد أول تخطيط — تعمل في الاتجاهين وبأي عرض.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final weekdays = loc.isAr
        ? ['أح', 'إث', 'ثل', 'أر', 'خم', 'جم', 'سب']
        : ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    final months = loc.isAr
        ? ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر']
        : ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final sel = widget.selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 20, left: 20, bottom: 10),
          child: Text(
            '${months[sel.month - 1]} ${sel.year}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textSecondary),
          ),
        ),
        SizedBox(
          height: 76,
          child: ListView.builder(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _dates.length,
            itemBuilder: (_, i) {
              final d = _dates[i];
              final dayIsToday = isToday(d);
              final isSel = isSameDay(d, sel);
              return ZadTap(
                onTap: () {
                  Haptics.select();
                  widget.onSelect(d);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSel ? c.accent : c.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSel ? c.accent : (dayIsToday ? c.accent.withOpacity(0.5) : c.border),
                      width: dayIsToday && !isSel ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        weekdays[d.weekday % 7],
                        style: TextStyle(
                          fontSize: 11, letterSpacing: 11 * 0.01,
                          color: isSel ? c.onAccent.withOpacity(0.8) : c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${d.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isSel ? c.onAccent : c.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

}

// ─── Top Bar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String name;
  final int streak;
  const _TopBar({required this.name, required this.streak});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).greeting,
                style: TextStyle(fontSize: 13, color: c.textSecondary)),
            Text(name, style: TextStyle(fontSize: 20, letterSpacing: 20 * -0.01, fontWeight: FontWeight.w500, color: c.textPrimary)),
          ],
        ),
        const Spacer(),
        _StreakChip(days: streak),
        const SizedBox(width: 10),
        ZadTap(
          onTap: () {
            Haptics.select();
            Navigator.push(context, ZadPageRoute(page: const ProfileScreen()));
          },
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.surface,
              shape: BoxShape.circle,
              border: Border.all(color: c.border),
            ),
            child: Icon(Icons.person_outline_rounded, size: 22, color: c.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _StreakChip extends StatelessWidget {
  final int days;
  const _StreakChip({required this.days});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department_rounded, size: 16, color: c.accent2),
          const SizedBox(width: 4),
          Text('$days', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.accent2)),
        ],
      ),
    );
  }
}

// ─── Water Card ──────────────────────────────────────────────────────────────

class _WaterCard extends StatelessWidget {
  const _WaterCard();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final water = context.watch<WaterController>();
    return ZadTap(
      onLongPress: () {
        Haptics.select();
        showModalBottomSheet(
          context: context,
          backgroundColor: c.surface,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (_) => const _WaterGoalSheet(),
        );
      },
      child: _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Icon(Icons.water_drop_rounded, color: c.macroCarbs, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(loc.water, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.textPrimary)),
            const SizedBox(height: 2),
            Text('${water.cups} / ${water.goal} ${loc.cups}',
                style: TextStyle(fontSize: 13, color: c.textSecondary)),
          ]),
        ),
        _btn(context, c, Icons.remove_rounded, () => context.read<WaterController>().remove()),
        const SizedBox(width: 8),
        _btn(context, c, Icons.add_rounded, () => context.read<WaterController>().add()),
      ]),
      ),
    );
  }

  Widget _btn(BuildContext context, c, IconData icon, VoidCallback onTap) => ZadTap(
        onTap: () {
          Haptics.select();
          onTap();
        },
        child: Container(
          width: 36, height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: c.surfaceVariant, shape: BoxShape.circle, border: Border.all(color: c.border)),
          child: Icon(icon, size: 18, color: c.textPrimary),
        ),
      );
}

// ─── Activity Card ───────────────────────────────────────────────────────────

class _ActivityCard extends StatelessWidget {
  const _ActivityCard();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final burned = context.watch<ActivityController>().burnedToday;

    return ZadTap(
      onTap: () {
        Haptics.select();
        Navigator.push(context, ZadPageRoute(page: const ActivityScreen()));
      },
      child: _GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Icon(Icons.directions_run_rounded, color: c.accent2, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(loc.isAr ? 'النشاط' : 'Activity',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.textPrimary)),
              const SizedBox(height: 2),
              Text(
                burned > 0
                    ? (loc.isAr ? 'حرقت $burned سعرة — أُضيفت لميزانيتك' : '$burned burned — added to budget')
                    : (loc.isAr ? 'سجّل تمرينك وزد ميزانيتك' : 'Log a workout to earn calories'),
                style: TextStyle(fontSize: 13, color: c.textSecondary),
              ),
            ]),
          ),
          if (burned > 0)
            Text('+$burned',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.accent2)),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded, color: c.textTertiary),
        ]),
      ),
    );
  }
}

// ─── Meal Sections ───────────────────────────────────────────────────────────

class _MealSection extends StatelessWidget {
  final MealType type;
  final List<Meal> meals;
  final AppLocalizations loc;
  final dynamic c;
  const _MealSection({required this.type, required this.meals, required this.loc, required this.c});

  IconData get _icon => switch (type) {
    MealType.breakfast => Icons.free_breakfast_outlined,
    MealType.lunch => Icons.wb_sunny_outlined,
    MealType.dinner => Icons.nightlight_outlined,
    MealType.snack => Icons.cookie_outlined,
  };

  int get _totalCal => meals.fold(0, (s, m) => s + m.calories);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(children: [
              Icon(_icon, size: 18, color: c.accent),
              const SizedBox(width: 8),
              Text(loc.mealTypeLabel(type),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary)),
              const Spacer(),
              if (meals.isNotEmpty)
                Text('$_totalCal ${loc.calorieUnit}',
                    style: TextStyle(fontSize: 13, color: c.textSecondary)),
              const SizedBox(width: 8),
              ZadTap(
                onTap: () {
                  Haptics.select();
                  Navigator.push(context, ZadPageRoute(
                    page: AddMealScreen(defaultType: type),
                  ));
                },
                child: Container(
                  width: 28, height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.accent.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add_rounded, size: 18, color: c.accent),
                ),
              ),
            ]),
          ),
          if (meals.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(children: [
                Text(loc.addFood,
                    style: TextStyle(fontSize: 13, color: c.textTertiary)),
                const Spacer(),
                _CopyYesterdayButton(type: type, loc: loc, c: c),
              ]),
            )
          else
            ...meals.map((m) => _MealRow(meal: m, loc: loc, c: c)),
        ],
      ),
    );
  }
}

/// ينسخ وجبات نفس النوع من أمس بنقرة — أكثر سلوك متكرر في تتبّع السعرات.
class _CopyYesterdayButton extends StatefulWidget {
  final MealType type;
  final AppLocalizations loc;
  final dynamic c;
  const _CopyYesterdayButton({required this.type, required this.loc, required this.c});

  @override
  State<_CopyYesterdayButton> createState() => _CopyYesterdayButtonState();
}

class _CopyYesterdayButtonState extends State<_CopyYesterdayButton> {
  bool _busy = false;

  Future<void> _copy() async {
    if (_busy) return;
    setState(() => _busy = true);
    final loc = widget.loc;
    final repo = context.read<DiaryRepository>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      // اليوم السابق لليوم *المعروض* — لا ليوم أمس دائماً.
      final source = repo.selectedDate.subtract(const Duration(days: 1));
      final all = await repo.getMealsForDay(source);
      final same = all.where((m) => m.type == widget.type).toList();
      if (!mounted) return;
      if (same.isEmpty) {
        messenger.showSnackBar(SnackBar(
          content: Text(loc.isAr ? 'ما فيه تسجيل أمس لهذي الوجبة' : 'Nothing logged yesterday'),
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }
      final stamp = DateTime.now().microsecondsSinceEpoch;
      for (var i = 0; i < same.length; i++) {
        final m = same[i];
        repo.addMeal(Meal(
          id: '${stamp + i}',
          name: m.name,
          calories: m.calories,
          macros: m.macros,
          time: mealTimeFor(repo.selectedDate),
          type: m.type,
        ));
      }
      Haptics.light();
      messenger.showSnackBar(SnackBar(
        content: Text(loc.isAr ? 'نُسخت ${same.length} من أمس' : 'Copied ${same.length} from yesterday'),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return ZadTap(
      onTap: _copy,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (_busy)
            SizedBox(width: 12, height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.6, color: c.accent))
          else
            Icon(Icons.copy_rounded, size: 13, color: c.accent),
          const SizedBox(width: 5),
          Text(widget.loc.isAr ? 'انسخ من أمس' : 'Copy yesterday',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c.accent)),
        ]),
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  final Meal meal;
  final AppLocalizations loc;
  final dynamic c;
  const _MealRow({required this.meal, required this.loc, required this.c});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(meal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 20),
        color: c.danger,
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
      ),
      onDismissed: (_) {
        Haptics.light();
        final repo = context.read<DiaryRepository>();
        repo.removeMeal(meal);
        showUndoBar(
          context,
          message: loc.isAr ? 'حُذفت «${meal.name}»' : 'Deleted "${meal.name}"',
          onUndo: () => repo.addMeal(meal),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.border, width: 0.5)),
        ),
        child: Row(children: [
          Expanded(
            child: Text(meal.name,
                style: TextStyle(fontSize: 14, color: c.textPrimary)),
          ),
          Text('${meal.calories}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.accent)),
          Text(' ${loc.calorieUnit}',
              style: TextStyle(fontSize: 11, letterSpacing: 11 * 0.01, color: c.textSecondary)),
        ]),
      ),
    );
  }
}

// ─── Streak + Rank Card ───────────────────────────────────────────────────────

class _StreakRankCard extends StatelessWidget {
  final int streak;
  const _StreakRankCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final points = context.watch<PointsController>().total;
    final rank = rankFromPoints(points);
    final loc = AppLocalizations.of(context);
    return ZadTap(
      onTap: () {
        Haptics.select();
        Navigator.push(context, ZadPageRoute(page: const StreakScreen()));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.border),
        ),
        child: Row(children: [
          Icon(Icons.local_fire_department_rounded, size: 22, color: c.accent2),
          const SizedBox(width: 8),
          Text('$streak', style: TextStyle(fontSize: 20, letterSpacing: 20 * -0.01, fontWeight: FontWeight.w700, color: c.accent2)),
          const SizedBox(width: 4),
          Text(loc.isAr ? 'يوم' : 'days',
              style: TextStyle(fontSize: 13, color: c.textSecondary)),
          const Spacer(),
          Text(rank.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            loc.isAr ? rank.nameAr : rank.nameEn,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary),
          ),
          const SizedBox(width: 6),
          Text('$points ${loc.points}',
              style: TextStyle(fontSize: 11, letterSpacing: 11 * 0.01, color: c.textTertiary)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, size: 18, color: c.textTertiary),
        ]),
      ),
    );
  }
}

// ─── Glass Card ──────────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _GlassCard({required this.child, this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.border),
      ),
      child: child,
    );
  }
}

/// تغيير هدف الماء اليومي — يُفتح بضغطة مطوّلة على بطاقة الماء.
class _WaterGoalSheet extends StatefulWidget {
  const _WaterGoalSheet();

  @override
  State<_WaterGoalSheet> createState() => _WaterGoalSheetState();
}

class _WaterGoalSheetState extends State<_WaterGoalSheet> {
  double? _value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final water = context.read<WaterController>();
    final value = _value ??= water.goal.toDouble();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
                color: c.textTertiary, borderRadius: BorderRadius.circular(4)),
          ),
          Row(children: [
            Text(loc.isAr ? 'هدف الماء اليومي' : 'Daily water goal',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600, color: c.textPrimary)),
            const Spacer(),
            Text('${value.round()} ${loc.cups}',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: c.accent)),
          ]),
          Slider(
            value: value,
            min: WaterController.minGoal.toDouble(),
            max: WaterController.maxGoal.toDouble(),
            divisions: WaterController.maxGoal - WaterController.minGoal,
            activeColor: c.accent,
            inactiveColor: c.track,
            onChanged: (v) => setState(() => _value = v),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                water.setGoal(value.round());
                Haptics.light();
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: c.onAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(loc.save,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }
}
