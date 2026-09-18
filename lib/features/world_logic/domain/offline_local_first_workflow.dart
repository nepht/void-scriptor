/// Deterministic local-only tracer for Sprint 112.38.
class OfflineWorkflowInput {
  const OfflineWorkflowInput({
    required this.projectId,
    required this.draft,
    required this.analysisText,
    required this.exportTitle,
    required this.providerAvailable,
  });

  final String projectId;
  final String draft;
  final String analysisText;
  final String exportTitle;
  final bool providerAvailable;
}

class OfflineWorkflowResult {
  const OfflineWorkflowResult({
    required this.offlineOpen,
    required this.offlineEdit,
    required this.offlineAnalysis,
    required this.localExport,
    required this.queuedOptionalActions,
    required this.gracefulProviderFailure,
  });

  final bool offlineOpen;
  final String offlineEdit;
  final String offlineAnalysis;
  final String localExport;
  final List<String> queuedOptionalActions;
  final String gracefulProviderFailure;

  bool get isAccepted =>
      offlineOpen &&
      offlineEdit.isNotEmpty &&
      offlineAnalysis.isNotEmpty &&
      localExport.isNotEmpty &&
      queuedOptionalActions.isNotEmpty &&
      gracefulProviderFailure.isNotEmpty;
}

class OfflineLocalFirstWorkflow {
  const OfflineLocalFirstWorkflow();

  OfflineWorkflowResult run(OfflineWorkflowInput input) {
    _require(input.projectId, 'projectId');
    _require(input.draft, 'draft');
    _require(input.analysisText, 'analysisText');
    _require(input.exportTitle, 'exportTitle');

    final providerFailure = input.providerAvailable
        ? 'provider:available'
        : 'provider:unavailable; queued locally';
    return OfflineWorkflowResult(
      offlineOpen: true,
      offlineEdit: '${input.draft} [edited offline]',
      offlineAnalysis: 'analysis:local:${input.analysisText}',
      localExport: 'title:${input.exportTitle}\n${input.draft}',
      queuedOptionalActions: input.providerAvailable
          ? const <String>[]
          : const <String>['provider-generation'],
      gracefulProviderFailure: providerFailure,
    );
  }

  static void _require(String value, String field) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, field, 'cannot be empty');
    }
  }
}
