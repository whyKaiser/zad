import 'package:flutter/material.dart';

import '../models/challenge.dart';

List<Challenge> buildChallenges({
  required int streakDays,
  required int waterCups,
  required bool underGoalToday,
}) {
  return [
    Challenge(
      id: 'streak7',
      titleAr: 'التزم 7 أيام متتالية',
      titleEn: 'Keep a 7-day streak',
      current: streakDays.clamp(0, 7),
      target: 7,
      points: 50,
      icon: Icons.local_fire_department_rounded,
    ),
    Challenge(
      id: 'water8',
      titleAr: 'اشرب 8 أكواب ماء اليوم',
      titleEn: 'Drink 8 cups of water today',
      current: waterCups.clamp(0, 8),
      target: 8,
      points: 20,
      icon: Icons.water_drop_rounded,
    ),
    Challenge(
      id: 'log5',
      titleAr: 'سجّل وجباتك 5 أيام',
      titleEn: 'Log your meals for 5 days',
      current: streakDays.clamp(0, 5),
      target: 5,
      points: 30,
      icon: Icons.edit_note_rounded,
    ),
    Challenge(
      id: 'undergoal3',
      titleAr: 'ابقَ تحت هدفك 3 أيام',
      titleEn: 'Stay under your goal 3 days',
      current: underGoalToday ? 1 : 0,
      target: 3,
      points: 40,
      icon: Icons.trending_down_rounded,
    ),
  ];
}

const List<LeaderboardEntry> kLeaderboard = [
  LeaderboardEntry(rank: 1, name: 'سعد', points: 1240),
  LeaderboardEntry(rank: 2, name: 'نورة', points: 1100),
  LeaderboardEntry(rank: 3, name: 'خالد', points: 870),
  LeaderboardEntry(rank: 4, name: 'ريم', points: 760),
  LeaderboardEntry(rank: 5, name: 'فهد', points: 640),
];
