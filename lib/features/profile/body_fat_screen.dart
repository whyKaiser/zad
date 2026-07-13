import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/profile_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';

class BodyFatScreen extends StatefulWidget {
  const BodyFatScreen({super.key});

  @override
  State<BodyFatScreen> createState() => _BodyFatScreenState();
}

class _BodyFatScreenState extends State<BodyFatScreen> {
  final _neck = TextEditingController();
  final _waist = TextEditingController();
  final _hip = TextEditingController(); // للإناث فقط
  double? _result;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileController>().profile;
    if (profile != null) {
      _neck.text = '38';
      _waist.text = profile.weightKg > 0
          ? (profile.weightKg * 0.5).round().toString()
          : '85';
      _hip.text = '95';
    }
  }

  @override
  void dispose() {
    _neck.dispose(); _waist.dispose(); _hip.dispose();
    super.dispose();
  }

  double? _calculate(UserProfile? profile) {
    if (profile == null) return null;
    final h = profile.heightCm;
    final neck = double.tryParse(_neck.text);
    final waist = double.tryParse(_waist.text);
    if (neck == null || waist == null || h <= 0) return null;

    if (profile.gender == Gender.male) {
      if (waist <= neck) return null; // لوغاريتم قيمة سالبة = NaN
      // US Navy formula — male
      final val = 495 / (1.0324 - 0.19077 * math.log(waist - neck) / math.ln10 + 0.15456 * math.log(h) / math.ln10) - 450;
      if (val.isNaN || val.isInfinite) return null;
      return val.clamp(3.0, 60.0);
    } else {
      final hip = double.tryParse(_hip.text);
      if (hip == null) return null;
      if (waist + hip <= neck) return null;
      // US Navy formula — female
      final val = 495 / (1.29579 - 0.35004 * math.log(waist + hip - neck) / math.ln10 + 0.22100 * math.log(h) / math.ln10) - 450;
      if (val.isNaN || val.isInfinite) return null;
      return val.clamp(10.0, 60.0);
    }
  }

  String _category(double bf, Gender g) {
    if (g == Gender.male) {
      if (bf < 6) return 'رياضي محترف / Essential';
      if (bf < 14) return 'رياضي / Athletic';
      if (bf < 18) return 'لياقة / Fitness';
      if (bf < 25) return 'متوسط / Average';
      return 'سمنة / Obese';
    } else {
      if (bf < 14) return 'رياضية محترفة / Essential';
      if (bf < 21) return 'رياضية / Athletic';
      if (bf < 25) return 'لياقة / Fitness';
      if (bf < 32) return 'متوسط / Average';
      return 'سمنة / Obese';
    }
  }

  Color _color(double bf, Gender g, c) {
    final isHigh = g == Gender.male ? bf >= 25 : bf >= 32;
    final isLow = g == Gender.male ? bf < 6 : bf < 14;
    if (isHigh) return c.macroFat as Color;
    if (isLow) return c.macroCarbs as Color;
    return c.accent as Color;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final profile = context.watch<ProfileController>().profile;
    final isFemale = profile?.gender == Gender.female;

    _result = _calculate(profile);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Row(children: [
              IconButton(onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary)),
              Text(loc.isAr ? 'نسبة الدهون (Navy)' : 'Body Fat % (Navy)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: c.textPrimary)),
            ]),
            const SizedBox(height: 20),

            if (_result != null) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: c.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: c.border),
                ),
                child: Column(children: [
                  Text('${_result!.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800,
                          color: _color(_result!, profile!.gender, c))),
                  const SizedBox(height: 8),
                  Text(_category(_result!, profile.gender),
                      style: TextStyle(fontSize: 14, color: c.textSecondary)),
                  const SizedBox(height: 16),
                  _FatBar(value: _result! / 60, color: _color(_result!, profile.gender, c), c: c),
                ]),
              ),
              const SizedBox(height: 20),
            ],

            _Field(label: loc.isAr ? 'محيط الرقبة (سم)' : 'Neck (cm)', ctrl: _neck,
                onChanged: (_) => setState(() {})),
            const SizedBox(height: 12),
            _Field(label: loc.isAr ? 'محيط الخصر (سم)' : 'Waist (cm)', ctrl: _waist,
                onChanged: (_) => setState(() {})),
            if (isFemale) ...[
              const SizedBox(height: 12),
              _Field(label: loc.isAr ? 'محيط الأرداف (سم)' : 'Hip (cm)', ctrl: _hip,
                  onChanged: (_) => setState(() {})),
            ],
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.surfaceVariant, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.border),
              ),
              child: Text(
                loc.isAr
                    ? 'معادلة US Navy — تقريبية. أدق قياس عبر DEXA أو BodPod.'
                    : 'US Navy formula — approximate. Most accurate via DEXA or BodPod.',
                style: TextStyle(fontSize: 12, color: c.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final ValueChanged<String> onChanged;
  const _Field({required this.label, required this.ctrl, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 13, color: c.textSecondary)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        onChanged: onChanged,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
        style: TextStyle(color: c.textPrimary),
        decoration: InputDecoration(
          filled: true, fillColor: c.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.accent)),
        ),
      ),
    ]);
  }
}

class _FatBar extends StatelessWidget {
  final double value;
  final Color color;
  final dynamic c;
  const _FatBar({required this.value, required this.color, required this.c});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        backgroundColor: c.track,
        valueColor: AlwaysStoppedAnimation(color),
        minHeight: 10,
      ),
    );
  }
}
