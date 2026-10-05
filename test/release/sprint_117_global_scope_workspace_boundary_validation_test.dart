/// Canonical step 117.11 — Global Scope & Workspace Boundary Validation.
///
/// Objective (external canonical JSON): make sure the global Account Center
/// and access to the Novel / Character workspaces still require permission
/// and separate consent.
///
/// The six acceptance names span two committed contracts — 115.3's global
/// information architecture and 115.4's workspace boundary — plus the product
/// spec's `placement` block, so the check and the drill are deliberately
/// separate classes:
///
/// * [Sprint117GlobalScopeDrill] really executes the shipped mechanisms: the
///   route classification, the router registration with its query-preserving
///   legacy redirect, the profile shortcut through the navigation registry,
///   `resolveWorkspaceAccess`, `WorkspacePermissionPolicy`, the full
///   18-decision `resolveTransfer` matrix, and `backupBoundaryViolations`
///   over a real `WorkspaceFileNamespace`.
/// * [Sprint117GlobalScopeLoader] reads the committed manifests and the
///   product spec they pin, and never invents a check or an outcome.
/// * [Sprint117GlobalScopeGate] decides whether the recorded evidence is
///   coherent, synchronously and without side effects.
///
/// The decided-vs-coherent distinction carries over unchanged. A check no
/// drill has executed is *undetermined*; a check executed and then
/// contradicted is a violation. Three gates are drilled but have zero callers
/// in shipped `lib/` code outside their own contract — that absence is
/// recorded with the exact symbol spelling, never folded into a pass.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_global_scope_workspace_boundary_validation.dart';
import '../canonical_source_support.dart';

void main() {
  const step = Sprint117GlobalScopeContract.canonicalStep;

  group('contract surface', () {
    test('covers the six canonical checks in canonical order', () {
      expect(Sprint117GlobalScopeContract.requiredChecks, <String>[
        'global_route',
        'profile_summary_only',
        'novel_permission',
        'character_permission',
        'transfer_consent',
        'no_cross_workspace_leak',
      ]);
    });

    test('declares the canonical step as 117.11', () {
      expect(step, '117.11');
    });

    test(
      'every source manifest and evidence file it depends on is committed',
      () {
        for (final path in [
          ...Sprint117GlobalScopeContract.sourceManifests,
          ...Sprint117GlobalScopeContract.evidenceFiles,
        ]) {
          expect(
            File(path).existsSync(),
            isTrue,
            reason: 'source $path must exist to be a real source',
          );
        }
      },
    );

    test('profile surface shows mirror the product spec contract list', () {
      expect(Sprint117GlobalScopeContract.profileSurfaceShows, <String>[
        'avatar',
        'display_name',
        'plan',
        'connection_health',
        'remote_storage_summary',
        'security_summary',
        'open_account_cloud_center_action',
      ]);
      expect(
        Sprint117GlobalScopeContract.profileSurfaceRole,
        'SUMMARY_AND_SHORTCUT_ONLY',
      );
    });
  });

  group('drill', () {
    late Sprint117GlobalScopeDrillRun run;

    setUpAll(() async {
      run = await const Sprint117GlobalScopeDrill().run();
    });

    test('produces exactly one observation per canonical check', () {
      expect(
        run.observations.map((observation) => observation.checkId).toList(),
        Sprint117GlobalScopeContract.requiredChecks,
      );
    });

    test('every observation passes', () {
      if (skipUnlessExternalCanonical("every observation passes")) {
        return;
      }
      expect(
        run.allPassed,
        isTrue,
        reason: 'a failing observation names the local mechanism that broke',
      );
    });

    test('never touches a live install or a user project', () {
      expect(run.liveInstallTouched, isFalse);
      expect(run.userProjectTouched, isFalse);
    });

    test('verifies the product spec against the committed 115.4 pin', () {
      if (skipUnlessExternalCanonical(
        "verifies the product spec against the committed 115.4 pin",
      )) {
        return;
      }
      expect(run.productSpecPinnedSha256, hasLength(64));
      expect(run.productSpecActualSha256, hasLength(64));
      expect(run.productSpecMatchesPin, isTrue);
    });

    test('global route check: manifest, contract classification, router, and '
        'navigation registry all agree', () {
      final observation = run.observationFor('global_route')!;
      expect(observation.passed, isTrue);
      expect(
        observation.facts['manifest_canonical_route'],
        '/account/cloud-center',
      );
      expect(observation.facts['manifest_legacy_alias'], '/account-cloud');
      expect(observation.facts['declared_scope'], 'GLOBAL_USER');
      expect(observation.facts['classified_global_by_contract'], isTrue);
      expect(
        observation.facts['workspace_and_relative_routes_rejected'],
        isTrue,
      );
      expect(observation.facts['router_registers_canonical_route'], isTrue);
      expect(
        observation.facts['router_legacy_redirect_preserves_query'],
        isTrue,
      );
      expect(observation.facts['navigation_shortcut_key'], 'account-cloud');
      expect(observation.facts['navigation_shortcut_declared'], isTrue);
    });

    test('profile check resolves every product-spec show and carries the '
        'shortcut without workspace payload', () {
      if (skipUnlessExternalCanonical(
        "profile check resolves every product-spec show and carries the ",
      )) {
        return;
      }
      final observation = run.observationFor('profile_summary_only')!;
      expect(observation.passed, isTrue);
      expect(observation.facts['declared_role'], 'SUMMARY_AND_SHORTCUT_ONLY');
      expect(observation.facts['unresolved_shows'], isEmpty);
      expect(
        observation.facts['declared_shows']! as List<String>,
        hasLength(7),
      );
      expect(observation.facts['spec_invariant_2_covered'], isTrue);
      expect(observation.facts['alpha_bucket_invariant_2_held'], isTrue);
      expect(observation.facts['menu_carries_shortcut'], isTrue);
      expect(observation.facts['navigation_shortcut_declared'], isTrue);
      expect(observation.facts['snapshot_model_fields_summary_only'], isTrue);
      expect(observation.facts['surface_namespace_tokens'], isEmpty);
      expect(observation.facts['snapshot_namespace_tokens'], isEmpty);
    });

    test(
      'novel permission check denies without permission, allows with it',
      () {
        final observation = run.observationFor('novel_permission')!;
        expect(observation.passed, isTrue);
        expect(
          observation.facts['denied_decision'],
          'DENIED_WORKSPACE_PERMISSION_REQUIRED',
        );
        expect(
          observation.facts['allowed_decision'],
          'ALLOWED_WORKSPACE_SCOPED',
        );
        expect(
          observation.facts['global_without_permission_decision'],
          'ALLOWED_GLOBAL_SCOPE',
        );
        expect(observation.facts['projection_read_without_link'], isFalse);
        expect(
          observation.facts['projection_read_with_owner_and_link'],
          isTrue,
        );
        expect(
          observation.unresolvable,
          contains('resolve_workspace_access_caller_absent'),
        );
      },
    );

    test('character permission check additionally gates canon writes and '
        'private fields', () {
      final observation = run.observationFor('character_permission')!;
      expect(observation.passed, isTrue);
      expect(
        observation.facts['denied_decision'],
        'DENIED_WORKSPACE_PERMISSION_REQUIRED',
      );
      expect(observation.facts['canon_write_without_owner_api'], isFalse);
      expect(observation.facts['canon_write_with_owner_api'], isTrue);
      expect(observation.facts['private_fields_without_grant'], isFalse);
    });

    test('transfer check resolves all 18 decisions with zero mismatches', () {
      final observation = run.observationFor('transfer_consent')!;
      expect(observation.passed, isTrue);
      expect(observation.facts['decisions_resolved'], 18);
      expect(observation.facts['expected_decisions'], 18);
      expect(observation.facts['mismatches'], 0);
      expect(
        observation.unresolvable,
        contains('resolve_transfer_caller_absent'),
      );
    });

    test('leak check matches namespaces, rejects traversal, flags every '
        'documented violation class, and finds no workspace payload on '
        'account surfaces', () {
      final observation = run.observationFor('no_cross_workspace_leak')!;
      expect(observation.passed, isTrue);
      expect(observation.facts['novel_root_relative'], 'workspaces/novels');
      expect(
        observation.facts['character_root_relative'],
        'workspaces/characters',
      );
      expect(observation.facts['namespaces_match_contract'], isTrue);
      expect(observation.facts['path_traversal_rejected'], isTrue);
      expect(
        observation.facts['backup_violations_behave_as_documented'],
        isTrue,
      );
      expect(
        observation.facts['account_surface_files_with_namespace'],
        isEmpty,
      );
      expect(
        observation.unresolvable,
        contains('backup_boundary_violations_caller_absent'),
      );
    });

    test('records the exact spelling of every unresolved reference', () {
      expect(run.unresolvableReferences, <String>[
        'backup_boundary_violations_caller_absent',
        'resolve_transfer_caller_absent',
        'resolve_workspace_access_caller_absent',
      ]);
    });

    test('every unresolvable reference stays a flat exact token', () {
      for (final observation in run.observations) {
        for (final reference in observation.unresolvable) {
          expect(
            reference,
            matches(RegExp(r'^[a-z0-9_]+$')),
            reason: 'unresolvable references stay a flat exact token',
          );
        }
      }
    });

    test('separates acceptances the drill demonstrated from the ones it '
        'could not, so six passing rows never read as six claims', () {
      if (skipUnlessExternalCanonical(
        "separates acceptances the drill demonstrated from the ones it ",
      )) {
        return;
      }
      // The getter sorts for stable reporting; canonical order lives on the
      // observations themselves.
      final sortedCanonical = (List<String>.of(
        Sprint117GlobalScopeContract.requiredChecks,
      )..sort());
      expect(run.acceptanceSatisfied, sortedCanonical);
      expect(run.acceptanceUnmet, isEmpty);
      for (final checkId in run.acceptanceSatisfied) {
        expect(
          run.observationFor(checkId)!.passed,
          isTrue,
          reason: 'an acceptance may only be claimed when demonstrated',
        );
      }
    });

    test('serializes to JSON with string keys everywhere', () {
      if (skipUnlessExternalCanonical(
        "serializes to JSON with string keys everywhere",
      )) {
        return;
      }
      final encoded = jsonEncode(run.toJson());
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(decoded['all_passed'], isTrue);
      expect(
        (decoded['observations'] as List<dynamic>).length,
        Sprint117GlobalScopeContract.requiredChecks.length,
      );
    });
  });

  group('loader', () {
    test(
      'reads six rows in canonical order, all undefined without a drill',
      () {
        final input = const Sprint117GlobalScopeLoader().load();
        expect(input.rows, isNotNull);
        expect(
          input.rows!.map((row) => row.checkId).toList(),
          Sprint117GlobalScopeContract.requiredChecks,
        );
        expect(
          input.rows!.every((row) => row.observedOutcome == null),
          isTrue,
          reason: 'no drill has run, so nothing may claim an outcome',
        );
        expect(input.drillRun, isNull);
      },
    );

    test('anchors every decision to committed manifests and a pinned spec', () {
      if (skipUnlessExternalCanonical(
        "anchors every decision to committed manifests and a pinned spec",
      )) {
        return;
      }
      final anchor = const Sprint117GlobalScopeLoader().load().anchor!;
      expect(anchor.informationArchitectureDeclared, startsWith('DECLARED:'));
      expect(anchor.workspaceBoundaryDeclared, startsWith('DECLARED:'));
      expect(anchor.alphaAcceptanceDeclared, startsWith('DECLARED:'));
      expect(anchor.boundaryEvidenceDeclared, isTrue);
      expect(anchor.iaEvidenceDeclared, isTrue);
      expect(anchor.productSpecPinned, isTrue);
      expect(anchor.productSpecPresent, isTrue);
      expect(anchor.productSpecMatchesPin, isTrue);
      expect(anchor.evidenceFiles.values, everyElement(isTrue));
    });

    test(
      'folds a measured drill into the rows without inventing outcomes',
      () async {
        if (skipUnlessExternalCanonical(
          "folds a measured drill into the rows without inventing outcomes",
        )) {
          return;
        }
        final drill = await const Sprint117GlobalScopeDrill().run();
        final input = const Sprint117GlobalScopeLoader().loadWithDrill(drill);
        expect(input.drillRun, same(drill));
        expect(input.productSpecIntegrityDrift, isFalse);
        for (final row in input.rows!) {
          expect(
            row.observedOutcome,
            drill.observationFor(row.checkId)!.outcome,
            reason: 'a recorded outcome must come from the measured drill',
          );
        }
      },
    );
  });

  group('gate', () {
    late Sprint117GlobalScopeDrillRun drill;

    setUpAll(() async {
      drill = await const Sprint117GlobalScopeDrill().run();
    });

    test('passes on the measured drill run', () async {
      if (skipUnlessExternalCanonical("passes on the measured drill run")) {
        return;
      }
      final report = await const Sprint117GlobalScopeGate().evaluateWithDrill(
        drill,
      );
      expect(report.status, Sprint117GlobalScopeState.pass);
      expect(report.verdict, 'GLOBAL_SCOPE_WORKSPACE_BOUNDARY_VALIDATED_LOCAL');
      expect(report.violations, isEmpty);
      expect(report.missingFields, isEmpty);
      expect(report.unmappedChecks, isEmpty);
      expect(report.undeterminedChecks, isEmpty);
      expect(report.coverage, 1);
      expect(
        report.acceptanceSatisfied,
        List<String>.of(Sprint117GlobalScopeContract.requiredChecks)..sort(),
      );
      expect(report.acceptanceUnmet, isEmpty);
      expect(
        report.openItems,
        contains('widget_route_evidence_reused_not_reexecuted'),
      );
      expect(
        report.openItems,
        contains('external_product_spec_outside_repository'),
      );
      expect(
        report.openItems,
        contains('unresolvable_reference:resolve_transfer_caller_absent'),
      );
    });

    test('blocks when no drill has ever run', () {
      final report = const Sprint117GlobalScopeGate().evaluate();
      expect(report.status, Sprint117GlobalScopeState.blocked);
      expect(
        report.verdict,
        'GLOBAL_SCOPE_WORKSPACE_BOUNDARY_BLOCKED_NO_LOCAL_EVIDENCE',
      );
      expect(report.missingFields, contains('drill_run'));
      expect(report.coverage, 0);
      expect(report.undeterminedChecks, [
        'character_permission',
        'global_route',
        'no_cross_workspace_leak',
        'novel_permission',
        'profile_summary_only',
        'transfer_consent',
      ]);
      expect(report.acceptanceSatisfied, isEmpty);
      expect(report.acceptanceUnmet, isEmpty);
    });

    test('refuses a check whose observed outcome contradicts the drill', () {
      final rows = const Sprint117GlobalScopeLoader()
          .loadWithDrill(drill)
          .rows!;
      final tampered = <Sprint117GlobalScopeCheck>[
        for (final row in rows)
          if (row.checkId == 'transfer_consent')
            Sprint117GlobalScopeCheck(
              checkId: row.checkId,
              method: row.method,
              expectedOutcome: row.expectedOutcome,
              observedOutcome: 'TRANSFER_NEEDS_NO_CONSENT',
              sourceManifest: row.sourceManifest,
              liveInstallResult: false,
              drilledAgainstLiveInstall: false,
            )
          else
            row,
      ];
      final report = const Sprint117GlobalScopeGate().evaluateWith(
        Sprint117GlobalScopeInput(rows: tampered, drillRun: drill),
      );
      expect(report.status, Sprint117GlobalScopeState.fail);
      expect(
        report.violations,
        contains('check_outcome_contradicts_drill:transfer_consent'),
      );
    });

    test('refuses a check that claims a live-install result', () {
      final rows = const Sprint117GlobalScopeLoader()
          .loadWithDrill(drill)
          .rows!;
      final claimed = <Sprint117GlobalScopeCheck>[
        for (final row in rows)
          if (row.checkId == 'global_route')
            Sprint117GlobalScopeCheck(
              checkId: row.checkId,
              method: row.method,
              expectedOutcome: row.expectedOutcome,
              observedOutcome: row.observedOutcome,
              sourceManifest: row.sourceManifest,
              liveInstallResult: true,
              drilledAgainstLiveInstall: false,
            )
          else
            row,
      ];
      final report = const Sprint117GlobalScopeGate().evaluateWith(
        Sprint117GlobalScopeInput(rows: claimed, drillRun: drill),
      );
      expect(report.status, Sprint117GlobalScopeState.fail);
      expect(
        report.violations,
        contains('check_live_install_claim:global_route'),
      );
    });

    test('refuses a product spec whose hash no longer matches the pin', () {
      final report = const Sprint117GlobalScopeGate().evaluateWith(
        Sprint117GlobalScopeInput(
          rows: const Sprint117GlobalScopeLoader().loadWithDrill(drill).rows,
          drillRun: drill,
          productSpecIntegrityDrift: true,
        ),
      );
      expect(report.status, Sprint117GlobalScopeState.fail);
      expect(report.violations, contains('product_spec_integrity_drift'));
    });

    test('refuses a drill that wrote to a user project', () {
      final touched = Sprint117GlobalScopeDrillRun(
        observations: drill.observations,
        liveInstallTouched: false,
        userProjectTouched: true,
        productSpecPinnedSha256: drill.productSpecPinnedSha256,
        productSpecActualSha256: drill.productSpecActualSha256,
      );
      final report = const Sprint117GlobalScopeGate().evaluateWith(
        Sprint117GlobalScopeInput(
          rows: const Sprint117GlobalScopeLoader().loadWithDrill(drill).rows,
          drillRun: touched,
        ),
      );
      expect(report.status, Sprint117GlobalScopeState.fail);
      expect(report.violations, contains('user_project_touched'));
    });

    test('refuses a drill whose product spec pin drifted during the run', () {
      final drifted = Sprint117GlobalScopeDrillRun(
        observations: drill.observations,
        liveInstallTouched: false,
        userProjectTouched: false,
        productSpecPinnedSha256: 'dead'.padRight(64, '0'),
        productSpecActualSha256: drill.productSpecActualSha256,
      );
      final report = const Sprint117GlobalScopeGate().evaluateWith(
        Sprint117GlobalScopeInput(
          rows: const Sprint117GlobalScopeLoader().loadWithDrill(drill).rows,
          drillRun: drifted,
        ),
      );
      expect(report.status, Sprint117GlobalScopeState.fail);
      expect(report.violations, contains('product_spec_integrity_drift'));
    });

    test('reports a missing evidence file as a missing field, not a pass', () {
      if (skipUnlessExternalCanonical(
        "reports a missing evidence file as a missing field, not a pass",
      )) {
        return;
      }
      final anchor = const Sprint117GlobalScopeLoader().load().anchor!;
      final broken = Sprint117GlobalScopeAnchor(
        informationArchitectureDeclared: anchor.informationArchitectureDeclared,
        workspaceBoundaryDeclared: anchor.workspaceBoundaryDeclared,
        alphaAcceptanceDeclared: anchor.alphaAcceptanceDeclared,
        productSpecPinnedSha256: anchor.productSpecPinnedSha256,
        productSpecActualSha256: anchor.productSpecActualSha256,
        boundaryEvidenceDeclared: anchor.boundaryEvidenceDeclared,
        iaEvidenceDeclared: anchor.iaEvidenceDeclared,
        evidenceFiles: <String, bool>{'docs/missing-source.json': false},
      );
      final report = const Sprint117GlobalScopeGate().evaluateWith(
        Sprint117GlobalScopeInput(
          rows: const Sprint117GlobalScopeLoader().loadWithDrill(drill).rows,
          anchor: broken,
          drillRun: drill,
        ),
      );
      expect(report.status, Sprint117GlobalScopeState.blocked);
      expect(
        report.missingFields,
        contains('evidence_file:docs/missing-source.json'),
      );
    });

    test('serializes the report to JSON with string keys everywhere', () async {
      if (skipUnlessExternalCanonical(
        "serializes the report to JSON with string keys everywhere",
      )) {
        return;
      }
      final report = await const Sprint117GlobalScopeGate().evaluateWithDrill(
        drill,
      );
      final decoded =
          jsonDecode(jsonEncode(report.toJson())) as Map<String, dynamic>;
      expect(
        decoded['verdict'],
        'GLOBAL_SCOPE_WORKSPACE_BOUNDARY_VALIDATED_LOCAL',
      );
      expect(decoded['status'], 'pass');
      expect(decoded['coverage'], 1);
      expect((decoded['checks'] as List<dynamic>).length, 6);
      expect((decoded['open_items'] as List<dynamic>), isNotEmpty);
    });
  });
}
