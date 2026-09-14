import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/project/project_database.dart';
import '../../application/bible_timeline_repository.dart';
import '../../application/timeline_era_image_importer.dart';
import '../../../projects/presentation/project_persistence_providers.dart';
import 'world_image_card.dart';

/// run236: kartu gambar era timeline. Era bukan baris `assets` sehingga
/// kolom gambarnya sendiri (`timeline_eras.image_path`, migrasi 60->61);
/// display delegated ke [WorldImageCard] yang sama dipakai faksi.
class TimelineEraImageCard extends ConsumerWidget {
  const TimelineEraImageCard({super.key, required this.eraId});

  final String eraId;

  static Future<String?> read(ProjectDatabase db, String id) async {
    final eras = await BibleTimelineRepository(db).listErasById(id);
    final path = eras.isEmpty ? '' : eras.single.imagePath;
    return path.isEmpty ? null : path;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(projectSessionProvider).valueOrNull;
    return WorldImageCard(
      projectId: session?.manifest.id ?? '',
      entityId: eraId,
      title: 'ERA IMAGE',
      placeholderIcon: Icons.timeline,
      readImage: (id) =>
          session == null ? Future.value(null) : read(session.database, id),
      importImage: (id, sourcePath) => TimelineEraImageImporter(
        database: session!.database,
        assetsDirectory: session.package.assetsDirectory,
      ).importFromFile(eraId: id, sourcePath: sourcePath),
    );
  }
}
