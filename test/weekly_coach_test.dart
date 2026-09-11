import 'package:flutter_test/flutter_test.dart';
import 'package:zad/services/weekly_coach_service.dart';

WeekSummary _week({
  int daysLogged = 5,
  int avgCalories = 2000,
  int goalCalories = 2000,
  int avgProtein = 140,
  int goalProtein = 150,
  int daysOnTarget = 4,
  int workouts = 2,
  double? weightChangeKg,
}) =>
    WeekSummary(
      daysLogged: daysLogged,
      avgCalories: avgCalories,
      goalCalories: goalCalories,
      avgProtein: avgProtein,
      goalProtein: goalProtein,
      daysOnTarget: daysOnTarget,
      streak: 3,
      waterAvgCups: 6,
      workouts: workouts,
      weightChangeKg: weightChangeKg,
      goalLabel: 'إنقاص وزن',
    );

void main() {
  // بلا مفتاح في بيئة الاختبار، الخدمة تسقط للتقرير المحلي — وهو المقصود:
  // المستخدم لازم يحصل تقريراً مفيداً حتى بلا إنترنت.
  final coach = WeeklyCoachService();

  test('الملخّص لا يحمل أي بيانات شخصية', () {
    final json = _week().toPromptJson();
    final text = json.toString();
    expect(text.contains('@'), isFalse);
    expect(json.keys, isNot(contains('name')));
    expect(json.keys, isNot(contains('uid')));
  });

  test('يومان فأقل = بيانات غير كافية', () {
    expect(_week(daysLogged: 1).hasEnoughData, isFalse);
    expect(_week(daysLogged: 2).hasEnoughData, isTrue);
  });

  test('بيانات قليلة تعطي تشجيعاً لا لوماً', () async {
    final r = await coach.generate(_week(daysLogged: 1));
    expect(r.headline.isNotEmpty, isTrue);
    expect(r.tip.isNotEmpty, isTrue);
    expect(r.body.contains('فشل'), isFalse);
  });

  test('تجاوز الهدف ينتج نصيحة تقليل', () async {
    final r = await coach.generate(_week(avgCalories: 2600, goalCalories: 2000));
    expect(r.headline, contains('فوق'));
    expect(r.tip, contains('قلّل'));
  });

  test('أقل بكثير من الهدف يُنبَّه عليه بدل تشجيع التجويع', () async {
    final r = await coach.generate(
        _week(avgCalories: 1400, goalCalories: 2000, avgProtein: 140, goalProtein: 150));
    expect(r.headline, contains('تحت'));
    expect(r.tip, contains('2000'));
  });

  test('بروتين منخفض له أولوية في النصيحة', () async {
    final r = await coach.generate(_week(avgProtein: 60, goalProtein: 150));
    expect(r.tip, contains('بروتين'));
    expect(r.tip, contains('150'));
  });

  test('التقرير دائماً يحتوي نصيحة واحدة غير فارغة', () async {
    for (final w in [
      _week(),
      _week(daysLogged: 0),
      _week(avgCalories: 3000),
      _week(workouts: 0, daysOnTarget: 0),
    ]) {
      final r = await coach.generate(w);
      expect(r.tip.trim().isNotEmpty, isTrue);
      expect(r.body.trim().isNotEmpty, isTrue);
    }
  });

  tearDownAll(coach.close);
}
