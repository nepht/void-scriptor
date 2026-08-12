import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/project/project_database.dart';
import '../data/character_repository_impl.dart';
import '../domain/character_model.dart';
import '../application/create_character_service.dart';
import '../../projects/presentation/project_persistence_providers.dart';

final selectedCharacterIdProvider = StateProvider<String?>((ref) => null);

/// Compatibility alias used by the existing Explorer and Inspector.
final selectedAssetProvider = selectedCharacterIdProvider;

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
    ref.read(selectedAssetProvider.notifier).state = id;
    return id;
  }

  Future<void> delete(String id) async {
    await CharacterRepositoryImpl(
      database: database,
      projectId: projectId,
      paths: ref.read(projectPathsProvider),
    ).deleteCharacter(id);
    ref.invalidate(characterControllerProvider(projectId));
    if (ref.read(selectedAssetProvider) == id) {
      ref.read(selectedAssetProvider.notifier).state = null;
    }
  }
}
