import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/meal.dart';

/// يرفع ما سُجِّل محلياً (قبل الاتصال) إلى حساب المستخدم بعد نجاح الدخول،
/// ثم يمسح النسخة المحلية. يعمل مرة واحدة ولا يرمي أبداً.
abstract class DiaryMigrator {
  static bool _running = false;

  static Future<void> migrate({
    required String userId,
    required Map<String, List<Meal>> local,
  }) async {
    if (_running || local.isEmpty) return;
    _running = true;
    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();
      var count = 0;
      local.forEach((dayKey, meals) {
        for (final m in meals) {
          final ref = db
              .collection('users')
              .doc(userId)
              .collection('diary')
              .doc(dayKey)
              .collection('meals')
              .doc(m.id);
          batch.set(ref, m.toJson());
          count++;
        }
      });
      if (count == 0) return;
      await batch.commit();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('zad_local_diary');
      debugPrint('رُحّلت $count وجبة محلية للسحابة');
    } catch (e) {
      // فشل الترحيل يترك البيانات المحلية كما هي — نعيد المحاولة لاحقاً.
      debugPrint('Diary migration failed: $e');
    } finally {
      _running = false;
    }
  }

  /// للاختبارات فقط.
  @visibleForTesting
  static void resetForTest() => _running = false;
}
