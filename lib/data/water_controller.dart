import 'package:flutter/foundation.dart';
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDate = prefs.getString(_dateKey);
      _cups = savedDate == _today ? (prefs.getInt(_countKey) ?? 0) : 0;
      notifyListeners();
    } catch (e) {
      debugPrint('WaterController load error: $e');
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_countKey, _cups);
      await prefs.setString(_dateKey, _today);
    } catch (e) {
      debugPrint('WaterController persist error: $e');
    }
  }

  /// لو تغيّر اليوم والتطبيق مفتوح — صفّر العداد قبل أي تعديل.
  Future<void> _rolloverIfNewDay() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDate = prefs.getString(_dateKey);
      if (savedDate != null && savedDate != _today && _cups != 0) {
        _cups = 0;
        notifyListeners(); // بدونه تبقى الواجهة على عدّاد الأمس
      }
    } catch (e) {
      debugPrint('WaterController rollover error: $e');
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
