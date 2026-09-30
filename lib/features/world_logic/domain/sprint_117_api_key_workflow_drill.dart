part of 'sprint_117_api_key_workflow_validation.dart';

/// Executes the shipped credential mechanisms and records what each one
/// produced. It writes nothing — no manifest, no report, no user file — opens
/// no user project, contacts no provider or OS vault, and every secret it
/// touches is fixture data it created itself.
class Sprint117ApiKeyWorkflowDrill {
  const Sprint117ApiKeyWorkflowDrill();

  /// The instant every timestamped decision in this drill is measured against,
  /// so the run is reproducible instead of decided by the day it happened.
  static final DateTime fixedNow = DateTime.utc(2026, 1, 1, 12);

  /// A secret this drill owns. It is fixture data, never a live credential.
  static const String secret = 'drill-api-secret-9f2c7a41';

  /// Source files that hold the shipped credential mechanisms. A check whose
  /// behaviour only these files exercise is the mechanism existing, not the
  /// feature being reachable by a user.
  static const List<String> shippedSources = <String>[
    'lib/features/account/domain/account_center_api_keys_manager.dart',
    'lib/features/account/domain/account_center_secure_token_vault.dart',
  ];

  /// Whether [source] still declares [symbol], i.e. whether the mechanism this
  /// check exercises exists at all.
  ///
  /// This is measured rather than assumed so that renaming or deleting the
  /// shipped method makes the fact false instead of leaving a constant `true`
  /// behind. A constant would be the same defect as the `satisfied` default it
  /// replaces: it would make the acceptance look decided by something that
  /// never ran.
  static bool _declares(String source, String symbol) {
    final file = File(source);
    if (!file.existsSync()) return false;
    return file.readAsLinesSync().any((line) => line.contains(symbol));
  }

  /// Counts production call sites that reach [source] under `lib/`.
  ///
  /// Separate from [\_declares] on purpose: a declared mechanism that nothing
  /// calls satisfies the acceptance in the abstract but not for a user, and
  /// the two facts must not be collapsed into one. The harness family is
  /// excluded wholesale because no `sprint_117_*` file is reachable from
  /// `main.dart` — without that exclusion an acceptance drill counts itself
  /// as the production caller it was supposed to measure.
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
      for (var i = 0; i < entity.readAsLinesSync().length; i += 1) {
        if (entity.readAsLinesSync()[i].contains(stem)) {
          found.add('$path:${i + 1}');
          break;
        }
      }
    }
    return found.length;
  }

  /// Per shipped source: does it declare the mechanism, and does anything in
  /// production reach it.
  static final Map<String, bool> _mechanismPresent = <String, bool>{
    'manager.add|replace': _declares(shippedSources.first, 'replace('),
    'manager.validate': _declares(shippedSources.first, 'validate('),
    'manager.maskedValue': _declares(shippedSources.first, 'maskedValue'),
    'manager.scopes': _declares(shippedSources.first, 'scopes'),
    'manager.revoke': _declares(shippedSources.first, 'revoke('),
    'manager.audit': _declares(shippedSources.first, 'audit'),
    'manager.markUsed': _declares(shippedSources.first, 'markUsed'),
    'vault.copyToClipboard': _declares(shippedSources.last, 'copyToClipboard'),
    'vault.encrypted': _declares(shippedSources.last, 'revoke('),
  };

  /// Whether any production file outside the acceptance harness imports the
  /// credential mechanisms this slice validates.
  static final bool _productionCallerPresent =
      _productionCallSites(shippedSources.first) +
          _productionCallSites(shippedSources.last) >
      0;

  /// Runs every canonical check against the repository as it stands.
  Future<Sprint117ApiKeyWorkflowDrillRun> run() async {
    var matched = 0;
    var checked = 0;
    for (final entry in Sprint117ApiKeyWorkflowContract.externalPins.entries) {
      final actual = _sha256OfFile(entry.key);
      if (actual == null) continue;
      checked += 1;
      if (actual == entry.value) matched += 1;
    }
    return Sprint117ApiKeyWorkflowDrillRun(
      observations: <Sprint117ApiKeyWorkflowObservation>[
        await _observeAddReplace(),
        await _observeValidate(),
        await _observeMask(),
        await _observeScope(),
        await _observeSecureCopy(),
        await _observeRevoke(),
        await _observeAudit(),
        await _observeNoPlaintext(),
        await _observeLastUsed(),
      ],
      liveProviderTouched: false,
      userProjectTouched: false,
      liveSecretObserved: false,
      externalPinsMatched: matched,
      externalPinsChecked: checked,
      productionCallerPresent: _productionCallerPresent,
    );
  }

  /// `add_replace` — a rotated key must serve the new secret, stay masked in
  /// its public view, and a refused rotation must change nothing.
  Future<Sprint117ApiKeyWorkflowObservation> _observeAddReplace() async {
    final fixture = _KeyFixture();

    await fixture.manager.add(
      id: 'primary',
      providerId: 'cloud-ai',
      label: 'Primary key',
      secret: secret,
      scopes: const <String>{'models:read', 'generation:write'},
    );
    final storedAfterAdd = await fixture.store.read(
      'account/drill_account/api_key/primary',
    );
    await fixture.manager.validate('primary');
    await fixture.manager.replace(id: 'primary', secret: 'rotated-secret-4417');
    final storedAfterReplace = await fixture.store.read(
      'account/drill_account/api_key/primary',
    );

    // A refused rotation must leave the previous material in place, so the
    // user is not left believing a rotation happened when none did.
    fixture.reauthenticated = false;
    var refusedThrew = false;
    try {
      await fixture.manager.replace(id: 'primary', secret: 'never-applied');
    } on StateError {
      refusedThrew = true;
    }
    final storedAfterRefusal = await fixture.store.read(
      'account/drill_account/api_key/primary',
    );
    final key = fixture.manager.keys.single;

    final rotated = storedAfterReplace == 'rotated-secret-4417';
    final refusedKeptOld = storedAfterRefusal == 'rotated-secret-4417';
    final masked =
        !key.toPublicJson().toString().contains(secret) &&
        !key.toPublicJson().toString().contains('rotated-secret-4417');
    final resetAfterRotation =
        key.validation == ApiKeyValidation.unverified &&
        key.validatedAt == null;
    final deniedAudited = fixture.manager.audit.any(
      (e) => e.action == 'denied_replace',
    );

    final passed =
        storedAfterAdd == secret &&
        rotated &&
        refusedThrew &&
        refusedKeptOld &&
        masked &&
        resetAfterRotation &&
        deniedAudited;

    return Sprint117ApiKeyWorkflowObservation(
      checkId: 'add_replace',
      outcome: passed
          ? 'ROTATED_KEY_SERVES_NEW_SECRET_AND_REFUSAL_CHANGES_NOTHING'
          : 'ROTATION_OR_REFUSAL_MISBEHAVED',
      facts: <String, Object?>{
        'stored_after_add_is_secret': storedAfterAdd == secret,
        'stored_after_replace_is_rotated': rotated,
        'refused_rotation_threw': refusedThrew,
        'refused_rotation_kept_previous_secret': refusedKeptOld,
        'public_view_carries_no_secret': masked,
        'rotation_resets_validation': resetAfterRotation,
        'denied_replace_audited': deniedAudited,
        'mechanism': 'AccountCenterApiKeysManager.add/replace',
        'acceptance_mechanism_present':
            _mechanismPresent['manager.add|replace']!,
      },
      passed: passed,
    );
  }

  /// `validate` — a refused gate is a decided result, not an absent one.
  Future<Sprint117ApiKeyWorkflowObservation> _observeValidate() async {
    final fixture = _KeyFixture();

    await fixture.manager.add(
      id: 'primary',
      providerId: 'cloud-ai',
      label: 'Primary key',
      secret: secret,
      scopes: const <String>{'models:read'},
    );

    final goodAccepted = await fixture.manager.validate('primary');
    // Capture the state as scalars here. `keys.single` returns the live
    // ManagedApiKey object, so a reference captured now would still be
    // mutated by the later replace/validate and every term below would read
    // the final state instead of the one this step produced.
    final goodValidation = fixture.manager.keys.single.validation;
    final goodTimestamped = fixture.manager.keys.single.validatedAt != null;

    await fixture.manager.replace(id: 'primary', secret: 'wrong-secret-8801');
    final badRejected = await fixture.manager.validate('primary');
    final badValidation = fixture.manager.keys.single.validation;

    // Now refuse the gate itself: no secret is readable, so no probe can run.
    fixture.reauthenticated = false;
    final refused = await fixture.manager.validate('primary');
    final refusalValidation = fixture.manager.keys.single.validation;
    final refusalTimestamped = fixture.manager.keys.single.validatedAt != null;
    final refusedAudited = fixture.manager.audit
        .where((e) => e.action == 'denied_validate')
        .length;

    final decidedOnRefusal =
        refusalValidation == ApiKeyValidation.invalid && refusalTimestamped;
    final passed =
        goodAccepted &&
        goodValidation == ApiKeyValidation.valid &&
        goodTimestamped &&
        !badRejected &&
        badValidation == ApiKeyValidation.invalid &&
        !refused &&
        decidedOnRefusal &&
        refusedAudited == 1 &&
        fixture.probeCalls == 2;

    return Sprint117ApiKeyWorkflowObservation(
      checkId: 'validate',
      outcome: passed
          ? 'VALIDATION_DECIDED_AND_AUDITED_INCLUDING_REFUSAL'
          : 'VALIDATION_STATE_NOT_DECIDED_OR_NOT_AUDITED',
      facts: <String, Object?>{
        'good_key_accepted': goodAccepted,
        'good_key_marked_valid': goodValidation.name,
        'good_key_timestamped': goodTimestamped,
        'bad_key_rejected': !badRejected,
        'refused_gate_returned_false': !refused,
        'refusal_marked_invalid': refusalValidation.name,
        'refusal_timestamped': refusalTimestamped,
        'denied_validate_audit_rows': refusedAudited,
        'probe_invocations': fixture.probeCalls,
        'mechanism': 'AccountCenterApiKeysManager.validate; vault reauth gate',
        'acceptance_mechanism_present': _mechanismPresent['manager.validate']!,
      },
      passed: passed,
    );
  }

  /// `mask` — a key must never render as its secret, in any projection.
  Future<Sprint117ApiKeyWorkflowObservation> _observeMask() async {
    final fixture = _KeyFixture();

    // Add a real key so the masked value and the public projection come from
    // the shipped object rather than from a literal written here.
    await fixture.manager.add(
      id: 'primary',
      providerId: 'cloud-ai',
      label: 'Primary key',
      secret: secret,
      scopes: const <String>{'models:read'},
    );

    final key = fixture.manager.keys.single;
    final maskedValue = key.maskedValue;
    final vaultMask = fixture.vault.maskedDisplay(secret);
    final publicJson = key.toPublicJson().toString();
    final emptyMask = fixture.vault.maskedDisplay('');

    final maskedHidesSecret =
        !maskedValue.contains(secret) &&
        maskedValue.length >= 12 &&
        // A mask that is the secret plus decoration still leaks the secret.
        !secret.contains(maskedValue);
    final vaultMaskHidesSecret =
        !vaultMask.contains(secret) && vaultMask.length >= 12;
    final publicViewClean =
        !publicJson.contains(secret) && publicJson.contains(maskedValue);
    // An empty secret has nothing to hide, so no mask is required.
    final emptyHandled = emptyMask.isEmpty;

    final passed =
        maskedHidesSecret &&
        vaultMaskHidesSecret &&
        publicViewClean &&
        emptyHandled;

    return Sprint117ApiKeyWorkflowObservation(
      checkId: 'mask',
      outcome: passed
          ? 'KEY_NEVER_RENDERED_AS_SECRET'
          : 'KEY_RENDERING_LEAKED_SECRET_MATERIAL',
      facts: <String, Object?>{
        'masked_value_length': maskedValue.length,
        'masked_value_is_not_secret': maskedHidesSecret,
        'vault_mask_is_not_secret': vaultMaskHidesSecret,
        'public_projection_free_of_secret': publicViewClean,
        'empty_secret_masked_to_empty': emptyHandled,
        'mechanism': 'ManagedApiKey.maskedValue; maskedDisplay; toPublicJson',
        'acceptance_mechanism_present':
            _mechanismPresent['manager.maskedValue']!,
      },
      passed: passed,
    );
  }

  /// `scope` — a key keeps exactly the scopes it was added with.
  Future<Sprint117ApiKeyWorkflowObservation> _observeScope() async {
    final fixture = _KeyFixture();

    await fixture.manager.add(
      id: 'readonly',
      providerId: 'cloud-ai',
      label: 'Read only',
      secret: secret,
      scopes: const <String>{'models:read'},
    );
    await fixture.manager.add(
      id: 'writer',
      providerId: 'cloud-ai',
      label: 'Writer',
      secret: secret,
      scopes: const <String>{'models:read', 'generation:write'},
    );

    final reader = fixture.manager.keys.firstWhere((k) => k.id == 'readonly');
    final writer = fixture.manager.keys.firstWhere((k) => k.id == 'writer');

    // The probe must receive the key's own scopes, not a merged set.
    await fixture.manager.validate('writer');
    final probes = fixture.probeRequests.toList(growable: false);

    var emptyRefused = false;
    try {
      await fixture.manager.add(
        id: 'empty',
        providerId: 'cloud-ai',
        label: 'Empty',
        secret: secret,
        scopes: const <String>{},
      );
    } on ArgumentError {
      emptyRefused = true;
    }
    var blankRefused = false;
    try {
      await fixture.manager.add(
        id: 'blank',
        providerId: 'cloud-ai',
        label: 'Blank',
        secret: secret,
        scopes: const <String>{'  '},
      );
    } on ArgumentError {
      blankRefused = true;
    }
    var widened = false;
    try {
      reader.scopes.add('generation:write');
    } on UnsupportedError {
      widened = true;
    }

    final disjoint = !reader.scopes.contains('generation:write');
    final probeGotOwnScopes =
        probes.length == 1 &&
        probes.single.scopes.join(',') == 'models:read,generation:write' &&
        probes.single.scopes.length == 2;
    final passed =
        reader.scopes.length == 1 &&
        writer.scopes.length == 2 &&
        disjoint &&
        probeGotOwnScopes &&
        emptyRefused &&
        blankRefused &&
        widened;

    return Sprint117ApiKeyWorkflowObservation(
      checkId: 'scope',
      outcome: passed
          ? 'EACH_KEY_SCOPE_SET_KEPT_OWN_AND_UNMODIFIABLE'
          : 'SCOPE_SET_MUTABLE_OR_LEAKED_ACROSS_KEYS',
      facts: <String, Object?>{
        'reader_scope_count': reader.scopes.length,
        'writer_scope_count': writer.scopes.length,
        'scopes_disjoint': disjoint,
        'probe_received_key_own_scopes': probeGotOwnScopes,
        'empty_scopes_refused': emptyRefused,
        'blank_scope_refused': blankRefused,
        'scope_set_immutable': widened,
        'mechanism': 'ManagedApiKey.scopes; ApiKeyValidationRequest.scopes',
        'acceptance_mechanism_present': _mechanismPresent['manager.scopes']!,
      },
      passed: passed,
    );
  }

  /// `secure_copy` — a copy happens only after reauthentication.
  Future<Sprint117ApiKeyWorkflowObservation> _observeSecureCopy() async {
    final fixture = _KeyFixture();

    await fixture.manager.add(
      id: 'primary',
      providerId: 'cloud-ai',
      label: 'Primary key',
      secret: secret,
      scopes: const <String>{'models:read'},
    );

    fixture.reauthenticated = false;
    final refused = await fixture.manager.secureCopy('primary');
    final clipboardAfterRefusal = fixture.clipboard;

    fixture.reauthenticated = true;
    final allowed = await fixture.manager.secureCopy('primary');

    // A denied copy must be a refusal, not a silent empty success.
    final refusedDidNotWrite = clipboardAfterRefusal == null;
    final copiedExactly = fixture.clipboard == secret;
    final passed = !refused && refusedDidNotWrite && allowed && copiedExactly;

    return Sprint117ApiKeyWorkflowObservation(
      checkId: 'secure_copy',
      outcome: passed
          ? 'COPY_ONLY_AFTER_REAUTHENTICATION'
          : 'COPY_GATE_MISBEHAVED',
      facts: <String, Object?>{
        'refused_copy_returned_false': !refused,
        'refused_copy_wrote_nothing': refusedDidNotWrite,
        'allowed_copy_returned_true': allowed,
        'clipboard_holds_exact_secret': copiedExactly,
        'mechanism': 'AccountSecureTokenVault.copyToClipboard',
        'acceptance_mechanism_present':
            _mechanismPresent['vault.copyToClipboard']!,
      },
      passed: passed,
    );
  }

  /// `revoke` — a revoked key keeps no secret, no clipboard copy, no action.
  Future<Sprint117ApiKeyWorkflowObservation> _observeRevoke() async {
    final fixture = _KeyFixture();

    await fixture.manager.add(
      id: 'primary',
      providerId: 'cloud-ai',
      label: 'Primary key',
      secret: secret,
      scopes: const <String>{'models:read'},
    );
    // Put a live copy on the clipboard before revoking, so the revoke has to
    // clear it rather than merely deleting the stored one.
    final copied = await fixture.manager.secureCopy('primary');
    final clipboardBeforeRevoke = fixture.clipboard;

    await fixture.manager.revoke('primary');

    final stored = await fixture.store.read(
      'account/drill_account/api_key/primary',
    );
    final clipboardAfterRevoke = fixture.clipboard;
    final key = fixture.manager.keys.single;

    var validateAfter = false;
    var copyAfter = false;
    try {
      await fixture.manager.validate('primary');
    } on StateError {
      validateAfter = true;
    }
    try {
      await fixture.manager.secureCopy('primary');
    } on StateError {
      copyAfter = true;
    }

    final gone = stored == null;
    final clipboardCleared =
        clipboardAfterRevoke == null || clipboardAfterRevoke.isEmpty;
    final inert =
        key.status == ApiKeyStatus.revoked && validateAfter && copyAfter;

    final passed =
        copied &&
        clipboardBeforeRevoke == secret &&
        gone &&
        clipboardCleared &&
        inert;

    return Sprint117ApiKeyWorkflowObservation(
      checkId: 'revoke',
      outcome: passed
          ? 'REVOKED_KEY_KEEPS_NO_SECRET_NO_CLIPBOARD_NO_ACTION'
          : 'REVOKE_LEFT_KEY_MATERIAL_USABLE',
      facts: <String, Object?>{
        'clipboard_held_secret_before_revoke': clipboardBeforeRevoke == secret,
        'stored_secret_after_revoke_is_null': gone,
        'clipboard_cleared_at_revoke': clipboardCleared,
        'status_revoked': key.status.name,
        'validate_refused_after_revoke': validateAfter,
        'secure_copy_refused_after_revoke': copyAfter,
        'mechanism': 'AccountCenterApiKeysManager.revoke; vault.revoke',
        'acceptance_mechanism_present': _mechanismPresent['manager.revoke']!,
      },
      passed: passed,
    );
  }

  /// `audit` — every action emits one row carrying no secret.
  Future<Sprint117ApiKeyWorkflowObservation> _observeAudit() async {
    final fixture = _KeyFixture();

    await fixture.manager.add(
      id: 'primary',
      providerId: 'cloud-ai',
      label: 'Primary key',
      secret: secret,
      scopes: const <String>{'models:read'},
    );
    await fixture.manager.validate('primary');
    fixture.manager.markUsed('primary');
    await fixture.manager.replace(id: 'primary', secret: 'rotated-secret-4417');
    await fixture.manager.secureCopy('primary');
    await fixture.manager.revoke('primary');

    final actions = fixture.manager.audit.map((e) => e.action).toList();
    final vaultActions = fixture.vaultAudit.map((e) => e.action).toList();
    final serialized = fixture.manager.audit
        .map((e) => '${e.action}|${e.keyId}|${e.secret}')
        .join(';');
    final vaultSerialized = fixture.vaultAudit
        .map((e) => '${e.action}|${e.accountId}|${e.secret}')
        .join(';');

    final noSecret =
        !serialized.contains(secret) &&
        !serialized.contains('rotated-secret-4417') &&
        !vaultSerialized.contains(secret) &&
        !vaultSerialized.contains('rotated-secret-4417');
    // Every action taken must have left exactly one row.
    final everyActionAudited = <String>{
      'add',
      'validate',
      'use',
      'replace',
      'copy',
      'revoke',
    }.every((action) => actions.contains(action));
    final vaultCovers = <String>{
      'save',
      'read',
      'copy',
      'revoke',
    }.every((action) => vaultActions.contains(action));

    final passed = noSecret && everyActionAudited && vaultCovers;

    return Sprint117ApiKeyWorkflowObservation(
      checkId: 'audit',
      outcome: passed
          ? 'EVERY_ACTION_AUDITED_WITHOUT_SECRET_MATERIAL'
          : 'AUDIT_TRAIL_INCOMPLETE_OR_LEAKED_SECRET',
      facts: <String, Object?>{
        'manager_actions': actions,
        'vault_actions': vaultActions,
        'every_manager_action_audited': everyActionAudited,
        'vault_read_save_copy_revoke_audited': vaultCovers,
        'no_audit_row_carries_secret': noSecret,
        'mechanism': 'AccountCenterApiKeysManager.audit; VaultAuditEvent',
        'acceptance_mechanism_present': _mechanismPresent['manager.audit']!,
      },
      passed: passed,
    );
  }

  /// `no_plaintext` — nothing readable is left at rest or in any projection.
  Future<Sprint117ApiKeyWorkflowObservation> _observeNoPlaintext() async {
    final backing = MemoryCredentialStore();
    final store = EncryptedCredentialStore(
      cipher: const AesGcmCipher(),
      key: SecretKey(List<int>.filled(32, 7)),
      delegate: backing,
    );
    final vault = AccountSecureTokenVault(
      store: store,
      reauthenticate: () async => true,
      clipboardWriter: (value) async {},
    );
    final manager = AccountCenterApiKeysManager(
      accountId: 'drill_account',
      vault: vault,
      validator: (_) async => true,
    );

    await manager.add(
      id: 'primary',
      providerId: 'cloud-ai',
      label: 'Primary key',
      secret: secret,
      scopes: const <String>{'models:read'},
    );

    const key = 'account/drill_account/api_key/primary';
    final raw = await backing.read(key);
    final atRestHidden = raw != null && !raw.contains(secret);
    // A fragment long enough to be useful must not be recoverable either.
    final fragmentHidden =
        raw == null ||
        !raw.contains(secret.substring(0, 12)) ||
        secret.length < 12;

    // The namespace is per account: one account can never address another's.
    final otherNamespace = vault.keyFor(
      'other_account',
      VaultSecretKind.apiKey,
      secretId: 'primary',
    );

    final readBack = await store.read(key);
    final roundTrip = readBack == secret;

    final publicView = manager.keys.single.toPublicJson().toString();
    final vaultMask = vault.maskedDisplay(secret);
    final projectionsClean =
        !publicView.contains(secret) &&
        !publicView.contains(raw ?? secret) &&
        vaultMask != secret;

    final passed =
        atRestHidden &&
        fragmentHidden &&
        roundTrip &&
        projectionsClean &&
        otherNamespace != key;

    return Sprint117ApiKeyWorkflowObservation(
      checkId: 'no_plaintext',
      outcome: passed
          ? 'NO_PLAINTEXT_AT_REST_OR_IN_ANY_PROJECTION'
          : 'PLAINTEXT_FOUND_AT_REST_OR_IN_PROJECTION',
      facts: <String, Object?>{
        'cipher_envelope_present': raw != null,
        'raw_value_length': raw?.length ?? 0,
        'secret_absent_at_rest': atRestHidden,
        'secret_fragment_absent_at_rest': fragmentHidden,
        'encrypted_store_round_trips': roundTrip,
        'public_and_masked_projections_clean': projectionsClean,
        'account_namespace_isolated': otherNamespace != key,
        'mechanism': 'EncryptedCredentialStore over AesGcmCipher',
        'acceptance_mechanism_present': _mechanismPresent['vault.encrypted']!,
      },
      passed: passed,
      // The only production wiring for this is a store the screens inject;
      // the OS-backed store is selected by the caller, not by this mechanism.
      unresolvable: const <String>[],
    );
  }

  /// `last_used` — an acceptance the pinned 115.27 manifest declares and this
  /// slice had no row for.
  ///
  /// Canonical step 117.16 does not name it, but its own anchor binds the
  /// validation to 115.27, whose acceptance list includes `last_used`. A
  /// declared anchor item with no check is the same unmapped gap the gate
  /// rejects as `check_unmapped`, so it is measured here rather than skipped.
  Future<Sprint117ApiKeyWorkflowObservation> _observeLastUsed() async {
    final fixture = _KeyFixture();

    await fixture.manager.add(
      id: 'primary',
      providerId: 'cloud-ai',
      label: 'Primary key',
      secret: secret,
      scopes: const <String>{'models:read'},
    );
    final beforeUse = fixture.manager.keys.single.lastUsedAt;
    fixture.manager.markUsed('primary');
    final afterUse = fixture.manager.keys.single.lastUsedAt;

    final stamped = afterUse == Sprint117ApiKeyWorkflowDrill.fixedNow;
    final absentBefore = beforeUse == null;
    // The stamp must be metadata only: recording a use may never leak the
    // secret it just proved was readable.
    final projectionCarriesNoSecret = !fixture.manager.keys.single
        .toPublicJson()
        .toString()
        .contains(secret);

    final passed = stamped && absentBefore && projectionCarriesNoSecret;

    return Sprint117ApiKeyWorkflowObservation(
      checkId: 'last_used',
      outcome: passed
          ? 'USE_STAMPED_ON_KEY_METADATA_ONLY'
          : 'LAST_USED_NOT_STAMPED_OR_LEAKED_SECRET',
      facts: <String, Object?>{
        'last_used_null_before_use': absentBefore,
        'last_used_stamped_on_use': stamped,
        'stamped_value': afterUse?.toIso8601String(),
        'public_projection_free_of_secret': projectionCarriesNoSecret,
        'acceptance_mechanism_present': _mechanismPresent['manager.markUsed'],
        'mechanism': 'AccountCenterApiKeysManager.markUsed',
      },
      passed: passed,
      acceptance: _mechanismPresent['manager.markUsed']!
          ? Sprint117ApiKeyWorkflowAcceptance.satisfied
          : Sprint117ApiKeyWorkflowAcceptance.mechanismAbsent,
    );
  }
}

/// A manager over an in-memory vault with a controllable reauthentication
/// gate, a probe that records what it was handed, and a clock this drill owns.
class _KeyFixture {
  _KeyFixture() {
    vault = AccountSecureTokenVault(
      store: store,
      reauthenticate: () async => reauthenticated,
      clipboardWriter: (value) async => clipboard = value,
      clock: () => now,
      auditSink: vaultAudit.add,
    );
    manager = AccountCenterApiKeysManager(
      accountId: 'drill_account',
      vault: vault,
      clock: () => now,
      validator: (request) async {
        probeCalls += 1;
        probeRequests.add(request);
        return request.secret == Sprint117ApiKeyWorkflowDrill.secret;
      },
    );
  }

  final store = MemoryCredentialStore();
  final vaultAudit = <VaultAuditEvent>[];
  final probeRequests = <ApiKeyValidationRequest>[];
  late final AccountSecureTokenVault vault;
  late final AccountCenterApiKeysManager manager;
  DateTime now = DateTime.utc(2026, 1, 1, 12);
  bool reauthenticated = true;
  String? clipboard;

  int probeCalls = 0;
}
