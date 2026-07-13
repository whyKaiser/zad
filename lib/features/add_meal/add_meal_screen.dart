import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/motion.dart';
import '../../data/diary_repository.dart';
import '../../data/food_seed.dart';
import '../../l10n/app_localizations.dart';
import '../../models/food_item.dart';
import '../../models/meal.dart';
import '../../services/open_food_facts_service.dart';
import '../../theme/app_theme.dart';
import 'barcode_scan_screen.dart';
import 'custom_food_screen.dart';

class AddMealScreen extends StatefulWidget {
  final MealType defaultType;
  const AddMealScreen({super.key, this.defaultType = MealType.snack});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _search = TextEditingController();
  final _off = OpenFoodFactsService();
  String _query = '';
  late MealType _selectedType;
  List<OFFResult> _offResults = [];
  bool _offLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.defaultType;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _openPortion(FoodItem item) {
    final repo = context.read<DiaryRepository>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PortionSheet(
        item: item,
        repo: repo,
        mealType: _selectedType,
        onAdd: (grams, servings) {
          final v = item.forGrams((grams * servings).round());
          repo.addMeal(Meal(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            name: item.nameAr,
            calories: v.calories,
            macros: v.macros,
            time: DateTime.now(),
            type: _selectedType,
          ));
          Haptics.light();
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _onQueryChanged(String v) {
    setState(() {
      _query = v;
      _offResults = [];
    });
    _debounce?.cancel();
    if (v.length >= 2) {
      _debounce = Timer(const Duration(milliseconds: 450), () => _searchOFF(v));
    }
  }

  Future<void> _searchOFF(String q) async {
    setState(() => _offLoading = true);
    final res = await _off.search(q);
    if (mounted && _query == q) {
      setState(() { _offResults = res; _offLoading = false; });
    }
  }

  void _openOFFPortion(OFFResult off) {
    final repo = context.read<DiaryRepository>();
    final c = context.colors;
    // Build a synthetic FoodItem (per-100g values)
    final item = FoodItem(
      id: 'off_${off.name}',
      nameAr: off.name,
      nameEn: off.name,
      kcalPer100g: off.calories,
      proteinPer100g: off.macros.protein.toDouble(),
      carbsPer100g: off.macros.carbs.toDouble(),
      fatPer100g: off.macros.fat.toDouble(),
      typicalServingG: 100,
      servingLabelAr: '100 جرام',
      servingLabelEn: '100g',
      source: 'Open Food Facts',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PortionSheet(
        item: item,
        repo: repo,
        mealType: _selectedType,
        onAdd: (grams, servings) {
          final v = item.forGrams((grams * servings).round());
          repo.addMeal(Meal(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            name: off.name,
            calories: v.calories,
            macros: v.macros,
            time: DateTime.now(),
            type: _selectedType,
          ));
          Haptics.light();
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final results = searchFoods(_query);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(loc.addMeal,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: c.textPrimary)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.push(context, ZadPageRoute(
                      page: BarcodeScanScreen(mealType: _selectedType),
                    )),
                    icon: Icon(Icons.qr_code_scanner_rounded, color: c.accent),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            // meal type chips
            SizedBox(
              height: 40,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: MealType.values.map((t) {
                  final sel = t == _selectedType;
                  return GestureDetector(
                    onTap: () { Haptics.select(); setState(() => _selectedType = t); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? c.accent.withOpacity(0.14) : c.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? c.accent : c.border, width: sel ? 1.5 : 1),
                      ),
                      child: Text(loc.mealTypeLabel(t),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                              color: sel ? c.accent : c.textSecondary)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _search,
                onChanged: _onQueryChanged,
                style: TextStyle(color: c.textPrimary),
                decoration: InputDecoration(
                  hintText: loc.searchFood,
                  hintStyle: TextStyle(color: c.textTertiary),
                  prefixIcon: Icon(Icons.search_rounded, color: c.textSecondary),
                  filled: true,
                  fillColor: c.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.accent)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {
                  Haptics.select();
                  Navigator.push(context, ZadPageRoute(
                    page: CustomFoodScreen(defaultType: _selectedType),
                  ));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Row(children: [
                    Icon(Icons.add_circle_outline_rounded, size: 18, color: context.colors.accent),
                    const SizedBox(width: 10),
                    Text(
                      AppLocalizations.of(context).isAr ? 'أضف طعام مخصص' : 'Add custom food',
                      style: TextStyle(fontSize: 14, color: context.colors.accent, fontWeight: FontWeight.w500),
                    ),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  // local results
                  ...results.map((item) => _FoodRow(item: item, onTap: () => _openPortion(item))),

                  // OFacts section
                  if (_query.length >= 2) ...[
                    if (_offLoading)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(children: [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: c.accent)),
                          const SizedBox(width: 10),
                          Text(loc.isAr ? 'جارٍ البحث في الإنترنت…' : 'Searching online…',
                              style: TextStyle(fontSize: 13, color: c.textSecondary)),
                        ]),
                      )
                    else if (_offResults.isNotEmpty) ...[
                      if (results.isNotEmpty) const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          Icon(Icons.public_rounded, size: 14, color: c.textTertiary),
                          const SizedBox(width: 6),
                          Text(loc.isAr ? 'نتائج من الإنترنت' : 'Online results',
                              style: TextStyle(fontSize: 12, color: c.textTertiary)),
                        ]),
                      ),
                      ..._offResults.map((off) => _OFFRow(off: off, onTap: () => _openOFFPortion(off))),
                    ] else if (results.isEmpty && !_offLoading)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(loc.noFoodMatch,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: c.textSecondary, fontSize: 14)),
                        ),
                      ),
                  ] else if (results.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(loc.noFoodMatch,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: c.textSecondary, fontSize: 14)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Food Row ─────────────────────────────────────────────────────────────────

class _FoodRow extends StatelessWidget {
  final FoodItem item;
  final VoidCallback onTap;
  const _FoodRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final t = item.typical;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.isAr ? item.nameAr : item.nameEn,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.textPrimary)),
                  const SizedBox(height: 3),
                  Text('${loc.isAr ? item.servingLabelAr : item.servingLabelEn} · ${item.typicalServingG}${loc.grams} · ${t.calories} ${loc.calorieUnit}',
                      style: TextStyle(fontSize: 12, color: c.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.add_circle_outline_rounded, color: c.accent),
          ],
        ),
      ),
    );
  }
}

// ─── OFF Row ──────────────────────────────────────────────────────────────────

class _OFFRow extends StatelessWidget {
  final OFFResult off;
  final VoidCallback onTap;
  const _OFFRow({required this.off, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(off.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text('100${loc.grams} · ${off.calories} ${loc.calorieUnit} · ${loc.isAr ? "ب" : "P"}: ${off.macros.protein}  ${loc.isAr ? "ك" : "C"}: ${off.macros.carbs}  ${loc.isAr ? "د" : "F"}: ${off.macros.fat}',
                style: TextStyle(fontSize: 12, color: c.textSecondary)),
          ])),
          Icon(Icons.add_circle_outline_rounded, color: c.accent),
        ]),
      ),
    );
  }
}

// ─── Portion Sheet ────────────────────────────────────────────────────────────

class _PortionSheet extends StatefulWidget {
  final FoodItem item;
  final DiaryRepository repo;
  final MealType mealType;
  final void Function(int grams, int servings) onAdd;

  const _PortionSheet({
    required this.item,
    required this.repo,
    required this.mealType,
    required this.onAdd,
  });

  @override
  State<_PortionSheet> createState() => _PortionSheetState();
}

class _PortionSheetState extends State<_PortionSheet> {
  late double _grams = widget.item.typicalServingG.toDouble();
  int _servings = 1;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final totalGrams = (_grams * _servings).round();
    final v = widget.item.forGrams(totalGrams);

    // daily progress
    final repo = widget.repo;
    final consumed = repo.consumedCalories;
    final goal = repo.goal.calories;
    final consumedM = repo.consumedMacros;
    final goalM = repo.goal.macros;

    final mealLabel = loc.mealTypeLabel(widget.mealType);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(color: c.textTertiary, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            Text(loc.isAr ? widget.item.nameAr : widget.item.nameEn,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.textPrimary)),
            const SizedBox(height: 16),

            // calories preview
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('${v.calories}',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: c.accent)),
                const SizedBox(width: 4),
                Text(loc.calorieUnit, style: TextStyle(fontSize: 13, color: c.textSecondary)),
              ],
            ),

            // macro tags
            const SizedBox(height: 10),
            Row(children: [
              _tag(c, '${loc.protein} ${v.macros.protein}${loc.grams}', c.macroProtein),
              const SizedBox(width: 8),
              _tag(c, '${loc.carbs} ${v.macros.carbs}${loc.grams}', c.macroCarbs),
              const SizedBox(width: 8),
              _tag(c, '${loc.fat} ${v.macros.fat}${loc.grams}', c.macroFat),
            ]),

            const SizedBox(height: 16),

            // grams slider
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('${_grams.round()} ${loc.grams}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.textPrimary)),
                const Spacer(),
                Text(loc.isAr ? 'حجم الحصة' : 'Serving size',
                    style: TextStyle(fontSize: 12, color: c.textSecondary)),
              ],
            ),
            Slider(
              value: _grams,
              min: 10,
              max: 500,
              divisions: 49,
              activeColor: c.accent,
              inactiveColor: c.track,
              onChanged: (g) => setState(() => _grams = g),
            ),

            // servings row
            Row(children: [
              Text(loc.isAr ? 'عدد الحصص' : 'Servings',
                  style: TextStyle(fontSize: 14, color: c.textPrimary)),
              const Spacer(),
              _CounterBtn(
                icon: Icons.remove_rounded,
                onTap: _servings > 1 ? () => setState(() => _servings--) : null,
                c: c,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('$_servings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.textPrimary)),
              ),
              _CounterBtn(
                icon: Icons.add_rounded,
                onTap: _servings < 20 ? () => setState(() => _servings++) : null,
                c: c,
              ),
            ]),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // daily goal section
            Text(loc.isAr ? 'نسبة الهدف اليومي' : 'Daily goal',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary)),
            const SizedBox(height: 12),
            _DailyBar(
              label: loc.isAr ? 'السعرات' : 'Calories',
              current: consumed,
              adding: v.calories,
              goal: goal,
              color: c.accent,
            ),
            const SizedBox(height: 8),
            _DailyBar(
              label: loc.protein,
              current: consumedM.protein,
              adding: v.macros.protein,
              goal: goalM.protein,
              color: c.macroProtein,
            ),
            const SizedBox(height: 8),
            _DailyBar(
              label: loc.carbs,
              current: consumedM.carbs,
              adding: v.macros.carbs,
              goal: goalM.carbs,
              color: c.macroCarbs,
            ),
            const SizedBox(height: 8),
            _DailyBar(
              label: loc.fat,
              current: consumedM.fat,
              adding: v.macros.fat,
              goal: goalM.fat,
              color: c.macroFat,
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => widget.onAdd(_grams.round(), _servings),
                style: TextButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: c.onAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  loc.isAr ? 'أضف إلى $mealLabel' : 'Add to $mealLabel',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(c, String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
      );
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final dynamic c;
  const _CounterBtn({required this.icon, required this.onTap, required this.c});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null ? () { Haptics.select(); onTap!(); } : null,
      child: Container(
        width: 36, height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap != null ? c.surfaceVariant : c.track,
          shape: BoxShape.circle,
          border: Border.all(color: c.border),
        ),
        child: Icon(icon, size: 18, color: onTap != null ? c.textPrimary : c.textTertiary),
      ),
    );
  }
}

class _DailyBar extends StatelessWidget {
  final String label;
  final int current;
  final int adding;
  final int goal;
  final Color color;
  const _DailyBar({
    required this.label,
    required this.current,
    required this.adding,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final before = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    final after = goal > 0 ? ((current + adding) / goal).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(label, style: TextStyle(fontSize: 12, color: c.textSecondary)),
          const Spacer(),
          Text('${current + adding} / $goal',
              style: TextStyle(fontSize: 12, color: c.textSecondary)),
          const SizedBox(width: 4),
          Text('${(after * 100).round()}%',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ]),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(color: c.track, borderRadius: BorderRadius.circular(3)),
            ),
            FractionallySizedBox(
              widthFactor: before,
              child: Container(
                height: 6,
                decoration: BoxDecoration(color: color.withOpacity(0.4), borderRadius: BorderRadius.circular(3)),
              ),
            ),
            FractionallySizedBox(
              widthFactor: after,
              child: Container(
                height: 6,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
