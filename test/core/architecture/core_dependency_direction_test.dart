import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Sprint 145.19 — Core Dependency Direction.
///
/// Canonical direction: Network may depend on Cloud and Core; Cloud may
/// depend on Core; Core depends on neither Cloud nor Network. In this
/// repository Core lives in `lib/core`, and feature layers (including the
/// Cloud/Network feature families) live in `lib/features`.
///
/// This gate rejects every production `lib/core` import or export that
/// reaches into `lib/features`, so Core cannot regress into depending on
/// feature-owned layers.
void main() {
  test('lib/core does not import or export lib/features', () {
    final coreRoot = Directory('lib/core');
    expect(coreRoot.existsSync(), isTrue, reason: 'lib/core must exist');

    final violations = <String>[];
    final pattern = RegExp(
      r'''^\s*(?:import|export)\s+['"](?:(?:package:void_scriptor/)|((?:\.\./)+))(features/)[^'"]+['"]''',
    );

    for (final entity in coreRoot.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalizedPath = entity.path.replaceAll(
        Platform.pathSeparator,
        '/',
      );
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final match = pattern.firstMatch(lines[i]);
        if (match != null) {
          violations.add('$normalizedPath:${i + 1}: ${lines[i].trim()}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Core must not depend on feature layers (Network/Cloud/Core '
          'direction). Violations:\n${violations.join('\n')}',
    );
  });
}
