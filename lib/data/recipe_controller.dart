import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/food_seed.dart';
import '../models/meal.dart';

/// مكوّن في وصفة: صنف من القاعدة بكمية بالجرام.
@immutable
class RecipeIngredient {
  final String foodId;
  final int grams;

  const RecipeIngredient({required this.foodId, required this.grams});

  /// الاسم بلغة الواجهة، أو المعرّف إن حُذف الصنف من القاعدة.
  String name({required bool isAr}) =>
      foodById(foodId)?.name(isAr: isAr) ?? foodId;

  int get calories {
    final f = foodById(foodId);
    return f == null ? 0 : (f.kcalPer100g * grams / 100).round();
  }

  Macros get macros {
    final f = foodById(foodId);
    if (f == null) return const Macros();
    final k = grams / 100.0;
    return Macros(
      protein: (f.proteinPer100g * k).round(),
      carbs: (f.carbsPer100g * k).round(),
      fat: (f.fatPer100g * k).round(),
    );
  }

  Map<String, dynamic> toMap() => {'f': foodId, 'g': grams};

  factory RecipeIngredient.fromMap(Map<String, dynamic> m) => RecipeIngredient(
        foodId: m['f'] as String,
        grams: (m['g'] as num).round(),
      );
}

/// وصفة يحفظها المستخدم: مكوّنات + عدد حصص.
/// تُسجَّل كوجبة واحدة بدل إدخال كل مكوّن على حدة.
@immutable
class Recipe {
  final String id;
  final String name;
  final int servings;
  final List<RecipeIngredient> ingredients;

  const Recipe({
    required this.id,
    required this.name,
    required this.servings,
    required this.ingredients,
  });

  int get totalCalories =>
      ingredients.fold<int>(0, (a, i) => a + i.calories);

  Macros get totalMacros =>
      ingredients.fold(const Macros(), (a, i) => a + i.macros);

  int get totalGrams => ingredients.fold<int>(0, (a, i) => a + i.grams);

  /// عدد الحصص لا ينزل تحت ١ — القسمة على صفر تُنتج قيماً لا نهائية.
  int get _safeServings => servings < 1 ? 1 : servings;

  int get caloriesPerServing => (totalCalories / _safeServings).round();

  Macros get macrosPerServing {
    final m = totalMacros;
    final s = _safeServings;
    return Macros(
      protein: (m.protein / s).round(),
      carbs: (m.carbs / s).round(),
      fat: (m.fat / s).round(),
    );
  }

  /// يبني وجبة من [count] حصة جاهزة للتسجيل في اليوميات.
  Meal toMeal({
    required MealType type,
    required DateTime time,
    double count = 1,
    String? idOverride,
  }) {
    final m = macrosPerServing;
    return Meal(
      id: idOverride ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: count == 1 ? name : '$name ×${count.toStringAsFixed(count == count.roundToDouble() ? 0 : 1)}',
      calories: (caloriesPerServing * count).round(),
      macros: Macros(
        protein: (m.protein * count).round(),
        carbs: (m.carbs * count).round(),
        fat: (m.fat * count).round(),
      ),
      time: time,
      type: type,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'servings': servings,
        'items': ingredients.map((i) => i.toMap()).toList(),
      };

  factory Recipe.fromMap(Map<String, dynamic> m) => Recipe(
        id: m['id'] as String,
        name: m['name'] as String,
        servings: (m['servings'] as num?)?.round() ?? 1,
        ingredients: ((m['items'] as List?) ?? const [])
            .map((e) => RecipeIngredient.fromMap(e as Map<String, dynamic>))
            .toList(),
      );
}

/// وصفات المستخدم المحفوظة محلياً.
class RecipeController extends ChangeNotifier {
  static const _key = 'zad_recipes';

  final List<Recipe> _recipes = [];
  List<Recipe> get recipes => List.unmodifiable(_recipes);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _recipes
        ..clear()
        ..addAll(list.map(Recipe.fromMap));
      notifyListeners();
    } catch (e) {
      debugPrint('RecipeController load error: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_key);
      } catch (_) {}
    }
  }

  Future<void> save(Recipe r) async {
    final i = _recipes.indexWhere((x) => x.id == r.id);
    if (i == -1) {
      _recipes.insert(0, r);
    } else {
      _recipes[i] = r;
    }
    notifyListeners();
    await _persist();
  }

  Future<void> remove(Recipe r) async {
    _recipes.removeWhere((x) => x.id == r.id);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, jsonEncode(_recipes.map((e) => e.toMap()).toList()));
    } catch (e) {
      debugPrint('RecipeController persist error: $e');
    }
  }
}
