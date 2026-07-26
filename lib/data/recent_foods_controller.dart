import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/meal.dart';

/// صنف مسجَّل سابقاً — يحفظ القيم النهائية (بعد حساب الكمية)
/// عشان يشتغل مع قاعدة الأطعمة و Open Food Facts والمخصص والـ AI بنفس الشكل.
@immutable
class QuickFood {
  final String name;
  final int calories;
  final Macros macros;
  final int grams;
  final DateTime lastUsed;
  final int useCount;

  const QuickFood({
    required this.name,
    required this.calories,
    required this.macros,
    required this.grams,
    required this.lastUsed,
    this.useCount = 1,
  });

  /// المفتاح الفريد: الاسم + الكمية — نفس الصنف بكمية مختلفة = إدخال منفصل.
  String get key => '$name|$grams';

  QuickFood bumped() => QuickFood(
        name: name,
        calories: calories,
        macros: macros,
        grams: grams,
        lastUsed: DateTime.now(),
        useCount: useCount + 1,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'cal': calories,
        'p': macros.protein,
        'c': macros.carbs,
        'f': macros.fat,
        'g': grams,
        'at': lastUsed.toIso8601String(),
        'n': useCount,
      };

  factory QuickFood.fromMap(Map<String, dynamic> m) => QuickFood(
        name: m['name'] as String,
        calories: (m['cal'] as num).round(),
        macros: Macros(
          protein: (m['p'] as num? ?? 0).round(),
          carbs: (m['c'] as num? ?? 0).round(),
          fat: (m['f'] as num? ?? 0).round(),
        ),
        grams: (m['g'] as num? ?? 100).round(),
        lastUsed: DateTime.parse(m['at'] as String),
        useCount: (m['n'] as num? ?? 1).round(),
      );
}

/// يدير الأصناف الأخيرة والمفضّلة — يقلّل احتكاك التسجيل اليومي.
class RecentFoodsController extends ChangeNotifier {
  static const _recentsKey = 'zad_recent_foods';
  static const _favsKey = 'zad_favorite_foods';
  static const _maxRecents = 30;

  final List<QuickFood> _recents = [];
  final Set<String> _favoriteKeys = {};

  /// الأخيرة مرتّبة من الأحدث.
  List<QuickFood> get recents => List.unmodifiable(_recents);

  /// المفضّلة مرتّبة بالأكثر استخداماً.
  List<QuickFood> get favorites {
    final favs = _recents.where((f) => _favoriteKeys.contains(f.key)).toList();
    favs.sort((a, b) => b.useCount.compareTo(a.useCount));
    return List.unmodifiable(favs);
  }

  bool isFavorite(QuickFood f) => _favoriteKeys.contains(f.key);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_recentsKey);
      if (raw != null) {
        final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        _recents
          ..clear()
          ..addAll(list.map(QuickFood.fromMap));
      }
      _favoriteKeys.addAll(prefs.getStringList(_favsKey) ?? const []);
      notifyListeners();
    } catch (e) {
      debugPrint('RecentFoods load error: $e');
    }
  }

  /// يُسجّل استخدام صنف — يرفعه لأعلى القائمة ويزيد عدّاده.
  Future<void> record(Meal meal, {int grams = 0}) async {
    final entry = QuickFood(
      name: meal.name,
      calories: meal.calories,
      macros: meal.macros,
      grams: grams > 0 ? grams : 100,
      lastUsed: DateTime.now(),
    );
    final idx = _recents.indexWhere((f) => f.key == entry.key);
    if (idx != -1) {
      final bumped = _recents.removeAt(idx).bumped();
      _recents.insert(0, bumped);
    } else {
      _recents.insert(0, entry);
    }
    // احتفظ بالمفضّلة دائماً حتى لو تجاوزنا الحد.
    while (_recents.length > _maxRecents) {
      final removable = _recents.lastIndexWhere((f) => !_favoriteKeys.contains(f.key));
      if (removable == -1) break;
      _recents.removeAt(removable);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> toggleFavorite(QuickFood f) async {
    if (!_favoriteKeys.remove(f.key)) _favoriteKeys.add(f.key);
    notifyListeners();
    await _persist();
  }

  Future<void> remove(QuickFood f) async {
    _recents.removeWhere((x) => x.key == f.key);
    _favoriteKeys.remove(f.key);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _recentsKey, jsonEncode(_recents.map((e) => e.toMap()).toList()));
      await prefs.setStringList(_favsKey, _favoriteKeys.toList());
    } catch (e) {
      debugPrint('RecentFoods persist error: $e');
    }
  }
}
