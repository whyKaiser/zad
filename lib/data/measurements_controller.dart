import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BodyMeasurement {
  final DateTime date;
  final double? chest;   // صدر
  final double? waist;   // خصر
  final double? arm;     // ذراع
  final double? thigh;   // فخذ
  final double? hip;     // أرداف
  final double? neck;    // رقبة

  const BodyMeasurement({
    required this.date,
    this.chest,
    this.waist,
    this.arm,
    this.thigh,
    this.hip,
    this.neck,
  });

  Map<String, dynamic> toMap() => {
    'd': date.toIso8601String(),
    if (chest != null) 'chest': chest,
    if (waist != null) 'waist': waist,
    if (arm != null) 'arm': arm,
    if (thigh != null) 'thigh': thigh,
    if (hip != null) 'hip': hip,
    if (neck != null) 'neck': neck,
  };

  factory BodyMeasurement.fromMap(Map<String, dynamic> m) => BodyMeasurement(
    date: DateTime.parse(m['d'] as String),
    chest: (m['chest'] as num?)?.toDouble(),
    waist: (m['waist'] as num?)?.toDouble(),
    arm: (m['arm'] as num?)?.toDouble(),
    thigh: (m['thigh'] as num?)?.toDouble(),
    hip: (m['hip'] as num?)?.toDouble(),
    neck: (m['neck'] as num?)?.toDouble(),
  );
}

class MeasurementsController extends ChangeNotifier {
  static const _key = 'zad_measurements';
  final List<BodyMeasurement> _entries = [];

  List<BodyMeasurement> get entries => List.unmodifiable(_entries);
  BodyMeasurement? get latest => _entries.isEmpty ? null : _entries.last;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _entries
        ..clear()
        ..addAll(list.map(BodyMeasurement.fromMap));
      _entries.sort((a, b) => a.date.compareTo(b.date));
      notifyListeners();
    }
  }

  Future<void> add(BodyMeasurement m) async {
    _entries.add(m);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_entries.map((e) => e.toMap()).toList()));
  }
}
