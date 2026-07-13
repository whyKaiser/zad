import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// شريط ماكرو واحد — يتمدّد بسلاسة عند الظهور.
class MacroBar extends StatelessWidget {
  final String label;
  final int current;
  final int target;
  final Color color;

  const MacroBar({
    super.key,
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ratio = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: c.textSecondary)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 6, color: c.track),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: ratio),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => FractionallySizedBox(
                    widthFactor: v,
                    child: Container(height: 6, color: color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(children: [
              TextSpan(
                text: '$current',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.textPrimary),
              ),
              TextSpan(
                text: ' / $target',
                style: TextStyle(fontSize: 12, color: c.textTertiary),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
