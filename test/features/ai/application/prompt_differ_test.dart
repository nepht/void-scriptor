import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/application/prompt_differ.dart';

void main() {
  const differ = PromptDiffer();

  test('detects added lines', () {
    final diff = differ.diff('line1\nline2', 'line1\nline2\nline3');
    expect(diff.added, ['line3']);
    expect(diff.removed, isEmpty);
  });

  test('detects removed lines', () {
    final diff = differ.diff('a\nb\nc', 'a\nc');
    expect(diff.removed, ['b']);
    expect(diff.added, isEmpty);
  });

  test('identical text yields no diff', () {
    final diff = differ.diff('same', 'same');
    expect(diff.added, isEmpty);
    expect(diff.removed, isEmpty);
    expect(diff.changed, isFalse);
  });

  test('changed text reports changed', () {
    final diff = differ.diff('old', 'new');
    expect(diff.changed, isTrue);
  });
}
