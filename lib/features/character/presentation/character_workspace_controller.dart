import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../projects/presentation/project_persistence_providers.dart';
import '../application/update_character_identity_command.dart';
import '../data/character_repository_impl.dart';
import '../domain/character_identity_profile.dart';
import '../domain/character_model.dart';

final characterWorkspaceProvider =
    FutureProvider.family<CharacterModel?, String>((ref, characterId) async {
      final session = ref.watch(projectSessionProvider).valueOrNull;
      if (session == null) return null;
      return CharacterRepositoryImpl(
        database: session.database,
        projectId: session.manifest.id,
        paths: ref.read(projectPathsProvider),
      ).getCharacter(characterId);
    });

final characterIdentityProvider =
    FutureProvider.family<CharacterIdentityProfile?, String>((
      ref,
      characterId,
    ) async {
      final session = ref.watch(projectSessionProvider).valueOrNull;
      if (session == null) return null;
      return CharacterRepositoryImpl(
        database: session.database,
        projectId: session.manifest.id,
        paths: ref.read(projectPathsProvider),
      ).getIdentity(characterId);
    });

class CharacterIdentityActions {
  const CharacterIdentityActions(this.ref);
  final WidgetRef ref;

  Future<void> update(CharacterIdentityProfile profile) async {
    final session = ref.read(projectSessionProvider).valueOrNull;
    if (session == null) return;
    final repository = CharacterRepositoryImpl(
      database: session.database,
      projectId: session.manifest.id,
      paths: ref.read(projectPathsProvider),
    );
    final current = await repository.getIdentity(profile.characterId);
    if (current == null) {
      throw StateError('Character identity profile not found');
    }
    await session.mutationRuntime.bus.execute(
      UpdateCharacterIdentityCommand(
        id: const Uuid().v4(),
        projectId: session.manifest.id,
        repository: repository,
        oldValue: current,
        newValue: profile,
      ),
    );
    ref.invalidate(characterIdentityProvider(profile.characterId));
  }
}
