import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/theme/void_theme_context.dart';
import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';
import '../../../projects/presentation/project_persistence_providers.dart';

/// run236 (Choi: "terapkan juga untuk world building dan timeline") — kartu
/// gambar dunia untuk entri yang BUKAN baris `assets` (faksi dan era
/// timeline menyimpan path di kolomnya sendiri, sehingga pipeline
/// thumbnail aset biasa tidak bisa dipakai).
///
/// Kontrak display sama dengan [AssetThumbnailCard]: tampilkan gambar milik
/// paket bila terikat (path basi yang filenya hilang jatuh jujur ke empty
/// state), ikon placeholder bila tidak, dan aksi import nyata bila ada
/// sesi proyek. Sumber path dan importer diinjeksikan lewat callback agar
/// kartu ini tetap dipakai dua entri dunia dengan kolom berbeda.
class WorldImageCard extends ConsumerStatefulWidget {
  const WorldImageCard({
    super.key,
    required this.entityId,
    required this.title,
    required this.placeholderIcon,
    required this.readImage,
    required this.importImage,
    this.aspectRatio = 16 / 9,
  });

  final String entityId;
  final String title;
  final IconData placeholderIcon;
  final Future<String?> Function(String entityId) readImage;
  final Future<void> Function(String entityId, String sourcePath) importImage;
  final double aspectRatio;

  @override
  ConsumerState<WorldImageCard> createState() => _WorldImageCardState();
}

class _WorldImageCardState extends ConsumerState<WorldImageCard> {
  String? _path;
  Future<void>? _loading;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(WorldImageCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entityId != widget.entityId) _reload();
  }

  Future<void> _reload() {
    final future = () async {
      final raw = await widget.readImage(widget.entityId);
      if (!mounted) return;
      setState(() {
        // Path basi (file sudah dihapus/pindah) = kosong, bukan gambar pecah.
        _path = (raw == null || raw.isEmpty || !File(raw).existsSync())
            ? null
            : raw;
      });
    }();
    _loading = future;
    return future;
  }

  Future<void> _import() async {
    final session = ref.read(projectSessionProvider).valueOrNull;
    if (session == null) return;
    const typeGroup = XTypeGroup(
      label: 'Images',
      extensions: ['png', 'jpg', 'jpeg', 'webp', 'gif'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;
    try {
      await widget.importImage(widget.entityId, file.path);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image import failed: $error')));
      return;
    }
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Image updated.')));
  }

  @override
  Widget build(BuildContext context) {
    final hasSession = ref.watch(projectSessionProvider).valueOrNull != null;
    return VoidCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: VoidTypography.headingMedium),
          const SizedBox(height: 14),
          AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: Container(
              decoration: BoxDecoration(
                color: context.palette.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.palette.borderSoft),
              ),
              child: FutureBuilder<void>(
                future: _loading,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: SizedBox.shrink());
                  }
                  final path = _path;
                  if (path != null) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(File(path), fit: BoxFit.cover),
                    );
                  }
                  return Center(
                    child: Icon(
                      widget.placeholderIcon,
                      size: 56,
                      color: context.palette.textMuted,
                    ),
                  );
                },
              ),
            ),
          ),
          if (hasSession) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _import,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Add Image'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
