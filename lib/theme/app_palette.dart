import 'package:flutter/material.dart';

/// نظام الألوان الدلالي (tokens) — تُستعمل في كل الواجهات بدل الألوان الثابتة.
/// كل بالِتة هي نسخة من [AppColors]. التبديل بينها يتمايل بسلاسة لأن [lerp] معرّفة.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color accent;
  final Color onAccent;
  final Color accent2;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color track;
  final Color border;
  final Color macroProtein;
  final Color macroCarbs;
  final Color macroFat;

  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.accent,
    required this.onAccent,
    required this.accent2,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.track,
    required this.border,
    required this.macroProtein,
    required this.macroCarbs,
    required this.macroFat,
  });

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? accent,
    Color? onAccent,
    Color? accent2,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? track,
    Color? border,
    Color? macroProtein,
    Color? macroCarbs,
    Color? macroFat,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accent2: accent2 ?? this.accent2,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      track: track ?? this.track,
      border: border ?? this.border,
      macroProtein: macroProtein ?? this.macroProtein,
      macroCarbs: macroCarbs ?? this.macroCarbs,
      macroFat: macroFat ?? this.macroFat,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accent2: Color.lerp(accent2, other.accent2, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      track: Color.lerp(track, other.track, t)!,
      border: Color.lerp(border, other.border, t)!,
      macroProtein: Color.lerp(macroProtein, other.macroProtein, t)!,
      macroCarbs: Color.lerp(macroCarbs, other.macroCarbs, t)!,
      macroFat: Color.lerp(macroFat, other.macroFat, t)!,
    );
  }
}

/// الثيمات الأربعة المتاحة للمستخدم.
enum ZadPalette { energy, luxe, clean, gulf }

extension ZadPaletteInfo on ZadPalette {
  // ملاحظة: تسميات الثيمات صارت في AppLocalizations.paletteLabel (عربي/إنجليزي).
  Brightness get brightness => switch (this) {
        ZadPalette.energy || ZadPalette.luxe => Brightness.dark,
        ZadPalette.clean || ZadPalette.gulf => Brightness.light,
      };

  AppColors get colors => switch (this) {
        ZadPalette.energy => _energy,
        ZadPalette.luxe => _luxe,
        ZadPalette.clean => _clean,
        ZadPalette.gulf => _gulf,
      };
}

const AppColors _energy = AppColors(
  background: Color(0xFF14161A),
  surface: Color(0xFF1E2128),
  surfaceVariant: Color(0xFF242A33),
  accent: Color(0xFFC6FF3A),
  onAccent: Color(0xFF14161A),
  accent2: Color(0xFFFF5B4A),
  textPrimary: Color(0xFFF5F7FA),
  textSecondary: Color(0xFF8A93A0),
  textTertiary: Color(0xFF5F6772),
  track: Color(0xFF1E2128),
  border: Color(0xFF2A2E36),
  macroProtein: Color(0xFFC6FF3A),
  macroCarbs: Color(0xFFFFC24B),
  macroFat: Color(0xFFFF5B4A),
);

const AppColors _luxe = AppColors(
  background: Color(0xFF0C0C0E),
  surface: Color(0xFF18171A),
  surfaceVariant: Color(0xFF201E22),
  accent: Color(0xFFD4AF37),
  onAccent: Color(0xFF0C0C0E),
  accent2: Color(0xFFE8C36B),
  textPrimary: Color(0xFFF2EFE8),
  textSecondary: Color(0xFF9A917E),
  textTertiary: Color(0xFF6A6253),
  track: Color(0xFF18171A),
  border: Color(0xFF2A2620),
  macroProtein: Color(0xFFD4AF37),
  macroCarbs: Color(0xFFE8C36B),
  macroFat: Color(0xFFC9A24B),
);

const AppColors _clean = AppColors(
  background: Color(0xFFFFFFFF),
  surface: Color(0xFFF4F7FB),
  surfaceVariant: Color(0xFFEDF1F7),
  accent: Color(0xFF2F80ED),
  onAccent: Color(0xFFFFFFFF),
  accent2: Color(0xFF1D9E75),
  textPrimary: Color(0xFF1A2230),
  textSecondary: Color(0xFF5A6573),
  textTertiary: Color(0xFF97A1B0),
  track: Color(0xFFEDF1F7),
  border: Color(0xFFE2E8F0),
  macroProtein: Color(0xFF1D9E75),
  macroCarbs: Color(0xFF2F80ED),
  macroFat: Color(0xFFF59E0B),
);

const AppColors _gulf = AppColors(
  background: Color(0xFFF4EDE0),
  surface: Color(0xFFFBF6EC),
  surfaceVariant: Color(0xFFEFE7D7),
  accent: Color(0xFF1B5E3F),
  onAccent: Color(0xFFF4EDE0),
  accent2: Color(0xFFC36A3C),
  textPrimary: Color(0xFF2A2417),
  textSecondary: Color(0xFF6E6450),
  textTertiary: Color(0xFF9C9176),
  track: Color(0xFFE4D9C5),
  border: Color(0xFFE0D5C2),
  macroProtein: Color(0xFF1B5E3F),
  macroCarbs: Color(0xFFC9A24B),
  macroFat: Color(0xFFC36A3C),
);
