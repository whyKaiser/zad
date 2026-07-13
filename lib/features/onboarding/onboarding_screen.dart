import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/motion.dart';
import '../../data/profile_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _name = TextEditingController();
  Gender _gender = Gender.male;
  double _age = 25, _height = 170, _weight = 70;
  ActivityLevel _activity = ActivityLevel.moderate;
  GoalType _goal = GoalType.maintain;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  UserProfile get _draft => UserProfile(
        name: _name.text.trim().isEmpty ? '—' : _name.text.trim(),
        gender: _gender,
        age: _age.round(),
        heightCm: _height.round(),
        weightKg: _weight,
        activity: _activity,
        goal: _goal,
      );

  void _finish() {
    final loc = AppLocalizations.of(context);
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.enterName)));
      return;
    }
    Haptics.light();
    context.read<ProfileController>().save(_draft);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Text(loc.welcome,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: c.textPrimary)),
            const SizedBox(height: 6),
            Text(loc.onboardingSub, style: TextStyle(fontSize: 14, color: c.textSecondary)),
            const SizedBox(height: 26),

            _label(c, loc.nameQ),
            TextField(
              controller: _name,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: c.textPrimary),
              decoration: _fieldDeco(c, loc.namePlaceholder),
            ),
            const SizedBox(height: 22),

            _label(c, loc.genderQ),
            Row(children: [
              _chip(c, loc.male, _gender == Gender.male, () => setState(() => _gender = Gender.male)),
              const SizedBox(width: 10),
              _chip(c, loc.female, _gender == Gender.female, () => setState(() => _gender = Gender.female)),
            ]),
            const SizedBox(height: 22),

            _slider(c, '${loc.ageQ}: ${_age.round()}', _age, 15, 80, (v) => setState(() => _age = v)),
            _slider(c, '${loc.heightQ}: ${_height.round()}', _height, 140, 210, (v) => setState(() => _height = v)),
            _slider(c, '${loc.weightQ}: ${_weight.toStringAsFixed(1)}', _weight, 40, 160, (v) => setState(() => _weight = v)),
            const SizedBox(height: 14),

            _label(c, loc.activityQ),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final a in ActivityLevel.values)
                _chip(c, loc.activityLabel(a), _activity == a, () => setState(() => _activity = a)),
            ]),
            const SizedBox(height: 22),

            _label(c, loc.goalQ),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final g in GoalType.values)
                _chip(c, loc.goalLabel(g), _goal == g, () => setState(() => _goal = g)),
            ]),
            const SizedBox(height: 26),

            // معاينة حيّة للهدف
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: c.border),
              ),
              child: Row(
                children: [
                  Text(loc.yourTarget, style: TextStyle(fontSize: 14, color: c.textSecondary)),
                  const Spacer(),
                  Text('${_draft.targetCalories}',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: c.accent)),
                  const SizedBox(width: 4),
                  Text(loc.calorieUnit, style: TextStyle(fontSize: 13, color: c.textSecondary)),
                ],
              ),
            ).animate(target: 1).fadeIn(),
            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _finish,
                style: TextButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: c.onAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(loc.startApp,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(c, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.textPrimary)),
      );

  InputDecoration _fieldDeco(c, String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.textTertiary),
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.accent)),
      );

  Widget _chip(c, String label, bool selected, VoidCallback onTap) => GestureDetector(
        onTap: () {
          Haptics.select();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? c.accent.withOpacity(0.14) : c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? c.accent : c.border, width: selected ? 2 : 1),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: selected ? c.accent : c.textPrimary)),
        ),
      );

  Widget _slider(c, String label, double value, double min, double max, ValueChanged<double> onChanged) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.textPrimary)),
            Slider(
              value: value,
              min: min,
              max: max,
              activeColor: c.accent,
              inactiveColor: c.track,
              onChanged: onChanged,
            ),
          ],
        ),
      );
}
