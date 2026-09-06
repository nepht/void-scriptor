import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/workspace_layout/application/layout_preset_repository.dart';

void main() {
  test('layout repository is safe before a project session is available', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      () => container.read(layoutPresetRepositoryProvider),
      returnsNormally,
    );
  });
}
