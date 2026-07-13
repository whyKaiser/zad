import 'package:flutter/material.dart';

/// تحدّي بنقاط (بلا جوائز مالية — قرار مقفول).
@immutable
class Challenge {
  final String id;
  final String titleAr;
  final String titleEn;
  final int current;
  final int target;
  final int points;
  final IconData icon;

  const Challenge({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.current,
    required this.target,
    required this.points,
    required this.icon,
  });

  double get progress => target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
  bool get done => current >= target;
}

/// صف في لوحة الصدارة (الدوري).
@immutable
class LeaderboardEntry {
  final int rank;
  final String name;
  final int points;
  final bool isMe;

  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.points,
    this.isMe = false,
  });
}
