/// Provider and external-dependency health contract for Sprint 114.25.
///
/// Dependency-free review model. It records health signals without collecting
/// credentials, provider secrets, creative content, or external payloads.
/// Fallback and consent are root safety signals: provider failures must be
/// recovered through fallback, while consent failures must be recovered before
/// any external transfer can be considered healthy.
enum ProviderSignal {
  providerAvailability,
  timeout,
  throttling,
  authExpiry,
  costVisibility,
  fallbackSuccess,
  consentFailure,
}

enum ProviderOutcome { ok, failed, recovered }

enum ProviderHealthState { pass, fail, blocked }

class ProviderObservation {
  const ProviderObservation({
    required this.signal,
    required this.outcome,
    required this.note,
  });

  final ProviderSignal signal;
  final ProviderOutcome outcome;
  final String note;
}

class ProviderHealthReport {
  const ProviderHealthReport({
    required this.state,
    required this.observations,
    required this.coveredSignals,
    required this.invalidFields,
    required this.violations,
    required this.notes,
  });

  final ProviderHealthState state;
  final List<ProviderObservation> observations;
  final List<ProviderSignal> coveredSignals;
  final List<String> invalidFields;
  final List<String> violations;
  final List<String> notes;
}

class ProviderHealth {
  static const List<ProviderSignal> canonicalSignals = <ProviderSignal>[
    ProviderSignal.providerAvailability,
    ProviderSignal.timeout,
    ProviderSignal.throttling,
    ProviderSignal.authExpiry,
    ProviderSignal.costVisibility,
    ProviderSignal.fallbackSuccess,
    ProviderSignal.consentFailure,
  ];
}

class ProviderExternalDependencyHealth {
  ProviderHealthReport evaluate(List<ProviderObservation>? observations) {
    if (observations == null || observations.isEmpty) {
      return const ProviderHealthReport(
        state: ProviderHealthState.blocked,
        observations: <ProviderObservation>[],
        coveredSignals: <ProviderSignal>[],
        invalidFields: <String>[],
        violations: <String>[],
        notes: <String>[
          'Belum ada observasi provider; tidak ada klaim availability, '
              'fallback, biaya, atau consent; credential collection '
              'DISABLED-BY-CONTRACT; external transfer consent '
              'DEFERRED-EXTERNAL.',
        ],
      );
    }

    final covered = <ProviderSignal>{
      for (final observation in observations) observation.signal,
    };
    final invalid = <String>[];
    if (covered.length != ProviderHealth.canonicalSignals.length ||
        !ProviderHealth.canonicalSignals.every(covered.contains)) {
      invalid.add('signals');
    }
    if (observations.any((observation) => observation.note.trim().isEmpty)) {
      invalid.add('notes');
    }

    final violations = <String>[];
    if (invalid.isEmpty) {
      ProviderOutcome outcomeOf(ProviderSignal signal) => observations
          .firstWhere((observation) => observation.signal == signal)
          .outcome;

      final fallback = outcomeOf(ProviderSignal.fallbackSuccess);
      final providerFailed = <ProviderSignal>[
        ProviderSignal.providerAvailability,
        ProviderSignal.timeout,
        ProviderSignal.throttling,
        ProviderSignal.authExpiry,
      ].where((signal) => outcomeOf(signal) == ProviderOutcome.failed);
      if (providerFailed.isNotEmpty && fallback != ProviderOutcome.recovered) {
        violations.add('fallback_success_unrecovered');
      }

      if (outcomeOf(ProviderSignal.consentFailure) != ProviderOutcome.ok &&
          outcomeOf(ProviderSignal.consentFailure) !=
              ProviderOutcome.recovered) {
        violations.add('consent_failure_unrecovered');
      }
    }

    return ProviderHealthReport(
      state: invalid.isEmpty && violations.isEmpty
          ? ProviderHealthState.pass
          : ProviderHealthState.fail,
      observations: List<ProviderObservation>.unmodifiable(observations),
      coveredSignals: List<ProviderSignal>.unmodifiable(
        ProviderHealth.canonicalSignals.where(covered.contains),
      ),
      invalidFields: List<String>.unmodifiable(invalid),
      violations: List<String>.unmodifiable(violations),
      notes: const <String>[
        'Review lokal atas tujuh sinyal provider tanpa credential atau '
            'creative content; no credential collection; external transfer '
            'consent and live provider validation DEFERRED-EXTERNAL.',
      ],
    );
  }
}
