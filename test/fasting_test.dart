import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zad/data/fasting_controller.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('البروتوكولات لها معرّفات فريدة ونوافذ أكل منطقية', () {
    final ids = <String>{};
    for (final p in kFastingPlans) {
      expect(ids.add(p.id), isTrue, reason: 'معرّف مكرر ${p.id}');
      expect(p.fastHours, inInclusiveRange(8, 23));
      expect(p.eatHours, 24 - p.fastHours);
    }
  });

  test('البدء والإيقاف يسجّلان جلسة', () async {
    final f = FastingController();
    expect(f.isFasting, isFalse);
    await f.start();
    expect(f.isFasting, isTrue);
    expect(f.startedAt, isNotNull);
    final s = await f.stop();
    expect(f.isFasting, isFalse);
    // جلسة أقل من دقيقة لا تُسجَّل — ضغطة خاطئة
    expect(s, isNotNull);
    expect(f.log, isEmpty);
  });

  test('البدء مرتين لا يعيد ضبط وقت البدء', () async {
    final f = FastingController();
    await f.start();
    final first = f.startedAt;
    await f.start();
    expect(f.startedAt, first);
  });

  test('الإيقاف بلا جلسة يرجّع null', () async {
    final f = FastingController();
    expect(await f.stop(), isNull);
  });

  test('التقدّم والمتبقّي يُحسبان من وقت البدء', () async {
    SharedPreferences.setMockInitialValues({
      'zad_fast_plan': '16_8',
      'zad_fast_start':
          DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(),
    });
    final f = FastingController();
    await f.load();
    expect(f.isFasting, isTrue);
    expect(f.plan.fastHours, 16);
    expect(f.progress, closeTo(0.5, 0.02));
    expect(f.remaining.inHours, 7); // ٧ ساعات و٥٩ دقيقة
    expect(f.reachedGoal, isFalse);
  });

  test('تجاوز الهدف: التقدّم يُحصر بـ 1 والمتبقّي صفر', () async {
    SharedPreferences.setMockInitialValues({
      'zad_fast_plan': '16_8',
      'zad_fast_start':
          DateTime.now().subtract(const Duration(hours: 20)).toIso8601String(),
    });
    final f = FastingController();
    await f.load();
    expect(f.progress, 1.0);
    expect(f.remaining, Duration.zero);
    expect(f.reachedGoal, isTrue);
  });

  test('جلسة منسيّة أقدم من ٤٨ ساعة تُتجاهل', () async {
    SharedPreferences.setMockInitialValues({
      'zad_fast_start':
          DateTime.now().subtract(const Duration(hours: 60)).toIso8601String(),
    });
    final f = FastingController();
    await f.load();
    expect(f.isFasting, isFalse,
        reason: 'عرض عدّاد ٦٠ ساعة مضلّل — الجلسة منسيّة');
  });

  test('اختيار البروتوكول يُحفظ', () async {
    final a = FastingController();
    await a.setPlan(kFastingPlans.first);

    final b = FastingController();
    await b.load();
    expect(b.plan.id, kFastingPlans.first.id);
  });

  test('reachedGoal في الجلسة يقارن بالهدف وقتها', () {
    final done = FastSession(
      start: DateTime(2026, 1, 1, 20),
      end: DateTime(2026, 1, 2, 12),
      targetHours: 16,
    );
    final short = FastSession(
      start: DateTime(2026, 1, 1, 20),
      end: DateTime(2026, 1, 2, 6),
      targetHours: 16,
    );
    expect(done.reachedGoal, isTrue);
    expect(short.reachedGoal, isFalse);
  });

  test('عدّ أهداف الأسبوع يتجاهل الجلسات الأقدم', () async {
    final old = FastSession(
      start: DateTime.now().subtract(const Duration(days: 20)),
      end: DateTime.now().subtract(const Duration(days: 20)).add(const Duration(hours: 17)),
      targetHours: 16,
    );
    final recent = FastSession(
      start: DateTime.now().subtract(const Duration(days: 2)),
      end: DateTime.now().subtract(const Duration(days: 2)).add(const Duration(hours: 17)),
      targetHours: 16,
    );
    SharedPreferences.setMockInitialValues({
      'zad_fast_log': '[${_json(old)},${_json(recent)}]',
    });
    final f = FastingController();
    await f.load();
    expect(f.log.length, 2);
    expect(f.goalsThisWeek, 1);
  });
}

String _json(FastSession s) =>
    '{"s":"${s.start.toIso8601String()}","e":"${s.end.toIso8601String()}","h":${s.targetHours}}';
