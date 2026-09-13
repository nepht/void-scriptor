// Regression: vs-hunt-20260914-platform PLAT-BUG-02 (Medium).
// ModuleBoundary.hasCircularDependency only inspected immediate back-edges
// (A -> B -> A) and missed transitive cycles of length 3+.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/platform/domain/feature_registry.dart';

void main() {
  group('ModuleBoundary.hasCircularDependency transitive cycles', () {
    test('detects a 3-node cycle A -> B -> C -> A', () {
      const a = ModuleBoundary(id: 'a', module: 'A', dependsOn: ['B']);
      const b = ModuleBoundary(id: 'b', module: 'B', dependsOn: ['C']);
      const c = ModuleBoundary(id: 'c', module: 'C', dependsOn: ['A']);
      final all = {'A': a, 'B': b, 'C': c};

      expect(a.hasCircularDependency(all), isTrue);
      expect(b.hasCircularDependency(all), isTrue);
      expect(c.hasCircularDependency(all), isTrue);
    });

    test('detects a self-dependency cycle A -> A', () {
      const a = ModuleBoundary(id: 'a', module: 'A', dependsOn: ['A']);
      final all = {'A': a};

      expect(a.hasCircularDependency(all), isTrue);
    });

    test('keeps detecting the direct 2-node cycle A -> B -> A', () {
      const a = ModuleBoundary(id: 'a', module: 'A', dependsOn: ['B']);
      const b = ModuleBoundary(id: 'b', module: 'B', dependsOn: ['A']);
      final all = {'A': a, 'B': b};

      expect(a.hasCircularDependency(all), isTrue);
    });

    test('diamond without a cycle reports no circular dependency', () {
      const a = ModuleBoundary(id: 'a', module: 'A', dependsOn: ['B', 'C']);
      const b = ModuleBoundary(id: 'b', module: 'B', dependsOn: ['D']);
      const c = ModuleBoundary(id: 'c', module: 'C', dependsOn: ['D']);
      const d = ModuleBoundary(id: 'd', module: 'D');
      final all = {'A': a, 'B': b, 'C': c, 'D': d};

      expect(a.hasCircularDependency(all), isFalse);
      expect(b.hasCircularDependency(all), isFalse);
      expect(d.hasCircularDependency(all), isFalse);
    });

    test('cycle in a disconnected branch does not mark a clean module', () {
      const a = ModuleBoundary(id: 'a', module: 'A', dependsOn: ['B']);
      const b = ModuleBoundary(id: 'b', module: 'B');
      const x = ModuleBoundary(id: 'x', module: 'X', dependsOn: ['Y']);
      const y = ModuleBoundary(id: 'y', module: 'Y', dependsOn: ['X']);
      final all = {'A': a, 'B': b, 'X': x, 'Y': y};

      expect(a.hasCircularDependency(all), isFalse);
      expect(x.hasCircularDependency(all), isTrue);
    });

    test('missing dependency nodes are ignored without throwing', () {
      const a = ModuleBoundary(id: 'a', module: 'A', dependsOn: ['ghost']);
      final all = {'A': a};

      expect(a.hasCircularDependency(all), isFalse);
    });
  });
}
