import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// يدير لغة التطبيق (عربي/إنجليزي) ويحفظ الاختيار.
class LocaleController extends ChangeNotifier {
  static const _prefsKey = 'zad_locale';

  Locale _locale = const Locale('ar');
  Locale get locale => _locale;

  bool get isAr => _locale.languageCode == 'ar';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null) {
      _locale = Locale(saved);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }

  void toggle() => setLocale(isAr ? const Locale('en') : const Locale('ar'));
}
