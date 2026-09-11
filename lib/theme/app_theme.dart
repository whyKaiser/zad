import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_palette.dart';

/// يبني [ThemeData] كاملة من بالِتة [AppColors].
/// كل الألوان تُشتق من الـ tokens — صفر ألوان ثابتة في الواجهات.
ThemeData buildTheme(ZadPalette palette) {
  final c = palette.colors;
  final b = palette.brightness;

  final baseTextTheme = b == Brightness.dark
      ? ThemeData.dark().textTheme
      : ThemeData.light().textTheme;

  return ThemeData(
    useMaterial3: true,
    brightness: b,
    scaffoldBackgroundColor: c.background,
    canvasColor: c.background,
    primaryColor: c.accent,
    splashColor: c.accent.withOpacity(0.08),
    highlightColor: c.accent.withOpacity(0.04),
    colorScheme: ColorScheme(
      brightness: b,
      primary: c.accent,
      onPrimary: c.onAccent,
      secondary: c.accent2,
      onSecondary: c.onAccent,
      surface: c.surface,
      onSurface: c.textPrimary,
      error: const Color(0xFFE24B4A),
      onError: Colors.white,
    ),
    textTheme: GoogleFonts.tajawalTextTheme(baseTextTheme).apply(
      bodyColor: c.textPrimary,
      displayColor: c.textPrimary,
    ),
    iconTheme: IconThemeData(color: c.textPrimary),

    // السلايدر الافتراضي يُظهر فقاعة قيمة وعلامات تقسيم تزاحم الإصبع،
    // والقيمة معروضة أصلاً فوق كل سلايدر في التطبيق. نُبقي المسار نظيفاً
    // ونكبّر الإبهام قليلاً ليقع تحت الإصبع بلا تردّد.
    sliderTheme: SliderThemeData(
      trackHeight: 4,
      activeTrackColor: c.accent,
      inactiveTrackColor: c.track,
      thumbColor: c.accent,
      overlayColor: c.accent.withOpacity(0.12),
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
      // بلا علامات تقسيم ولا فقاعة — القيمة ظاهرة في العنوان.
      tickMarkShape: SliderTickMarkShape.noTickMark,
      showValueIndicator: ShowValueIndicator.never,
      trackShape: const RoundedRectSliderTrackShape(),
    ),

    extensions: [c],
  );
}

/// اختصار: `context.colors.accent` بدل `Theme.of(context).extension<AppColors>()!`.
extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
