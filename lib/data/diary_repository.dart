import 'package:flutter/material.dart';

import '../models/meal.dart';

abstract class DiaryRepository extends ChangeNotifier {
  DailyGoal get goal;
  List<Meal> get todayMeals;
  int get streakDays;
  String get userName;
  DateTime get selectedDate;
  void selectDate(DateTime date);

  Macros get consumedMacros =>
      todayMeals.fold(const Macros(), (acc, m) => acc + m.macros);
  int get consumedCalories =>
      todayMeals.fold(0, (acc, m) => acc + m.calories);
  int get remainingCalories =>
      (goal.calories - consumedCalories).clamp(0, goal.calories);

  void addMeal(Meal meal);
  void removeMeal(Meal meal);
  Future<List<Meal>> getMealsForDay(DateTime date);
}

class MockDiaryRepository extends ChangeNotifier implements DiaryRepository {
  @override
  final String userName = 'عبدالله';

  @override
  final int streakDays = 12;

  @override
  final DailyGoal goal = const DailyGoal(
    calories: 2000,
    macros: Macros(protein: 150, carbs: 240, fat: 65),
  );

  DateTime _selectedDate = DateTime.now();

  @override
  DateTime get selectedDate => _selectedDate;

  @override
  void selectDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  final List<Meal> _allMeals = [
    Meal(
      id: '1',
      name: 'بيض مقلي وخبز',
      calories: 320,
      macros: const Macros(protein: 18, carbs: 28, fat: 14),
      time: DateTime.now().subtract(const Duration(hours: 5)),
      type: MealType.breakfast,
    ),
    Meal(
      id: '2',
      name: 'صدر دجاج مشوي وأرز',
      calories: 450,
      macros: const Macros(protein: 45, carbs: 40, fat: 6),
      time: DateTime.now().subtract(const Duration(hours: 2)),
      type: MealType.lunch,
    ),
    Meal(
      id: '3',
      name: 'تمر وحليب',
      calories: 180,
      macros: const Macros(protein: 6, carbs: 30, fat: 4),
      time: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      type: MealType.snack,
    ),
    Meal(
      id: '4',
      name: 'شاورما دجاج',
      calories: 520,
      macros: const Macros(protein: 38, carbs: 55, fat: 14),
      time: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
      type: MealType.dinner,
    ),
  ];

  @override
  List<Meal> get todayMeals {
    final d = _selectedDate;
    return List.unmodifiable(
      _allMeals.where((m) =>
          m.time.year == d.year &&
          m.time.month == d.month &&
          m.time.day == d.day),
    );
  }

  @override
  Macros get consumedMacros =>
      todayMeals.fold(const Macros(), (acc, m) => acc + m.macros);

  @override
  int get consumedCalories =>
      todayMeals.fold(0, (acc, m) => acc + m.calories);

  @override
  int get remainingCalories =>
      (goal.calories - consumedCalories).clamp(0, goal.calories);

  @override
  void addMeal(Meal meal) {
    _allMeals.add(meal);
    notifyListeners();
  }

  @override
  void removeMeal(Meal meal) {
    _allMeals.removeWhere((m) => m.id == meal.id);
    notifyListeners();
  }

  @override
  Future<List<Meal>> getMealsForDay(DateTime date) async {
    final d = DateTime(date.year, date.month, date.day);
    return _allMeals
        .where((m) =>
            m.time.year == d.year &&
            m.time.month == d.month &&
            m.time.day == d.day)
        .toList();
  }
}
