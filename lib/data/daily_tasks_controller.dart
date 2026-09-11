import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/dates.dart';
import '../models/meal.dart';
import 'diary_repository.dart';
import 'points_controller.dart';
import 'water_controller.dart';
import 'weight_controller.dart';

enum DailyTaskType { logBreakfast, logLunch, logDinner, waterGoal, stayUnderGoal, logWeight, logAllMeals }

class DailyTask {
  final DailyTaskType type;
  final String titleAr;
  final String titleEn;
  final int points;
  final IconData icon;
  final int current;
  final int target;

  const DailyTask({
    required this.type,
    required this.titleAr,
    required this.titleEn,
    required this.points,
    required this.icon,
    required this.current,
    required this.target,
  });

  bool get isDone => current >= target;
  double get progress => (current / target).clamp(0.0, 1.0);
}

class DailyTasksController extends ChangeNotifier {
  static const _key = 'zad_tasks_awarded';

  final DiaryRepository _diary;
  final WaterController _water;
  final WeightController _weight;
  final PointsController _points;

  final Set<String> _awardedToday = {};
  String _todayKey = '';
  bool _awardsLoaded = false;
  bool _disposed = false;

  DailyTasksController({
    required DiaryRepository diary,
    required WaterController water,
    required WeightController weight,
    required PointsController points,
  })  : _diary = diary,
        _water = water,
        _weight = weight,
        _points = points {
    _loadAwarded();
  }

  List<DailyTask> get tasks => _buildTasks();

  /// هل مصادر البيانات نفسها؟ يمنع إعادة بناء المتحكّم بلا داعٍ من ProxyProvider.
  bool usesSameSources(DiaryRepository diary) => identical(_diary, diary);

  /// المهام تخصّ اليوم فقط — تصفّح يوم سابق لا يمنح نقاطاً.
  bool get _viewingToday => isToday(_diary.selectedDate);

  List<DailyTask> _buildTasks() {
    final today = DateTime.now();
    final meals = _diary.todayMeals;
    final goalCal = _diary.goal.calories;
    final consumed = _diary.consumedCalories;
    final waterCups = _water.cups;
    final hasWeightToday = _weight.entries.any((e) =>
        e.date.year == today.year &&
        e.date.month == today.month &&
        e.date.day == today.day);

    final hasBreakfast = meals.any((m) => m.type == MealType.breakfast);
    final hasLunch = meals.any((m) => m.type == MealType.lunch);
    final hasDinner = meals.any((m) => m.type == MealType.dinner);
    final underGoal = consumed > 0 && consumed <= goalCal;

    return [
      DailyTask(
        type: DailyTaskType.logBreakfast,
        titleAr: 'سجّل الفطور',
        titleEn: 'Log breakfast',
        points: 10,
        icon: Icons.wb_sunny_outlined,
        current: hasBreakfast ? 1 : 0,
        target: 1,
      ),
      DailyTask(
        type: DailyTaskType.logLunch,
        titleAr: 'سجّل الغداء',
        titleEn: 'Log lunch',
        points: 10,
        icon: Icons.restaurant_outlined,
        current: hasLunch ? 1 : 0,
        target: 1,
      ),
      DailyTask(
        type: DailyTaskType.logDinner,
        titleAr: 'سجّل العشاء',
        titleEn: 'Log dinner',
        points: 10,
        icon: Icons.nights_stay_outlined,
        current: hasDinner ? 1 : 0,
        target: 1,
      ),
      DailyTask(
        type: DailyTaskType.waterGoal,
        titleAr: 'اشرب 8 أكواب ماء',
        titleEn: 'Drink 8 cups of water',
        points: 20,
        icon: Icons.water_drop_outlined,
        current: waterCups,
        target: 8,
      ),
      DailyTask(
        type: DailyTaskType.stayUnderGoal,
        titleAr: 'ابقَ تحت هدفك اليومي',
        titleEn: 'Stay under your daily goal',
        points: 30,
        icon: Icons.trending_down_rounded,
        current: underGoal ? 1 : 0,
        target: 1,
      ),
      DailyTask(
        type: DailyTaskType.logWeight,
        titleAr: 'سجّل وزنك اليوم',
        titleEn: 'Log your weight today',
        points: 15,
        icon: Icons.monitor_weight_outlined,
        current: hasWeightToday ? 1 : 0,
        target: 1,
      ),
      DailyTask(
        type: DailyTaskType.logAllMeals,
        titleAr: 'سجّل الوجبات الثلاث',
        titleEn: 'Log all 3 meals',
        points: 25,
        icon: Icons.check_circle_outline_rounded,
        current: [hasBreakfast, hasLunch, hasDinner].where((b) => b).length,
        target: 3,
      ),
    ];
  }

  void checkAndAward() {
    if (!_awardsLoaded) return;
    // تصفّح يوم سابق يعرض مهامه لكنه لا يمنح نقاطاً — يمنع تكديس النقاط.
    if (!_viewingToday) return;

    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    if (_todayKey != todayKey) {
      _awardedToday.clear();
      _todayKey = todayKey;
    }

    var awarded = false;
    for (final task in tasks) {
      if (task.isDone && !_awardedToday.contains(task.type.name)) {
        _awardedToday.add(task.type.name);
        _points.addPoints(task.points, task.type.name);
        awarded = true;
      }
    }
    if (awarded) {
      _saveAwarded(); // كتابة واحدة بدل واحدة لكل مهمة
      _notifyAfterBuild();
    }
  }

  /// `checkAndAward` يُستدعى من ProxyProvider أثناء البناء —
  /// الإشعار المباشر يرمي "setState during build".
  void _notifyAfterBuild() {
    if (_disposed) return;
    SchedulerBinding? binding;
    try {
      binding = SchedulerBinding.instance;
    } catch (_) {
      binding = null; // بلا binding (اختبار وحدة) — الإشعار المباشر آمن
    }
    final phase = binding?.schedulerPhase;
    if (binding != null &&
        (phase == SchedulerPhase.persistentCallbacks ||
            phase == SchedulerPhase.midFrameMicrotasks)) {
      binding.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  Future<void> _loadAwarded() async {
    final today = DateTime.now();
    _todayKey = '${today.year}-${today.month}-${today.day}';
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        if (map['key'] == _todayKey) {
          _awardedToday.addAll((map['awarded'] as List).cast<String>());
        }
      }
    } catch (e) {
      // سجلّ تالف: نبدأ يوماً نظيفاً بدل تعطيل المهام للأبد.
      debugPrint('DailyTasks load error: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_key);
      } catch (_) {}
    }
    _awardsLoaded = true;
    _notifyAfterBuild();
  }

  Future<void> _saveAwarded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, jsonEncode({'key': _todayKey, 'awarded': _awardedToday.toList()}));
    } catch (e) {
      debugPrint('DailyTasks save error: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
