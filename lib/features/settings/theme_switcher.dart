import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/motion.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/locale_controller.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';

/// ورقة سفلية: اختيار الثيم (4 بالِتات) + اللغة.
void showThemeSwitcher(BuildContext context) {
  final c = context.colors;
  showModalBottomSheet(
    context: context,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final theme = context.watch<ThemeController>();
    final locale = context.watch<LocaleController>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: c.textTertiary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Text(loc.appearance,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: c.textPrimary)),
            const SizedBox(height: 14),
            ...ZadPalette.values.map((p) => _PaletteTile(
                  palette: p,
                  label: loc.paletteLabel(p),
                  selected: theme.palette == p,
                  onTap: () {
                    Haptics.select();
                    theme.setPalette(p);
                  },
                )),
            const SizedBox(height: 20),
            Text(loc.language,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: c.textPrimary)),
            const SizedBox(height: 14),
            Row(
              children: [
                _LangChip(
                  label: loc.arabic,
                  selected: locale.isAr,
                  onTap: () {
                    Haptics.select();
                    locale.setLocale(const Locale('ar'));
                  },
                ),
                const SizedBox(width: 12),
                _LangChip(
                  label: loc.english,
                  selected: !locale.isAr,
                  onTap: () {
                    Haptics.select();
                    locale.setLocale(const Locale('en'));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaletteTile extends StatelessWidget {
  final ZadPalette palette;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PaletteTile({
    required this.palette,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pc = palette.colors;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? c.accent : c.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            _Swatch(colors: [pc.background, pc.accent, pc.accent2]),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.textPrimary)),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: c.accent, size: 22),
          ],
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? c.accent.withOpacity(0.12) : c.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? c.accent : c.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: selected ? c.accent : c.textPrimary,
              )),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final List<Color> colors;
  const _Swatch({required this.colors});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 32,
      child: Row(
        children: [
          for (var i = 0; i < colors.length; i++)
            Expanded(
              child: Container(
                margin: EdgeInsetsDirectional.only(end: i == colors.length - 1 ? 0 : 3),
                decoration: BoxDecoration(
                  color: colors[i],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.black.withOpacity(0.08)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
