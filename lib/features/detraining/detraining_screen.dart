import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/motion.dart';
import '../../l10n/app_localizations.dart';
import '../../models/detraining.dart';
import '../../theme/app_theme.dart';

class DetrainingScreen extends StatefulWidget {
  const DetrainingScreen({super.key});

  @override
  State<DetrainingScreen> createState() => _DetrainingScreenState();
}

class _DetrainingScreenState extends State<DetrainingScreen> {
  double _weeks = 4;
  TrainingExperience _exp = TrainingExperience.intermediate;
  BreakReason _reason = BreakReason.travel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final est = estimateDetraining(
      weeksOff: _weeks.round(),
      experience: _exp,
      reason: _reason,
    );

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Row(children: [
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary)),
              Expanded(
                child: Text(loc.comebackTitle,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: c.textPrimary)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(loc.comebackSub, style: TextStyle(fontSize: 13, color: c.textSecondary)),
            const SizedBox(height: 22),

            Row(children: [
              Text(loc.weeksOffQ, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.textPrimary)),
              const Spacer(),
              Text('${_weeks.round()} ${loc.weeksUnit}',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.accent)),
            ]),
            Slider(
              value: _weeks, min: 1, max: 52, divisions: 51,
              activeColor: c.accent, inactiveColor: c.track,
              onChanged: (v) => setState(() => _weeks = v),
            ),
            const SizedBox(height: 10),

            Text(loc.experienceQ, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.textPrimary)),
            const SizedBox(height: 10),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final e in TrainingExperience.values)
                _chip(c, loc.experienceLabel(e), _exp == e, () => setState(() => _exp = e)),
            ]),
            const SizedBox(height: 18),

            Text(loc.reasonQ, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.textPrimary)),
            const SizedBox(height: 10),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final r in BreakReason.values)
                _chip(c, loc.reasonLabel(r), _reason == r, () => setState(() => _reason = r)),
            ]),
            const SizedBox(height: 24),

            // النتيجة
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _loss(c, loc.strengthLoss, est.strengthLossPct, c.macroProtein),
                    _loss(c, loc.muscleLoss, est.muscleLossPct, c.accent2),
                    _loss(c, loc.cardioLoss, est.cardioLossPct, c.macroCarbs),
                  ]),
                  const SizedBox(height: 18),
                  Divider(color: c.border, height: 1),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(loc.startAtLabel, style: TextStyle(fontSize: 13, color: c.textSecondary)),
                        const SizedBox(height: 4),
                        Text('${est.startWeightPct}%',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: c.accent)),
                        Text(loc.ofPrevious, style: TextStyle(fontSize: 11, color: c.textTertiary)),
                      ]),
                    ),
                    Container(width: 1, height: 48, color: c.border),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(loc.recoveryTime, style: TextStyle(fontSize: 13, color: c.textSecondary)),
                        const SizedBox(height: 4),
                        Text('${est.recoveryWeeks} ${loc.weeksUnit}',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: c.accent2)),
                      ]),
                    ),
                  ]),
                ],
              ),
            ).animate(key: ValueKey('${est.strengthLossPct}-${est.startWeightPct}')).fadeIn(duration: 300.ms),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline_rounded, size: 18, color: c.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(loc.detrainingDisclaimer,
                      style: TextStyle(fontSize: 12, height: 1.6, color: c.textSecondary)),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loss(c, String label, int pct, Color color) => Expanded(
        child: Column(children: [
          Text('−$pct%',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: c.textSecondary)),
        ]),
      );

  Widget _chip(c, String label, bool selected, VoidCallback onTap) => GestureDetector(
        onTap: () {
          Haptics.select();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? c.accent.withOpacity(0.14) : c.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? c.accent : c.border, width: selected ? 2 : 1),
          ),
          child: Text(label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: selected ? c.accent : c.textPrimary)),
        ),
      );
}
