import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../character/domain/character_identity_profile.dart';
import '../../../character/domain/character_model.dart';
import '../../../character/data/character_repository_impl.dart';
import '../../../character/presentation/character_workspace_controller.dart';
import '../../../project_resilience/application/project_version_control_service.dart';
import '../../../projects/presentation/project_persistence_providers.dart';
import '../widgets/reference_inspector_panel.dart';
import '../widgets/relation_section.dart';

String _heightLabel(double? heightCm) {
  if (heightCm == null) return '';
  final value = heightCm == heightCm.roundToDouble()
      ? heightCm.toInt().toString()
      : heightCm.toString();
  return '$value cm';
}

String _dateLabel(DateTime? value) =>
    value == null ? '' : value.toIso8601String().substring(0, 10);

class CharacterInspectorDetails {
  const CharacterInspectorDetails({
    this.assetName = '',
    this.version = '',
    this.createdAt,
    this.updatedAt,
    this.tags = const [],
    this.referenceCount = 0,
    this.versions = const [],
  });

  final String assetName;
  final String version;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> tags;
  final int referenceCount;
  final List<String> versions;
}

final characterInspectorNameProvider = FutureProvider.family<String?, String>((
  ref,
  characterId,
) async {
  final session = ref.watch(projectSessionProvider).valueOrNull;
  if (session == null) return null;
  final asset = await session.database.assetDao.getById(characterId);
  if (asset == null || asset.projectId != session.manifest.id) return null;
  return asset.name;
});

final characterInspectorDetailsProvider =
    FutureProvider.family<CharacterInspectorDetails, String>((
      ref,
      characterId,
    ) async {
      final session = ref.watch(projectSessionProvider).valueOrNull;
      if (session == null) return const CharacterInspectorDetails();
      final asset = await session.database.assetDao.getById(characterId);
      if (asset == null || asset.projectId != session.manifest.id) {
        return const CharacterInspectorDetails();
      }
      final repository = CharacterRepositoryImpl(
        database: session.database,
        projectId: session.manifest.id,
        paths: ref.read(projectPathsProvider),
      );
      final tags = await repository.getTags(characterId);
      final references = await repository.getReferences(characterId);
      final snapshots = await ProjectVersionControlService(
        session.package,
      ).listSnapshots();
      return CharacterInspectorDetails(
        assetName: asset.name,
        version: asset.version,
        createdAt: asset.createdAt,
        updatedAt: asset.updatedAt,
        tags: tags,
        referenceCount: references.length,
        versions: snapshots
            .where(
              (snapshot) =>
                  snapshot.assetType == 'character' &&
                  snapshot.assetId == characterId,
            )
            .map((snapshot) => snapshot.label)
            .toList(growable: false),
      );
    });

class CharacterInspector extends ConsumerWidget {
  const CharacterInspector({super.key, required this.characterId});
  final String characterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final character = ref.watch(characterWorkspaceProvider(characterId));
    final name = ref.watch(characterInspectorNameProvider(characterId));
    final identity = ref.watch(characterIdentityProvider(characterId));
    final details = ref.watch(characterInspectorDetailsProvider(characterId));
    return character.when(
      loading: () => _CharacterInspectorBody(
        characterId: characterId,
        character: null,
        assetName: name.valueOrNull,
        identity: identity.valueOrNull,
        details: details.valueOrNull ?? const CharacterInspectorDetails(),
      ),
      error: (error, _) => _CharacterInspectorBody(
        characterId: characterId,
        character: null,
        assetName: name.valueOrNull,
        identity: identity.valueOrNull,
        details: details.valueOrNull ?? const CharacterInspectorDetails(),
      ),
      data: (value) => _CharacterInspectorBody(
        characterId: characterId,
        character: value,
        assetName: name.valueOrNull,
        identity: identity.valueOrNull,
        details: details.valueOrNull ?? const CharacterInspectorDetails(),
      ),
    );
  }
}

class _CharacterInspectorBody extends StatelessWidget {
  const _CharacterInspectorBody({
    required this.characterId,
    required this.character,
    required this.assetName,
    required this.identity,
    required this.details,
  });

  final String characterId;
  final CharacterModel? character;
  final String? assetName;
  final CharacterIdentityProfile? identity;
  final CharacterInspectorDetails details;

  @override
  Widget build(BuildContext context) {
    final value = character;
    return Column(
      children: [
        RelationSection(assetId: characterId),
        const SizedBox(height: 16),
        Expanded(
          child: ReferenceInspectorPanel(
            properties: [
              InspectorProperty(
                'Name',
                value?.displayName ??
                    assetName ??
                    (details.assetName.isEmpty
                        ? 'Unknown asset'
                        : details.assetName),
              ),
              InspectorProperty('Role', value?.alias ?? ''),
              const InspectorProperty('Affiliation', ''),
              InspectorProperty('Gender', value?.gender ?? ''),
              InspectorProperty('Age', value?.age?.toString() ?? ''),
              InspectorProperty('Height', _heightLabel(value?.heightCm)),
              InspectorProperty('Version', details.version),
              InspectorProperty('Created', _dateLabel(details.createdAt)),
              InspectorProperty('Modified', _dateLabel(details.updatedAt)),
            ],
            tags: details.tags,
            quickNotes: identity?.notes ?? '',
            aiPrompt: '',
            locks: [
              InspectorLockState('Face Lock', identity?.faceLock ?? false),
              InspectorLockState(
                'Hair Geometry Lock',
                identity?.hairLock ?? false,
              ),
              InspectorLockState(
                'Body Proportion Lock',
                identity?.bodyLock ?? false,
              ),
              InspectorLockState('Color Lock', identity?.colorLock ?? false),
              InspectorLockState(
                'Wardrobe Lock',
                identity?.outfitLock ?? false,
              ),
              InspectorLockState('Weapon Lock', identity?.weaponLock ?? false),
              InspectorLockState(
                'Accessory Lock',
                identity?.accessoryLock ?? false,
              ),
            ],
            linkedAssets: [
              const InspectorAssetCount(
                'Wardrobe',
                '—',
                Icons.checkroom_outlined,
              ),
              const InspectorAssetCount('Weapons', '—', Icons.gavel_outlined),
              const InspectorAssetCount(
                'Expressions',
                '—',
                Icons.face_outlined,
              ),
              const InspectorAssetCount(
                'Poses',
                '—',
                Icons.accessibility_new_outlined,
              ),
              const InspectorAssetCount(
                'AI Assets',
                '—',
                Icons.settings_outlined,
              ),
              InspectorAssetCount(
                'References',
                details.referenceCount.toString(),
                Icons.description_outlined,
              ),
            ],
            versionHistory: details.versions,
            actionLabels: const [],
          ),
        ),
      ],
    );
  }
}
