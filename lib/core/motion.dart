import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// تمرير مطّاطي على كل المنصّات — إحساس iOS الأساسي.
class ZadScrollBehavior extends MaterialScrollBehavior {
  const ZadScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}

/// انتقال صفحات ناعم (انزلاق + تلاشي) بدل القفز الافتراضي.
class ZadPageRoute<T> extends PageRouteBuilder<T> {
  ZadPageRoute({required Widget page})
      : super(
          transitionDuration: const Duration(milliseconds: 380),
          reverseTransitionDuration: const Duration(milliseconds: 320),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

/// اهتزاز لمسي خفيف موحّد.
abstract class Haptics {
  static void light() => HapticFeedback.lightImpact();
  static void select() => HapticFeedback.selectionClick();
}
