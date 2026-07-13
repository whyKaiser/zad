import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeightEntry {
  final DateTime date;
  final double kg;
  const WeightEntry(this.date, this.kg);

  Map<String, dynamic> toMap() => {'d': date.toIso8601String(), 'kg': kg};
  factory WeightEntry.fromMap(Map<String, dynamic> m) =>
      WeightEntry(DateTime.parse(m['d'] as String), (m['kg'] as num).toDouble());
}

/// سجلّ الوزن عبر الزمن. يُحفظ محلياً.
class WeightController extends ChangeNotifier {
  static const _prefsKey = 'zad_weight_log';

  final List<WeightEntry> _entries = [];
  List<WeightEntry> get entries => List.unmodifiable(_entries);

  double? get latest => _entries.isEmpty ? null : _entries.last.kg;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _entries
        ..clear()
        ..addAll(list.map(WeightEntry.fromMap));
      _entries.sort((a, b) => a.date.compareTo(b.date));
      notifyListeners();
    }
  }

  Future<void> add(double kg) async {
    final clamped = kg.clamp(20.0, 300.0);
    _entries.add(WeightEntry(DateTime.now(), clamped));
    notifyListeners();
    await _persist();
  }

  Future<void> remove(WeightEntry entry) async {
    _entries.remove(entry);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_entries.map((e) => e.toMap()).toList()));
  }
}
