import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../data/daily_tasks_controller.dart';
import '../../data/points_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class DailyTasksScreen extends StatelessWidget {
  const DailyTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final ctrl = context.watch<DailyTasksController>();
    final pts = context.watch<PointsController>();
    final tasks = ctrl.tasks;
    final done = tasks.where((t) => t.isDone).length;
    final todayPts = pts.todayTotal();

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
                Text(loc.isAr ? 'مهام اليوم' : "Today's tasks",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: c.textPrimary)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: c.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.bolt_rounded, size: 16, color: c.accent),
                    const SizedBox(width: 4),
                    Text('+$todayPts ${loc.points}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.accent)),
                  ]),
                ),
              ]),
            ),

            // progress summary
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: c.border),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(
                      loc.isAr ? '$done / ${tasks.length} مهمة مكتملة' : '$done / ${tasks.length} tasks done',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.textPrimary),
                    ),
                    const Spacer(),
                    Text(tasks.isEmpty ? '0%' : '${(done / tasks.length * 100).round()}%',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.accent)),
                  ]),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: tasks.isEmpty ? 0 : done / tasks.length,
                      backgroundColor: c.track,
                      valueColor: AlwaysStoppedAnimation(c.accent),
                      minHeight: 8,
                    ),
                  ),
                ]),
              ),
            ).animate().fadeIn(delay: 80.ms),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                itemCount: tasks.length,
                itemBuilder: (context, i) {
                  final task = tasks[i];
                  return _TaskCard(task: task, loc: loc, c: c)
                      .animate()
                      .fadeIn(delay: (120 + i * 60).ms, duration: 350.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOutCubic);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final DailyTask task;
  final AppLocalizations loc;
  final dynamic c;

  const _TaskCard({required this.task, required this.loc, required this.c});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: task.isDone ? c.accent.withOpacity(0.08) : c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: task.isDone ? c.accent : c.border,
          width: task.isDone ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: task.isDone ? c.accent.withOpacity(0.15) : c.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            task.isDone ? Icons.check_rounded : task.icon,
            color: task.isDone ? c.accent : c.textSecondary,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              loc.isAr ? task.titleAr : task.titleEn,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: task.isDone ? c.accent : c.textPrimary,
                decoration: task.isDone ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 6),
            if (task.target > 1) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: task.progress,
                  backgroundColor: c.track,
                  valueColor: AlwaysStoppedAnimation(task.isDone ? c.accent : c.accent2),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 4),
              Text('${task.current} / ${task.target}',
                  style: TextStyle(fontSize: 12, color: c.textSecondary)),
            ],
          ]),
        ),
        const SizedBox(width: 12),
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.bolt_rounded, size: 14, color: task.isDone ? c.accent : c.textTertiary),
          Text('+${task.points}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: task.isDone ? c.accent : c.textTertiary,
              )),
        ]),
      ]),
    );
  }
}
