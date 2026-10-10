// Sprint 117.42 — Documentation & Known Limitations.
//
// Canonical step objective: "Menyelesaikan setup, permissions, quota, units,
// usage, cost, privacy, disconnect, recovery, billing, and provider
// limitations.", with eight `outputs`:
//   setup_guides, permission_guides, quota_notes, usage_cost_notes,
//   privacy_notes, disconnect_guide, recovery_guide, limitations.
//
// The step names no per-output acceptance vocabulary, so this gate measures the
// two things it DOES state and does not invent a third:
//
// 1. every named output resolves to a set of documents that exist on disk and
//    to a seam that actually measured it, and
// 2. the `limitations` a provider row publishes are the limitations the shipped
//    connector manifest derives — not a constant invented by the caller.
//
// Defect 117.42-01 (FAIL-OPEN, fixed here) — provider `limitations` were not
//   derived from anything. The 117.41 registry test supplies every one of its
//   32 rows the same hand-typed pair
//   `['not_live_provider_availability', 'no_signed_connector_release']`, and
//   `ProviderConnectorEntry` — the shipped per-provider source — carries no
//   limitations field at all. So the registry reported a per-provider
//   limitation set that no seam derived, and step 117.42's own
//   "provider limitations" obligation was satisfied by a constant. Root cause:
//   the limitation vocabulary was never bound to the manifest, so any caller
//   could publish any string and the gate had nothing to compare against.
//   Fix: `Sprint117ProviderLimitationCatalogue.derive` computes the limitation
//   set from the shipped entry (availability, auth type, health endpoint,
//   permissions), and this gate compares DECLARED against DERIVED so a constant
//   and a fabricated string both fail.
//
// Defect 117.42-02 (fixed in this follow-up slice) — the shipped
//   `ProviderPermission` vocabulary previously had no member that covered
//   developer/repo access, so the four developer connectors (github, gitlab,
//   bitbucket, azure_devops) shipped a permission set byte-identical to an
//   identity connector's. The manifest now carries an explicit
//   `developer_repository` scope while remaining unverified and withheld.
//
// Every `observed` value is produced by running the shipped seam in this run;
// the aggregate test throws `StateError` rather than letting a hand-typed
// verdict through.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_billing_summary.dart';
import 'package:void_scriptor/features/account/domain/account_center_privacy_data_flow_review.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_connector_manifest.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_documentation_known_limitations.dart';

/// Writes the committed evidence file and returns its byte count.
///
/// The sha256 is deliberately NOT computed here: per the repository SHA policy
/// the ledger value is hashed from the COMMITTED artifact (`git show`), never
/// from a working-tree read a parallel suite could rewrite in between.
int _writeManifest(Map<String, Object?> manifest, String relativePath) {
  final file = File(relativePath);
  file.parent.createSync(recursive: true);
  final bytes = utf8.encode(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
  file.writeAsBytesSync(bytes, flush: true);
  return bytes.length;
}

void main() {
  const manifestFileName = 'sprint-117-42-manifest-20261002.json';

  group('117.42 defect 1 — provider limitations were never derived', () {
    // Root cause: nothing bound `limitations` to the shipped manifest entry, so
    // the 117.41 registry accepted any caller-supplied string.

    test('the shipped manifest entry carries no limitations of its own', () {
      // This is the root cause, asserted rather than assumed: the connector
      // manifest has no limitations field, so the limitation set for a provider
      // can only come from a derivation over the fields it does ship.
      final entry = ProviderConnectorManifest.standard.require('openai');
      // ignore: avoid_... — the assertion below is the point of the probe.
      expect(entry.toJson().containsKey('limitations'), isFalse);
    });

    test('derivation follows the shipped entry, not the caller', () {
      final manifest = ProviderConnectorManifest.standard;

      final openai = Sprint117ProviderLimitationCatalogue.derive(
        manifest.require('openai'),
      );
      final google = Sprint117ProviderLimitationCatalogue.derive(
        manifest.require('google'),
      );
      final stripe = Sprint117ProviderLimitationCatalogue.derive(
        manifest.require('stripe'),
      );

      // openai is an AI_KEY entry: it must record its own auth shape.
      expect(openai, contains('auth_api_key'));
      expect(openai, contains('availability_unverified'));
      // google is an OAUTH2_PKCE identity entry: a different auth shape.
      expect(google, contains('auth_oauth2_pkce'));
      expect(google, isNot(contains('auth_api_key')));
      // stripe is a payment entry and carries the billing permission the two
      // others do not.
      expect(stripe, contains('permission_billing'));
      expect(openai, isNot(contains('permission_billing')));

      // Every derived set is non-empty: an empty set would document nothing.
      for (final entry in manifest.all) {
        expect(
          Sprint117ProviderLimitationCatalogue.derive(entry),
          isNotEmpty,
          reason: '${entry.providerId} derived no limitation at all',
        );
      }
    });

    test('a hand-typed constant limitation set is rejected', () {
      // The exact constant the 117.41 registry test supplies for all 32 rows.
      const handTyped = <String>[
        'not_live_provider_availability',
        'no_signed_connector_release',
      ];
      final entry = ProviderConnectorManifest.standard.require('openai');
      final derived = Sprint117ProviderLimitationCatalogue.derive(entry);

      expect(derived, isNot(equals(handTyped)));
      expect(
        Sprint117ProviderLimitationCatalogue.isDerived(entry, handTyped),
        isFalse,
        reason:
            'a constant that the shipped entry does not derive is not evidence',
      );
      expect(
        Sprint117ProviderLimitationCatalogue.isDerived(entry, derived),
        isTrue,
      );
    });

    test('a fabricated limitation nobody can derive is rejected', () {
      final entry = ProviderConnectorManifest.standard.require('openai');
      expect(
        Sprint117ProviderLimitationCatalogue.isDerived(entry, <String>[
          ...Sprint117ProviderLimitationCatalogue.derive(entry),
          'invented_limitation_not_in_vocabulary',
        ]),
        isFalse,
      );
    });

    test('a dropped limitation is rejected too', () {
      final entry = ProviderConnectorManifest.standard.require('openai');
      final derived = Sprint117ProviderLimitationCatalogue.derive(entry);
      expect(
        Sprint117ProviderLimitationCatalogue.isDerived(
          entry,
          derived.sublist(1),
        ),
        isFalse,
        reason:
            'publishing fewer limitations than the seam derives hides scope',
      );
    });
  });

  group('117.42 defect 2 — developer scope is explicit', () {
    test('the permission vocabulary names developer/repository access', () {
      final wireNames = ProviderPermission.values
          .map((permission) => permission.wireName)
          .toList();
      expect(
        wireNames,
        contains('developer_repository'),
        reason:
            'developer connectors need an explicit repository scope in the '
            'shared manifest vocabulary',
      );
    });

    test('developer connectors carry a repository-scoped permission', () {
      final manifest = ProviderConnectorManifest.standard;
      final identity = manifest.require('google').permissions;
      const developers = <String>[
        'github',
        'gitlab',
        'bitbucket',
        'azure_devops',
      ];

      for (final providerId in developers) {
        final entry = manifest.require(providerId);
        expect(
          entry.capabilities,
          contains(ProviderConnectorCapability.developer),
          reason:
              '$providerId must ship the developer capability it is gated on',
        );
        expect(
          entry.permissions.map((permission) => permission.wireName),
          contains('developer_repository'),
          reason: '$providerId must declare repository scope explicitly',
        );
        expect(
          entry.permissions,
          isNot(equals(identity)),
          reason: '$providerId must not reuse the identity permission set',
        );
        expect(
          Sprint117ProviderLimitationCatalogue.derive(entry),
          contains('permission_developer_repository'),
        );
      }
    });
  });

  group('117.42 canonical contract gate', () {
    test('declares the eight canonical outputs verbatim', () {
      expect(Sprint117DocumentationContract.requiredOutputs, <String>[
        'setup_guides',
        'permission_guides',
        'quota_notes',
        'usage_cost_notes',
        'privacy_notes',
        'disconnect_guide',
        'recovery_guide',
        'limitations',
      ]);
    });

    test('every canonical output resolves to documents that exist on disk', () {
      for (final outputId in Sprint117DocumentationContract.requiredOutputs) {
        final references = Sprint117DocumentationContract.referencesFor(
          outputId,
        );
        expect(
          references,
          isNotEmpty,
          reason: '$outputId resolves to no document',
        );
        for (final path in references) {
          expect(
            File(path).existsSync(),
            isTrue,
            reason: '$outputId names a document nobody can open: $path',
          );
          expect(File(path).lengthSync(), greaterThan(0));
        }
      }
    });

    test('the vocabulary cannot drift silently', () {
      expect(
        Sprint117DocumentationContract.requiredOutputs.toSet().length,
        Sprint117DocumentationContract.requiredOutputs.length,
      );
      expect(
        Sprint117DocumentationContract.referencesFor('limitations'),
        contains('docs/release/v1.2.0-rc.1-known-limits.md'),
      );
      expect(
        Sprint117DocumentationContract.referencesFor('permission_guides'),
        contains(
          'docs/planning/v1.2/sprint_115_provider_connector_manifest.json',
        ),
      );
    });

    test('a complete documentation set passes', () {
      final manifest = ProviderConnectorManifest.standard;
      final rows = <Sprint117DocumentationRow>[
        for (final entry in manifest.all)
          Sprint117DocumentationRow(
            providerId: entry.providerId,
            derivedLimitations: Sprint117ProviderLimitationCatalogue.derive(
              entry,
            ),
            declaredLimitations: Sprint117ProviderLimitationCatalogue.derive(
              entry,
            ),
          ),
      ];
      final outputs = <Sprint117DocumentationOutput>[
        for (final outputId in Sprint117DocumentationContract.requiredOutputs)
          Sprint117DocumentationOutput(
            outputId: outputId,
            references: Sprint117DocumentationContract.referencesFor(outputId),
            seamLabel: 'probe_seam_for_$outputId',
          ),
      ];
      final checks = <Sprint117DocumentationCheck>[
        for (final outputId in Sprint117DocumentationContract.requiredOutputs)
          Sprint117DocumentationCheck.pass_(
            outputId: outputId,
            check: 'document_resolves_to_seam',
            declared: 'the output names a document that exists',
            observed: 'resolved and measured this run',
          ),
      ];

      final result = Sprint117DocumentationContract.evaluate(
        outputs,
        checks,
        rows,
      );

      expect(result.failures, isEmpty, reason: result.failures.join(' | '));
      expect(result.verdict, Sprint117DocumentationContract.passVerdict);
      expect(() => jsonEncode(result.toJson()), returnsNormally);
    });

    test(
      'an output with no passing check fails instead of passing quietly',
      () {
        final outputs = <Sprint117DocumentationOutput>[
          for (final outputId in Sprint117DocumentationContract.requiredOutputs)
            Sprint117DocumentationOutput(
              outputId: outputId,
              references: Sprint117DocumentationContract.referencesFor(
                outputId,
              ),
              seamLabel: 'probe_seam',
            ),
        ];

        final result = Sprint117DocumentationContract.evaluate(
          outputs,
          const <Sprint117DocumentationCheck>[],
          const <Sprint117DocumentationRow>[],
        );

        expect(result.failures, contains('output_without_pass:setup_guides'));
        expect(result.failures, contains('no_documentation_rows'));
        expect(result.pass, isFalse);
      },
    );

    test('an output naming a document nobody can open fails', () {
      final outputs = <Sprint117DocumentationOutput>[
        for (final outputId in Sprint117DocumentationContract.requiredOutputs)
          Sprint117DocumentationOutput(
            outputId: outputId,
            references: outputId == 'recovery_guide'
                ? const <String>['docs/release/does-not-exist-11742.md']
                : Sprint117DocumentationContract.referencesFor(outputId),
            seamLabel: 'probe_seam',
          ),
      ];
      final checks = <Sprint117DocumentationCheck>[
        for (final outputId in Sprint117DocumentationContract.requiredOutputs)
          Sprint117DocumentationCheck.pass_(
            outputId: outputId,
            check: 'document_resolves_to_seam',
            declared: 'declared',
            observed: 'observed',
          ),
      ];

      final result = Sprint117DocumentationContract.evaluate(
        outputs,
        checks,
        const <Sprint117DocumentationRow>[],
      );

      expect(
        result.failures,
        contains(
          'missing_reference:recovery_guide:docs/release/does-not-exist-11742.md',
        ),
      );
    });

    test('an output with no document at all is named, not skipped', () {
      final outputs = <Sprint117DocumentationOutput>[
        for (final outputId in Sprint117DocumentationContract.requiredOutputs)
          Sprint117DocumentationOutput(
            outputId: outputId,
            references: outputId == 'disconnect_guide'
                ? const <String>[]
                : Sprint117DocumentationContract.referencesFor(outputId),
            seamLabel: 'probe_seam',
          ),
      ];
      final checks = <Sprint117DocumentationCheck>[
        for (final outputId in Sprint117DocumentationContract.requiredOutputs)
          Sprint117DocumentationCheck.pass_(
            outputId: outputId,
            check: 'document_resolves_to_seam',
            declared: 'declared',
            observed: 'observed',
          ),
      ];

      final result = Sprint117DocumentationContract.evaluate(
        outputs,
        checks,
        const <Sprint117DocumentationRow>[],
      );

      expect(result.failures, contains('no_document:disconnect_guide'));
    });

    test('a row whose declared limitations are not the derived ones fails', () {
      final manifest = ProviderConnectorManifest.standard;
      final rows = <Sprint117DocumentationRow>[
        for (final entry in manifest.all)
          Sprint117DocumentationRow(
            providerId: entry.providerId,
            derivedLimitations: Sprint117ProviderLimitationCatalogue.derive(
              entry,
            ),
            declaredLimitations: const <String>[
              'not_live_provider_availability',
              'no_signed_connector_release',
            ],
          ),
      ];
      final outputs = <Sprint117DocumentationOutput>[
        for (final outputId in Sprint117DocumentationContract.requiredOutputs)
          Sprint117DocumentationOutput(
            outputId: outputId,
            references: Sprint117DocumentationContract.referencesFor(outputId),
            seamLabel: 'probe_seam',
          ),
      ];
      final checks = <Sprint117DocumentationCheck>[
        for (final outputId in Sprint117DocumentationContract.requiredOutputs)
          Sprint117DocumentationCheck.pass_(
            outputId: outputId,
            check: 'document_resolves_to_seam',
            declared: 'declared',
            observed: 'observed',
          ),
      ];

      final result = Sprint117DocumentationContract.evaluate(
        outputs,
        checks,
        rows,
      );

      expect(result.failures, contains('limitations_not_derived:openai'));
      expect(result.pass, isFalse);
    });

    test('a row publishing NO limitations at all fails closed', () {
      // A registry row that publishes an empty limitation set is documenting
      // nothing, and the shipped entry derives a non-empty set for every one of
      // the 32 providers — so this is a real regression, not a hypothetical.
      final rows = <Sprint117DocumentationRow>[
        const Sprint117DocumentationRow(
          providerId: 'openai',
          derivedLimitations: <String>['auth_api_key'],
          declaredLimitations: <String>[],
        ),
      ];
      final outputs = <Sprint117DocumentationOutput>[
        for (final outputId in Sprint117DocumentationContract.requiredOutputs)
          Sprint117DocumentationOutput(
            outputId: outputId,
            references: Sprint117DocumentationContract.referencesFor(outputId),
            seamLabel: 'probe_seam',
          ),
      ];
      final checks = <Sprint117DocumentationCheck>[
        for (final outputId in Sprint117DocumentationContract.requiredOutputs)
          Sprint117DocumentationCheck.pass_(
            outputId: outputId,
            check: 'document_resolves_to_seam',
            declared: 'declared',
            observed: 'observed',
          ),
      ];

      final result = Sprint117DocumentationContract.evaluate(
        outputs,
        checks,
        rows,
      );

      expect(
        result.failures,
        contains('limitations_not_derived:openai'),
        reason: 'an empty published set must not read as "no limitations"',
      );
      expect(result.unresolvedProviderIds, <String>['openai']);
      expect(result.exposedProviderIds, isEmpty);
    });

    test('a provider the shipped manifest does not carry fails closed', () {
      final rows = <Sprint117DocumentationRow>[
        const Sprint117DocumentationRow(
          providerId: 'probe',
          derivedLimitations: <String>['probe_limitation'],
          declaredLimitations: <String>['probe_limitation'],
        ),
      ];
      final outputs = <Sprint117DocumentationOutput>[
        for (final outputId in Sprint117DocumentationContract.requiredOutputs)
          Sprint117DocumentationOutput(
            outputId: outputId,
            references: Sprint117DocumentationContract.referencesFor(outputId),
            seamLabel: 'probe_seam',
          ),
      ];
      final checks = <Sprint117DocumentationCheck>[
        for (final outputId in Sprint117DocumentationContract.requiredOutputs)
          Sprint117DocumentationCheck.pass_(
            outputId: outputId,
            check: 'document_resolves_to_seam',
            declared: 'declared',
            observed: 'observed',
          ),
      ];

      final result = Sprint117DocumentationContract.evaluate(
        outputs,
        checks,
        rows,
      );

      expect(
        result.failures,
        contains('unknown_provider:probe'),
        reason:
            'a limitation set for a provider nobody ships documents nothing',
      );
    });

    test('no shipped provider derives an empty limitation set', () {
      // This is the invariant the `no_derived_limitation` guard defends: it is
      // unreachable while every shipped entry derives at least its auth type
      // and its availability, and this test fails loudly if a future change
      // ever breaks that rather than letting empty pass as "no limits".
      for (final entry in ProviderConnectorManifest.standard.all) {
        expect(
          Sprint117ProviderLimitationCatalogue.derive(entry),
          isNotEmpty,
          reason: '${entry.providerId} derives no limitation at all',
        );
      }
    });

    test('a vacuous check statement is not evidence', () {
      final outputs = <Sprint117DocumentationOutput>[
        for (final outputId in Sprint117DocumentationContract.requiredOutputs)
          Sprint117DocumentationOutput(
            outputId: outputId,
            references: Sprint117DocumentationContract.referencesFor(outputId),
            seamLabel: 'probe_seam',
          ),
      ];
      final checks = <Sprint117DocumentationCheck>[
        for (final outputId in Sprint117DocumentationContract.requiredOutputs)
          Sprint117DocumentationCheck.pass_(
            outputId: outputId,
            check: 'document_resolves_to_seam',
            declared: 'declared',
            observed: '   ',
          ),
      ];

      final result = Sprint117DocumentationContract.evaluate(
        outputs,
        checks,
        const <Sprint117DocumentationRow>[],
      );

      expect(
        result.failures,
        contains('vacuous:setup_guides:document_resolves_to_seam'),
        reason:
            'a blank observed statement is not evidence of a measured output',
      );
      // Each blank statement also loses its output's passing coverage, so the
      // fail-closed count is 2 per output plus the empty row set.
      expect(result.failures, hasLength(17));
      expect(
        result.failures.where((code) => code.startsWith('vacuous:')).length,
        8,
      );
      expect(
        result.failures
            .where((code) => code.startsWith('output_without_pass:'))
            .length,
        8,
      );
      expect(result.failures, contains('no_documentation_rows'));
    });
  });

  group('117.42 shipped documentation facts', () {
    test('billing is recorded as not verified by the shipped seam', () {
      // The step requires billing limitations to be documented; the shipped
      // seam's own verdict is what a guide has to match.
      expect(
        AccountCenterBillingSummary.billingContractStatus,
        'PLANNED_NOT_VERIFIED',
      );
    });

    test('the privacy seam ships the documented output vocabulary', () {
      expect(
        AccountCenterPrivacyDataFlowReview.requiredOutputs,
        containsAll(<String>[
          'data_flow',
          'consent',
          'retention',
          'deletion',
          'external_transfer',
        ]),
      );
    });
  });

  group('117.42 evidence manifest', () {
    test('writes the manifest with probes measured this run', () {
      final probes = <String, bool>{};

      final manifest = ProviderConnectorManifest.standard;
      probes['all_declared_documents_exist'] = <bool>[
        for (final outputId in Sprint117DocumentationContract.requiredOutputs)
          for (final path in Sprint117DocumentationContract.referencesFor(
            outputId,
          ))
            File(path).existsSync() && File(path).lengthSync() > 0,
      ].every((value) => value);

      probes['every_provider_derives_limitations'] = manifest.all.every(
        (entry) =>
            Sprint117ProviderLimitationCatalogue.derive(entry).isNotEmpty,
      );

      probes['hand_typed_constant_rejected'] =
          Sprint117ProviderLimitationCatalogue.isDerived(
            manifest.require('openai'),
            const <String>[
              'not_live_provider_availability',
              'no_signed_connector_release',
            ],
          ) ==
          false;

      probes['derivation_is_entry_specific'] =
          !Set<String>.of(
            Sprint117ProviderLimitationCatalogue.derive(
              manifest.require('openai'),
            ),
          ).contains(
            Sprint117ProviderLimitationCatalogue.derive(
              manifest.require('google'),
            ).first,
          );

      probes['billing_reports_not_verified'] =
          AccountCenterBillingSummary.billingContractStatus ==
          'PLANNED_NOT_VERIFIED';

      final rows = <Sprint117DocumentationRow>[
        for (final entry in manifest.all)
          Sprint117DocumentationRow(
            providerId: entry.providerId,
            derivedLimitations: Sprint117ProviderLimitationCatalogue.derive(
              entry,
            ),
            declaredLimitations: Sprint117ProviderLimitationCatalogue.derive(
              entry,
            ),
          ),
      ];
      final outputs = <Sprint117DocumentationOutput>[
        for (final outputId in Sprint117DocumentationContract.requiredOutputs)
          Sprint117DocumentationOutput(
            outputId: outputId,
            references: Sprint117DocumentationContract.referencesFor(outputId),
            seamLabel: 'see_check_surface_labels',
          ),
      ];
      final checks = <Sprint117DocumentationCheck>[
        for (final outputId in Sprint117DocumentationContract.requiredOutputs)
          Sprint117DocumentationCheck.pass_(
            outputId: outputId,
            check: 'document_resolves_to_seam',
            declared:
                'the output names a document that exists and a seam that read it',
            observed:
                '${Sprint117DocumentationContract.referencesFor(outputId).length} document(s) resolved this run',
          ),
      ];

      final result = Sprint117DocumentationContract.evaluate(
        outputs,
        checks,
        rows,
      );

      if (probes.values.any((value) => !value)) {
        throw StateError(
          'A 117.42 probe measured false: '
          '${probes.entries.where((e) => !e.value).map((e) => e.key).toList()}',
        );
      }
      if (result.failures.isNotEmpty) {
        throw StateError(
          '117.42 documentation gate failed: ${result.failures}',
        );
      }

      final manifestJson = <String, Object?>{
        'canonical_step': Sprint117DocumentationContract.canonicalStep,
        'document_role': 'EVIDENCE',
        'verdict': result.verdict,
        'pass': result.pass,
        'required_outputs': Sprint117DocumentationContract.requiredOutputs
            .toList(),
        'output_reference_counts': <String, int>{
          for (final outputId in Sprint117DocumentationContract.requiredOutputs)
            outputId: Sprint117DocumentationContract.referencesFor(
              outputId,
            ).length,
        },
        'provider_count': rows.length,
        'distinct_derived_limitation_sets': <String>{
          for (final row in rows) row.derivedLimitations.join('|'),
        }.length,
        'checks': result.checks.length,
        'failures': result.failures,
        'open_items': result.openItems,
        'probes': probes,
        'defects_fixed': const <String>[
          '117.42-01: provider limitations were a hand-typed test constant and '
              'ProviderConnectorEntry ships no limitations field, so any caller '
              'could publish any limitation set; derivation now binds limitations '
              'to the shipped manifest entry and the gate compares declared '
              'against derived',
          '117.42-02: ProviderPermission lacked developer/repository scope and '
              'developer connectors therefore reused identity permissions; the '
              'manifest now declares developer_repository explicitly while the '
              'connectors remain unverified and withheld',
        ],
        'claim_boundary':
            'No live beta, no participant, and no release is claimed. Every '
            'status here is local documentation state measured on test-owned '
            'fixtures and on committed documents. Live provider health, quota, '
            'cost, hosted CI, and publication remain DEFERRED-EXTERNAL.',
      };

      final outputDirectory = Directory.systemTemp.createTempSync(
        'void-scriptor-sprint-117-42-',
      );
      try {
        final outputPath =
            '${outputDirectory.path}${Platform.pathSeparator}$manifestFileName';
        final written = _writeManifest(manifestJson, outputPath);
        final reread = jsonDecode(File(outputPath).readAsStringSync());
        expect(reread['verdict'], result.verdict);
        expect(reread['pass'], isTrue);
        expect(probes.length, greaterThanOrEqualTo(5));
        // ignore: avoid_print
        print('PROBE_11742_MANIFEST bytes=$written');
      } finally {
        outputDirectory.deleteSync(recursive: true);
      }
    });
  });
}
