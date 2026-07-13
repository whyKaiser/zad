import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

import '../../core/motion.dart';
import '../../data/measurements_controller.dart';
import '../../data/profile_controller.dart';
import '../../data/unit_controller.dart';
import '../../data/weight_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _logWeight(BuildContext context) {
    final c = context.colors;
    final profileCtrl = context.read<ProfileController>();
    final weightCtrl = context.read<WeightController>();
    final unitCtrl = context.read<UnitController>();
    final profile = profileCtrl.profile;
    final startKg = weightCtrl.latest ?? profile?.weightKg ?? 70;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => _LogWeightSheet(
        startKg: startKg,
        useKg: unitCtrl.useKg,
        onSave: (kg) async {
          await weightCtrl.add(kg);
          if (profile != null) {
            await profileCtrl.save(profile.copyWith(weightKg: kg));
          }
          Haptics.light();
          if (sheetContext.mounted) Navigator.pop(sheetContext);
        },
      ),
    );
  }

  void _logMeasurements(BuildContext context) {
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => _LogMeasurementsSheet(
        onSave: (m) async {
          await context.read<MeasurementsController>().add(m);
          Haptics.light();
          if (sheetContext.mounted) Navigator.pop(sheetContext);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final profile = context.watch<ProfileController>().profile;
    final weights = context.watch<WeightController>();
    final unit = context.watch<UnitController>();
    final measurements = context.watch<MeasurementsController>();
    final current = weights.latest ?? profile?.weightKg;
    final bmi = (current != null && profile != null)
        ? current / ((profile.heightCm / 100.0) * (profile.heightCm / 100.0))
        : null;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
                ),
                Text(loc.weightTracking,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: c.textPrimary)),
              ]),
            ),
            TabBar(
              controller: _tab,
              labelColor: c.accent,
              unselectedLabelColor: c.textSecondary,
              indicatorColor: c.accent,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [
                Tab(text: loc.isAr ? 'الوزن' : 'Weight'),
                Tab(text: loc.isAr ? 'القياسات' : 'Measurements'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  // ── وزن ──
                  _WeightTab(
                    weights: weights,
                    current: current,
                    bmi: bmi,
                    unit: unit,
                    loc: loc,
                    c: c,
                    onLog: () => _logWeight(context),
                  ),
                  // ── قياسات ──
                  _MeasurementsTab(
                    measurements: measurements,
                    loc: loc,
                    c: c,
                    onLog: () => _logMeasurements(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Weight Tab ───────────────────────────────────────────────────────────────

class _WeightTab extends StatelessWidget {
  final WeightController weights;
  final double? current;
  final double? bmi;
  final UnitController unit;
  final AppLocalizations loc;
  final dynamic c;
  final VoidCallback onLog;

  const _WeightTab({
    required this.weights, required this.current, required this.bmi,
    required this.unit, required this.loc, required this.c, required this.onLog,
  });

  @override
  Widget build(BuildContext context) {
    final dispVal = current != null ? unit.toDisplay(current!) : null;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Row(children: [
                Expanded(child: _metric(c, loc.currentWeight,
                    dispVal != null ? '${dispVal.toStringAsFixed(1)} ${unit.useKg ? loc.kg : loc.lbs}' : '—')),
                const SizedBox(width: 12),
                Expanded(child: _metric(c, loc.bmiLabel,
                    bmi != null ? '${bmi!.toStringAsFixed(1)} · ${loc.bmiCategory(bmi!)}' : '—')),
              ]),
              const SizedBox(height: 18),
              if (weights.entries.length >= 2)
                Container(
                  height: 140,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: c.border),
                  ),
                  child: CustomPaint(
                    painter: _Sparkline(
                      values: weights.entries.map((e) => unit.toDisplay(e.kg)).toList(),
                      color: c.accent, track: c.track,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              const SizedBox(height: 18),
              if (weights.entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: Text(loc.noWeightYet,
                      style: TextStyle(color: c.textSecondary, fontSize: 14))),
                )
              else
                ...weights.entries.reversed.map((e) => Dismissible(
                  key: ValueKey('${e.date.toIso8601String()}_${e.kg}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: AlignmentDirectional.centerEnd,
                    padding: const EdgeInsetsDirectional.only(end: 20),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                  ),
                  onDismissed: (_) {
                    Haptics.light();
                    context.read<WeightController>().remove(e);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: c.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.border),
                    ),
                    child: Row(children: [
                      Text(intl.DateFormat('d MMM').format(e.date),
                          style: TextStyle(fontSize: 14, color: c.textSecondary)),
                      const Spacer(),
                      Text('${unit.toDisplay(e.kg).toStringAsFixed(1)} ${unit.useKg ? loc.kg : loc.lbs}',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.textPrimary)),
                    ]),
                  ),
                )),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onLog,
              style: TextButton.styleFrom(
                backgroundColor: c.accent, foregroundColor: c.onAccent,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(loc.logWeight, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _metric(c, String label, String value) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 13, color: c.textSecondary)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.textPrimary)),
        ]),
      );
}

// ─── Measurements Tab ─────────────────────────────────────────────────────────

class _MeasurementsTab extends StatelessWidget {
  final MeasurementsController measurements;
  final AppLocalizations loc;
  final dynamic c;
  final VoidCallback onLog;

  const _MeasurementsTab({
    required this.measurements, required this.loc, required this.c, required this.onLog,
  });

  static const _fields = [
    ('chest', '💪', 'صدر', 'Chest'),
    ('waist', '⬜', 'خصر', 'Waist'),
    ('arm',   '💪', 'ذراع', 'Arm'),
    ('thigh', '🦵', 'فخذ', 'Thigh'),
    ('hip',   '⬛', 'أرداف', 'Hip'),
    ('neck',  '🔵', 'رقبة', 'Neck'),
  ];

  double? _val(BodyMeasurement m, String key) => switch (key) {
    'chest' => m.chest,
    'waist' => m.waist,
    'arm'   => m.arm,
    'thigh' => m.thigh,
    'hip'   => m.hip,
    'neck'  => m.neck,
    _       => null,
  };

  @override
  Widget build(BuildContext context) {
    final latest = measurements.latest;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              // latest summary card
              if (latest != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: c.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.isAr ? 'آخر قياس' : 'Latest',
                        style: TextStyle(fontSize: 13, color: c.textSecondary),
                      ),
                      Text(
                        intl.DateFormat('d MMM yyyy').format(latest.date),
                        style: TextStyle(fontSize: 12, color: c.textTertiary),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: _fields.map((f) {
                          final v = _val(latest, f.$1);
                          if (v == null) return const SizedBox.shrink();
                          return _MeasChip(
                            label: loc.isAr ? f.$3 : f.$4,
                            value: v,
                            c: c,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // history
              if (measurements.entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text(
                    loc.isAr ? 'ما فيه قياسات بعد' : 'No measurements yet',
                    style: TextStyle(color: c.textSecondary, fontSize: 14),
                  )),
                )
              else
                ...measurements.entries.reversed.map((m) => _MeasRow(
                  m: m, fields: _fields, valOf: _val, loc: loc, c: c,
                )),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onLog,
              style: TextButton.styleFrom(
                backgroundColor: c.accent, foregroundColor: c.onAccent,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                loc.isAr ? 'سجّل قياسات' : 'Log measurements',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MeasChip extends StatelessWidget {
  final String label;
  final double value;
  final dynamic c;
  const _MeasChip({required this.label, required this.value, required this.c});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(value.toStringAsFixed(1), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.accent)),
      Text(label, style: TextStyle(fontSize: 11, color: c.textSecondary)),
    ]);
  }
}

class _MeasRow extends StatelessWidget {
  final BodyMeasurement m;
  final List<(String, String, String, String)> fields;
  final double? Function(BodyMeasurement, String) valOf;
  final AppLocalizations loc;
  final dynamic c;
  const _MeasRow({required this.m, required this.fields, required this.valOf, required this.loc, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(intl.DateFormat('d MMM yyyy').format(m.date),
            style: TextStyle(fontSize: 12, color: c.textTertiary)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 16, runSpacing: 8,
          children: fields.map((f) {
            final v = valOf(m, f.$1);
            if (v == null) return const SizedBox.shrink();
            return Row(mainAxisSize: MainAxisSize.min, children: [
              Text(loc.isAr ? f.$3 : f.$4,
                  style: TextStyle(fontSize: 13, color: c.textSecondary)),
              const SizedBox(width: 4),
              Text('${v.toStringAsFixed(1)} سم',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary)),
            ]);
          }).toList(),
        ),
      ]),
    );
  }
}

// ─── Log Weight Sheet ─────────────────────────────────────────────────────────

class _LogWeightSheet extends StatefulWidget {
  final double startKg;
  final bool useKg;
  final ValueChanged<double> onSave;
  const _LogWeightSheet({required this.startKg, required this.useKg, required this.onSave});

  @override
  State<_LogWeightSheet> createState() => _LogWeightSheetState();
}

class _LogWeightSheetState extends State<_LogWeightSheet> {
  late double _kg;

  @override
  void initState() {
    super.initState();
    _kg = widget.startKg;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final disp = widget.useKg ? _kg : _kg * 2.20462;
    final unit = widget.useKg ? loc.kg : loc.lbs;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(
            width: 40, height: 4, margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(color: c.textTertiary, borderRadius: BorderRadius.circular(4)),
          )),
          Row(children: [
            Text(loc.logWeight, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.textPrimary)),
            const Spacer(),
            Text('${disp.toStringAsFixed(1)} $unit',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c.accent)),
          ]),
          Slider(
            value: _kg, min: 35, max: 180, divisions: 290,
            activeColor: c.accent, inactiveColor: c.track,
            onChanged: (v) => setState(() => _kg = v),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => widget.onSave(double.parse(_kg.toStringAsFixed(1))),
              style: TextButton.styleFrom(
                backgroundColor: c.accent, foregroundColor: c.onAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(loc.save, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Log Measurements Sheet ───────────────────────────────────────────────────

class _LogMeasurementsSheet extends StatefulWidget {
  final ValueChanged<BodyMeasurement> onSave;
  const _LogMeasurementsSheet({required this.onSave});

  @override
  State<_LogMeasurementsSheet> createState() => _LogMeasurementsSheetState();
}

class _LogMeasurementsSheetState extends State<_LogMeasurementsSheet> {
  final _chest = TextEditingController();
  final _waist = TextEditingController();
  final _arm   = TextEditingController();
  final _thigh = TextEditingController();
  final _hip   = TextEditingController();
  final _neck  = TextEditingController();

  @override
  void dispose() {
    for (final c in [_chest, _waist, _arm, _thigh, _hip, _neck]) { c.dispose(); }
    super.dispose();
  }

  bool get _hasAny => [_chest, _waist, _arm, _thigh, _hip, _neck]
      .any((c) => double.tryParse(c.text) != null);

  void _save() {
    if (!_hasAny) return;
    widget.onSave(BodyMeasurement(
      date: DateTime.now(),
      chest: double.tryParse(_chest.text),
      waist: double.tryParse(_waist.text),
      arm:   double.tryParse(_arm.text),
      thigh: double.tryParse(_thigh.text),
      hip:   double.tryParse(_hip.text),
      neck:  double.tryParse(_neck.text),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(
            width: 40, height: 4, margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(color: c.textTertiary, borderRadius: BorderRadius.circular(4)),
          )),
          Text(
            loc.isAr ? 'سجّل القياسات (سم)' : 'Log measurements (cm)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.textPrimary),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _field(c, loc.isAr ? 'صدر' : 'Chest', _chest)),
            const SizedBox(width: 12),
            Expanded(child: _field(c, loc.isAr ? 'خصر' : 'Waist', _waist)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _field(c, loc.isAr ? 'ذراع' : 'Arm', _arm)),
            const SizedBox(width: 12),
            Expanded(child: _field(c, loc.isAr ? 'فخذ' : 'Thigh', _thigh)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _field(c, loc.isAr ? 'أرداف' : 'Hip', _hip)),
            const SizedBox(width: 12),
            Expanded(child: _field(c, loc.isAr ? 'رقبة' : 'Neck', _neck)),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _hasAny ? _save : null,
              style: TextButton.styleFrom(
                backgroundColor: c.accent, foregroundColor: c.onAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(loc.save, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _field(c, String label, TextEditingController ctrl) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: c.textSecondary)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
            style: TextStyle(color: c.textPrimary, fontSize: 15),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '0.0',
              hintStyle: TextStyle(color: c.textTertiary),
              suffixText: 'سم',
              suffixStyle: TextStyle(color: c.textTertiary, fontSize: 12),
              filled: true, fillColor: c.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.accent)),
            ),
          ),
        ],
      );
}

// ─── Sparkline ────────────────────────────────────────────────────────────────

class _Sparkline extends CustomPainter {
  final List<double> values;
  final Color color;
  final Color track;
  _Sparkline({required this.values, required this.color, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 0.5 ? 1.0 : (maxV - minV);
    final dx = size.width / (values.length - 1);

    Offset point(int i) => Offset(
      dx * i,
      size.height - ((values[i] - minV) / range) * size.height,
    );

    final path = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < values.length; i++) { path.lineTo(point(i).dx, point(i).dy); }

    canvas.drawPath(path, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);

    canvas.drawCircle(point(values.length - 1), 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_Sparkline old) => old.values != values || old.color != color;
}
