import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

import '../../projects/presentation/project_persistence_providers.dart';
import '../data/character_loadout_repository_impl.dart';
import '../data/character_mode_repository_impl.dart';
import '../domain/character_mode.dart';
import '../../../database/project/project_database.dart' as db;
import '../domain/loadout_slot.dart';
import '../domain/character_mode_changed.dart';

final characterModesProvider =
    FutureProvider.family<List<CharacterMode>, String>((
      ref,
      characterId,
    ) async {
      final session = ref.watch(projectSessionProvider).value;
      if (session == null) return const [];
      return CharacterModeRepositoryImpl(
        session.database,
      ).getModes(characterId);
    });

final lastUsedCharacterModeProvider = FutureProvider.family<String?, String>((
  ref,
  characterId,
) async {
  final session = ref.watch(projectSessionProvider).value;
  if (session == null) return null;
  return CharacterModeRepositoryImpl(
    session.database,
  ).getLastUsedMode(characterId);
});

final selectedCharacterModeProvider = StateProvider.family<String?, String>(
  (ref, characterId) => null,
);

final characterModeChangedProvider =
    StateProvider.family<CharacterModeChanged?, String>(
      (ref, characterId) => null,
    );

final characterModeLoadoutProvider =
    FutureProvider.family<List<db.CharacterLoadoutEntry>, String>((
      ref,
      modeId,
    ) async {
      final session = ref.watch(projectSessionProvider).value;
      if (session == null) return const [];
      return CharacterLoadoutRepositoryImpl(
        session.database,
      ).getLoadout(modeId);
    });

final projectAssetsProvider = FutureProvider<List<db.Asset>>((ref) async {
  final session = ref.watch(projectSessionProvider).value;
  if (session == null) return const [];
  return session.database.assetDao.getAllAssets();
});

class CharacterModeActions {
  const CharacterModeActions(this.ref);
  final WidgetRef ref;

  Future<String?> create({
    required String characterId,
    required String name,
  }) async {
    final session = ref.read(projectSessionProvider).value;
    if (session == null) return null;
    final id = await CharacterModeRepositoryImpl(session.database).createMode(
      projectId: session.manifest.id,
      characterId: characterId,
      name: name,
    );
    ref.invalidate(characterModesProvider(characterId));
    ref.read(selectedCharacterModeProvider(characterId).notifier).state = id;
    return id;
  }

  Future<void> setSlot({
    required String modeId,
    required LoadoutSlot slot,
    required String assetId,
    int quantity = 1,
  }) async {
    final session = ref.read(projectSessionProvider).value;
    if (session == null) return;
    await CharacterLoadoutRepositoryImpl(
      session.database,
    ).setSlot(modeId: modeId, slot: slot, assetId: assetId, quantity: quantity);
    ref.invalidate(characterModeLoadoutProvider(modeId));
  }

  Future<void> removeSlot({
    required String modeId,
    required LoadoutSlot slot,
    required String assetId,
  }) async {
    final session = ref.read(projectSessionProvider).value;
    if (session == null) return;
    await CharacterLoadoutRepositoryImpl(
      session.database,
    ).removeSlot(modeId: modeId, slot: slot, assetId: assetId);
    ref.invalidate(characterModeLoadoutProvider(modeId));
  }

  Future<db.Asset?> createStandaloneAsset({
    required String name,
    required String description,
    required String type,
  }) async {
    final session = ref.read(projectSessionProvider).value;
    if (session == null) return null;
    final id = const Uuid().v4();
    await session.database.assetDao.createStandaloneCharacterAsset(
      id: id,
      projectId: session.manifest.id,
      name: name,
      description: description,
      type: type,
      now: DateTime.now().toUtc(),
    );
    ref.invalidate(projectAssetsProvider);
    return session.database.assetDao.getById(id);
  }
}
