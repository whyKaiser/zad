import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/motion.dart';
import '../../data/diary_repository.dart';
import '../../data/points_controller.dart';
import '../../data/profile_controller.dart';
import '../../data/water_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/meal.dart';
import '../../models/rank.dart';
import '../../theme/app_theme.dart';
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

    final goalCalories = profile?.targetCalories ?? repo.goal.calories;
    final goalMacros = profile?.targetMacros ?? repo.goal.macros;
    final consumedCal = repo.consumedCalories;
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
          ).animate().fadeIn(delay: 60.ms, duration: 350.ms),
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
          ).animate().fadeIn(delay: 120.ms, duration: 500.ms).slideY(begin: 0.15, curve: Curves.easeOutCubic),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _StreakRankCard(streak: repo.streakDays),
          ).animate().fadeIn(delay: 180.ms, duration: 400.ms),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _WaterCard(),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 20),
          ..._buildMealSections(context, c, loc, repo),
        ],
      ),
    );
  }

  List<Widget> _buildMealSections(BuildContext context, c, AppLocalizations loc, DiaryRepository repo) {
    final widgets = <Widget>[];
    var delay = 280;
    for (final type in MealType.values) {
      final meals = repo.todayMeals.where((m) => m.type == type).toList();
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _MealSection(type: type, meals: meals, loc: loc, c: c),
        ).animate().fadeIn(delay: delay.ms, duration: 350.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic),
      );
      widgets.add(const SizedBox(height: 12));
      delay += 60;
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
    _scroll = ScrollController(
      initialScrollOffset: (_days - 1) * 64.0,
    );
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
              final isToday = _isToday(d);
              final isSel = _isSameDay(d, sel);
              return GestureDetector(
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
                      color: isSel ? c.accent : (isToday ? c.accent.withOpacity(0.5) : c.border),
                      width: isToday && !isSel ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        weekdays[d.weekday % 7],
                        style: TextStyle(
                          fontSize: 11,
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

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
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
            Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: c.textPrimary)),
          ],
        ),
        const Spacer(),
        _StreakChip(days: streak),
        const SizedBox(width: 10),
        GestureDetector(
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
    return _GlassCard(
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
    );
  }

  Widget _btn(BuildContext context, c, IconData icon, VoidCallback onTap) => GestureDetector(
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
              GestureDetector(
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(loc.addFood,
                  style: TextStyle(fontSize: 13, color: c.textTertiary)),
            )
          else
            ...meals.map((m) => _MealRow(meal: m, loc: loc, c: c)),
        ],
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
        color: Colors.red.withOpacity(0.85),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
      ),
      onDismissed: (_) {
        Haptics.light();
        final repo = context.read<DiaryRepository>();
        repo.removeMeal(meal);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loc.isAr ? 'حُذفت «${meal.name}»' : 'Deleted "${meal.name}"'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: loc.isAr ? 'تراجع' : 'Undo',
            onPressed: () => repo.addMeal(meal),
          ),
        ));
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
              style: TextStyle(fontSize: 11, color: c.textSecondary)),
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
    return GestureDetector(
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
          Text('$streak', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c.accent2)),
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
              style: TextStyle(fontSize: 11, color: c.textTertiary)),
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
