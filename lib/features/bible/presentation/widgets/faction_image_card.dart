import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/project/project_database.dart';
import '../../application/faction_image_importer.dart';
import '../../application/faction_repository.dart';
import '../../../projects/presentation/project_persistence_providers.dart';
import 'world_image_card.dart';

/// run236: kartu gambar faksi pada Worldbuilding body. Faksi bukan baris
/// `assets` sehingga kolom gambarnya sendiri (`factions.image_path`,
/// migrasi 60->61); display delegated ke [WorldImageCard] yang sama
/// dipakai era timeline.
class FactionImageCard extends ConsumerWidget {
  const FactionImageCard({super.key, required this.factionId});

  final String factionId;

  static Future<String?> read(ProjectDatabase db, String id) async {
    final faction = await FactionRepository(db).get(id);
    final path = faction?.imagePath ?? '';
    return path.isEmpty ? null : path;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(projectSessionProvider).valueOrNull;
    return WorldImageCard(
      entityId: factionId,
      title: 'FACTION IMAGE',
      placeholderIcon: Icons.groups_outlined,
      readImage: (id) =>
          session == null ? Future.value(null) : read(session.database, id),
      importImage: (id, sourcePath) => FactionImageImporter(
        database: session!.database,
        assetsDirectory: session.package.assetsDirectory,
      ).importFromFile(assetId: id, sourcePath: sourcePath),
    );
  }
}
