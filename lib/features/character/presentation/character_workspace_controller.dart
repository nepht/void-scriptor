import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../projects/presentation/project_persistence_providers.dart';
import '../application/update_character_identity_command.dart';
import '../data/character_repository_impl.dart';
import '../domain/character_identity_profile.dart';
import '../domain/character_model.dart';

/// Portrait file bound to a character asset, resolved from the asset
/// `thumbnail_path` written by [AssetThumbnailImporter]. Null means the
/// character has no imported portrait yet; a stale path pointing at a
/// deleted file is filtered so the card falls back to its empty state.
final characterPortraitProvider = FutureProvider.family<String?, String>((
  ref,
  characterId,
) async {
  final session = ref.watch(projectSessionProvider).valueOrNull;
  if (session == null) return null;
  final asset = await session.database.assetDao.getById(characterId);
  final path = asset?.thumbnailPath;
  if (path == null || path.isEmpty) return null;
  return File(path).existsSync() ? path : null;
});

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
