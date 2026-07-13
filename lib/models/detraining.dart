// نموذج تقدير تراجع الأداء بعد الانقطاع — مسنود بأبحاث detraining.
// المصادر: strongerbyscience, sci-fit, compedgept, دراسات MSSE.
// كل القيم تقديرية وتُعرض مع تنويه.

enum TrainingExperience { beginner, intermediate, advanced }

enum BreakReason { travel, exams, injury, other }

class DetrainingEstimate {
  final int strengthLossPct;
  final int muscleLossPct;
  final int cardioLossPct;
  final int startWeightPct; // % من الوزن السابق للبدء
  final int recoveryWeeks;

  const DetrainingEstimate({
    required this.strengthLossPct,
    required this.muscleLossPct,
    required this.cardioLossPct,
    required this.startWeightPct,
    required this.recoveryWeeks,
  });
}

DetrainingEstimate estimateDetraining({
  required int weeksOff,
  required TrainingExperience experience,
  required BreakReason reason,
}) {
  // القوة: فترة سماح ثم فقد أسبوعي، حسب الخبرة (المتقدّم يصمد أطول).
  final graceStrength = switch (experience) {
    TrainingExperience.advanced => 4,
    TrainingExperience.intermediate => 3,
    TrainingExperience.beginner => 1,
  };
  final strengthPerWeek = switch (experience) {
    TrainingExperience.advanced => 1.5,
    TrainingExperience.intermediate => 2.0,
    TrainingExperience.beginner => 3.0,
  };
  final strengthCap = switch (experience) {
    TrainingExperience.advanced => 20.0,
    TrainingExperience.intermediate => 25.0,
    TrainingExperience.beginner => 30.0,
  };
  final strength =
      (((weeksOff - graceStrength).clamp(0, 999)) * strengthPerWeek).clamp(0.0, strengthCap);

  // العضلات: سماح أسبوعين ثم ~1%/أسبوع (1.5 للمبتدئ).
  const graceMuscle = 2;
  final musclePerWeek = experience == TrainingExperience.beginner ? 1.5 : 1.0;
  final muscleCap = experience == TrainingExperience.beginner ? 25.0 : 18.0;
  final muscle =
      (((weeksOff - graceMuscle).clamp(0, 999)) * musclePerWeek).clamp(0.0, muscleCap);

  // اللياقة الهوائية: أسرع، أقل اعتماداً على الخبرة.
  final cardio = (((weeksOff - 1).clamp(0, 999)) * 2.3).clamp(0.0, 40.0);

  // وزن البداية: متحفّظ بسبب تأقلم الأوتار البطيء.
  var start = (100 - strength - 15).round();
  if (reason == BreakReason.injury) start -= 10;
  start = start.clamp(40, 90);

  // العودة للمستوى (ذاكرة العضل = أسرع من البناء الأول).
  final recovery = (weeksOff * 0.8).round().clamp(3, 12);

  return DetrainingEstimate(
    strengthLossPct: strength.round(),
    muscleLossPct: muscle.round(),
    cardioLossPct: cardio.round(),
    startWeightPct: start,
    recoveryWeeks: recovery,
  );
}
