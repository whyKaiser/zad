import 'package:flutter_test/flutter_test.dart';
import 'package:zad/models/detraining.dart';

void main() {
  test('انقطاع قصير للمتقدّم = تراجع بسيط', () {
    final e = estimateDetraining(
        weeksOff: 2, experience: TrainingExperience.advanced, reason: BreakReason.travel);
    expect(e.strengthLossPct, 0); // ضمن فترة السماح (4 أسابيع)
    expect(e.startWeightPct, 85);
    expect(e.recoveryWeeks, 3);
  });

  test('انقطاع 12 أسبوع للمتوسط', () {
    final e = estimateDetraining(
        weeksOff: 12, experience: TrainingExperience.intermediate, reason: BreakReason.travel);
    expect(e.strengthLossPct, 18); // (12-3)*2
    expect(e.muscleLossPct, 10); // (12-2)*1
    expect(e.cardioLossPct, 25); // (12-1)*2.3 ≈ 25
    expect(e.recoveryWeeks, 10);
  });

  test('الإصابة تخفّض وزن البداية أكثر', () {
    final travel = estimateDetraining(
        weeksOff: 12, experience: TrainingExperience.intermediate, reason: BreakReason.travel);
    final injury = estimateDetraining(
        weeksOff: 12, experience: TrainingExperience.intermediate, reason: BreakReason.injury);
    expect(injury.startWeightPct, travel.startWeightPct - 10);
  });

  test('وزن البداية لا ينزل تحت 40%', () {
    final e = estimateDetraining(
        weeksOff: 52, experience: TrainingExperience.beginner, reason: BreakReason.injury);
    expect(e.startWeightPct, greaterThanOrEqualTo(40));
  });
}
