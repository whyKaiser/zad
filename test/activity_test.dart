import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zad/data/activity_controller.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('معادلة MET: جري خفيف 30 دقيقة لوزن 70 كجم ≈ 257 سعرة', () {
    final run = activityById('run')!;
    // 7.0 × 3.5 × 70 ÷ 200 × 30 = 257.25
    expect(run.caloriesFor(weightKg: 70, minutes: 30), 257);
  });

  test('السعرات تتناسب طردياً مع الوزن والمدة (بهامش تقريب)', () {
    final walk = activityById('walk')!;
    final light = walk.caloriesFor(weightKg: 60, minutes: 30);
    final heavier = walk.caloriesFor(weightKg: 120, minutes: 30);
    final longer = walk.caloriesFor(weightKg: 60, minutes: 60);
    // التقريب لأقرب عدد صحيح قد يزيح الناتج بسعرة واحدة.
    expect(heavier, closeTo(light * 2, 1));
    expect(longer, closeTo(light * 2, 1));
  });

  test('كل الأنشطة لها MET موجب ومعرّف فريد', () {
    final ids = <String>{};
    for (final a in kActivities) {
      expect(a.met, greaterThan(0));
      expect(ids.add(a.id), isTrue, reason: 'معرّف مكرر: ${a.id}');
      expect(a.nameAr.isNotEmpty, isTrue);
      expect(a.nameEn.isNotEmpty, isTrue);
    }
  });

  test('إجمالي المحروق اليوم يجمع كل التسجيلات', () async {
    final c = ActivityController();
    await c.add(ActivityEntry(
        id: 'run', name: 'جري', minutes: 30, calories: 250, date: DateTime.now()));
    await c.add(ActivityEntry(
        id: 'walk', name: 'مشي', minutes: 20, calories: 80, date: DateTime.now()));
    expect(c.burnedToday, 330);
  });

  test('نشاط أمس لا يُحتسب ضمن اليوم', () async {
    final c = ActivityController();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await c.add(ActivityEntry(
        id: 'run', name: 'جري', minutes: 30, calories: 250, date: yesterday));
    expect(c.burnedToday, 0);
    expect(c.burnedOn(yesterday), 250);
  });

  test('الحذف يخصم من الإجمالي', () async {
    final c = ActivityController();
    final e = ActivityEntry(
        id: 'run', name: 'جري', minutes: 30, calories: 250, date: DateTime.now());
    await c.add(e);
    await c.remove(e);
    expect(c.burnedToday, 0);
  });

  test('البيانات تُحفظ وتُقرأ بعد إعادة التحميل', () async {
    final a = ActivityController();
    await a.add(ActivityEntry(
        id: 'swim', name: 'سباحة', minutes: 45, calories: 400, date: DateTime.now()));

    final b = ActivityController();
    await b.load();
    expect(b.burnedToday, 400);
    expect(b.entries.first.name, 'سباحة');
  });
}
