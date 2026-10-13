import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/patch_regression_matrix_v114.dart';

void main() {
  group('114.35 Patch Regression Matrix', () {
    test('empty matrix is blocked without claiming patch readiness', () {
      final report = PatchRegressionMatrixRegister().evaluate();

      expect(report.status, PatchRegressionMatrixStatus.blocked);
      expect(report.executedSuiteCount, 0);
      expect(report.limitations, isNotEmpty);
    });

    test('complete matrix covers every canonical suite exactly once', () {
      final register = PatchRegressionMatrixRegister()
        ..addEntries(_completeEntries());
      final report = register.evaluate();

      expect(report.status, PatchRegressionMatrixStatus.pass);
      expect(
        report.executedSuiteNames,
        <String>[...PatchRegressionMatrix.requiredSuites]..sort(),
      );
      expect(report.missingSuites, isEmpty);
      expect(report.unexpectedSuites, isEmpty);
    });

    test('missing suite remains failed instead of being dropped', () {
      final register = PatchRegressionMatrixRegister()
        ..addEntries(
          _completeEntries().where(
            (entry) => entry.suite != PatchRegressionMatrix.suiteRecovery,
          ),
        );
      final report = register.evaluate();

      expect(report.status, PatchRegressionMatrixStatus.fail);
      expect(report.missingSuites, <String>[
        PatchRegressionMatrix.suiteRecovery,
      ]);
    });

    test('non-passing suite keeps the matrix failed with named reason', () {
      final register = PatchRegressionMatrixRegister()
        ..addEntries(
          _completeEntries()
              .map(
                (entry) => entry.suite == PatchRegressionMatrix.suiteSecurity
                    ? entry.copyWith(
                        result: PatchRegressionSuiteResult.failed,
                        evidence: const <String>[],
                        notes: 'security regression reproduced',
                      )
                    : entry,
              )
              .toList(growable: false),
        );
      final report = register.evaluate();

      expect(report.status, PatchRegressionMatrixStatus.fail);
      expect(report.failedSuites, <String>[
        PatchRegressionMatrix.suiteSecurity,
      ]);
      expect(report.limitations.join(' '), contains('security'));
    });

    test('unexecuted or evidence-free suite is never accepted', () {
      final entries = _completeEntries()
          .map(
            (entry) => entry.suite == PatchRegressionMatrix.suiteUnit
                ? entry.copyWith(
                    result: PatchRegressionSuiteResult.notRun,
                    evidence: const <String>[],
                  )
                : entry,
          )
          .toList(growable: false);
      final report = (PatchRegressionMatrixRegister()..addEntries(entries))
          .evaluate();

      expect(report.status, PatchRegressionMatrixStatus.fail);
      expect(report.notRunSuites, <String>[PatchRegressionMatrix.suiteUnit]);
    });

    test('duplicate suite and malformed evidence fail closed', () {
      final duplicate = PatchRegressionMatrixRegister()
        ..addEntries(_completeEntries())
        ..add(
          const PatchRegressionMatrixEntry(
            suite: PatchRegressionMatrix.suiteUnit,
            command: 'duplicate command',
            result: PatchRegressionSuiteResult.passed,
            evidence: <String>['duplicate evidence'],
          ),
        );
      final duplicateReport = duplicate.evaluate();

      expect(duplicateReport.status, PatchRegressionMatrixStatus.fail);
      expect(duplicateReport.limitations.join(' '), contains('duplicate'));

      final malformed = PatchRegressionMatrixRegister()
        ..add(
          const PatchRegressionMatrixEntry(
            suite: PatchRegressionMatrix.suiteUnit,
            command: '   ',
            result: PatchRegressionSuiteResult.passed,
            evidence: <String>['   '],
          ),
        );
      final malformedReport = malformed.evaluate();

      expect(malformedReport.status, PatchRegressionMatrixStatus.fail);
      expect(malformedReport.limitations.join(' '), contains('command'));
      expect(malformedReport.limitations.join(' '), contains('evidence'));
    });

    test('manifest records all canonical suites and evidence boundary', () {
      final manifest =
          json.decode(
                File(
                  'docs/planning/v1.2/sprint_114_patch_regression_matrix.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;

      expect(manifest['canonical_step'], '114.35');
      expect(manifest['required_suites'], PatchRegressionMatrix.requiredSuites);
      expect(manifest['results'], isA<List<dynamic>>());
      expect(manifest['limitations'], isNotEmpty);
    });
  });
}

List<PatchRegressionMatrixEntry> _completeEntries() {
  return <PatchRegressionMatrixEntry>[
    for (final suite in PatchRegressionMatrix.requiredSuites)
      PatchRegressionMatrixEntry(
        suite: suite,
        command: 'C:/Flutter-SDK-3.47.7/flutter/bin/flutter.bat test $suite',
        result: PatchRegressionSuiteResult.passed,
        evidence: <String>['docs/evidence/sprint-114-35-$suite.meta'],
      ),
  ];
}
