import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_support_incident_readiness.dart';

/// Canonical step 117.6 — Support & Incident Readiness.
///
/// Objective (external canonical JSON): prepare intake, severity, owners,
/// response targets, recovery guidance, and provider escalation.
///
/// The six canonical fields are testable conditions, not prose. The load-bearing
/// distinction this suite protects is the same one 117.5 established: a field the
/// sources never recorded is *undecided*, while a field that is recorded and
/// contradicted is *incoherent*. Collapsing the two would report a support plan
/// that is merely unfinished as a support plan that is provably wrong.
void main() {
  const step = Sprint117SupportContract.canonicalStep;

  group('contract surface', () {
    test('covers the six canonical fields in canonical order', () {
      expect(Sprint117SupportContract.requiredFields, <String>[
        'support_playbook',
        'severity_matrix',
        'owners',
        'response_targets',
        'recovery_guides',
        'provider_escalation',
      ]);
    });

    test('declares the canonical step as 117.6', () {
      expect(step, '117.6');
    });

    test('every source manifest it depends on is a committed file', () {
      for (final path in Sprint117SupportContract.sourceManifests) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: 'source manifest $path must exist to be a real source',
        );
      }
    });
  });

  group('live evidence', () {
    late Sprint117SupportReport report;

    setUpAll(() {
      report = const Sprint117SupportGate().evaluate();
    });

    test('reaches a decided verdict on the committed evidence', () {
      expect(
        report.state,
        Sprint117SupportState.pass,
        reason:
            'live violations=${report.violations} '
            'missing=${report.missingFields}',
      );
      expect(report.verdict, Sprint117SupportContract.passVerdict);
      expect(report.missingFields, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('decides the severity matrix from the recorded four levels', () {
      expect(report.severityLevels, <String>['P0', 'P1', 'P2', 'P3']);
      expect(
        report.fieldCoverage['severity_matrix'],
        report.severityLevels.length,
      );
    });

    test(
      'every severity level names an owner, a response target and a guide',
      () {
        for (final level in report.severityLevels) {
          final record = report.severityByLevel[level]!;
          expect(record.owner, isNotEmpty, reason: 'owner missing for $level');
          expect(
            record.maxResponseHours,
            greaterThan(0),
            reason: 'response target missing for $level',
          );
          expect(record.definition, isNotEmpty, reason: 'definition $level');
          expect(
            record.resolutionTargetHours,
            greaterThanOrEqualTo(record.maxResponseHours),
            reason: 'a level cannot resolve before it is answered ($level)',
          );
        }
      },
    );

    test('severity response targets are ordered, not arbitrary', () {
      final p0 = report.severityByLevel['P0']!.maxResponseHours;
      final p1 = report.severityByLevel['P1']!.maxResponseHours;
      final p2 = report.severityByLevel['P2']!.maxResponseHours;
      final p3 = report.severityByLevel['P3']!.maxResponseHours;
      expect(p0, lessThan(p1));
      expect(p1, lessThan(p2));
      expect(p2, lessThan(p3));
    });

    test('every referenced guide and playbook path exists on disk', () {
      for (final path in report.referencedDocuments) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: 'readiness must not point at a missing document: $path',
        );
      }
      expect(report.referencedDocuments, isNotEmpty);
    });

    test(
      'every recovery guide resolves to a real scenario and a real owner',
      () {
        expect(report.recoveryGuides, isNotEmpty);
        for (final guide in report.recoveryGuides) {
          expect(guide.scenario, isNotEmpty);
          expect(guide.guidePath, isNotEmpty);
          expect(guide.owner, isNotEmpty);
          expect(File(guide.guidePath).existsSync(), isTrue);
        }
      },
    );

    test('every escalation path names an owner and an action', () {
      expect(report.escalationPaths, isNotEmpty);
      for (final path in report.escalationPaths) {
        expect(path.trigger, isNotEmpty);
        expect(path.action, isNotEmpty);
        expect(path.owner, isNotEmpty);
      }
    });

    test('provider escalation is decided for the exposed beta surface', () {
      // Provider escalation is the one field a v1.2 support plan cannot supply:
      // 113.5 predates the beta connector set entirely. It is therefore
      // reported per provider, and a provider the rollout never staged is
      // undetermined rather than silently assumed covered. Every provider on
      // the exposed surface must be accounted for exactly once, as either
      // escalated or undetermined — never dropped, never both.
      final anchor = report.anchor!;
      expect(anchor.surfaceProviderIds, isNotEmpty);
      expect(report.escalatedProviders, isNotEmpty);
      final accounted = <String>{
        ...report.escalatedProviders,
        ...report.undeterminedProviders,
      };
      expect(accounted.length, anchor.surfaceProviderIds.length);
      expect(accounted, containsAll(anchor.surfaceProviderIds));
      expect(
        report.violations.where(
          (v) => v.startsWith('provider_escalation_unmapped'),
        ),
        isEmpty,
      );
    });

    test('no provider is escalated without a stop condition it can act on', () {
      for (final providerId in report.escalatedProviders) {
        final record = report.providerEscalation.firstWhere(
          (row) => row.providerId == providerId,
        );
        expect(
          record.stopConditionIds,
          isNotEmpty,
          reason: '$providerId is escalated but no stop condition triggers it',
        );
        expect(
          record.killSwitchId,
          isNotEmpty,
          reason: '$providerId escalated without a kill switch',
        );
        expect(record.owner, isNotEmpty);
      }
    });

    test('declares the incident owner scope the charter already assigned', () {
      // 117.2 assigned the `incident` scope to a charter owner id
      // (`support-owner`). The 113.5 ladder separately records human owner
      // names (`Choirudin`, `nephthys`). Those are two identity namespaces:
      // this asserts the charter scope is carried through, and that the ladder
      // names real responders, without demanding one appear inside the other.
      expect(report.charterIncidentOwner, 'support-owner');
      expect(report.owners, isNotEmpty);
      expect(report.owners, contains('Choirudin'));
      for (final owner in report.owners) {
        expect(owner.trim(), isNotEmpty);
      }
    });

    test(
      'carries the release-cut open item forward instead of dropping it',
      () {
        expect(
          report.openItems.where(
            (item) => item.startsWith('release_cut_pending'),
          ),
          isNotEmpty,
          reason:
              'a plan that silently forgets the release cut turns it into a '
              'surprise later',
        );
      },
    );

    test('never claims a live incident, page, or support channel was used', () {
      expect(report.liveIncidentExecuted, isFalse);
      expect(report.externalGates, Sprint117SupportContract.externalGates);
      expect(report.limitations, isNotEmpty);
    });

    test('reports no open item twice when a carried item is also derived', () {
      // 117.4 already records the cohort verdict in its carried open items and
      // this gate derives the same fact independently. Appending without
      // de-duplication would list one open problem twice and make the manifest
      // look like it found more than it did.
      final openItems = report.openItems;
      expect(
        openItems.toSet().length,
        openItems.length,
        reason:
            'duplicate open items: '
            '${openItems.where((i) => openItems.where((o) => o == i).length > 1).toSet()}',
      );
      expect(
        openItems.where(
          (item) => item.startsWith('upstream_cohort_not_verified'),
        ),
        hasLength(1),
      );
    });
  });

  group('fail-closed on missing anchor', () {
    test('a null anchor is BLOCKED, never a pass', () {
      final report = const Sprint117SupportGate().evaluateWith(
        const Sprint117SupportInput(rows: null, anchor: null),
      );
      expect(report.state, Sprint117SupportState.blocked);
      expect(report.missingFields, contains('support_anchor'));
    });

    test('null rows are BLOCKED and name the row field', () {
      final report = const Sprint117SupportGate().evaluateWith(
        Sprint117SupportInput(rows: null, anchor: _anchor()),
      );
      expect(report.state, Sprint117SupportState.blocked);
      expect(report.missingFields, contains('readiness_rows'));
    });
  });

  group('anchor integrity', () {
    test('a drifted readiness anchor is a violation, not a re-derivation', () {
      final report = const Sprint117SupportGate().evaluateWith(
        Sprint117SupportInput(
          rows: _rows(),
          anchor: _anchor(readinessVerdict: 'SOMETHING_ELSE_LOCAL'),
        ),
      );
      expect(report.state, Sprint117SupportState.fail);
      expect(report.violations, contains('anchor_verdict_drift'));
    });

    test('a blank support verdict is reported as missing evidence', () {
      final report = const Sprint117SupportGate().evaluateWith(
        Sprint117SupportInput(
          rows: _rows(),
          anchor: _anchor(readinessVerdict: '   '),
        ),
      );
      expect(report.state, Sprint117SupportState.blocked);
      expect(report.missingFields, contains('readiness_verdict'));
    });
  });

  group('severity matrix coherence', () {
    test('a severity level outside the recorded vocabulary fails', () {
      final rows = _rows();
      rows.add(
        _severity(
          level: 'P9',
          definition: 'x',
          owner: 'Choirudin',
          maxResponse: 1,
          resolution: 2,
          action: 'halt',
        ),
      );
      final report = const Sprint117SupportGate().evaluateWith(
        Sprint117SupportInput(rows: rows, anchor: _anchor()),
      );
      expect(report.violations, contains('severity_unknown_level:P9'));
    });

    test('a duplicate severity level is one fault, not two rows', () {
      final rows = _rows();
      rows.add(
        _severity(
          level: 'P0',
          definition: 'y',
          owner: 'Choirudin',
          maxResponse: 2,
          resolution: 24,
          action: 'halt',
        ),
      );
      final report = const Sprint117SupportGate().evaluateWith(
        Sprint117SupportInput(rows: rows, anchor: _anchor()),
      );
      expect(report.violations, contains('severity_duplicate:P0'));
    });

    test('a level with no owner is BLOCKED evidence, not a wrong row', () {
      final rows = _rows();
      rows[0] = _severity(
        level: 'P0',
        definition: 'd',
        owner: '',
        maxResponse: 2,
        resolution: 24,
        action: 'halt',
      );
      final report = const Sprint117SupportGate().evaluateWith(
        Sprint117SupportInput(rows: rows, anchor: _anchor()),
      );
      expect(report.state, Sprint117SupportState.blocked);
      expect(report.missingFields, contains('severity_owner:P0'));
    });

    test('a level that answers slower than it resolves is a contradiction', () {
      final rows = _rows();
      rows[0] = _severity(
        level: 'P0',
        definition: 'd',
        owner: 'Choirudin',
        maxResponse: 48,
        resolution: 4,
        action: 'halt',
      );
      final report = const Sprint117SupportGate().evaluateWith(
        Sprint117SupportInput(rows: rows, anchor: _anchor()),
      );
      expect(
        report.violations,
        contains('severity_resolution_before_response:P0'),
      );
    });

    test('a negative response target is refused rather than sorted away', () {
      final rows = _rows();
      rows[0] = _severity(
        level: 'P1',
        definition: 'd',
        owner: 'Choirudin',
        maxResponse: -4,
        resolution: 72,
        action: 'investigate',
      );
      final report = const Sprint117SupportGate().evaluateWith(
        Sprint117SupportInput(rows: rows, anchor: _anchor()),
      );
      expect(report.violations, contains('severity_response_not_positive:P1'));
    });

    test('a level removed from the recorded matrix is an unmapped level', () {
      final rows = _rows()..removeWhere((row) => row.level == 'P3');
      final report = const Sprint117SupportGate().evaluateWith(
        Sprint117SupportInput(rows: rows, anchor: _anchor()),
      );
      expect(report.violations, contains('severity_unmapped:P3'));
    });
  });

  group('owner and response-target coherence', () {
    test(
      'a response target that contradicts the severity record is a drift',
      () {
        final rows = _rows();
        rows[0] = _severity(
          level: 'P0',
          definition: 'd',
          owner: 'Choirudin',
          maxResponse: 2,
          resolution: 24,
          action: 'halt',
        );
        final report = const Sprint117SupportGate().evaluateWith(
          Sprint117SupportInput(
            rows: rows,
            anchor: _anchor(responseTargetHours: const {'P0': 9}),
          ),
        );
        expect(report.violations, contains('response_target_drift:P0:9:2'));
      },
    );

    test('a response target nobody answers to is reported as an open item', () {
      final report = const Sprint117SupportGate().evaluateWith(
        Sprint117SupportInput(
          rows: _rows(),
          anchor: _anchor(responseTargetHours: const {'P9': 1}),
        ),
      );
      expect(report.openItems, contains('response_target_orphan:P9'));
    });
  });

  group('recovery guide and escalation coherence', () {
    test('a guide pointing at a missing document is a violation', () {
      final rows = _rows();
      rows[0] = const Sprint117RecoveryGuideRecord(
        scenario: 'Database corruption',
        guidePath: 'docs/release/does-not-exist-1176.md',
        owner: 'nephthys',
      );
      final report = const Sprint117SupportGate().evaluateWith(
        Sprint117SupportInput(rows: rows, anchor: _anchor()),
      );
      expect(
        report.violations,
        contains(
          'recovery_guide_missing_document:docs/release/does-not-exist-1176.md',
        ),
      );
    });

    test('a guide with no owner leaves recovery unowned', () {
      final rows = _rows();
      rows[0] = const Sprint117RecoveryGuideRecord(
        scenario: 'Database corruption',
        guidePath: Sprint117SupportContract.recoveryGuideRef,
        owner: '',
      );
      final report = const Sprint117SupportGate().evaluateWith(
        Sprint117SupportInput(rows: rows, anchor: _anchor()),
      );
      expect(
        report.missingFields,
        contains('recovery_guide_owner:Database corruption'),
      );
    });

    test('a duplicated scenario is one guide wearing two rows', () {
      final rows = _rows();
      rows.add(
        const Sprint117RecoveryGuideRecord(
          scenario: 'Database corruption or migration failure',
          guidePath: Sprint117SupportContract.recoveryGuideRef,
          owner: 'nephthys',
        ),
      );
      final report = const Sprint117SupportGate().evaluateWith(
        Sprint117SupportInput(rows: rows, anchor: _anchor()),
      );
      expect(
        report.violations,
        contains(
          'recovery_guide_duplicate:Database corruption or migration failure',
        ),
      );
    });

    test('an escalation path with no action cannot be followed', () {
      final rows = _rows();
      rows.add(
        const Sprint117EscalationRecord(
          trigger: 'P0 synthetic trigger',
          action: '',
          owner: 'Choirudin',
          communication: 'direct',
        ),
      );
      final report = const Sprint117SupportGate().evaluateWith(
        Sprint117SupportInput(rows: rows, anchor: _anchor()),
      );
      expect(
        report.violations,
        contains('escalation_action_blank:P0 synthetic trigger'),
      );
    });

    test('an escalation path with no owner is unowned, not wrong', () {
      final rows = _rows();
      rows.add(
        const Sprint117EscalationRecord(
          trigger: 'P1 synthetic trigger',
          action: 'investigate',
          owner: '',
          communication: 'tracker',
        ),
      );
      final report = const Sprint117SupportGate().evaluateWith(
        Sprint117SupportInput(rows: rows, anchor: _anchor()),
      );
      expect(
        report.missingFields,
        contains('escalation_owner:P1 synthetic trigger'),
      );
    });
  });

  group('provider escalation is decided per provider, never assumed', () {
    test('a provider the sources never staged is undetermined, not failed', () {
      // This is the core 117.6 concept. 113.5 predates the beta connector set,
      // so most providers have no recorded provider-escalation decision. Calling
      // those violations would report an unfinished plan as a broken one. Every
      // surfaced provider is listed as undetermined here, plus one off-surface
      // entry, and the gate must still pass.
      final report = const Sprint117SupportGate().evaluateWith(
        Sprint117SupportInput(
          rows: _rows(),
          anchor: _anchor(
            undeterminedProviders: const ['gemini', 'unsourced_provider'],
          ),
        ),
      );
      expect(
        report.state,
        Sprint117SupportState.pass,
        reason: 'violations=${report.violations}',
      );
      expect(report.violations, isEmpty);
      expect(report.undeterminedProviders, contains('unsourced_provider'));
      expect(report.escalatedProviders, contains('openai'));
    });

    test('an escalated provider with no stop condition is a violation', () {
      final report = const Sprint117SupportGate().evaluateWith(
        Sprint117SupportInput(
          rows: _rows(),
          anchor: _anchor(
            undeterminedProviders: const <String>[],
            escalated: <Sprint117ProviderEscalationRecord>[
              Sprint117ProviderEscalationRecord(
                providerId: 'gemini',
                killSwitchId: 'kill_gemini',
                stopConditionIds: <String>[],
                owner: 'Choirudin',
              ),
            ],
          ),
        ),
      );
      expect(report.violations, contains('provider_escalation_no_stop:gemini'));
    });

    test('an escalated provider with no kill switch cannot be contained', () {
      final report = const Sprint117SupportGate().evaluateWith(
        Sprint117SupportInput(
          rows: _rows(),
          anchor: _anchor(
            undeterminedProviders: const <String>[],
            escalated: <Sprint117ProviderEscalationRecord>[
              Sprint117ProviderEscalationRecord(
                providerId: 'gemini',
                killSwitchId: '',
                stopConditionIds: <String>['stop_ghost'],
                owner: 'Choirudin',
              ),
            ],
          ),
        ),
      );
      expect(report.violations, contains('provider_escalation_no_kill:gemini'));
    });

    test('a provider escalation the sources never stage is unsourced', () {
      final report = const Sprint117SupportGate().evaluateWith(
        Sprint117SupportInput(
          rows: _rows(),
          anchor: _anchor(
            escalated: <Sprint117ProviderEscalationRecord>[
              Sprint117ProviderEscalationRecord(
                providerId: 'unlisted_provider',
                killSwitchId: 'kill_openai',
                stopConditionIds: <String>['stop_alpha_auth'],
                owner: 'Choirudin',
              ),
            ],
          ),
        ),
      );
      expect(
        report.violations,
        contains('provider_escalation_unlisted:unlisted_provider'),
      );
    });

    test('a stop condition that no source records cannot be cited', () {
      final report = const Sprint117SupportGate().evaluateWith(
        Sprint117SupportInput(
          rows: _rows(),
          anchor: _anchor(
            escalated: <Sprint117ProviderEscalationRecord>[
              Sprint117ProviderEscalationRecord(
                providerId: 'openai',
                killSwitchId: 'kill_openai',
                stopConditionIds: <String>['stop_invented'],
                owner: 'Choirudin',
              ),
            ],
          ),
        ),
      );
      expect(
        report.violations,
        contains('provider_stop_unsourced:openai:stop_invented'),
      );
    });

    test('a kill switch no source records cannot be the containment path', () {
      final report = const Sprint117SupportGate().evaluateWith(
        Sprint117SupportInput(
          rows: _rows(),
          anchor: _anchor(
            escalated: <Sprint117ProviderEscalationRecord>[
              Sprint117ProviderEscalationRecord(
                providerId: 'openai',
                killSwitchId: 'kill_invented',
                stopConditionIds: <String>['stop_alpha_auth'],
                owner: 'Choirudin',
              ),
            ],
          ),
        ),
      );
      expect(
        report.violations,
        contains('provider_kill_drift:openai:kill_invented:kill_openai'),
      );
    });

    test('a provider in both sets is one contradiction, not two decisions', () {
      final report = const Sprint117SupportGate().evaluateWith(
        Sprint117SupportInput(
          rows: _rows(),
          anchor: _anchor(undeterminedProviders: const ['openai']),
        ),
      );
      expect(report.violations, contains('provider_escalation_overlap:openai'));
    });
  });

  group('secret hygiene', () {
    test('no readiness row carries a credential-shaped value', () {
      final forbidden = <String>[
        'sk-',
        'api_key',
        'apikey',
        'bearer ',
        'private_key',
        'password=',
        'token=',
      ];
      for (final entry in _rows().map((row) => row.toJson()).toList()) {
        final text = jsonEncode(entry).toLowerCase();
        for (final needle in forbidden) {
          expect(
            text.contains(needle),
            isFalse,
            reason: 'readiness row leaks $needle: ${entry['level']}',
          );
        }
      }
    });
  });
}

Sprint117SupportAnchor _anchor({
  String readinessVerdict = 'SUPPORT_READINESS_DEFINED',
  Map<String, int> responseTargetHours = const {
    'P0': 2,
    'P1': 8,
    'P2': 24,
    'P3': 72,
  },
  List<String> undeterminedProviders = const ['gemini'],
  List<Sprint117ProviderEscalationRecord>? escalated,
}) {
  return Sprint117SupportAnchor(
    readinessVerdict: readinessVerdict,
    supportVerdict: 'COHORT_CONSENT_VERIFICATION_FAILED',
    charterVerdict: 'CHARTER_COMPLETE_LOCAL',
    exposureVerdict: 'CERTIFICATION_SNAPSHOT_LOCKED_LOCAL',
    severityLevels: const <String>['P0', 'P1', 'P2', 'P3'],
    responseTargetHours: responseTargetHours,
    recordedResponseTargetHours: responseTargetHours,
    surfaceProviderIds: const ['openai', 'gemini'],
    providerKill: const {'openai': 'kill_openai', 'gemini': 'kill_gemini'},
    recordedStopIds: const [
      'stop_internal_error',
      'stop_alpha_error',
      'stop_alpha_auth',
      'stop_waitlist_error',
      'stop_waitlist_crash',
    ],
    providerStopConditions: const {
      'openai': <String>[
        'stop_internal_error',
        'stop_alpha_error',
        'stop_alpha_auth',
        'stop_waitlist_error',
        'stop_waitlist_crash',
      ],
    },
    undrilledKillIds: const ['kill_openai', 'kill_gemini'],
    escalatedProviders:
        escalated ??
        <Sprint117ProviderEscalationRecord>[
          Sprint117ProviderEscalationRecord(
            providerId: 'openai',
            killSwitchId: 'kill_openai',
            stopConditionIds: <String>['stop_alpha_auth'],
            owner: 'Choirudin',
          ),
        ],
    undeterminedProviders: undeterminedProviders,
    charterIncidentOwner: 'support-owner',
    carriedOpenItems: const [
      'release_cut_pending: pubspec 1.2.0-rc.1 != v1.3.0-beta.1',
    ],
  );
}

Sprint117SeverityRecord _severity({
  required String level,
  required String definition,
  required String owner,
  required int maxResponse,
  required int resolution,
  required String action,
}) {
  return Sprint117SeverityRecord(
    level: level,
    definition: definition,
    responseTarget: action,
    maxResponseHours: maxResponse,
    resolutionTargetHours: resolution,
    owner: owner,
  );
}

List<Sprint117ReadinessRow> _rows() {
  return <Sprint117ReadinessRow>[
    _severity(
      level: 'P0',
      definition: 'Kehilangan/korupsi data yang dapat direproduksi',
      owner: 'Choirudin',
      maxResponse: 2,
      resolution: 24,
      action: 'Immediate',
    ),
    _severity(
      level: 'P1',
      definition: 'Project tidak dapat dibuka',
      owner: 'Choirudin',
      maxResponse: 8,
      resolution: 72,
      action: 'Urgent',
    ),
    _severity(
      level: 'P2',
      definition: 'Fungsi salah dengan workaround aman',
      owner: 'nephthys',
      maxResponse: 24,
      resolution: 168,
      action: 'Normal',
    ),
    _severity(
      level: 'P3',
      definition: 'Kosmetik, dokumentasi, atau friction non-blocking',
      owner: 'nephthys',
      maxResponse: 72,
      resolution: 336,
      action: 'Low',
    ),
    const Sprint117RecoveryGuideRecord(
      scenario: 'Database corruption or migration failure',
      guidePath: Sprint117SupportContract.recoveryGuideRef,
      owner: 'nephthys',
    ),
    const Sprint117RecoveryGuideRecord(
      scenario: 'Security/privacy incident',
      guidePath: 'docs/release/hotfix-runbook-v1.0.1.md',
      owner: 'Choirudin',
    ),
    const Sprint117EscalationRecord(
      trigger: 'P0 data loss or security incident',
      action: 'Immediate halt of distribution',
      owner: 'Choirudin',
      communication: 'Direct channel',
    ),
    const Sprint117EscalationRecord(
      trigger: 'External dependency failure (AI provider, OS update)',
      action: 'Document workaround, notify users via release notes',
      owner: 'nephthys',
      communication: 'Release notes',
    ),
  ];
}
