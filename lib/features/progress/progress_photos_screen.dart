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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final entries = <_PhotoEntry>[];
    for (final s in raw) {
      final parts = s.split('|');
      if (parts.length == 2) {
        final file = File(parts[0]);
        if (await file.exists()) {
          entries.add(_PhotoEntry(path: parts[0], date: DateTime.parse(parts[1])));
        }
      }
    }
    if (mounted) setState(() => _photos = entries..sort((a, b) => b.date.compareTo(a.date)));
  }

  Future<void> _addPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now();
    final dest = '${dir.path}/progress_${ts.millisecondsSinceEpoch}.jpg';
    await File(picked.path).copy(dest);
    final entry = _PhotoEntry(path: dest, date: ts);
    _photos.insert(0, entry);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _photos.map((e) => '${e.path}|${e.date.toIso8601String()}').toList());
    if (mounted) setState(() {});
  }

  Future<void> _delete(_PhotoEntry e) async {
    _photos.remove(e);
    try { await File(e.path).delete(); } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _photos.map((x) => '${x.path}|${x.date.toIso8601String()}').toList());
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
                    icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary)),
                Text(loc.isAr ? 'صور التقدم' : 'Progress Photos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: c.textPrimary)),
                const Spacer(),
                IconButton(
                  onPressed: _addPhoto,
                  icon: Icon(Icons.add_photo_alternate_outlined, color: c.accent),
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
                          onPressed: _addPhoto,
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
  final String path;
  final DateTime date;
  _PhotoEntry({required this.path, required this.date});
}

class _PhotoCard extends StatelessWidget {
  final _PhotoEntry entry;
  final AppLocalizations loc;
  final dynamic c;
  final VoidCallback onDelete;
  const _PhotoCard({required this.entry, required this.loc, required this.c, required this.onDelete});

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
                child: Text(loc.isAr ? 'حذف' : 'Delete', style: const TextStyle(color: Colors.red))),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(fit: StackFit.expand, children: [
          Image.file(File(entry.path), fit: BoxFit.cover),
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
