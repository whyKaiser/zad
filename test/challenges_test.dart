import 'package:flutter_test/flutter_test.dart';
import 'package:zad/data/challenges_data.dart';

void main() {
  test('لوحة الصدارة لا تحتوي على مستخدم مميّز (أنا) — يُضاف ديناميكياً', () {
    final me = kLeaderboard.where((e) => e.isMe).toList();
    expect(me.length, 0);
  });

  test('كل التحديات المبنية لها هدف موجب وتقدّم منطقي', () {
    final challenges = buildChallenges(
      streakDays: 3,
      waterCups: 5,
      underGoalToday: true,
    );
    for (final ch in challenges) {
      expect(ch.target, greaterThan(0));
      expect(ch.current, lessThanOrEqualTo(ch.target));
      expect(ch.progress, inInclusiveRange(0.0, 1.0));
    }
  });
}
