import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Directory('test');
  final files = root
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('_test.dart'))
      .map((file) => file.path.replaceAll('\\', '/'))
      .toSet();

  test('matrix has executable coverage for every required suite', () {
    final matrix = <String, bool>{
      'unit': files.any((path) => path.contains('/domain/')),
      'integration':
          files.any((path) => path.contains('/integration/')) ||
          files.any((path) => path.contains('/persistence')),
      'contract': files.any((path) => path.contains('contract_test.dart')),
      'migration': files.any((path) => path.contains('migration')),
      'ui': files.any((path) => path.contains('/presentation/')),
      'end_to_end':
          files.any((path) => path.contains('e2e')) ||
          files.any((path) => path.contains('end_to_end')),
      'regression': files.any((path) => path.contains('regression')),
    };
    expect(matrix.values, everyElement(isTrue), reason: matrix.toString());
  });

  test('matrix names the 109.39–109.44 regression slices', () {
    expect(files, contains('test/features/export/clean_export_test.dart'));
    expect(files, contains('test/features/export/export_preflight_test.dart'));
    expect(
      files,
      contains('test/features/subplot/story_quest_model_test.dart'),
    );
    expect(files, contains('test/features/subplot/mission_board_test.dart'));
    expect(files, contains('test/features/subplot/subplot_alerts_test.dart'));
    expect(
      files,
      contains('test/features/workspaces/novel_character_link_test.dart'),
    );
    expect(
      files,
      contains('test/features/workspaces/workspace_import_service_test.dart'),
    );
  });

  test('matrix is discoverable and contains no empty test files', () {
    expect(files, isNotEmpty);
    expect(
      files.where((path) => File(path).readAsStringSync().trim().isEmpty),
      isEmpty,
    );
  });
}
