/// Support operations review contract for Sprint 114.7.
///
/// Dependency-free model that assesses operational support metadata only:
/// volume, severity, response time, resolution time, repeat rate, workaround
/// coverage, and documentation gaps. Ticket content, user manuscripts, and
/// secrets are outside the review scope.
class SupportCase {
  const SupportCase({
    required this.caseId,
    required this.severity,
    required this.openedAt,
    required this.firstResponseAt,
    required this.resolvedAt,
    required this.workaroundProvided,
    required this.documentationRef,
    this.repeatOfCaseId,
  });

  final String caseId;
  final String severity;

  /// ISO-8601 timestamp of when the case was opened.
  final String openedAt;

  /// ISO-8601 timestamp of the first response, or null when none exists yet.
  final String? firstResponseAt;

  /// ISO-8601 timestamp of resolution, or null when still open.
  final String? resolvedAt;

  final bool workaroundProvided;

  /// Documentation reference; empty means a documentation gap.
  final String documentationRef;

  final String? repeatOfCaseId;
}

enum SupportOperationsState { pass, fail, blocked }

class SupportOperationsMetrics {
  const SupportOperationsMetrics({
    required this.severityCounts,
    required this.responseTimeCoverage,
    required this.resolutionTimeCoverage,
    required this.repeatRate,
    required this.workaroundCoverage,
    required this.documentationGapCount,
  });

  final Map<String, int> severityCounts;
  final int responseTimeCoverage;
  final int resolutionTimeCoverage;
  final double repeatRate;
  final int workaroundCoverage;
  final int documentationGapCount;
}

class SupportOperationsDecision {
  const SupportOperationsDecision({
    required this.state,
    required this.volume,
    required this.invalidFields,
    required this.gaps,
    required this.metrics,
    required this.notes,
  });

  final SupportOperationsState state;
  final int volume;
  final List<String> invalidFields;
  final List<String> gaps;
  final SupportOperationsMetrics metrics;
  final List<String> notes;
}

class SupportOperationsReview {
  final List<SupportCase> _cases = <SupportCase>[];

  List<SupportCase> get cases => List<SupportCase>.unmodifiable(_cases);

  void add(SupportCase supportCase) => _cases.add(supportCase);

  SupportOperationsDecision evaluate() {
    if (_cases.isEmpty) {
      return const SupportOperationsDecision(
        state: SupportOperationsState.blocked,
        volume: 0,
        invalidFields: <String>[],
        gaps: <String>[],
        metrics: SupportOperationsMetrics(
          severityCounts: <String, int>{},
          responseTimeCoverage: 0,
          resolutionTimeCoverage: 0,
          repeatRate: 0,
          workaroundCoverage: 0,
          documentationGapCount: 0,
        ),
        notes: <String>[
          'Belum ada data support operations; volume dinilai bukan diklaim; '
              'external support operations DEFERRED-EXTERNAL.',
        ],
      );
    }

    final invalid = <String>[];
    final severityCounts = <String, int>{};
    var responseCoverage = 0;
    var resolutionCoverage = 0;
    var repeats = 0;
    var workaroundCoverage = 0;
    var documentationGaps = 0;
    var missingResponse = false;
    var missingResolution = false;
    var missingWorkaround = false;
    var missingDocumentation = false;

    for (final supportCase in _cases) {
      if (supportCase.caseId.trim().isEmpty) {
        invalid.add('case_id');
      }
      if (supportCase.severity.trim().isEmpty) {
        invalid.add('severity');
      } else {
        severityCounts.update(
          supportCase.severity,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }

      final opened = DateTime.tryParse(supportCase.openedAt);
      if (opened == null) {
        invalid.add('opened_at');
      }

      final responded = supportCase.firstResponseAt == null
          ? null
          : DateTime.tryParse(supportCase.firstResponseAt!);
      if (supportCase.firstResponseAt != null) {
        if (responded == null ||
            (opened != null && responded.isBefore(opened))) {
          invalid.add('response_time');
        } else {
          responseCoverage++;
        }
      } else {
        missingResponse = true;
      }

      final resolved = supportCase.resolvedAt == null
          ? null
          : DateTime.tryParse(supportCase.resolvedAt!);
      if (supportCase.resolvedAt != null) {
        if (resolved == null || (opened != null && resolved.isBefore(opened))) {
          invalid.add('resolution_time');
        } else {
          resolutionCoverage++;
        }
      } else {
        missingResolution = true;
      }

      if (supportCase.workaroundProvided) {
        workaroundCoverage++;
      } else {
        missingWorkaround = true;
      }

      if (supportCase.documentationRef.trim().isEmpty) {
        documentationGaps++;
        missingDocumentation = true;
      }

      if ((supportCase.repeatOfCaseId ?? '').trim().isNotEmpty) {
        repeats++;
      }
    }

    final uniqueInvalid = <String>{}.toList();
    for (final field in invalid) {
      if (!uniqueInvalid.contains(field)) uniqueInvalid.add(field);
    }

    final gaps = <String>[];
    if (missingResponse) gaps.add('response_time');
    if (missingResolution) gaps.add('resolution_time');
    if (missingWorkaround) gaps.add('workaround');
    if (missingDocumentation) gaps.add('documentation_gap');

    return SupportOperationsDecision(
      state: uniqueInvalid.isEmpty
          ? SupportOperationsState.pass
          : SupportOperationsState.fail,
      volume: _cases.length,
      invalidFields: List<String>.unmodifiable(uniqueInvalid),
      gaps: List<String>.unmodifiable(gaps),
      metrics: SupportOperationsMetrics(
        severityCounts: Map<String, int>.unmodifiable(severityCounts),
        responseTimeCoverage: responseCoverage,
        resolutionTimeCoverage: resolutionCoverage,
        repeatRate: repeats / _cases.length,
        workaroundCoverage: workaroundCoverage,
        documentationGapCount: documentationGaps,
      ),
      notes: const <String>[
        'Review menilai metadata operasional saja; content_collection '
            'excluded dan external support operations DEFERRED-EXTERNAL.',
      ],
    );
  }
}
