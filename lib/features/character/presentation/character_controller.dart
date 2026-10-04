import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/project/project_database.dart';
import '../../../core/selection/selection_controller.dart';
import '../../../core/selection/selection_model.dart';
import '../../assets/domain/asset_type.dart';
import '../data/character_repository_impl.dart';
import '../domain/character_model.dart';
import '../application/create_character_service.dart';
import '../../projects/presentation/project_persistence_providers.dart';
import '../../workspaces/application/workspace_character_deletion_service.dart';
import '../application/rename_character_command.dart';

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
      final session = ref.watch(projectSessionProvider).value;
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

  Future<void> rename(String id, String newName) async {
    final session = ref.read(projectSessionProvider).value;
    if (session == null || session.manifest.id != projectId) {
      throw StateError('No active project session');
    }
    final repository = CharacterRepositoryImpl(
      database: database,
      projectId: projectId,
      paths: ref.read(projectPathsProvider),
    );
    final current = await repository.getCharacter(id);
    if (current == null) throw StateError('Character not found');
    await session.mutationRuntime.bus.execute(
      RenameCharacterCommand(
        id: 'character.rename:$id:${DateTime.now().microsecondsSinceEpoch}',
        projectId: projectId,
        repository: repository,
        characterId: id,
        oldName: current.displayName,
        newName: newName,
      ),
    );
    ref.invalidate(characterControllerProvider(projectId));
  }

  Future<CharacterDeletionReview> reviewDeletion(String id) async {
    final session = ref.read(projectSessionProvider).value;
    if (session == null || session.manifest.id != projectId) {
      throw StateError('No active project session');
    }
    return session.characterDeletion.review(id);
  }

  Future<void> delete(
    String id, {
    required CharacterDeletionDecision decision,
  }) async {
    final session = ref.read(projectSessionProvider).value;
    if (session == null || session.manifest.id != projectId) {
      throw StateError('No active project session');
    }
    await session.characterDeletion.deleteCharacterWorkspace(
      id,
      decision: decision,
    );
    ref.invalidate(characterControllerProvider(projectId));
    if (ref.read(selectionProvider)?.assetId == id) {
      ref.read(selectionProvider.notifier).clear();
    }
  }
}
