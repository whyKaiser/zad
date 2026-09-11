import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' as intl;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class ProgressPhotosScreen extends StatefulWidget {
  const ProgressPhotosScreen({super.key});

  @override
  State<ProgressPhotosScreen> createState() => _ProgressPhotosScreenState();
}

class _ProgressPhotosScreenState extends State<ProgressPhotosScreen> {
  static const _key = 'zad_progress_photos';
  List<_PhotoEntry> _photos = [];
  final _picker = ImagePicker();

  /// مجلّد الصور الحالي. **لا نخزّن مسارات مطلقة**: مسار حاوية التطبيق
  /// يتغيّر بعد التحديث على iOS فتختفي كل الصور. نخزّن الاسم فقط ونركّبه هنا.
  String? _dir;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _dir = dir.path;
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_key) ?? const [];
      final entries = <_PhotoEntry>[];
      for (final s in raw) {
        final parts = s.split('|');
        if (parts.length != 2) continue;
        final date = DateTime.tryParse(parts[1]);
        if (date == null) continue;
        // توافق مع النسخة القديمة التي خزّنت مساراً كاملاً.
        final name = parts[0].split(RegExp(r'[/\\]')).last;
        final file = File('${dir.path}/$name');
        // متعمّد غير متزامن: الفحص يتم لعدة ملفات عند فتح الشاشة،
        // والنسخة المتزامنة تُجمّد الواجهة.
        // ignore: avoid_slow_async_io
        if (await file.exists()) {
          entries.add(_PhotoEntry(name: name, date: date));
        }
      }
      entries.sort((a, b) => b.date.compareTo(a.date));
      if (mounted) setState(() => _photos = entries);
      // نعيد الكتابة بالصيغة الجديدة (أسماء فقط) لترحيل السجلات القديمة.
      await _persist();
    } catch (e) {
      debugPrint('progress photos load error: $e');
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _key,
        _photos.map((e) => '${e.name}|${e.date.toIso8601String()}').toList(),
      );
    } catch (e) {
      debugPrint('progress photos persist error: $e');
    }
  }

  Future<void> _addPhoto(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    final loc = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked =
          await _picker.pickImage(source: source, imageQuality: 75, maxWidth: 1600);
      if (picked == null) return;
      final dir = _dir ?? (await getApplicationDocumentsDirectory()).path;
      _dir = dir;
      final ts = DateTime.now();
      final name = 'progress_${ts.millisecondsSinceEpoch}.jpg';
      await File(picked.path).copy('$dir/$name');
      _photos.insert(0, _PhotoEntry(name: name, date: ts));
      await _persist();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('addPhoto error: $e');
      messenger.showSnackBar(SnackBar(
        content: Text(loc.isAr ? 'تعذّر حفظ الصورة' : 'Could not save the photo'),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// اختيار المصدر — التصوير الآن أهم من المعرض لصور التقدّم.
  void _pickSource() {
    final loc = AppLocalizations.of(context);
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: c.textTertiary, borderRadius: BorderRadius.circular(4)),
          ),
          ListTile(
            leading: Icon(Icons.photo_camera_rounded, color: c.accent),
            title: Text(loc.isAr ? 'التقط صورة' : 'Take a photo',
                style: TextStyle(color: c.textPrimary)),
            onTap: () {
              Navigator.pop(sheetCtx);
              _addPhoto(ImageSource.camera);
            },
          ),
          ListTile(
            leading: Icon(Icons.photo_library_outlined, color: c.accent),
            title: Text(loc.isAr ? 'من المعرض' : 'From gallery',
                style: TextStyle(color: c.textPrimary)),
            onTap: () {
              Navigator.pop(sheetCtx);
              _addPhoto(ImageSource.gallery);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Future<void> _delete(_PhotoEntry e) async {
    _photos.remove(e);
    final dir = _dir;
    if (dir != null) {
      try {
        await File('$dir/${e.name}').delete();
      } catch (_) {
        // الملف مفقود أصلاً — يكفي شطبه من السجل.
      }
    }
    await _persist();
    if (mounted) setState(() {});
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
                IconButton(onPressed: () => Navigator.pop(context),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary)),
                Text(loc.isAr ? 'صور التقدم' : 'Progress Photos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: c.textPrimary)),
                const Spacer(),
                IconButton(
                  tooltip: AppLocalizations.of(context).isAr ? 'أضف صورة' : 'Add photo',
                  onPressed: _busy ? null : _pickSource,
                  icon: Icon(Icons.add_a_photo_outlined, color: c.accent),
                ),
              ]),
            ),
            Expanded(
              child: _photos.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.photo_library_outlined, size: 64, color: c.textTertiary),
                        const SizedBox(height: 16),
                        Text(loc.isAr ? 'ما فيه صور بعد' : 'No photos yet',
                            style: TextStyle(color: c.textSecondary, fontSize: 15)),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _busy ? null : _pickSource,
                          icon: Icon(Icons.add, color: c.accent),
                          label: Text(loc.isAr ? 'أضف صورة' : 'Add photo',
                              style: TextStyle(color: c.accent)),
                        ),
                      ]),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.75,
                      ),
                      itemCount: _photos.length,
                      itemBuilder: (_, i) => _PhotoCard(
                        dir: _dir ?? '',
                        entry: _photos[i],
                        loc: loc, c: c,
                        onDelete: () => _delete(_photos[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoEntry {
  /// اسم الملف فقط — المسار يُركَّب وقت العرض من مجلّد التطبيق الحالي.
  final String name;
  final DateTime date;
  _PhotoEntry({required this.name, required this.date});
}

class _PhotoCard extends StatelessWidget {
  final String dir;
  final _PhotoEntry entry;
  final AppLocalizations loc;
  final dynamic c;
  final VoidCallback onDelete;
  const _PhotoCard(
      {required this.dir,
      required this.entry,
      required this.loc,
      required this.c,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(loc.isAr ? 'حذف الصورة؟' : 'Delete photo?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.isAr ? 'إلغاء' : 'Cancel')),
            TextButton(onPressed: () { Navigator.pop(context); onDelete(); },
                child: Text(loc.isAr ? 'حذف' : 'Delete', style: TextStyle(color: context.colors.danger))),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(fit: StackFit.expand, children: [
          Image.file(
            File('$dir/${entry.name}'),
            fit: BoxFit.cover,
            // ملف محذوف من خارج التطبيق يجب ألا يكسر الشبكة كاملة.
            errorBuilder: (_, __, ___) => Container(
              color: c.surfaceVariant as Color,
              child: Icon(Icons.broken_image_outlined, color: c.textTertiary as Color),
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              child: Text(
                intl.DateFormat('d MMM yyyy').format(entry.date),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
