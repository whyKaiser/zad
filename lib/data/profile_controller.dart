import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

/// يدير ملف المستخدم ويحفظه. onboarded = صار له ملف.
class ProfileController extends ChangeNotifier {
  static const _prefsKey = 'zad_profile';

  ProfileController();

  /// لتهيئة الاختبارات بملف جاهز بدون تخزين.
  ProfileController.seeded(this._profile);

  UserProfile? _profile;
  UserProfile? get profile => _profile;
  bool get onboarded => _profile != null;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null) {
      try {
        _profile = UserProfile.fromJson(saved);
        notifyListeners();
      } catch (e) {
        // ملف تالف — نمسحه ونعيد onboarding بدل فشل متكرر كل إقلاع.
        debugPrint('ProfileController load error: $e');
        try {
          await prefs.remove(_prefsKey);
        } catch (_) {}
      }
    }
  }

  Future<void> save(UserProfile profile) async {
    _profile = profile;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, profile.toJson());
  }
}
