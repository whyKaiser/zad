import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UnitController extends ChangeNotifier {
  bool _useKg = true;

  bool get useKg => _useKg;
  String get weightUnit => _useKg ? 'كجم' : 'رطل';
  String get weightUnitEn => _useKg ? 'kg' : 'lbs';

  double toDisplay(double kg) => _useKg ? kg : kg * 2.20462;
  double fromDisplay(double val) => _useKg ? val : val / 2.20462;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _useKg = p.getBool('use_kg') ?? true;
    notifyListeners();
  }

  Future<void> toggle() async {
    _useKg = !_useKg;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool('use_kg', _useKg);
  }
}
