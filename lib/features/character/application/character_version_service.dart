import 'package:uuid/uuid.dart';

import '../../project_resilience/application/project_mutation_runtime.dart';
import '../../project_resilience/application/project_version_control_service.dart';
import '../data/character_repository_impl.dart';
import 'update_character_command.dart';

class CharacterVersionService {
  CharacterVersionService({
    required this.repository,
    required this.runtime,
    required this.versions,
  });

  final CharacterRepositoryImpl repository;
  final ProjectMutationRuntime runtime;
  final ProjectVersionControlService versions;

  Future<ProjectSnapshot> capture(
    String characterId, {
    required String label,
  }) async {
    final character = await repository.getCharacter(characterId);
    if (character == null || character.projectId != runtime.projectId) {
      throw StateError('Character is not available in the active project');
    }
    return versions.createSnapshot(
      label: label,
      assetType: 'character',
      assetId: characterId,
      data: characterToData(character),
    );
  }

  Future<VersionDiff> compare(String firstId, String secondId) =>
      versions.compare(firstId, secondId);

  Future<void> restore(String snapshotId) async {
    await versions.restore(snapshotId, (data) async {
      final target = characterFromData(data);
      if (target.projectId != runtime.projectId) {
        throw StateError('Snapshot does not belong to the active project');
      }
      final current = await repository.getCharacter(target.assetId);
      if (current == null) {
        throw StateError('Character is not available in the active project');
      }
      await runtime.bus.execute(
        UpdateCharacterCommand(
          id: const Uuid().v4(),
          projectId: runtime.projectId,
          repository: repository,
          oldValue: current,
          newValue: target,
          label: 'Restore Character Revision',
        ),
      );
    });
  }
}
