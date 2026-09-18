import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/offline_local_first_workflow.dart';

void main() {
  test('112.38 completes core work offline and queues optional actions', () {
    const input = OfflineWorkflowInput(
      projectId: 'offline-project',
      draft: 'A local draft.',
      analysisText: 'Check this local manuscript.',
      exportTitle: 'Offline Export',
      providerAvailable: false,
    );

    final result = const OfflineLocalFirstWorkflow().run(input);

    expect(result.offlineOpen, isTrue);
    expect(result.offlineEdit, 'A local draft. [edited offline]');
    expect(result.offlineAnalysis, contains('analysis:local'));
    expect(result.localExport, contains('Offline Export'));
    expect(result.queuedOptionalActions, contains('provider-generation'));
    expect(result.gracefulProviderFailure, contains('unavailable'));
    expect(result.isAccepted, isTrue);
  });

  test('112.38 fails closed for blank project identity', () {
    expect(
      () => const OfflineLocalFirstWorkflow().run(
        const OfflineWorkflowInput(
          projectId: ' ',
          draft: 'Draft',
          analysisText: 'Analysis',
          exportTitle: 'Export',
          providerAvailable: true,
        ),
      ),
      throwsArgumentError,
    );
  });
}
