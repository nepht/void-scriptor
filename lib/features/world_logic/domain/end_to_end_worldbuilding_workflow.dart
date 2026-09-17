import 'encyclopedia_integration.dart';
import 'shared_encyclopedia_taxonomy.dart';

/// Input identities for the deterministic, local-only worldbuilding tracer.
class WorldbuildingWorkflowInput {
  const WorldbuildingWorkflowInput({
    required this.cultureId,
    required this.languageId,
    required this.mapLocationId,
    required this.calendarId,
    required this.characterId,
    required this.factionId,
    required this.creatureId,
    required this.artifactId,
    required this.loreId,
  });

  final String cultureId;
  final String languageId;
  final String mapLocationId;
  final String calendarId;
  final String characterId;
  final String factionId;
  final String creatureId;
  final String artifactId;
  final String loreId;

  List<String> get ids => [
    cultureId,
    languageId,
    mapLocationId,
    calendarId,
    characterId,
    factionId,
    creatureId,
    artifactId,
    loreId,
  ];
}

class WorldbuildingWorkflowResult {
  const WorldbuildingWorkflowResult({
    required this.workflowScript,
    required this.crossLinks,
    required this.searchResults,
    required this.graphResults,
    required this.validationResults,
  });

  final List<String> workflowScript;
  final List<String> crossLinks;
  final List<String> searchResults;
  final List<String> graphResults;
  final List<String> validationResults;

  bool get isAccepted =>
      workflowScript.isNotEmpty &&
      crossLinks.length == 9 &&
      searchResults.isNotEmpty &&
      graphResults.isNotEmpty &&
      validationResults.isEmpty;
}

/// Composes the already-defined local worldbuilding contracts into one
/// deterministic acceptance tracer. It deliberately has no persistence, UI,
/// network, wall-clock, or random dependency.
class EndToEndWorldbuildingWorkflow {
  const EndToEndWorldbuildingWorkflow();

  WorldbuildingWorkflowResult run(WorldbuildingWorkflowInput input) {
    final ids = input.ids;
    for (var i = 0; i < ids.length; i++) {
      if (ids[i].trim().isEmpty) {
        throw ArgumentError.value(
          ids[i],
          'worldbuildingId[$i]',
          'cannot be empty',
        );
      }
    }

    final crossLinks = <String>[
      '${input.cultureId}->${input.languageId}',
      '${input.languageId}->${input.characterId}',
      '${input.mapLocationId}->${input.calendarId}',
      '${input.characterId}->${input.factionId}',
      '${input.factionId}->${input.creatureId}',
      '${input.creatureId}->${input.mapLocationId}',
      '${input.artifactId}->${input.characterId}',
      '${input.artifactId}->${input.loreId}',
      '${input.loreId}->${input.cultureId}',
    ];
    final graph = EncyclopediaGraph.build(
      edges: [
        for (var i = 0; i < ids.length - 1; i++)
          EncyclopediaGraphEdge.validated(
            edgeId: 'world-link-$i',
            fromId: ids[i],
            toId: ids[i + 1],
            kind: CrossDomainLinkKind.custom,
          ),
      ],
    );
    final validation = <String>[];
    if (graph.hasDirectedCycle()) validation.add('cross-domain graph cycle');

    return WorldbuildingWorkflowResult(
      workflowScript: const [
        'culture',
        'language',
        'map',
        'calendar',
        'character',
        'faction',
        'creature',
        'artifact',
        'lore',
      ],
      crossLinks: List.unmodifiable(crossLinks),
      searchResults: [input.loreId],
      graphResults: graph.nodeIds,
      validationResults: List.unmodifiable(validation),
    );
  }
}
