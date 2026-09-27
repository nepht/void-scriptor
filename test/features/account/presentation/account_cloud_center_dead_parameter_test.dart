// 115.53 — dead-parameter contract.
//
// `_ConnectionBadge.shrinkToFit` is declared but never passed by any call
// site. A declared-but-unused optional parameter is dead API surface: it
// advertises a behaviour the widget never implemented, and the analyzer
// reports it as `unused_element_parameter` at
// account_cloud_center_screen.dart:3632.
//
// The parameter is private, so it cannot be exercised through the widget
// tree from a test. This contract therefore pins the invariant at the
// source level: the private widget must not declare an optional parameter
// that no call site supplies. That is exactly the condition the analyzer
// lints, so a failure here predicts the analyzer warning.
//
// RED history: failed while `shrinkToFit` was still declared on
// `_ConnectionBadge` (introduced 5fe5adf, last passed in a5ed3ae, then
// orphaned). GREEN only after the parameter was removed.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('115.53 connection badge has no dead parameter', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/features/account/presentation/'
        'account_cloud_center_screen.dart',
      ).readAsStringSync();
    });

    test('the screen source still contains the badge widget', () {
      expect(
        source,
        contains('class _ConnectionBadge'),
        reason: 'test must fail loudly if the badge is renamed or removed',
      );
    });

    test('the badge declares no shrink-to-fit flag', () {
      expect(
        source,
        isNot(contains('shrinkToFit')),
        reason:
            'shrinkToFit is never passed by any call site; it is dead API '
            'surface and the analyzer flags it as unused_element_parameter',
      );
    });

    test('the badge constructor takes only parameters the widget reads', () {
      final constructor = RegExp(
        r'const _ConnectionBadge\(\{([^}]*)\}\)',
      ).firstMatch(source);
      expect(
        constructor,
        isNotNull,
        reason: '_ConnectionBadge must keep a const named constructor',
      );

      final declared = RegExp(r'this\.(\w+)')
          .allMatches(constructor!.group(1)!)
          .map((m) => m.group(1)!)
          .toSet();

      expect(declared, isNotEmpty, reason: 'constructor must take state');

      // Every declared parameter must be referenced in the class body,
      // otherwise it is an optional knob that silently does nothing.
      final classStart = source.indexOf('class _ConnectionBadge');
      expect(classStart, greaterThan(-1));
      final classBody = source.substring(classStart);

      for (final name in declared) {
        expect(
          classBody,
          contains(name),
          reason: 'parameter $name is declared but never referenced',
        );
      }
    });
  });
}
