import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/food_seed.dart';
import '../models/food_item.dart';
import '../models/meal.dart';

class MealPlanEntry {
  final String dayKey; // 'Mon', 'Tue', ...
  final MealType type;
  final String foodId;
  final int grams;

  const MealPlanEntry({
    required this.dayKey,
    required this.type,
    required this.foodId,
    required this.grams,
  });

  FoodItem? get food => foodById(foodId);

  int get calories {
    final f = food;
    if (f == null) return 0;
    return (f.kcalPer100g * grams / 100).round();
  }

  Map<String, dynamic> toMap() => {'day': dayKey, 'type': type.name, 'food': foodId, 'grams': grams};

  factory MealPlanEntry.fromMap(Map<String, dynamic> m) => MealPlanEntry(
    dayKey: m['day'] as String,
    type: MealType.values.byName(m['type'] as String),
    foodId: m['food'] as String,
    grams: m['grams'] as int,
  );
}

class MealPlanController extends ChangeNotifier {
  static const _key = 'zad_meal_plan';
  List<MealPlanEntry> _entries = [];

  List<MealPlanEntry> get entries => List.unmodifiable(_entries);

  List<MealPlanEntry> forDay(String dayKey) =>
      _entries.where((e) => e.dayKey == dayKey).toList();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _entries = list.map(MealPlanEntry.fromMap).toList();
      notifyListeners();
    }
  }

  Future<void> add(MealPlanEntry e) async {
    _entries.add(e);
    notifyListeners();
    await _persist();
  }

  Future<void> remove(MealPlanEntry e) async {
    final idx = _entries.indexWhere(
        (x) => x.dayKey == e.dayKey && x.type == e.type && x.foodId == e.foodId);
    if (idx != -1) _entries.removeAt(idx);
    notifyListeners();
    await _persist();
  }

  List<String> shoppingList() {
    final map = <String, int>{};
    for (final e in _entries) {
      map[e.foodId] = (map[e.foodId] ?? 0) + e.grams;
    }
    return map.entries.map((kv) {
      final f = foodById(kv.key);
      final name = f?.nameAr ?? kv.key;
      return '$name — ${kv.value}g';
    }).toList();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_entries.map((e) => e.toMap()).toList()));
  }
}
