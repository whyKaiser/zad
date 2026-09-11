import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// بروتوكول صيام متقطّع. الساعات = مدة الصيام، والباقي نافذة الأكل.
@immutable
class FastingPlan {
  final String id;
  final int fastHours;
  final String nameAr;
  final String nameEn;
  final String descAr;
  final String descEn;

  const FastingPlan({
    required this.id,
    required this.fastHours,
    required this.nameAr,
    required this.nameEn,
    required this.descAr,
    required this.descEn,
  });

  int get eatHours => 24 - fastHours;
  String name({required bool isAr}) => isAr ? nameAr : nameEn;
  String desc({required bool isAr}) => isAr ? descAr : descEn;
}

const kFastingPlans = <FastingPlan>[
  FastingPlan(
    id: '12_12', fastHours: 12,
    nameAr: '12:12', nameEn: '12:12',
    descAr: 'للمبتدئ — صيام ١٢ ساعة ونافذة أكل ١٢',
    descEn: 'Beginner — 12h fast, 12h eating window',
  ),
  FastingPlan(
    id: '14_10', fastHours: 14,
    nameAr: '14:10', nameEn: '14:10',
    descAr: 'متوسط — صيام ١٤ ساعة ونافذة أكل ١٠',
    descEn: 'Moderate — 14h fast, 10h eating window',
  ),
  FastingPlan(
    id: '16_8', fastHours: 16,
    nameAr: '16:8', nameEn: '16:8',
    descAr: 'الأشهر — صيام ١٦ ساعة ونافذة أكل ٨',
    descEn: 'Most common — 16h fast, 8h eating window',
  ),
  FastingPlan(
    id: '18_6', fastHours: 18,
    nameAr: '18:6', nameEn: '18:6',
    descAr: 'متقدّم — صيام ١٨ ساعة ونافذة أكل ٦',
    descEn: 'Advanced — 18h fast, 6h eating window',
  ),
];

FastingPlan? fastingPlanById(String id) {
  for (final p in kFastingPlans) {
    if (p.id == id) return p;
  }
  return null;
}

/// جلسة صيام منتهية — للسجل والستريك.
@immutable
class FastSession {
  final DateTime start;
  final DateTime end;
  final int targetHours;

  const FastSession({required this.start, required this.end, required this.targetHours});

  Duration get duration => end.difference(start);
  bool get reachedGoal => duration.inMinutes >= targetHours * 60;

  Map<String, dynamic> toMap() => {
        's': start.toIso8601String(),
        'e': end.toIso8601String(),
        'h': targetHours,
      };

  factory FastSession.fromMap(Map<String, dynamic> m) => FastSession(
        start: DateTime.parse(m['s'] as String),
        end: DateTime.parse(m['e'] as String),
        targetHours: (m['h'] as num).round(),
      );
}

/// يدير مؤقّت الصيام المتقطّع وسجلّه. يبقى دقيقاً بعد إغلاق التطبيق
/// لأن وقت البدء نفسه هو ما يُحفظ (لا عدّاد يعمل بالخلفية).
class FastingController extends ChangeNotifier {
  static const _startKey = 'zad_fast_start';
  static const _planKey = 'zad_fast_plan';
  static const _logKey = 'zad_fast_log';
  static const _maxLog = 60;

  DateTime? _startedAt;
  FastingPlan _plan = kFastingPlans[2]; // 16:8 افتراضياً
  final List<FastSession> _log = [];

  DateTime? get startedAt => _startedAt;
  FastingPlan get plan => _plan;
  bool get isFasting => _startedAt != null;
  List<FastSession> get log => List.unmodifiable(_log);

  /// المدة المنقضية منذ بدء الصيام.
  Duration get elapsed =>
      _startedAt == null ? Duration.zero : DateTime.now().difference(_startedAt!);

  /// نسبة الإنجاز من الهدف (0..1).
  double get progress {
    if (_startedAt == null) return 0;
    final target = _plan.fastHours * 60;
    if (target <= 0) return 0;
    return (elapsed.inMinutes / target).clamp(0.0, 1.0);
  }

  /// المتبقّي للهدف — صفر إن تجاوزه.
  Duration get remaining {
    if (_startedAt == null) return Duration.zero;
    final left = Duration(hours: _plan.fastHours) - elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  bool get reachedGoal => isFasting && elapsed.inMinutes >= _plan.fastHours * 60;

  /// متى تُفتح نافذة الأكل.
  DateTime? get endsAt =>
      _startedAt?.add(Duration(hours: _plan.fastHours));

  /// عدد الجلسات التي بلغت هدفها خلال آخر ٧ أيام.
  int get goalsThisWeek {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _log.where((s) => s.end.isAfter(weekAgo) && s.reachedGoal).length;
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final planId = prefs.getString(_planKey);
      if (planId != null) _plan = fastingPlanById(planId) ?? _plan;

      final start = prefs.getString(_startKey);
      if (start != null) {
        final parsed = DateTime.tryParse(start);
        // جلسة تتجاوز ٤٨ ساعة غالباً منسيّة — نتجاهلها بدل عرض رقم مضلّل.
        if (parsed != null &&
            DateTime.now().difference(parsed) < const Duration(hours: 48)) {
          _startedAt = parsed;
        } else {
          await prefs.remove(_startKey);
        }
      }

      final raw = prefs.getString(_logKey);
      if (raw != null) {
        final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        _log
          ..clear()
          ..addAll(list.map(FastSession.fromMap));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('FastingController load error: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_logKey);
        await prefs.remove(_startKey);
      } catch (_) {}
    }
  }

  Future<void> setPlan(FastingPlan p) async {
    _plan = p;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_planKey, p.id);
    } catch (e) {
      debugPrint('FastingController setPlan error: $e');
    }
  }

  Future<void> start() async {
    if (isFasting) return;
    _startedAt = DateTime.now();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_startKey, _startedAt!.toIso8601String());
    } catch (e) {
      debugPrint('FastingController start error: $e');
    }
  }

  /// ينهي الجلسة ويسجّلها. يرجّع الجلسة المنتهية أو null إن لم تكن هناك جلسة.
  Future<FastSession?> stop() async {
    final start = _startedAt;
    if (start == null) return null;
    final session = FastSession(
      start: start,
      end: DateTime.now(),
      targetHours: _plan.fastHours,
    );
    _startedAt = null;
    // جلسة أقل من دقيقة = ضغطة خاطئة، لا تُسجَّل.
    if (session.duration.inMinutes >= 1) {
      _log.insert(0, session);
      while (_log.length > _maxLog) {
        _log.removeLast();
      }
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_startKey);
      await prefs.setString(_logKey, jsonEncode(_log.map((e) => e.toMap()).toList()));
    } catch (e) {
      debugPrint('FastingController stop error: $e');
    }
    return session;
  }
}
