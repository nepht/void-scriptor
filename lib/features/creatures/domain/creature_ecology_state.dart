class CreatureEcologyState {
  const CreatureEcologyState({
    required this.creatureId,
    required this.speciesId,
    required this.genomeJson,
    required this.phenotypeJson,
    required this.needsJson,
    this.lineageId,
    this.simulationTick = 0,
  });

  final String creatureId;
  final String speciesId;
  final String genomeJson;
  final String phenotypeJson;
  final String needsJson;
  final String? lineageId;
  final int simulationTick;
}
