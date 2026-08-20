import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/agent_boundary.dart';

void main() {
  test('explains deterministic resolution without raw payload', () {
    final resolver = IntentResolutionExplainer();
    resolver.record(
      intent: 'save',
      source: 'voice',
      confidence: .9,
      rawPayload: 'secret',
    );
    expect(resolver.entries.single.reason, contains('voice'));
    expect(resolver.entries.single.rawPayload, isNull);
  });

  test('records and expands a safe natural macro', () {
    final macros = NaturalMacroRegistry();
    macros.record('saveScene', const ['save', 'preview']);
    expect(macros.expand('saveScene'), ['save', 'preview']);
  });

  test('AI is consulted only when deterministic resolution is unavailable', () {
    const policy = IntentAgentPolicy();
    expect(policy.shouldUseAi(deterministic: true), isFalse);
    expect(policy.shouldUseAi(deterministic: false), isTrue);
    expect(policy.migrateVersion('0.50', '0.51'), isTrue);
  });
}
