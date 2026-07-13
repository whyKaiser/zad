import 'package:flutter/foundation.dart';

enum MealType { breakfast, lunch, dinner, snack }

/// عناصر غذائية كبرى (ماكروز) بالجرام.
@immutable
class Macros {
  final int protein;
  final int carbs;
  final int fat;

  const Macros({this.protein = 0, this.carbs = 0, this.fat = 0});

  Macros operator +(Macros o) =>
      Macros(protein: protein + o.protein, carbs: carbs + o.carbs, fat: fat + o.fat);
}

/// وجبة مسجّلة.
@immutable
class Meal {
  final String id;
  final String name;
  final int calories;
  final Macros macros;
  final DateTime time;
  final MealType type;

  const Meal({
    required this.id,
    required this.name,
    required this.calories,
    required this.macros,
    required this.time,
    this.type = MealType.snack,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'calories': calories,
        'protein': macros.protein,
        'carbs': macros.carbs,
        'fat': macros.fat,
        'time': time.toIso8601String(),
        'type': type.name,
      };

  factory Meal.fromJson(Map<String, dynamic> j) => Meal(
        id: j['id'] as String,
        name: j['name'] as String,
        calories: (j['calories'] as num).round(),
        macros: Macros(
          protein: (j['protein'] as num? ?? 0).round(),
          carbs: (j['carbs'] as num? ?? 0).round(),
          fat: (j['fat'] as num? ?? 0).round(),
        ),
        time: DateTime.parse(j['time'] as String),
        type: MealType.values.firstWhere(
          (e) => e.name == (j['type'] as String? ?? 'snack'),
          orElse: () => MealType.snack,
        ),
      );
}

/// هدف المستخدم اليومي.
@immutable
class DailyGoal {
  final int calories;
  final Macros macros;

  const DailyGoal({required this.calories, required this.macros});
}
