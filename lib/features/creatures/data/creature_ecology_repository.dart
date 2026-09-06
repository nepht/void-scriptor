import 'package:drift/drift.dart';

import '../../../database/project/project_database.dart';
import '../domain/creature_ecology_state.dart' as domain;

class CreatureEcologyRepository {
  CreatureEcologyRepository(this.database);

  final ProjectDatabase database;

  Future<void> save(domain.CreatureEcologyState state) {
    return database
        .into(database.creatureEcologyStates)
        .insertOnConflictUpdate(
          CreatureEcologyStatesCompanion.insert(
            creatureId: state.creatureId,
            speciesId: state.speciesId,
            genomeJson: state.genomeJson,
            phenotypeJson: state.phenotypeJson,
            needsJson: state.needsJson,
            lineageId: Value(state.lineageId),
            simulationTick: Value(state.simulationTick),
          ),
        );
  }

  Future<domain.CreatureEcologyState?> get(String creatureId) async {
    final row = await (database.select(
      database.creatureEcologyStates,
    )..where((item) => item.creatureId.equals(creatureId))).getSingleOrNull();
    return row == null
        ? null
        : domain.CreatureEcologyState(
            creatureId: row.creatureId,
            speciesId: row.speciesId,
            genomeJson: row.genomeJson,
            phenotypeJson: row.phenotypeJson,
            needsJson: row.needsJson,
            lineageId: row.lineageId,
            simulationTick: row.simulationTick,
          );
  }
}
