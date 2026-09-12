import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

import '../../core/motion.dart';
import '../../data/fasting_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// مؤقّت الصيام المتقطّع — يبقى دقيقاً بعد إغلاق التطبيق
/// لأن المحفوظ هو لحظة البدء لا عدّاد يعمل بالخلفية.
class FastingScreen extends StatefulWidget {
  const FastingScreen({super.key});

  @override
  State<FastingScreen> createState() => _FastingScreenState();
}

class _FastingScreenState extends State<FastingScreen> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // تحديث العرض كل ثانية فقط أثناء الصيام.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && context.read<FastingController>().isFasting) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final f = context.watch<FastingController>();

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(children: [
              IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
              ),
              Flexible(child: Text(loc.isAr ? 'الصيام المتقطّع' : 'Intermittent fasting',
                  style: TextStyle(
                      fontSize: 20, letterSpacing: 20 * -0.01, fontWeight: FontWeight.w600, color: c.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 8),

            // الحلقة والمؤقّت
            Center(
              child: SizedBox(
                width: 230,
                height: 230,
                child: CustomPaint(
                  painter: _FastRing(
                    progress: f.progress,
                    track: c.track,
                    accent: f.reachedGoal ? c.accent2 : c.accent,
                  ),
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        f.isFasting ? _fmt(f.elapsed) : '--:--:--',
                        style: TextStyle(
                          fontSize: 32, letterSpacing: 32 * -0.025,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        !f.isFasting
                            ? (loc.isAr ? 'جاهز تبدأ' : 'Ready to start')
                            : f.reachedGoal
                                ? (loc.isAr ? '🎉 وصلت هدفك' : '🎉 Goal reached')
                                : (loc.isAr
                                    ? 'باقي ${f.remaining.inHours}س ${f.remaining.inMinutes % 60}د'
                                    : '${f.remaining.inHours}h ${f.remaining.inMinutes % 60}m left'),
                        style: TextStyle(fontSize: 13, color: c.textSecondary),
                      ),
                    ]),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 18),

            if (f.isFasting && f.endsAt != null)
              Center(
                child: Text(
                  loc.isAr
                      ? 'نافذة الأكل تفتح ${intl.DateFormat('h:mm a').format(f.endsAt!)}'
                      : 'Eating window opens at ${intl.DateFormat('h:mm a').format(f.endsAt!)}',
                  style: TextStyle(fontSize: 13, color: c.textSecondary),
                ),
              ),
            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () async {
                  Haptics.light();
                  if (f.isFasting) {
                    final s = await f.stop();
                    if (!context.mounted || s == null) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(s.reachedGoal
                          ? (loc.isAr
                              ? 'أنهيت صيامك — وصلت الهدف 👏'
                              : 'Fast complete — goal reached 👏')
                          : (loc.isAr
                              ? 'أنهيت بعد ${s.duration.inHours}س ${s.duration.inMinutes % 60}د'
                              : 'Ended after ${s.duration.inHours}h ${s.duration.inMinutes % 60}m')),
                      behavior: SnackBarBehavior.floating,
                    ));
                  } else {
                    await f.start();
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: f.isFasting ? c.surfaceVariant : c.accent,
                  foregroundColor: f.isFasting ? c.textPrimary : c.onAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  f.isFasting
                      ? (loc.isAr ? 'أنهِ الصيام' : 'End fast')
                      : (loc.isAr ? 'ابدأ الصيام' : 'Start fast'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(loc.isAr ? 'البروتوكول' : 'Protocol',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary)),
            const SizedBox(height: 10),
            ...kFastingPlans.map((p) {
              final sel = p.id == f.plan.id;
              return ZadTap(
                onTap: f.isFasting
                    ? null // تغيير الهدف أثناء الصيام يفسد الحساب
                    : () {
                        Haptics.select();
                        f.setPlan(p);
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: sel ? c.accent.withOpacity(0.12) : c.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: sel ? c.accent : c.border, width: sel ? 1.6 : 1),
                  ),
                  child: Opacity(
                    opacity: f.isFasting && !sel ? 0.5 : 1,
                    child: Row(children: [
                      Icon(sel ? Icons.radio_button_checked : Icons.radio_button_off,
                          size: 20, color: sel ? c.accent : c.textTertiary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name(isAr: loc.isAr),
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: sel ? c.accent : c.textPrimary)),
                              Text(p.desc(isAr: loc.isAr),
                                  style:
                                      TextStyle(fontSize: 12, color: c.textSecondary)),
                            ]),
                      ),
                    ]),
                  ),
                ),
              );
            }),

            if (f.log.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: Text(loc.isAr ? 'السجل' : 'History',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                Flexible(child: Text(
                  loc.isAr
                      ? '${f.goalsThisWeek} أهداف هذا الأسبوع'
                      : '${f.goalsThisWeek} goals this week',
                  style: TextStyle(fontSize: 12, color: c.accent), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 10),
              ...f.log.take(7).map((s) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.border),
                    ),
                    child: Row(children: [
                      Icon(
                          s.reachedGoal
                              ? Icons.check_circle_rounded
                              : Icons.timelapse_rounded,
                          size: 18,
                          color: s.reachedGoal ? c.accent : c.textTertiary),
                      const SizedBox(width: 10),
                      Expanded(child: Text(intl.DateFormat('d MMM').format(s.start),
                          style: TextStyle(fontSize: 13, color: c.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Flexible(child: Text(
                        '${s.duration.inHours}${loc.hourShort} '
                        '${s.duration.inMinutes % 60}${loc.minuteShort}',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Flexible(child: Text(' / ${s.targetHours}${loc.hourShort}',
                          style: TextStyle(fontSize: 11, letterSpacing: 11 * 0.01, color: c.textTertiary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ]),
                  )),
            ],

            const SizedBox(height: 16),
            Text(
              loc.isAr
                  ? 'الصيام المتقطّع لا يناسب الجميع. راجع مختصاً إن كنت حاملاً أو مرضعاً '
                      'أو عندك سكري أو تاريخ اضطراب أكل.'
                  : 'Intermittent fasting is not for everyone. Consult a professional if you '
                      'are pregnant, nursing, diabetic, or have a history of disordered eating.',
              style: TextStyle(fontSize: 11, letterSpacing: 11 * 0.01, height: 1.7, color: c.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

class _FastRing extends CustomPainter {
  final double progress;
  final Color track;
  final Color accent;
  _FastRing({required this.progress, required this.track, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14,
    );

    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_FastRing old) =>
      old.progress != progress || old.accent != accent;
}
