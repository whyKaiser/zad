import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/meal.dart';
import '../../../theme/app_theme.dart';

class MacroRing extends StatelessWidget {
  final int current;
  final int target;
  final Color color;
  final String label;

  const MacroRing({
    super.key,
    required this.current,
    required this.target,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final loc = AppLocalizations.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CustomPaint(
                painter: _ArcPainter(
                  progress: progress * t,
                  track: c.track,
                  color: color,
                ),
                child: Center(
                  child: Text(
                    '${(current * t).round()}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(fontSize: 11, color: c.textSecondary)),
            Text('/ $target ${loc.grams}',
                style: TextStyle(fontSize: 10, color: c.textTertiary)),
          ],
        );
      },
    );
  }
}

class MacroRingsRow extends StatelessWidget {
  final Macros consumed;
  final Macros target;

  const MacroRingsRow({
    super.key,
    required this.consumed,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        MacroRing(
          current: consumed.protein,
          target: target.protein,
          color: c.macroProtein,
          label: loc.protein,
        ),
        MacroRing(
          current: consumed.carbs,
          target: target.carbs,
          color: c.macroCarbs,
          label: loc.carbs,
        ),
        MacroRing(
          current: consumed.fat,
          target: target.fat,
          color: c.macroFat,
          label: loc.fat,
        ),
      ],
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color track;
  final Color color;

  _ArcPainter({required this.progress, required this.track, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 5;
    const stroke = 5.0;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.color != color;
}
