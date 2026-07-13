import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';

/// حلقة السعرات: القوس يتعبّى والرقم يعدّ تصاعدياً عند الظهور.
class CalorieRing extends StatelessWidget {
  final int remaining;
  final int consumed;
  final int goal;
  final double size;

  const CalorieRing({
    super.key,
    required this.remaining,
    required this.consumed,
    required this.goal,
    this.size = 180,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final progress = goal > 0 ? (consumed / goal).clamp(0.0, 1.0) : 0.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(
              progress: progress * t,
              track: c.track,
              accent: c.accent,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (remaining * t).round().toString(),
                    style: TextStyle(
                      fontSize: size * 0.2,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).caloriesLeft,
                    style: TextStyle(fontSize: size * 0.075, color: c.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color track;
  final Color accent;

  _RingPainter({required this.progress, required this.track, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 9;
    final stroke = size.width * 0.06;

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, trackPaint);

    final accentPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.accent != accent || old.track != track;
}
