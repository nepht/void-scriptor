import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/domain/ai_policy.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';

void main() {
  group('AiPolicy unified BYOK/context/consent contract', () {
    test('allows local generation when all gates pass', () {
      const policy = AiPolicy.byDefault();
      final result = policy.check(
        const AiPolicyCheckRequest(
          target: PromptTarget.story,
          contextSummary: 'scene draft context',
          byokReady: true,
        ),
      );
      expect(result, isA<PolicyResultAllowed>());
      final allowed = result as PolicyResultAllowed;
      expect(allowed.requiredContext, contains('scene draft context'));
    });

    test('denies external transfer without explicit consent', () {
      const policy = AiPolicy.byDefault();
      final result = policy.check(
        const AiPolicyCheckRequest(
          target: PromptTarget.story,
          contextSummary: 'ctx',
          byokReady: true,
          externalTransfer: true,
        ),
      );
      expect(result, isA<PolicyResultDenied>());
      final denied = result as PolicyResultDenied;
      expect(denied.reason, contains('consent'));
    });

    test('allows external transfer only with explicit consent', () {
      const policy = AiPolicy.byDefault();
      final result = policy.check(
        const AiPolicyCheckRequest(
          target: PromptTarget.story,
          contextSummary: 'ctx',
          byokReady: true,
          externalTransfer: true,
          externalTransferConsent: true,
        ),
      );
      expect(result, isA<PolicyResultAllowed>());
    });

    test('denies any request when BYOK credentials are missing', () {
      const policy = AiPolicy.byDefault();
      final result = policy.check(
        const AiPolicyCheckRequest(
          target: PromptTarget.story,
          contextSummary: 'ctx',
          byokReady: false,
        ),
      );
      expect(result, isA<PolicyResultDenied>());
      final denied = result as PolicyResultDenied;
      expect(denied.reason, contains('credential'));
    });

    test('denies request without any context summary', () {
      const policy = AiPolicy.byDefault();
      final result = policy.check(
        const AiPolicyCheckRequest(
          target: PromptTarget.story,
          contextSummary: '',
          byokReady: true,
        ),
      );
      expect(result, isA<PolicyResultDenied>());
      final denied = result as PolicyResultDenied;
      expect(denied.reason, contains('context'));
    });

    test('byDefault is local-only until explicit external consent', () {
      const policy = AiPolicy.byDefault();
      final local = policy.check(
        const AiPolicyCheckRequest(
          target: PromptTarget.story,
          contextSummary: 'ctx',
          byokReady: true,
        ),
      );
      final remote = policy.check(
        const AiPolicyCheckRequest(
          target: PromptTarget.story,
          contextSummary: 'ctx',
          byokReady: true,
          externalTransfer: true,
        ),
      );
      expect(local, isA<PolicyResultAllowed>());
      expect(remote, isA<PolicyResultDenied>());
    });
  });
}
