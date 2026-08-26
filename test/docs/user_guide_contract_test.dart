import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('109.49 user guide covers required operational topics', () {
    final content = File(
      'docs/user/void_scriptor_user_guide.md',
    ).readAsStringSync();
    for (final heading in <String>[
      '## Feature guides',
      '## Analisis dan batasnya',
      '## Privasi',
      '## Backup dan restore',
      '## Sharing dan export',
      '## Known limits',
      '## In-product guidance',
    ]) {
      expect(content, contains(heading));
    }
    expect(content, isNot(contains('sk-')));
    expect(content, isNot(contains('password123')));
    expect(content, contains('reference-manifest'));
    expect(content, contains('preflight'));
  });
}
