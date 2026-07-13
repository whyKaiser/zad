import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/motion.dart';
import '../../data/food_seed.dart';
import '../../data/meal_plan_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/meal.dart';
import '../../theme/app_theme.dart';
import 'shopping_list_screen.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  static const _days = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
  static const _daysEn = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  static const _dayKeys = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  int _dayIdx = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final ctrl = context.watch<MealPlanController>();
    final dayKey = _dayKeys[_dayIdx];
    final dayEntries = ctrl.forDay(dayKey);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(children: [
                IconButton(onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary)),
                Text(loc.isAr ? 'خطة الوجبات' : 'Meal Plan',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: c.textPrimary)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    Haptics.select();
                    Navigator.push(context, ZadPageRoute(page: const ShoppingListScreen()));
                  },
                  icon: Icon(Icons.shopping_cart_outlined, size: 18, color: c.accent),
                  label: Text(loc.isAr ? 'قائمة الشراء' : 'Shopping', style: TextStyle(color: c.accent, fontSize: 13)),
                ),
              ]),
            ),
            // day selector
            SizedBox(
              height: 48,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: _days.length,
                itemBuilder: (_, i) {
                  final sel = i == _dayIdx;
                  return GestureDetector(
                    onTap: () { Haptics.select(); setState(() => _dayIdx = i); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? c.accent : c.surfaceVariant,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: sel ? c.accent : c.border),
                      ),
                      child: Text(loc.isAr ? _days[i] : _daysEn[i],
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                              color: sel ? c.onAccent : c.textSecondary)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                children: MealType.values.map((type) {
                  final typeEntries = dayEntries.where((e) => e.type == type).toList();
                  return _MealTypeSection(
                    type: type, entries: typeEntries, dayKey: dayKey,
                    loc: loc, c: c, ctrl: ctrl,
                  ).animate().fadeIn(delay: (MealType.values.indexOf(type) * 80).ms);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealTypeSection extends StatelessWidget {
  final MealType type;
  final List<MealPlanEntry> entries;
  final String dayKey;
  final AppLocalizations loc;
  final dynamic c;
  final MealPlanController ctrl;
  const _MealTypeSection({required this.type, required this.entries, required this.dayKey,
    required this.loc, required this.c, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: c.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(children: [
              Text(loc.mealTypeLabel(type),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.accent)),
              const Spacer(),
              GestureDetector(
                onTap: () => _addEntry(context),
                child: Icon(Icons.add_circle_outline_rounded, color: c.accent, size: 22),
              ),
            ]),
          ),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(loc.isAr ? 'لا يوجد — اضغط + للإضافة' : 'Empty — tap + to add',
                  style: TextStyle(fontSize: 13, color: c.textTertiary)),
            )
          else
            ...entries.map((e) {
              final f = e.food;
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(loc.isAr ? (f?.nameAr ?? e.foodId) : (f?.nameEn ?? e.foodId),
                    style: TextStyle(fontSize: 14, color: c.textPrimary)),
                subtitle: Text('${e.grams}g · ${e.calories} ${loc.calorieUnit}',
                    style: TextStyle(fontSize: 12, color: c.textSecondary)),
                trailing: IconButton(
                  icon: Icon(Icons.remove_circle_outline, size: 18, color: c.textTertiary),
                  onPressed: () => ctrl.remove(e),
                ),
              );
            }),
        ],
      ),
    );
  }

  void _addEntry(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddEntrySheet(dayKey: dayKey, type: type, loc: loc, c: c, ctrl: ctrl),
    );
  }
}

class _AddEntrySheet extends StatefulWidget {
  final String dayKey;
  final MealType type;
  final AppLocalizations loc;
  final dynamic c;
  final MealPlanController ctrl;
  const _AddEntrySheet({required this.dayKey, required this.type, required this.loc, required this.c, required this.ctrl});

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  String _query = '';
  int _grams = 100;

  @override
  Widget build(BuildContext context) {
    final results = searchFoods(_query).take(8).toList();
    final c = widget.c;
    final loc = widget.loc;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (_, scrollCtrl) => Column(
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 12),
              decoration: BoxDecoration(color: c.textTertiary, borderRadius: BorderRadius.circular(4))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: loc.searchFood,
                hintStyle: TextStyle(color: c.textTertiary),
                prefixIcon: Icon(Icons.search_rounded, color: c.textSecondary),
                filled: true, fillColor: c.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.accent)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Text('${_grams}g', style: TextStyle(fontSize: 14, color: c.textPrimary)),
              Expanded(child: Slider(value: _grams.toDouble(), min: 25, max: 400, divisions: 15,
                  activeColor: c.accent, inactiveColor: c.track,
                  onChanged: (v) => setState(() => _grams = v.round()))),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: results.length,
              itemBuilder: (_, i) {
                final item = results[i];
                final cal = (item.kcalPer100g * _grams / 100).round();
                return ListTile(
                  title: Text(loc.isAr ? item.nameAr : item.nameEn,
                      style: TextStyle(fontSize: 14, color: c.textPrimary)),
                  subtitle: Text('$_grams g · $cal ${loc.calorieUnit}',
                      style: TextStyle(fontSize: 12, color: c.textSecondary)),
                  trailing: Icon(Icons.add_circle_outline_rounded, color: c.accent),
                  onTap: () {
                    widget.ctrl.add(MealPlanEntry(
                      dayKey: widget.dayKey, type: widget.type,
                      foodId: item.id, grams: _grams,
                    ));
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
