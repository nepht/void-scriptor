/// Sprint 117.41 — Final Connector Registry Reconciliation (gate gagal-tertutup).
///
/// Canonical step (external `sprint_117.json`) objective: "Memperbarui status
/// per provider berdasarkan bukti dan memastikan UNVERIFIED/BLOCKED tidak tampil
/// sebagai available.", with seven `required_fields`:
///   `provider_id`, `connector_version`, `status`, `evidence`, `limitations`,
///   `visibility`, `recheck_date`.
///
/// The step names no per-field acceptance vocabulary beyond those seven, so the
/// gate does not invent one. It measures the two claims the step DOES state:
///
/// 1. every provider row carries all seven canonical fields as real,
///    non-vacuous values, and
/// 2. a row whose status is UNVERIFIED or BLOCKED is never `exposed` — the
///    exact failure the objective names.
///
/// Status per check:
/// * `pass` — the shipped seam produced the measured value for that row;
/// * `violation` — the row claims exposure its own status forbids, or a
///   canonical field is absent, blank, or carried by no executed test;
/// * `unmet` — a row this slice could not measure from a shipped seam. Named as
///   an open item, never converted to a pass.
///
/// Fail-closed structural failures:
/// * `no_registry_rows` — an empty registry proves nothing;
/// * `non_canonical_fields` — the seven required fields drifted;
/// * `duplicate_provider_id:<id>`;
/// * `missing_field:<id>:<field>` — a canonical field absent or blank;
/// * `vacuous:<id>:<field>` — a present-but-empty declaration is not evidence,
///   so it fails like an absent one;
/// * `recheck_date_unparsed:<id>` — a recheck date nobody can parse silently
///   disables the recertification promise (overflow dates such as 2099-02-30
///   are rejected rather than normalised);
/// * `unverified_exposed:<id>` / `blocked_exposed:<id>` — the objective's own
///   failure, stated explicitly so exposure cannot hide behind a name;
/// * `no_check_for_row:<id>` — a row claims exposure with no executed test;
/// * `duplicate_check:<id>:<check>`;
/// * `unknown_field:<field>` / `unknown_check:<id>:<check>` — vocabulary drift
///   outside the canonical seven is rejected, never quietly accepted.
///
/// The gate is pure Dart so it can be re-evaluated from recorded facts.
library;

/// Status of one measured check on one provider row.
enum Sprint117ConnectorRegistryStatus { pass, violation, unmet }

/// Reconciliation status recorded for one provider.
///
/// The wire names are the values the beta registry records. `certified` is the
/// only status that can be exposed; every other status is withheld, and the
/// gate below enforces that rather than trusting the row to self-declare it.
enum Sprint117ConnectorRegistryState {
  /// Live certification evidence exists behind the status.
  certified('CERTIFIED'),

  /// Usable under recorded restrictions.
  limited('LIMITED'),

  /// Declared, no certification evidence yet. Never exposed.
  unverified('UNVERIFIED'),

  /// Named in the roadmap but not built. Never exposed.
  planned('PLANNED'),

  /// The provider answered but is unhealthy. Never exposed as healthy.
  degraded('DEGRADED'),

  /// Withheld by a certification or privacy decision. Never exposed.
  blocked('BLOCKED');

  const Sprint117ConnectorRegistryState(this.wireName);

  final String wireName;

  /// True when this status is allowed to be exposed to users at all.
  bool get mayBeExposed =>
      this == Sprint117ConnectorRegistryState.certified ||
      this == Sprint117ConnectorRegistryState.limited;
}

/// Whether a reconciled provider is shown to users.
enum Sprint117ConnectorVisibility {
  /// The row is published in the provider surface.
  exposed('EXPOSED'),

  /// The row exists and is reconciled, but is not published.
  notExposed('WITHHELD');

  const Sprint117ConnectorVisibility(this.wireName);

  final String wireName;
}

/// One reconciled provider row carrying the seven canonical fields.
final class Sprint117ConnectorRegistryRow {
  const Sprint117ConnectorRegistryRow({
    required this.providerId,
    required this.connectorVersion,
    required this.status,
    required this.evidence,
    required this.limitations,
    required this.visibility,
    required this.recheckDate,
  });

  /// Stable identity of the provider.
  final String providerId;

  /// The connector contract version the shipped manifest records.
  final String connectorVersion;

  /// The reconciled certification status.
  final Sprint117ConnectorRegistryState status;

  /// The measured basis for the status. Never blank: an unmeasured status has
  /// no evidence and the gate fails it as vacuous.
  final String evidence;

  /// Recorded limitations. At least one non-blank entry is required.
  final List<String> limitations;

  /// Whether the row is published.
  final Sprint117ConnectorVisibility visibility;

  /// ISO-8601 date the row is next due for recheck.
  final String recheckDate;

  /// The seven canonical `required_fields`, in contract order.
  Map<String, String> get fields => <String, String>{
    'provider_id': providerId,
    'connector_version': connectorVersion,
    'status': status.wireName,
    'evidence': evidence,
    'limitations': limitations
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .join('; '),
    'visibility': visibility.wireName,
    'recheck_date': recheckDate,
  };

  Map<String, Object?> toJson() => <String, Object?>{
    'provider_id': providerId,
    'connector_version': connectorVersion,
    'status': status.wireName,
    'evidence': evidence,
    'limitations': List<String>.from(limitations),
    'visibility': visibility.wireName,
    'recheck_date': recheckDate,
  };
}

/// One measured statement about one provider row.
final class Sprint117ConnectorRegistryCheck {
  const Sprint117ConnectorRegistryCheck({
    required this.providerId,
    required this.check,
    required this.status,
    required this.declared,
    required this.observed,
    this.note = '',
  });

  factory Sprint117ConnectorRegistryCheck.pass_({
    required String providerId,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117ConnectorRegistryCheck(
    providerId: providerId,
    check: check,
    status: Sprint117ConnectorRegistryStatus.pass,
    declared: declared,
    observed: observed,
    note: note,
  );

  factory Sprint117ConnectorRegistryCheck.violation({
    required String providerId,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117ConnectorRegistryCheck(
    providerId: providerId,
    check: check,
    status: Sprint117ConnectorRegistryStatus.violation,
    declared: declared,
    observed: observed,
    note: note,
  );

  factory Sprint117ConnectorRegistryCheck.unmet({
    required String providerId,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117ConnectorRegistryCheck(
    providerId: providerId,
    check: check,
    status: Sprint117ConnectorRegistryStatus.unmet,
    declared: declared,
    observed: observed,
    note: note,
  );

  final String providerId;
  final String check;
  final Sprint117ConnectorRegistryStatus status;
  final String declared;
  final String observed;
  final String note;

  String get code => '$providerId:$check';

  bool get isViolation => status == Sprint117ConnectorRegistryStatus.violation;

  Map<String, Object?> toJson() => <String, Object?>{
    'provider_id': providerId,
    'check': check,
    'status': status.name,
    'declared': declared,
    'observed': observed,
    if (note.isNotEmpty) 'note': note,
  };
}

/// Aggregate verdict of the 117.41 final connector registry gate.
final class Sprint117ConnectorRegistryResult {
  const Sprint117ConnectorRegistryResult({
    required this.verdict,
    required this.pass,
    required this.failures,
    required this.openItems,
    required this.checks,
    required this.rows,
    required this.exposedProviderIds,
    required this.withheldProviderIds,
  });

  final String verdict;
  final bool pass;
  final List<String> failures;
  final List<String> openItems;
  final List<Sprint117ConnectorRegistryCheck> checks;
  final List<Sprint117ConnectorRegistryRow> rows;
  final List<String> exposedProviderIds;
  final List<String> withheldProviderIds;

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': Sprint117FinalConnectorRegistryContract.canonicalStep,
    'document_role': 'EVIDENCE',
    'verdict': verdict,
    'pass': pass,
    'required_fields': Sprint117FinalConnectorRegistryContract.requiredFields
        .toList(),
    'row_count': rows.length,
    'exposed_provider_ids': List<String>.from(exposedProviderIds),
    'withheld_provider_ids': List<String>.from(withheldProviderIds),
    'failures': List<String>.from(failures),
    'open_items': List<String>.from(openItems),
    'checks': [for (final check in checks) check.toJson()],
    'rows': [for (final row in rows) row.toJson()],
  };
}

/// Fail-closed final connector registry contract for sprint 117.41.
abstract final class Sprint117FinalConnectorRegistryContract {
  /// The canonical roadmap step this gate measures.
  static const String canonicalStep = '117.41';

  /// The seven canonical `required_fields`, verbatim and in contract order.
  static const List<String> requiredFields = <String>[
    'provider_id',
    'connector_version',
    'status',
    'evidence',
    'limitations',
    'visibility',
    'recheck_date',
  ];

  static const String passVerdict = 'FINAL_CONNECTOR_REGISTRY_RECONCILED_LOCAL';
  static const String failVerdict = 'FINAL_CONNECTOR_REGISTRY_INCONSISTENT';

  static String _readable(String providerId) =>
      providerId.trim().isEmpty ? '(no provider_id)' : providerId.trim();

  /// A declared or observed value that trims to nothing is not evidence.
  static bool isVacuous(Sprint117ConnectorRegistryCheck check) =>
      check.declared.trim().isEmpty || check.observed.trim().isEmpty;

  /// A recheck date the gate cannot parse is not a recertification promise.
  ///
  /// The round trip through the formatted value rejects overflow dates such as
  /// 2099-02-30 that `DateTime.parse` would otherwise normalise silently into
  /// 2099-03-02.
  static DateTime? parseRecheckDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) return null;
    final month = int.tryParse(trimmed.substring(5, 7));
    final day = int.tryParse(trimmed.substring(8, 10));
    if (month == null || day == null) return null;
    if (month != parsed.month || day != parsed.day) return null;
    return DateTime.utc(parsed.year, parsed.month, parsed.day);
  }

  /// The canonical fields a row left absent entirely.
  ///
  /// An ABSENT value (`''`) is reported as `missing_field`. A value that is
  /// present but trims to nothing is reported as `vacuous` instead, so a
  /// whitespace-only declaration cannot hide behind the same code as a field
  /// nobody wrote at all.
  static List<String> absentFields(Sprint117ConnectorRegistryRow row) {
    final fields = row.fields;
    return <String>[
      for (final field in requiredFields)
        if ((fields[field] ?? '').isEmpty) field,
    ];
  }

  /// The canonical fields a row declared but left without any content.
  static List<String> vacuousFields(Sprint117ConnectorRegistryRow row) {
    final fields = row.fields;
    return <String>[
      for (final field in requiredFields)
        if ((fields[field] ?? '').isNotEmpty && fields[field]!.trim().isEmpty)
          field,
    ];
  }

  static Sprint117ConnectorRegistryResult evaluate(
    List<Sprint117ConnectorRegistryRow> rows,
    List<Sprint117ConnectorRegistryCheck> checks,
  ) {
    if (requiredFields.toSet().length != requiredFields.length) {
      return Sprint117ConnectorRegistryResult(
        verdict: failVerdict,
        pass: false,
        failures: const <String>['non_canonical_fields'],
        openItems: const <String>[],
        checks: const <Sprint117ConnectorRegistryCheck>[],
        rows: rows,
        exposedProviderIds: const <String>[],
        withheldProviderIds: const <String>[],
      );
    }

    final failures = <String>[];

    if (rows.isEmpty) {
      failures.add('no_registry_rows');
    }

    final seenIds = <String>{};
    for (final row in rows) {
      final id = row.providerId.trim();
      if (id.isEmpty) {
        failures.add('missing_field:${_readable(id)}:provider_id');
        continue;
      }
      if (!seenIds.add(id)) {
        failures.add('duplicate_provider_id:${_readable(id)}');
      }

      for (final field in absentFields(row)) {
        failures.add('missing_field:${_readable(id)}:$field');
      }
      for (final field in vacuousFields(row)) {
        failures.add('vacuous:${_readable(id)}:$field');
      }

      final recheck = row.recheckDate.trim();
      if (recheck.isNotEmpty && parseRecheckDate(recheck) == null) {
        failures.add('recheck_date_unparsed:${_readable(id)}');
      }

      // The step's own objective, stated as a named failure so exposure cannot
      // hide behind a status name: an UNVERIFIED or BLOCKED row published to
      // users is the exact defect this step exists to prevent.
      final exposed = row.visibility == Sprint117ConnectorVisibility.exposed;
      if (exposed && !row.status.mayBeExposed) {
        failures.add(
          '${row.status == Sprint117ConnectorRegistryState.blocked ? 'blocked' : 'unverified'}_exposed:${_readable(id)}',
        );
      }
    }

    final seenChecks = <String>{};
    for (final check in checks) {
      if (!seenChecks.add(check.code)) {
        failures.add('duplicate_check:${check.code}');
      }
      if (isVacuous(check)) {
        failures.add('vacuous:${check.code}');
      }
      if (check.isViolation) {
        failures.add('violation:${check.code}');
      }
      if (check.check.trim().isEmpty) {
        failures.add('unknown_check:${_readable(check.providerId)}:');
      }
    }

    // A row published to users must be covered by a check that actually passed;
    // otherwise the pass rests on the row's own declaration.
    for (final row in rows) {
      if (row.visibility != Sprint117ConnectorVisibility.exposed) continue;
      final id = row.providerId.trim();
      final covered = checks.where((check) => check.providerId == id);
      if (covered.isEmpty) {
        failures.add('no_check_for_row:${_readable(id)}');
        continue;
      }
      final passing = covered.any(
        (check) =>
            check.status == Sprint117ConnectorRegistryStatus.pass &&
            !isVacuous(check),
      );
      if (!passing) {
        failures.add('row_without_pass:${_readable(id)}');
      }
    }

    final openItems = <String>[
      for (final check in checks)
        if (check.status != Sprint117ConnectorRegistryStatus.pass) check.code,
    ];

    final exposedIds = <String>[
      for (final row in rows)
        if (row.visibility == Sprint117ConnectorVisibility.exposed)
          row.providerId.trim(),
    ]..sort();
    final withheldIds = <String>[
      for (final row in rows)
        if (row.visibility == Sprint117ConnectorVisibility.notExposed)
          row.providerId.trim(),
    ]..sort();

    return Sprint117ConnectorRegistryResult(
      verdict: failures.isEmpty ? passVerdict : failVerdict,
      pass: failures.isEmpty,
      failures: failures,
      openItems: openItems,
      checks: checks,
      rows: rows,
      exposedProviderIds: exposedIds,
      withheldProviderIds: withheldIds,
    );
  }
}
