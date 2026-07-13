import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';

/// شاشة مبدئية للتبويبات اللي بنبنيها لاحقاً (المساعد/الخريطة/التحديات).
class PlaceholderScreen extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const PlaceholderScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: c.surface,
                shape: BoxShape.circle,
                border: Border.all(color: c.border),
              ),
              child: Icon(icon, size: 40, color: c.accent),
            ).animate(onPlay: (ctrl) => ctrl.repeat(reverse: true)).scaleXY(
                begin: 1, end: 1.06, duration: 1400.ms, curve: Curves.easeInOut),
            const SizedBox(height: 20),
            Text(title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: c.textPrimary)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: c.textSecondary)),
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }
}
