import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zad/data/activity_controller.dart';
import 'package:zad/data/weight_controller.dart';

/// الإجراءات المدمّرة القابلة للاسترجاع يجب أن تعيد **نفس** البيانات،
/// لا نسخة جديدة بتاريخ اليوم — وإلا فالتراجع يفسد السجل بدل إصلاحه.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('تراجع حذف الوزن', () {
    test('الاسترجاع يحفظ التاريخ الأصلي لا تاريخ اليوم', () async {
      final c = WeightController();
      final old = WeightEntry(DateTime(2026, 3, 4), 81.5);
      await c.restore(old);
      expect(c.entries.single.date, DateTime(2026, 3, 4));

      final removed = c.entries.single;
      await c.remove(removed);
      expect(c.entries, isEmpty);

      await c.restore(removed);
      expect(c.entries.single.date, DateTime(2026, 3, 4),
          reason: 'التراجع لازم يرجّع الإدخال كما كان');
      expect(c.entries.single.kg, 81.5);
    });

    test('الاسترجاع يحافظ على الترتيب الزمني', () async {
      final c = WeightController();
      await c.restore(WeightEntry(DateTime(2026, 3, 10), 80));
      await c.restore(WeightEntry(DateTime(2026, 3, 1), 82));
      expect(c.entries.first.date, DateTime(2026, 3, 1));
      expect(c.latest, 80, reason: 'الأحدث هو آخر القائمة بعد الفرز');
    });

    test('الاسترجاع يُحفظ على القرص', () async {
      final a = WeightController();
      await a.restore(WeightEntry(DateTime(2026, 3, 4), 77.7));

      final b = WeightController();
      await b.load();
      expect(b.entries.single.kg, 77.7);
    });
  });

  group('تراجع حذف النشاط', () {
    test('إعادة الإضافة تستعيد السعرات المحروقة كاملة', () async {
      final c = ActivityController();
      final e = ActivityEntry(
          id: 'run', name: 'جري', minutes: 30, calories: 250, date: DateTime.now());
      await c.add(e);
      expect(c.burnedToday, 250);

      await c.remove(e);
      expect(c.burnedToday, 0);

      await c.add(e);
      expect(c.burnedToday, 250, reason: 'التراجع يرجّع النشاط نفسه');
      expect(c.entries.single.minutes, 30);
    });

    test('التراجع يُحفظ على القرص', () async {
      final a = ActivityController();
      final e = ActivityEntry(
          id: 'swim', name: 'سباحة', minutes: 40, calories: 320, date: DateTime.now());
      await a.add(e);
      await a.remove(e);
      await a.add(e);

      final b = ActivityController();
      await b.load();
      expect(b.burnedToday, 320);
    });
  });
}
