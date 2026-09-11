import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/dates.dart';
import '../models/meal.dart';
import 'diary_repository.dart';

/// يوميات محلية تُحفظ على الجهاز — تُستخدم قبل نجاح الدخول المجهول
/// (أول تشغيل بلا إنترنت). ما يُسجَّل هنا يُرحَّل للسحابة عند الاتصال.
class LocalDiaryRepository extends DiaryRepository {
  static const _key = 'zad_local_diary';

  @override
  final DailyGoal goal;
  final String _name;

  LocalDiaryRepository({required this.goal, String name = ''}) : _name = name {
    _load();
  }

  /// يوم → وجباته.
  final Map<String, List<Meal>> _byDay = {};
  DateTime _selectedDate = DateTime.now();
  bool _disposed = false;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _byDay.clear();
      map.forEach((day, meals) {
        _byDay[day] = (meals as List)
            .map((m) {
              try {
                return Meal.fromJson(m as Map<String, dynamic>);
              } catch (_) {
                return null;
              }
            })
            .whereType<Meal>()
            .toList();
      });
      _safeNotify();
    } catch (e) {
      debugPrint('LocalDiary load error: $e');
      await _clearCorrupt();
    }
  }

  Future<void> _clearCorrupt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _byDay.map(
          (day, meals) => MapEntry(day, meals.map((m) => m.toJson()).toList()));
      await prefs.setString(_key, jsonEncode(map));
    } catch (e) {
      debugPrint('LocalDiary persist error: $e');
    }
  }

  @override
  DateTime get selectedDate => _selectedDate;

  @override
  void selectDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    _safeNotify();
  }

  @override
  List<Meal> get todayMeals =>
      List.unmodifiable(_byDay[dayKey(_selectedDate)] ?? const <Meal>[]);

  @override
  String get userName => _name;

  @override
  int get streakDays {
    final today = DateTime.now();
    var streak = 0;
    for (var i = 0; i <= 60; i++) {
      final day = today.subtract(Duration(days: i));
      final has = (_byDay[dayKey(day)] ?? const []).isNotEmpty;
      if (!has) {
        if (i == 0) continue; // اليوم لم ينتهِ
        break;
      }
      streak++;
    }
    return streak;
  }

  @override
  Macros get consumedMacros =>
      todayMeals.fold(const Macros(), (acc, m) => acc + m.macros);

  @override
  int get consumedCalories => todayMeals.fold(0, (acc, m) => acc + m.calories);

  @override
  int get remainingCalories =>
      (goal.calories - consumedCalories).clamp(0, goal.calories);

  @override
  void addMeal(Meal meal) {
    _byDay.putIfAbsent(dayKey(_selectedDate), () => []).add(meal);
    _safeNotify();
    _persist();
  }

  @override
  void removeMeal(Meal meal) {
    _byDay[dayKey(_selectedDate)]?.removeWhere((m) => m.id == meal.id);
    _safeNotify();
    _persist();
  }

  @override
  Future<List<Meal>> getMealsForDay(DateTime date) async =>
      List.unmodifiable(_byDay[dayKey(date)] ?? const <Meal>[]);

  /// كل ما سُجّل محلياً — للترحيل للسحابة بعد نجاح الدخول.
  Map<String, List<Meal>> snapshot() =>
      _byDay.map((k, v) => MapEntry(k, List<Meal>.unmodifiable(v)));

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
