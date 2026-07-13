import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_palette.dart';

/// يدير الثيم الحالي ويحفظ اختيار المستخدم بين الجلسات.
class ThemeController extends ChangeNotifier {
  static const _prefsKey = 'zad_palette';

  ZadPalette _palette = ZadPalette.energy;
  ZadPalette get palette => _palette;

  /// يحمّل الثيم المحفوظ عند الإقلاع.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null) {
      _palette = ZadPalette.values.firstWhere(
        (p) => p.name == saved,
        orElse: () => ZadPalette.energy,
      );
      notifyListeners();
    }
  }

  /// يبدّل الثيم ويحفظه — الواجهة تتمايل تلقائياً عبر AnimatedTheme.
  Future<void> setPalette(ZadPalette palette) async {
    if (_palette == palette) return;
    _palette = palette;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, palette.name);
  }
}
