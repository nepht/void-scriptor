/// Sprint 115.51 — Automated Test Matrix contract.
///
/// The canonical objective for step 115.51 asks for
/// `unit, state-machine, contract, connector, security, billing, UI,
/// accessibility, and end-to-end tests` plus the regression gate, so the ten
/// canonical suites are transcribed here in spec order and never invented.
///
/// The matrix is fail-closed like its siblings (115.44, 115.49, 115.50):
///
/// * a suite outside the canonical set, or a row whose key disagrees with the
///   row it labels, is rejected with [ArgumentError];
/// * a canonical suite that was never recorded is rejected with [StateError];
/// * a suite may only report `pass` when it actually executed tests
///   (`tests > 0`) against a command pinned to the absolute Flutter
///   toolchain — a bare `flutter` invocation cannot prove which SDK ran;
/// * a suite that is not passing must say why: `fail` requires a note, and
///   `blocked` requires a note plus zero executed tests, so an external
///   boundary can never be dressed up as a local run;
/// * a `pending` row may not claim executed tests, and [AccountTestMatrixReport.isPass]
///   only turns true when the matrix is complete and every canonical suite
///   passed.
///
/// Evidence paths are repository-relative test paths: absolute paths and `..`
/// segments are rejected so a suite cannot cite something outside the
/// checkout. The accompanying test grounds every committed row in the live
/// repository (path existence, real `*_test.dart` content, aggregate
/// regression coverage).
library;

/// The executable every suite command must be pinned to.
///
/// Absolute on purpose: the roadmap rules forbid bare `flutter`/`dart`, and a
/// matrix that recorded a relative command could not prove which SDK produced
/// its numbers.
const String accountTestToolchain =
    'C:/Flutter-SDK-3.47.6/flutter/bin/flutter.bat test';

/// Outcome of one canonical suite run.
enum AccountTestSuiteStatus {
  /// Executed and every test in the suite passed.
  pass,

  /// Executed and at least one test failed; [AccountTestSuiteResult.note]
  /// names the concrete failure.
  fail,

  /// Cannot be executed locally in this build (external boundary); requires a
  /// note and may never carry executed test counts.
  blocked,

  /// Recorded as a target but not yet run; never survives into a complete
  /// matrix.
  pending,
}

/// One row of the automated test matrix.
final class AccountTestSuiteResult {
  const AccountTestSuiteResult({
    required this.suite,
    required this.status,
    required this.command,
    required this.evidence,
    this.tests = 0,
    this.note = '',
  });

  /// Canonical suite this row belongs to; must match its report key.
  final String suite;

  final AccountTestSuiteStatus status;

  /// Full command, pinned to [accountTestToolchain].
  final String command;

  /// Repository-relative test files or directories this suite executed.
  final List<String> evidence;

  /// Number of test cases the run executed (passed + failed).
  final int tests;

  /// Why the suite is not passing, or a scope clarification for a passing one.
  final String note;

  Map<String, Object?> toPublicJson() => <String, Object?>{
    'name': suite,
    'status': status.name,
    'command': command,
    'tests': tests,
    'evidence': evidence,
    'note': note,
  };
}

/// The validated matrix for canonical step 115.51.
final class AccountTestMatrixReport {
  AccountTestMatrixReport._(this.results);

  /// Recorded suites in canonical order.
  final Map<String, AccountTestSuiteResult> results;

  /// True when every canonical suite has a recorded, non-pending row.
  bool get isComplete => results.values.every(
    (row) => row.status != AccountTestSuiteStatus.pending,
  );

  /// Number of suites that passed.
  int get passCount => results.values
      .where((row) => row.status == AccountTestSuiteStatus.pass)
      .length;

  /// True only for a complete matrix whose every suite passed.
  bool get isPass =>
      isComplete &&
      passCount == AccountCenterAutomatedTestMatrix.requiredSuites.length;

  /// Machine-readable summary; the committed manifest must repeat this value.
  String get verdict => !isComplete
      ? 'INCOMPLETE'
      : isPass
      ? 'ALL_PASS'
      : 'COMPLETE_${passCount}_OF_'
            '${AccountCenterAutomatedTestMatrix.requiredSuites.length}_PASS';

  AccountTestSuiteStatus statusOf(String suite) => results[suite]!.status;
}

/// Fail-closed Automated Test Matrix for canonical step 115.51.
abstract final class AccountCenterAutomatedTestMatrix {
  /// `required_suites` for canonical step 115.51, in spec order.
  static const List<String> requiredSuites = <String>[
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
  ];

  /// Validates a suite map against [requiredSuites].
  ///
  /// Throws [ArgumentError] for an unknown suite, a label that disagrees with
  /// its key, a command that leaves [accountTestToolchain], a malformed or
  /// duplicated evidence path, a `pass` without executed tests, a `fail`
  /// without a note, a `blocked` row with executed tests or without a note,
  /// and a `pending` row that claims executed tests. Throws [StateError] when
  /// a canonical suite is missing, so a matrix can never claim completeness by
  /// quietly dropping a suite.
  static AccountTestMatrixReport buildReport(
    Map<String, AccountTestSuiteResult> results,
  ) {
    for (final key in results.keys) {
      if (!requiredSuites.contains(key)) {
        throw ArgumentError.value(
          key,
          'results',
          'Suite outside the canonical required_suites of step 115.51.',
        );
      }
    }
    final missing = requiredSuites
        .where((suite) => !results.containsKey(suite))
        .toList(growable: false);
    if (missing.isNotEmpty) {
      throw StateError('Missing canonical suite(s): ${missing.join(', ')}.');
    }
    final ordered = <String, AccountTestSuiteResult>{
      for (final suite in requiredSuites) suite: results[suite]!,
    };
    for (final entry in ordered.entries) {
      _validate(entry.key, entry.value);
    }
    return AccountTestMatrixReport._(Map.unmodifiable(ordered));
  }

  static void _validate(String key, AccountTestSuiteResult row) {
    if (row.suite != key) {
      throw ArgumentError.value(
        row.suite,
        'results',
        'Row labelled ${row.suite} is stored under the canonical key $key.',
      );
    }
    if (row.command.isEmpty || !row.command.startsWith(accountTestToolchain)) {
      throw ArgumentError.value(
        row.command,
        'results',
        'Suite $key must run the absolute Flutter toolchain.',
      );
    }
    if (row.evidence.isEmpty) {
      throw ArgumentError.value(
        row.evidence,
        'results',
        'Suite $key must cite the tests it executed.',
      );
    }
    final seen = <String>{};
    for (final path in row.evidence) {
      if (path.isEmpty ||
          path.startsWith('/') ||
          path.contains(':') ||
          path.startsWith('../') ||
          path.contains('/../') ||
          path.endsWith('/..')) {
        throw ArgumentError.value(
          path,
          'results',
          'Suite $key evidence must be a repository-relative test path.',
        );
      }
      if (!seen.add(path)) {
        throw ArgumentError.value(
          path,
          'results',
          'Suite $key cites the same evidence path twice.',
        );
      }
    }
    if (row.tests < 0) {
      throw ArgumentError.value(
        row.tests,
        'results',
        'Suite $key reports a negative test count.',
      );
    }
    switch (row.status) {
      case AccountTestSuiteStatus.pass:
        if (row.tests == 0) {
          throw ArgumentError.value(
            row.tests,
            'results',
            'Suite $key claims pass without executed tests.',
          );
        }
      case AccountTestSuiteStatus.fail:
        if (row.note.trim().isEmpty) {
          throw ArgumentError.value(
            row.note,
            'results',
            'Suite $key failed without saying what failed.',
          );
        }
      case AccountTestSuiteStatus.blocked:
        if (row.note.trim().isEmpty) {
          throw ArgumentError.value(
            row.note,
            'results',
            'Suite $key is blocked without naming the external boundary.',
          );
        }
        if (row.tests != 0) {
          throw ArgumentError.value(
            row.tests,
            'results',
            'Suite $key is blocked but claims executed tests.',
          );
        }
      case AccountTestSuiteStatus.pending:
        if (row.tests != 0) {
          throw ArgumentError.value(
            row.tests,
            'results',
            'Suite $key is pending but claims executed tests.',
          );
        }
    }
  }
}
