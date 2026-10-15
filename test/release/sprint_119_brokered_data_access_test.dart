import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/application/sprint_119_brokered_data_access.dart';

final DateTime t0 = DateTime.utc(2026, 3, 1, 12);

const String handle = 'scoperef:alpha:workspace-read';
const String permissionRef = 'permref:alpha:read-workspace';

const BrokeredScope scope = BrokeredScope(
  handle: handle,
  resource: ResourceKind.workspace,
  allowedFields: <String>['id', 'name', 'created_at'],
  permissionRef: permissionRef,
);

/// A dataset that also carries a field the scope does not allow.
const Map<String, List<Map<String, String>>> dataset =
    <String, List<Map<String, String>>>{
      'workspace': <Map<String, String>>[
        <String, String>{
          'id': 'ws-1',
          'name': 'Alpha Workspace',
          'created_at': '2026-01-01',
          'internal_note': 'not reachable',
        },
        <String, String>{
          'id': 'ws-2',
          'name': 'Beta Workspace',
          'created_at': '2026-02-01',
          'internal_note': 'not reachable',
        },
        <String, String>{
          'id': 'ws-3',
          'name': 'Gamma Workspace',
          'created_at': '2026-03-01',
          'internal_note': 'not reachable',
        },
      ],
    };

DataBroker broker({
  List<BrokeredScope> scopes = const <BrokeredScope>[scope],
}) => DataBroker(scopes: scopes, dataset: dataset, clock: () => t0);

QueryRequest query({
  String handleRef = handle,
  ResourceKind resource = ResourceKind.workspace,
  List<String> fields = const <String>[],
  List<QueryFilter> filters = const <QueryFilter>[],
  int limit = 50,
  String? cursor,
}) => QueryRequest(
  handle: handleRef,
  resource: resource,
  fields: fields,
  filters: filters,
  limit: limit,
  cursor: cursor,
);

ExportRequest export({
  String handleRef = handle,
  ResourceKind resource = ResourceKind.workspace,
  List<String> fields = const <String>['id', 'name'],
  int limit = 50,
  ExportFormat format = ExportFormat.json,
  bool destinationLocal = true,
}) => ExportRequest(
  handle: handleRef,
  resource: resource,
  fields: fields,
  limit: limit,
  format: format,
  destinationLocal: destinationLocal,
);

void main() {
  group('119.23 brokered data access contract', () {
    test('declares the six canonical acceptance points in canonical order', () {
      expect(BrokeredDataAccessContract.canonicalStep, '119.23');
      expect(BrokeredDataAccessContract.requiredAcceptance, <String>[
        'scoped_handle',
        'query_contract',
        'export_contract',
        'audit',
        'revocation',
        'no_direct_database',
      ]);
      expect(BrokeredDataAccessContract.canonicalFields.keys, <ResourceKind>[
        ResourceKind.account,
        ResourceKind.project,
        ResourceKind.novel,
        ResourceKind.character,
        ResourceKind.workspace,
      ]);
    });

    test('canonical manifest satisfies the contract', () {
      final manifest = <String, dynamic>{
        'canonical_step': '119.23',
        'unknown_field_policy': 'REJECT',
        'acceptance': <String, dynamic>{
          'scoped_handle': <String, dynamic>{},
          'query_contract': <String, dynamic>{},
          'export_contract': <String, dynamic>{},
          'audit': <String, dynamic>{},
          'revocation': <String, dynamic>{},
          'no_direct_database': <String, dynamic>{},
        },
      };
      expect(BrokeredDataAccessContract.validateManifest(manifest), isEmpty);
    });

    test('manifest missing or reordering acceptance points is refused', () {
      final missing = <String, dynamic>{
        'canonical_step': '119.23',
        'unknown_field_policy': 'REJECT',
        'acceptance': <String, dynamic>{
          'scoped_handle': <String, dynamic>{},
          'query_contract': <String, dynamic>{},
          'export_contract': <String, dynamic>{},
          'audit': <String, dynamic>{},
          'revocation': <String, dynamic>{},
        },
      };
      expect(BrokeredDataAccessContract.validateManifest(missing), <String>[
        'acceptance_missing:no_direct_database',
      ]);

      final reordered = <String, dynamic>{
        'canonical_step': '119.23',
        'unknown_field_policy': 'REJECT',
        'acceptance': <String, dynamic>{
          'scoped_handle': <String, dynamic>{},
          'export_contract': <String, dynamic>{},
          'query_contract': <String, dynamic>{},
          'audit': <String, dynamic>{},
          'revocation': <String, dynamic>{},
          'no_direct_database': <String, dynamic>{},
        },
      };
      expect(BrokeredDataAccessContract.validateManifest(reordered), <String>[
        'acceptance_order_invalid',
      ]);
    });

    test(
      'a scope is declared with an opaque handle and an exact field set',
      () {
        expect(broker().diagnostics(), isEmpty);

        expect(
          broker(
            scopes: const <BrokeredScope>[
              BrokeredScope(
                handle: 'file:///var/lib/void/data.db',
                resource: ResourceKind.workspace,
                allowedFields: <String>['id'],
                permissionRef: permissionRef,
              ),
            ],
          ).diagnostics(),
          contains('handle_invalid'),
        );

        expect(
          broker(
            scopes: const <BrokeredScope>[
              BrokeredScope(
                handle: handle,
                resource: ResourceKind.unknown,
                allowedFields: <String>['id'],
                permissionRef: permissionRef,
              ),
            ],
          ).diagnostics(),
          contains('resource_unknown'),
        );

        expect(
          broker(
            scopes: const <BrokeredScope>[
              BrokeredScope(
                handle: handle,
                resource: ResourceKind.workspace,
                allowedFields: <String>['id', 'api_key'],
                permissionRef: permissionRef,
              ),
            ],
          ).diagnostics(),
          contains('scope_field_secret_refused'),
        );

        expect(
          broker(
            scopes: const <BrokeredScope>[
              BrokeredScope(
                handle: handle,
                resource: ResourceKind.workspace,
                allowedFields: <String>['id', 'internal_note'],
                permissionRef: permissionRef,
              ),
            ],
          ).diagnostics(),
          contains('scope_field_not_allowed:internal_note'),
        );

        expect(
          broker(
            scopes: const <BrokeredScope>[
              BrokeredScope(
                handle: handle,
                resource: ResourceKind.workspace,
                allowedFields: <String>[],
                permissionRef: permissionRef,
              ),
            ],
          ).diagnostics(),
          contains('scope_fields_empty'),
        );
      },
    );

    test('a well-formed query is accepted and honours the limit', () {
      final result = broker().query(query(limit: 2));

      expect(result.accepted, isTrue);
      expect(result.diagnostics, isEmpty);
      expect(result.rowCount, 2);
      expect(result.rows.first['id'], 'ws-1');
      expect(result.rows.first.keys.toSet(), <String>{
        'id',
        'name',
        'created_at',
      });
    });

    test('filters use a closed operator set', () {
      expect(
        broker()
            .query(
              query(
                filters: const <QueryFilter>[
                  QueryFilter(
                    field: 'name',
                    operator: QueryOperator.eq,
                    values: <String>['Beta Workspace'],
                  ),
                ],
              ),
            )
            .rows
            .single['id'],
        'ws-2',
      );

      expect(
        broker()
            .query(
              query(
                filters: const <QueryFilter>[
                  QueryFilter(
                    field: 'name',
                    operator: QueryOperator.prefix,
                    values: <String>['Alpha'],
                  ),
                ],
              ),
            )
            .rowCount,
        1,
      );

      expect(
        broker()
            .query(
              query(
                filters: const <QueryFilter>[
                  QueryFilter(
                    field: 'id',
                    operator: QueryOperator.inSet,
                    values: <String>['ws-1', 'ws-3'],
                  ),
                ],
              ),
            )
            .rowCount,
        2,
      );

      expect(
        broker()
            .query(
              query(
                filters: const <QueryFilter>[
                  QueryFilter(
                    field: 'created_at',
                    operator: QueryOperator.gte,
                    values: <String>['2026-02-01'],
                  ),
                ],
              ),
            )
            .rowCount,
        2,
      );
    });

    test('a field outside the allow-list is never reachable', () {
      final refused = broker().query(
        query(fields: <String>['id', 'internal_note']),
      );
      expect(refused.accepted, isFalse);
      expect(
        refused.diagnostics,
        contains('query_field_not_allowed:internal_note'),
      );

      final projected = broker().query(query());
      expect(projected.accepted, isTrue);
      for (final row in projected.rows) {
        expect(row.containsKey('internal_note'), isFalse);
      }

      final filtered = broker().query(
        query(
          filters: const <QueryFilter>[
            QueryFilter(
              field: 'internal_note',
              operator: QueryOperator.eq,
              values: <String>['not reachable'],
            ),
          ],
        ),
      );
      expect(filtered.accepted, isFalse);
      expect(
        filtered.diagnostics,
        contains('query_field_not_allowed:internal_note'),
      );
    });

    test('an unknown operator and a missing operand are refused', () {
      expect(
        broker()
            .query(
              query(
                filters: const <QueryFilter>[
                  QueryFilter(
                    field: 'name',
                    operator: QueryOperator.unknown,
                    values: <String>['x'],
                  ),
                ],
              ),
            )
            .diagnostics,
        contains('query_operator_unknown:name'),
      );

      expect(
        broker()
            .query(
              query(
                filters: const <QueryFilter>[
                  QueryFilter(field: 'name', operator: QueryOperator.eq),
                ],
              ),
            )
            .diagnostics,
        contains('query_filter_value_missing:name'),
      );
    });

    test('an expression-like operand is refused, not escaped', () {
      for (final String value in <String>[
        "Beta'; drop table workspaces;--",
        'select * from workspace',
        r'name || $1',
        r'{ "$gt": "" }',
      ]) {
        final result = broker().query(
          query(
            filters: <QueryFilter>[
              QueryFilter(
                field: 'name',
                operator: QueryOperator.eq,
                values: <String>[value],
              ),
            ],
          ),
        );
        expect(result.accepted, isFalse, reason: value);
        expect(
          result.diagnostics,
          contains('query_expression_refused:name'),
          reason: value,
        );
      }
    });

    test('the row limit is required to be inside the bound', () {
      expect(
        broker().query(query(limit: 0)).diagnostics,
        contains('query_limit_out_of_range'),
      );
      expect(
        broker().query(query(limit: 1001)).diagnostics,
        contains('query_limit_out_of_range'),
      );
      expect(
        broker().query(query(limit: QueryRequest.maxLimit)).accepted,
        isTrue,
      );
    });

    test('the cursor is opaque and resumes deterministically', () {
      expect(
        broker().query(query(cursor: 'ws-1')).diagnostics,
        contains('cursor_invalid'),
      );

      final resumed = broker().query(query(cursor: 'cursorref:ws-1'));
      expect(resumed.accepted, isTrue);
      expect(resumed.rows.map((Map<String, String> row) => row['id']), <String>[
        'ws-2',
        'ws-3',
      ]);

      expect(
        broker().query(query(cursor: 'cursorref:ws-9')).diagnostics,
        contains('cursor_unknown'),
      );
    });

    test('an export serializes only allowed fields', () {
      final json = broker().export(export());
      expect(json.accepted, isTrue);
      expect(json.payload, contains('ws-1'));
      expect(json.payload, isNot(contains('internal_note')));

      final csv = broker().export(
        export(
          fields: const <String>['id', 'created_at'],
          format: ExportFormat.csv,
        ),
      );
      expect(csv.accepted, isTrue);
      expect(csv.payload!.split('\n').first, 'id,created_at');
      expect(csv.payload, isNot(contains('internal_note')));
    });

    test('an export refuses a bad format, an empty or disallowed selection, a '
        'remote destination, and an out-of-range limit', () {
      expect(
        broker().export(export(format: ExportFormat.unknown)).diagnostics,
        contains('export_format_unknown'),
      );
      expect(
        broker().export(export(fields: const <String>[])).diagnostics,
        contains('export_fields_empty'),
      );
      expect(
        broker()
            .export(export(fields: const <String>['id', 'internal_note']))
            .diagnostics,
        contains('export_field_not_allowed:internal_note'),
      );
      expect(
        broker().export(export(destinationLocal: false)).diagnostics,
        contains('export_destination_not_local'),
      );
      expect(
        broker().export(export(limit: 0)).diagnostics,
        contains('export_limit_out_of_range'),
      );
    });

    test('a credential-bearing field can never be exported', () {
      final credentialScope = DataBroker(
        scopes: const <BrokeredScope>[
          BrokeredScope(
            handle: handle,
            resource: ResourceKind.account,
            allowedFields: <String>['id', 'api_key'],
            permissionRef: permissionRef,
          ),
        ],
        dataset: dataset,
        clock: () => t0,
      );

      final result = credentialScope.export(
        export(
          resource: ResourceKind.account,
          fields: const <String>['id', 'api_key'],
        ),
      );
      expect(result.accepted, isFalse);
      expect(
        result.diagnostics,
        contains('export_secret_field_refused:api_key'),
      );
    });

    test('an unknown or mismatched scope is refused before any read', () {
      expect(
        broker().query(query(handleRef: 'scoperef:alpha:other')).diagnostics,
        contains('scope_unknown'),
      );
      expect(
        broker().query(query(resource: ResourceKind.novel)).diagnostics,
        contains('scope_resource_mismatch'),
      );
    });

    test('revocation takes effect at once and is idempotent', () {
      final instance = broker();

      expect(instance.isRevoked(handle), isFalse);
      expect(instance.query(query()).accepted, isTrue);

      instance.revoke(handle);
      expect(instance.isRevoked(handle), isTrue);
      expect(instance.query(query()).diagnostics, contains('scope_revoked'));
      expect(instance.export(export()).diagnostics, contains('scope_revoked'));

      final afterFirstRevoke = instance.auditTrail.length;
      instance.revoke(handle);
      expect(instance.isRevoked(handle), isTrue);
      expect(instance.query(query()).diagnostics, contains('scope_revoked'));
      expect(instance.auditTrail.length, greaterThan(afterFirstRevoke));

      instance.revoke('scoperef:alpha:never-seen');
      expect(instance.isRevoked('scoperef:alpha:never-seen'), isTrue);
    });

    test('the audit trail is append-only and records refusals', () {
      final instance = broker();

      instance.query(query());
      instance.query(query(fields: <String>['internal_note']));
      instance.export(export());

      final trail = instance.auditTrail;
      expect(trail.length, 3);
      expect(trail.map((AuditEntry entry) => entry.sequence), <int>[1, 2, 3]);
      expect(trail[0].decision, isTrue);
      expect(trail[1].decision, isFalse);
      expect(trail[1].detail, contains('query_field_not_allowed'));
      expect(trail[2].action, 'export');

      final firstEntry = trail.first.toJson();
      expect(firstEntry['handle'], '[REDACTED]');
      expect(firstEntry['decision'], 'accepted');
      expect(firstEntry['resource'], 'workspace');

      instance.query(query(limit: 0));
      expect(instance.auditTrail.length, 4);
      expect(
        instance.auditTrail.first.toJson()['detail'],
        firstEntry['detail'],
      );

      expect(
        BrokeredDataAccessContract.redact(
          'failed scoperef:alpha:workspace-read',
        ),
        'failed [REDACTED]',
      );
    });

    test('no public member hands a caller direct storage access', () {
      for (final String member in DataBroker.publicSurface) {
        for (final String forbidden
            in BrokeredDataAccessContract.forbiddenSurface) {
          expect(
            member.contains(forbidden),
            isFalse,
            reason: '$member must not mention $forbidden',
          );
        }
      }

      expect(
        BrokeredDataAccessContract.isDirectStorageReference('file:///var/x.db'),
        isTrue,
      );
      expect(
        BrokeredDataAccessContract.isDirectStorageReference('/var/lib/x'),
        isTrue,
      );
      expect(
        BrokeredDataAccessContract.isDirectStorageReference(r'C:\data\x.db'),
        isTrue,
      );
      expect(
        BrokeredDataAccessContract.isDirectStorageReference('sqlite://x'),
        isTrue,
      );
      expect(
        BrokeredDataAccessContract.isDirectStorageReference(handle),
        isFalse,
      );
      expect(BrokeredDataAccessContract.isOpaqueHandle(handle), isTrue);
      expect(
        BrokeredDataAccessContract.isOpaqueHandle(
          'scoperef:alpha:workspace-read.db',
        ),
        isFalse,
      );
    });
  });
}
