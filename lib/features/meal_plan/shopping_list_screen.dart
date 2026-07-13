import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/meal_plan_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final Set<int> _checked = {};

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final ctrl = context.watch<MealPlanController>();
    final items = ctrl.shoppingList();

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(children: [
                IconButton(onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary)),
                Text(loc.isAr ? 'قائمة الشراء' : 'Shopping List',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: c.textPrimary)),
                const Spacer(),
                if (items.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      final text = items.join('\n');
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(loc.isAr ? 'نُسخت القائمة' : 'List copied'),
                            backgroundColor: c.surface, behavior: SnackBarBehavior.floating),
                      );
                    },
                    icon: Icon(Icons.copy_rounded, color: c.accent),
                  ),
              ]),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(child: Text(
                      loc.isAr ? 'أضف وجبات للخطة أولاً' : 'Add meals to the plan first',
                      style: TextStyle(color: c.textSecondary, fontSize: 14)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final done = _checked.contains(i);
                        return GestureDetector(
                          onTap: () => setState(() => done ? _checked.remove(i) : _checked.add(i)),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: done ? c.surfaceVariant : c.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: done ? c.accent.withOpacity(0.3) : c.border),
                            ),
                            child: Row(children: [
                              Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                  color: done ? c.accent : c.textTertiary, size: 22),
                              const SizedBox(width: 14),
                              Expanded(child: Text(items[i],
                                  style: TextStyle(
                                    fontSize: 14, color: done ? c.textTertiary : c.textPrimary,
                                    decoration: done ? TextDecoration.lineThrough : null,
                                  ))),
                            ]),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
