/// Canonical step 117.11 — Global Scope & Workspace Boundary Validation.
///
/// Objective (external canonical JSON): make sure the global Account Center
/// and access to the Novel / Character workspaces still require permission
/// and separate consent.
///
/// The six acceptance names span two committed contracts — 115.3's global
/// information architecture and 115.4's workspace boundary — plus the product
/// spec's `placement` block, so the check and the drill are deliberately
/// separate classes, exactly as 117.5-117.10 did:
///
/// * [Sprint117GlobalScopeDrill] really executes the shipped mechanisms:
///   the route constants and their boundary classification, the profile
///   shortcut through the live navigation registry, `resolveWorkspaceAccess`,
///   `WorkspacePermissionPolicy` behind the real projection reader, the full
///   18-decision `resolveTransfer` matrix, and `backupBoundaryViolations`
///   fed with workspace paths derived from the shipped WorkspaceFileNamespace
///   over a real ProjectPackage. It writes nothing.
/// * [Sprint117GlobalScopeLoader] reads the committed manifests and the
///   product spec they pin, and never invents a check or an outcome.
/// * [Sprint117GlobalScopeGate] decides whether the recorded evidence is
///   coherent, synchronously and without side effects.
///
/// The decided-vs-coherent distinction carries over unchanged. A check no
/// drill has executed is *undetermined*; a check executed and then
/// contradicted is a violation. Three of the six checks additionally record a
/// measured absence: `resolveWorkspaceAccess`, `resolveTransfer`, and
/// `backupBoundaryViolations` have zero call sites anywhere in `lib/` outside
/// their own contract file, so the boundary gates are defined and drilled but
/// not yet invoked by shipped code. That is reported with the exact spelling
/// of the symbol, never folded into a pass.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:void_scriptor/app/navigation/app_navigation_registry.dart';
import 'package:void_scriptor/app/routing/app_routes.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/features/account/domain/account_center_workspace_boundary_contract.dart';
import 'package:void_scriptor/features/account/domain/account_cloud_snapshot.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_file_namespace.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_permission_policy.dart';

part 'sprint_117_global_scope_drill.dart';

enum Sprint117GlobalScopeState { pass, fail, blocked }

/// Immutable description of the contract, its sources, and its verdicts.
abstract final class Sprint117GlobalScopeContract {
  static const String canonicalStep = '117.11';

  /// 115.3 supplies the global route, the legacy alias, and the profile
  /// shortcut key.
  static const String informationArchitecture =
      'docs/planning/v1.2/sprint_115_global_information_architecture.json';

  /// 115.4 supplies the permission gate, the transfer-consent gate, the
  /// backup-boundary validator, and the product-spec integrity pin.
  static const String workspaceBoundary =
      'docs/planning/v1.2/sprint_115_workspace_boundary_contract.json';

  /// 115.55 records the alpha acceptance buckets, including the profile
  /// summary invariant.
  static const String alphaAcceptance =
      'docs/planning/v1.2/sprint_115_alpha_acceptance.json';

  /// Committed widget evidence that really navigates the canonical route and
  /// the legacy redirect. Reused here, not re-executed.
  static const String routeWidgetEvidence =
      'test/app/routing/account_cloud_center_ia_route_test.dart';

  /// Committed domain evidence for the boundary contract itself.
  static const String boundaryContractEvidence =
      'test/features/account/domain/account_center_workspace_boundary_contract_test.dart';

  /// Every committed source this validation decides from.
  static const List<String> sourceManifests = <String>[
    informationArchitecture,
    workspaceBoundary,
    alphaAcceptance,
  ];

  /// Committed evidence files this validation reuses instead of re-running.
  static const List<String> evidenceFiles = <String>[
    routeWidgetEvidence,
    boundaryContractEvidence,
  ];

  /// The surface whose contents the profile check measures.
  static const String summarySurfaceSource =
      'lib/features/account/presentation/account_cloud_center_screen.dart';

  /// The data model behind the account summary rail.
  static const String summaryModelSource =
      'lib/features/account/domain/account_cloud_snapshot.dart';

  /// The top-bar account menu that carries the profile shortcut.
  static const String accountMenuSource =
      'lib/app/shell/desktop/void_top_bar.dart';

  /// The router file whose route table is scanned for registration.
  static const String routerSource = 'lib/app/routing/app_router.dart';

  /// The six checks canonical step 117.11 names, in canonical order.
  static const List<String> requiredChecks = <String>[
    'global_route',
    'profile_summary_only',
    'novel_permission',
    'character_permission',
    'transfer_consent',
    'no_cross_workspace_leak',
  ];

  /// The product spec's `placement.profile_surface.shows` list, in spec order.
  static const List<String> profileSurfaceShows = <String>[
    'avatar',
    'display_name',
    'plan',
    'connection_health',
    'remote_storage_summary',
    'security_summary',
    'open_account_cloud_center_action',
  ];

  /// The product spec's `placement.profile_surface.role`.
  static const String profileSurfaceRole = 'SUMMARY_AND_SHORTCUT_ONLY';

  static const String passVerdict =
      'GLOBAL_SCOPE_WORKSPACE_BOUNDARY_VALIDATED_LOCAL';
  static const String blockedVerdict =
      'GLOBAL_SCOPE_WORKSPACE_BOUNDARY_BLOCKED_NO_LOCAL_EVIDENCE';
  static const String failVerdict =
      'GLOBAL_SCOPE_WORKSPACE_BOUNDARY_INCONSISTENT';
}

/// One canonical check, the method that exercises it, and its outcome.
class Sprint117GlobalScopeCheck {
  Sprint117GlobalScopeCheck({
    required this.checkId,
    required this.method,
    required this.expectedOutcome,
    required this.observedOutcome,
    required this.sourceManifest,
    required this.liveInstallResult,
    required this.drilledAgainstLiveInstall,
  });

  /// The canonical check identity, e.g. `global_route`.
  final String checkId;

  /// The step this validation runs. Empty means the check only wishes for it.
  final String method;

  /// What the method is expected to produce locally.
  final String expectedOutcome;

  /// What the local drill actually produced. Null while no drill has run.
  final String? observedOutcome;

  /// The upstream manifest that defines this check.
  final String sourceManifest;

  /// Whether a live install produced this outcome. It never has.
  final bool liveInstallResult;

  /// Whether the check ran against a real install. It never did.
  final bool drilledAgainstLiveInstall;

  bool get executed =>
      observedOutcome != null && observedOutcome!.trim().isNotEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
    'check_id': checkId,
    'method': method,
    'expected_outcome': expectedOutcome,
    'observed_outcome': observedOutcome,
    'executed': executed,
    'source_manifest': sourceManifest,
    'live_install_result': liveInstallResult,
    'drilled_against_live_install': drilledAgainstLiveInstall,
  };
}

/// The evidence this validation is allowed to decide from.
class Sprint117GlobalScopeAnchor {
  Sprint117GlobalScopeAnchor({
    required this.informationArchitectureDeclared,
    required this.workspaceBoundaryDeclared,
    required this.alphaAcceptanceDeclared,
    required this.productSpecPinnedSha256,
    required this.productSpecActualSha256,
    required this.boundaryEvidenceDeclared,
    required this.iaEvidenceDeclared,
    required Map<String, bool> evidenceFiles,
  }) : evidenceFiles = Map<String, bool>.unmodifiable(evidenceFiles);

  /// How many contract items 115.3 declares.
  final String informationArchitectureDeclared;

  /// How many contract items 115.4 declares.
  final String workspaceBoundaryDeclared;

  /// How many buckets 115.55 declares.
  final String alphaAcceptanceDeclared;

  /// The product-spec sha256 115.4 pins.
  final String productSpecPinnedSha256;

  /// The sha256 actually computed over the external product spec. Empty when
  /// the file cannot be read.
  final String productSpecActualSha256;

  /// Whether 115.4 states where its own evidence stops.
  final bool boundaryEvidenceDeclared;

  /// Whether 115.3 states where its own evidence stops.
  final bool iaEvidenceDeclared;

  /// Whether each committed evidence file still exists on disk.
  final Map<String, bool> evidenceFiles;

  bool get productSpecPinned => productSpecPinnedSha256.trim().isNotEmpty;

  bool get productSpecPresent => productSpecActualSha256.trim().isNotEmpty;

  bool get productSpecMatchesPin =>
      productSpecPinned &&
      productSpecPresent &&
      productSpecActualSha256 == productSpecPinnedSha256;
}

class Sprint117GlobalScopeInput {
  const Sprint117GlobalScopeInput({
    this.rows,
    this.anchor,
    this.drillRun,
    this.productSpecIntegrityDrift = false,
  });

  final List<Sprint117GlobalScopeCheck>? rows;
  final Sprint117GlobalScopeAnchor? anchor;
  final Sprint117GlobalScopeDrillRun? drillRun;

  /// Whether the external product spec's hash no longer matches the pin.
  final bool productSpecIntegrityDrift;
}

/// Whether a canonical acceptance could be satisfied by shipped code at all.
enum Sprint117GlobalScopeAcceptance { satisfied, mechanismAbsent }

/// One measured local observation behind a canonical check.
class Sprint117GlobalScopeObservation {
  Sprint117GlobalScopeObservation({
    required this.checkId,
    required this.outcome,
    required Map<String, Object?> facts,
    required this.passed,
    required this.acceptance,
    required List<String> unresolvable,
  }) : facts = Map<String, Object?>.unmodifiable(facts),
       unresolvable = List<String>.unmodifiable(unresolvable);

  final String checkId;

  /// What the local exercise produced.
  final String outcome;

  /// The measured facts behind that outcome.
  final Map<String, Object?> facts;

  /// Whether the local mechanism responded as the contract expects.
  final bool passed;

  /// Whether the acceptance this check stands for could be satisfied.
  final Sprint117GlobalScopeAcceptance acceptance;

  /// Recorded subjects the check could not resolve, spelled exactly.
  final List<String> unresolvable;

  bool get acceptanceSatisfied =>
      acceptance == Sprint117GlobalScopeAcceptance.satisfied;

  Map<String, Object?> toJson() => <String, Object?>{
    'check_id': checkId,
    'outcome': outcome,
    'facts': Map<String, Object?>.from(facts),
    'passed': passed,
    'acceptance': acceptance.name,
    'acceptance_satisfied': acceptanceSatisfied,
    'unresolvable': List<String>.from(unresolvable),
  };
}

/// The record of one local drill run.
class Sprint117GlobalScopeDrillRun {
  Sprint117GlobalScopeDrillRun({
    required List<Sprint117GlobalScopeObservation> observations,
    required this.liveInstallTouched,
    required this.userProjectTouched,
    required this.productSpecPinnedSha256,
    required this.productSpecActualSha256,
  }) : observations = List<Sprint117GlobalScopeObservation>.unmodifiable(
         observations,
       );

  final List<Sprint117GlobalScopeObservation> observations;

  /// Always false: this drill installs nothing.
  final bool liveInstallTouched;

  /// Always false: this drill writes nothing — it only reads shipped code,
  /// committed manifests, and the external product spec.
  final bool userProjectTouched;

  /// The pin 115.4 records for the external product spec.
  final String productSpecPinnedSha256;

  /// The hash the drill computed over that spec while running.
  final String productSpecActualSha256;

  bool get productSpecMatchesPin =>
      productSpecPinnedSha256.isNotEmpty &&
      productSpecActualSha256 == productSpecPinnedSha256;

  /// Every recorded subject the drill could not resolve, across checks.
  List<String> get unresolvableReferences {
    final refs = <String>{
      for (final observation in observations)
        for (final reference in observation.unresolvable) reference,
    };
    return refs.toList(growable: false)..sort();
  }

  bool get allPassed => observations.every((observation) => observation.passed);

  /// Checks whose acceptance shipped code can actually satisfy, sorted.
  List<String> get acceptanceSatisfied {
    final satisfied = <String>[
      for (final observation in observations)
        if (observation.acceptanceSatisfied) observation.checkId,
    ];
    return satisfied..sort();
  }

  /// Checks whose acceptance cannot be satisfied, sorted.
  List<String> get acceptanceUnmet {
    final unmet = <String>[
      for (final observation in observations)
        if (!observation.acceptanceSatisfied) observation.checkId,
    ];
    return unmet..sort();
  }

  Sprint117GlobalScopeObservation? observationFor(String checkId) {
    for (final observation in observations) {
      if (observation.checkId == checkId) return observation;
    }
    return null;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'observations': <Map<String, Object?>>[
      for (final observation in observations) observation.toJson(),
    ],
    'live_install_touched': liveInstallTouched,
    'user_project_touched': userProjectTouched,
    'product_spec_pinned_sha256': productSpecPinnedSha256,
    'product_spec_actual_sha256': productSpecActualSha256,
    'product_spec_matches_pin': productSpecMatchesPin,
    'all_passed': allPassed,
    'acceptance_satisfied': acceptanceSatisfied,
    'acceptance_unmet': acceptanceUnmet,
    'unresolvable_references': unresolvableReferences,
  };
}

/// Reads the committed manifests and never invents a subject.
class Sprint117GlobalScopeLoader {
  const Sprint117GlobalScopeLoader();

  Sprint117GlobalScopeInput load() =>
      Sprint117GlobalScopeInput(rows: _loadRows(), anchor: _loadAnchor());

  /// Folds the measured drill into the committed record.
  Sprint117GlobalScopeInput loadWithDrill(Sprint117GlobalScopeDrillRun run) =>
      Sprint117GlobalScopeInput(
        rows: _loadRows(run),
        anchor: _loadAnchor(),
        drillRun: run,
        // A run that never resolved the pin cannot prove drift either; only a
        // recorded pin that no longer matches is a contradiction.
        productSpecIntegrityDrift:
            run.productSpecPinnedSha256.isNotEmpty &&
            !run.productSpecMatchesPin,
      );

  Sprint117GlobalScopeAnchor? _loadAnchor() {
    final ia = _readJsonFile(
      Sprint117GlobalScopeContract.informationArchitecture,
    );
    final boundary = _readJsonFile(
      Sprint117GlobalScopeContract.workspaceBoundary,
    );
    final alpha = _readJsonFile(Sprint117GlobalScopeContract.alphaAcceptance);
    if (ia == null || boundary == null || alpha == null) return null;

    return Sprint117GlobalScopeAnchor(
      informationArchitectureDeclared: _declaredContractSize(ia, const <String>[
        'acceptance_coverage',
      ]),
      workspaceBoundaryDeclared: _declaredContractSize(boundary, const <String>[
        'acceptance',
      ]),
      alphaAcceptanceDeclared: _declaredContractSize(alpha, const <String>[
        'buckets',
      ]),
      productSpecPinnedSha256: _productSpecPinFrom(boundary),
      productSpecActualSha256: _productSpecActualSha(boundary),
      boundaryEvidenceDeclared: _declaredText(boundary, const <String>[
        'boundary',
        'evidence_boundary',
      ]),
      iaEvidenceDeclared: _declaredText(ia, const <String>[
        'boundary',
        'evidence_boundary',
        'evidence_limits',
      ]),
      evidenceFiles: <String, bool>{
        for (final path in Sprint117GlobalScopeContract.evidenceFiles)
          path: File(path).existsSync(),
      },
    );
  }

  List<Sprint117GlobalScopeCheck>? _loadRows([
    Sprint117GlobalScopeDrillRun? run,
  ]) {
    if (_loadAnchor() == null) return null;
    return <Sprint117GlobalScopeCheck>[
      for (final checkId in Sprint117GlobalScopeContract.requiredChecks)
        if (_defined(checkId))
          Sprint117GlobalScopeCheck(
            checkId: checkId,
            method: _method(checkId),
            expectedOutcome: _expectedOutcome(checkId),
            // Only the measured drill may supply an outcome. With no drill the
            // check stays undetermined rather than borrowing a verdict.
            observedOutcome: run?.observationFor(checkId)?.outcome,
            sourceManifest: _sourceFor(checkId),
            liveInstallResult: false,
            drilledAgainstLiveInstall: false,
          ),
    ];
  }

  /// A check exists only where its source records a contract. The profile
  /// check is anchored to the exact alpha bucket check the 115.55 manifest
  /// records, not to the mere existence of buckets.
  static bool _defined(String checkId) {
    final path = _sourceFor(checkId);
    final source = _readJsonFile(path);
    if (source == null) return false;
    if (checkId == 'profile_summary_only') {
      return _alphaCheckHeld(source, 'invariant_2_profile_summary_covered');
    }
    return _declaredContractSize(source, _contractKeysFor(path)).isNotEmpty;
  }

  /// Whether the 115.55 manifest records [name] as a held check.
  static bool _alphaCheckHeld(Map<String, dynamic> alpha, String name) {
    final buckets = alpha['buckets'];
    if (buckets is! List<dynamic>) return false;
    for (final rawBucket in buckets) {
      if (rawBucket is! Map<String, dynamic>) continue;
      final checks = rawBucket['checks'];
      if (checks is! List<dynamic>) continue;
      for (final rawCheck in checks) {
        if (rawCheck is! Map<String, dynamic>) continue;
        if (rawCheck['name'] == name && rawCheck['held'] == true) {
          return true;
        }
      }
    }
    return false;
  }

  /// The committed manifest that owns a check.
  static String _sourceFor(String checkId) => switch (checkId) {
    'global_route' => Sprint117GlobalScopeContract.informationArchitecture,
    'profile_summary_only' => Sprint117GlobalScopeContract.alphaAcceptance,
    'novel_permission' => Sprint117GlobalScopeContract.workspaceBoundary,
    'character_permission' => Sprint117GlobalScopeContract.workspaceBoundary,
    'transfer_consent' => Sprint117GlobalScopeContract.workspaceBoundary,
    'no_cross_workspace_leak' => Sprint117GlobalScopeContract.workspaceBoundary,
    _ => '',
  };

  /// The contract key each manifest declares its subject with. The 115 family
  /// is not uniform: 115.3 lists `acceptance_coverage`, 115.4 maps
  /// `acceptance`, 115.55 stacks `buckets`. Reading one key for all of them
  /// would report a real subject as undeclared.
  static List<String> _contractKeysFor(String path) => switch (path) {
    Sprint117GlobalScopeContract.informationArchitecture => const <String>[
      'acceptance_coverage',
    ],
    Sprint117GlobalScopeContract.workspaceBoundary => const <String>[
      'acceptance',
    ],
    Sprint117GlobalScopeContract.alphaAcceptance => const <String>['buckets'],
    _ => const <String>[],
  };

  /// The step this validation runs for a check.
  static String _method(String checkId) => switch (checkId) {
    'global_route' =>
      'resolve the canonical route through AppRoutes, the boundary '
          'contract, the router table, and the navigation registry',
    'profile_summary_only' =>
      'build the shipped account summary snapshot, inspect the profile '
          'menu, and resolve every product-spec profile show',
    'novel_permission' =>
      'gate Novel workspace access through the contract gate '
          'resolveWorkspaceAccess plus WorkspacePermissionPolicy link gates',
    'character_permission' =>
      'gate Character workspace access through the contract gate '
          'resolveWorkspaceAccess plus WorkspacePermissionPolicy link, owner, '
          'and character-owner-API gates',
    'transfer_consent' =>
      'resolve every scope pair through resolveTransfer with and without '
          'consent',
    'no_cross_workspace_leak' =>
      'derive workspace namespaces from WorkspaceFileNamespace, validate '
          'all three backup boundaries, and scan account surfaces',
    _ => '',
  };

  /// What the step is expected to produce locally.
  static String _expectedOutcome(String checkId) => switch (checkId) {
    'global_route' =>
      'canonical route resolves as a global surface outside workspace '
          'prefixes',
    'profile_summary_only' =>
      'profile surface carries account summary fields and the shortcut only',
    'novel_permission' =>
      'Novel access denied without explicit permission, allowed with it',
    'character_permission' =>
      'Character access denied without explicit permission, link, and grant',
    'transfer_consent' =>
      'global to global allowed; every workspace-touching pair denied '
          'without consent',
    'no_cross_workspace_leak' =>
      'shipped namespaces match the contract and account surfaces carry no '
          'workspace payload',
    _ => '',
  };

  /// How many contract items a source declares, or empty when it declares
  /// none.
  static String _declaredContractSize(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    for (final key in keys) {
      final declared = source[key];
      if (declared is List<dynamic> && declared.isNotEmpty) {
        return 'DECLARED:$key:${declared.length}';
      }
      if (declared is Map<String, dynamic> && declared.isNotEmpty) {
        return 'DECLARED:$key:${declared.length}';
      }
    }
    return '';
  }

  /// Whether a source states where its own evidence stops.
  static bool _declaredText(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) return true;
      if (value is List<dynamic> && value.isNotEmpty) return true;
    }
    return false;
  }
}

/// Decides whether the recorded global-scope evidence is coherent.
class Sprint117GlobalScopeGate {
  const Sprint117GlobalScopeGate();

  /// Runs the drill, then decides from its measured output.
  Future<Sprint117GlobalScopeReport> evaluateWithDrill([
    Sprint117GlobalScopeDrillRun? run,
  ]) async {
    final measured = run ?? await const Sprint117GlobalScopeDrill().run();
    return evaluateWith(
      const Sprint117GlobalScopeLoader().loadWithDrill(measured),
    );
  }

  Sprint117GlobalScopeReport evaluate() =>
      evaluateWith(const Sprint117GlobalScopeLoader().load());

  Sprint117GlobalScopeReport evaluateWith(Sprint117GlobalScopeInput input) {
    final missing = <String>{};
    final violations = <String>{};

    final anchor = input.anchor;
    if (anchor == null) {
      missing.add('global_scope_anchor');
    } else {
      if (anchor.informationArchitectureDeclared.trim().isEmpty) {
        missing.add('information_architecture_contract');
      }
      if (anchor.workspaceBoundaryDeclared.trim().isEmpty) {
        missing.add('workspace_boundary_contract');
      }
      if (anchor.alphaAcceptanceDeclared.trim().isEmpty) {
        missing.add('alpha_acceptance_contract');
      }
      if (!anchor.boundaryEvidenceDeclared) {
        violations.add('external_boundary_not_declared:workspace_boundary');
      }
      if (!anchor.iaEvidenceDeclared) {
        violations.add(
          'external_boundary_not_declared:information_architecture',
        );
      }
      if (!anchor.productSpecPinned) {
        missing.add('product_spec_pin');
      } else if (!anchor.productSpecPresent) {
        missing.add('product_spec_external');
      }
      for (final entry in anchor.evidenceFiles.entries) {
        if (!entry.value) missing.add('evidence_file:${entry.key}');
      }
    }

    // A product spec whose hash no longer matches the committed pin
    // contradicts every decision derived from it.
    if (input.productSpecIntegrityDrift) {
      violations.add('product_spec_integrity_drift');
    }

    final drillRun = input.drillRun;
    if (drillRun == null) {
      // Without a measured run there is no observed outcome to decide from,
      // so the report is blocked rather than passed on prose.
      missing.add('drill_run');
    } else {
      if (drillRun.liveInstallTouched) violations.add('live_install_touched');
      if (drillRun.userProjectTouched) violations.add('user_project_touched');
      if (drillRun.productSpecPinnedSha256.isNotEmpty &&
          !drillRun.productSpecMatchesPin) {
        violations.add('product_spec_integrity_drift');
      }
      if (!drillRun.allPassed) {
        for (final observation in drillRun.observations) {
          if (!observation.passed) {
            violations.add('drill_observation_failed:${observation.checkId}');
            violations.add('drill_outcome:${observation.outcome}');
          }
        }
      }
    }

    final rows = input.rows;
    final rowIds = <String>{};
    final checks = <Sprint117GlobalScopeCheck>[];
    final undetermined = <String>[];

    if (rows == null || rows.isEmpty) {
      missing.add('check_rows');
    } else {
      for (final row in rows) {
        final checkId = row.checkId.trim();
        if (checkId.isEmpty) {
          violations.add('check_id_blank');
          continue;
        }
        if (!rowIds.add(checkId)) {
          violations.add('check_duplicate:$checkId');
          continue;
        }
        checks.add(row);
        _checkCheck(row, drillRun, missing, violations);
        if (!row.executed) {
          undetermined.add(checkId);
          if (drillRun != null) missing.add('check_observed_outcome:$checkId');
        }
      }
    }

    final unmapped = <String>[];
    if (anchor != null && !missing.contains('global_scope_anchor')) {
      for (final checkId in Sprint117GlobalScopeContract.requiredChecks) {
        if (!rowIds.contains(checkId)) unmapped.add(checkId);
      }
      for (final checkId in unmapped) {
        violations.add('check_unmapped:$checkId');
      }
    }

    // Coverage counts canonical checks the evidence has actually decided, not
    // rows a manifest happened to declare.
    var decidedCount = 0;
    for (final row in checks) {
      if (row.executed) decidedCount += 1;
    }
    final total = Sprint117GlobalScopeContract.requiredChecks.length;
    final coverage = total == 0 ? 0.0 : decidedCount / total;

    final complete = missing.isEmpty && violations.isEmpty;
    final state = violations.isNotEmpty
        ? Sprint117GlobalScopeState.fail
        : (complete
              ? Sprint117GlobalScopeState.pass
              : Sprint117GlobalScopeState.blocked);

    return Sprint117GlobalScopeReport(
      status: state,
      verdict: switch (state) {
        Sprint117GlobalScopeState.pass =>
          Sprint117GlobalScopeContract.passVerdict,
        Sprint117GlobalScopeState.fail =>
          Sprint117GlobalScopeContract.failVerdict,
        Sprint117GlobalScopeState.blocked =>
          Sprint117GlobalScopeContract.blockedVerdict,
      },
      missingFields: missing.toList(growable: false)..sort(),
      violations: violations.toList(growable: false)..sort(),
      unmappedChecks: unmapped.toList(growable: false)..sort(),
      undeterminedChecks: undetermined.toList(growable: false)..sort(),
      coverage: coverage,
      acceptanceSatisfied: List<String>.of(
        drillRun?.acceptanceSatisfied ?? const <String>[],
      )..sort(),
      acceptanceUnmet: List<String>.of(
        drillRun?.acceptanceUnmet ?? const <String>[],
      )..sort(),
      checks: checks,
      anchor: anchor,
      openItems: _openItems(drillRun, undetermined),
    );
  }

  void _checkCheck(
    Sprint117GlobalScopeCheck row,
    Sprint117GlobalScopeDrillRun? drillRun,
    Set<String> missing,
    Set<String> violations,
  ) {
    final checkId = row.checkId.trim();
    if (row.method.trim().isEmpty) missing.add('check_method:$checkId');
    if (row.expectedOutcome.trim().isEmpty) {
      missing.add('check_expected_outcome:$checkId');
    }
    if (row.sourceManifest.trim().isEmpty) {
      missing.add('check_source_manifest:$checkId');
    } else if (!File(row.sourceManifest).existsSync()) {
      missing.add('check_source_manifest_missing:$checkId');
    }
    if (row.liveInstallResult) {
      violations.add('check_live_install_claim:$checkId');
    }
    if (row.drilledAgainstLiveInstall) {
      violations.add('check_live_install_claim:$checkId');
    }
    if (row.observedOutcome == null) {
      // Nothing has run, so the check stays undetermined — an open item, never
      // a violation this gate invents an observation for.
      return;
    }
    final measured = drillRun?.observationFor(checkId);
    if (measured == null) {
      violations.add('check_observation_unsourced:$checkId');
      return;
    }
    if (row.observedOutcome != measured.outcome) {
      violations.add('check_outcome_contradicts_drill:$checkId');
      violations.add('recorded_outcome:${row.observedOutcome}');
      violations.add('measured_outcome:${measured.outcome}');
    }
  }

  List<String> _openItems(
    Sprint117GlobalScopeDrillRun? drillRun,
    List<String> undetermined,
  ) {
    final items = <String>{
      for (final checkId in undetermined)
        'check_observed_outcome_null:$checkId',
      for (final checkId in drillRun?.acceptanceUnmet ?? const <String>[])
        'check_acceptance_unmet:$checkId',
      for (final reference
          in drillRun?.unresolvableReferences ?? const <String>[])
        'unresolvable_reference:$reference',
      'widget_route_evidence_reused_not_reexecuted',
      'external_product_spec_outside_repository',
    };
    return items.toList(growable: false)..sort();
  }
}

/// The gate's verdict, with the evidence it decided from.
class Sprint117GlobalScopeReport {
  Sprint117GlobalScopeReport({
    required this.status,
    required this.verdict,
    required List<String> missingFields,
    required List<String> violations,
    required List<String> unmappedChecks,
    required List<String> undeterminedChecks,
    required this.coverage,
    required List<String> acceptanceSatisfied,
    required List<String> acceptanceUnmet,
    required List<Sprint117GlobalScopeCheck> checks,
    required this.anchor,
    required List<String> openItems,
  }) : acceptanceSatisfied = List<String>.unmodifiable(acceptanceSatisfied),
       acceptanceUnmet = List<String>.unmodifiable(acceptanceUnmet),
       missingFields = List<String>.unmodifiable(missingFields),
       violations = List<String>.unmodifiable(violations),
       unmappedChecks = List<String>.unmodifiable(unmappedChecks),
       undeterminedChecks = List<String>.unmodifiable(undeterminedChecks),
       checks = List<Sprint117GlobalScopeCheck>.unmodifiable(checks),
       openItems = List<String>.unmodifiable(openItems);

  final Sprint117GlobalScopeState status;

  /// The decision this report carries.
  final String verdict;

  final List<String> missingFields;
  final List<String> violations;
  final List<String> unmappedChecks;

  /// Checks that are defined but that no drill has decided yet.
  final List<String> undeterminedChecks;

  /// Fraction of the canonical checks the evidence decided.
  final double coverage;

  /// Checks whose acceptance shipped code can satisfy.
  final List<String> acceptanceSatisfied;

  /// Checks whose acceptance cannot be satisfied because no mechanism ships.
  final List<String> acceptanceUnmet;

  final List<Sprint117GlobalScopeCheck> checks;
  final Sprint117GlobalScopeAnchor? anchor;

  /// Every open item this validation carries forward.
  final List<String> openItems;

  Map<String, Object?> toJson() => <String, Object?>{
    'verdict': verdict,
    'status': status.name,
    'missing_fields': List<String>.from(missingFields),
    'violations': List<String>.from(violations),
    'unmapped_checks': List<String>.from(unmappedChecks),
    'undetermined_checks': List<String>.from(undeterminedChecks),
    'coverage': coverage,
    'acceptance_satisfied': List<String>.from(acceptanceSatisfied),
    'acceptance_unmet': List<String>.from(acceptanceUnmet),
    'open_items': List<String>.from(openItems),
    'anchor': anchor?.toJson(),
    'checks': <Map<String, Object?>>[
      for (final check in checks) check.toJson(),
    ],
  };
}

extension on Sprint117GlobalScopeAnchor {
  Map<String, Object?> toJson() => <String, Object?>{
    'information_architecture_declared': informationArchitectureDeclared,
    'workspace_boundary_declared': workspaceBoundaryDeclared,
    'alpha_acceptance_declared': alphaAcceptanceDeclared,
    'product_spec_pinned_sha256': productSpecPinnedSha256,
    'product_spec_actual_sha256': productSpecActualSha256,
    'product_spec_matches_pin': productSpecMatchesPin,
    'boundary_evidence_declared': boundaryEvidenceDeclared,
    'ia_evidence_declared': iaEvidenceDeclared,
    'evidence_files': Map<String, bool>.from(evidenceFiles),
  };
}

/// The external product spec, as the committed 115.4 pin resolves it.
class _SpecFile {
  _SpecFile({required this.rawPath, required this.json});

  final String rawPath;
  final Map<String, dynamic> json;
}

/// The product-spec pin record inside 115.4, or null when absent.
Map<String, dynamic>? _productSpecPinRecord(Map<String, dynamic> boundary) {
  final sources = boundary['sources'];
  if (sources is! Map<String, dynamic>) return null;
  final spec = sources['product_spec'];
  if (spec is! Map<String, dynamic>) return null;
  return spec;
}

/// The product-spec path 115.4 pins, or null when the pin is missing.
String? _productSpecPinPathFrom(Map<String, dynamic> boundary) {
  final record = _productSpecPinRecord(boundary);
  if (record == null) return null;
  final path = record['path'];
  return path is String && path.trim().isNotEmpty ? path : null;
}

/// The sha256 115.4 pins for the external product spec.
String _productSpecPinFrom(Map<String, dynamic> boundary) {
  final record = _productSpecPinRecord(boundary);
  if (record == null) return '';
  final sha = record['sha256'];
  return sha is String ? sha : '';
}

/// The sha256 the drill or the anchor computes over that same file.
String _productSpecActualSha(Map<String, dynamic> boundary) {
  final path = _productSpecPinPathFrom(boundary);
  if (path == null) return '';
  final file = File(path);
  if (!file.existsSync()) return '';
  return sha256.convert(file.readAsBytesSync()).toString();
}

/// Reads the external product spec through the committed pin. A path outside
/// the repository is only ever read, never written.
_SpecFile? _readProductSpec() {
  final boundary = _readJsonFile(
    Sprint117GlobalScopeContract.workspaceBoundary,
  );
  if (boundary == null) return null;
  final path = _productSpecPinPathFrom(boundary);
  if (path == null) return null;
  final file = File(path);
  if (!file.existsSync()) return null;
  final Object? decoded;
  try {
    decoded = jsonDecode(file.readAsStringSync());
  } on FormatException {
    return null;
  }
  if (decoded is! Map<String, dynamic>) return null;
  return _SpecFile(rawPath: path, json: decoded);
}

/// Reads a committed JSON object, or null when it is absent or malformed.
Map<String, dynamic>? _readJsonFile(String path) {
  final file = File(path);
  if (!file.existsSync()) return null;
  final Object? decoded;
  try {
    decoded = jsonDecode(file.readAsStringSync());
  } on FormatException {
    return null;
  }
  if (decoded is! Map<String, dynamic>) return null;
  return decoded;
}

/// Reads a shipped source file as text, or null when it is absent.
String? _readSource(String relativePath) {
  final file = File(relativePath);
  if (!file.existsSync()) return null;
  return file.readAsStringSync();
}

/// The block the legacy-route marker opens, bounded so a scan cannot wander.
String? _legacyRedirectBlock(String routerSource) {
  const marker = 'path: AppRoutes.accountCloudLegacy,';
  final start = routerSource.indexOf(marker);
  if (start < 0) return null;
  final end = start + 600 > routerSource.length
      ? routerSource.length
      : start + 600;
  final block = routerSource.substring(start, end);
  if (!block.contains('redirect:')) return null;
  if (!block.contains('AppRoutes.accountCloud')) return null;
  if (!block.contains('state.uri.query')) return null;
  return block;
}

/// The body of the class declaration starting with [header], up to the next
/// class declaration.
String? _classBody(String source, String header) {
  final start = source.indexOf(header);
  if (start < 0) return null;
  final rest = source.substring(start + header.length);
  final next = RegExp(r'\nclass ').firstMatch(rest);
  return next == null ? rest : rest.substring(0, next.start);
}

/// The `final` field names declared by `class AccountCloudSnapshot`.
List<String> _finalFieldNames(String source) {
  final body = _classBody(source, 'class AccountCloudSnapshot {');
  if (body == null) return const <String>[];
  final names = <String>[
    for (final match in RegExp(
      r'^\s*final\s+[A-Za-z0-9_<>,?\s]+\s+([a-zA-Z0-9_]+);',
      multiLine: true,
    ).allMatches(body))
      match.group(1)!,
  ];
  return names..sort();
}

/// The values the shipped `_AccountMenu` really offers, sorted.
List<String> _accountMenuValues(String source) {
  final body = _classBody(source, 'class _AccountMenu ');
  if (body == null) return const <String>[];
  final values = <String>{
    for (final match in RegExp(
      r"PopupMenuItem\(value: '([^']+)'",
    ).allMatches(body))
      match.group(1)!,
  };
  return values.toList(growable: false)..sort();
}

/// Workspace namespace tokens a serialized surface carries.
List<String> _namespaceHits(String payload) {
  final hits = <String>[];
  for (final token in <String>[
    AccountCenterWorkspaceBoundaryContract.novelWorkspaceDataNamespace,
    AccountCenterWorkspaceBoundaryContract.characterWorkspaceDataNamespace,
  ]) {
    if (payload.contains(token)) hits.add(token);
  }
  return hits;
}

/// The `shows` entries the product spec declares for the profile surface.
List<String> _declaredProfileShows(_SpecFile? spec) {
  if (spec == null) return const <String>[];
  final placement = spec.json['placement'];
  if (placement is! Map<String, dynamic>) return const <String>[];
  final profile = placement['profile_surface'];
  if (profile is! Map<String, dynamic>) return const <String>[];
  return _stringList(profile['shows'] ?? const <dynamic>[]);
}

/// The declared role of the product spec's profile surface.
String? _profileSurfaceRole(_SpecFile? spec) {
  if (spec == null) return null;
  final placement = spec.json['placement'];
  if (placement is! Map<String, dynamic>) return null;
  final profile = placement['profile_surface'];
  if (profile is! Map<String, dynamic>) return null;
  final role = profile['role'];
  return role is String ? role : null;
}

/// Coerces a JSON list of scalars into a list of strings.
List<String> _stringList(List<dynamic> raw) => <String>[
  for (final value in raw)
    if (value is String) value,
];

/// The path of [child] relative to [root], with forward slashes.
String _relativeInside(String root, String child) {
  final normalizedRoot = root.replaceAll(r'\', '/');
  final normalizedChild = child.replaceAll(r'\', '/');
  if (normalizedChild.startsWith('$normalizedRoot/')) {
    return normalizedChild.substring(normalizedRoot.length + 1);
  }
  return normalizedChild;
}

/// Every `.dart` file under [directory] that contains any of [needles].
List<String> _filesContaining(String directory, List<String> needles) {
  final root = Directory(directory);
  if (!root.existsSync()) return const <String>[];
  final hits = <String>[];
  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final source = entity.readAsStringSync();
    if (needles.any(source.contains)) {
      hits.add(entity.path.replaceAll(r'\', '/'));
    }
  }
  return hits..sort();
}

/// How many shipped `lib/` files call [symbol], excluding the contract that
/// declares it and this validation that measures it.
///
/// A gate nobody calls is a gate that has never been crossed, which is a
/// different fact from a gate that failed — the count keeps them apart.
int _callSites(String symbol) {
  final pattern = RegExp(RegExp.escape(symbol) + r'\s*\(');
  final lib = Directory('lib');
  if (!lib.existsSync()) return -1;
  var count = 0;
  for (final entity in lib.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll(r'\', '/');
    // The contract that declares the symbol and this validation that measures
    // it are not callers — only shipped code outside both counts.
    if (path.contains('account_center_workspace_boundary_contract.dart')) {
      continue;
    }
    if (path.contains('sprint_117_global_scope')) continue;
    // Any other step's acceptance drill or validation harness in this
    // directory is equally not a shipped caller. Excluding only this step's
    // own family made the count depend on which sibling steps happened to be
    // present in the tree: adding 117.14's drill, which legitimately calls
    // the same boundary contracts, silently reported a production caller that
    // does not exist. No `sprint_117_*` file is reachable from main.dart, so
    // none of them is production wiring; the count now means what its
    // doc comment claims.
    if (path.contains('sprint_117_')) continue;
    if (pattern.hasMatch(entity.readAsStringSync())) count += 1;
  }
  return count;
}
