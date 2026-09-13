// Regression vs-hunt-20260914-platform PLAT-BUG-05 (Referee REAL BUG, Low).
// BootstrapPlan.orderedSteps memakai sort tunggal pada `order`; Dart
// List.sort tidak dijamin stabil, sehingga langkah dengan order kembar bisa
// berpindah antar eksekusi. Kontrak: urut `order` naik, lalu `id` naik sebagai
// tie-breaker deterministik.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/platform/domain/bootstrap.dart';

BootstrapStep _step(String id, int order) =>
    BootstrapStep(id: id, name: 'Step $id', order: order, required: true);

void main() {
  group('BootstrapPlan.orderedSteps deterministic tie-breaker', () {
    test('equal order resolves by id ascending, not insertion order', () {
      // Input disengaja terbalik dari urutan id supaya tie-breaker wajib
      // bekerja; tanpa tie-breaker, sort yang stabil akan meloloskan z,a.
      final plan = BootstrapPlan(
        id: 'p1',
        steps: [_step('zeta', 1), _step('alpha', 1), _step('mike', 1)],
      );

      expect(plan.orderedSteps.map((s) => s.id).toList(), [
        'alpha',
        'mike',
        'zeta',
      ]);
    });

    test('order remains the primary key', () {
      final plan = BootstrapPlan(
        id: 'p2',
        steps: [_step('late', 9), _step('early', 1), _step('middle', 5)],
      );

      expect(plan.orderedSteps.map((s) => s.id).toList(), [
        'early',
        'middle',
        'late',
      ]);
    });

    test('mixed duplicates are fully deterministic', () {
      final plan = BootstrapPlan(
        id: 'p3',
        steps: [_step('b2', 2), _step('a9', 1), _step('a1', 2), _step('b1', 1)],
      );

      expect(plan.orderedSteps.map((s) => s.id).toList(), [
        'a9',
        'b1',
        'a1',
        'b2',
      ]);
    });

    test('repeated calls return the same sequence', () {
      final plan = BootstrapPlan(
        id: 'p4',
        steps: [_step('c', 1), _step('a', 1), _step('b', 1)],
      );

      expect(
        plan.orderedSteps.map((s) => s.id).toList(),
        plan.orderedSteps.map((s) => s.id).toList(),
      );
    });

    test('source steps list is never mutated', () {
      final steps = [_step('z', 2), _step('a', 1)];
      final plan = BootstrapPlan(id: 'p5', steps: steps);

      plan.orderedSteps;

      expect(steps.map((s) => s.id).toList(), ['z', 'a']);
    });
  });
}
