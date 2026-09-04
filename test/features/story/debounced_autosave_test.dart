import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/story/application/debounced_autosave.dart';

void main() {
  test('debounced autosave runs only the latest scheduled save', () async {
    final autosave = DebouncedAutosave(delay: const Duration(milliseconds: 20));
    addTearDown(autosave.dispose);
    final saved = <String>[];

    autosave.schedule(() async => saved.add('old'));
    autosave.schedule(() async => saved.add('latest'));
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(saved, ['latest']);
  });
}
