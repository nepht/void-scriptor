import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/application/sprint_119_ai_connector_interface.dart';

void main() {
  final textModel = AiModelDescriptor(
    ref: AiModelRef.tryParse('modelref:vendor:chat-large')!,
    modalities: const <AiModality>{AiModality.text, AiModality.image},
    supportsStreaming: true,
    supportsCancellation: true,
    contextWindowTokens: 128000,
  );
  final batchModel = AiModelDescriptor(
    ref: AiModelRef.tryParse('modelref:vendor:batch-small')!,
    modalities: const <AiModality>{AiModality.text},
    supportsStreaming: false,
    supportsCancellation: false,
    contextWindowTokens: 8000,
  );
  final allPermissions = <AiPermission>{
    AiPermission.listModels,
    AiPermission.execute,
    AiPermission.stream,
    AiPermission.cancel,
  };

  group('119.14 AI Connector Interface', () {
    test('model references are opaque and malformed values are rejected', () {
      final ref = AiModelRef.tryParse('modelref:vendor:chat-large');
      expect(ref, isNotNull);
      expect(ref!.value, 'modelref:vendor:chat-large');
      expect(ref.toString(), '[REDACTED]');
      expect(AiModelRef.tryParse('vendor/chat-large'), isNull);
      expect(AiModelRef.tryParse('storageref:drive:primary'), isNull);
    });

    test('listModels filters by required modalities only', () {
      final models = AiConnectorInterface.listModels(
        <AiModelDescriptor>[textModel, batchModel],
        requiredModalities: const <AiModality>{AiModality.image},
      );

      expect(models, hasLength(1));
      expect(models.single.ref.value, 'modelref:vendor:chat-large');

      final none = AiConnectorInterface.listModels(
        <AiModelDescriptor>[batchModel],
        requiredModalities: const <AiModality>{AiModality.video},
      );
      expect(none, isEmpty);
    });

    test(
      'execute is denied without its permission or an explicit destination',
      () {
        expect(
          AiConnectorInterface.execute(
            model: textModel.ref,
            destination: AiDataDestination.providerOnly,
            granted: <AiPermission>{AiPermission.listModels},
          ),
          AiOperationResult.deniedMissingPermission,
        );
        expect(
          AiConnectorInterface.execute(
            model: textModel.ref,
            destination: AiDataDestination.unknown,
            granted: allPermissions,
          ),
          AiOperationResult.deniedUnknownDestination,
        );
        expect(
          AiConnectorInterface.execute(
            model: null,
            destination: AiDataDestination.providerOnly,
            granted: allPermissions,
          ),
          AiOperationResult.deniedUnknownModel,
        );
        expect(
          AiConnectorInterface.execute(
            model: textModel.ref,
            destination: AiDataDestination.providerOnly,
            granted: allPermissions,
          ),
          AiOperationResult.ok,
        );
      },
    );

    test('stream is denied for models without streaming support', () {
      expect(
        AiConnectorInterface.stream(
          model: batchModel,
          destination: AiDataDestination.providerOnly,
          granted: allPermissions,
        ),
        AiOperationResult.unknownOperation,
      );
      expect(
        AiConnectorInterface.stream(
          model: textModel,
          destination: AiDataDestination.unknown,
          granted: allPermissions,
        ),
        AiOperationResult.deniedUnknownDestination,
      );
      expect(
        AiConnectorInterface.stream(
          model: textModel,
          destination: AiDataDestination.providerOnly,
          granted: allPermissions,
        ),
        AiOperationResult.ok,
      );
    });

    test(
      'cancel fails closed without reauthentication and when unsupported',
      () {
        expect(
          AiConnectorInterface.cancel(model: textModel, reauthenticated: false),
          AiOperationResult.deniedMissingPermission,
        );
        expect(
          AiConnectorInterface.cancel(model: textModel, reauthenticated: true),
          AiOperationResult.ok,
        );
        expect(
          AiConnectorInterface.cancel(model: batchModel, reauthenticated: true),
          AiOperationResult.unknownOperation,
        );
      },
    );

    test(
      'stream chunks must be strictly ordered and end with one final chunk',
      () {
        expect(
          AiConnectorInterface.isOrderedStream(<AiStreamChunk>[
            const AiStreamChunk(sequence: 1),
            const AiStreamChunk(sequence: 2),
            const AiStreamChunk(sequence: 3, isFinal: true),
          ]),
          isTrue,
        );
        expect(
          AiConnectorInterface.isOrderedStream(<AiStreamChunk>[
            const AiStreamChunk(sequence: 1),
            const AiStreamChunk(sequence: 3, isFinal: true),
            const AiStreamChunk(sequence: 4),
          ]),
          isFalse,
        );
        expect(
          AiConnectorInterface.isOrderedStream(<AiStreamChunk>[
            const AiStreamChunk(sequence: 2, isFinal: true),
            const AiStreamChunk(sequence: 1),
          ]),
          isFalse,
        );
        expect(
          AiConnectorInterface.isOrderedStream(<AiStreamChunk>[
            const AiStreamChunk(sequence: 1),
          ]),
          isFalse,
        );
        expect(
          AiConnectorInterface.isOrderedStream(const <AiStreamChunk>[]),
          isFalse,
        );
      },
    );

    test('cost metadata is validated and never carries a credential', () {
      const cost = AiCostMetadata(
        currency: 'USD',
        unitLabel: 'per_1k_tokens',
        unitCost: 0.002,
        isEstimate: true,
      );
      expect(AiConnectorInterface.validateCost(cost), isEmpty);

      expect(
        AiConnectorInterface.validateCost(
          const AiCostMetadata(
            currency: 'usd',
            unitLabel: 'per_1k_tokens',
            unitCost: 0.002,
            isEstimate: false,
          ),
        ),
        contains('currency_not_iso4217'),
      );
      expect(
        AiConnectorInterface.validateCost(
          const AiCostMetadata(
            currency: 'USD',
            unitLabel: 'per_1k_tokens',
            unitCost: -1,
            isEstimate: false,
          ),
        ),
        contains('unit_cost_negative'),
      );
      expect(
        AiConnectorInterface.validateCost(
          const AiCostMetadata(
            currency: 'USD',
            unitLabel: '',
            unitCost: 0.002,
            isEstimate: false,
          ),
        ),
        contains('unit_label_missing'),
      );
    });

    test('model descriptor serialization redacts the model reference', () {
      final json = textModel.toJson();
      expect(json['model_ref'], '[REDACTED]');
      expect(json['supports_streaming'], isTrue);
      expect(json['context_window_tokens'], 128000);
      expect(json.toString(), isNot(contains('modelref:vendor:chat-large')));
      expect(json['modalities'], contains('text'));
    });

    test('health reports unavailable, degraded, and ok deterministically', () {
      expect(
        AiConnectorInterface.health(
          reachable: false,
          authorized: true,
          withinQuota: true,
        ),
        AiHealthStatus.unavailable,
      );
      expect(
        AiConnectorInterface.health(
          reachable: true,
          authorized: true,
          withinQuota: false,
        ),
        AiHealthStatus.degraded,
      );
      expect(
        AiConnectorInterface.health(
          reachable: true,
          authorized: true,
          withinQuota: true,
        ),
        AiHealthStatus.ok,
      );
    });

    test('diagnostics redact opaque references', () {
      expect(
        AiConnectorInterface.redact('model modelref:vendor:chat-large failed'),
        'model [REDACTED] failed',
      );
    });

    test('validates the canonical manifest and rejects missing methods', () {
      expect(AiConnectorInterface.validateCanonicalManifest(), isEmpty);

      final missing = <String, dynamic>{
        'canonical_step': '119.14',
        'unknown_field_policy': 'REJECT',
        'required_methods': <String>['list_models'],
        'acceptance': <String, dynamic>{},
      };
      expect(
        AiConnectorInterface.validateManifest(missing),
        containsAll(<String>[
          'method_missing:execute',
          'method_missing:cost_metadata',
          'method_missing:health',
          'acceptance_missing:destination',
        ]),
      );
      expect(
        AiConnectorInterface.validateManifest(<String, dynamic>{
          'canonical_step': '119.13',
          'unknown_field_policy': 'ALLOW',
        }),
        containsAll(<String>[
          'canonical_step_invalid',
          'unknown_field_policy_invalid',
        ]),
      );
    });
  });
}
