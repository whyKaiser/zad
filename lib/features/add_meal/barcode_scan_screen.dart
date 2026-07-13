import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/motion.dart';
import '../../data/diary_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/meal.dart';
import '../../services/open_food_facts_service.dart';
import '../../theme/app_theme.dart';

class BarcodeScanScreen extends StatefulWidget {
  final MealType mealType;
  const BarcodeScanScreen({super.key, required this.mealType});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  final _ctrl = MobileScannerController();
  final _off = OpenFoodFactsService();
  bool _scanning = true;
  bool _loading = false;
  String? _error;

  Future<void> _onBarcode(String code) async {
    if (!_scanning) return;
    setState(() { _scanning = false; _loading = true; _error = null; });
    _ctrl.stop();

    final results = await _off.searchByBarcode(code);
    if (!mounted) return;

    if (results == null) {
      setState(() { _loading = false; _error = 'ما وُجد المنتج في قاعدة البيانات'; _scanning = false; });
      return;
    }

    final repo = context.read<DiaryRepository>();
    final loc = AppLocalizations.of(context);
    setState(() => _loading = false);

    if (!mounted) return;
    final sheetColor = context.colors.surface;
    await showModalBottomSheet(
      context: context,
      backgroundColor: sheetColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => _BarcodeResultSheet(
        result: results,
        mealType: widget.mealType,
        loc: loc, c: context.colors,
        onAdd: (grams) {
          final factor = grams / 100.0;
          repo.addMeal(Meal(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            name: results.name,
            calories: (results.calories * factor).round(),
            macros: Macros(
              protein: (results.macros.protein * factor).round(),
              carbs: (results.macros.carbs * factor).round(),
              fat: (results.macros.fat * factor).round(),
            ),
            time: DateTime.now(),
            type: widget.mealType,
          ));
          Haptics.light();
          Navigator.pop(sheetCtx);
          Navigator.pop(context);
        },
      ),
    );
    if (mounted) setState(() { _scanning = true; _ctrl.start(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _ctrl,
            onDetect: (capture) {
              final barcode = capture.barcodes.firstOrNull;
              if (barcode?.rawValue != null) _onBarcode(barcode!.rawValue!);
            },
          ),
          // overlay
          Positioned.fill(child: CustomPaint(painter: _ScanOverlay())),
          // top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
                Text(loc.isAr ? 'مسح الباركود' : 'Scan Barcode',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                const Spacer(),
                IconButton(
                  onPressed: () => _ctrl.toggleTorch(),
                  icon: const Icon(Icons.flashlight_on_rounded, color: Colors.white),
                ),
              ]),
            ),
          ),
          // bottom status
          Positioned(
            bottom: 60, left: 0, right: 0,
            child: Column(children: [
              if (_loading)
                const CircularProgressIndicator(color: Colors.white),
              if (_error != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(14)),
                  child: Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 14), textAlign: TextAlign.center),
                ),
              if (!_loading && _error != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() { _error = null; _scanning = true; _ctrl.start(); }),
                  child: const Text('حاول مجدداً', style: TextStyle(color: Colors.white)),
                ),
              ],
              if (!_loading && _error == null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    loc.isAr ? 'وجّه الكاميرا نحو الباركود' : 'Point camera at barcode',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _BarcodeResultSheet extends StatefulWidget {
  final OFFResult result;
  final MealType mealType;
  final AppLocalizations loc;
  final dynamic c;
  final ValueChanged<int> onAdd;
  const _BarcodeResultSheet({required this.result, required this.mealType, required this.loc, required this.c, required this.onAdd});

  @override
  State<_BarcodeResultSheet> createState() => _BarcodeResultSheetState();
}

class _BarcodeResultSheetState extends State<_BarcodeResultSheet> {
  double _grams = 100;

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final loc = widget.loc;
    final cal = (widget.result.calories * _grams / 100).round();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(color: c.textTertiary, borderRadius: BorderRadius.circular(4)))),
          Text(widget.result.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.textPrimary),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _MacroChip(label: loc.isAr ? 'سعرات' : 'Cal', value: cal.toString(), c: c, highlight: true),
            _MacroChip(label: loc.isAr ? 'بروتين' : 'P', value: '${(widget.result.macros.protein * _grams / 100).round()}g', c: c),
            _MacroChip(label: loc.isAr ? 'كارب' : 'C', value: '${(widget.result.macros.carbs * _grams / 100).round()}g', c: c),
            _MacroChip(label: loc.isAr ? 'دهون' : 'F', value: '${(widget.result.macros.fat * _grams / 100).round()}g', c: c),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Text('${_grams.round()} ${loc.grams}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary)),
          ]),
          Slider(value: _grams, min: 10, max: 500, divisions: 49,
              activeColor: c.accent, inactiveColor: c.track,
              onChanged: (v) => setState(() => _grams = v)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => widget.onAdd(_grams.round()),
              style: TextButton.styleFrom(
                backgroundColor: c.accent, foregroundColor: c.onAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(loc.save, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label, value;
  final dynamic c;
  final bool highlight;
  const _MacroChip({required this.label, required this.value, required this.c, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
          color: highlight ? c.accent : c.textPrimary)),
      Text(label, style: TextStyle(fontSize: 11, color: c.textSecondary)),
    ]);
  }
}

class _ScanOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dim = size.shortestSide * 0.65;
    final l = (size.width - dim) / 2;
    final t = (size.height - dim) / 2;
    final rect = Rect.fromLTWH(l, t, dim, dim);

    final paint = Paint()..color = Colors.black.withOpacity(0.55);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    canvas.drawRect(rect, Paint()..blendMode = BlendMode.clear);

    final corner = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round;
    const len = 24.0;
    // top-left
    canvas.drawLine(Offset(l, t + len), Offset(l, t), corner);
    canvas.drawLine(Offset(l, t), Offset(l + len, t), corner);
    // top-right
    canvas.drawLine(Offset(l + dim - len, t), Offset(l + dim, t), corner);
    canvas.drawLine(Offset(l + dim, t), Offset(l + dim, t + len), corner);
    // bottom-left
    canvas.drawLine(Offset(l, t + dim - len), Offset(l, t + dim), corner);
    canvas.drawLine(Offset(l, t + dim), Offset(l + len, t + dim), corner);
    // bottom-right
    canvas.drawLine(Offset(l + dim - len, t + dim), Offset(l + dim, t + dim), corner);
    canvas.drawLine(Offset(l + dim, t + dim), Offset(l + dim, t + dim - len), corner);
  }

  @override
  bool shouldRepaint(_) => false;
}
