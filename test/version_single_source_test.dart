import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/void_project_format.dart';

/// D3 (G6): pubspec.yaml is the single source of the application version.
/// VoidProjectFormat.applicationVersion must stay in lockstep with it.
void main() {
  test('VoidProjectFormat.applicationVersion matches pubspec version', () {
    final pubspec = File('pubspec.yaml').readAsLinesSync();
    final versionLine = pubspec
        .firstWhere((line) => line.startsWith('version:'))
        .trim();
    // pubspec uses "x.y.z+build"; the format constant carries x.y.z only.
    final pubspecVersion = versionLine
        .substring('version:'.length)
        .trim()
        .split('+')
        .first;

    expect(pubspecVersion, isNotEmpty);
    expect(
      VoidProjectFormat.applicationVersion,
      pubspecVersion,
      reason:
          'D3 single-source-of-truth drift: update '
          'VoidProjectFormat.applicationVersion together with pubspec.yaml.',
    );
  });
}
