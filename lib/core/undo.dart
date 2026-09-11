import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// شريط "تراجع" موحّد للإجراءات المدمّرة القابلة للاسترجاع.
///
/// مبدأ Apple في وكالة المستخدم: الزلّات تُعالَج بتراجعٍ سهل،
/// لا بحوار تأكيد يعترض كل حذف حتى يتعوّد المستخدم على تجاهله.
/// الحوار يُحفظ لما لا يمكن استرجاعه فعلاً (حذف ملف من القرص).
void showUndoBar(
  BuildContext context, {
  required String message,
  required VoidCallback onUndo,
}) {
  final loc = AppLocalizations.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: loc.isAr ? 'تراجع' : 'Undo',
          onPressed: onUndo,
        ),
      ),
    );
}
