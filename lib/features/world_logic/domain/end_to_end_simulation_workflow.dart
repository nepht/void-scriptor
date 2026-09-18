/// Deterministic, local-only tracer for the Sprint 112.34 simulation contract.
class SimulationWorkflowInput {
  const SimulationWorkflowInput({
    required this.eventId,
    required this.eventDescription,
    required this.originLocationId,
    required this.destinationLocationId,
    required this.factionId,
    required this.affectedCharacterId,
    required this.commodityId,
    required this.technologyId,
    required this.storyId,
    required this.tick,
  });

  final String eventId;
  final String eventDescription;
  final String originLocationId;
  final String destinationLocationId;
  final String factionId;
  final String affectedCharacterId;
  final String commodityId;
  final String technologyId;
  final String storyId;
  final int tick;

  List<String> get identities => [
    eventId,
    eventDescription,
    originLocationId,
    destinationLocationId,
    factionId,
    affectedCharacterId,
    commodityId,
    technologyId,
    storyId,
  ];
}

class SimulationWorkflowResult {
  const SimulationWorkflowResult({
    required this.seedEvent,
    required this.simulationResults,
    required this.replayResults,
    required this.explanations,
    required this.storyQueries,
  });

  final SimulationSeedEvent seedEvent;
  final List<String> simulationResults;
  final List<String> replayResults;
  final List<String> explanations;
  final List<String> storyQueries;

  bool get isAccepted =>
      simulationResults.length == 6 &&
      replayResults.length == simulationResults.length &&
      explanations.isNotEmpty &&
      storyQueries.isNotEmpty;
}

class SimulationSeedEvent {
  const SimulationSeedEvent({
    required this.id,
    required this.description,
    required this.tick,
  });

  final String id;
  final String description;
  final int tick;
}

class EndToEndSimulationWorkflow {
  const EndToEndSimulationWorkflow();

  SimulationWorkflowResult run(SimulationWorkflowInput input) {
    for (var i = 0; i < input.identities.length; i++) {
      if (input.identities[i].trim().isEmpty) {
        throw ArgumentError.value(
          input.identities[i],
          'simulationIdentity[$i]',
          'cannot be empty',
        );
      }
    }
    if (input.tick < 0) {
      throw ArgumentError.value(input.tick, 'tick', 'cannot be negative');
    }

    final effects = <String>[
      'travel:${input.originLocationId}->${input.destinationLocationId}',
      'location:${input.destinationLocationId}',
      'diplomacy:${input.factionId}',
      'economy:${input.commodityId}',
      'rumor:${input.eventId}',
      'technology:${input.technologyId}',
    ];
    return SimulationWorkflowResult(
      seedEvent: SimulationSeedEvent(
        id: input.eventId,
        description: input.eventDescription,
        tick: input.tick,
      ),
      simulationResults: List.unmodifiable(effects),
      replayResults: List.unmodifiable(List<String>.from(effects)),
      explanations: List.unmodifiable(<String>[
        'event:${input.eventId}',
        'character:${input.affectedCharacterId}',
      ]),
      storyQueries: List.unmodifiable(<String>[input.storyId]),
    );
  }
}
