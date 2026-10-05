/// Sprint 115.51 — Automated Test Matrix.
///
/// Locks the ten canonical `required_suites` of step 115.51, proves the
/// matrix contract is fail-closed (unknown suite, missing suite, a `pass`
/// without real evidence, a command that leaves the absolute toolchain, a
/// `blocked`/`pending` suite that pretends to have run), then grounds the
/// committed manifest in the live repository:
///
/// * every suite command must cite the absolute Flutter toolchain;
/// * every evidence path must exist and must really contain tests;
/// * the aggregate `regression` suite must cover the roots every other
///   suite cites, so no suite can claim coverage outside the regression;
/// * the matrix must report its own test file as covered;
/// * the manifest verdict must equal the verdict derived from the recorded
///   statuses, so a summary line can never disagree with its rows.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_automated_test_matrix.dart';
import '../../../canonical_source_support.dart';

void main() {
  const canonicalSprintPath =
      'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/'
      'sprint_115.json';
  const canonicalSprintSha256 =
      'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba';
  const matrixTestPath =
      'test/features/account/domain/'
      'account_center_automated_test_matrix_test.dart';
  const regressionRoots = <String>[
    'test/features/account',
    'test/app',
    'test/release/sprint_115_entry_gate_test.dart',
    'test/release/sprint_115_readiness_gate_test.dart',
  ];

  final manifestFile = File(
    'docs/planning/v1.2/sprint_115_automated_test_matrix.json',
  );

  Map<String, dynamic> readManifest() {
    expect(manifestFile.existsSync(), isTrue, reason: '115.51 manifest');
    return jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  }

  /// Builds one suite result. Executed tests default to zero so a synthetic
  /// `blocked`/`pending` row cannot accidentally claim a run; passing rows
  /// pass their own counts.
  AccountTestSuiteResult result({
    String suite = 'unit',
    AccountTestSuiteStatus status = AccountTestSuiteStatus.pass,
    String command =
        'D:/DevTools/Flutter SDK/flutter/bin/flutter.bat test '
        'test/features/account/domain',
    List<String> evidence = const <String>['test/features/account/domain'],
    int tests = 0,
    String note = '',
  }) => AccountTestSuiteResult(
    suite: suite,
    status: status,
    command: command,
    evidence: evidence,
    tests: tests,
    note: note,
  );

  /// A matrix in which every canonical suite passes with executed tests.
  Map<String, AccountTestSuiteResult> fullPassMatrix({
    String? replaceSuite,
    AccountTestSuiteResult? withResult,
  }) => <String, AccountTestSuiteResult>{
    for (final suite in AccountCenterAutomatedTestMatrix.requiredSuites)
      suite: (replaceSuite == suite && withResult != null)
          ? withResult
          : result(suite: suite, tests: 4),
  };

  group('115.51 canonical suite set', () {
    test('locks the ten canonical suites in spec order', () {
      expect(AccountCenterAutomatedTestMatrix.requiredSuites, const <String>[
        'unit',
        'state_machine',
        'contract',
        'connector',
        'security',
        'billing',
        'ui',
        'accessibility',
        'end_to_end',
        'regression',
      ]);
    });

    test('matches required_suites of step 115.51 in sprint_115.json', () {
      if (skipUnlessExternalCanonical(
        "matches required_suites of step 115.51 in sprint_115.json",
      )) {
        return;
      }
      final file = File(canonicalSprintPath);
      expect(file.existsSync(), isTrue, reason: 'canonical sprint_115.json');
      expect(
        sha256.convert(file.readAsBytesSync()).toString(),
        canonicalSprintSha256,
        reason: 'canonical sprint hash drift',
      );
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final steps = document['steps'] as List<dynamic>;
      final step = steps.cast<Map<String, dynamic>>().firstWhere(
        (entry) => entry['id'] == '115.51',
      );
      expect(step['title'], 'Automated Test Matrix');
      expect(
        step['required_suites'],
        AccountCenterAutomatedTestMatrix.requiredSuites,
        reason: 'required_suites must be transcribed, not invented',
      );
    });

    test('rejects a suite outside the canonical set', () {
      expect(
        () => AccountCenterAutomatedTestMatrix.buildReport({
          for (final suite in AccountCenterAutomatedTestMatrix.requiredSuites)
            suite: result(suite: suite),
          'property': result(suite: 'property'),
        }),
        throwsArgumentError,
      );
    });

    test('rejects a canonical suite that was never recorded', () {
      final incomplete = fullPassMatrix()..remove('end_to_end');
      expect(
        () => AccountCenterAutomatedTestMatrix.buildReport(incomplete),
        throwsStateError,
      );
    });

    test('rejects a row whose key does not match its suite', () {
      expect(
        () => AccountCenterAutomatedTestMatrix.buildReport({
          for (final suite in AccountCenterAutomatedTestMatrix.requiredSuites)
            suite: result(suite: suite == 'unit' ? 'billing' : suite),
        }),
        throwsArgumentError,
      );
    });
  });

  group('115.51 fail-closed suite rules', () {
    test('rejects a pass with zero executed tests', () {
      expect(
        () => AccountCenterAutomatedTestMatrix.buildReport(
          fullPassMatrix(
            replaceSuite: 'unit',
            withResult: result(suite: 'unit', tests: 0),
          ),
        ),
        throwsArgumentError,
      );
    });

    test('rejects a pass without evidence', () {
      expect(
        () => AccountCenterAutomatedTestMatrix.buildReport(
          fullPassMatrix(
            replaceSuite: 'unit',
            withResult: result(suite: 'unit', evidence: const <String>[]),
          ),
        ),
        throwsArgumentError,
      );
    });

    test('rejects a command that leaves the absolute toolchain', () {
      expect(
        () => AccountCenterAutomatedTestMatrix.buildReport(
          fullPassMatrix(
            replaceSuite: 'unit',
            withResult: result(
              suite: 'unit',
              command: 'flutter test test/features/account/domain',
            ),
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterAutomatedTestMatrix.buildReport(
          fullPassMatrix(
            replaceSuite: 'unit',
            withResult: result(suite: 'unit', command: ''),
          ),
        ),
        throwsArgumentError,
      );
    });

    test('rejects an evidence path that is absolute or escapes the repo', () {
      expect(
        () => AccountCenterAutomatedTestMatrix.buildReport(
          fullPassMatrix(
            replaceSuite: 'unit',
            withResult: result(
              suite: 'unit',
              evidence: const <String>['C:/void/test/foo_test.dart'],
            ),
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterAutomatedTestMatrix.buildReport(
          fullPassMatrix(
            replaceSuite: 'ui',
            withResult: result(
              suite: 'ui',
              evidence: const <String>['test/../lib/features/account'],
            ),
          ),
        ),
        throwsArgumentError,
      );
    });

    test('rejects an evidence path claimed twice by one suite', () {
      expect(
        () => AccountCenterAutomatedTestMatrix.buildReport(
          fullPassMatrix(
            replaceSuite: 'contract',
            withResult: result(
              suite: 'contract',
              evidence: const <String>[
                'test/features/account/domain/x_test.dart',
                'test/features/account/domain/x_test.dart',
              ],
            ),
          ),
        ),
        throwsArgumentError,
      );
    });

    test('rejects a fail that does not say what failed', () {
      expect(
        () => AccountCenterAutomatedTestMatrix.buildReport(
          fullPassMatrix(
            replaceSuite: 'regression',
            withResult: result(
              suite: 'regression',
              status: AccountTestSuiteStatus.fail,
            ),
          ),
        ),
        throwsArgumentError,
      );
    });

    test('rejects a blocked suite without a reason or with test counts', () {
      expect(
        () => AccountCenterAutomatedTestMatrix.buildReport(
          fullPassMatrix(
            replaceSuite: 'connector',
            withResult: result(
              suite: 'connector',
              status: AccountTestSuiteStatus.blocked,
            ),
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterAutomatedTestMatrix.buildReport(
          fullPassMatrix(
            replaceSuite: 'connector',
            withResult: result(
              suite: 'connector',
              status: AccountTestSuiteStatus.blocked,
              tests: 12,
              note: 'live connector unreachable in this build',
            ),
          ),
        ),
        throwsArgumentError,
      );
    });

    test('rejects a pending suite that claims executed tests', () {
      expect(
        () => AccountCenterAutomatedTestMatrix.buildReport(
          fullPassMatrix(
            replaceSuite: 'billing',
            withResult: result(
              suite: 'billing',
              status: AccountTestSuiteStatus.pending,
              tests: 9,
            ),
          ),
        ),
        throwsArgumentError,
      );
    });
  });

  group('115.51 report verdict', () {
    test('a fully passing matrix is complete, passing, and ALL_PASS', () {
      final report = AccountCenterAutomatedTestMatrix.buildReport(
        fullPassMatrix(),
      );
      expect(report.isComplete, isTrue);
      expect(report.passCount, 10);
      expect(report.isPass, isTrue);
      expect(report.verdict, 'ALL_PASS');
    });

    test('a pending suite makes the matrix incomplete', () {
      final report = AccountCenterAutomatedTestMatrix.buildReport(
        fullPassMatrix(
          replaceSuite: 'unit',
          withResult: result(
            suite: 'unit',
            status: AccountTestSuiteStatus.pending,
          ),
        ),
      );
      expect(report.isComplete, isFalse);
      expect(report.isPass, isFalse);
      expect(report.verdict, 'INCOMPLETE');
    });

    test('a failing suite keeps the matrix complete but not passing', () {
      final report = AccountCenterAutomatedTestMatrix.buildReport(
        fullPassMatrix(
          replaceSuite: 'regression',
          withResult: result(
            suite: 'regression',
            status: AccountTestSuiteStatus.fail,
            tests: 871,
            note:
                'test/app/auth/auth_flow_test.dart still fails on committed '
                'a5ed3ae (label rewrite), outside sprint 115 scope.',
          ),
        ),
      );
      expect(report.isComplete, isTrue);
      expect(report.passCount, 9);
      expect(report.isPass, isFalse);
      expect(report.verdict, 'COMPLETE_9_OF_10_PASS');
      expect(report.statusOf('regression'), AccountTestSuiteStatus.fail);
    });

    test('a blocked suite completes the matrix without passing it', () {
      final report = AccountCenterAutomatedTestMatrix.buildReport(
        fullPassMatrix(
          replaceSuite: 'connector',
          withResult: result(
            suite: 'connector',
            status: AccountTestSuiteStatus.blocked,
            note: 'live provider connector is DEFERRED-EXTERNAL.',
          ),
        ),
      );
      expect(report.isComplete, isTrue);
      expect(report.isPass, isFalse);
      expect(report.verdict, 'COMPLETE_9_OF_10_PASS');
    });
  });

  group('115.51 committed manifest', () {
    test('declares the step and carries the canonical suite list', () {
      final manifest = readManifest();
      expect(manifest['step'], '115.51');
      expect(manifest['title'], 'Automated Test Matrix');
      expect(
        manifest['required_suites'],
        AccountCenterAutomatedTestMatrix.requiredSuites,
      );
    });

    test('records every canonical suite in order and passes buildReport', () {
      final manifest = readManifest();
      final suites = (manifest['suites'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(
        suites.map((suite) => suite['name']),
        AccountCenterAutomatedTestMatrix.requiredSuites,
        reason: 'suite rows must follow the canonical order, no extras',
      );

      final results = <String, AccountTestSuiteResult>{
        for (final suite in suites)
          suite['name'] as String: AccountTestSuiteResult(
            suite: suite['name'] as String,
            status: AccountTestSuiteStatus.values.firstWhere(
              (status) => status.name == suite['status'],
              orElse: () => throw ArgumentError.value(
                suite['status'],
                'suites',
                'Unknown suite status in the committed manifest.',
              ),
            ),
            command: suite['command'] as String,
            evidence: (suite['evidence'] as List<dynamic>).cast<String>(),
            tests: (suite['tests'] as num).toInt(),
            note: (suite['note'] as String?) ?? '',
          ),
      };
      final report = AccountCenterAutomatedTestMatrix.buildReport(results);
      expect(
        report.isComplete,
        isTrue,
        reason: 'a committed matrix may never leave a suite pending',
      );
      expect(manifest['verdict'], report.verdict);
      expect(manifest['verdict'], isNot('INCOMPLETE'));
    });

    test('every suite command cites the absolute Flutter toolchain', () {
      final manifest = readManifest();
      for (final suite
          in (manifest['suites'] as List<dynamic>)
              .cast<Map<String, dynamic>>()) {
        expect(
          suite['command'] as String,
          startsWith(accountTestToolchain),
          reason: '${suite['name']} must not fall back to a bare flutter',
        );
      }
    });

    test('every evidence path exists and really contains tests', () {
      final manifest = readManifest();
      for (final suite
          in (manifest['suites'] as List<dynamic>)
              .cast<Map<String, dynamic>>()) {
        final evidence = (suite['evidence'] as List<dynamic>).cast<String>();
        expect(evidence, isNotEmpty, reason: suite['name']);
        for (final path in evidence) {
          final asFile = File(path);
          final asDirectory = Directory(path);
          expect(
            asFile.existsSync() || asDirectory.existsSync(),
            isTrue,
            reason: '${suite['name']} evidence missing: $path',
          );
          if (asFile.existsSync()) {
            expect(
              path.endsWith('_test.dart'),
              isTrue,
              reason: 'file evidence must be a test file: $path',
            );
          } else {
            final testFiles = asDirectory
                .listSync(recursive: true)
                .whereType<File>()
                .where((file) => file.path.endsWith('_test.dart'));
            expect(
              testFiles.isNotEmpty,
              isTrue,
              reason: 'directory evidence holds no test: $path',
            );
          }
        }
      }
    });

    test('the matrix reports its own test file as covered', () {
      final manifest = readManifest();
      var covered = false;
      for (final suite
          in (manifest['suites'] as List<dynamic>)
              .cast<Map<String, dynamic>>()) {
        for (final path
            in (suite['evidence'] as List<dynamic>).cast<String>()) {
          if (path == matrixTestPath || matrixTestPath.startsWith('$path/')) {
            covered = true;
          }
        }
      }
      expect(
        covered,
        isTrue,
        reason: 'the matrix must document its own coverage',
      );
    });

    test('regression covers the roots every other suite cites', () {
      final manifest = readManifest();
      final suites = (manifest['suites'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final regression = suites.firstWhere(
        (suite) => suite['name'] == 'regression',
      );
      final roots = (regression['evidence'] as List<dynamic>)
          .cast<String>()
          .toList();
      expect(roots, containsAll(regressionRoots));

      for (final suite in suites.where((s) => s['name'] != 'regression')) {
        for (final path
            in (suite['evidence'] as List<dynamic>).cast<String>()) {
          final covered = roots.any(
            (root) => path == root || path.startsWith('$root/'),
          );
          expect(
            covered,
            isTrue,
            reason: '${suite['name']} cites $path outside the regression roots',
          );
        }
      }
    });

    test('a suite that is not passing explains itself concretely', () {
      final manifest = readManifest();
      for (final suite
          in (manifest['suites'] as List<dynamic>)
              .cast<Map<String, dynamic>>()) {
        if (suite['status'] == 'pass') {
          expect(
            (suite['tests'] as num).toInt(),
            greaterThan(0),
            reason: '${suite['name']} passed without executed tests',
          );
          continue;
        }
        final note = (suite['note'] as String?) ?? '';
        expect(
          note.length,
          greaterThanOrEqualTo(30),
          reason: '${suite['name']} must state why it is not passing',
        );
      }
    });

    test('external boundaries stay declared instead of silently passing', () {
      final manifest = readManifest();
      final deferred = (manifest['deferred_external'] as List<dynamic>)
          .cast<String>();
      expect(
        deferred.length,
        greaterThanOrEqualTo(4),
        reason: 'external gates must be listed, not dropped',
      );
      expect(
        deferred.any((item) => item.toLowerCase().contains('connector')),
        isTrue,
      );
      expect(
        (manifest['overlap_note'] as String? ?? '').isNotEmpty,
        isTrue,
        reason: 'suites overlap by design; the overlap must be stated',
      );
    });
  });
}
