import 'dart:convert';

import 'meal.dart';

enum Gender { male, female }

enum ActivityLevel { sedentary, light, moderate, active }

enum GoalType { lose, maintain, gain }

extension ActivityFactor on ActivityLevel {
  double get factor => switch (this) {
        ActivityLevel.sedentary => 1.2,
        ActivityLevel.light => 1.375,
        ActivityLevel.moderate => 1.55,
        ActivityLevel.active => 1.725,
      };
}

extension GoalAdjust on GoalType {
  /// تعديل السعرات اليومي عن TDEE.
  int get calorieDelta => switch (this) {
        GoalType.lose => -500,
        GoalType.maintain => 0,
        GoalType.gain => 350,
      };
}

/// ملف المستخدم — يحسب الهدف اليومي بمعادلة Mifflin-St Jeor.
class UserProfile {
  final String name;
  final Gender gender;
  final int age;
  final int heightCm;
  final double weightKg;
  final ActivityLevel activity;
  final GoalType goal;

  const UserProfile({
    required this.name,
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.activity,
    required this.goal,
  });

  /// معدّل الأيض الأساسي (BMR) — Mifflin-St Jeor.
  double get bmr {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return gender == Gender.male ? base + 5 : base - 161;
  }

  /// إجمالي الطاقة اليومية حسب النشاط.
  double get tdee => bmr * activity.factor;

  /// هدف السعرات بعد تعديل الهدف. لا ينزل تحت حدّ آمن (1200).
  int get targetCalories => (tdee + goal.calorieDelta).round().clamp(1200, 6000);

  /// ماكروز الهدف: بروتين 1.8غ/كغ، دهون 25% سعرات، الباقي كارب.
  Macros get targetMacros {
    final protein = (1.8 * weightKg).round();
    final fat = (targetCalories * 0.25 / 9).round();
    final carbs = ((targetCalories - protein * 4 - fat * 9) / 4).round().clamp(0, 1000);
    return Macros(protein: protein, carbs: carbs, fat: fat);
  }

  double get bmi {
    final m = heightCm / 100.0;
    return weightKg / (m * m);
  }

  UserProfile copyWith({double? weightKg, GoalType? goal, ActivityLevel? activity}) => UserProfile(
        name: name,
        gender: gender,
        age: age,
        heightCm: heightCm,
        weightKg: weightKg ?? this.weightKg,
        activity: activity ?? this.activity,
        goal: goal ?? this.goal,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'gender': gender.name,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'activity': activity.name,
        'goal': goal.name,
      };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
        name: m['name'] as String,
        gender: Gender.values.byName(m['gender'] as String),
        age: m['age'] as int,
        heightCm: m['heightCm'] as int,
        weightKg: (m['weightKg'] as num).toDouble(),
        activity: ActivityLevel.values.byName(m['activity'] as String),
        goal: GoalType.values.byName(m['goal'] as String),
      );

  String toJson() => jsonEncode(toMap());
  factory UserProfile.fromJson(String s) =>
      UserProfile.fromMap(jsonDecode(s) as Map<String, dynamic>);
}
