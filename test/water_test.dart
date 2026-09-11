import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zad/data/challenges_data.dart';
import 'package:zad/data/water_controller.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('الهدف الافتراضي ٨ أكواب', () async {
    final w = WaterController();
    await w.load();
    expect(w.goal, 8);
    expect(w.cups, 0);
  });

  test('الإضافة والإنقاص ضمن الحدود', () async {
    final w = WaterController();
    await w.load();
    await w.add();
    await w.add();
    expect(w.cups, 2);
    await w.remove();
    expect(w.cups, 1);
  });

  test('الإنقاص تحت الصفر مستحيل', () async {
    final w = WaterController();
    await w.load();
    await w.remove();
    expect(w.cups, 0);
  });

  test('سقف الإضافة = الهدف + ٤', () async {
    final w = WaterController();
    await w.load();
    for (var i = 0; i < 50; i++) {
      await w.add();
    }
    expect(w.cups, w.goal + 4);
  });

  test('تغيير الهدف يُحفظ ويُقرأ', () async {
    final a = WaterController();
    await a.load();
    await a.setGoal(12);
    expect(a.goal, 12);

    final b = WaterController();
    await b.load();
    expect(b.goal, 12);
  });

  test('الهدف يُحصر بين الحد الأدنى والأعلى — لا صفر ولا خيالي', () async {
    final w = WaterController();
    await w.load();
    await w.setGoal(0);
    expect(w.goal, WaterController.minGoal);
    await w.setGoal(9999);
    expect(w.goal, WaterController.maxGoal);
  });

  test('هدف محفوظ خارج الحدود يُصحَّح عند التحميل', () async {
    SharedPreferences.setMockInitialValues({'zad_water_goal': 500});
    final w = WaterController();
    await w.load();
    expect(w.goal, WaterController.maxGoal);
  });

  test('تحدي الماء يتبع هدف المستخدم لا الرقم الثابت', () {
    final challenges = buildChallenges(
      streakDays: 0,
      waterCups: 5,
      underGoalToday: false,
      waterGoal: 12,
    );
    final water = challenges.firstWhere((c) => c.id == 'water8');
    expect(water.target, 12);
    expect(water.titleAr, contains('12'));
    expect(water.current, 5);
  });

  test('أكواب أكثر من الهدف لا تتجاوز الهدف في التحدي', () {
    final challenges = buildChallenges(
      streakDays: 0,
      waterCups: 20,
      underGoalToday: false,
      waterGoal: 8,
    );
    final water = challenges.firstWhere((c) => c.id == 'water8');
    expect(water.current, 8);
    expect(water.progress, 1.0);
  });
}
