import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/project/project_database.dart';
import '../../../core/selection/selection_controller.dart';
import '../../../core/selection/selection_model.dart';
import '../../assets/domain/asset_type.dart';
import '../data/character_repository_impl.dart';
import '../domain/character_model.dart';
import '../application/create_character_service.dart';
import '../../projects/presentation/project_persistence_providers.dart';

final selectedCharacterIdProvider = Provider<String?>(
  (ref) => ref.watch(selectionProvider)?.assetType == AssetType.character
      ? ref.watch(selectionProvider)?.assetId
      : null,
);

/// Compatibility alias used by the existing Explorer and Inspector.
final selectedAssetProvider = Provider<String?>(
  (ref) => ref.watch(selectionProvider)?.assetId,
);

final characterControllerProvider =
    FutureProvider.family<List<CharacterModel>, String>((ref, projectId) async {
      final session = ref.watch(projectSessionProvider).valueOrNull;
      if (session == null || session.manifest.id != projectId) return const [];
      return CharacterRepositoryImpl(
        database: session.database,
        projectId: projectId,
        paths: ref.read(projectPathsProvider),
      ).getCharacters();
    });

class CharacterActions {
  const CharacterActions(this.ref, this.projectId, this.database);

  final WidgetRef ref;
  final String projectId;
  final ProjectDatabase database;

  Future<String> create(String name) async {
    final id = await CreateCharacterService(
      database: database,
      paths: ref.read(projectPathsProvider),
    ).create(projectId: projectId, name: name);
    ref.invalidate(characterControllerProvider(projectId));
    ref
        .read(selectionProvider.notifier)
        .select(
          SelectionModel(
            assetId: id,
            assetType: AssetType.character,
            projectId: projectId,
          ),
        );
    return id;
  }

  Future<void> delete(String id) async {
    await CharacterRepositoryImpl(
      database: database,
      projectId: projectId,
      paths: ref.read(projectPathsProvider),
    ).deleteCharacter(id);
    ref.invalidate(characterControllerProvider(projectId));
    if (ref.read(selectionProvider)?.assetId == id) {
      ref.read(selectionProvider.notifier).clear();
    }
  }
}
