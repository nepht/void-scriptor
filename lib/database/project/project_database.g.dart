// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_database.dart';

// ignore_for_file: type=lint
class $ProjectMetadataTable extends ProjectMetadata
    with TableInfo<$ProjectMetadataTable, ProjectMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'project_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProjectMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  ProjectMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProjectMetadataData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $ProjectMetadataTable createAlias(String alias) {
    return $ProjectMetadataTable(attachedDatabase, alias);
  }
}

class ProjectMetadataData extends DataClass
    implements Insertable<ProjectMetadataData> {
  final String key;
  final String value;
  const ProjectMetadataData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  ProjectMetadataCompanion toCompanion(bool nullToAbsent) {
    return ProjectMetadataCompanion(key: Value(key), value: Value(value));
  }

  factory ProjectMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProjectMetadataData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  ProjectMetadataData copyWith({String? key, String? value}) =>
      ProjectMetadataData(key: key ?? this.key, value: value ?? this.value);
  ProjectMetadataData copyWithCompanion(ProjectMetadataCompanion data) {
    return ProjectMetadataData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProjectMetadataData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProjectMetadataData &&
          other.key == this.key &&
          other.value == this.value);
}

class ProjectMetadataCompanion extends UpdateCompanion<ProjectMetadataData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const ProjectMetadataCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectMetadataCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<ProjectMetadataData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectMetadataCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return ProjectMetadataCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectMetadataCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ProjectDatabase extends GeneratedDatabase {
  _$ProjectDatabase(QueryExecutor e) : super(e);
  $ProjectDatabaseManager get managers => $ProjectDatabaseManager(this);
  late final $ProjectMetadataTable projectMetadata = $ProjectMetadataTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [projectMetadata];
}

typedef $$ProjectMetadataTableCreateCompanionBuilder =
    ProjectMetadataCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$ProjectMetadataTableUpdateCompanionBuilder =
    ProjectMetadataCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$ProjectMetadataTableFilterComposer
    extends Composer<_$ProjectDatabase, $ProjectMetadataTable> {
  $$ProjectMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProjectMetadataTableOrderingComposer
    extends Composer<_$ProjectDatabase, $ProjectMetadataTable> {
  $$ProjectMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProjectMetadataTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $ProjectMetadataTable> {
  $$ProjectMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$ProjectMetadataTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $ProjectMetadataTable,
          ProjectMetadataData,
          $$ProjectMetadataTableFilterComposer,
          $$ProjectMetadataTableOrderingComposer,
          $$ProjectMetadataTableAnnotationComposer,
          $$ProjectMetadataTableCreateCompanionBuilder,
          $$ProjectMetadataTableUpdateCompanionBuilder,
          (
            ProjectMetadataData,
            BaseReferences<
              _$ProjectDatabase,
              $ProjectMetadataTable,
              ProjectMetadataData
            >,
          ),
          ProjectMetadataData,
          PrefetchHooks Function()
        > {
  $$ProjectMetadataTableTableManager(
    _$ProjectDatabase db,
    $ProjectMetadataTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectMetadataCompanion(
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => ProjectMetadataCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProjectMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $ProjectMetadataTable,
      ProjectMetadataData,
      $$ProjectMetadataTableFilterComposer,
      $$ProjectMetadataTableOrderingComposer,
      $$ProjectMetadataTableAnnotationComposer,
      $$ProjectMetadataTableCreateCompanionBuilder,
      $$ProjectMetadataTableUpdateCompanionBuilder,
      (
        ProjectMetadataData,
        BaseReferences<
          _$ProjectDatabase,
          $ProjectMetadataTable,
          ProjectMetadataData
        >,
      ),
      ProjectMetadataData,
      PrefetchHooks Function()
    >;

class $ProjectDatabaseManager {
  final _$ProjectDatabase _db;
  $ProjectDatabaseManager(this._db);
  $$ProjectMetadataTableTableManager get projectMetadata =>
      $$ProjectMetadataTableTableManager(_db, _db.projectMetadata);
}
