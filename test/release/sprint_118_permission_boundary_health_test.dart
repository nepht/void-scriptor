import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_permission_boundary_health.dart';

Sprint118PermissionBoundaryAnchor _anchor({
  String baselineState = 'pass',
  String baselineVerdict =
      Sprint118PermissionBoundaryContract.requiredBaselineVerdict,
  String releaseState = Sprint118PermissionBoundaryContract.delayedReleaseState,
  String charterState = 'pass',
  int charterWindowMinutes = 60480,
  String boundaryState = 'pass',
  String boundaryVerdict =
      Sprint118PermissionBoundaryContract.requiredBoundaryVerdict,
  double boundaryCoverage = 1.0,
  List<String> boundaryUnmet = const <String>[],
  bool coOwnershipAllowed = false,
  List<String>? readableSources,
}) {
  return Sprint118PermissionBoundaryAnchor(
    baselineState: baselineState,
    baselineVerdict: baselineVerdict,
    releaseState: releaseState,
    charterState: charterState,
    charterVerdict: Sprint118PermissionBoundaryContract.requiredCharterVerdict,
    charterWindowMinutes: charterWindowMinutes,
    boundaryState: boundaryState,
    boundaryVerdict: boundaryVerdict,
    boundaryCoverage: boundaryCoverage,
    boundaryChecks: const <String>[
      'global_route',
      'profile_summary_only',
      'novel_permission',
      'character_permission',
      'transfer_consent',
      'no_cross_workspace_leak',
    ],
    boundaryUnmet: boundaryUnmet,
    coOwnershipAllowed: coOwnershipAllowed,
    boundaryAcceptance: const <String>[
      'global_user_scope',
      'no_workspace_co_ownership',
      'explicit_workspace_permission',
      'explicit_transfer_consent',
      'separate_backup_boundaries',
    ],
    novelCharacterEvidence: const <String>[
      'distinct_namespaces',
      'reference_integrity',
      'override_isolation',
      'unlink_safety',
      'delete_safety',
      'permission_boundary',
      'restore_results',
    ],
    auditAcceptance: const <String>[
      'filters',
      'timestamps',
      'actor',
      'result',
      'redaction',
      'retention',
      'detail_link',
    ],
    readableSources:
        readableSources ??
        <String>[
          Sprint118PermissionBoundaryContract.baselineManifestPath,
          Sprint118PermissionBoundaryContract.charterManifestPath,
          Sprint118PermissionBoundaryContract.boundaryContractManifestPath,
          Sprint118PermissionBoundaryContract.boundaryValidationManifestPath,
          Sprint118PermissionBoundaryContract.novelCharacterManifestPath,
          Sprint118PermissionBoundaryContract.auditManifestPath,
        ],
  );
}

Sprint118PermissionBoundaryReview _review({
  List<Sprint118PermissionBoundaryEntry>? entries,
  String releaseState = Sprint118PermissionBoundaryContract.delayedReleaseState,
}) {
  return Sprint118PermissionBoundaryReview(
    releaseState: releaseState,
    entries:
        entries ?? Sprint118PermissionBoundaryContract.canonicalReview.entries,
  );
}

List<Sprint118PermissionBoundaryEntry> _withReplacement(
  String evidence,
  Sprint118PermissionBoundaryEntry replacement,
) {
  return <Sprint118PermissionBoundaryEntry>[
    for (final entry
        in Sprint118PermissionBoundaryContract.canonicalReview.entries)
      if (entry.evidence == evidence) replacement else entry,
  ];
}

void main() {
  group('118.20 Novel-Character Permission Boundary Health', () {
    test('pins the canonical contract', () {
      expect(Sprint118PermissionBoundaryContract.canonicalStep, '118.20');
      expect(
        Sprint118PermissionBoundaryContract.title,
        'Novel-Character Permission Boundary Health',
      );
      expect(Sprint118PermissionBoundaryContract.requiredEvidence.length, 6);
      expect(Sprint118PermissionBoundaryContract.requiredFields.length, 5);
      for (final evidence
          in Sprint118PermissionBoundaryContract.requiredEvidence) {
        expect(
          Sprint118PermissionBoundaryContract.sourceFor(evidence),
          isNotEmpty,
        );
      }
    });

    test('canonical review covers all evidence without live observation', () {
      final review = Sprint118PermissionBoundaryContract.canonicalReview;
      expect(review.evidenceItems.toSet(), <String>{
        'novel_permission',
        'character_permission',
        'transfer_consent',
        'backup_boundary',
        'unlink_behavior',
        'audit',
      });
      expect(review.observedCount, 0);
      for (final entry in review.entries) {
        expect(entry.detail, isNotEmpty);
        expect(entry.limitations, isNotEmpty);
        expect(entry.automaticAccess, isFalse);
        expect(entry.explicitTransfer, isTrue);
        expect(entry.boundarySeparate, isTrue);
      }
    });

    test('passes the canonical review and loader', () {
      final report = const Sprint118PermissionBoundaryGate().evaluateWith(
        _anchor(),
        _review(),
      );
      expect(report.state, Sprint118PermissionBoundaryState.pass);
      expect(
        report.verdict,
        'NOVEL_CHARACTER_PERMISSION_BOUNDARY_HEALTH_VERIFIED_LOCAL',
      );
      expect(report.reviewVerified, isTrue);
      expect(report.observedCount, 0);
      expect(const Sprint118PermissionBoundaryLoader().loadAnchor(), isNotNull);
    });

    test('rejects an automatic access claim', () {
      final entry =
          Sprint118PermissionBoundaryContract.canonicalReview.entries[0];
      final report = const Sprint118PermissionBoundaryGate().evaluateWith(
        _anchor(),
        _review(
          entries: _withReplacement(
            entry.evidence,
            Sprint118PermissionBoundaryEntry(
              evidence: entry.evidence,
              referenceState: entry.referenceState,
              source: entry.source,
              detail: entry.detail,
              limitations: entry.limitations,
              automaticAccess: true,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118PermissionBoundaryState.fail);
      expect(
        report.violations,
        contains('automatic_access_claimed:novel_permission'),
      );
    });

    test('rejects unknown, missing, or duplicate evidence', () {
      final entries =
          [...Sprint118PermissionBoundaryContract.canonicalReview.entries]
            ..removeAt(0)
            ..add(
              const Sprint118PermissionBoundaryEntry(
                evidence: 'unknown',
                referenceState: 'novel_permission',
                source: Sprint118PermissionBoundaryContract
                    .boundaryContractManifestPath,
                detail: 'local',
                limitations: <String>['fixture'],
              ),
            );
      final report = const Sprint118PermissionBoundaryGate().evaluateWith(
        _anchor(),
        _review(entries: entries),
      );
      expect(report.state, Sprint118PermissionBoundaryState.fail);
      expect(report.violations, contains('evidence_unknown:unknown'));
      expect(report.violations, contains('evidence_missing:novel_permission'));
    });

    test('rejects missing boundary controls', () {
      final entry =
          Sprint118PermissionBoundaryContract.canonicalReview.entries[0];
      final report = const Sprint118PermissionBoundaryGate().evaluateWith(
        _anchor(),
        _review(
          entries: _withReplacement(
            entry.evidence,
            Sprint118PermissionBoundaryEntry(
              evidence: entry.evidence,
              referenceState: entry.referenceState,
              source: entry.source,
              detail: '',
              limitations: const <String>[],
              explicitTransfer: false,
              boundarySeparate: false,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118PermissionBoundaryState.fail);
      expect(report.violations, contains('detail_missing:novel_permission'));
      expect(
        report.violations,
        contains('limitations_missing:novel_permission'),
      );
      expect(
        report.violations,
        contains('transfer_not_explicit:novel_permission'),
      );
      expect(
        report.violations,
        contains('boundary_not_separate:novel_permission'),
      );
    });

    test('rejects unknown reference state and unreadable source', () {
      final entry =
          Sprint118PermissionBoundaryContract.canonicalReview.entries[0];
      final report = const Sprint118PermissionBoundaryGate().evaluateWith(
        _anchor(readableSources: const <String>[]),
        _review(
          entries: _withReplacement(
            entry.evidence,
            const Sprint118PermissionBoundaryEntry(
              evidence: 'novel_permission',
              referenceState: 'not_a_boundary_state',
              source: 'missing.json',
              detail: 'local',
              limitations: <String>['fixture'],
            ),
          ),
        ),
      );
      expect(report.state, Sprint118PermissionBoundaryState.fail);
      expect(
        report.violations,
        contains('reference_state_invalid:novel_permission'),
      );
      expect(report.violations, contains('source_unreadable:novel_permission'));
    });

    test(
      'blocks when upstream baseline or boundary validation is not verified',
      () {
        final report = const Sprint118PermissionBoundaryGate().evaluateWith(
          _anchor(baselineState: 'blocked', boundaryState: 'blocked'),
          _review(),
        );
        expect(report.state, Sprint118PermissionBoundaryState.blocked);
        expect(report.blockers, contains('baseline_not_frozen'));
        expect(report.blockers, contains('boundary_validation_not_verified'));
      },
    );

    test('rejects co-ownership and incomplete boundary validation', () {
      final report = const Sprint118PermissionBoundaryGate().evaluateWith(
        _anchor(
          coOwnershipAllowed: true,
          boundaryCoverage: 0.5,
          boundaryUnmet: const <String>['novel_permission'],
        ),
        _review(),
      );
      expect(report.state, Sprint118PermissionBoundaryState.fail);
      expect(report.violations, contains('workspace_co_ownership_allowed'));
      expect(report.violations, contains('boundary_validation_incomplete'));
    });

    test('rejects a release-state mismatch', () {
      final report = const Sprint118PermissionBoundaryGate().evaluateWith(
        _anchor(releaseState: 'GA_RELEASED'),
        _review(releaseState: 'GA_RELEASED'),
      );
      expect(report.state, Sprint118PermissionBoundaryState.fail);
      expect(report.violations, contains('release_state_mismatch'));
    });
  });
}
