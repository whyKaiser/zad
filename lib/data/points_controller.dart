import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PointEntry {
  final int amount;
  final String source;
  final DateTime date;

  const PointEntry({required this.amount, required this.source, required this.date});

  Map<String, dynamic> toMap() => {
    'amount': amount,
    'source': source,
    'date': date.toIso8601String(),
  };

  factory PointEntry.fromMap(Map<String, dynamic> m) => PointEntry(
    amount: m['amount'] as int,
    source: m['source'] as String,
    date: DateTime.parse(m['date'] as String),
  );
}

class PointsController extends ChangeNotifier {
  static const _key = 'zad_points';
  final List<PointEntry> _history = [];

  List<PointEntry> get history => List.unmodifiable(_history);

  int get total => _history.fold(0, (acc, e) => acc + e.amount);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _history
        ..clear()
        ..addAll(list.map(PointEntry.fromMap));
      notifyListeners();
    }
  }

  Future<void> addPoints(int amount, String source) async {
    _history.add(PointEntry(amount: amount, source: source, date: DateTime.now()));
    notifyListeners();
    await _persist();
  }

  int todayTotal() {
    final today = DateTime.now();
    return _history
        .where((e) =>
            e.date.year == today.year &&
            e.date.month == today.month &&
            e.date.day == today.day)
        .fold(0, (acc, e) => acc + e.amount);
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(_history.map((e) => e.toMap()).toList()));
    } catch (e) {
      debugPrint('PointsController persist error: $e');
    }
  }
}
