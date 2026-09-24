/// Dependency-free patch regression matrix contract for Sprint 114.35.
enum PatchRegressionSuiteResult { passed, failed, notRun }

enum PatchRegressionMatrixStatus { pass, fail, blocked }

class PatchRegressionMatrix {
  const PatchRegressionMatrix._();

  static const String suiteUnit = 'unit';
  static const String suiteIntegration = 'integration';
  static const String suiteMigration = 'migration';
  static const String suiteRecovery = 'recovery';
  static const String suiteSecurity = 'security';
  static const String suitePrivacy = 'privacy';
  static const String suiteAccessibility = 'accessibility';
  static const String suiteUi = 'ui';
  static const String suiteEndToEnd = 'end_to_end';
  static const String suiteRegression = 'regression';

  static const List<String> requiredSuites = <String>[
    suiteUnit,
    suiteIntegration,
    suiteMigration,
    suiteRecovery,
    suiteSecurity,
    suitePrivacy,
    suiteAccessibility,
    suiteUi,
    suiteEndToEnd,
    suiteRegression,
  ];

  static bool isRequiredSuite(String suite) => requiredSuites.contains(suite);
}

class PatchRegressionMatrixEntry {
  const PatchRegressionMatrixEntry({
    required this.suite,
    required this.command,
    required this.result,
    required this.evidence,
    this.notes = '',
  });

  final String suite;
  final String command;
  final PatchRegressionSuiteResult result;
  final List<String> evidence;
  final String notes;

  PatchRegressionMatrixEntry copyWith({
    String? suite,
    String? command,
    PatchRegressionSuiteResult? result,
    List<String>? evidence,
    String? notes,
  }) {
    return PatchRegressionMatrixEntry(
      suite: suite ?? this.suite,
      command: command ?? this.command,
      result: result ?? this.result,
      evidence: evidence ?? this.evidence,
      notes: notes ?? this.notes,
    );
  }
}

class PatchRegressionMatrixReport {
  const PatchRegressionMatrixReport({
    required this.status,
    required this.executedSuiteNames,
    required this.missingSuites,
    required this.unexpectedSuites,
    required this.failedSuites,
    required this.notRunSuites,
    required this.limitations,
  });

  final PatchRegressionMatrixStatus status;
  final List<String> executedSuiteNames;
  final List<String> missingSuites;
  final List<String> unexpectedSuites;
  final List<String> failedSuites;
  final List<String> notRunSuites;
  final List<String> limitations;

  int get executedSuiteCount => executedSuiteNames.length;
}

class PatchRegressionMatrixRegister {
  final List<PatchRegressionMatrixEntry> _entries =
      <PatchRegressionMatrixEntry>[];

  void add(PatchRegressionMatrixEntry entry) => _entries.add(entry);

  void addEntries(Iterable<PatchRegressionMatrixEntry> entries) =>
      _entries.addAll(entries);

  PatchRegressionMatrixReport evaluate() {
    if (_entries.isEmpty) {
      return const PatchRegressionMatrixReport(
        status: PatchRegressionMatrixStatus.blocked,
        executedSuiteNames: <String>[],
        missingSuites: PatchRegressionMatrix.requiredSuites,
        unexpectedSuites: <String>[],
        failedSuites: <String>[],
        notRunSuites: <String>[],
        limitations: <String>[
          'No patch regression matrix is available; no patch readiness is claimed.',
        ],
      );
    }

    final limitations = <String>[];
    final counts = <String, int>{};
    final executed = <String>[];
    final failed = <String>[];
    final notRun = <String>[];

    for (final entry in _entries) {
      final suite = entry.suite.trim();
      counts.update(suite, (count) => count + 1, ifAbsent: () => 1);
      if (!PatchRegressionMatrix.isRequiredSuite(suite)) {
        limitations.add('$suite unexpected suite');
        continue;
      }
      if (counts[suite]! > 1) {
        limitations.add('$suite duplicate suite');
        continue;
      }
      if (entry.command.trim().isEmpty) {
        limitations.add('$suite missing command');
      }
      if (entry.evidence.isEmpty ||
          entry.evidence.any((item) => item.trim().isEmpty)) {
        limitations.add('$suite missing evidence');
      }
      if (entry.result == PatchRegressionSuiteResult.notRun) {
        notRun.add(suite);
        limitations.add('$suite not run');
      } else if (entry.result != PatchRegressionSuiteResult.passed) {
        failed.add(suite);
        final detail = entry.notes.trim();
        limitations.add(
          detail.isEmpty ? '$suite failed' : '$suite failed: $detail',
        );
      } else {
        executed.add(suite);
      }
    }

    final missing = PatchRegressionMatrix.requiredSuites
        .where((suite) => !counts.containsKey(suite))
        .toList(growable: false);
    final unexpected =
        counts.keys
            .where((suite) => !PatchRegressionMatrix.isRequiredSuite(suite))
            .toList(growable: false)
          ..sort();
    for (final suite in missing) {
      limitations.add('$suite missing suite');
    }

    final status = limitations.isEmpty
        ? PatchRegressionMatrixStatus.pass
        : PatchRegressionMatrixStatus.fail;
    executed.sort();
    failed.sort();
    notRun.sort();
    return PatchRegressionMatrixReport(
      status: status,
      executedSuiteNames: List<String>.unmodifiable(executed),
      missingSuites: List<String>.unmodifiable(missing),
      unexpectedSuites: List<String>.unmodifiable(unexpected),
      failedSuites: List<String>.unmodifiable(failed),
      notRunSuites: List<String>.unmodifiable(notRun),
      limitations: List<String>.unmodifiable(limitations),
    );
  }
}
