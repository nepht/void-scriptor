import 'package:uuid/uuid.dart';

import '../../../database/project/project_database.dart';
import '../data/character_mode_repository_impl.dart';

class CreateCharacterModeService {
  CreateCharacterModeService({required this.database})
    : repository = CharacterModeRepositoryImpl(database);

  final ProjectDatabase database;
  final CharacterModeRepositoryImpl repository;

  Future<String> create({
    required String projectId,
    required String characterId,
    required String name,
    bool isDefault = false,
    String description = '',
  }) => repository.createMode(
    projectId: projectId,
    characterId: characterId,
    name: name,
    isDefault: isDefault,
  );

  Future<String> clone({required String sourceModeId, required String name}) =>
      repository.cloneMode(sourceModeId: sourceModeId, name: name);
}

String generateModeId() => const Uuid().v4();
