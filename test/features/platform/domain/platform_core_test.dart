import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/platform/domain/feature_registry.dart';
import 'package:void_scriptor/features/platform/domain/bootstrap.dart';

void main() {
  group('FeatureEntry', () {
    test('holds feature readiness', () {
      const f = FeatureEntry(
        id: 'fe1',
        name: 'Creator Platform',
        status: FeatureStatus.ready,
      );
      expect(f.name, 'Creator Platform');
      expect(f.status, FeatureStatus.ready);
    });
  });

  group('FeatureStatus', () {
    test('exposes statuses in order', () {
      expect(FeatureStatus.values.map((e) => e.name), [
        'frozen',
        'inProgress',
        'ready',
        'verified',
        'released',
      ]);
    });
  });

  group('BootstrapStep', () {
    test('holds startup order', () {
      const step = BootstrapStep(
        id: 'bs1',
        name: 'load-schema',
        order: 1,
        required: true,
      );
      expect(step.order, 1);
      expect(step.required, isTrue);
    });
  });

  group('EventScope', () {
    test('exposes event scopes', () {
      expect(EventScope.values.map((e) => e.name), [
        'global',
        'project',
        'session',
        'local',
      ]);
    });
  });

  group('ModuleBoundary', () {
    test('holds module dependency', () {
      const m = ModuleBoundary(
        id: 'mb1',
        module: 'creator',
        dependsOn: ['core', 'ai'],
      );
      expect(m.dependsOn, contains('core'));
    });
  });
}
