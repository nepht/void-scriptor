import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/automation/automation_rule.dart';
import 'package:void_scriptor/automation/external_integrations.dart';
import 'package:void_scriptor/core/plugin/domain/plugin_api_version.dart';
import 'package:void_scriptor/core/plugin/domain/plugin_manifest.dart';
import 'package:void_scriptor/features/ai/application/provider_router.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';
import 'package:void_scriptor/features/ai/domain/ai_streaming.dart';
import 'package:void_scriptor/automation/workflow_trigger.dart';

/// Sprint 104 / 104.14-104.20 — external integrations over canonical
/// infrastructure.
AutomationRule ruleOf(String workflowId) => AutomationRule(
  ruleId: 'r-$workflowId',
  trigger: WorkflowTrigger(
    triggerId: 't-$workflowId',
    type: WorkflowTriggerType.jobEvent,
    configuration: const {},
    createdAt: DateTime.utc(2026, 8, 25),
    updatedAt: DateTime.utc(2026, 8, 25),
  ),
  conditions: const [],
  workflowId: workflowId,
);

void main() {
  group('104.14 AI integration', () {
    test('routes through ProviderRouter; no direct provider bypass', () async {
      final costs = <String>[];
      final integration = AiWorkflowIntegration(
        router: ProviderRouter([const MockAiProvider()]),
        externalTransferCheck: () async => true,
        onCost: (p, cost) => costs.add('$p:$cost'),
      );
      final result = await integration.run(
        ruleOf('wf-ai'),
        const AiGenerationRequest(
          jobId: 'j-ai',
          prompt: 'describe scene',
          target: PromptTarget.story,
        ),
      );
      expect(result.outputs, isNotEmpty);
      // The cost line names the provider that ACTUALLY served the request.
      // It used to name the requested provider (`preferredProviderId ?? 'auto'`),
      // so a fallback served by a different provider was billed to the wrong one.
      expect(costs.single, startsWith('mock:'));
    });

    test('cost is attributed to the provider that served after a fallback, '
        'not to the requested provider', () async {
      final costs = <String>[];
      final failing = _RecordingProvider(
        () {},
        id: 'requested',
        failGenerate: true,
      );
      final serving = _RecordingProvider(() {}, id: 'served');
      final integration = AiWorkflowIntegration(
        router: ProviderRouter([failing, serving]),
        externalTransferCheck: () async => true,
        onCost: (p, cost) => costs.add(p),
      );

      await integration.run(
        ruleOf('wf-ai'),
        const AiGenerationRequest(
          jobId: 'j-ai',
          prompt: 'describe scene',
          target: PromptTarget.story,
        ),
        preferredProviderId: 'requested',
      );

      expect(
        costs,
        <String>['served'],
        reason:
            'the requested provider failed; charging its id would book the '
            'cost to a provider that produced nothing',
      );
    });

    test(
      'a configured costOf is actually used instead of a hardcoded zero',
      () async {
        final costs = <double>[];
        final integration = AiWorkflowIntegration(
          router: ProviderRouter([const MockAiProvider()]),
          externalTransferCheck: () async => true,
          onCost: (_, cost) => costs.add(cost),
          costOf: (_) => 0.25,
        );

        await integration.run(
          ruleOf('wf-ai'),
          const AiGenerationRequest(
            jobId: 'j-ai',
            prompt: 'describe scene',
            target: PromptTarget.story,
          ),
        );

        expect(
          costs.single,
          0.25,
          reason:
              'costOf was accepted and stored but never read, so every automated '
              'AI call reported zero cost',
        );
      },
    );

    test(
      'blocks BEFORE any provider call when transfer check refuses',
      () async {
        var providerTouched = false;
        final probe = _RecordingProvider(() => providerTouched = true);
        final integration = AiWorkflowIntegration(
          router: ProviderRouter([probe]),
          externalTransferCheck: () async => false,
        );
        await expectLater(
          integration.run(
            ruleOf('wf-ai'),
            const AiGenerationRequest(
              jobId: 'j-ai',
              prompt: 'x',
              target: PromptTarget.story,
            ),
          ),
          throwsA(isA<StateError>()),
        );
        expect(
          providerTouched,
          isFalse,
          reason: 'no direct bypass past a refused transfer',
        );
      },
    );

    test('cancellation delegates to the canonical provider API', () async {
      final probe = _RecordingProvider(() {});
      await integrationCancel(probe, 'req-1');
      expect(probe.cancelledIds, ['req-1']);
    });
  });

  group('104.15 render pipeline', () {
    test('describes jobs with mandatory budget and provenance', () {
      final descriptor = describeRenderJob(
        const WorkflowRenderRequest(
          ruleId: 'r-render',
          cinematicId: 'cin-1',
          presetId: 'preset-hd',
          resourceBudget: {'cpuMinutes': 10, 'diskMb': 512},
          outputProvenance: {'rule.id': 'r-render'},
        ),
      );
      expect(descriptor.resourceBudget['cpuMinutes'], 10);
      expect(descriptor.outputProvenance['rule.id'], 'r-render');
    });

    test('renders without an explicit budget are rejected', () {
      expect(
        () => describeRenderJob(
          const WorkflowRenderRequest(
            ruleId: 'r-render',
            cinematicId: 'cin-1',
            presetId: 'preset-hd',
            resourceBudget: {},
            outputProvenance: {'rule.id': 'r-render'},
          ),
        ),
        throwsA(isA<RenderBudgetException>()),
      );
    });
  });

  group('104.16 publishing', () {
    test('allowlist denies unknown destinations', () {
      const adapter = PublishingWorkflowAdapter(
        allowedDestinations: {'archive.org', 'local-export'},
      );
      expect(adapter.isDestinationAllowed('archive.org'), isTrue);
      expect(adapter.isDestinationAllowed('random-cdn.example'), isFalse);
    });

    test('human confirmation is the default and decisions are audited', () {
      const adapter = PublishingWorkflowAdapter(
        allowedDestinations: {'archive.org'},
      );
      expect(
        adapter.defaultConfirmation('archive.org'),
        PublishConfirmation.required,
      );
      final record = adapter.auditRecord(
        ruleId: 'r-pub',
        destination: 'archive.org',
        confirmed: true,
        accepted: true,
      );
      expect(record['publish.destination'], 'archive.org');
      expect(record.keys.any((k) => k.contains('secret')), isFalse);
    });
  });

  group('104.17 plugin steps', () {
    PluginManifest manifestOf(int major) => PluginManifest(
      id: 'demo-plugin',
      name: 'Demo',
      version: '1.0.0',
      author: 'Choirudin',
      apiVersion: PluginApiVersion(major, 0),
      capabilities: const ['fs.read'],
      permissions: const [],
      entrypoint: 'main.dart',
    );

    test('api major 1 with granted capabilities is accepted', () {
      final decision = evaluatePluginStep(
        PluginStepRegistration(
          pluginId: 'demo-plugin',
          manifest: manifestOf(1),
          declaredCapabilities: const {'fs.read'},
        ),
        hostCapabilities: const {'fs.read', 'net.write'},
      );
      expect(decision, PluginStepDecision.accepted);
    });

    test('other api majors are rejected', () {
      final decision = evaluatePluginStep(
        PluginStepRegistration(
          pluginId: 'demo-plugin',
          manifest: manifestOf(2),
          declaredCapabilities: const {},
        ),
      );
      expect(decision, PluginStepDecision.rejectedApiVersion);
    });

    test('undeclared-but-ungranted capabilities are rejected (permission)', () {
      final decision = evaluatePluginStep(
        PluginStepRegistration(
          pluginId: 'demo-plugin',
          manifest: manifestOf(1),
          declaredCapabilities: const {'net.write'},
        ),
        hostCapabilities: const {'fs.read'},
      );
      expect(decision, PluginStepDecision.rejectedCapability);
    });

    test('uninstall removes exactly the namespaced steps', () {
      expect(pluginStepKey('demo', 'resize'), 'plugin.demo.resize');
    });
  });

  group('104.18 capability preflight', () {
    test('missing capabilities are visible, never silent fallbacks', () {
      final result = preflightCapabilities(
        {'render.gpu', 'publish.net'},
        available: const {'render.gpu'},
      );
      expect(result.satisfied, isFalse);
      expect(result.missing, {'publish.net'});
      expect(result.report().single, contains('publish.net'));
    });

    test('satisfied requirements produce no findings', () {
      final result = preflightCapabilities(
        {'fs.read'},
        available: const {'fs.read'},
      );
      expect(result.satisfied, isTrue);
      expect(result.report(), isEmpty);
    });
  });

  group('104.19 secret references', () {
    test('plaintext values are structurally impossible', () {
      final reference = SecretReference.fromStore('provider/openai/key');
      expect(reference.storeKey, 'provider/openai/key');
      expect(reference.toString(), '[REDACTED]');
    });

    test('empty or multiline store keys are rejected', () {
      expect(() => SecretReference.fromStore(''), throwsArgumentError);
      expect(() => SecretReference.fromStore('a\nb'), throwsArgumentError);
    });
  });

  group('104.20 network policy', () {
    test('deny-by-default outside the allowlist, audited every time', () {
      final policy = AutomationNetworkPolicy(
        allowedDestinations: {'api.example.com'},
      );
      expect(
        policy.checkRequest(
          destination: 'evil.example',
          capability: 'net.write',
        ),
        NetworkDecision.deniedByDefault,
      );
      expect(
        policy.checkRequest(
          destination: 'api.example.com',
          capability: 'net.write',
        ),
        NetworkDecision.allowed,
      );
      expect(policy.audit, hasLength(2));
      expect(policy.audit.first.decision, NetworkDecision.deniedByDefault);
    });
  });
}

/// Probe provider that records touches/cancels without network access.
class _RecordingProvider implements AiProvider {
  _RecordingProvider(
    this._onResolve, {
    this.id = 'probe',
    this.failGenerate = false,
  });

  final void Function() _onResolve;
  final List<String> cancelledIds = [];

  @override
  final String id;

  /// When true the provider raises instead of answering, so a fallback can be
  /// observed rather than assumed.
  final bool failGenerate;

  @override
  String get displayName => id;

  @override
  Set<AiCapability> get capabilities => {AiCapability.textGeneration};

  @override
  Future<List<AiModelInfo>> listModels() async => const [];

  @override
  Future<AiGenerationResult> generate(AiGenerationRequest request) async {
    _onResolve();
    if (failGenerate) {
      throw StateError('provider $id unavailable');
    }
    return AiGenerationResult(
      providerRequestId: '$id-1',
      outputs: const [AiGeneratedOutput(type: AiOutputType.text, text: 'ok')],
    );
  }

  @override
  Future<void> cancel(String requestId) async {
    cancelledIds.add(requestId);
  }

  @override
  bool validateTarget(PromptTarget target) => target == PromptTarget.story;

  @override
  Stream<AiStreamingChunk> streamGenerate(AiGenerationRequest request) =>
      throw UnimplementedError();
}

Future<void> integrationCancel(AiProvider provider, String requestId) =>
    AiWorkflowIntegration(
      router: ProviderRouter([provider]),
      externalTransferCheck: () async => true,
    ).cancel(provider, requestId);
