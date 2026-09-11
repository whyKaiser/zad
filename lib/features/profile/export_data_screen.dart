import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/dates.dart';
import '../../core/motion.dart';
import '../../data/activity_controller.dart';
import '../../data/diary_repository.dart';
import '../../data/measurements_controller.dart';
import '../../data/weight_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/meal.dart';
import '../../services/data_export_service.dart';
import '../../theme/app_theme.dart';

/// تصدير بيانات المستخدم كـ CSV — بياناته ملكه، يقدر يأخذها متى شاء.
class ExportDataScreen extends StatefulWidget {
  const ExportDataScreen({super.key});

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

enum _ExportKind { meals, dailyTotals, weight, measurements, activity }

class _ExportDataScreenState extends State<ExportDataScreen> {
  _ExportKind? _busy;
  int _days = 90;

  Future<Map<String, List<Meal>>> _collectMeals() async {
    final repo = context.read<DiaryRepository>();
    final today = DateTime.now();
    final days = List.generate(_days, (i) => today.subtract(Duration(days: i)));
    final lists = await Future.wait(days.map(repo.getMealsForDay));
    final out = <String, List<Meal>>{};
    for (var i = 0; i < days.length; i++) {
      if (lists[i].isNotEmpty) out[dayKey(days[i])] = lists[i];
    }
    return out;
  }

  Future<String> _buildCsv(_ExportKind kind) async {
    switch (kind) {
      case _ExportKind.meals:
        return DataExportService.mealsCsv(await _collectMeals());
      case _ExportKind.dailyTotals:
        return DataExportService.dailyTotalsCsv(await _collectMeals());
      case _ExportKind.weight:
        return DataExportService.weightCsv(context.read<WeightController>().entries);
      case _ExportKind.measurements:
        return DataExportService.measurementsCsv(
            context.read<MeasurementsController>().entries);
      case _ExportKind.activity:
        return DataExportService.activityCsv(
            context.read<ActivityController>().entries);
    }
  }

  String _fileName(_ExportKind kind) {
    final stamp = dayKey(DateTime.now());
    return switch (kind) {
      _ExportKind.meals => 'zad-meals-$stamp.csv',
      _ExportKind.dailyTotals => 'zad-daily-$stamp.csv',
      _ExportKind.weight => 'zad-weight-$stamp.csv',
      _ExportKind.measurements => 'zad-measurements-$stamp.csv',
      _ExportKind.activity => 'zad-activity-$stamp.csv',
    };
  }

  Future<void> _export(_ExportKind kind) async {
    if (_busy != null) return;
    setState(() => _busy = kind);
    final loc = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final csv = await _buildCsv(kind);
      // ترويسة فقط = لا بيانات بعد
      if (csv.split('\n').length <= 1) {
        messenger.showSnackBar(SnackBar(
          content: Text(loc.isAr ? 'ما فيه بيانات لتصديرها بعد' : 'Nothing to export yet'),
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }

      if (kIsWeb) {
        // الويب: لا نظام ملفات — ننسخ للحافظة بدل فشل صامت.
        await Clipboard.setData(ClipboardData(text: csv));
        messenger.showSnackBar(SnackBar(
          content: Text(loc.isAr ? 'نُسخت البيانات للحافظة' : 'Copied to clipboard'),
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${_fileName(kind)}');
      await file.writeAsString(csv, flush: true);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: loc.isAr ? 'بيانات زاد' : 'Zad data export',
      );
    } catch (e) {
      debugPrint('export error: $e');
      messenger.showSnackBar(SnackBar(
        content: Text(loc.isAr ? 'تعذّر التصدير، حاول مجدداً' : 'Export failed, try again'),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
              ),
              Text(loc.isAr ? 'تصدير بياناتك' : 'Export your data',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600, color: c.textPrimary)),
            ]),
            const SizedBox(height: 6),
            Text(
              loc.isAr
                  ? 'بياناتك ملكك. صدّرها كملف CSV يفتح في Excel أو Google Sheets.'
                  : 'Your data is yours. Export it as CSV for Excel or Google Sheets.',
              style: TextStyle(fontSize: 13, height: 1.7, color: c.textSecondary),
            ),
            const SizedBox(height: 20),

            // مدى التصدير للوجبات
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(loc.isAr ? 'مدى يوميات الطعام' : 'Food diary range',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, children: [
                  for (final d in [30, 90, 365])
                    GestureDetector(
                      onTap: () {
                        Haptics.select();
                        setState(() => _days = d);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _days == d ? c.accent.withOpacity(0.14) : c.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _days == d ? c.accent : c.border,
                              width: _days == d ? 1.5 : 1),
                        ),
                        child: Text(
                          loc.isAr ? '$d يوم' : '$d days',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _days == d ? c.accent : c.textSecondary),
                        ),
                      ),
                    ),
                ]),
              ]),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 18),

            _tile(c, loc, _ExportKind.meals, Icons.restaurant_menu_rounded,
                loc.isAr ? 'يوميات الطعام' : 'Food diary',
                loc.isAr ? 'صف لكل صنف سجّلته' : 'One row per logged item'),
            _tile(c, loc, _ExportKind.dailyTotals, Icons.summarize_rounded,
                loc.isAr ? 'ملخّص يومي' : 'Daily totals',
                loc.isAr ? 'مجاميع كل يوم' : 'Totals per day'),
            _tile(c, loc, _ExportKind.weight, Icons.monitor_weight_outlined,
                loc.isAr ? 'سجل الوزن' : 'Weight log',
                loc.isAr ? 'كل تسجيلات وزنك' : 'All your weigh-ins'),
            _tile(c, loc, _ExportKind.measurements, Icons.straighten_rounded,
                loc.isAr ? 'قياسات الجسم' : 'Body measurements',
                loc.isAr ? 'صدر وخصر وذراع وغيرها' : 'Chest, waist, arm and more'),
            _tile(c, loc, _ExportKind.activity, Icons.directions_run_rounded,
                loc.isAr ? 'سجل النشاط' : 'Activity log',
                loc.isAr ? 'تمارينك والسعرات المحروقة' : 'Workouts and calories burned'),

            const SizedBox(height: 14),
            Text(
              loc.isAr
                  ? 'التصدير يتم على جهازك — لا يُرفع شيء لأي خادم.'
                  : 'Export happens on your device — nothing is uploaded anywhere.',
              style: TextStyle(fontSize: 11, height: 1.6, color: c.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(dynamic c, AppLocalizations loc, _ExportKind kind, IconData icon,
          String title, String subtitle) =>
      GestureDetector(
        onTap: () => _export(kind),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border),
          ),
          child: Row(children: [
            Icon(icon, size: 22, color: c.accent),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500, color: c.textPrimary)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: c.textSecondary)),
              ]),
            ),
            if (_busy == kind)
              SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: c.accent))
            else
              Icon(Icons.ios_share_rounded, size: 20, color: c.textTertiary),
          ]),
        ),
      );
}
