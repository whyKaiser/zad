enum MuscleGroup { chest, back, shoulders, arms, legs, core, cardio, fullBody }

class Exercise {
  final String id;
  final String nameAr;
  final String nameEn;
  final MuscleGroup muscle;
  final String descAr;
  final String descEn;
  final int sets;
  final int reps;

  const Exercise({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.muscle,
    required this.descAr,
    required this.descEn,
    this.sets = 3,
    this.reps = 12,
  });
}

extension MuscleGroupX on MuscleGroup {
  String get nameAr => switch (this) {
    MuscleGroup.chest => 'صدر',
    MuscleGroup.back => 'ظهر',
    MuscleGroup.shoulders => 'أكتاف',
    MuscleGroup.arms => 'أذرع',
    MuscleGroup.legs => 'أرجل',
    MuscleGroup.core => 'كور',
    MuscleGroup.cardio => 'كارديو',
    MuscleGroup.fullBody => 'جسم كامل',
  };

  String get nameEn => switch (this) {
    MuscleGroup.chest => 'Chest',
    MuscleGroup.back => 'Back',
    MuscleGroup.shoulders => 'Shoulders',
    MuscleGroup.arms => 'Arms',
    MuscleGroup.legs => 'Legs',
    MuscleGroup.core => 'Core',
    MuscleGroup.cardio => 'Cardio',
    MuscleGroup.fullBody => 'Full Body',
  };

  String get emoji => switch (this) {
    MuscleGroup.chest => '💪',
    MuscleGroup.back => '🔙',
    MuscleGroup.shoulders => '🏋️',
    MuscleGroup.arms => '💪',
    MuscleGroup.legs => '🦵',
    MuscleGroup.core => '🎯',
    MuscleGroup.cardio => '🏃',
    MuscleGroup.fullBody => '⚡',
  };
}
