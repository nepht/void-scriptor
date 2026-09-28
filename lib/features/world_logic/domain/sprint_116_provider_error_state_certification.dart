import 'dart:convert';
import 'dart:io';

enum Sprint116ErrorStateStatus { pass, fail, blocked }

/// A single observed provider error, classified into one of the eight
/// canonical error states of step 116.42.
///
/// [retryable] records what the provider behaviour allows; the certification
/// refuses any state whose retry semantics contradict that flag, so a
/// permanent failure can never be presented as "just try again".
class Sprint116ErrorObservation {
  const Sprint116ErrorObservation({
    required this.observationId,
    required this.providerId,
    required this.errorState,
    required this.retryable,
    required this.userMessage,
    required this.observedAtEpochMs,
    required this.source,
    this.httpStatus,
    this.retryAfterSeconds,
    this.evidenceRef,
  });

  final String observationId;
  final String providerId;
  final String errorState;
  final bool retryable;
  final int? httpStatus;
  final int? retryAfterSeconds;
  final String userMessage;
  final int observedAtEpochMs;
  final String source;
  final String? evidenceRef;
}

class Sprint116ErrorStateReport {
  Sprint116ErrorStateReport({
    required this.state,
    required this.invalidRecords,
    required this.observations,
    required this.coveredStates,
    required this.retryableIds,
  });

  final Sprint116ErrorStateStatus state;
  final List<String> invalidRecords;
  final List<Sprint116ErrorObservation> observations;
  final List<String> coveredStates;
  final List<String> retryableIds;

  String get externalGates => Sprint116ErrorStateContract.externalGates;
}

abstract final class Sprint116ErrorStateContract {
  static const String canonicalStep = '116.42';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_provider_error_state_certification.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The eight error states every provider connector must classify.
  static const List<String> requiredStates = <String>[
    'invalid_credentials',
    'expired',
    'revoked',
    'scope_denied',
    'rate_limited',
    'outage',
    'unsupported_region',
    'unsupported_plan',
  ];

  /// States that retrying cannot fix: only re-authentication, a consent
  /// change, or a different region/plan resolves them.
  static const List<String> nonRetryableStates = <String>[
    'invalid_credentials',
    'expired',
    'revoked',
    'scope_denied',
    'unsupported_region',
    'unsupported_plan',
  ];

  /// States where a later attempt can succeed; `rate_limited` additionally
  /// requires a positive delay before that attempt.
  static const List<String> retryableStates = <String>[
    'rate_limited',
    'outage',
  ];

  static const List<String> supportedSources = <String>[
    'synthetic_local',
    'live',
  ];

  /// Fragments a user-visible error message must never contain, so raw
  /// credential material cannot leak through error reporting.
  static const List<String> redactedFragments = <String>[
    'authorization:',
    'bearer ',
    'api_key',
    'password',
    'sk-',
  ];
}

class Sprint116ErrorStateCertification {
  /// Certifies provider error observations against the eight-state contract.
  ///
  /// Manifest fixtures are consulted only when [observations] is omitted, so
  /// explicit observations can never borrow fixture data to pass.
  Sprint116ErrorStateReport certify({
    List<Sprint116ErrorObservation>? observations,
    bool requireCoverage = false,
  }) {
    final effective = observations ?? _readManifestObservations();

    if (effective.isEmpty) {
      return Sprint116ErrorStateReport(
        state: Sprint116ErrorStateStatus.blocked,
        invalidRecords: const <String>['observations'],
        observations: const <Sprint116ErrorObservation>[],
        coveredStates: const <String>[],
        retryableIds: const <String>[],
      );
    }

    final invalid = <String>[];
    final covered = <String>[];
    final retryableIds = <String>[];

    for (var index = 0; index < effective.length; index++) {
      final observation = effective[index];
      final id = observation.observationId.trim();
      if (id.isEmpty) {
        invalid.add('observation_id:$index');
        continue;
      }

      if (observation.providerId.trim().isEmpty) {
        invalid.add('provider_id:$id');
      }

      final errorState = observation.errorState.trim();
      final knownState = Sprint116ErrorStateContract.requiredStates.contains(
        errorState,
      );
      if (!knownState) {
        invalid.add('error_state:$id');
      } else if (!covered.contains(errorState)) {
        covered.add(errorState);
      }

      final status = observation.httpStatus;
      if (status != null && (status < 400 || status > 599)) {
        invalid.add('http_status:$id');
      }

      if (observation.observedAtEpochMs <= 0) {
        invalid.add('observed_at:$id');
      }

      if (knownState) {
        final retryableState = Sprint116ErrorStateContract.retryableStates
            .contains(errorState);
        if (observation.retryable != retryableState) {
          invalid.add('retry_semantics:$id');
        }
        if (observation.retryable) {
          retryableIds.add(id);
        }

        // Only `rate_limited` may demand a delay; any reported delay must be
        // positive, and a rate limit without one is not certifiable.
        final delay = observation.retryAfterSeconds;
        if (errorState == 'rate_limited') {
          if (delay == null || delay <= 0) {
            invalid.add('retry_after:$id');
          }
        } else if (delay != null && delay <= 0) {
          invalid.add('retry_after:$id');
        }
      } else if (observation.retryable) {
        retryableIds.add(id);
      }

      final message = observation.userMessage.trim();
      if (message.isEmpty) {
        invalid.add('user_message:$id');
      } else {
        final lowered = message.toLowerCase();
        for (final fragment in Sprint116ErrorStateContract.redactedFragments) {
          if (lowered.contains(fragment)) {
            invalid.add('redaction:$id');
            break;
          }
        }
      }

      final source = observation.source.trim();
      final evidence = observation.evidenceRef?.trim();
      if (!Sprint116ErrorStateContract.supportedSources.contains(source) ||
          (source == 'live' && (evidence == null || evidence.isEmpty))) {
        invalid.add('no_mock_values:$id');
      }
    }

    if (requireCoverage) {
      for (final required in Sprint116ErrorStateContract.requiredStates) {
        if (!covered.contains(required)) {
          invalid.add('state_coverage:$required');
        }
      }
    }

    return Sprint116ErrorStateReport(
      state: invalid.isEmpty
          ? Sprint116ErrorStateStatus.pass
          : Sprint116ErrorStateStatus.fail,
      invalidRecords: invalid,
      observations: effective,
      coveredStates: covered,
      retryableIds: retryableIds,
    );
  }

  Map<String, dynamic>? _readManifest() {
    final file = File(Sprint116ErrorStateContract.manifestPath);
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  List<Sprint116ErrorObservation> _readManifestObservations() {
    final raw = _readManifest()?['observations'];
    if (raw is! List) return <Sprint116ErrorObservation>[];
    return raw
        .whereType<Map>()
        .map(
          (item) => Sprint116ErrorObservation(
            observationId: item['observation_id']?.toString() ?? '',
            providerId: item['provider_id']?.toString() ?? '',
            errorState: item['error_state']?.toString() ?? '',
            retryable: item['retryable'] == true,
            httpStatus: (item['http_status'] as num?)?.toInt(),
            retryAfterSeconds: (item['retry_after_seconds'] as num?)?.toInt(),
            userMessage: item['user_message']?.toString() ?? '',
            observedAtEpochMs:
                (item['observed_at_epoch_ms'] as num?)?.toInt() ?? 0,
            source: item['source']?.toString() ?? '',
            evidenceRef: item['evidence_ref']?.toString(),
          ),
        )
        .toList(growable: false);
  }
}
