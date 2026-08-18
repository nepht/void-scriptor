import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/intent_engine.dart';

void main() {
  group('IntentEngine', () {
    test('rejects signals without explicit consent', () {
      const engine = IntentEngine();
      final result = engine.resolve(
        signals: const [
          IntentSignal(kind: IntentInputKind.voice, value: 'buat project'),
        ],
        consent: const IntentConsent(),
      );

      expect(result.intent, CreativeIntent.unknown);
      expect(result.sourceKinds, isEmpty);
    });

    test('fuses consented multimodal signals deterministically', () {
      const engine = IntentEngine();
      final result = engine.resolve(
        signals: const [
          IntentSignal(
            kind: IntentInputKind.voice,
            value: 'buat project',
            confidence: .8,
          ),
          IntentSignal(
            kind: IntentInputKind.keyboard,
            value: 'create project',
            confidence: .7,
          ),
        ],
        consent: const IntentConsent(voice: true, keyboard: false),
      );

      expect(result.intent, CreativeIntent.create);
      expect(result.confidence, closeTo(.8, .001));
      expect(result.sourceKinds, contains(IntentInputKind.voice));
      expect(result.sourceKinds, isNot(contains(IntentInputKind.keyboard)));
    });

    test('does not predict low-confidence intent', () {
      const engine = IntentEngine();
      final result = engine.resolve(
        signals: const [
          IntentSignal(
            kind: IntentInputKind.context,
            value: 'preview',
            confidence: .2,
          ),
        ],
        consent: const IntentConsent(context: true),
      );

      expect(result.intent, CreativeIntent.unknown);
      expect(result.command, isNull);
    });

    test('routes only commands allowed by registry', () {
      const engine = IntentEngine();
      final result = engine.resolve(
        signals: const [
          IntentSignal(kind: IntentInputKind.keyboard, value: 'simpan project'),
        ],
        consent: const IntentConsent(),
        commands: const ConsentCommandRegistry({'project.save'}),
      );

      expect(result.intent, CreativeIntent.save);
      expect(result.command, 'project.save');
    });

    test('BCI remains an adapter boundary and needs consent', () {
      const bciSnapshot = [
        IntentSignal(kind: IntentInputKind.bci, value: 'preview'),
      ];
      final denied = intentEngine.resolve(
        signals: bciSnapshot,
        consent: const IntentConsent(),
      );
      final allowed = intentEngine.resolve(
        signals: bciSnapshot,
        consent: const IntentConsent(bci: true),
      );

      expect(denied.intent, CreativeIntent.unknown);
      expect(allowed.intent, CreativeIntent.preview);
      expect(bciIsExperimental, isTrue);
    });
  });
}
