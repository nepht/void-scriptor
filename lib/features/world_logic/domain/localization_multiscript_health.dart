/// Localization & multiscript health contract for Sprint 114.21.
///
/// Dependency-free model that records problems across the seven canonical
/// signals: locale_issue, rtl_issue, text_overflow, date_issue,
/// calendar_issue, unit_issue, and multiscript_issue. The canonical
/// contract lists problems only and defines no recovery-mechanism signal,
/// so recovery is per-signal: a failed issue only counts as honestly
/// recovered when that same signal is observed as recovered. A recovered
/// rtl issue never excuses a failing locale issue. An absent observation
/// set stays BLOCKED without health claims. Native locale/RTL/IME
/// verification, hosted CI, and public distribution remain external gates
/// and are not claimed here.
enum LocalizationSignal {
  localeIssue,
  rtlIssue,
  textOverflow,
  dateIssue,
  calendarIssue,
  unitIssue,
  multiscriptIssue,
}

enum LocalizationOutcome { ok, failed, recovered }

enum LocalizationState { pass, fail, blocked }

class LocalizationObservation {
  const LocalizationObservation({
    required this.signal,
    required this.outcome,
    required this.note,
  });

  final LocalizationSignal signal;
  final LocalizationOutcome outcome;
  final String note;
}

class LocalizationReport {
  const LocalizationReport({
    required this.state,
    required this.observations,
    required this.coveredSignals,
    required this.invalidFields,
    required this.violations,
    required this.notes,
  });

  final LocalizationState state;
  final List<LocalizationObservation> observations;
  final List<LocalizationSignal> coveredSignals;
  final List<String> invalidFields;
  final List<String> violations;
  final List<String> notes;
}

class LocalizationMultiscriptHealth {
  static const List<LocalizationSignal> canonicalSignals = <LocalizationSignal>[
    LocalizationSignal.localeIssue,
    LocalizationSignal.rtlIssue,
    LocalizationSignal.textOverflow,
    LocalizationSignal.dateIssue,
    LocalizationSignal.calendarIssue,
    LocalizationSignal.unitIssue,
    LocalizationSignal.multiscriptIssue,
  ];

  static const Map<LocalizationSignal, String> _wireNames =
      <LocalizationSignal, String>{
        LocalizationSignal.localeIssue: 'locale_issue',
        LocalizationSignal.rtlIssue: 'rtl_issue',
        LocalizationSignal.textOverflow: 'text_overflow',
        LocalizationSignal.dateIssue: 'date_issue',
        LocalizationSignal.calendarIssue: 'calendar_issue',
        LocalizationSignal.unitIssue: 'unit_issue',
        LocalizationSignal.multiscriptIssue: 'multiscript_issue',
      };

  LocalizationReport evaluate(List<LocalizationObservation>? observations) {
    if (observations == null || observations.isEmpty) {
      return const LocalizationReport(
        state: LocalizationState.blocked,
        observations: <LocalizationObservation>[],
        coveredSignals: <LocalizationSignal>[],
        invalidFields: <String>[],
        violations: <String>[],
        notes: <String>[
          'Belum ada observasi lokalisasi/multiskrip; tidak ada klaim '
              'kesehatan; verifikasi locale native DEFERRED-EXTERNAL.',
        ],
      );
    }

    final covered = <LocalizationSignal>{
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
        if (outcome == LocalizationOutcome.failed) {
          violations.add('${_wireNames[signal]}_unrecovered');
        }
      }
    }

    return LocalizationReport(
      state: invalid.isEmpty && violations.isEmpty
          ? LocalizationState.pass
          : LocalizationState.fail,
      observations: List<LocalizationObservation>.unmodifiable(observations),
      coveredSignals: List<LocalizationSignal>.unmodifiable(
        canonicalSignals.where(covered.contains),
      ),
      invalidFields: List<String>.unmodifiable(invalid.toSet()),
      violations: List<String>.unmodifiable(violations.toSet()),
      notes: const <String>[
        'Verifikasi kontrak lokal atas tujuh sinyal lokalisasi; verifikasi '
            'locale RTL/IME native, hosted CI, dan publikasi distribusi '
            'DEFERRED-EXTERNAL.',
      ],
    );
  }
}
