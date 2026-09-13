import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/studio/domain/agent_memory_resilience.dart';

// Regression for vs-hunt-20260913-studio STU-BUG-08 (Low, Referee REAL BUG):
// ModelRouter.select used a case-sensitive exact `contains('local')` check and
// returned the static string 'local' instead of the matched registered model.
void main() {
  test(
    'matches local models case-insensitively and keeps registration order',
    () {
      final router = ModelRouter(['remote', 'Local Model']);
      expect(router.select(preferLocal: true), 'Local Model');
    },
  );

  test('returns the exact registered name for an uppercase LOCAL token', () {
    final router = ModelRouter(['remote', 'LOCAL']);
    expect(router.select(preferLocal: true), 'LOCAL');
  });

  test('exact lowercase local still resolves (existing pinned contract)', () {
    final router = ModelRouter(['local', 'remote']);
    expect(router.select(preferLocal: true), 'local');
  });

  test('preferLocal false returns the first registered model', () {
    final router = ModelRouter(['remote', 'Local Model']);
    expect(router.select(preferLocal: false), 'remote');
  });

  test('falls back to the first model when nothing matches local', () {
    final router = ModelRouter(['remote', 'cloud']);
    expect(router.select(preferLocal: true), 'remote');
  });

  test('empty catalogue returns null', () {
    expect(ModelRouter([]).select(preferLocal: true), isNull);
  });
}
