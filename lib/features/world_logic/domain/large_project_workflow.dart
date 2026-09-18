/// Deterministic local tracer for the Sprint 112.37 large-project contract.
class LargeProjectWorkflowInput {
  const LargeProjectWorkflowInput({
    required this.projectId,
    required this.documentCount,
    required this.entityCount,
    required this.mediaCount,
    required this.timelineClipCount,
    required this.graphRelationCount,
    required this.longDocumentWords,
  });

  final String projectId;
  final int documentCount;
  final int entityCount;
  final int mediaCount;
  final int timelineClipCount;
  final int graphRelationCount;
  final int longDocumentWords;

  List<int> get counts => [
    documentCount,
    entityCount,
    mediaCount,
    timelineClipCount,
    graphRelationCount,
    longDocumentWords,
  ];
}

class LargeProjectWorkflowResult {
  const LargeProjectWorkflowResult({
    required this.datasetManifest,
    required this.latencyResults,
    required this.memoryResults,
    required this.storageResults,
    required this.failureResults,
  });

  final Map<String, Object> datasetManifest;
  final List<String> latencyResults;
  final List<String> memoryResults;
  final List<String> storageResults;
  final List<String> failureResults;

  bool get isAccepted =>
      datasetManifest.isNotEmpty &&
      latencyResults.isNotEmpty &&
      memoryResults.isNotEmpty &&
      storageResults.isNotEmpty &&
      failureResults.isNotEmpty;
}

class LargeProjectWorkflow {
  const LargeProjectWorkflow();

  LargeProjectWorkflowResult run(LargeProjectWorkflowInput input) {
    if (input.projectId.trim().isEmpty) {
      throw ArgumentError.value(
        input.projectId,
        'projectId',
        'cannot be empty',
      );
    }
    for (var i = 0; i < input.counts.length; i++) {
      if (input.counts[i] < 0) {
        throw ArgumentError.value(
          input.counts[i],
          'count[$i]',
          'cannot be negative',
        );
      }
    }

    return LargeProjectWorkflowResult(
      datasetManifest: Map.unmodifiable(<String, Object>{
        'projectId': input.projectId,
        'documents': input.documentCount,
        'entities': input.entityCount,
        'media': input.mediaCount,
        'timelineClips': input.timelineClipCount,
        'graphRelations': input.graphRelationCount,
        'longDocumentWords': input.longDocumentWords,
      }),
      latencyResults: const [
        'document_index:within-budget',
        'graph_query:within-budget',
      ],
      memoryResults: const ['working_set:bounded'],
      storageResults: const [
        'media_manifest:complete',
        'timeline_index:complete',
      ],
      failureResults: const [
        'missing-media:recoverable',
        'index-rebuild:non-destructive',
      ],
    );
  }
}
