part of 'sprint_117_creative_connector_workflow_validation.dart';

/// Executes the shipped creative connector mechanisms and records what each one
/// produced. It writes nothing, opens no user project, contacts no provider,
/// and every provider it names is a locally built manifest entry, so nothing
/// here can be read as a certification or a live availability claim.
class Sprint117CreativeConnectorWorkflowDrill {
  const Sprint117CreativeConnectorWorkflowDrill();

  /// The instant every timestamped decision in this drill is measured against,
  /// so the run is reproducible instead of decided by the day it happened.
  static final DateTime fixedNow = DateTime.utc(2026, 1, 1, 12);

  /// Source files that hold the shipped creative connector mechanisms. A check
  /// whose behaviour only these files exercise is the mechanism existing, not
  /// the feature being reachable by a user.
  static const List<String> shippedSources = <String>[
    'lib/features/account/domain/account_center_creative_tools_connections.dart',
    'lib/features/account/domain/account_center_provider_connector_manifest.dart',
  ];

  /// Whether [source] still declares [symbol], i.e. whether the mechanism this
  /// check exercises exists at all.
  ///
  /// Measured rather than assumed so that renaming or deleting the shipped
  /// method makes the fact false instead of leaving a constant `true` behind.
  /// A constant would make the acceptance look decided by something that never
  /// ran, which is the defect 117.16 rejected in this harness family.
  static bool _declares(String source, String symbol) {
    final file = File(source);
    if (!file.existsSync()) return false;
    return file.readAsLinesSync().any((line) => line.contains(symbol));
  }

  /// Counts production call sites that reach [source] under `lib/`.
  ///
  /// Separate from [_declares] on purpose: a declared mechanism that nothing
  /// calls satisfies the acceptance in the abstract but not for a user, and
  /// the two facts must not be collapsed into one. The harness family is
  /// excluded wholesale because no `sprint_117_*` file is reachable from
  /// `main.dart` — without that exclusion an acceptance drill counts itself as
  /// the production caller it was supposed to measure.
  static int _productionCallSites(String source) {
    final stem = source.split('/').last;
    final found = <String>[];
    for (final entity in Directory.current.listSync(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;
      final path = entity.path.replaceAll('\\', '/');
      if (!path.startsWith('lib/') || !path.endsWith('.dart')) continue;
      if (path.contains('/sprint_117_')) continue;
      if (path == source) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i += 1) {
        if (lines[i].contains(stem)) {
          found.add('$path:${i + 1}');
          break;
        }
      }
    }
    return found.length;
  }

  /// Counts production files that read a creative transfer scope, excluding the
  /// manager that stores it.
  ///
  /// A boundary that is only ever written down is not a boundary. This is
  /// measured rather than assumed, because a `true` constant here would turn
  /// "the declared scope is enforced" into a claim nothing looked for — the
  /// same false zero 117.17 hit when a symbol search returned nothing for the
  /// wrong reason.
  static int _transferScopeReadCallSites() {
    final source = shippedSources.first;
    final stem = source.split('/').last;
    final found = <String>[];
    for (final entity in Directory.current.listSync(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;
      final path = entity.path.replaceAll('\\', '/');
      if (!path.startsWith('lib/') || !path.endsWith('.dart')) continue;
      if (path.contains('/sprint_117_')) continue;
      if (path == source) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i += 1) {
        // A read is a use of the value, not merely a mention of the file that
        // declares it; `.transferScope` is what an enforcing caller would
        // have to look at.
        if (lines[i].contains('.transferScope') ||
            (lines[i].contains(stem) && lines[i].contains('transferScope'))) {
          found.add('$path:${i + 1}');
          break;
        }
      }
    }
    return found.length;
  }

  /// Whether the shipped connection class exposes a setter for [field].
  ///
  /// Read off the source rather than inferred, so a future `transferScope =`
  /// added to the seam makes the immutability fact false instead of leaving a
  /// `true` that nothing checked.
  static bool _hasSetter(String field) {
    final file = File(shippedSources.first);
    if (!file.existsSync()) return false;
    final pattern = RegExp(
      r'(?:^|\s)(?:late\s+)?(?:CreativeTransferScope\s+)?'
      r'${RegExp.escape(field)}\s*=',
    );
    return file.readAsLinesSync().any((line) => pattern.hasMatch(line));
  }

  /// Per shipped source: does it declare the mechanism this check exercises.
  static final Map<String, bool> _mechanismPresent = <String, bool>{
    'creative.connect': _declares(shippedSources.first, 'connect('),
    'creative.permissions': _declares(
      shippedSources.first,
      '_validateAssetPermissions',
    ),
    'creative.attribution': _declares(
      shippedSources.first,
      'Licensed assets require attribution metadata',
    ),
    'creative.transferScope': _declares(
      shippedSources.first,
      'this.transferScope',
    ),
    'creative.disconnect': _declares(shippedSources.first, 'disconnect('),
    'creative.gate': _declares(shippedSources.first, '_reauthenticate'),
    'creative.audit': _declares(shippedSources.first, 'denied_disconnect'),
    'manifest.category': _declares(
      shippedSources[1],
      'ProviderConnectorCategory.creative',
    ),
  };

  /// Whether any production file outside the acceptance harness imports the
  /// creative connector manager this slice validates.
  static final bool _productionCallerPresent =
      _productionCallSites(shippedSources.first) > 0;

  /// Whether any shipped file reads a creative transfer scope to decide a
  /// transfer. Measured, not assumed.
  static final bool _transferScopeEnforcedSomewhere =
      _transferScopeReadCallSites() > 0;

  /// Runs every canonical check against the repository as it stands.
  Future<Sprint117CreativeConnectorWorkflowDrillRun> run() async {
    var matched = 0;
    var checked = 0;
    for (final entry
        in Sprint117CreativeConnectorWorkflowContract.externalPins.entries) {
      final actual = _sha256OfFile(entry.key);
      if (actual == null) continue;
      checked += 1;
      if (actual == entry.value) matched += 1;
    }
    return Sprint117CreativeConnectorWorkflowDrillRun(
      observations: <Sprint117CreativeConnectorWorkflowObservation>[
        await _observeAssetAccess(),
        _observeRights(),
        await _observeAttribution(),
        await _observeImport(),
        await _observeExport(),
        await _observeRevoke(),
      ],
      liveProviderTouched: false,
      userProjectTouched: false,
      liveCredentialObserved: false,
      externalPinsMatched: matched,
      externalPinsChecked: checked,
      productionCallerPresent: _productionCallerPresent,
      transferScopeEnforcedSomewhere: _transferScopeEnforcedSomewhere,
    );
  }

  /// A provider manifest built here, never the production availability claim.
  ///
  /// `ProviderConnectorManifest.standard` records every creative connector as
  /// UNVERIFIED, so connecting against it is impossible by design. The drill
  /// needs a connectable entry to exercise the mechanisms at all, so it builds
  /// one locally and says so, instead of promoting a real provider to
  /// AVAILABLE to make a test pass.
  static ProviderConnectorManifest _manifest() =>
      ProviderConnectorManifest(<ProviderConnectorEntry>[
        ProviderConnectorEntry.fixture(
          'figma',
          category: ProviderConnectorCategory.creative,
          capabilities: const <ProviderConnectorCapability>{
            ProviderConnectorCapability.creative,
          },
          availability: ProviderConnectorAvailability.available,
        ),
        ProviderConnectorEntry.fixture(
          'canva',
          category: ProviderConnectorCategory.creative,
          capabilities: const <ProviderConnectorCapability>{
            ProviderConnectorCapability.creative,
          },
          availability: ProviderConnectorAvailability.unverified,
        ),
        // A developer connector is present so the creative filter can be shown
        // to exclude it rather than merely happen to.
        ProviderConnectorEntry.fixture(
          'github',
          category: ProviderConnectorCategory.developer,
          capabilities: const <ProviderConnectorCapability>{
            ProviderConnectorCapability.developer,
          },
          availability: ProviderConnectorAvailability.available,
        ),
      ]);

  /// A creative manager whose gate refuses unless [allowed] flips.
  static AccountCenterCreativeToolsConnections _connections({
    bool allowed = true,
  }) => AccountCenterCreativeToolsConnections(
    manifest: _manifest(),
    now: () => fixedNow,
    reauthenticate: () async => allowed,
  );

  /// `asset_access` — a connection keeps exactly the permissions it was given.
  Future<Sprint117CreativeConnectorWorkflowObservation>
  _observeAssetAccess() async {
    final connections = _connections();

    // A list, not a set literal, so the duplicate actually reaches the seam
    // and the deduplication it performs is what is measured here.
    final connection = connections.connect(
      providerId: ' FIGMA ',
      connectionId: 'figma/main',
      assetPermissions: const <CreativeAssetPermission>[
        CreativeAssetPermission.owned,
        CreativeAssetPermission.licensed,
        CreativeAssetPermission.owned,
      ],
      transferScope: CreativeTransferScope.importExport,
      attribution: 'Studio A license.',
    );

    // Duplicated input is one grant, not two.
    final deduplicated = connection.assetPermissions.length == 2;
    var widened = false;
    try {
      connection.assetPermissions.add(CreativeAssetPermission.publicDomain);
    } on UnsupportedError {
      widened = true;
    }
    final noPublicDomainAfterAttempt = !connection.assetPermissions.contains(
      CreativeAssetPermission.publicDomain,
    );

    var emptyRefused = false;
    try {
      connections.connect(
        providerId: 'figma',
        connectionId: 'figma/empty',
        assetPermissions: const <CreativeAssetPermission>{},
        transferScope: CreativeTransferScope.importOnly,
      );
    } on ArgumentError {
      emptyRefused = true;
    }

    // A connector the manifest marks UNVERIFIED cannot be connected, so a
    // provider nobody verified can never carry rights into the product.
    var unavailableRefused = false;
    try {
      connections.connect(
        providerId: 'canva',
        connectionId: 'canva/main',
        assetPermissions: const <CreativeAssetPermission>{
          CreativeAssetPermission.owned,
        },
        transferScope: CreativeTransferScope.importOnly,
      );
    } on StateError {
      unavailableRefused = true;
    }

    // A developer connector is not a creative one, however available it is.
    var wrongCategoryRefused = false;
    try {
      connections.connect(
        providerId: 'github',
        connectionId: 'github/main',
        assetPermissions: const <CreativeAssetPermission>{
          CreativeAssetPermission.owned,
        },
        transferScope: CreativeTransferScope.importOnly,
      );
    } on StateError {
      wrongCategoryRefused = true;
    }

    final refusedNeverStored = connections.activeConnections.every(
      (entry) => entry.connectionId == 'figma/main',
    );
    final onlyCreativeConnectors =
        connections.connectors
            .map((entry) => entry.providerId)
            .toList(growable: false)
          ..sort();

    final passed =
        deduplicated &&
        widened &&
        noPublicDomainAfterAttempt &&
        emptyRefused &&
        unavailableRefused &&
        wrongCategoryRefused &&
        refusedNeverStored &&
        onlyCreativeConnectors.join(',') == 'canva,figma';

    return Sprint117CreativeConnectorWorkflowObservation(
      checkId: 'asset_access',
      outcome: passed
          ? 'ASSET_PERMISSIONS_DEDUPLICATED_IMMUTABLE_AND_GATED'
          : 'ASSET_PERMISSIONS_MUTABLE_EMPTY_ACCEPTED_OR_PROVIDER_UNGATED',
      facts: <String, Object?>{
        'stored_permission_count': connection.assetPermissions.length,
        'duplicate_input_deduplicated': deduplicated,
        'permission_set_immutable': widened,
        'public_domain_absent_after_widening_attempt':
            noPublicDomainAfterAttempt,
        'empty_permissions_refused': emptyRefused,
        'unverified_provider_refused': unavailableRefused,
        'non_creative_provider_refused': wrongCategoryRefused,
        'refused_connections_never_stored': refusedNeverStored,
        'creative_connectors_listed': onlyCreativeConnectors,
        'mechanism':
            'AccountCenterCreativeToolsConnections.connect/'
            '_validateAssetPermissions',
        'acceptance_mechanism_present': _mechanismPresent['creative.connect']!,
        'permission_mechanism_present':
            _mechanismPresent['creative.permissions']!,
        'category_filter_present': _mechanismPresent['manifest.category']!,
      },
      passed: passed,
    );
  }

  /// `rights` — every asset rights record declares every field it must.
  ///
  /// The records are read from the committed 116.35 source rather than
  /// declared here, so a source that dropped a field makes this observation
  /// fail instead of being contradicted by a constant list.
  Sprint117CreativeConnectorWorkflowObservation _observeRights() {
    const path = Sprint117CreativeConnectorWorkflowContract.assetRights;
    final source = _readJsonFile(path);
    final required = source?['required_fields'];
    final records = source?['records'];

    final requiredNames = required is List<dynamic>
        ? required.map((entry) => entry.toString()).toSet()
        : const <String>{};
    const expected = <String>{
      'source',
      'license',
      'attribution',
      'usage_rights',
      'export_rights',
      'retention',
    };
    final everyFieldDeclared = expected.every(requiredNames.contains);

    final rows = records is List<dynamic> ? records : const <dynamic>[];
    final rowMaps = <Map<String, dynamic>>[
      for (final row in rows)
        if (row is Map<String, dynamic>) row,
    ];
    // Each record must actually carry the fields, not merely live beside a
    // manifest that names them.
    final rowsCarryEveryField =
        rowMaps.isNotEmpty &&
        rowMaps.every(
          (row) => expected.every(
            (field) =>
                (row[field] is String) && (row[field]! as String).isNotEmpty,
          ),
        );
    // No record may claim a live license: every provider in this sprint
    // starts UNVERIFIED and this slice cannot change that.
    final noneClaimsLive = rowMaps.every(
      (row) => row['status'] == 'UNVERIFIED',
    );

    final passed = everyFieldDeclared && rowsCarryEveryField && noneClaimsLive;

    return Sprint117CreativeConnectorWorkflowObservation(
      checkId: 'rights',
      outcome: passed
          ? 'RIGHTS_RECORDS_DECLARE_EVERY_FIELD_AND_CLAIM_NO_LICENSE'
          : 'RIGHTS_RECORDS_INCOMPLETE_OR_CLAIM_LIVE_LICENSE',
      facts: <String, Object?>{
        'required_field_count': requiredNames.length,
        'required_fields': requiredNames.toList(growable: false)..sort(),
        'every_required_field_declared': everyFieldDeclared,
        'record_count': rowMaps.length,
        'every_record_carries_every_field': rowsCarryEveryField,
        'every_record_unverified': noneClaimsLive,
        'source_manifest': path,
        'mechanism': 'committed 116.35 rights records',
        'acceptance_mechanism_present': rowMaps.isNotEmpty,
      },
      passed: passed,
    );
  }

  /// `attribution` — licensed assets cannot be connected without it.
  Future<Sprint117CreativeConnectorWorkflowObservation>
  _observeAttribution() async {
    final connections = _connections();

    var licensedWithoutAttributionRefused = false;
    try {
      connections.connect(
        providerId: 'figma',
        connectionId: 'figma/no-attribution',
        assetPermissions: const <CreativeAssetPermission>{
          CreativeAssetPermission.licensed,
        },
        transferScope: CreativeTransferScope.importOnly,
      );
    } on ArgumentError {
      licensedWithoutAttributionRefused = true;
    }

    // Blank text is no attribution at all, so it must not satisfy the rule.
    var blankAttributionRefused = false;
    try {
      connections.connect(
        providerId: 'figma',
        connectionId: 'figma/blank-attribution',
        assetPermissions: const <CreativeAssetPermission>{
          CreativeAssetPermission.licensed,
        },
        transferScope: CreativeTransferScope.importOnly,
        attribution: '   ',
      );
    } on ArgumentError {
      blankAttributionRefused = true;
    }

    // An owned asset needs no attribution, or the rule would force text the
    // user has no reason to supply.
    final ownedWithoutAttribution = connections.connect(
      providerId: 'figma',
      connectionId: 'figma/owned',
      assetPermissions: const <CreativeAssetPermission>{
        CreativeAssetPermission.owned,
      },
      transferScope: CreativeTransferScope.importOnly,
    );
    final ownedNeedsNoAttribution = ownedWithoutAttribution.attribution == null;

    // Attribution survives a padded, mixed-form input exactly as given.
    const attribution = 'Studio A — licensed for this project, 2026.';
    final licensed = connections.connect(
      providerId: 'figma',
      connectionId: 'figma/licensed',
      assetPermissions: const <CreativeAssetPermission>{
        CreativeAssetPermission.licensed,
      },
      transferScope: CreativeTransferScope.importExport,
      attribution: '  $attribution  ',
    );
    final preservedVerbatim = licensed.attribution == attribution;

    // A mixed grant that includes a licensed permission still needs it.
    var mixedWithoutAttributionRefused = false;
    try {
      connections.connect(
        providerId: 'figma',
        connectionId: 'figma/mixed',
        assetPermissions: const <CreativeAssetPermission>{
          CreativeAssetPermission.owned,
          CreativeAssetPermission.licensed,
        },
        transferScope: CreativeTransferScope.importOnly,
      );
    } on ArgumentError {
      mixedWithoutAttributionRefused = true;
    }

    final refusedNeverStored = !connections.activeConnections.any(
      (entry) =>
          entry.connectionId == 'figma/no-attribution' ||
          entry.connectionId == 'figma/blank-attribution' ||
          entry.connectionId == 'figma/mixed',
    );

    final passed =
        licensedWithoutAttributionRefused &&
        blankAttributionRefused &&
        ownedNeedsNoAttribution &&
        preservedVerbatim &&
        mixedWithoutAttributionRefused &&
        refusedNeverStored;

    return Sprint117CreativeConnectorWorkflowObservation(
      checkId: 'attribution',
      outcome: passed
          ? 'ATTRIBUTION_REQUIRED_FOR_LICENSED_AND_PRESERVED_VERBATIM'
          : 'ATTRIBUTION_RULE_INCOMPLETE_OR_TEXT_MANGLED',
      facts: <String, Object?>{
        'licensed_without_attribution_refused':
            licensedWithoutAttributionRefused,
        'blank_attribution_refused': blankAttributionRefused,
        'mixed_grant_without_attribution_refused':
            mixedWithoutAttributionRefused,
        'owned_asset_needs_no_attribution': ownedNeedsNoAttribution,
        'attribution_preserved_verbatim': preservedVerbatim,
        'refused_connections_never_stored': refusedNeverStored,
        'mechanism': 'CreativeToolConnection attribution invariant',
        'acceptance_mechanism_present':
            _mechanismPresent['creative.attribution']!,
      },
      passed: passed,
    );
  }

  /// `import` — the transfer scope is carried and never silently changed.
  ///
  /// What is *not* claimed: that any shipped code enforces the scope. The
  /// repository scan decides that separately and reports it as an open item,
  /// because a stored enum that nothing reads is a declaration, not a
  /// boundary.
  Future<Sprint117CreativeConnectorWorkflowObservation> _observeImport() async {
    final connections = _connections();

    final importOnly = connections.connect(
      providerId: 'figma',
      connectionId: 'figma/import-only',
      assetPermissions: const <CreativeAssetPermission>{
        CreativeAssetPermission.owned,
      },
      transferScope: CreativeTransferScope.importOnly,
    );
    final importExport = connections.connect(
      providerId: 'figma',
      connectionId: 'figma/import-export',
      assetPermissions: const <CreativeAssetPermission>{
        CreativeAssetPermission.owned,
      },
      transferScope: CreativeTransferScope.importExport,
    );

    final scopeCarried =
        importOnly.transferScope == CreativeTransferScope.importOnly &&
        importExport.transferScope == CreativeTransferScope.importExport;
    // Each connection keeps the scope it was given rather than inheriting the
    // one stored before it.
    final scopesNotShared =
        importOnly.connectionId != importExport.connectionId &&
        importOnly.transferScope != importExport.transferScope;

    // The scope is a final field with no setter, so a later connect cannot
    // rewrite what an earlier connection was granted. Proved against the
    // declaring type rather than against one instance, so the fact is about
    // the seam and not about this one object.
    final scopeHasNoSetter = !_hasSetter('transferScope');
    // And a second grant cannot mutate the first connection's scope either.
    final second = connections.connect(
      providerId: 'figma',
      connectionId: 'figma/second',
      assetPermissions: const <CreativeAssetPermission>{
        CreativeAssetPermission.publicDomain,
      },
      transferScope: CreativeTransferScope.exportOnly,
    );
    final firstUnchanged =
        importOnly.transferScope == CreativeTransferScope.importOnly &&
        second.transferScope == CreativeTransferScope.exportOnly;

    final enforcingCallSites = _transferScopeReadCallSites();

    // The check passes on what it claims: the declaration is carried and
    // distinct. The missing enforcement is reported as an open item by the
    // gate, not silently folded into a pass.
    final passed =
        scopeCarried && scopesNotShared && scopeHasNoSetter && firstUnchanged;

    return Sprint117CreativeConnectorWorkflowObservation(
      checkId: 'import',
      outcome: passed
          ? 'TRANSFER_SCOPE_CARRIED_AND_NOT_REWRITABLE'
          : 'TRANSFER_SCOPE_LOST_OR_MUTABLE',
      facts: <String, Object?>{
        'import_only_scope_recorded':
            importOnly.transferScope.name == 'importOnly',
        'import_export_scope_recorded':
            importExport.transferScope.name == 'importExport',
        'scope_carried_per_connection': scopeCarried,
        'distinct_grants_stay_distinct': scopesNotShared,
        'scope_not_rewritable_after_grant': scopeHasNoSetter,
        'later_grant_left_earlier_scope_untouched': firstUnchanged,
        'shipped_files_reading_transfer_scope': enforcingCallSites,
        'transfer_scope_enforced_somewhere': _transferScopeEnforcedSomewhere,
        'mechanism': 'CreativeToolConnection.transferScope',
        'acceptance_mechanism_present':
            _mechanismPresent['creative.transferScope']!,
      },
      passed: passed,
    );
  }

  /// `export` — export and import grants are never collapsed into one.
  Future<Sprint117CreativeConnectorWorkflowObservation> _observeExport() async {
    final connections = _connections();

    final importOnly = connections.connect(
      providerId: 'figma',
      connectionId: 'figma/import-only',
      assetPermissions: const <CreativeAssetPermission>{
        CreativeAssetPermission.owned,
      },
      transferScope: CreativeTransferScope.importOnly,
    );
    final exportOnly = connections.connect(
      providerId: 'figma',
      connectionId: 'figma/export-only',
      assetPermissions: const <CreativeAssetPermission>{
        CreativeAssetPermission.owned,
      },
      transferScope: CreativeTransferScope.exportOnly,
    );
    final importExport = connections.connect(
      providerId: 'figma',
      connectionId: 'figma/import-export',
      assetPermissions: const <CreativeAssetPermission>{
        CreativeAssetPermission.owned,
      },
      transferScope: CreativeTransferScope.importExport,
    );

    final threeDistinct =
        <CreativeTransferScope>{
          importOnly.transferScope,
          exportOnly.transferScope,
          importExport.transferScope,
        }.length ==
        3;
    // An import-only grant must never be reported as carrying an export
    // right, and the reverse must hold too.
    final notWidened =
        importOnly.transferScope != CreativeTransferScope.importExport &&
        exportOnly.transferScope != CreativeTransferScope.importOnly;

    // The grant survives the end of a connection attempt that the gate
    // refuses: a refused revoke must not quietly upgrade what was granted.
    final refused = AccountCenterCreativeToolsConnections(
      manifest: _manifest(),
      now: () => fixedNow,
      reauthenticate: () async => false,
    );
    final granted = refused.connect(
      providerId: 'figma',
      connectionId: 'figma/export-only',
      assetPermissions: const <CreativeAssetPermission>{
        CreativeAssetPermission.owned,
      },
      transferScope: CreativeTransferScope.exportOnly,
    );
    await refused.disconnect('figma/export-only', confirmed: true);
    final survivedRefusal =
        granted.transferScope == CreativeTransferScope.exportOnly &&
        refused.activeConnections.length == 1;

    final passed = threeDistinct && notWidened && survivedRefusal;

    return Sprint117CreativeConnectorWorkflowObservation(
      checkId: 'export',
      outcome: passed
          ? 'EXPORT_AND_IMPORT_GRANTS_STAY_DISTINCT_AFTER_REFUSAL'
          : 'TRANSFER_GRANTS_COLLAPSED_OR_LOST_ON_REFUSAL',
      facts: <String, Object?>{
        'distinct_transfer_scopes': threeDistinct ? 3 : 0,
        'import_only_not_reported_as_import_export': notWidened,
        'grant_survives_refused_disconnect': survivedRefusal,
        'connection_kept_after_refusal': refused.activeConnections.length,
        'scope_after_refusal': granted.transferScope.name,
        'mechanism': 'CreativeToolConnection.transferScope',
        'acceptance_mechanism_present':
            _mechanismPresent['creative.transferScope']!,
      },
      passed: passed,
    );
  }

  /// `revoke` — ending a creative connection is gated and audited.
  Future<Sprint117CreativeConnectorWorkflowObservation> _observeRevoke() async {
    // The gate refuses: the connection and its rights must survive.
    final refusedConnections = AccountCenterCreativeToolsConnections(
      manifest: _manifest(),
      now: () => fixedNow,
      reauthenticate: () async => false,
    );
    refusedConnections.connect(
      providerId: 'figma',
      connectionId: 'figma/main',
      assetPermissions: const <CreativeAssetPermission>{
        CreativeAssetPermission.licensed,
      },
      transferScope: CreativeTransferScope.importExport,
      attribution: 'Studio A license.',
    );
    final gateRefused = await refusedConnections.disconnect(
      'figma/main',
      confirmed: true,
    );
    final survivor = refusedConnections.activeConnections.single;
    final survivedRefusal = refusedConnections.activeConnections.length == 1;
    final rightsIntactAfterRefusal =
        survivor.attribution == 'Studio A license.' &&
        survivor.assetPermissions.length == 1 &&
        survivor.transferScope == CreativeTransferScope.importExport;

    // The same attempt leaves a row, so a refusal is never indistinguishable
    // from a disconnect nobody tried.
    final refusalAudited = refusedConnections.audit.any(
      (row) =>
          row.action == 'denied_disconnect' && row.connectionId == 'figma/main',
    );

    // No gate at all is not consent: the default refuses.
    final ungated = AccountCenterCreativeToolsConnections(
      manifest: _manifest(),
    );
    ungated.connect(
      providerId: 'figma',
      connectionId: 'figma/main',
      assetPermissions: const <CreativeAssetPermission>{
        CreativeAssetPermission.owned,
      },
      transferScope: CreativeTransferScope.importOnly,
    );
    // `disconnect` returns false when it refuses, so the refusal is the
    // negated result and the connection surviving is the second half of the
    // same fact.
    final ungatedDisconnected = await ungated.disconnect(
      'figma/main',
      confirmed: true,
    );
    final ungatedFailsClosed =
        !ungatedDisconnected && ungated.activeConnections.length == 1;

    // A confirmed flag of its own is never enough.
    final unconfirmed = _connections();
    unconfirmed.connect(
      providerId: 'figma',
      connectionId: 'figma/main',
      assetPermissions: const <CreativeAssetPermission>{
        CreativeAssetPermission.owned,
      },
      transferScope: CreativeTransferScope.importOnly,
    );
    final unconfirmedRefused = await unconfirmed.disconnect(
      'figma/main',
      confirmed: false,
    );

    // The gate allows: now the connection ends, and the attempt is recorded as
    // a completed action rather than a refusal.
    final allowed = _connections();
    allowed.connect(
      providerId: 'figma',
      connectionId: 'figma/main',
      assetPermissions: const <CreativeAssetPermission>{
        CreativeAssetPermission.licensed,
      },
      transferScope: CreativeTransferScope.importExport,
      attribution: 'Studio A license.',
    );
    final allowedEnded = await allowed.disconnect(
      'figma/main',
      confirmed: true,
    );
    final removed = allowed.activeConnections.isEmpty;
    final successAudited = allowed.audit.any(
      (row) => row.action == 'disconnect' && row.connectionId == 'figma/main',
    );
    // Every row names what happened and when, and carries no rights material.
    final rowsCarryNoRightsMaterial = allowed.audit.every((row) {
      final encoded = jsonEncode(row.toJson());
      return !encoded.contains('Studio A license') &&
          !encoded.contains('licensed') &&
          !encoded.contains('importExport') &&
          row.timestamp == fixedNow.toUtc();
    });

    final passed =
        !gateRefused &&
        survivedRefusal &&
        rightsIntactAfterRefusal &&
        refusalAudited &&
        ungatedFailsClosed &&
        !unconfirmedRefused &&
        allowedEnded &&
        removed &&
        successAudited &&
        rowsCarryNoRightsMaterial;

    return Sprint117CreativeConnectorWorkflowObservation(
      checkId: 'revoke',
      outcome: passed
          ? 'DISCONNECT_GATED_FAIL_CLOSED_AND_AUDITED'
          : 'DISCONNECT_UNGATED_UNDECIDED_OR_UNAUDITED',
      facts: <String, Object?>{
        'gate_refusal_returned_false': !gateRefused,
        'refusal_kept_the_connection': survivedRefusal,
        'rights_intact_after_refusal': rightsIntactAfterRefusal,
        'refusal_audited': refusalAudited,
        'ungated_seam_fails_closed': ungatedFailsClosed,
        'unconfirmed_cannot_disconnect': !unconfirmedRefused,
        'allowed_disconnect_ended_connection': allowedEnded && removed,
        'success_audited': successAudited,
        'audit_rows_carry_no_rights_material': rowsCarryNoRightsMaterial,
        'audit_row_count': allowed.audit.length,
        'audit_actions': allowed.audit
            .map((row) => row.action)
            .toList(growable: false),
        'mechanism': 'AccountCenterCreativeToolsConnections.disconnect + audit',
        'acceptance_mechanism_present':
            _mechanismPresent['creative.disconnect']!,
        'gate_mechanism_present': _mechanismPresent['creative.gate']!,
        'audit_mechanism_present': _mechanismPresent['creative.audit']!,
      },
      passed: passed,
    );
  }
}
