/// Workflow outcome review contract for Sprint 114.23.
///
/// Dependency-free model that judges whether the writer, lore, simulation,
/// sharing, and publishing workflows can be completed and recovered when
/// they fail. Every entry carries seven canonical dimensions — completion,
/// failure, recovery, abandonment, workaround, repeat_use, limitations;
/// absent values are reported by canonical wire name, while an empty
/// limitations list is a recorded answer ("no recorded limitation"), not a
/// missing field. Coverage must be exactly the five canonical workflows
/// once each.
///
/// Three cross-dimension honesty rules run on top of coverage: a recorded
/// failure must show a recovered state (silent unrecovered failure fails),
/// an incomplete workflow must carry a cause of failure or abandonment
/// (incompleteness without cause fails), and repeat use may only be claimed
/// on a workflow that completes (repeat use without completion fails).
/// An absent entry set stays BLOCKED without outcome claims.
///
/// Outcomes here are judged from recorded review entries, not from live
/// native sessions. Native workflow execution, end-user validation, and
/// public distribution remain external gates and are not claimed by this
/// model.
class WorkflowOutcomeEntry {
  const WorkflowOutcomeEntry({
    required this.workflow,
    required this.completion,
    required this.failure,
    required this.recovery,
    required this.abandonment,
    required this.workaround,
    required this.repeatUse,
    required this.limitations,
  });

  static const List<String> requiredDimensions = <String>[
    'completion',
    'failure',
    'recovery',
    'abandonment',
    'workaround',
    'repeat_use',
    'limitations',
  ];

  /// Workflow identity reported alongside the dimensions when blank.
  final String workflow;
  final bool? completion;
  final bool? failure;
  final String? recovery;
  final bool? abandonment;
  final bool? workaround;
  final bool? repeatUse;
  final List<String>? limitations;
}

enum WorkflowOutcomeState { pass, fail, blocked }

class WorkflowOutcomeReport {
  const WorkflowOutcomeReport({
    required this.state,
    required this.entries,
    required this.workflowCount,
    required this.missingDimensions,
    required this.violations,
    required this.notes,
  });

  final WorkflowOutcomeState state;
  final List<WorkflowOutcomeEntry> entries;
  final int workflowCount;
  final List<String> missingDimensions;
  final List<String> violations;
  final List<String> notes;
}

class WorkflowOutcomeReview {
  static const List<String> expectedWorkflows = <String>[
    'writer',
    'lore',
    'simulation',
    'sharing',
    'publishing',
  ];

  /// Canonical-order missing dimensions for a single entry. A blank
  /// [workflow] string, null scalar dimensions, and null [limitations] are
  /// each reported by wire name; a non-null empty [limitations] list is a
  /// recorded answer.
  List<String> missingDimensions(WorkflowOutcomeEntry entry) {
    final missing = <String>[];
    if (entry.workflow.trim().isEmpty) {
      missing.add('workflow');
    }
    if (entry.completion == null) {
      missing.add('completion');
    }
    if (entry.failure == null) {
      missing.add('failure');
    }
    if (entry.recovery == null || entry.recovery!.trim().isEmpty) {
      missing.add('recovery');
    }
    if (entry.abandonment == null) {
      missing.add('abandonment');
    }
    if (entry.workaround == null) {
      missing.add('workaround');
    }
    if (entry.repeatUse == null) {
      missing.add('repeat_use');
    }
    if (entry.limitations == null) {
      missing.add('limitations');
    }
    return missing;
  }

  WorkflowOutcomeReport evaluate(List<WorkflowOutcomeEntry>? entries) {
    if (entries == null || entries.isEmpty) {
      return const WorkflowOutcomeReport(
        state: WorkflowOutcomeState.blocked,
        entries: <WorkflowOutcomeEntry>[],
        workflowCount: 0,
        missingDimensions: <String>[],
        violations: <String>[],
        notes: <String>[
          'Belum ada entri review hasil workflow; tidak ada klaim bahwa '
              'workflow dapat diselesaikan atau dipulihkan; eksekusi workflow '
              'native, validasi end-user, dan publikasi distribusi '
              'DEFERRED-EXTERNAL.',
        ],
      );
    }

    final missing = <String>{};
    final violations = <String>[];
    final seen = <String>{};

    for (final entry in entries) {
      missing.addAll(missingDimensions(entry));
      final id = entry.workflow.trim();
      if (id.isNotEmpty) {
        if (!expectedWorkflows.contains(id)) {
          violations.add('unexpected workflow: $id');
        } else if (!seen.add(id)) {
          violations.add('duplicate workflow: $id');
        }
      }
    }

    if (missing.isEmpty) {
      final missingWorkflows = <String>[
        for (final id in expectedWorkflows)
          if (!seen.contains(id)) id,
      ];
      if (missingWorkflows.isNotEmpty) {
        violations.add(
          'coverage incomplete: missing ${missingWorkflows.join(', ')}',
        );
      }

      for (final entry in entries) {
        final id = entry.workflow.trim();
        if (!expectedWorkflows.contains(id) || !seen.contains(id)) {
          continue;
        }
        if (entry.failure == true && entry.recovery != 'ok') {
          violations.add('unrecovered_failure: $id');
        }
        if (entry.completion == false &&
            entry.failure != true &&
            entry.abandonment != true) {
          violations.add('incomplete_without_cause: $id');
        }
        if (entry.repeatUse == true && entry.completion != true) {
          violations.add('repeat_use_without_completion: $id');
        }
      }
    }

    return WorkflowOutcomeReport(
      state: missing.isEmpty && violations.isEmpty
          ? WorkflowOutcomeState.pass
          : WorkflowOutcomeState.fail,
      entries: List<WorkflowOutcomeEntry>.unmodifiable(entries),
      workflowCount: entries.length,
      missingDimensions: List<String>.unmodifiable(
        missing.toList()..sort((a, b) {
          const order = <String>[
            'workflow',
            ...WorkflowOutcomeEntry.requiredDimensions,
          ];
          return order.indexOf(a).compareTo(order.indexOf(b));
        }),
      ),
      violations: List<String>.unmodifiable(violations),
      notes: const <String>[
        'Review lokal hasil lima workflow kanonik atas entri tercatat; '
            'eksekusi workflow native, validasi end-user, dan publikasi '
            'distribusi DEFERRED-EXTERNAL.',
      ],
    );
  }
}
