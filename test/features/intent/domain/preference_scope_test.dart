import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/preference_scope.dart';

void main() {
  test('defaults to session scope and keeps values isolated by scope', () {
    final preferences = ScopedIntentPreferences();

    preferences.set('toolbar.mode', 'compact');
    preferences.set('toolbar.mode', 'wide', scope: PreferenceScope.project);

    expect(preferences.get('toolbar.mode'), 'compact');
    expect(
      preferences.get('toolbar.mode', scope: PreferenceScope.project),
      'wide',
    );
    expect(
      preferences.get('toolbar.mode', scope: PreferenceScope.global),
      isNull,
    );
  });

  test('project and global preferences can be cleared independently', () {
    final preferences = ScopedIntentPreferences();

    preferences.set('handsFree', true, scope: PreferenceScope.project);
    preferences.set('handsFree', false, scope: PreferenceScope.global);

    preferences.clear(scope: PreferenceScope.project);

    expect(
      preferences.get('handsFree', scope: PreferenceScope.project),
      isNull,
    );
    expect(preferences.get('handsFree', scope: PreferenceScope.global), false);
  });

  test('rejects blank keys', () {
    final preferences = ScopedIntentPreferences();

    expect(() => preferences.set('', true), throwsArgumentError);
    expect(() => preferences.get(' '), throwsArgumentError);
  });
}
