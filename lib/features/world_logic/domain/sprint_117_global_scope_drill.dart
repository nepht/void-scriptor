part of 'sprint_117_global_scope_workspace_boundary_validation.dart';

/// Executes the shipped global-scope and workspace-boundary mechanisms and
/// records what each one produced. It writes nothing — no manifest, no
/// report, no user file — and it never touches a live install.
class Sprint117GlobalScopeDrill {
  const Sprint117GlobalScopeDrill();

  /// Runs every canonical check against the repository as it stands.
  Future<Sprint117GlobalScopeDrillRun> run() async {
    final boundaryManifest = _readJsonFile(
      Sprint117GlobalScopeContract.workspaceBoundary,
    );
    final pin = boundaryManifest == null
        ? ''
        : _productSpecPinFrom(boundaryManifest);
    final actual = boundaryManifest == null
        ? ''
        : _productSpecActualSha(boundaryManifest);
    return Sprint117GlobalScopeDrillRun(
      observations: <Sprint117GlobalScopeObservation>[
        _observeGlobalRoute(),
        _observeProfileSummaryOnly(),
        _observePermission(
          checkId: 'novel_permission',
          target: AccountCenterDataScope.novelWorkspace,
        ),
        _observePermission(
          checkId: 'character_permission',
          target: AccountCenterDataScope.characterWorkspace,
        ),
        _observeTransferConsent(),
        _observeNoCrossWorkspaceLeak(),
      ],
      liveInstallTouched: false,
      userProjectTouched: false,
      productSpecPinnedSha256: pin,
      productSpecActualSha256: actual,
    );
  }

  /// `global_route` — the canonical route must match the 115.3 manifest,
  /// classify as a global surface through the shipped boundary contract, be
  /// registered in the shipped router with a query-preserving legacy
  /// redirect, and carry the profile shortcut through the navigation
  /// registry.
  Sprint117GlobalScopeObservation _observeGlobalRoute() {
    final ia = _readJsonFile(
      Sprint117GlobalScopeContract.informationArchitecture,
    );
    final router = _readSource(Sprint117GlobalScopeContract.routerSource);

    final globalRoute = ia == null
        ? null
        : _nestedString(ia, const <String>['global_route', 'canonical']);
    final legacyAlias = ia == null
        ? null
        : _nestedString(ia, const <String>['global_route', 'legacy_alias']);
    final declaredScope = ia == null
        ? null
        : _nestedString(ia, const <String>['global_route', 'scope']);
    final shortcutKey = ia == null
        ? null
        : _nestedString(ia, const <String>[
            'profile_shortcut',
            'navigation_key',
          ]);
    final shortcutRoute = ia == null
        ? null
        : _nestedString(ia, const <String>['profile_shortcut', 'route']);

    final legacyBlock = router == null ? null : _legacyRedirectBlock(router);
    final routerRegistersCanonical =
        router != null && router.contains('path: AppRoutes.accountCloud,');
    final manifestMatchesShipped =
        globalRoute == AppRoutes.accountCloud &&
        legacyAlias == AppRoutes.accountCloudLegacy &&
        declaredScope == AccountCenterWorkspaceBoundaryContract.scope;

    // The contract itself must classify the canonical route as global and
    // reject workspace, studio, and relative routes (fail closed).
    final classifiedGlobal =
        AccountCenterWorkspaceBoundaryContract.isGlobalSurfaceRoute(
          AppRoutes.accountCloud,
        );
    final workspaceRoutesRejected =
        !AccountCenterWorkspaceBoundaryContract.isGlobalSurfaceRoute(
          AppRoutes.workspace,
        ) &&
        !AccountCenterWorkspaceBoundaryContract.isGlobalSurfaceRoute(
          AppRoutes.studioProject,
        ) &&
        !AccountCenterWorkspaceBoundaryContract.isGlobalSurfaceRoute(
          'relative/path',
        );

    final navEntries = _allNavigationDestinations();
    final shortcutDeclared =
        shortcutKey != null &&
        shortcutRoute == AppRoutes.accountCloud &&
        navEntries.any(
          (entry) =>
              entry.key == shortcutKey && entry.route == AppRoutes.accountCloud,
        );

    final passed =
        manifestMatchesShipped &&
        declaredScope == 'GLOBAL_USER' &&
        classifiedGlobal &&
        workspaceRoutesRejected &&
        routerRegistersCanonical &&
        legacyBlock != null &&
        shortcutDeclared;

    return Sprint117GlobalScopeObservation(
      checkId: 'global_route',
      outcome: passed
          ? 'GLOBAL_ROUTE_RESOLVES_OUTSIDE_WORKSPACE_PREFIXES'
          : 'GLOBAL_ROUTE_NOT_GLOBAL',
      facts: <String, Object?>{
        'shipped_route': AppRoutes.accountCloud,
        'manifest_canonical_route': globalRoute,
        'shipped_legacy_route': AppRoutes.accountCloudLegacy,
        'manifest_legacy_alias': legacyAlias,
        'declared_scope': declaredScope,
        'classified_global_by_contract': classifiedGlobal,
        'workspace_and_relative_routes_rejected': workspaceRoutesRejected,
        'router_registers_canonical_route': routerRegistersCanonical,
        'router_legacy_redirect_preserves_query': legacyBlock != null,
        'navigation_shortcut_key': shortcutKey,
        'navigation_shortcut_declared': shortcutDeclared,
        'navigation_entry_count': navEntries.length,
      },
      passed: passed,
      acceptance: passed
          ? Sprint117GlobalScopeAcceptance.satisfied
          : Sprint117GlobalScopeAcceptance.mechanismAbsent,
      unresolvable: const <String>[],
    );
  }

  /// `profile_summary_only` — the shipped summary surface must resolve every
  /// `shows` entry the product spec declares, the profile menu must carry the
  /// 115.3 shortcut key, and neither the surface nor a freshly built snapshot
  /// may carry workspace payloads.
  Sprint117GlobalScopeObservation _observeProfileSummaryOnly() {
    final spec = _readProductSpec();
    final alpha = _readJsonFile(Sprint117GlobalScopeContract.alphaAcceptance);
    final ia = _readJsonFile(
      Sprint117GlobalScopeContract.informationArchitecture,
    );
    final surfaceSource = _readSource(
      Sprint117GlobalScopeContract.summarySurfaceSource,
    );
    final menuSource = _readSource(
      Sprint117GlobalScopeContract.accountMenuSource,
    );

    final snapshot = AccountCloudSnapshot.localOnly(session: null);
    final menuValues = menuSource == null
        ? const <String>[]
        : _accountMenuValues(menuSource);
    final declaredShows = _declaredProfileShows(spec);
    final declaredRole = _profileSurfaceRole(spec);
    final invariants = spec == null
        ? const <String>[]
        : <String>[
            for (final value
                in (spec.json['acceptance_invariants'] ?? const <dynamic>[]))
              if (value is String) value,
          ];
    final invariantCovered = invariants.contains(
      'profile_contains_summary_and_shortcut_only',
    );
    final alphaHeld =
        alpha != null &&
        Sprint117GlobalScopeLoader._alphaCheckHeld(
          alpha,
          'invariant_2_profile_summary_covered',
        );
    final shortcutKey = ia == null
        ? null
        : _nestedString(ia, const <String>[
            'profile_shortcut',
            'navigation_key',
          ]);
    final navDeclared =
        shortcutKey != null &&
        _allNavigationDestinations().any(
          (entry) =>
              entry.key == shortcutKey && entry.route == AppRoutes.accountCloud,
        );
    final menuCarriesShortcut =
        shortcutKey != null && menuValues.contains(shortcutKey);

    final resolved = <String, String>{};
    final unresolved = <String>[];
    for (final show in declaredShows) {
      final owner = _resolveProfileShow(
        show,
        surfaceSource: surfaceSource,
        navKeyRegistered: navDeclared,
        menuCarriesShortcut: menuCarriesShortcut,
      );
      if (owner == null) {
        unresolved.add(show);
      } else {
        resolved[show] = owner;
      }
    }

    final modelFields = _readSource(
      Sprint117GlobalScopeContract.summaryModelSource,
    );
    final snapshotFields = modelFields == null
        ? const <String>[]
        : _finalFieldNames(modelFields);
    final snapshotFieldsSummaryOnly =
        snapshotFields.isNotEmpty &&
        snapshotFields.every(
          (field) =>
              _namespaceHits(field).isEmpty &&
              !field.toLowerCase().contains('workspace'),
        );

    final surfaceNamespaceHits = surfaceSource == null
        ? const <String>['surface_source_absent']
        : _namespaceHits(surfaceSource);
    final snapshotStrings = <String>[
      snapshot.accountModeLabel,
      snapshot.accountDisplayName,
      snapshot.accountEmail ?? '',
      for (final service in snapshot.services) ...<String>[
        service.id,
        service.label,
        service.description,
        service.usageLabel ?? '',
      ],
    ].join('\n');
    final snapshotNamespaceHits = _namespaceHits(snapshotStrings);

    final passed =
        spec != null &&
        declaredRole == Sprint117GlobalScopeContract.profileSurfaceRole &&
        declaredShows.isNotEmpty &&
        invariantCovered &&
        alphaHeld &&
        menuCarriesShortcut &&
        navDeclared &&
        unresolved.isEmpty &&
        surfaceNamespaceHits.isEmpty &&
        snapshotNamespaceHits.isEmpty &&
        snapshot.services.isNotEmpty &&
        snapshotFieldsSummaryOnly &&
        snapshot.accountDisplayName.trim().isNotEmpty;

    return Sprint117GlobalScopeObservation(
      checkId: 'profile_summary_only',
      outcome: passed
          ? 'PROFILE_SURFACE_SUMMARY_AND_SHORTCUT_ONLY'
          : 'PROFILE_SURFACE_NOT_SUMMARY_ONLY',
      facts: <String, Object?>{
        'declared_role': declaredRole,
        'declared_shows': declaredShows,
        'resolved_shows': resolved,
        'unresolved_shows': unresolved,
        'spec_invariant_2_covered': invariantCovered,
        'alpha_bucket_invariant_2_held': alphaHeld,
        'profile_menu_values': menuValues,
        'shortcut_key': shortcutKey,
        'menu_carries_shortcut': menuCarriesShortcut,
        'navigation_shortcut_declared': navDeclared,
        'snapshot_account_mode': snapshot.accountModeLabel,
        'snapshot_display_name': snapshot.accountDisplayName,
        'snapshot_service_count': snapshot.services.length,
        'surface_namespace_tokens': surfaceNamespaceHits,
        'snapshot_namespace_tokens': snapshotNamespaceHits,
        'snapshot_model_fields': snapshotFields,
        'snapshot_model_fields_summary_only': snapshotFieldsSummaryOnly,
        'product_spec_present': spec != null,
      },
      passed: passed,
      acceptance: passed
          ? Sprint117GlobalScopeAcceptance.satisfied
          : Sprint117GlobalScopeAcceptance.mechanismAbsent,
      unresolvable: const <String>[],
    );
  }

  /// Resolves one declared profile show through shipped sources, or null.
  String? _resolveProfileShow(
    String show, {
    required String? surfaceSource,
    required bool navKeyRegistered,
    required bool menuCarriesShortcut,
  }) {
    if (show == 'open_account_cloud_center_action') {
      return navKeyRegistered && menuCarriesShortcut
          ? 'navigation_and_menu_action'
          : null;
    }
    if (surfaceSource == null) return null;
    const tokens = <String, List<String>>{
      'avatar': <String>['ProfileAvatar'],
      'display_name': <String>['displayName', 'accountDisplayName'],
      'plan': <String>['_PlanBadge', 'AccountPlan', '_planFrom'],
      'connection_health': <String>[
        'providerHealthLabel',
        'connection_health',
        'Connection health',
      ],
      'remote_storage_summary': <String>[
        '_StorageDistributionCard',
        'remote_storage_summary',
        'Remote storage',
      ],
      'security_summary': <String>['security_summary', 'SECURITY CENTER'],
    };
    for (final token in tokens[show] ?? const <String>[]) {
      if (surfaceSource.contains(token)) return 'surface_token:$token';
    }
    if (surfaceSource.contains(show)) return 'surface_literal';
    return null;
  }

  /// `novel_permission` / `character_permission` — the contract gate must deny
  /// workspace access without explicit permission and allow it with it, and
  /// the shipped WorkspacePermissionPolicy must refuse projection reads and
  /// character-canon writes that lack the required link/API/ownership.
  Sprint117GlobalScopeObservation _observePermission({
    required String checkId,
    required AccountCenterDataScope target,
  }) {
    final denied =
        AccountCenterWorkspaceBoundaryContract.resolveWorkspaceAccess(
          target: target,
          hasExplicitWorkspacePermission: false,
        );
    final allowed =
        AccountCenterWorkspaceBoundaryContract.resolveWorkspaceAccess(
          target: target,
          hasExplicitWorkspacePermission: true,
        );
    final globalAlwaysAllowed =
        AccountCenterWorkspaceBoundaryContract.resolveWorkspaceAccess(
          target: AccountCenterDataScope.globalUser,
          hasExplicitWorkspacePermission: false,
        );

    const policy = WorkspacePermissionPolicy();
    const owner = WorkspaceAccess(isLocalProjectOwner: true);
    final projectionWithoutLink = policy.canReadCharacterProjection(
      access: const WorkspaceAccess(),
      novelWorkspaceId: 'ws-novel-1',
      characterWorkspaceId: 'ws-char-1',
      hasExplicitLink: false,
    );
    final projectionWithOwnerAndLink = policy.canReadCharacterProjection(
      access: owner,
      novelWorkspaceId: 'ws-novel-1',
      characterWorkspaceId: 'ws-char-1',
      hasExplicitLink: true,
    );
    final writeWithoutOwnerApi = policy.canWriteCharacterCanon(
      access: owner,
      novelWorkspaceId: 'ws-novel-1',
      characterWorkspaceId: 'ws-char-1',
      throughCharacterOwnerApi: false,
    );
    final writeWithOwnerApi = policy.canWriteCharacterCanon(
      access: owner,
      novelWorkspaceId: 'ws-novel-1',
      characterWorkspaceId: 'ws-char-1',
      throughCharacterOwnerApi: true,
    );
    final privateFieldsWithoutGrant = policy.canReadPrivateCharacterFields(
      access: const WorkspaceAccess(),
      characterWorkspaceId: 'ws-char-1',
    );

    final contractGateHolds =
        denied == WorkspaceBoundaryDecision.deniedWorkspacePermissionRequired &&
        allowed == WorkspaceBoundaryDecision.allowedWorkspaceScoped &&
        globalAlwaysAllowed == WorkspaceBoundaryDecision.allowedGlobalScope;
    final policyGateHolds =
        !projectionWithoutLink &&
        projectionWithOwnerAndLink &&
        !writeWithoutOwnerApi &&
        writeWithOwnerApi &&
        !privateFieldsWithoutGrant;
    final passed = contractGateHolds && policyGateHolds;

    final contractCallSites = _callSites('resolveWorkspaceAccess');
    final policyCallSites = _callSites('canReadCharacterProjection');

    return Sprint117GlobalScopeObservation(
      checkId: checkId,
      outcome: passed
          ? 'ACCESS_DENIED_WITHOUT_PERMISSION_ALLOWED_WITH_IT'
          : 'ACCESS_NOT_GATED_BY_PERMISSION',
      facts: <String, Object?>{
        'target_scope': target.name,
        'denied_decision': denied.id,
        'allowed_decision': allowed.id,
        'global_without_permission_decision': globalAlwaysAllowed.id,
        'projection_read_without_link': projectionWithoutLink,
        'projection_read_with_owner_and_link': projectionWithOwnerAndLink,
        'canon_write_without_owner_api': writeWithoutOwnerApi,
        'canon_write_with_owner_api': writeWithOwnerApi,
        'private_fields_without_grant': privateFieldsWithoutGrant,
        'resolve_workspace_access_call_sites': contractCallSites,
        'can_read_character_projection_call_sites': policyCallSites,
        'mechanism': 'resolveWorkspaceAccess + WorkspacePermissionPolicy',
      },
      passed: passed,
      acceptance: passed
          ? Sprint117GlobalScopeAcceptance.satisfied
          : Sprint117GlobalScopeAcceptance.mechanismAbsent,
      // The gates are defined and drilled, but only shipped callers outside
      // the contract prove production wiring — that count is a fact.
      unresolvable: contractCallSites == 0
          ? const <String>['resolve_workspace_access_caller_absent']
          : const <String>[],
    );
  }

  /// `transfer_consent` — all 18 scope-pair/consent decisions must resolve
  /// through the shipped gate: global to global allowed, workspace-touching
  /// pairs denied without consent, allowed with it.
  Sprint117GlobalScopeObservation _observeTransferConsent() {
    const scopes = <AccountCenterDataScope>[
      AccountCenterDataScope.globalUser,
      AccountCenterDataScope.novelWorkspace,
      AccountCenterDataScope.characterWorkspace,
    ];
    const consents = <bool>[false, true];
    final outcomes = <String, String>{};
    var total = 0;
    var mismatches = 0;

    for (final source in scopes) {
      for (final destination in scopes) {
        for (final consent in consents) {
          total += 1;
          final decision =
              AccountCenterWorkspaceBoundaryContract.resolveTransfer(
                source: source,
                destination: destination,
                hasExplicitTransferConsent: consent,
              );
          final key = '${source.name}->${destination.name}:consent=$consent';
          outcomes[key] = decision.id;

          // Expected outcome derived from the contract's documented rule:
          // global -> global never needs consent, every other pair does.
          final bothGlobal =
              source == AccountCenterDataScope.globalUser &&
              destination == AccountCenterDataScope.globalUser;
          final expectedDecision = (bothGlobal || consent)
              ? (bothGlobal
                    ? WorkspaceBoundaryDecision.allowedGlobalScope
                    : WorkspaceBoundaryDecision.allowedWorkspaceScoped)
              : WorkspaceBoundaryDecision.deniedTransferConsentRequired;
          if (decision != expectedDecision) mismatches += 1;
        }
      }
    }

    final callSites = _callSites('resolveTransfer');
    final passed = mismatches == 0 && total == 18;

    return Sprint117GlobalScopeObservation(
      checkId: 'transfer_consent',
      outcome: passed
          ? 'GLOBAL_TO_GLOBAL_ALLOWED_WORKSPACE_PAIRS_REQUIRE_CONSENT'
          : 'TRANSFER_GATE_CONTRADICTS_CONSENT_RULE',
      facts: <String, Object?>{
        'decisions_resolved': total,
        'expected_decisions': 18,
        'mismatches': mismatches,
        'outcomes': outcomes,
        'resolve_transfer_call_sites': callSites,
        'mechanism': 'AccountCenterWorkspaceBoundaryContract.resolveTransfer',
      },
      passed: passed,
      acceptance: passed
          ? Sprint117GlobalScopeAcceptance.satisfied
          : Sprint117GlobalScopeAcceptance.mechanismAbsent,
      unresolvable: callSites == 0
          ? const <String>['resolve_transfer_caller_absent']
          : const <String>[],
    );
  }

  /// `no_cross_workspace_leak` — the shipped namespace must equal the
  /// contract namespaces, path traversal must be rejected, the backup
  /// validator must flag every documented violation class, and no other
  /// account surface may carry a workspace payload.
  Sprint117GlobalScopeObservation _observeNoCrossWorkspaceLeak() {
    final package = ProjectPackage(
      projectId: 'sprint-117-global-scope-drill',
      root: Directory(
        _joinPath('C:/void-scriptor-sprint-117', 'drill-package'),
      ),
    );
    final namespace = WorkspaceFileNamespace(package);
    final novelRelative = _relativeInside(
      package.root.path,
      namespace.novelRoot.path,
    );
    final characterRelative = _relativeInside(
      package.root.path,
      namespace.characterRoot.path,
    );
    final namespacesMatch =
        novelRelative ==
            AccountCenterWorkspaceBoundaryContract
                .novelWorkspaceDataNamespace &&
        characterRelative ==
            AccountCenterWorkspaceBoundaryContract
                .characterWorkspaceDataNamespace;

    // Real traversal rejection: escaping paths must throw.
    var traversalRejected = false;
    try {
      namespace.novelFile('ws-novel-1', '../../escape.txt');
    } on ArgumentError {
      traversalRejected = true;
    }

    final violationResults = <String, List<String>>{
      'account_global_holds_novel_data':
          AccountCenterWorkspaceBoundaryContract.backupBoundaryViolations(
            boundary: AccountBackupBoundary.accountGlobal,
            relativePaths: const <String>[
              'workspaces/novels/novel-1/chapter.md',
            ],
          ),
      'novel_boundary_holds_character_data':
          AccountCenterWorkspaceBoundaryContract.backupBoundaryViolations(
            boundary: AccountBackupBoundary.novelWorkspace,
            relativePaths: const <String>[
              'workspaces/characters/char-1/x.json',
            ],
          ),
      'character_boundary_holds_novel_data':
          AccountCenterWorkspaceBoundaryContract.backupBoundaryViolations(
            boundary: AccountBackupBoundary.characterWorkspace,
            relativePaths: const <String>['workspaces/novels/novel-1/x.json'],
          ),
      'account_global_clean':
          AccountCenterWorkspaceBoundaryContract.backupBoundaryViolations(
            boundary: AccountBackupBoundary.accountGlobal,
            relativePaths: const <String>['database/project.db'],
          ),
      'novel_boundary_clean':
          AccountCenterWorkspaceBoundaryContract.backupBoundaryViolations(
            boundary: AccountBackupBoundary.novelWorkspace,
            relativePaths: const <String>['workspaces/novels/novel-1/notes.md'],
          ),
    };
    final violationsBehave =
        violationResults['account_global_holds_novel_data']!.contains(
          'ACCOUNT_GLOBAL_MUST_NOT_HOLD_WORKSPACE_DATA',
        ) &&
        violationResults['novel_boundary_holds_character_data']!.contains(
          'NOVEL_WORKSPACE_BOUNDARY_MUST_NOT_HOLD_CHARACTER_DATA',
        ) &&
        violationResults['character_boundary_holds_novel_data']!.contains(
          'CHARACTER_WORKSPACE_BOUNDARY_MUST_NOT_HOLD_NOVEL_DATA',
        ) &&
        violationResults['account_global_clean']!.isEmpty &&
        violationResults['novel_boundary_clean']!.isEmpty;

    // Any account surface other than the contract that declares them must
    // not carry workspace namespace payloads.
    final accountSurfaceFiles =
        _filesContaining('lib/features/account', <String>[
          AccountCenterWorkspaceBoundaryContract.novelWorkspaceDataNamespace,
          AccountCenterWorkspaceBoundaryContract
              .characterWorkspaceDataNamespace,
        ]).where(
          (path) =>
              !path.endsWith('account_center_workspace_boundary_contract.dart'),
        );

    final callSites = _callSites('backupBoundaryViolations');
    final passed =
        namespacesMatch &&
        traversalRejected &&
        violationsBehave &&
        accountSurfaceFiles.isEmpty;

    return Sprint117GlobalScopeObservation(
      checkId: 'no_cross_workspace_leak',
      outcome: passed
          ? 'NAMESPACES_MATCH_AND_ACCOUNT_SURFACES_CARRY_NO_WORKSPACE_PAYLOAD'
          : 'WORKSPACE_BOUNDARY_NOT_SEPARATED',
      facts: <String, Object?>{
        'novel_root_relative': novelRelative,
        'character_root_relative': characterRelative,
        'namespaces_match_contract': namespacesMatch,
        'path_traversal_rejected': traversalRejected,
        'backup_violation_results': violationResults,
        'backup_violations_behave_as_documented': violationsBehave,
        'account_surface_files_with_namespace': accountSurfaceFiles.toList(),
        'backup_boundary_violations_call_sites': callSites,
        'mechanism': 'WorkspaceFileNamespace + backupBoundaryViolations',
      },
      passed: passed,
      acceptance: passed
          ? Sprint117GlobalScopeAcceptance.satisfied
          : Sprint117GlobalScopeAcceptance.mechanismAbsent,
      unresolvable: callSites == 0
          ? const <String>['backup_boundary_violations_caller_absent']
          : const <String>[],
    );
  }
}

/// Joins path segments with forward slashes without another dependency.
String _joinPath(String a, String b) => '$a/$b';

/// Every navigation destination the shipped registry offers, across core,
/// mobile, and optional lists.
List<AppNavigationDestination> _allNavigationDestinations() =>
    <AppNavigationDestination>[
      ...coreNavigationDestinations,
      ...mobilePrimaryDestinations,
      ...optionalNavigationDestinations,
    ];

/// Reads a nested string field by key path, or null when any level is absent.
String? _nestedString(Map<String, dynamic> source, List<String> keys) {
  Object? current = source;
  for (final key in keys) {
    if (current is! Map<String, dynamic>) return null;
    current = current[key];
  }
  return current is String ? current : null;
}
