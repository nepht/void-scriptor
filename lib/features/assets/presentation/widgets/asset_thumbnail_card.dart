import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';

import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';
import '../../../projects/presentation/project_persistence_providers.dart';
import '../../application/asset_thumbnail_importer.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Reads the imported thumbnail file bound to an asset (written by
/// [AssetThumbnailImporter]); a stale path pointing at a deleted file is
/// filtered so cards fall back to their empty state.
final assetThumbnailProvider = FutureProvider.family<String?, String>((
  ref,
  assetId,
) async {
  final session = ref.watch(projectSessionProvider).valueOrNull;
  if (session == null) return null;
  final asset = await session.database.assetDao.getById(assetId);
  final path = asset?.thumbnailPath;
  if (path == null || path.isEmpty) return null;
  return File(path).existsSync() ? path : null;
});

/// Shared visual card used by wardrobe (Product View), weapons (Technical
/// View) and supporting assets (accessory/vehicle/hair/carried): renders a
/// package-owned image when bound, otherwise the type placeholder icon, and
/// offers the real import action whenever a session exists. The same
/// [AssetThumbnailImporter] the character portrait and asset browser use,
/// so images survive moving project folders.
class AssetThumbnailCard extends ConsumerStatefulWidget {
  const AssetThumbnailCard({
    super.key,
    required this.assetId,
    required this.title,
    required this.placeholderIcon,
    this.aspectRatio = 4 / 5,
  });

  final String assetId;
  final String title;
  final IconData placeholderIcon;

  /// Visual box shape; workspace cards use 4/5 while the environment
  /// location preview keeps its historical 16/9.
  final double aspectRatio;

  @override
  ConsumerState<AssetThumbnailCard> createState() => _AssetThumbnailCardState();
}

class _AssetThumbnailCardState extends ConsumerState<AssetThumbnailCard> {
  Future<void> _import() async {
    final session = ref.read(projectSessionProvider).valueOrNull;
    if (session == null) return;
    const typeGroup = XTypeGroup(
      label: 'Images',
      extensions: ['png', 'jpg', 'jpeg', 'webp', 'gif'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;
    final importer = AssetThumbnailImporter(
      database: session.database,
      assetsDirectory: session.package.assetsDirectory,
    );
    try {
      await importer.importFromFile(
        assetId: widget.assetId,
        sourcePath: file.path,
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image import failed: $error')));
      return;
    }
    ref.invalidate(assetThumbnailProvider(widget.assetId));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Image updated.')));
  }

  @override
  Widget build(BuildContext context) {
    final thumbnail = ref.watch(assetThumbnailProvider(widget.assetId));
    final path = thumbnail.valueOrNull;
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
              child: path != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(File(path), fit: BoxFit.cover),
                    )
                  : Center(
                      child: Icon(
                        widget.placeholderIcon,
                        size: 56,
                        color: context.palette.textMuted,
                      ),
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
