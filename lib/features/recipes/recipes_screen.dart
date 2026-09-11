import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/dates.dart';
import '../../core/motion.dart';
import '../../data/diary_repository.dart';
import '../../data/food_seed.dart';
import '../../data/recent_foods_controller.dart';
import '../../data/recipe_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/meal.dart';
import '../../theme/app_theme.dart';

/// وصفاتي — تجمع عدة أصناف في وجبة واحدة تُسجَّل بنقرة.
class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final ctrl = context.watch<RecipeController>();
    final recipes = ctrl.recipes;

    return Scaffold(
      backgroundColor: c.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        elevation: 0,
        onPressed: () {
          Haptics.select();
          Navigator.push(context, ZadPageRoute(page: const RecipeEditorScreen()));
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(loc.isAr ? 'وصفة جديدة' : 'New recipe',
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
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
              Text(loc.isAr ? 'وصفاتي' : 'My recipes',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600, color: c.textPrimary)),
            ]),
          ),
          Expanded(
            child: recipes.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.menu_book_rounded, size: 44, color: c.textTertiary),
                        const SizedBox(height: 14),
                        Text(
                          loc.isAr
                              ? 'ما عندك وصفات بعد.\nاجمع مكوّنات أكلتك المتكرّرة مرة واحدة،\nوسجّلها بعدها بنقرة.'
                              : 'No recipes yet.\nBuild your regular dish once,\nthen log it with a single tap.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, height: 1.8, color: c.textSecondary),
                        ),
                      ]),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: recipes.length,
                    itemBuilder: (_, i) => _RecipeCard(recipe: recipes[i])
                        .animate()
                        .fadeIn(delay: (i * 50).ms, duration: 300.ms),
                  ),
          ),
        ]),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final m = recipe.macrosPerServing;

    return Dismissible(
      key: ValueKey(recipe.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => await showDialog<bool>(
            context: context,
            builder: (dCtx) => AlertDialog(
              title: Text(loc.isAr ? 'حذف الوصفة؟' : 'Delete recipe?'),
              content: Text(recipe.name),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dCtx, false),
                    child: Text(loc.isAr ? 'إلغاء' : 'Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(dCtx, true),
                    child: Text(loc.isAr ? 'حذف' : 'Delete',
                        style: TextStyle(color: c.danger))),
              ],
            ),
          ) ??
          false,
      onDismissed: (_) {
        Haptics.light();
        context.read<RecipeController>().remove(recipe);
      },
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration:
            BoxDecoration(color: c.danger, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () {
          Haptics.select();
          Navigator.push(context,
              ZadPageRoute(page: RecipeEditorScreen(existing: recipe)));
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(recipe.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary)),
              ),
              Text('${recipe.caloriesPerServing}',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: c.accent)),
              Text(' ${loc.calorieUnit}',
                  style: TextStyle(fontSize: 11, color: c.textSecondary)),
            ]),
            const SizedBox(height: 4),
            Text(
              loc.isAr
                  ? '${recipe.ingredients.length} مكوّنات · ${recipe.servings} حصص · للحصة'
                  : '${recipe.ingredients.length} ingredients · ${recipe.servings} servings · per serving',
              style: TextStyle(fontSize: 12, color: c.textSecondary),
            ),
            const SizedBox(height: 10),
            Row(children: [
              _macro(c, loc.protein, m.protein, c.macroProtein),
              const SizedBox(width: 8),
              _macro(c, loc.carbs, m.carbs, c.macroCarbs),
              const SizedBox(width: 8),
              _macro(c, loc.fat, m.fat, c.macroFat),
              const Spacer(),
              GestureDetector(
                onTap: () => _logSheet(context, recipe),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: c.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_rounded, size: 16, color: c.onAccent),
                    const SizedBox(width: 4),
                    Text(loc.isAr ? 'سجّل' : 'Log',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: c.onAccent)),
                  ]),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _macro(dynamic c, String label, int v, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(7)),
        child: Text('$label $v',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w500, color: color)),
      );

  void _logSheet(BuildContext context, Recipe r) {
    Haptics.select();
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _LogRecipeSheet(recipe: r),
    );
  }
}

class _LogRecipeSheet extends StatefulWidget {
  final Recipe recipe;
  const _LogRecipeSheet({required this.recipe});

  @override
  State<_LogRecipeSheet> createState() => _LogRecipeSheetState();
}

class _LogRecipeSheetState extends State<_LogRecipeSheet> {
  double _servings = 1;
  MealType _type = MealType.lunch;

  @override
  void initState() {
    super.initState();
    _type = _inferType();
  }

  MealType _inferType() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 11) return MealType.breakfast;
    if (h >= 11 && h < 16) return MealType.lunch;
    if (h >= 16 && h < 22) return MealType.dinner;
    return MealType.snack;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final cal = (widget.recipe.caloriesPerServing * _servings).round();

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
            Expanded(
              child: Text(widget.recipe.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700, color: c.textPrimary)),
            ),
            Text('$cal ${loc.calorieUnit}',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: c.accent)),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: MealType.values.map((t) {
                final sel = t == _type;
                return GestureDetector(
                  onTap: () {
                    Haptics.select();
                    setState(() => _type = t);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsetsDirectional.only(end: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? c.accent.withOpacity(0.14) : c.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel ? c.accent : c.border, width: sel ? 1.5 : 1),
                    ),
                    child: Text(loc.mealTypeLabel(t),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: sel ? c.accent : c.textSecondary)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Text(loc.isAr ? 'عدد الحصص' : 'Servings',
                style: TextStyle(fontSize: 14, color: c.textSecondary)),
            const Spacer(),
            Text(_servings.toStringAsFixed(_servings == _servings.roundToDouble() ? 0 : 1),
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: c.accent)),
          ]),
          Slider(
            value: _servings,
            min: 0.5,
            max: 5,
            divisions: 9,
            activeColor: c.accent,
            inactiveColor: c.track,
            onChanged: (v) => setState(() => _servings = v),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                final repo = context.read<DiaryRepository>();
                final meal = widget.recipe.toMeal(
                  type: _type,
                  time: mealTimeFor(repo.selectedDate),
                  count: _servings,
                );
                repo.addMeal(meal);
                context.read<RecentFoodsController>().record(meal);
                Haptics.light();
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: c.onAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(loc.addToDiary,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── محرّر الوصفة ──────────────────────────────────────────────────────────────

class RecipeEditorScreen extends StatefulWidget {
  final Recipe? existing;
  const RecipeEditorScreen({super.key, this.existing});

  @override
  State<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends State<RecipeEditorScreen> {
  late final TextEditingController _name;
  late List<RecipeIngredient> _items;
  late int _servings;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _items = [...?e?.ingredients];
    _servings = e?.servings ?? 1;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _valid => _name.text.trim().isNotEmpty && _items.isNotEmpty;

  Recipe get _draft => Recipe(
        id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: _name.text.trim(),
        servings: _servings,
        ingredients: _items,
      );

  void _save() {
    if (!_valid) return;
    context.read<RecipeController>().save(_draft);
    Haptics.light();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final draft = _draft;

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
              Expanded(
                child: Text(
                    widget.existing == null
                        ? (loc.isAr ? 'وصفة جديدة' : 'New recipe')
                        : (loc.isAr ? 'تعديل الوصفة' : 'Edit recipe'),
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600, color: c.textPrimary)),
              ),
              TextButton(
                onPressed: _valid ? _save : null,
                style: TextButton.styleFrom(
                  backgroundColor: _valid ? c.accent : c.surfaceVariant,
                  foregroundColor: _valid ? c.onAccent : c.textTertiary,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(loc.save,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                TextField(
                  controller: _name,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(color: c.textPrimary),
                  decoration: InputDecoration(
                    hintText: loc.isAr ? 'اسم الوصفة — مثل: سلطتي' : 'Recipe name',
                    hintStyle: TextStyle(color: c.textTertiary),
                    filled: true,
                    fillColor: c.surface,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: c.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: c.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: c.accent)),
                  ),
                ),
                const SizedBox(height: 18),

                // ملخّص حي
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.accent.withOpacity(0.3)),
                  ),
                  child: Column(children: [
                    Row(children: [
                      Text(loc.isAr ? 'المجموع' : 'Total',
                          style: TextStyle(fontSize: 13, color: c.textSecondary)),
                      const Spacer(),
                      Text('${draft.totalCalories} ${loc.calorieUnit}',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary)),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      Text(loc.isAr ? 'للحصة الواحدة' : 'Per serving',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary)),
                      const Spacer(),
                      Text('${draft.caloriesPerServing} ${loc.calorieUnit}',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: c.accent)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 16),

                Row(children: [
                  Text(loc.isAr ? 'عدد الحصص' : 'Servings',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500, color: c.textPrimary)),
                  const Spacer(),
                  IconButton(
                    tooltip: AppLocalizations.of(context).isAr ? 'إنقاص' : 'Decrease',
                    onPressed: _servings > 1
                        ? () {
                            Haptics.select();
                            setState(() => _servings--);
                          }
                        : null,
                    icon: Icon(Icons.remove_circle_outline_rounded,
                        color: _servings > 1 ? c.accent : c.textTertiary),
                  ),
                  Text('$_servings',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700, color: c.textPrimary)),
                  IconButton(
                    tooltip: AppLocalizations.of(context).isAr ? 'زيادة' : 'Increase',
                    onPressed: _servings < 20
                        ? () {
                            Haptics.select();
                            setState(() => _servings++);
                          }
                        : null,
                    icon: Icon(Icons.add_circle_outline_rounded,
                        color: _servings < 20 ? c.accent : c.textTertiary),
                  ),
                ]),
                const SizedBox(height: 8),

                Row(children: [
                  Text(loc.isAr ? 'المكوّنات' : 'Ingredients',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _addIngredient,
                    icon: Icon(Icons.add_rounded, size: 18, color: c.accent),
                    label: Text(loc.isAr ? 'أضف' : 'Add',
                        style: TextStyle(color: c.accent)),
                  ),
                ]),

                if (_items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        loc.isAr ? 'أضف أول مكوّن' : 'Add your first ingredient',
                        style: TextStyle(fontSize: 13, color: c.textTertiary),
                      ),
                    ),
                  )
                else
                  ..._items.asMap().entries.map((e) {
                    final i = e.key;
                    final item = e.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.border),
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name(isAr: loc.isAr),
                                    style: TextStyle(
                                        fontSize: 14, color: c.textPrimary)),
                                Text('${item.grams} ${loc.grams} · ${item.calories} ${loc.calorieUnit}',
                                    style: TextStyle(
                                        fontSize: 11, color: c.textSecondary)),
                              ]),
                        ),
                        IconButton(
                          tooltip: AppLocalizations.of(context).isAr ? 'إنقاص' : 'Decrease',
                          onPressed: () {
                            Haptics.light();
                            setState(() => _items.removeAt(i));
                          },
                          icon: Icon(Icons.remove_circle_outline_rounded,
                              size: 20, color: c.textTertiary),
                        ),
                      ]),
                    );
                  }),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  void _addIngredient() {
    Haptics.select();
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PickIngredientSheet(
        onPick: (ing) => setState(() => _items.add(ing)),
      ),
    );
  }
}

class _PickIngredientSheet extends StatefulWidget {
  final ValueChanged<RecipeIngredient> onPick;
  const _PickIngredientSheet({required this.onPick});

  @override
  State<_PickIngredientSheet> createState() => _PickIngredientSheetState();
}

class _PickIngredientSheetState extends State<_PickIngredientSheet> {
  String _query = '';
  String? _selectedId;
  double _grams = 100;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final results = searchFoods(_query).take(20).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Column(children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration:
              BoxDecoration(color: c.textTertiary, borderRadius: BorderRadius.circular(4)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            style: TextStyle(color: c.textPrimary),
            decoration: InputDecoration(
              hintText: loc.searchFood,
              hintStyle: TextStyle(color: c.textTertiary),
              prefixIcon: Icon(Icons.search_rounded, color: c.textSecondary),
              filled: true,
              fillColor: c.surfaceVariant,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: c.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: c.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: c.accent)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            controller: scrollCtrl,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: results.length,
            itemBuilder: (_, i) {
              final f = results[i];
              final sel = f.id == _selectedId;
              return GestureDetector(
                onTap: () {
                  Haptics.select();
                  setState(() {
                    _selectedId = f.id;
                    _grams = f.typicalServingG.toDouble().clamp(10, 1000);
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: sel ? c.accent.withOpacity(0.12) : c.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: sel ? c.accent : c.border, width: sel ? 1.5 : 1),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Text(f.name(isAr: loc.isAr),
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                              color: sel ? c.accent : c.textPrimary)),
                    ),
                    Text('${f.kcalPer100g} / 100${loc.grams}',
                        style: TextStyle(fontSize: 11, color: c.textSecondary)),
                  ]),
                ),
              );
            },
          ),
        ),
        if (_selectedId != null)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(top: BorderSide(color: c.border)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Text(loc.isAr ? 'الكمية' : 'Amount',
                    style: TextStyle(fontSize: 14, color: c.textSecondary)),
                const Spacer(),
                Text('${_grams.round()} ${loc.grams}',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: c.accent)),
              ]),
              Slider(
                value: _grams,
                min: 10,
                max: 1000,
                divisions: 99,
                activeColor: c.accent,
                inactiveColor: c.track,
                onChanged: (v) => setState(() => _grams = v),
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    widget.onPick(RecipeIngredient(
                        foodId: _selectedId!, grams: _grams.round()));
                    Haptics.light();
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: c.accent,
                    foregroundColor: c.onAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape:
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(loc.isAr ? 'أضف المكوّن' : 'Add ingredient',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ),
      ]),
    );
  }
}
