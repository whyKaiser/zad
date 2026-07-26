import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// نشاط رياضي بقيمة MET معتمدة (Compendium of Physical Activities).
/// السعرات = MET × 3.5 × الوزن(كغ) ÷ 200 × الدقائق — المعادلة القياسية.
@immutable
class ActivityType {
  final String id;
  final String nameAr;
  final String nameEn;
  final double met;
  final IconData icon;

  const ActivityType({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.met,
    required this.icon,
  });

  int caloriesFor({required double weightKg, required int minutes}) =>
      (met * 3.5 * weightKg / 200 * minutes).round();
}

const kActivities = <ActivityType>[
  ActivityType(id: 'walk', nameAr: 'مشي معتدل', nameEn: 'Walking', met: 3.5, icon: Icons.directions_walk_rounded),
  ActivityType(id: 'walk_fast', nameAr: 'مشي سريع', nameEn: 'Brisk walking', met: 4.3, icon: Icons.directions_walk_rounded),
  ActivityType(id: 'run', nameAr: 'جري خفيف', nameEn: 'Jogging', met: 7.0, icon: Icons.directions_run_rounded),
  ActivityType(id: 'run_fast', nameAr: 'جري سريع', nameEn: 'Running', met: 11.0, icon: Icons.directions_run_rounded),
  ActivityType(id: 'weights', nameAr: 'حديد ومقاومة', nameEn: 'Weight training', met: 5.0, icon: Icons.fitness_center_rounded),
  ActivityType(id: 'hiit', nameAr: 'كارديو مكثّف', nameEn: 'HIIT', met: 8.0, icon: Icons.bolt_rounded),
  ActivityType(id: 'cycling', nameAr: 'دراجة', nameEn: 'Cycling', met: 7.5, icon: Icons.pedal_bike_rounded),
  ActivityType(id: 'swim', nameAr: 'سباحة', nameEn: 'Swimming', met: 8.0, icon: Icons.pool_rounded),
  ActivityType(id: 'football', nameAr: 'كرة قدم', nameEn: 'Football', met: 7.0, icon: Icons.sports_soccer_rounded),
  ActivityType(id: 'padel', nameAr: 'بادل وتنس', nameEn: 'Padel / Tennis', met: 7.3, icon: Icons.sports_tennis_rounded),
  ActivityType(id: 'jump_rope', nameAr: 'نط الحبل', nameEn: 'Jump rope', met: 12.0, icon: Icons.self_improvement_rounded),
  ActivityType(id: 'stairs', nameAr: 'صعود درج', nameEn: 'Stair climbing', met: 8.0, icon: Icons.stairs_rounded),
  ActivityType(id: 'yoga', nameAr: 'يوغا وإطالة', nameEn: 'Yoga / Stretching', met: 2.8, icon: Icons.self_improvement_rounded),
  ActivityType(id: 'housework', nameAr: 'أعمال منزلية', nameEn: 'Housework', met: 3.3, icon: Icons.cleaning_services_rounded),
];

ActivityType? activityById(String id) {
  for (final a in kActivities) {
    if (a.id == id) return a;
  }
  return null;
}

@immutable
class ActivityEntry {
  final String id;
  final String name;
  final int minutes;
  final int calories;
  final DateTime date;

  const ActivityEntry({
    required this.id,
    required this.name,
    required this.minutes,
    required this.calories,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'min': minutes,
        'cal': calories,
        'at': date.toIso8601String(),
      };

  factory ActivityEntry.fromMap(Map<String, dynamic> m) => ActivityEntry(
        id: m['id'] as String,
        name: m['name'] as String,
        minutes: (m['min'] as num).round(),
        calories: (m['cal'] as num).round(),
        date: DateTime.parse(m['at'] as String),
      );
}

/// يسجّل النشاط اليومي — السعرات المحروقة تُضاف لميزانية اليوم.
class ActivityController extends ChangeNotifier {
  static const _key = 'zad_activity_log';

  final List<ActivityEntry> _entries = [];

  List<ActivityEntry> get entries => List.unmodifiable(_entries);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<ActivityEntry> forDay(DateTime day) =>
      _entries.where((e) => _sameDay(e.date, day)).toList();

  /// إجمالي المحروق في يوم معيّن.
  int burnedOn(DateTime day) =>
      forDay(day).fold(0, (acc, e) => acc + e.calories);

  int get burnedToday => burnedOn(DateTime.now());

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _entries
        ..clear()
        ..addAll(list.map(ActivityEntry.fromMap));
      // نحتفظ بآخر 90 يوم فقط — يمنع تضخّم التخزين.
      final cutoff = DateTime.now().subtract(const Duration(days: 90));
      _entries.removeWhere((e) => e.date.isBefore(cutoff));
      notifyListeners();
    } catch (e) {
      debugPrint('ActivityController load error: $e');
    }
  }

  Future<void> add(ActivityEntry entry) async {
    _entries.add(entry);
    notifyListeners();
    await _persist();
  }

  Future<void> remove(ActivityEntry entry) async {
    _entries.removeWhere((e) => e.id == entry.id && e.date == entry.date);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(_entries.map((e) => e.toMap()).toList()));
    } catch (e) {
      debugPrint('ActivityController persist error: $e');
    }
  }
}
