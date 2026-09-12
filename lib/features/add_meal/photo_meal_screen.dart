import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/dates.dart';
import '../../core/motion.dart';
import '../../data/diary_repository.dart';
import '../../data/recent_foods_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/meal.dart';
import '../../services/ai_router.dart';
import '../../services/ai_service.dart';
import '../../theme/app_theme.dart';

/// تسجيل وجبة بالتصوير — يحلّل الصورة بموديل رؤية ويقدّر السعرات.
/// النتيجة تقديرية دائماً وتُوسم كذلك (سياسة القاعدة الموثّقة أولاً).
class PhotoMealScreen extends StatefulWidget {
  final MealType mealType;
  const PhotoMealScreen({super.key, required this.mealType});

  @override
  State<PhotoMealScreen> createState() => _PhotoMealScreenState();
}

class _PhotoMealScreenState extends State<PhotoMealScreen> {
  final _picker = ImagePicker();
  final _ai = AiRouter();

  Uint8List? _bytes;
  String? _path;
  bool _loading = false;
  String? _error;
  FoodEstimate? _result;
  double _portion = 1.0;

  @override
  void dispose() {
    _ai.close();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1024,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _path = picked.path;
        _result = null;
        _error = null;
        _portion = 1.0;
      });
      await _analyze();
    } catch (e) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).couldNotOpenImage);
      }
    }
  }

  Future<void> _analyze() async {
    final bytes = _bytes;
    if (bytes == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final est = await _ai.estimateFromImage(bytes);
      if (!mounted) return;
      setState(() { _result = est; _loading = false; });
      Haptics.light();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        final loc = AppLocalizations.of(context);
        _error = _ai.hasVision ? loc.photoAnalysisFailed : loc.visionNotEnabled;
      });
    }
  }

  void _save() {
    final r = _result;
    if (r == null) return;
    final repo = context.read<DiaryRepository>();
    final meal = Meal(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: r.name.isEmpty ? AppLocalizations.of(context).mealFromPhoto : r.name,
      calories: (r.calories * _portion).round(),
      macros: Macros(
        protein: (r.protein * _portion).round(),
        carbs: (r.carbs * _portion).round(),
        fat: (r.fat * _portion).round(),
      ),
      time: mealTimeFor(repo.selectedDate),
      type: widget.mealType,
    );
    repo.addMeal(meal);
    context.read<RecentFoodsController>().record(meal);
    Haptics.light();
    Navigator.pop(context);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(children: [
                IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
                ),
                Flexible(child: Text(loc.isAr ? 'صوّر وجبتك' : 'Snap your meal',
                    style: TextStyle(fontSize: 20, letterSpacing: 20 * -0.01, fontWeight: FontWeight.w600, color: c.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  // معاينة الصورة
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: c.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: c.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _bytes == null
                          ? Center(
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.photo_camera_outlined, size: 44, color: c.textTertiary),
                                const SizedBox(height: 10),
                                Text(loc.isAr ? 'صوّر الطبق أو اختر صورة' : 'Take a photo or pick one',
                                    style: TextStyle(fontSize: 13, color: c.textSecondary)),
                              ]),
                            )
                          : (kIsWeb || _path == null
                              ? Image.memory(_bytes!, fit: BoxFit.cover)
                              : Image.file(File(_path!), fit: BoxFit.cover)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // أزرار المصدر
                  Row(children: [
                    Expanded(child: _sourceBtn(c, Icons.photo_camera_rounded,
                        loc.isAr ? 'الكاميرا' : 'Camera', () => _pick(ImageSource.camera), true)),
                    const SizedBox(width: 10),
                    Expanded(child: _sourceBtn(c, Icons.photo_library_outlined,
                        loc.isAr ? 'المعرض' : 'Gallery', () => _pick(ImageSource.gallery), false)),
                  ]),
                  const SizedBox(height: 18),

                  if (_loading)
                    Column(children: [
                      CircularProgressIndicator(color: c.accent),
                      const SizedBox(height: 12),
                      Text(loc.isAr ? 'أحلّل الطبق…' : 'Analyzing…',
                          style: TextStyle(fontSize: 14, color: c.textSecondary)),
                    ]),

                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.border),
                      ),
                      child: Row(children: [
                        Icon(Icons.info_outline_rounded, size: 18, color: c.macroFat),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_error!,
                            style: TextStyle(fontSize: 13, color: c.textSecondary))),
                      ]),
                    ),

                  if (_result != null && !_loading) _resultCard(c, loc, _result!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sourceBtn(dynamic c, IconData icon, String label, VoidCallback onTap, bool primary) =>
      ZadTap(
        onTap: () { Haptics.select(); onTap(); },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: primary ? c.accent : c.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: primary ? c.accent : c.border),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18, color: primary ? c.onAccent : c.accent),
            const SizedBox(width: 8),
            Flexible(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: primary ? c.onAccent : c.accent), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
        ),
      );

  Widget _resultCard(dynamic c, AppLocalizations loc, FoodEstimate r) {
    final cal = (r.calories * _portion).round();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(r.name.isEmpty ? (loc.isAr ? 'وجبة' : 'Meal') : r.name,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.textPrimary))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: c.macroCarbs.withOpacity(0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(loc.approximate,
                style: TextStyle(fontSize: 11, letterSpacing: 11 * 0.01, fontWeight: FontWeight.w600, color: c.macroCarbs)),
          ),
        ]),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic,
            children: [
          Flexible(child: Text('$cal',
              style: TextStyle(fontSize: 34, letterSpacing: 34 * -0.025, fontWeight: FontWeight.w700, color: c.accent), maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 5),
          Flexible(child: Text(loc.calorieUnit, style: TextStyle(fontSize: 13, color: c.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _macroChip(c, loc.protein, (r.protein * _portion).round(), c.macroProtein),
          const SizedBox(width: 8),
          _macroChip(c, loc.carbs, (r.carbs * _portion).round(), c.macroCarbs),
          const SizedBox(width: 8),
          _macroChip(c, loc.fat, (r.fat * _portion).round(), c.macroFat),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Text(loc.isAr ? 'حجم الحصة' : 'Portion size',
              style: TextStyle(fontSize: 13, color: c.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Flexible(child: Text('×${_portion.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.accent), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        Slider(
          value: _portion, min: 0.25, max: 3.0, divisions: 11,
          activeColor: c.accent, inactiveColor: c.track,
          onChanged: (v) => setState(() => _portion = v),
        ),
        Text(loc.isAr
                ? 'راجع الرقم قبل الحفظ — التقدير من الصورة ليس دقيقاً كالقاعدة الموثّقة.'
                : 'Review before saving — photo estimates are less precise than the verified database.',
            style: TextStyle(fontSize: 11, letterSpacing: 11 * 0.01, height: 1.5, color: c.textTertiary)),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _save,
            style: TextButton.styleFrom(
              backgroundColor: c.accent, foregroundColor: c.onAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(loc.addToDiary,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, curve: Curves.easeOutCubic);
  }

  Widget _macroChip(dynamic c, String label, int value, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: [
            Text('$value', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: TextStyle(fontSize: 10, letterSpacing: 10 * 0.02, color: c.textSecondary)),
          ]),
        ),
      );
}
