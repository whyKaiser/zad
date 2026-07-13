import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/meal.dart';
import 'diary_repository.dart';

class FirestoreDiaryRepository extends ChangeNotifier implements DiaryRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId;
  final String _name;
  @override
  final DailyGoal goal;

  FirestoreDiaryRepository({
    required this.userId,
    required this.goal,
    String name = '',
  }) : _name = name {
    _listenToday();
    _loadStreak();
  }

  List<Meal> _meals = [];
  int _streak = 0;
  StreamSubscription<QuerySnapshot>? _sub;
  DateTime _selectedDate = DateTime.now();

  @override
  DateTime get selectedDate => _selectedDate;

  @override
  void selectDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    _listenToday();
    notifyListeners();
  }

  @override
  List<Meal> get todayMeals => List.unmodifiable(_meals);

  @override
  int get streakDays => _streak;

  @override
  String get userName => _name;

  @override
  Macros get consumedMacros =>
      _meals.fold(const Macros(), (acc, m) => acc + m.macros);

  @override
  int get consumedCalories => _meals.fold(0, (acc, m) => acc + m.calories);

  @override
  int get remainingCalories =>
      (goal.calories - consumedCalories).clamp(0, goal.calories);

  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String get _todayKey => _dayKey(_selectedDate);

  CollectionReference<Map<String, dynamic>> get _mealsCol => _db
      .collection('users')
      .doc(userId)
      .collection('diary')
      .doc(_todayKey)
      .collection('meals');

  void _listenToday() {
    _sub?.cancel();
    _sub = _mealsCol.orderBy('time').snapshots().listen((snap) {
      _meals = snap.docs.map((d) => Meal.fromJson(d.data())).toList();
      notifyListeners();
    });
  }

  Future<void> _loadStreak() async {
    int streak = 0;
    final today = DateTime.now();
    for (int i = 1; i <= 60; i++) {
      final day = today.subtract(Duration(days: i));
      final snap = await _db
          .collection('users')
          .doc(userId)
          .collection('diary')
          .doc(_dayKey(day))
          .collection('meals')
          .limit(1)
          .get();
      if (snap.docs.isEmpty) break;
      streak++;
    }
    _streak = streak;
    notifyListeners();
  }

  @override
  void addMeal(Meal meal) {
    _mealsCol.doc(meal.id).set(meal.toJson()).catchError(
        (Object e) => debugPrint('addMeal error: $e'));
  }

  @override
  void removeMeal(Meal meal) {
    _mealsCol.doc(meal.id).delete().catchError(
        (Object e) => debugPrint('removeMeal error: $e'));
  }

  @override
  Future<List<Meal>> getMealsForDay(DateTime date) async {
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('diary')
        .doc(_dayKey(date))
        .collection('meals')
        .orderBy('time')
        .get();
    return snap.docs.map((d) => Meal.fromJson(d.data())).toList();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
