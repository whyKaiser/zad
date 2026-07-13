import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// عدّاد أكواب الماء اليومي — يتصفّر مع يوم جديد. يُحفظ محلياً.
class WaterController extends ChangeNotifier {
  static const _countKey = 'zad_water_count';
  static const _dateKey = 'zad_water_date';

  final int goal = 8;
  int _cups = 0;
  int get cups => _cups;

  String get _today => DateTime.now().toIso8601String().substring(0, 10);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_dateKey);
    if (savedDate == _today) {
      _cups = prefs.getInt(_countKey) ?? 0;
    } else {
      _cups = 0; // يوم جديد
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_countKey, _cups);
    await prefs.setString(_dateKey, _today);
  }

  /// لو تغيّر اليوم والتطبيق مفتوح — صفّر العداد قبل أي تعديل.
  Future<void> _rolloverIfNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_dateKey);
    if (savedDate != null && savedDate != _today) {
      _cups = 0;
    }
  }

  Future<void> add() async {
    await _rolloverIfNewDay();
    if (_cups >= goal + 4) return;
    _cups++;
    notifyListeners();
    await _persist();
  }

  Future<void> remove() async {
    await _rolloverIfNewDay();
    if (_cups == 0) return;
    _cups--;
    notifyListeners();
    await _persist();
  }
}
