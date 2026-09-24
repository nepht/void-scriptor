/// Accessibility health contract for Sprint 114.20.
///
/// Dependency-free model that records blockers across the seven canonical
/// signals: keyboard_blocker, screen_reader_blocker, focus_loss,
/// scaling_break, contrast_issue, motion_issue, and nonvisual_gap. The
/// canonical contract defines no recovery-mechanism signal, so recovery is
/// per-signal: a failed blocker only counts as honestly recovered when that
/// same signal is observed as recovered. The nonvisual fallback never
/// excuses another signal's failure. An absent observation set stays
/// BLOCKED without health claims. Native assistive-technology verification,
/// hosted CI, and public distribution remain external gates and are not
/// claimed here.
enum AccessibilitySignal {
  keyboardBlocker,
  screenReaderBlocker,
  focusLoss,
  scalingBreak,
  contrastIssue,
  motionIssue,
  nonvisualGap,
}

enum AccessibilityOutcome { ok, failed, recovered }

enum AccessibilityState { pass, fail, blocked }

class AccessibilityObservation {
  const AccessibilityObservation({
    required this.signal,
    required this.outcome,
    required this.note,
  });

  final AccessibilitySignal signal;
  final AccessibilityOutcome outcome;
  final String note;
}

class AccessibilityReport {
  const AccessibilityReport({
    required this.state,
    required this.observations,
    required this.coveredSignals,
    required this.invalidFields,
    required this.violations,
    required this.notes,
  });

  final AccessibilityState state;
  final List<AccessibilityObservation> observations;
  final List<AccessibilitySignal> coveredSignals;
  final List<String> invalidFields;
  final List<String> violations;
  final List<String> notes;
}

class AccessibilityHealth {
  static const List<AccessibilitySignal> canonicalSignals =
      <AccessibilitySignal>[
        AccessibilitySignal.keyboardBlocker,
        AccessibilitySignal.screenReaderBlocker,
        AccessibilitySignal.focusLoss,
        AccessibilitySignal.scalingBreak,
        AccessibilitySignal.contrastIssue,
        AccessibilitySignal.motionIssue,
        AccessibilitySignal.nonvisualGap,
      ];

  static const Map<AccessibilitySignal, String> _wireNames =
      <AccessibilitySignal, String>{
        AccessibilitySignal.keyboardBlocker: 'keyboard_blocker',
        AccessibilitySignal.screenReaderBlocker: 'screen_reader_blocker',
        AccessibilitySignal.focusLoss: 'focus_loss',
        AccessibilitySignal.scalingBreak: 'scaling_break',
        AccessibilitySignal.contrastIssue: 'contrast_issue',
        AccessibilitySignal.motionIssue: 'motion_issue',
        AccessibilitySignal.nonvisualGap: 'nonvisual_gap',
      };

  AccessibilityReport evaluate(List<AccessibilityObservation>? observations) {
    if (observations == null || observations.isEmpty) {
      return const AccessibilityReport(
        state: AccessibilityState.blocked,
        observations: <AccessibilityObservation>[],
        coveredSignals: <AccessibilitySignal>[],
        invalidFields: <String>[],
        violations: <String>[],
        notes: <String>[
          'Belum ada observasi aksesibilitas; tidak ada klaim kesehatan; '
              'verifikasi assistive technology native DEFERRED-EXTERNAL.',
        ],
      );
    }

    final covered = <AccessibilitySignal>{
      for (final observation in observations) observation.signal,
    };
    final invalid = <String>[];
    if (covered.length != canonicalSignals.length ||
        !canonicalSignals.every(covered.contains)) {
      invalid.add('signals');
    }
    if (observations.any((o) => o.note.trim().isEmpty)) {
      invalid.add('notes');
    }

    // Aturan pemulihan per-signal hanya dinilai saat cakupan lengkap;
    // cakupan belum lengkap sudah gagal lewat invalidasi `signals`.
    final violations = <String>[];
    if (invalid.isEmpty) {
      for (final signal in canonicalSignals) {
        final outcome = observations
            .firstWhere((o) => o.signal == signal)
            .outcome;
        if (outcome == AccessibilityOutcome.failed) {
          violations.add('${_wireNames[signal]}_unrecovered');
        }
      }
    }

    return AccessibilityReport(
      state: invalid.isEmpty && violations.isEmpty
          ? AccessibilityState.pass
          : AccessibilityState.fail,
      observations: List<AccessibilityObservation>.unmodifiable(observations),
      coveredSignals: List<AccessibilitySignal>.unmodifiable(
        canonicalSignals.where(covered.contains),
      ),
      invalidFields: List<String>.unmodifiable(invalid.toSet()),
      violations: List<String>.unmodifiable(violations.toSet()),
      notes: const <String>[
        'Verifikasi kontrak lokal atas tujuh sinyal aksesibilitas; '
            'pengujian assistive technology native, hosted CI, dan '
            'publikasi distribusi DEFERRED-EXTERNAL.',
      ],
    );
  }
}
