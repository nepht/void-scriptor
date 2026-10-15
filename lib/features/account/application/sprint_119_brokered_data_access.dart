import 'dart:convert';

/// The kind of data a brokered scope reaches.
enum ResourceKind { account, project, novel, character, workspace, unknown }

/// A closed filter operator. There is no free-form expression.
enum QueryOperator {
  eq,
  ne,
  lt,
  lte,
  gt,
  gte,

  /// Membership in a declared value set.
  inSet,

  contains,
  prefix,

  /// An operator this build does not know. Always refused.
  unknown,
}

/// The wire name of a resource kind.
extension ResourceKindWireName on ResourceKind {
  /// The canonical snake_case name used on the wire.
  String get wireName => switch (this) {
    ResourceKind.account => 'account',
    ResourceKind.project => 'project',
    ResourceKind.novel => 'novel',
    ResourceKind.character => 'character',
    ResourceKind.workspace => 'workspace',
    ResourceKind.unknown => 'unknown',
  };
}

/// One filter in a brokered query.
final class QueryFilter {
  const QueryFilter({
    required this.field,
    required this.operator,
    this.values = const <String>[],
  });

  /// The field being filtered. Must be inside the scope's allow-list.
  final String field;

  /// The operator. Drawn from a closed set.
  final QueryOperator operator;

  /// The operands.
  final List<String> values;
}

/// A brokered query. There is no path, no connection, and no statement text.
final class QueryRequest {
  const QueryRequest({
    required this.handle,
    required this.resource,
    this.fields = const <String>[],
    this.filters = const <QueryFilter>[],
    required this.limit,
    this.cursor,
  });

  /// The opaque scope handle.
  final String handle;

  /// The resource kind.
  final ResourceKind resource;

  /// The projection. Empty means every field the scope allows.
  final List<String> fields;

  /// The filters.
  final List<QueryFilter> filters;

  /// The maximum number of rows to return.
  final int limit;

  /// An opaque resume handle.
  final String? cursor;

  /// The largest row count a single brokered query may return.
  static const int maxLimit = 200;
}

/// The serialization format of a brokered export.
enum ExportFormat { json, csv, unknown }

/// A brokered export. Credentials can never be part of one.
final class ExportRequest {
  const ExportRequest({
    required this.handle,
    required this.resource,
    required this.fields,
    required this.limit,
    required this.format,
    required this.destinationLocal,
  });

  /// The opaque scope handle.
  final String handle;

  /// The resource kind.
  final ResourceKind resource;

  /// The fields to export. Required, and a subset of the scope's allow-list.
  final List<String> fields;

  /// The maximum number of rows to export.
  final int limit;

  /// The serialization format.
  final ExportFormat format;

  /// Whether the export stays on this device.
  final bool destinationLocal;
}

/// A declared boundary. A scope names the resource it reaches and the exact
/// fields it may read. It carries no path and no connection.
final class BrokeredScope {
  const BrokeredScope({
    required this.handle,
    required this.resource,
    required this.allowedFields,
    required this.permissionRef,
  });

  /// The opaque scope handle.
  final String handle;

  /// The resource kind this scope reaches.
  final ResourceKind resource;

  /// The exact fields this scope may read.
  final List<String> allowedFields;

  /// The opaque permission handle this scope was derived from.
  final String permissionRef;
}

/// One append-only audit entry.
final class AuditEntry {
  const AuditEntry({
    required this.sequence,
    required this.action,
    required this.handle,
    required this.resource,
    required this.decision,
    required this.detail,
    required this.at,
  });

  /// The 1-based position in the trail.
  final int sequence;

  /// The action kind.
  final String action;

  /// The scope handle, redacted in the projection.
  final String handle;

  /// The resource kind.
  final ResourceKind resource;

  /// Whether the action was accepted.
  final bool decision;

  /// A short, redacted detail.
  final String detail;

  /// When the action happened.
  final DateTime at;

  /// A projection that redacts the handle and any opaque reference.
  Map<String, Object?> toJson() => <String, Object?>{
    'sequence': sequence,
    'action': action,
    'handle': '[REDACTED]',
    'resource': resource.wireName,
    'decision': decision ? 'accepted' : 'refused',
    'detail': BrokeredDataAccessContract.redact(detail),
    'at': at.toUtc().toIso8601String(),
  };

  @override
  String toString() =>
      'AuditEntry($sequence, $action, ${resource.wireName}, '
      '${decision ? 'accepted' : 'refused'})';
}

/// The outcome of a brokered action.
final class BrokerResult {
  const BrokerResult({
    required this.accepted,
    required this.diagnostics,
    this.rows = const <Map<String, String>>[],
    this.payload,
  });

  /// Whether the action was accepted.
  final bool accepted;

  /// The diagnostics that refused it.
  final List<String> diagnostics;

  /// The rows a query returned, projected to allowed fields only.
  final List<Map<String, String>> rows;

  /// The serialized payload an export produced.
  final String? payload;

  /// The number of rows returned.
  int get rowCount => rows.length;

  @override
  String toString() =>
      'BrokerResult(accepted: $accepted, rows: ${rows.length})';
}

/// The brokered data access boundary for one workspace.
///
/// A caller never receives a path, a connection string, or a storage handle.
/// Every read goes through an opaque scope handle that names the resource and
/// the exact fields it may touch, and every action appends to an audit trail.
final class DataBroker {
  DataBroker({
    required List<BrokeredScope> scopes,
    Map<String, List<Map<String, String>>>? dataset,
    DateTime Function()? clock,
  }) : _scopes = <String, BrokeredScope>{
         for (final BrokeredScope scope in scopes) scope.handle: scope,
       },
       _dataset = dataset ?? const <String, List<Map<String, String>>>{},
       _clock = clock ?? DateTime.now;

  final Map<String, BrokeredScope> _scopes;
  final Map<String, List<Map<String, String>>> _dataset;
  final DateTime Function() _clock;
  final List<AuditEntry> _audit = <AuditEntry>[];
  final Set<String> _revoked = <String>{};

  /// The public API surface. No member names a path, a file, a connection, a
  /// driver, or a statement, because a caller is never handed one.
  static const List<String> publicSurface = <String>[
    'diagnostics',
    'query',
    'export',
    'revoke',
    'isRevoked',
    'auditTrail',
  ];

  /// The append-only audit trail. There is no method that removes an entry.
  List<AuditEntry> get auditTrail => List<AuditEntry>.unmodifiable(_audit);

  /// Whether [handle] has been revoked.
  bool isRevoked(String handle) => _revoked.contains(handle);

  /// Validates the declared scopes.
  List<String> diagnostics() {
    final diagnostics = <String>[];
    for (final BrokeredScope scope in _scopes.values) {
      if (!BrokeredDataAccessContract.isOpaqueHandle(scope.handle)) {
        diagnostics.add('handle_invalid');
      }
      if (scope.resource == ResourceKind.unknown) {
        diagnostics.add('resource_unknown');
      }
      if (scope.allowedFields.isEmpty) {
        diagnostics.add('scope_fields_empty');
      }
      for (final String field in scope.allowedFields) {
        if (BrokeredDataAccessContract.isSecretFieldName(field)) {
          diagnostics.add('scope_field_secret_refused');
        } else if (!BrokeredDataAccessContract.isAllowedField(
          scope.resource,
          field,
        )) {
          diagnostics.add('scope_field_not_allowed:$field');
        }
      }
    }
    return diagnostics;
  }

  /// Runs a brokered query.
  BrokerResult query(QueryRequest request) {
    final diagnostics = <String>[
      ..._authorize(request.handle, request.resource),
    ];
    if (diagnostics.isNotEmpty) {
      return _refuse('query', request.handle, request.resource, diagnostics);
    }

    final scope = _scopes[request.handle]!;
    diagnostics.addAll(_validateQuery(request, scope));
    if (diagnostics.isNotEmpty) {
      return _refuse('query', request.handle, request.resource, diagnostics);
    }

    final projection = request.fields.isEmpty
        ? scope.allowedFields
        : request.fields;

    final source =
        _dataset[request.resource.wireName] ?? const <Map<String, String>>[];
    var rows = source
        .where(
          (Map<String, String> row) => request.filters.every(
            (QueryFilter filter) => _matches(row, filter),
          ),
        )
        .toList();

    if (request.cursor != null) {
      final resumeId = request.cursor!.substring('cursorref:'.length);
      final index = rows.indexWhere(
        (Map<String, String> row) => row['id'] == resumeId,
      );
      if (index < 0) {
        return _refuse('query', request.handle, request.resource, <String>[
          'cursor_unknown',
        ]);
      }
      rows = rows.sublist(index + 1);
    }

    final limited = rows.take(request.limit).toList();
    final projected = limited
        .map(
          (Map<String, String> row) => <String, String>{
            for (final String field in projection)
              if (row.containsKey(field)) field: row[field]!,
          },
        )
        .toList();

    _append(
      action: 'query',
      handle: request.handle,
      resource: request.resource,
      decision: true,
      detail:
          'fields=${projection.length} filters=${request.filters.length} '
          'limit=${request.limit} rows=${projected.length}',
    );

    return BrokerResult(
      accepted: true,
      diagnostics: const <String>[],
      rows: List<Map<String, String>>.unmodifiable(projected),
    );
  }

  /// Runs a brokered export.
  BrokerResult export(ExportRequest request) {
    final diagnostics = <String>[
      ..._authorize(request.handle, request.resource),
    ];
    if (diagnostics.isNotEmpty) {
      return _refuse('export', request.handle, request.resource, diagnostics);
    }

    final scope = _scopes[request.handle]!;
    diagnostics.addAll(_validateExport(request, scope));
    if (diagnostics.isNotEmpty) {
      return _refuse('export', request.handle, request.resource, diagnostics);
    }

    final source =
        _dataset[request.resource.wireName] ?? const <Map<String, String>>[];
    final rows = source
        .take(request.limit)
        .map(
          (Map<String, String> row) => <String, String>{
            for (final String field in request.fields)
              if (row.containsKey(field)) field: row[field]!,
          },
        )
        .toList();

    final payload = request.format == ExportFormat.json
        ? jsonEncode(<String, Object?>{'rows': rows})
        : _toCsv(request.fields, rows);

    _append(
      action: 'export',
      handle: request.handle,
      resource: request.resource,
      decision: true,
      detail:
          'format=${request.format.name} fields=${request.fields.length} '
          'rows=${rows.length}',
    );

    return BrokerResult(
      accepted: true,
      diagnostics: const <String>[],
      rows: List<Map<String, String>>.unmodifiable(rows),
      payload: payload,
    );
  }

  /// Revokes a scope handle. Always possible, and idempotent.
  void revoke(String handle) {
    _revoked.add(handle);
    _append(
      action: 'revoke',
      handle: handle,
      resource: _scopes[handle]?.resource ?? ResourceKind.unknown,
      decision: true,
      detail: 'revoked',
    );
  }

  List<String> _authorize(String handle, ResourceKind resource) {
    final scope = _scopes[handle];
    if (scope == null) {
      return const <String>['scope_unknown'];
    }
    if (_revoked.contains(handle)) {
      return const <String>['scope_revoked'];
    }
    if (scope.resource != resource) {
      return const <String>['scope_resource_mismatch'];
    }
    return const <String>[];
  }

  List<String> _validateQuery(QueryRequest request, BrokeredScope scope) {
    final diagnostics = <String>[];

    for (final String field in request.fields) {
      if (!scope.allowedFields.contains(field)) {
        diagnostics.add('query_field_not_allowed:$field');
      }
    }

    for (final QueryFilter filter in request.filters) {
      if (!scope.allowedFields.contains(filter.field)) {
        diagnostics.add('query_field_not_allowed:${filter.field}');
      }
      if (filter.operator == QueryOperator.unknown) {
        diagnostics.add('query_operator_unknown:${filter.field}');
      }
      if (filter.values.isEmpty) {
        diagnostics.add('query_filter_value_missing:${filter.field}');
      }
      for (final String value in filter.values) {
        if (BrokeredDataAccessContract.isExpressionLike(value)) {
          diagnostics.add('query_expression_refused:${filter.field}');
        }
      }
    }

    if (request.limit <= 0 || request.limit > QueryRequest.maxLimit) {
      diagnostics.add('query_limit_out_of_range');
    }

    final cursor = request.cursor;
    if (cursor != null && !BrokeredDataAccessContract.isOpaqueCursor(cursor)) {
      diagnostics.add('cursor_invalid');
    }

    return diagnostics;
  }

  List<String> _validateExport(ExportRequest request, BrokeredScope scope) {
    final diagnostics = <String>[];

    if (request.format == ExportFormat.unknown) {
      diagnostics.add('export_format_unknown');
    }
    if (request.fields.isEmpty) {
      diagnostics.add('export_fields_empty');
    }
    for (final String field in request.fields) {
      if (BrokeredDataAccessContract.isSecretFieldName(field)) {
        diagnostics.add('export_secret_field_refused:$field');
      } else if (!scope.allowedFields.contains(field)) {
        diagnostics.add('export_field_not_allowed:$field');
      }
    }
    if (request.limit <= 0 || request.limit > QueryRequest.maxLimit) {
      diagnostics.add('export_limit_out_of_range');
    }
    if (!request.destinationLocal) {
      diagnostics.add('export_destination_not_local');
    }

    return diagnostics;
  }

  bool _matches(Map<String, String> row, QueryFilter filter) {
    final value = row[filter.field];
    if (value == null) {
      return false;
    }
    final operand = filter.values.isEmpty ? '' : filter.values.first;
    return switch (filter.operator) {
      QueryOperator.eq => value == operand,
      QueryOperator.ne => value != operand,
      QueryOperator.lt => value.compareTo(operand) < 0,
      QueryOperator.lte => value.compareTo(operand) <= 0,
      QueryOperator.gt => value.compareTo(operand) > 0,
      QueryOperator.gte => value.compareTo(operand) >= 0,
      QueryOperator.inSet => filter.values.contains(value),
      QueryOperator.contains => value.contains(operand),
      QueryOperator.prefix => value.startsWith(operand),
      QueryOperator.unknown => false,
    };
  }

  String _toCsv(List<String> fields, List<Map<String, String>> rows) {
    final lines = <String>[fields.join(',')];
    for (final Map<String, String> row in rows) {
      lines.add(fields.map((String field) => row[field] ?? '').join(','));
    }
    return lines.join('\n');
  }

  BrokerResult _refuse(
    String action,
    String handle,
    ResourceKind resource,
    List<String> diagnostics,
  ) {
    _append(
      action: action,
      handle: handle,
      resource: resource,
      decision: false,
      detail: diagnostics.join(' '),
    );
    return BrokerResult(
      accepted: false,
      diagnostics: List<String>.unmodifiable(diagnostics),
    );
  }

  void _append({
    required String action,
    required String handle,
    required ResourceKind resource,
    required bool decision,
    required String detail,
  }) {
    _audit.add(
      AuditEntry(
        sequence: _audit.length + 1,
        action: action,
        handle: handle,
        resource: resource,
        decision: decision,
        detail: detail,
        at: _clock(),
      ),
    );
  }
}

/// The local brokered data access contract for roadmap step 119.23.
abstract final class BrokeredDataAccessContract {
  /// The manifest describing this step.
  static const String manifestPath =
      'docs/planning/v1.3/sprint_119_brokered_data_access.json';

  /// The canonical step identifier.
  static const String canonicalStep = '119.23';

  /// The six canonical acceptance points, in canonical order.
  static const List<String> requiredAcceptance = <String>[
    'scoped_handle',
    'query_contract',
    'export_contract',
    'audit',
    'revocation',
    'no_direct_database',
  ];

  /// The fields each resource kind allows. Nothing else is reachable.
  static const Map<ResourceKind, List<String>> canonicalFields =
      <ResourceKind, List<String>>{
        ResourceKind.account: <String>['id', 'email_handle', 'plan'],
        ResourceKind.project: <String>['id', 'name', 'updated_at'],
        ResourceKind.novel: <String>['id', 'title', 'status'],
        ResourceKind.character: <String>['id', 'name', 'novel_ref'],
        ResourceKind.workspace: <String>['id', 'name', 'created_at'],
      };

  /// Substrings that would mean a caller had been handed direct storage
  /// access. No public member name may contain one.
  static const List<String> forbiddenSurface = <String>[
    'path',
    'file',
    'dir',
    'sql',
    'statement',
    'connection',
    'database',
    'driver',
    'socket',
    'credential',
  ];

  static final RegExp _opaqueHandle = RegExp(
    r'^scoperef:[a-z][a-z0-9._-]{2,63}:[a-z0-9._-]{1,63}$',
  );

  static final RegExp _opaqueCursor = RegExp(
    r'^cursorref:[a-z0-9][a-z0-9._-]{1,63}$',
  );

  static final RegExp _secretField = RegExp(
    r'secret|token|password|passwd|api_?key|credential|private',
    caseSensitive: false,
  );

  static final RegExp _expressionLike = RegExp(
    r';|--|/\*|\*/|\bselect\b|\bunion\b|\bdrop\b|\binsert\b|\bupdate\b|'
    r'\bdelete\b|\bfrom\b|\bwhere\b|<\||\|\||\$|\{|\}|\\',
    caseSensitive: false,
  );

  static final RegExp _directStorage = RegExp(
    r'^(?:file|sqlite|postgres|postgresql|mysql|mongodb|redis|jdbc|odbc|'
    r'smb|ftp|s3)://|^[a-z]:[\\/]|^\\\\|^/|\.db$|\.sqlite$|\.sql$',
    caseSensitive: false,
  );

  static final RegExp _redactRef = RegExp(
    r'\b(?:scoperef|cursorref|permref|revokeref|secretref|provref|actionref|'
    r'evtref|idemref|payref|chkref|invref|modelref|assetref|orgref|resref|'
    r'jobref|iconref):[a-z0-9][a-z0-9._-]{1,63}(?::[a-z0-9._-]{1,63})?\b',
    caseSensitive: false,
  );

  /// Whether [value] is a well-formed opaque scope handle.
  static bool isOpaqueHandle(String value) =>
      _opaqueHandle.hasMatch(value) && !_directStorage.hasMatch(value);

  /// Whether [value] is a well-formed opaque resume handle.
  static bool isOpaqueCursor(String value) =>
      _opaqueCursor.hasMatch(value) && !_directStorage.hasMatch(value);

  /// Whether [value] names a credential-bearing field.
  static bool isSecretFieldName(String value) => _secretField.hasMatch(value);

  /// Whether [value] looks like a statement, an expression, or an injection.
  static bool isExpressionLike(String value) => _expressionLike.hasMatch(value);

  /// Whether [value] looks like a direct storage location.
  static bool isDirectStorageReference(String value) =>
      _directStorage.hasMatch(value);

  /// Whether [field] is reachable for [resource].
  static bool isAllowedField(ResourceKind resource, String field) =>
      canonicalFields[resource]?.contains(field) ?? false;

  /// Replaces opaque references in [text] so a diagnostic cannot leak one.
  static String redact(String text) =>
      text.replaceAll(_redactRef, '[REDACTED]');

  /// Validates a manifest against this step's contract.
  static List<String> validateManifest(Map<String, dynamic> manifest) {
    final diagnostics = <String>[];

    if (manifest['canonical_step'] != canonicalStep) {
      diagnostics.add('canonical_step_invalid');
    }
    if (manifest['unknown_field_policy'] != 'REJECT') {
      diagnostics.add('unknown_field_policy_invalid');
    }

    final acceptance = manifest['acceptance'];
    final declared = acceptance is Map
        ? acceptance.keys.map((Object? key) => '$key').toList()
        : acceptance is List
        ? acceptance.map((Object? entry) => '$entry').toList()
        : const <String>[];

    for (final String point in requiredAcceptance) {
      if (!declared.contains(point)) {
        diagnostics.add('acceptance_missing:$point');
      }
    }
    if (declared.length == requiredAcceptance.length &&
        !_sameOrder(declared, requiredAcceptance)) {
      diagnostics.add('acceptance_order_invalid');
    }

    return diagnostics;
  }

  static bool _sameOrder(List<String> left, List<String> right) {
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }
}
