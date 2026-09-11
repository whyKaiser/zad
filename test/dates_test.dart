import 'package:flutter_test/flutter_test.dart';
import 'package:zad/core/dates.dart';

void main() {
  test('isSameDay يتجاهل الوقت', () {
    final a = DateTime(2026, 9, 11, 1, 5);
    final b = DateTime(2026, 9, 11, 23, 59);
    expect(isSameDay(a, b), isTrue);
    expect(isSameDay(a, DateTime(2026, 9, 12)), isFalse);
  });

  test('dayKey يصفّر الشهر واليوم لخانتين', () {
    expect(dayKey(DateTime(2026, 1, 5)), '2026-01-05');
    expect(dayKey(DateTime(2026, 12, 31)), '2026-12-31');
  });

  test('mealTimeFor لليوم الحالي يرجّع الوقت الحالي', () {
    final t = mealTimeFor(DateTime.now());
    expect(isToday(t), isTrue);
  });

  test('mealTimeFor ليوم سابق يبقى داخل ذلك اليوم', () {
    final past = DateTime(2026, 3, 4);
    final t = mealTimeFor(past);
    expect(isSameDay(t, past), isTrue,
        reason: 'وجبة تُسجَّل ليوم سابق لازم تحمل تاريخ ذلك اليوم');
    expect(t.hour, DateTime.now().hour);
  });

  test('isToday يميّز الأمس', () {
    expect(isToday(DateTime.now()), isTrue);
    expect(isToday(DateTime.now().subtract(const Duration(days: 1))), isFalse);
  });
}
