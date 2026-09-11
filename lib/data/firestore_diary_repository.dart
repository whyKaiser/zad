import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/dates.dart';
import '../models/meal.dart';
import 'diary_repository.dart';

class FirestoreDiaryRepository extends DiaryRepository {
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
  bool _disposed = false;

  /// أي إشعار بعد dispose يرمي استثناء — كل النداءات غير المتزامنة تمر من هنا.
  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  DateTime get selectedDate => _selectedDate;

  bool get _viewingToday => isToday(_selectedDate);

  @override
  void selectDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    _meals = []; // لا نعرض وجبات اليوم السابق ريثما يصل اليوم الجديد
    _listenToday();
    _safeNotify();
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

  CollectionReference<Map<String, dynamic>> _colFor(DateTime day) => _db
      .collection('users')
      .doc(userId)
      .collection('diary')
      .doc(dayKey(day))
      .collection('meals');

  CollectionReference<Map<String, dynamic>> get _mealsCol => _colFor(_selectedDate);

  void _listenToday() {
    _sub?.cancel();
    _sub = _mealsCol.orderBy('time').snapshots().listen(
      (snap) {
        _meals = snap.docs
            .map((d) {
              try {
                return Meal.fromJson(d.data());
              } catch (e) {
                debugPrint('تخطّي وجبة تالفة ${d.id}: $e');
                return null;
              }
            })
            .whereType<Meal>()
            .toList();
        _safeNotify();
        if (_viewingToday) _refreshStreak();
      },
      onError: (Object e) {
        // انقطاع شبكة أو رفض قواعد — نبقي آخر نسخة ولا نُسقط التطبيق.
        debugPrint('diary listener error: $e');
      },
    );
  }

  /// يحسب الستريك من اليوم للخلف. اليوم يُحتسب إن كان فيه تسجيل،
  /// ولا يكسر السلسلة إن كان فارغاً (اليوم لم ينتهِ بعد).
  Future<void> _loadStreak() async {
    try {
      final today = DateTime.now();
      var streak = 0;
      for (var i = 0; i <= 60; i++) {
        if (_disposed) return;
        final day = today.subtract(Duration(days: i));
        final snap = await _colFor(day).limit(1).get();
        if (snap.docs.isEmpty) {
          if (i == 0) continue; // اليوم ما زال جارياً
          break;
        }
        streak++;
      }
      _streak = streak;
      _safeNotify();
    } catch (e) {
      debugPrint('loadStreak error: $e');
    }
  }

  DateTime? _lastStreakCalc;

  /// إعادة حساب مخفّفة — مرة كل دقيقة على الأكثر، تمنع عشرات القراءات
  /// مع كل تحديث لحظي من Firestore.
  void _refreshStreak() {
    final now = DateTime.now();
    if (_lastStreakCalc != null &&
        now.difference(_lastStreakCalc!) < const Duration(minutes: 1)) {
      return;
    }
    _lastStreakCalc = now;
    _loadStreak();
  }

  @override
  void addMeal(Meal meal) {
    _mealsCol
        .doc(meal.id)
        .set(meal.toJson())
        .catchError((Object e) => debugPrint('addMeal error: $e'));
  }

  @override
  void removeMeal(Meal meal) {
    _mealsCol
        .doc(meal.id)
        .delete()
        .catchError((Object e) => debugPrint('removeMeal error: $e'));
  }

  @override
  Future<List<Meal>> getMealsForDay(DateTime date) async {
    try {
      final snap = await _colFor(date).orderBy('time').get();
      return snap.docs
          .map((d) {
            try {
              return Meal.fromJson(d.data());
            } catch (_) {
              return null;
            }
          })
          .whereType<Meal>()
          .toList();
    } catch (e) {
      debugPrint('getMealsForDay error: $e');
      return const [];
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }
}
