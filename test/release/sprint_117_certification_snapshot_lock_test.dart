import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_certification_snapshot_lock.dart';

const String _artifact =
    'docs/planning/v1.3/sprint_117_certification_snapshot_lock.json';

/// The 117.1 entry gate records the instant the certification chain was
/// re-derived. The review window is measured against that recorded instant, not
/// against wall-clock time, so the verdict is reproducible.
const int _asOf = 1790726400000; // 2026-09-30T00:00:00Z

Sprint117SnapshotRecord _record({
  String providerId = 'openai',
  String connectorVersion = 'manifest-v1',
  String status = 'CERTIFIED',
  List<String> limitations = const <String>[
    'local_certification_chain_only',
    'no_live_provider_availability_claimed',
  ],
  String iconVersion = 'bundled-v1',
  String apiVersion = 'not-claimed',
  String reviewDate = '2027-03-27',
}) => Sprint117SnapshotRecord(
  providerId: providerId,
  connectorVersion: connectorVersion,
  status: status,
  limitations: limitations,
  iconVersion: iconVersion,
  apiVersion: apiVersion,
  reviewDate: reviewDate,
);

Sprint117SnapshotAnchor _anchor({
  String entryVerdict = Sprint117SnapshotContract.entryVerdict,
  String cohortVerdict = Sprint117SnapshotContract.cohortBlockedVerdict,
  int asOfEpochMs = _asOf,
  Map<String, String> entryVisibility = const <String, String>{
    'openai': 'certified',
    'kofi': 'limited',
    'saweria': 'blocked',
  },
  List<String> recordedApiVersions = const <String>['not-claimed'],
  List<String> recordedConnectorVersions = const <String>['manifest-v1'],
  Map<String, String> iconVersions = const <String, String>{
    'openai': 'bundled-v1',
    'kofi': 'generic-v1',
    'saweria': 'generic-v1',
  },
  String policyReviewDate = '2027-03-27',
  List<String> certificationStatuses = const <String>[
    'UNVERIFIED',
    'CERTIFIED',
    'LIMITED',
    'BLOCKED',
    'EXPIRED',
  ],
  List<String> carriedOpenItems = const <String>[
    'release_cut_pending: pubspec 1.2.0-rc.1 != v1.3.0-beta.1',
  ],
}) => Sprint117SnapshotAnchor(
  entryVerdict: entryVerdict,
  cohortVerdict: cohortVerdict,
  asOfEpochMs: asOfEpochMs,
  entryVisibility: entryVisibility,
  recordedApiVersions: recordedApiVersions,
  recordedConnectorVersions: recordedConnectorVersions,
  iconVersions: iconVersions,
  policyReviewDate: policyReviewDate,
  certificationStatuses: certificationStatuses,
  carriedOpenItems: carriedOpenItems,
);

List<Sprint117SnapshotRecord> _betaSubset() => <Sprint117SnapshotRecord>[
  _record(),
  _record(providerId: 'kofi', status: 'LIMITED', iconVersion: 'generic-v1'),
  _record(providerId: 'saweria', status: 'BLOCKED', iconVersion: 'generic-v1'),
];

Sprint117SnapshotInput _input({
  List<Sprint117SnapshotRecord>? records,
  Sprint117SnapshotAnchor? anchor,
}) => Sprint117SnapshotInput(
  records: records ?? _betaSubset(),
  anchor: anchor ?? _anchor(),
);

void main() {
  group('117.4 contract basics', () {
    test('the live loader locks the committed beta subset', () {
      final report = const Sprint117SnapshotGate().evaluate();

      expect(report.state, Sprint117SnapshotState.pass);
      expect(report.verdict, Sprint117SnapshotContract.passVerdict);
      expect(report.missingFields, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.lockedProviderCount, 32);
    });

    test(
      'the seven required fields are exactly the canonical 117.4 fields',
      () {
        expect(Sprint117SnapshotContract.requiredFields, <String>[
          'provider_id',
          'connector_version',
          'status',
          'limitations',
          'icon_version',
          'api_version',
          'review_date',
        ]);
      },
    );

    test(
      'the manifest, entry, policy, api, connector and cohort paths are pinned',
      () {
        expect(Sprint117SnapshotContract.manifestPath, _artifact);
        expect(
          Sprint117SnapshotContract.entryManifestPath,
          'docs/planning/v1.3/sprint_117_beta_entry_gate.json',
        );
        expect(
          Sprint117SnapshotContract.policyManifestPath,
          'docs/planning/v1.2/sprint_116_certification_policy.json',
        );
        expect(
          Sprint117SnapshotContract.apiManifestPath,
          'docs/planning/v1.2/sprint_116_current_api_sdk_verification.json',
        );
        expect(
          Sprint117SnapshotContract.connectorManifestPath,
          'docs/planning/v1.2/sprint_115_provider_connector_manifest.json',
        );
        expect(
          Sprint117SnapshotContract.cohortManifestPath,
          'docs/planning/v1.3/sprint_117_beta_cohort_consent_verification.json',
        );
        expect(Sprint117SnapshotContract.sourceManifests, hasLength(5));
      },
    );

    test('the lock reports exactly the providers it locked', () {
      final report = const Sprint117SnapshotGate().evaluateWith(_input());

      expect(report.lockedProviderCount, 3);
      expect(
        report.records.map((record) => record.providerId),
        containsAll(<String>['openai', 'kofi', 'saweria']),
      );
    });

    test('the exposed subset is certified plus limited and never blocked', () {
      final report = const Sprint117SnapshotGate().evaluateWith(_input());

      expect(report.exposedSubset, <String>['openai', 'kofi']);
      expect(report.blockedSubset, <String>['saweria']);
      expect(report.exposedSubset, isNot(contains('saweria')));
    });

    test('the lock never claims live provider availability', () {
      final report = const Sprint117SnapshotGate().evaluateWith(_input());

      expect(report.liveBetaExecuted, isFalse);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
      expect(
        report.limitations.join(' '),
        contains('not live provider availability'),
      );
    });

    test('every locked record is reported as a field coverage row', () {
      final report = const Sprint117SnapshotGate().evaluateWith(_input());

      expect(
        report.fieldCoverage.keys,
        Sprint117SnapshotContract.requiredFields,
      );
      for (final field in Sprint117SnapshotContract.requiredFields) {
        expect(
          report.fieldCoverage[field],
          3,
          reason: 'field $field should be reported for all three locked rows',
        );
      }
    });

    test(
      'the committed manifest records the same verdict as the live gate',
      () {
        final live = const Sprint117SnapshotGate().evaluate();
        final file = File(Sprint117SnapshotContract.manifestPath);
        expect(
          file.existsSync(),
          isTrue,
          reason: 'the generated lock manifest must be committed',
        );
        final decoded = jsonDecode(file.readAsStringSync());
        expect(decoded, isA<Map<String, dynamic>>());
        final manifest = decoded as Map<String, dynamic>;

        expect(manifest['state'], live.state.name);
        expect(manifest['verdict'], live.verdict);
        expect(
          List<String>.from(manifest['missing_fields'] as List<dynamic>),
          live.missingFields,
        );
        expect(
          List<String>.from(manifest['violations'] as List<dynamic>),
          live.violations,
        );
        expect(manifest['locked_provider_count'], live.lockedProviderCount);
      },
    );
  });

  group('117.4 anchor rules', () {
    test('a missing anchor is missing evidence, not a contradiction', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        Sprint117SnapshotInput(records: _betaSubset()),
      );

      expect(report.state, Sprint117SnapshotState.blocked);
      expect(report.missingFields, contains('entry_anchor'));
      expect(report.violations, isEmpty);
    });

    test('an entry verdict other than the 117.1 one blocks the lock', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        _input(anchor: _anchor(entryVerdict: 'BETA_ENTRY_BLOCKED')),
      );

      expect(report.state, Sprint117SnapshotState.blocked);
      expect(report.missingFields, contains('entry_anchor'));
    });

    test('a cohort verdict that is not verified is carried, not hidden', () {
      final report = const Sprint117SnapshotGate().evaluateWith(_input());

      expect(
        report.openItems,
        contains(
          'upstream_cohort_not_verified:'
          '${Sprint117SnapshotContract.cohortBlockedVerdict}',
        ),
      );
    });

    test(
      'a cohort verdict the lock cannot read stays missing, not assumed',
      () {
        final report = const Sprint117SnapshotGate().evaluateWith(
          _input(anchor: _anchor(cohortVerdict: '')),
        );

        expect(report.missingFields, contains('cohort_anchor'));
      },
    );

    test('the carried release-cut open item is not dropped silently', () {
      final report = const Sprint117SnapshotGate().evaluateWith(_input());

      expect(
        report.openItems,
        contains('release_cut_pending: pubspec 1.2.0-rc.1 != v1.3.0-beta.1'),
      );
    });

    test('a certification policy that records no review date is missing', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        _input(anchor: _anchor(policyReviewDate: '')),
      );

      expect(report.state, Sprint117SnapshotState.blocked);
      expect(report.missingFields, contains('policy_review_date'));
    });

    test('a policy without a certification vocabulary blocks the lock', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        _input(anchor: _anchor(certificationStatuses: const <String>[])),
      );

      expect(report.missingFields, contains('certification_status_vocabulary'));
    });

    test('a lock with no records at all is missing evidence', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        _input(records: const <Sprint117SnapshotRecord>[]),
      );

      expect(report.state, Sprint117SnapshotState.blocked);
      expect(report.missingFields, contains('snapshot_records'));
    });

    test('a null record list is missing evidence, not a pass', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        Sprint117SnapshotInput(anchor: _anchor()),
      );

      expect(report.missingFields, contains('snapshot_records'));
    });
  });

  group('117.4 identity rules', () {
    test('a blank provider id fails', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        _input(
          records: <Sprint117SnapshotRecord>[
            _record(providerId: '   '),
            _record(
              providerId: 'kofi',
              status: 'LIMITED',
              iconVersion: 'generic-v1',
            ),
          ],
        ),
      );

      expect(report.state, Sprint117SnapshotState.fail);
      expect(report.violations, contains('provider_id_blank'));
    });

    test('a duplicated provider id fails', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        _input(
          records: <Sprint117SnapshotRecord>[
            _record(),
            _record(),
            _record(
              providerId: 'kofi',
              status: 'LIMITED',
              iconVersion: 'generic-v1',
            ),
          ],
        ),
      );

      expect(report.violations, contains('snapshot_duplicate:openai'));
    });

    test('a provider the entry gate never recorded fails', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        _input(
          records: <Sprint117SnapshotRecord>[
            _record(),
            _record(providerId: 'phantom_provider'),
          ],
        ),
      );

      expect(report.violations, contains('provider_unlisted:phantom_provider'));
    });

    test('a provider the entry gate recorded but the lock omits fails', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        _input(records: <Sprint117SnapshotRecord>[_record()]),
      );

      expect(report.state, Sprint117SnapshotState.fail);
      expect(report.violations, contains('snapshot_provider_unaccounted:2:3'));
    });

    test('the whole beta subset is accounted for by the shipped lock', () {
      final report = const Sprint117SnapshotGate().evaluateWith(_input());

      expect(
        report.violations,
        isNot(contains('snapshot_provider_unaccounted:0:3')),
      );
      expect(report.lockedProviderCount, 3);
    });

    test('a status outside the certification vocabulary fails', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        _input(
          records: <Sprint117SnapshotRecord>[
            _record(status: 'SHIPPED'),
            _record(
              providerId: 'kofi',
              status: 'LIMITED',
              iconVersion: 'generic-v1',
            ),
          ],
        ),
      );

      expect(report.violations, contains('status_unknown:openai:SHIPPED'));
    });

    test('a status that drifts from the entry visibility fails', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        _input(
          records: <Sprint117SnapshotRecord>[
            _record(status: 'LIMITED'),
            _record(
              providerId: 'kofi',
              status: 'LIMITED',
              iconVersion: 'generic-v1',
            ),
          ],
        ),
      );

      expect(
        report.violations,
        contains('status_drift:openai:LIMITED:certified'),
      );
    });

    test('a blocked provider may not be locked as certified', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        _input(
          records: <Sprint117SnapshotRecord>[
            _record(),
            _record(
              providerId: 'kofi',
              status: 'LIMITED',
              iconVersion: 'generic-v1',
            ),
            _record(
              providerId: 'saweria',
              status: 'CERTIFIED',
              iconVersion: 'generic-v1',
            ),
          ],
        ),
      );

      expect(
        report.violations,
        contains('status_drift:saweria:CERTIFIED:blocked'),
      );
      expect(report.exposedSubset, isNot(contains('saweria')));
    });

    test(
      'the visibility vocabulary is matched case-insensitively only once',
      () {
        final report = const Sprint117SnapshotGate().evaluateWith(
          _input(
            records: <Sprint117SnapshotRecord>[
              _record(status: 'certified'),
              _record(
                providerId: 'kofi',
                status: 'LIMITED',
                iconVersion: 'generic-v1',
              ),
            ],
          ),
        );

        expect(report.violations, contains('status_unknown:openai:certified'));
      },
    );
  });

  group('117.4 connector version rules', () {
    test(
      'the shipped lock uses the connector contract version that is recorded',
      () {
        final report = const Sprint117SnapshotGate().evaluate();

        expect(report.records, isNotEmpty);
        for (final record in report.records) {
          expect(record.connectorVersion, 'manifest-v1');
        }
      },
    );

    test('a connector version no manifest records fails', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        _input(
          records: <Sprint117SnapshotRecord>[
            _record(connectorVersion: 'connector-v9'),
            _record(
              providerId: 'kofi',
              status: 'LIMITED',
              iconVersion: 'generic-v1',
            ),
            _record(
              providerId: 'saweria',
              status: 'BLOCKED',
              iconVersion: 'generic-v1',
            ),
          ],
        ),
      );

      expect(
        report.violations,
        contains('connector_version_unsourced:openai:connector-v9'),
      );
    });

    test('a blank connector version fails', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        _input(
          records: <Sprint117SnapshotRecord>[
            _record(connectorVersion: ' '),
            _record(
              providerId: 'kofi',
              status: 'LIMITED',
              iconVersion: 'generic-v1',
            ),
          ],
        ),
      );

      expect(report.violations, contains('connector_version_blank:openai'));
    });
  });

  group('117.4 limitation rules', () {
    test('a locked record with no limitation fails', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        _input(
          records: <Sprint117SnapshotRecord>[
            _record(limitations: const <String>[]),
            _record(
              providerId: 'kofi',
              status: 'LIMITED',
              iconVersion: 'generic-v1',
            ),
          ],
        ),
      );

      expect(report.violations, contains('limitations_blank:openai'));
    });

    test('a certified record with no limitation fails the policy rule', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        _input(
          records: <Sprint117SnapshotRecord>[
            _record(limitations: const <String>['  ']),
            _record(
              providerId: 'kofi',
              status: 'LIMITED',
              iconVersion: 'generic-v1',
            ),
          ],
        ),
      );

      expect(report.violations, contains('limitations_blank:openai'));
    });

    test('a limited record with no limitation fails too', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        _input(
          records: <Sprint117SnapshotRecord>[
            _record(),
            _record(
              providerId: 'kofi',
              status: 'LIMITED',
              iconVersion: 'generic-v1',
              limitations: const <String>[],
            ),
          ],
        ),
      );

      expect(report.violations, contains('limitations_blank:kofi'));
    });

    test('a blank limitation string does not count as a limitation', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        _input(
          records: <Sprint117SnapshotRecord>[
            _record(limitations: const <String>['  ']),
            _record(
              providerId: 'kofi',
              status: 'LIMITED',
              iconVersion: 'generic-v1',
            ),
          ],
        ),
      );

      expect(report.violations, contains('limitations_blank:openai'));
    });
  });

  group('117.4 icon version rules', () {
    test(
      'the shipped lock pins the icon version the registry actually ships',
      () {
        final report = const Sprint117SnapshotGate().evaluate();
        final anchor = report.anchor!;

        for (final record in report.records) {
          expect(record.iconVersion, anchor.iconVersions[record.providerId]);
        }
      },
    );

    test('an icon version that drifts from the shipped registry fails', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        _input(
          records: <Sprint117SnapshotRecord>[
            _record(iconVersion: 'bundled-v2'),
            _record(
              providerId: 'kofi',
              status: 'LIMITED',
              iconVersion: 'generic-v1',
            ),
          ],
        ),
      );

      expect(
        report.violations,
        contains('icon_version_drift:openai:bundled-v2:bundled-v1'),
      );
    });

    test('a provider the icon registry never registered fails', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        _input(
          records: <Sprint117SnapshotRecord>[
            _record(),
            _record(providerId: 'phantom_icon', iconVersion: 'generic-v1'),
          ],
        ),
      );

      expect(report.violations, contains('icon_provider_unknown:phantom_icon'));
    });

    test('a blank icon version fails', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        _input(
          records: <Sprint117SnapshotRecord>[
            _record(iconVersion: ''),
            _record(
              providerId: 'kofi',
              status: 'LIMITED',
              iconVersion: 'generic-v1',
            ),
          ],
        ),
      );

      expect(report.violations, contains('icon_version_blank:openai'));
    });
  });

  group('117.4 api version rules', () {
    test('the shipped lock reports the recorded not-claimed api version', () {
      final report = const Sprint117SnapshotGate().evaluate();

      expect(report.records, isNotEmpty);
      for (final record in report.records) {
        expect(record.apiVersion, 'not-claimed');
      }
    });

    test('a concrete api version that no verified source records fails', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        _input(
          records: <Sprint117SnapshotRecord>[
            _record(apiVersion: '2024-02-01'),
            _record(
              providerId: 'kofi',
              status: 'LIMITED',
              iconVersion: 'generic-v1',
            ),
          ],
        ),
      );

      expect(
        report.violations,
        contains('api_version_unsourced:openai:2024-02-01'),
      );
    });

    test('an api version the source did record is accepted', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        _input(
          anchor: _anchor(
            recordedApiVersions: const <String>['not-claimed', 'v1-2026-03'],
          ),
          records: <Sprint117SnapshotRecord>[
            _record(apiVersion: 'v1-2026-03'),
            _record(
              providerId: 'kofi',
              status: 'LIMITED',
              iconVersion: 'generic-v1',
            ),
            _record(
              providerId: 'saweria',
              status: 'BLOCKED',
              iconVersion: 'generic-v1',
            ),
          ],
        ),
      );

      expect(report.state, Sprint117SnapshotState.pass);
      expect(report.violations, isEmpty);
      expect(
        report.records.first.apiVersion,
        'v1-2026-03',
        reason: 'a sourced API version is locked verbatim, not replaced',
      );
    });

    test('a blank api version fails', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        _input(
          records: <Sprint117SnapshotRecord>[
            _record(apiVersion: '  '),
            _record(
              providerId: 'kofi',
              status: 'LIMITED',
              iconVersion: 'generic-v1',
            ),
          ],
        ),
      );

      expect(report.violations, contains('api_version_blank:openai'));
    });
  });

  group('117.4 review date rules', () {
    test(
      'the shipped lock uses the review date the certification policy records',
      () {
        final report = const Sprint117SnapshotGate().evaluate();

        expect(report.records, isNotEmpty);
        for (final record in report.records) {
          expect(record.reviewDate, '2027-03-27');
        }
      },
    );

    test('a blank review date fails', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        _input(
          records: <Sprint117SnapshotRecord>[
            _record(reviewDate: ''),
            _record(
              providerId: 'kofi',
              status: 'LIMITED',
              iconVersion: 'generic-v1',
            ),
          ],
        ),
      );

      expect(report.violations, contains('review_date_blank:openai'));
    });

    test('a malformed review date fails', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        _input(
          records: <Sprint117SnapshotRecord>[
            _record(reviewDate: '27-03-2027'),
            _record(
              providerId: 'kofi',
              status: 'LIMITED',
              iconVersion: 'generic-v1',
            ),
          ],
        ),
      );

      expect(
        report.violations,
        contains('review_date_unparsed:openai:27-03-2027'),
      );
    });

    test('an impossible calendar date fails', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        _input(
          records: <Sprint117SnapshotRecord>[
            _record(reviewDate: '2027-02-30'),
            _record(
              providerId: 'kofi',
              status: 'LIMITED',
              iconVersion: 'generic-v1',
            ),
          ],
        ),
      );

      expect(
        report.violations,
        contains('review_date_unparsed:openai:2027-02-30'),
      );
    });

    test('a review window still open is not expired', () {
      final report = const Sprint117SnapshotGate().evaluateWith(_input());

      expect(report.expiredProviderIds, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('a review date already elapsed without EXPIRED status fails', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        _input(
          anchor: _anchor(
            asOfEpochMs: DateTime.utc(2028, 1, 1).millisecondsSinceEpoch,
          ),
          records: <Sprint117SnapshotRecord>[
            _record(reviewDate: '2027-03-27'),
            _record(
              providerId: 'kofi',
              status: 'LIMITED',
              iconVersion: 'generic-v1',
            ),
            _record(
              providerId: 'saweria',
              status: 'BLOCKED',
              iconVersion: 'generic-v1',
            ),
          ],
        ),
      );

      expect(
        report.violations,
        contains('expired_status_required:openai:2027-03-27'),
      );
    });

    test('an elapsed window is accepted when the status says EXPIRED', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        _input(
          anchor: _anchor(
            asOfEpochMs: DateTime.utc(2028, 1, 1).millisecondsSinceEpoch,
            entryVisibility: const <String, String>{
              'openai': 'expired',
              'kofi': 'expired',
              'saweria': 'expired',
            },
          ),
          records: <Sprint117SnapshotRecord>[
            _record(reviewDate: '2027-03-27', status: 'EXPIRED'),
            _record(
              providerId: 'kofi',
              status: 'EXPIRED',
              iconVersion: 'generic-v1',
              reviewDate: '2027-03-27',
            ),
            _record(
              providerId: 'saweria',
              status: 'EXPIRED',
              iconVersion: 'generic-v1',
              reviewDate: '2027-03-27',
            ),
          ],
        ),
      );

      expect(report.state, Sprint117SnapshotState.pass);
      expect(
        report.expiredProviderIds,
        containsAll(<String>['openai', 'kofi', 'saweria']),
      );
    });

    test('an EXPIRED status whose window has not elapsed fails', () {
      final report = const Sprint117SnapshotGate().evaluateWith(
        _input(
          anchor: _anchor(
            entryVisibility: const <String, String>{
              'openai': 'expired',
              'kofi': 'limited',
              'saweria': 'blocked',
            },
          ),
          records: <Sprint117SnapshotRecord>[
            _record(status: 'EXPIRED'),
            _record(
              providerId: 'kofi',
              status: 'LIMITED',
              iconVersion: 'generic-v1',
            ),
            _record(
              providerId: 'saweria',
              status: 'BLOCKED',
              iconVersion: 'generic-v1',
            ),
          ],
        ),
      );

      expect(
        report.violations,
        contains('expired_status_without_elapsed_window:openai:2027-03-27'),
      );
    });

    test('the review window is measured at the recorded as-of instant', () {
      final late = const Sprint117SnapshotGate().evaluateWith(
        _input(
          anchor: _anchor(
            asOfEpochMs: DateTime.utc(2027, 4, 1).millisecondsSinceEpoch,
          ),
        ),
      );
      final early = const Sprint117SnapshotGate().evaluateWith(_input());

      expect(late.expiredProviderIds, isNotEmpty);
      expect(early.expiredProviderIds, isEmpty);
      expect(early.anchor!.asOfEpochMs, _asOf);
    });

    test('a review date exactly at the as-of instant is already elapsed', () {
      final asOf = DateTime.utc(2027, 3, 27).millisecondsSinceEpoch;
      final report = const Sprint117SnapshotGate().evaluateWith(
        _input(
          anchor: _anchor(
            asOfEpochMs: asOf,
            entryVisibility: const <String, String>{
              'openai': 'expired',
              'kofi': 'limited',
              'saweria': 'blocked',
            },
          ),
        ),
      );

      expect(
        report.violations,
        contains('expired_status_required:openai:2027-03-27'),
      );
    });
  });

  group('117.4 report shape', () {
    test('the report serialises the seven required fields', () {
      final json = const Sprint117SnapshotGate()
          .evaluateWith(_input())
          .toJson();

      expect(json['required_fields'], Sprint117SnapshotContract.requiredFields);
      expect(json['canonical_step'], '117.4');
      expect(json['external_gates'], 'DEFERRED-EXTERNAL');
      expect(json['live_beta_executed'], isFalse);
      final records = json['snapshot'] as List<dynamic>;
      expect(records, hasLength(3));
      final first = records.first as Map<String, dynamic>;
      expect(
        first.keys.toSet(),
        Sprint117SnapshotContract.requiredFields.toSet(),
      );
    });

    test('the report records the anchor it locked against', () {
      final json = const Sprint117SnapshotGate()
          .evaluateWith(_input())
          .toJson();
      final anchor = json['anchor'] as Map<String, dynamic>;

      expect(anchor['entry_verdict'], Sprint117SnapshotContract.entryVerdict);
      expect(anchor['as_of_epoch_ms'], _asOf);
      expect(anchor['policy_review_date'], '2027-03-27');
      expect(anchor['entry_visibility'], isA<Map<String, dynamic>>());
    });

    test('external gates stay deferred even on a passing lock', () {
      final report = const Sprint117SnapshotGate().evaluateWith(_input());

      expect(report.state, Sprint117SnapshotState.pass);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
      expect(
        report.limitations.any((entry) => entry.contains('DEFERRED-EXTERNAL')),
        isTrue,
      );
    });

    test('the shipped lock names the release cut it does not resolve', () {
      final report = const Sprint117SnapshotGate().evaluate();

      expect(
        report.openItems,
        contains('release_cut_pending: pubspec 1.2.0-rc.1 != v1.3.0-beta.1'),
      );
    });

    test('the shipped lock freezes all thirty-two registry providers', () {
      final report = const Sprint117SnapshotGate().evaluate();

      expect(report.records, hasLength(32));
      expect(
        report.records.map((record) => record.providerId).toSet(),
        hasLength(32),
      );
      expect(report.exposedSubset, hasLength(31));
      expect(report.blockedSubset, <String>['saweria']);
    });

    test(
      'the shipped lock keeps a blocked provider out of the exposed subset',
      () {
        final report = const Sprint117SnapshotGate().evaluate();

        expect(report.exposedSubset, isNot(contains('saweria')));
        expect(
          report.records
              .firstWhere((record) => record.providerId == 'saweria')
              .status,
          'BLOCKED',
        );
      },
    );

    test(
      'the shipped lock marks a limited provider as limited, not certified',
      () {
        final report = const Sprint117SnapshotGate().evaluate();

        expect(
          report.records
              .firstWhere((record) => record.providerId == 'kofi')
              .status,
          'LIMITED',
        );
        expect(report.exposedSubset, contains('kofi'));
      },
    );
  });
}
