import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/marketplace/domain/ai_agent_package.dart';

void main() {
  group('AIAgentPackage', () {
    test('holds agent identity and capabilities', () {
      final pkg = AIAgentPackage(
        id: 'agent1',
        name: 'Canon Checker',
        version: '1.0.0',
        author: 'Creator Studio',
        capabilities: {'canon-validation', 'continuity-scan'},
        manifestVersion: 1,
      );
      expect(pkg.name, 'Canon Checker');
      expect(pkg.capabilities, {'canon-validation', 'continuity-scan'});
      expect(pkg.manifestVersion, 1);
    });

    test('validates capability constraints', () {
      expect(
        () => AIAgentPackage(
          id: 'agent1',
          name: 'Test',
          version: '1.0',
          author: 'X',
          capabilities: {'a', 'b', 'c', 'd', 'e', 'f'},
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('AgentCapabilityManifest', () {
    test('lists capability definitions', () {
      const manifest = AgentCapabilityManifest(
        capabilities: [
          AgentCapabilityDefinition(
            id: 'canon-validation',
            label: 'Canon Validation',
            description: 'Checks story continuity against canon rules.',
          ),
        ],
      );
      expect(manifest.capabilities.first.label, 'Canon Validation');
    });
  });
}
