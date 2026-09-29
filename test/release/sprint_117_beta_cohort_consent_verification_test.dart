import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_beta_cohort_consent_verification.dart';

const String _cohortArtifact =
    'docs/planning/v1.3/sprint_117_beta_cohort_consent_verification.json';

const String _liveSource = Sprint117CohortContract.liveSource;

Sprint117CohortParticipant _participant({
  String participantId = 'project_alpha_01',
  String cohortId = 'cohort_alpha',
  List<String> consentedCategories = const <String>['novel_text'],
  List<String> usedProviders = const <String>['openai'],
  String source = _liveSource,
  String? evidenceRef = 'docs/evidence/beta/consent_alpha_01.json',
}) => Sprint117CohortParticipant(
  participantId: participantId,
  cohortId: cohortId,
  consentedCategories: consentedCategories,
  usedProviders: usedProviders,
  source: source,
  evidenceRef: evidenceRef,
);

Sprint117CohortConsent _consent({
  String consentId = 'consent_alpha_01',
  String participantId = 'project_alpha_01',
  String cohortId = 'cohort_alpha',
  bool explicitOptIn = true,
  String policyVersion = 'beta-consent-1.0',
  int grantedAtEpochMs = 1759276800000,
  List<String> coveredCategories = const <String>['novel_text'],
  String source = _liveSource,
  String? evidenceRef = 'docs/evidence/beta/consent_alpha_01.json',
}) => Sprint117CohortConsent(
  consentId: consentId,
  participantId: participantId,
  cohortId: cohortId,
  explicitOptIn: explicitOptIn,
  policyVersion: policyVersion,
  grantedAtEpochMs: grantedAtEpochMs,
  coveredCategories: coveredCategories,
  source: source,
  evidenceRef: evidenceRef,
);

Sprint117CohortCoverage _coverage({
  String providerId = 'openai',
  String connectorId = 'conn_openai',
  String stage = 'live',
  String consentRef = 'consent_alpha_01',
  String destinationHost = 'api.openai.com',
  String? reason,
}) => Sprint117CohortCoverage(
  providerId: providerId,
  connectorId: connectorId,
  stage: stage,
  consentRef: consentRef,
  destinationHost: destinationHost,
  reason: reason,
);

Sprint117CohortBoundary _boundary({
  String boundaryId = 'boundary_novel',
  String category = 'novel_text',
  bool leavesDevice = true,
  String destination = 'api.openai.com',
  bool encryptionInTransit = true,
  int retentionDays = 30,
  String source = _liveSource,
  String? evidenceRef = 'docs/evidence/beta/boundary_novel.json',
}) => Sprint117CohortBoundary(
  boundaryId: boundaryId,
  category: category,
  leavesDevice: leavesDevice,
  destination: destination,
  encryptionInTransit: encryptionInTransit,
  retentionDays: retentionDays,
  source: source,
  evidenceRef: evidenceRef,
);

Sprint117CohortWithdrawal _withdrawal({
  String withdrawalId = 'withdrawal_beta',
  String mechanism = 'in_app_settings',
  int deadlineDays = 7,
  List<String> coveredCategories = const <String>['novel_text'],
  bool noPenalty = true,
  String source = _liveSource,
  String? evidenceRef = 'docs/evidence/beta/withdrawal_beta.json',
}) => Sprint117CohortWithdrawal(
  withdrawalId: withdrawalId,
  mechanism: mechanism,
  deadlineDays: deadlineDays,
  coveredCategories: coveredCategories,
  noPenalty: noPenalty,
  source: source,
  evidenceRef: evidenceRef,
);

Sprint117CohortSupport _support({
  String supportId = 'support_alpha',
  String channel = 'in_app',
  String scope = 'cohort_alpha',
  int responseSlaHours = 48,
  String escalationPath = 'in_app_thread -> maintainer_inbox',
  String source = _liveSource,
  String? evidenceRef = 'docs/evidence/beta/support_alpha.json',
}) => Sprint117CohortSupport(
  supportId: supportId,
  channel: channel,
  scope: scope,
  responseSlaHours: responseSlaHours,
  escalationPath: escalationPath,
  source: source,
  evidenceRef: evidenceRef,
);

Sprint117CohortAnchor _anchor({
  String entryVerdict = Sprint117CohortContract.entryVerdict,
  String charterVerdict = Sprint117CohortContract.charterVerdict,
  List<String> exposedSubset = const <String>['openai', 'gemini'],
  List<String> hiddenSubset = const <String>['saweria'],
  List<String> destinationProviders = const <String>[
    'api.openai.com',
    'api.gemini.com',
  ],
  bool planLiveBetaExecution = true,
  List<String> planCohorts = const <String>['cohort_alpha'],
  List<String> carriedOpenItems = const <String>[
    'release_cut_pending: pubspec 1.2.0-rc.1 != v1.3.0-beta.1',
  ],
}) => Sprint117CohortAnchor(
  entryVerdict: entryVerdict,
  charterVerdict: charterVerdict,
  exposedSubset: exposedSubset,
  hiddenSubset: hiddenSubset,
  destinationProviders: destinationProviders,
  planLiveBetaExecution: planLiveBetaExecution,
  planCohorts: planCohorts,
  carriedOpenItems: carriedOpenItems,
);

/// A fully live, self-consistent fixture. Every rule test derives from this by
/// breaking exactly one thing, so a rule can never be masked by an unrelated
/// defect in the default fixture.
///
/// The sentinel matters: a plain `?? default` cannot tell "argument omitted"
/// from "explicitly null", which would silently mask the null-input rules.
const Object _omitted = Object();

Sprint117CohortInput _input({
  Object? participants = _omitted,
  Object? consents = _omitted,
  Object? coverage = _omitted,
  Object? boundaries = _omitted,
  Object? withdrawals = _omitted,
  Object? supports = _omitted,
  Object? anchor = _omitted,
}) => Sprint117CohortInput(
  participants: identical(participants, _omitted)
      ? <Sprint117CohortParticipant>[_participant()]
      : participants as List<Sprint117CohortParticipant>?,
  consents: identical(consents, _omitted)
      ? <Sprint117CohortConsent>[_consent()]
      : consents as List<Sprint117CohortConsent>?,
  coverage: identical(coverage, _omitted)
      ? <Sprint117CohortCoverage>[_coverage()]
      : coverage as List<Sprint117CohortCoverage>?,
  boundaries: identical(boundaries, _omitted)
      ? <Sprint117CohortBoundary>[_boundary()]
      : boundaries as List<Sprint117CohortBoundary>?,
  withdrawals: identical(withdrawals, _omitted)
      ? <Sprint117CohortWithdrawal>[_withdrawal()]
      : withdrawals as List<Sprint117CohortWithdrawal>?,
  supports: identical(supports, _omitted)
      ? <Sprint117CohortSupport>[_support()]
      : supports as List<Sprint117CohortSupport>?,
  anchor: identical(anchor, _omitted)
      ? _anchor()
      : anchor as Sprint117CohortAnchor?,
);

Sprint117CohortReport _evaluate(Sprint117CohortInput input) =>
    Sprint117CohortGate().evaluateWith(input);

void main() {
  group('117.3 Beta Cohort & Consent Verification contract', () {
    test(
      'canonical step is 117.3 and matches the required contract fields',
      () {
        expect(Sprint117CohortContract.canonicalStep, '117.3');
        expect(Sprint117CohortContract.requiredFields, <String>[
          'participant_or_project_id',
          'consent',
          'provider_coverage',
          'data_boundaries',
          'withdrawal',
          'support',
        ]);
      },
    );

    test('the six required fields are exactly the canonical 117.3 fields', () {
      const canonical = <String>[
        'participant_or_project_id',
        'consent',
        'provider_coverage',
        'data_boundaries',
        'withdrawal',
        'support',
      ];
      expect(Sprint117CohortContract.requiredFields, canonical);
    });

    test('the manifest, plan, privacy, entry and charter paths are pinned', () {
      expect(Sprint117CohortContract.manifestPath, _cohortArtifact);
      expect(
        Sprint117CohortContract.planManifestPath,
        'docs/planning/v1.2/sprint_116_beta_cohort_consent_plan.json',
      );
      expect(
        Sprint117CohortContract.privacyManifestPath,
        'docs/planning/v1.2/sprint_116_privacy_compliance_gate.json',
      );
      expect(
        Sprint117CohortContract.entryManifestPath,
        'docs/planning/v1.3/sprint_117_beta_entry_gate.json',
      );
      expect(
        Sprint117CohortContract.charterManifestPath,
        'docs/planning/v1.3/sprint_117_beta_validation_charter.json',
      );
    });

    test('a complete live cohort verifies as pass', () {
      final report = _evaluate(_input());
      expect(report.state, Sprint117CohortState.pass);
      expect(report.verdict, Sprint117CohortContract.passVerdict);
      expect(report.violations, isEmpty);
      expect(report.missingFields, isEmpty);
    });

    test('verification never claims a live beta it cannot evidence', () {
      final report = _evaluate(_input());
      expect(report.liveBetaExecuted, isTrue);
      expect(report.noFabricatedParticipants, isTrue);
    });

    test('the report exposes the participant count it actually verified', () {
      final report = _evaluate(_input());
      expect(report.verifiedParticipantCount, 1);
    });
  });

  group('117.3 anchor rules', () {
    test('a missing anchor is missing evidence, not a contradiction', () {
      final report = _evaluate(_input(anchor: null));
      expect(report.missingFields, contains('entry_anchor'));
    });

    test('an entry verdict other than the 117.1 one blocks verification', () {
      final report = _evaluate(
        _input(anchor: _anchor(entryVerdict: 'BETA_ENTRY_BLOCKED')),
      );
      expect(report.missingFields, contains('entry_anchor'));
    });

    test('a charter verdict other than the 117.2 one blocks verification', () {
      final report = _evaluate(
        _input(anchor: _anchor(charterVerdict: 'CHARTER_MISSING')),
      );
      expect(report.missingFields, contains('charter_anchor'));
    });

    test('claiming live participants the plan never authorised fails', () {
      final report = _evaluate(
        _input(anchor: _anchor(planLiveBetaExecution: false)),
      );
      expect(
        report.violations,
        contains('live_execution_claimed_without_plan'),
      );
    });

    test('an honest report that found nobody is not penalised', () {
      // The plan says no beta ran. Reporting zero participants is the truthful
      // outcome and must be BLOCKED on missing evidence, never FAILed for the
      // plan's own state. Every dependent list is dropped with the roster,
      // because coverage pointing at a consent record that does not exist is a
      // genuine contradiction, not an artefact of this test.
      final report = _evaluate(
        _input(
          anchor: _anchor(planLiveBetaExecution: false),
          participants: const <Sprint117CohortParticipant>[],
          consents: const <Sprint117CohortConsent>[],
          coverage: const <Sprint117CohortCoverage>[],
        ),
      );
      expect(
        report.violations,
        isNot(contains('live_execution_claimed_without_plan')),
      );
      expect(report.violations, isEmpty);
      expect(report.state, Sprint117CohortState.blocked);
    });

    test('the carried release-cut open item is not dropped silently', () {
      final report = _evaluate(
        _input(
          anchor: _anchor(
            carriedOpenItems: const <String>[
              'release_cut_pending: pubspec 1.2.0-rc.1 != v1.3.0-beta.1',
            ],
          ),
        ),
      );
      expect(
        report.openItems,
        contains('release_cut_pending: pubspec 1.2.0-rc.1 != v1.3.0-beta.1'),
      );
    });

    test('a cohort outside the committed plan fails', () {
      final report = _evaluate(
        _input(
          participants: <Sprint117CohortParticipant>[
            _participant(cohortId: 'cohort_invented'),
          ],
        ),
      );
      expect(
        report.violations,
        contains('participant_cohort_unknown:cohort_invented'),
      );
    });
  });

  group('117.3 participant rules', () {
    test('an empty cohort is missing evidence, not a pass', () {
      final report = _evaluate(
        _input(participants: const <Sprint117CohortParticipant>[]),
      );
      expect(report.missingFields, contains('participant_or_project_id'));
      expect(report.state, isNot(Sprint117CohortState.pass));
    });

    test('a null cohort is missing evidence', () {
      final report = _evaluate(_input(participants: null));
      expect(report.missingFields, contains('participant_or_project_id'));
    });

    test('a blank participant id fails', () {
      final report = _evaluate(
        _input(
          participants: <Sprint117CohortParticipant>[
            _participant(participantId: '   '),
          ],
        ),
      );
      expect(report.violations, contains('participant_id_blank:cohort_alpha'));
    });

    test('a duplicated participant id fails', () {
      final report = _evaluate(
        _input(
          participants: <Sprint117CohortParticipant>[
            _participant(),
            _participant(),
          ],
        ),
      );
      expect(
        report.violations,
        contains('participant_duplicate:project_alpha_01'),
      );
    });

    test(
      'a plan-stage participant is unverified evidence, not a violation',
      () {
        final report = _evaluate(
          _input(
            participants: <Sprint117CohortParticipant>[
              _participant(source: 'synthetic_local', evidenceRef: null),
            ],
          ),
        );
        expect(
          report.missingFields,
          contains('participant_unverified:project_alpha_01'),
        );
        expect(report.state, Sprint117CohortState.blocked);
      },
    );

    test('a live participant without an evidence reference is unverified', () {
      final report = _evaluate(
        _input(
          participants: <Sprint117CohortParticipant>[
            _participant(evidenceRef: null),
          ],
        ),
      );
      expect(
        report.missingFields,
        contains('participant_unverified:project_alpha_01'),
      );
    });

    test('a blank evidence reference counts as no evidence', () {
      final report = _evaluate(
        _input(
          participants: <Sprint117CohortParticipant>[
            _participant(evidenceRef: '  '),
          ],
        ),
      );
      expect(
        report.missingFields,
        contains('participant_unverified:project_alpha_01'),
      );
    });
  });

  group('117.3 consent rules', () {
    test('consent with no record at all is missing evidence', () {
      final report = _evaluate(
        _input(consents: const <Sprint117CohortConsent>[]),
      );
      expect(report.missingFields, contains('consent'));
    });

    test('an enrolled participant without consent fails', () {
      final report = _evaluate(
        _input(consents: const <Sprint117CohortConsent>[]),
      );
      expect(
        report.missingFields,
        isNot(contains('participant_or_project_id')),
      );
    });

    test('consent that is not explicit opt-in fails', () {
      final report = _evaluate(
        _input(
          consents: <Sprint117CohortConsent>[_consent(explicitOptIn: false)],
        ),
      );
      expect(report.violations, contains('consent_opt_in:consent_alpha_01'));
    });

    test('consent without a policy version fails', () {
      final report = _evaluate(
        _input(
          consents: <Sprint117CohortConsent>[_consent(policyVersion: '  ')],
        ),
      );
      expect(report.violations, contains('consent_policy:consent_alpha_01'));
    });

    test('consent without a grant timestamp fails', () {
      final report = _evaluate(
        _input(
          consents: <Sprint117CohortConsent>[_consent(grantedAtEpochMs: 0)],
        ),
      );
      expect(report.violations, contains('consent_timestamp:consent_alpha_01'));
    });

    test('consent covering no category fails', () {
      final report = _evaluate(
        _input(
          consents: <Sprint117CohortConsent>[
            _consent(coveredCategories: const <String>[]),
          ],
        ),
      );
      expect(report.violations, contains('consent_category:consent_alpha_01'));
    });

    test('a duplicate consent id fails', () {
      final report = _evaluate(
        _input(consents: <Sprint117CohortConsent>[_consent(), _consent()]),
      );
      expect(report.violations, contains('consent_duplicate:consent_alpha_01'));
    });

    test('consent recorded for a participant who is not enrolled fails', () {
      final report = _evaluate(
        _input(
          consents: <Sprint117CohortConsent>[
            _consent(participantId: 'project_ghost'),
          ],
        ),
      );
      expect(
        report.violations,
        contains('consent_participant_unknown:consent_alpha_01:project_ghost'),
      );
    });

    test(
      'a consent row that names nobody is unverified, not a contradiction',
      () {
        // With nobody enrolled, an unnamed consent row is simply incomplete.
        final report = _evaluate(
          _input(
            consents: <Sprint117CohortConsent>[_consent(participantId: '')],
          ),
        );
        expect(
          report.missingFields,
          contains('consent_participant_missing:consent_alpha_01'),
        );
        expect(
          report.violations,
          isNot(contains('consent_participant_unknown:consent_alpha_01:')),
        );
      },
    );

    test('consent disagreeing with the participant cohort fails', () {
      final report = _evaluate(
        _input(
          consents: <Sprint117CohortConsent>[
            _consent(cohortId: 'cohort_other'),
          ],
        ),
      );
      expect(
        report.violations,
        contains('consent_cohort_mismatch:consent_alpha_01'),
      );
    });

    test('an enrolled participant with no consent record fails', () {
      final report = _evaluate(
        _input(
          participants: <Sprint117CohortParticipant>[
            _participant(),
            _participant(participantId: 'project_alpha_02'),
          ],
          consents: <Sprint117CohortConsent>[_consent()],
        ),
      );
      expect(report.violations, contains('consent_uncovered:project_alpha_02'));
    });

    test('plan-stage consent is unverified evidence', () {
      final report = _evaluate(
        _input(
          consents: <Sprint117CohortConsent>[
            _consent(source: 'synthetic_local', evidenceRef: null),
          ],
        ),
      );
      expect(
        report.missingFields,
        contains('consent_unverified:consent_alpha_01'),
      );
    });

    test('a consented category with no data boundary fails', () {
      final report = _evaluate(
        _input(
          consents: <Sprint117CohortConsent>[
            _consent(
              coveredCategories: const <String>['novel_text', 'biography'],
            ),
          ],
          boundaries: <Sprint117CohortBoundary>[_boundary()],
        ),
      );
      expect(
        report.violations,
        contains('consent_category_unbounded:biography'),
      );
    });
  });

  group('117.3 provider coverage rules', () {
    test('empty coverage is missing evidence', () {
      final report = _evaluate(
        _input(coverage: const <Sprint117CohortCoverage>[]),
      );
      expect(report.missingFields, contains('provider_coverage'));
    });

    test('coverage for a provider outside the exposed beta subset fails', () {
      final report = _evaluate(
        _input(
          coverage: <Sprint117CohortCoverage>[
            _coverage(providerId: 'leaked_connector'),
          ],
        ),
      );
      expect(
        report.violations,
        contains('coverage_provider_not_exposed:leaked_connector'),
      );
    });

    test(
      'coverage for a hidden provider fails even when the subset allows it',
      () {
        final report = _evaluate(
          _input(
            coverage: <Sprint117CohortCoverage>[
              _coverage(providerId: 'saweria'),
            ],
          ),
        );
        expect(
          report.violations,
          contains('coverage_provider_blocked:saweria'),
        );
      },
    );

    test('coverage without a connector id fails', () {
      final report = _evaluate(
        _input(
          coverage: <Sprint117CohortCoverage>[_coverage(connectorId: '  ')],
        ),
      );
      expect(report.violations, contains('coverage_connector_blank:openai'));
    });

    test('coverage without a stage fails', () {
      final report = _evaluate(
        _input(coverage: <Sprint117CohortCoverage>[_coverage(stage: '')]),
      );
      expect(report.violations, contains('coverage_stage_blank:openai'));
    });

    test('coverage whose consent reference does not resolve fails', () {
      final report = _evaluate(
        _input(
          coverage: <Sprint117CohortCoverage>[
            _coverage(consentRef: 'consent_does_not_exist'),
          ],
        ),
      );
      expect(
        report.violations,
        contains('coverage_consent_unresolved:openai:consent_does_not_exist'),
      );
    });

    test('a provider a participant actually used but nobody covered fails', () {
      final report = _evaluate(
        _input(
          participants: <Sprint117CohortParticipant>[
            _participant(usedProviders: const <String>['openai', 'gemini']),
          ],
          coverage: <Sprint117CohortCoverage>[_coverage()],
        ),
      );
      expect(report.violations, contains('coverage_provider_uncovered:gemini'));
    });

    test('a covered provider with no recorded privacy destination fails', () {
      final report = _evaluate(
        _input(
          anchor: _anchor(
            destinationProviders: const <String>['api.gemini.com'],
          ),
        ),
      );
      expect(
        report.violations,
        contains('coverage_destination_unrecorded:openai'),
      );
    });

    test('a coverage row whose destination host was never assessed fails', () {
      final report = _evaluate(
        _input(
          coverage: <Sprint117CohortCoverage>[
            _coverage(destinationHost: 'api.unassessed.example'),
          ],
        ),
      );
      expect(
        report.violations,
        contains('coverage_destination_unrecorded:openai'),
      );
    });

    test('a coverage row with no destination host at all fails', () {
      final report = _evaluate(
        _input(
          coverage: <Sprint117CohortCoverage>[_coverage(destinationHost: '  ')],
        ),
      );
      expect(
        report.violations,
        contains('coverage_destination_unrecorded:openai'),
      );
    });

    test('a duplicated coverage row fails', () {
      final report = _evaluate(
        _input(coverage: <Sprint117CohortCoverage>[_coverage(), _coverage()]),
      );
      expect(report.violations, contains('coverage_duplicate:openai'));
    });
  });

  group('117.3 data boundary rules', () {
    test('empty boundaries are missing evidence', () {
      final report = _evaluate(
        _input(boundaries: const <Sprint117CohortBoundary>[]),
      );
      expect(report.missingFields, contains('data_boundaries'));
    });

    test('a boundary without a category fails', () {
      final report = _evaluate(
        _input(boundaries: <Sprint117CohortBoundary>[_boundary(category: ' ')]),
      );
      expect(
        report.violations,
        contains('boundary_category_blank:boundary_novel'),
      );
    });

    test('data that leaves the device with no destination fails', () {
      final report = _evaluate(
        _input(
          boundaries: <Sprint117CohortBoundary>[_boundary(destination: '  ')],
        ),
      );
      expect(
        report.violations,
        contains('boundary_destination:boundary_novel'),
      );
    });

    test('data that leaves the device unencrypted fails', () {
      final report = _evaluate(
        _input(
          boundaries: <Sprint117CohortBoundary>[
            _boundary(encryptionInTransit: false),
          ],
        ),
      );
      expect(report.violations, contains('boundary_encryption:boundary_novel'));
    });

    test('a boundary with unbounded retention fails', () {
      final report = _evaluate(
        _input(
          boundaries: <Sprint117CohortBoundary>[_boundary(retentionDays: 0)],
        ),
      );
      expect(report.violations, contains('boundary_retention:boundary_novel'));
    });

    test('a duplicated boundary id fails', () {
      final report = _evaluate(
        _input(boundaries: <Sprint117CohortBoundary>[_boundary(), _boundary()]),
      );
      expect(report.violations, contains('boundary_duplicate:boundary_novel'));
    });

    test('a plan-stage boundary is unverified evidence', () {
      final report = _evaluate(
        _input(
          boundaries: <Sprint117CohortBoundary>[
            _boundary(source: 'synthetic_local', evidenceRef: null),
          ],
        ),
      );
      expect(
        report.missingFields,
        contains('boundary_unverified:boundary_novel'),
      );
    });
  });

  group('117.3 withdrawal rules', () {
    test('no withdrawal mechanism is missing evidence', () {
      final report = _evaluate(
        _input(withdrawals: const <Sprint117CohortWithdrawal>[]),
      );
      expect(report.missingFields, contains('withdrawal'));
    });

    test('withdrawal without a mechanism fails', () {
      final report = _evaluate(
        _input(
          withdrawals: <Sprint117CohortWithdrawal>[_withdrawal(mechanism: ' ')],
        ),
      );
      expect(
        report.violations,
        contains('withdrawal_mechanism:withdrawal_beta'),
      );
    });

    test('withdrawal with no deadline fails', () {
      final report = _evaluate(
        _input(
          withdrawals: <Sprint117CohortWithdrawal>[
            _withdrawal(deadlineDays: 0),
          ],
        ),
      );
      expect(
        report.violations,
        contains('withdrawal_deadline:withdrawal_beta'),
      );
    });

    test('withdrawal that penalises the participant fails', () {
      final report = _evaluate(
        _input(
          withdrawals: <Sprint117CohortWithdrawal>[
            _withdrawal(noPenalty: false),
          ],
        ),
      );
      expect(report.violations, contains('withdrawal_penalty:withdrawal_beta'));
    });

    test('a consented category the withdrawal cannot reach fails', () {
      final report = _evaluate(
        _input(
          consents: <Sprint117CohortConsent>[
            _consent(
              coveredCategories: const <String>['novel_text', 'biography'],
            ),
          ],
          boundaries: <Sprint117CohortBoundary>[
            _boundary(),
            _boundary(boundaryId: 'boundary_bio', category: 'biography'),
          ],
          withdrawals: <Sprint117CohortWithdrawal>[_withdrawal()],
        ),
      );
      expect(
        report.violations,
        contains('withdrawal_category_uncovered:biography'),
      );
    });

    test('a plan-stage withdrawal is unverified evidence', () {
      final report = _evaluate(
        _input(
          withdrawals: <Sprint117CohortWithdrawal>[
            _withdrawal(source: 'synthetic_local', evidenceRef: null),
          ],
        ),
      );
      expect(
        report.missingFields,
        contains('withdrawal_unverified:withdrawal_beta'),
      );
    });
  });

  group('117.3 support rules', () {
    test('no support channel is missing evidence', () {
      final report = _evaluate(
        _input(supports: const <Sprint117CohortSupport>[]),
      );
      expect(report.missingFields, contains('support'));
    });

    test('support without a channel fails', () {
      final report = _evaluate(
        _input(supports: <Sprint117CohortSupport>[_support(channel: ' ')]),
      );
      expect(report.violations, contains('support_channel:support_alpha'));
    });

    test('support with no response SLA fails', () {
      final report = _evaluate(
        _input(
          supports: <Sprint117CohortSupport>[_support(responseSlaHours: 0)],
        ),
      );
      expect(report.violations, contains('support_sla:support_alpha'));
    });

    test('support without an escalation path fails', () {
      final report = _evaluate(
        _input(
          supports: <Sprint117CohortSupport>[_support(escalationPath: ' ')],
        ),
      );
      expect(report.violations, contains('support_escalation:support_alpha'));
    });

    test('an enrolled cohort with no support scope fails', () {
      // The rule names the cohort left without support, not the unused scope
      // the support row happened to declare.
      final report = _evaluate(
        _input(
          supports: <Sprint117CohortSupport>[_support(scope: 'cohort_other')],
        ),
      );
      expect(
        report.violations,
        contains('support_cohort_uncovered:cohort_alpha'),
      );
    });

    test('a global support scope covers every enrolled cohort', () {
      final report = _evaluate(
        _input(
          supports: <Sprint117CohortSupport>[_support(scope: 'beta_global')],
        ),
      );
      expect(report.violations, isEmpty);
      expect(report.state, Sprint117CohortState.pass);
    });

    test('a plan-stage support row is unverified evidence', () {
      final report = _evaluate(
        _input(
          supports: <Sprint117CohortSupport>[
            _support(source: 'synthetic_local', evidenceRef: null),
          ],
        ),
      );
      expect(
        report.missingFields,
        contains('support_unverified:support_alpha'),
      );
    });

    test('a global scope does not excuse unverified support evidence', () {
      // A global scope covers every cohort, so the coverage rule is satisfied;
      // it must not be able to suppress the unverified-evidence rule.
      final report = _evaluate(
        _input(
          supports: <Sprint117CohortSupport>[
            _support(
              scope: Sprint117CohortContract.globalSupportScope,
              source: 'synthetic_local',
              evidenceRef: null,
            ),
          ],
        ),
      );
      expect(
        report.missingFields,
        contains('support_unverified:support_alpha'),
      );
    });
  });

  group('117.3 state resolution', () {
    test('a contradiction outranks missing evidence', () {
      final report = _evaluate(
        _input(
          consents: <Sprint117CohortConsent>[
            _consent(
              explicitOptIn: false,
              source: 'synthetic_local',
              evidenceRef: null,
            ),
          ],
        ),
      );
      expect(report.state, Sprint117CohortState.fail);
    });

    test('missing evidence without a contradiction is blocked, not failed', () {
      final report = _evaluate(
        _input(
          consents: <Sprint117CohortConsent>[
            _consent(source: 'synthetic_local', evidenceRef: null),
          ],
        ),
      );
      expect(report.state, Sprint117CohortState.blocked);
      expect(report.verdict, Sprint117CohortContract.blockedVerdict);
    });

    test('the report records field coverage for every required field', () {
      final report = _evaluate(_input());
      for (final field in Sprint117CohortContract.requiredFields) {
        expect(report.fieldCoverage.containsKey(field), isTrue);
      }
    });

    test('the report keeps the live-beta execution claim honest', () {
      // Unverified consent alone does not decide whether a beta ran: the
      // claim keys off evidenced participants, so the participant must also be
      // unverified for the answer to be false.
      final report = _evaluate(
        _input(
          participants: <Sprint117CohortParticipant>[
            _participant(source: 'synthetic_local', evidenceRef: null),
          ],
          consents: <Sprint117CohortConsent>[
            _consent(source: 'synthetic_local', evidenceRef: null),
          ],
        ),
      );
      expect(report.liveBetaExecuted, isFalse);
      expect(report.verifiedParticipantCount, 0);
      expect(report.noFabricatedParticipants, isTrue);
    });

    test('external gates are never claimed as verified', () {
      expect(_evaluate(_input()).externalGates, 'DEFERRED-EXTERNAL');
    });
  });

  group('117.3 live repository evaluation', () {
    late Sprint117CohortReport report;

    setUpAll(() {
      report = Sprint117CohortGate().evaluate();
    });

    test('the gate runs against the committed repository manifests', () {
      expect(report.anchor, isNotNull);
      expect(report.anchor!.entryVerdict, Sprint117CohortContract.entryVerdict);
      expect(
        report.anchor!.charterVerdict,
        Sprint117CohortContract.charterVerdict,
      );
    });

    test('the anchor is derived from the 117.1 exposed subset', () {
      expect(report.anchor!.exposedSubset.length, 31);
      expect(report.anchor!.exposedSubset, contains('openai'));
      expect(report.anchor!.exposedSubset, contains('gemini'));
    });

    test('the committed plan still records zero enrolled participants', () {
      // 116.49 is a plan-stage fixture: no participant has been recruited, so
      // verification must be blocked, never quietly passed.
      expect(report.missingFields, contains('participant_or_project_id'));
      expect(report.verifiedParticipantCount, 0);
      expect(report.liveBetaExecuted, isFalse);
    });

    test('the live result is a real verdict with both lists reported', () {
      expect(
        report.state,
        anyOf(Sprint117CohortState.blocked, Sprint117CohortState.fail),
      );
      expect(report.verdict, isNotEmpty);
      expect(report.limitations, isNotEmpty);
    });

    test('the live result never fabricates a participant', () {
      expect(report.noFabricatedParticipants, isTrue);
      for (final participant in report.participants) {
        expect(participant.participantId.trim(), isNotEmpty);
      }
    });

    test('the live result keeps the release cut as an open item', () {
      expect(
        report.openItems,
        contains('release_cut_pending: pubspec 1.2.0-rc.1 != v1.3.0-beta.1'),
      );
    });

    test(
      'the live result cross-checks coverage against recorded destinations',
      () {
        // 116.49 records `api.openai.com` as a receiving destination but 116.46
        // never assessed the AI provider hosts, so the coverage rows carry no
        // `destination_host` at all. That gap must stay visible, not smoothed
        // over by borrowing a host from the plan.
        expect(
          report.violations.any(
            (violation) =>
                violation.startsWith('coverage_destination_unrecorded:'),
          ),
          isTrue,
        );
      },
    );

    test('the live result names the unverified plan-stage consent rows', () {
      expect(
        report.missingFields.any(
          (field) => field.startsWith('consent_unverified:'),
        ),
        isTrue,
      );
    });

    test('the live result flags consent that names no participant', () {
      expect(
        report.missingFields.any(
          (field) => field.startsWith('consent_participant_missing:'),
        ),
        isTrue,
      );
    });

    test('the live result surfaces the category that no boundary covers', () {
      // 116.49 consent covers `character_data`, but its data_boundaries only
      // describe novel_text, usage_telemetry and project_metadata. A consented
      // category with no boundary is a genuine ungoverned data path.
      expect(
        report.violations,
        contains('consent_category_unbounded:character_data'),
      );
    });

    test(
      'the live result surfaces the category that withdrawal cannot reach',
      () {
        expect(
          report.violations,
          contains('withdrawal_category_uncovered:character_data'),
        );
      },
    );

    test('the live result does not claim a live beta the plan forbids', () {
      // 116.49 records live_beta_execution=false and nobody is enrolled, so
      // the honest report stays BLOCKED and never contradicts its own source.
      expect(report.liveBetaExecuted, isFalse);
      expect(report.verifiedParticipantCount, 0);
      expect(
        report.violations,
        isNot(contains('live_execution_claimed_without_plan')),
      );
    });

    test(
      'the live result records the 116.49 limitation that nobody is enrolled',
      () {
        expect(
          report.limitations.any(
            (limitation) => limitation.toLowerCase().contains('enrolled'),
          ),
          isTrue,
        );
      },
    );

    test('the live result never claims external gates are verified', () {
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('the live result covers all six canonical fields', () {
      for (final field in Sprint117CohortContract.requiredFields) {
        expect(report.fieldCoverage.containsKey(field), isTrue);
      }
    });

    test(
      'the committed manifest is loadable and agrees with the live gate',
      () {
        final file = File(_cohortArtifact);
        expect(file.existsSync(), isTrue, reason: 'manifest must be committed');
        final decoded =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        expect(decoded['canonical_step'], '117.3');
        expect(decoded['state'], report.state.name);
        expect(decoded['verdict'], report.verdict);
        expect(
          List<String>.from(decoded['violations'] as List<dynamic>),
          report.violations,
        );
        expect(
          List<String>.from(decoded['missing_fields'] as List<dynamic>),
          report.missingFields,
        );
        expect(decoded['no_fabricated_participants'], isTrue);
        expect(decoded['live_beta_executed'], isFalse);
      },
    );

    test('the committed manifest carries no secret', () {
      final file = File(_cohortArtifact);
      final text = file.readAsStringSync().toLowerCase();
      for (final marker in <String>[
        'sk-',
        'api_key',
        'secret=',
        'bearer ',
        'client_secret',
        'password',
      ]) {
        expect(
          text.contains(marker),
          isFalse,
          reason: 'manifest must not carry a $marker marker',
        );
      }
    });

    test('the manifest records the 116.49 plan as its source of truth', () {
      final file = File(_cohortArtifact);
      final decoded =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(
        List<String>.from(decoded['source_manifests'] as List<dynamic>),
        contains(Sprint117CohortContract.planManifestPath),
      );
    });

    test('the manifest status stays UNVERIFIED because no beta ran', () {
      final file = File(_cohortArtifact);
      final decoded =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(decoded['status'], 'UNVERIFIED');
      expect(decoded['external_gates'], 'DEFERRED-EXTERNAL');
    });
  });
}
