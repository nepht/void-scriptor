import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('112.32 evidence manifest covers every canonical evidence dimension', () {
    final manifest =
        jsonDecode(
              File(
                'docs/planning/v1.2/sprint_112_end_to_end_writer_workflow.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;

    expect(manifest['workflowScript'], isA<String>());
    expect(manifest['results'], isA<Map<String, dynamic>>());
    expect(manifest['screens'], isA<List<dynamic>>());
    expect(manifest['issues'], isA<List<dynamic>>());
    expect(manifest['recoveryTest'], isA<String>());
    expect(manifest['acceptance'], isA<String>());
  });
}
