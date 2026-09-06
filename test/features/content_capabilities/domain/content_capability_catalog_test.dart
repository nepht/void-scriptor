import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/content_capabilities/domain/content_capability.dart';
import 'package:void_scriptor/features/content_capabilities/domain/content_capability_catalog.dart';

void main() {
  group('ContentCapabilityCatalog', () {
    test('uses stable unique ids and maps every workflow capability', () {
      final modules = ContentCapabilityCatalog.modules;

      expect(modules, isNotEmpty);
      expect(
        modules.map((module) => module.id).toSet(),
        hasLength(modules.length),
      );
      for (final module in modules) {
        expect(module.id.trim(), isNotEmpty);
        expect(module.label.trim(), isNotEmpty);
        expect(module.description.trim(), isNotEmpty);
        expect(
          module.workflowStates.keys.toSet(),
          ContentWorkflowCapability.values.toSet(),
        );
      }
    });

    test('exposes honest maturity groups and actionable gaps', () {
      final groups = ContentCapabilityCatalog.byMaturity;

      expect(groups[ContentModuleMaturity.partial], isNotEmpty);
      expect(groups[ContentModuleMaturity.domainOnly], isNotEmpty);
      expect(groups[ContentModuleMaturity.uiOnly], isNotEmpty);
      expect(groups[ContentModuleMaturity.planned], isNotEmpty);
      expect(
        ContentCapabilityCatalog.modules.every(
          (module) =>
              module.maturity == ContentModuleMaturity.full ||
              module.nextAction.trim().isNotEmpty,
        ),
        isTrue,
      );
    });

    test('search matches labels, descriptions, and capability labels', () {
      expect(
        ContentCapabilityCatalog.search('dialogue').map((item) => item.id),
        contains('dialogue'),
      );
      expect(ContentCapabilityCatalog.search('import export'), isNotEmpty);
      expect(ContentCapabilityCatalog.search('not-a-real-module'), isEmpty);
    });
  });
}
