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

class $AssetsTable extends Assets with TableInfo<$AssetsTable, Asset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('1.0.0'),
  );
  static const VerificationMeta _thumbnailPathMeta = const VerificationMeta(
    'thumbnailPath',
  );
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
    'thumbnail_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    name,
    description,
    type,
    version,
    thumbnailPath,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'assets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Asset> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
        _thumbnailPathMeta,
        thumbnailPath.isAcceptableOrUnknown(
          data['thumbnail_path']!,
          _thumbnailPathMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Asset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Asset(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      )!,
      thumbnailPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AssetsTable createAlias(String alias) {
    return $AssetsTable(attachedDatabase, alias);
  }
}

class Asset extends DataClass implements Insertable<Asset> {
  final String id;
  final String projectId;
  final String name;
  final String description;
  final String type;
  final String version;
  final String? thumbnailPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Asset({
    required this.id,
    required this.projectId,
    required this.name,
    required this.description,
    required this.type,
    required this.version,
    this.thumbnailPath,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['type'] = Variable<String>(type);
    map['version'] = Variable<String>(version);
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AssetsCompanion toCompanion(bool nullToAbsent) {
    return AssetsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      name: Value(name),
      description: Value(description),
      type: Value(type),
      version: Value(version),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Asset.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Asset(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      type: serializer.fromJson<String>(json['type']),
      version: serializer.fromJson<String>(json['version']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'type': serializer.toJson<String>(type),
      'version': serializer.toJson<String>(version),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Asset copyWith({
    String? id,
    String? projectId,
    String? name,
    String? description,
    String? type,
    String? version,
    Value<String?> thumbnailPath = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Asset(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    name: name ?? this.name,
    description: description ?? this.description,
    type: type ?? this.type,
    version: version ?? this.version,
    thumbnailPath: thumbnailPath.present
        ? thumbnailPath.value
        : this.thumbnailPath,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Asset copyWithCompanion(AssetsCompanion data) {
    return Asset(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      type: data.type.present ? data.type.value : this.type,
      version: data.version.present ? data.version.value : this.version,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Asset(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('version: $version, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    name,
    description,
    type,
    version,
    thumbnailPath,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Asset &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.name == this.name &&
          other.description == this.description &&
          other.type == this.type &&
          other.version == this.version &&
          other.thumbnailPath == this.thumbnailPath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AssetsCompanion extends UpdateCompanion<Asset> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> name;
  final Value<String> description;
  final Value<String> type;
  final Value<String> version;
  final Value<String?> thumbnailPath;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AssetsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.type = const Value.absent(),
    this.version = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssetsCompanion.insert({
    required String id,
    required String projectId,
    required String name,
    this.description = const Value.absent(),
    required String type,
    this.version = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       name = Value(name),
       type = Value(type),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Asset> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? type,
    Expression<String>? version,
    Expression<String>? thumbnailPath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (type != null) 'type': type,
      if (version != null) 'version': version,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssetsCompanion copyWith({
    Value<String>? id,
    Value<String>? projectId,
    Value<String>? name,
    Value<String>? description,
    Value<String>? type,
    Value<String>? version,
    Value<String?>? thumbnailPath,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AssetsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      version: version ?? this.version,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('version: $version, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssetTagsTable extends AssetTags
    with TableInfo<$AssetTagsTable, AssetTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, assetId, tag];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'asset_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssetTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('tag')) {
      context.handle(
        _tagMeta,
        tag.isAcceptableOrUnknown(data['tag']!, _tagMeta),
      );
    } else if (isInserting) {
      context.missing(_tagMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AssetTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssetTag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_id'],
      )!,
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      )!,
    );
  }

  @override
  $AssetTagsTable createAlias(String alias) {
    return $AssetTagsTable(attachedDatabase, alias);
  }
}

class AssetTag extends DataClass implements Insertable<AssetTag> {
  final int id;
  final String assetId;
  final String tag;
  const AssetTag({required this.id, required this.assetId, required this.tag});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['asset_id'] = Variable<String>(assetId);
    map['tag'] = Variable<String>(tag);
    return map;
  }

  AssetTagsCompanion toCompanion(bool nullToAbsent) {
    return AssetTagsCompanion(
      id: Value(id),
      assetId: Value(assetId),
      tag: Value(tag),
    );
  }

  factory AssetTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssetTag(
      id: serializer.fromJson<int>(json['id']),
      assetId: serializer.fromJson<String>(json['assetId']),
      tag: serializer.fromJson<String>(json['tag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'assetId': serializer.toJson<String>(assetId),
      'tag': serializer.toJson<String>(tag),
    };
  }

  AssetTag copyWith({int? id, String? assetId, String? tag}) => AssetTag(
    id: id ?? this.id,
    assetId: assetId ?? this.assetId,
    tag: tag ?? this.tag,
  );
  AssetTag copyWithCompanion(AssetTagsCompanion data) {
    return AssetTag(
      id: data.id.present ? data.id.value : this.id,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      tag: data.tag.present ? data.tag.value : this.tag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssetTag(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('tag: $tag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, assetId, tag);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetTag &&
          other.id == this.id &&
          other.assetId == this.assetId &&
          other.tag == this.tag);
}

class AssetTagsCompanion extends UpdateCompanion<AssetTag> {
  final Value<int> id;
  final Value<String> assetId;
  final Value<String> tag;
  const AssetTagsCompanion({
    this.id = const Value.absent(),
    this.assetId = const Value.absent(),
    this.tag = const Value.absent(),
  });
  AssetTagsCompanion.insert({
    this.id = const Value.absent(),
    required String assetId,
    required String tag,
  }) : assetId = Value(assetId),
       tag = Value(tag);
  static Insertable<AssetTag> custom({
    Expression<int>? id,
    Expression<String>? assetId,
    Expression<String>? tag,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (assetId != null) 'asset_id': assetId,
      if (tag != null) 'tag': tag,
    });
  }

  AssetTagsCompanion copyWith({
    Value<int>? id,
    Value<String>? assetId,
    Value<String>? tag,
  }) {
    return AssetTagsCompanion(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      tag: tag ?? this.tag,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetTagsCompanion(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('tag: $tag')
          ..write(')'))
        .toString();
  }
}

class $CharactersTable extends Characters
    with TableInfo<$CharactersTable, Character> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharactersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aliasMeta = const VerificationMeta('alias');
  @override
  late final GeneratedColumn<String> alias = GeneratedColumn<String>(
    'alias',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _biographyMeta = const VerificationMeta(
    'biography',
  );
  @override
  late final GeneratedColumn<String> biography = GeneratedColumn<String>(
    'biography',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _personalityMeta = const VerificationMeta(
    'personality',
  );
  @override
  late final GeneratedColumn<String> personality = GeneratedColumn<String>(
    'personality',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
    'gender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _ageMeta = const VerificationMeta('age');
  @override
  late final GeneratedColumn<int> age = GeneratedColumn<int>(
    'age',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightCmMeta = const VerificationMeta(
    'heightCm',
  );
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
    'height_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hairMeta = const VerificationMeta('hair');
  @override
  late final GeneratedColumn<String> hair = GeneratedColumn<String>(
    'hair',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _eyesMeta = const VerificationMeta('eyes');
  @override
  late final GeneratedColumn<String> eyes = GeneratedColumn<String>(
    'eyes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _skinMeta = const VerificationMeta('skin');
  @override
  late final GeneratedColumn<String> skin = GeneratedColumn<String>(
    'skin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    assetId,
    projectId,
    displayName,
    alias,
    biography,
    personality,
    gender,
    age,
    heightCm,
    hair,
    eyes,
    skin,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'characters';
  @override
  VerificationContext validateIntegrity(
    Insertable<Character> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('alias')) {
      context.handle(
        _aliasMeta,
        alias.isAcceptableOrUnknown(data['alias']!, _aliasMeta),
      );
    }
    if (data.containsKey('biography')) {
      context.handle(
        _biographyMeta,
        biography.isAcceptableOrUnknown(data['biography']!, _biographyMeta),
      );
    }
    if (data.containsKey('personality')) {
      context.handle(
        _personalityMeta,
        personality.isAcceptableOrUnknown(
          data['personality']!,
          _personalityMeta,
        ),
      );
    }
    if (data.containsKey('gender')) {
      context.handle(
        _genderMeta,
        gender.isAcceptableOrUnknown(data['gender']!, _genderMeta),
      );
    }
    if (data.containsKey('age')) {
      context.handle(
        _ageMeta,
        age.isAcceptableOrUnknown(data['age']!, _ageMeta),
      );
    }
    if (data.containsKey('height_cm')) {
      context.handle(
        _heightCmMeta,
        heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta),
      );
    }
    if (data.containsKey('hair')) {
      context.handle(
        _hairMeta,
        hair.isAcceptableOrUnknown(data['hair']!, _hairMeta),
      );
    }
    if (data.containsKey('eyes')) {
      context.handle(
        _eyesMeta,
        eyes.isAcceptableOrUnknown(data['eyes']!, _eyesMeta),
      );
    }
    if (data.containsKey('skin')) {
      context.handle(
        _skinMeta,
        skin.isAcceptableOrUnknown(data['skin']!, _skinMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {assetId};
  @override
  Character map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Character(
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      alias: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alias'],
      )!,
      biography: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}biography'],
      )!,
      personality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}personality'],
      )!,
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gender'],
      )!,
      age: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}age'],
      ),
      heightCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height_cm'],
      ),
      hair: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hair'],
      )!,
      eyes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}eyes'],
      )!,
      skin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}skin'],
      )!,
    );
  }

  @override
  $CharactersTable createAlias(String alias) {
    return $CharactersTable(attachedDatabase, alias);
  }
}

class Character extends DataClass implements Insertable<Character> {
  final String assetId;
  final String projectId;
  final String displayName;
  final String alias;
  final String biography;
  final String personality;
  final String gender;
  final int? age;
  final double? heightCm;
  final String hair;
  final String eyes;
  final String skin;
  const Character({
    required this.assetId,
    required this.projectId,
    required this.displayName,
    required this.alias,
    required this.biography,
    required this.personality,
    required this.gender,
    this.age,
    this.heightCm,
    required this.hair,
    required this.eyes,
    required this.skin,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['asset_id'] = Variable<String>(assetId);
    map['project_id'] = Variable<String>(projectId);
    map['display_name'] = Variable<String>(displayName);
    map['alias'] = Variable<String>(alias);
    map['biography'] = Variable<String>(biography);
    map['personality'] = Variable<String>(personality);
    map['gender'] = Variable<String>(gender);
    if (!nullToAbsent || age != null) {
      map['age'] = Variable<int>(age);
    }
    if (!nullToAbsent || heightCm != null) {
      map['height_cm'] = Variable<double>(heightCm);
    }
    map['hair'] = Variable<String>(hair);
    map['eyes'] = Variable<String>(eyes);
    map['skin'] = Variable<String>(skin);
    return map;
  }

  CharactersCompanion toCompanion(bool nullToAbsent) {
    return CharactersCompanion(
      assetId: Value(assetId),
      projectId: Value(projectId),
      displayName: Value(displayName),
      alias: Value(alias),
      biography: Value(biography),
      personality: Value(personality),
      gender: Value(gender),
      age: age == null && nullToAbsent ? const Value.absent() : Value(age),
      heightCm: heightCm == null && nullToAbsent
          ? const Value.absent()
          : Value(heightCm),
      hair: Value(hair),
      eyes: Value(eyes),
      skin: Value(skin),
    );
  }

  factory Character.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Character(
      assetId: serializer.fromJson<String>(json['assetId']),
      projectId: serializer.fromJson<String>(json['projectId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      alias: serializer.fromJson<String>(json['alias']),
      biography: serializer.fromJson<String>(json['biography']),
      personality: serializer.fromJson<String>(json['personality']),
      gender: serializer.fromJson<String>(json['gender']),
      age: serializer.fromJson<int?>(json['age']),
      heightCm: serializer.fromJson<double?>(json['heightCm']),
      hair: serializer.fromJson<String>(json['hair']),
      eyes: serializer.fromJson<String>(json['eyes']),
      skin: serializer.fromJson<String>(json['skin']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'assetId': serializer.toJson<String>(assetId),
      'projectId': serializer.toJson<String>(projectId),
      'displayName': serializer.toJson<String>(displayName),
      'alias': serializer.toJson<String>(alias),
      'biography': serializer.toJson<String>(biography),
      'personality': serializer.toJson<String>(personality),
      'gender': serializer.toJson<String>(gender),
      'age': serializer.toJson<int?>(age),
      'heightCm': serializer.toJson<double?>(heightCm),
      'hair': serializer.toJson<String>(hair),
      'eyes': serializer.toJson<String>(eyes),
      'skin': serializer.toJson<String>(skin),
    };
  }

  Character copyWith({
    String? assetId,
    String? projectId,
    String? displayName,
    String? alias,
    String? biography,
    String? personality,
    String? gender,
    Value<int?> age = const Value.absent(),
    Value<double?> heightCm = const Value.absent(),
    String? hair,
    String? eyes,
    String? skin,
  }) => Character(
    assetId: assetId ?? this.assetId,
    projectId: projectId ?? this.projectId,
    displayName: displayName ?? this.displayName,
    alias: alias ?? this.alias,
    biography: biography ?? this.biography,
    personality: personality ?? this.personality,
    gender: gender ?? this.gender,
    age: age.present ? age.value : this.age,
    heightCm: heightCm.present ? heightCm.value : this.heightCm,
    hair: hair ?? this.hair,
    eyes: eyes ?? this.eyes,
    skin: skin ?? this.skin,
  );
  Character copyWithCompanion(CharactersCompanion data) {
    return Character(
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      alias: data.alias.present ? data.alias.value : this.alias,
      biography: data.biography.present ? data.biography.value : this.biography,
      personality: data.personality.present
          ? data.personality.value
          : this.personality,
      gender: data.gender.present ? data.gender.value : this.gender,
      age: data.age.present ? data.age.value : this.age,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      hair: data.hair.present ? data.hair.value : this.hair,
      eyes: data.eyes.present ? data.eyes.value : this.eyes,
      skin: data.skin.present ? data.skin.value : this.skin,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Character(')
          ..write('assetId: $assetId, ')
          ..write('projectId: $projectId, ')
          ..write('displayName: $displayName, ')
          ..write('alias: $alias, ')
          ..write('biography: $biography, ')
          ..write('personality: $personality, ')
          ..write('gender: $gender, ')
          ..write('age: $age, ')
          ..write('heightCm: $heightCm, ')
          ..write('hair: $hair, ')
          ..write('eyes: $eyes, ')
          ..write('skin: $skin')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    assetId,
    projectId,
    displayName,
    alias,
    biography,
    personality,
    gender,
    age,
    heightCm,
    hair,
    eyes,
    skin,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Character &&
          other.assetId == this.assetId &&
          other.projectId == this.projectId &&
          other.displayName == this.displayName &&
          other.alias == this.alias &&
          other.biography == this.biography &&
          other.personality == this.personality &&
          other.gender == this.gender &&
          other.age == this.age &&
          other.heightCm == this.heightCm &&
          other.hair == this.hair &&
          other.eyes == this.eyes &&
          other.skin == this.skin);
}

class CharactersCompanion extends UpdateCompanion<Character> {
  final Value<String> assetId;
  final Value<String> projectId;
  final Value<String> displayName;
  final Value<String> alias;
  final Value<String> biography;
  final Value<String> personality;
  final Value<String> gender;
  final Value<int?> age;
  final Value<double?> heightCm;
  final Value<String> hair;
  final Value<String> eyes;
  final Value<String> skin;
  final Value<int> rowid;
  const CharactersCompanion({
    this.assetId = const Value.absent(),
    this.projectId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.alias = const Value.absent(),
    this.biography = const Value.absent(),
    this.personality = const Value.absent(),
    this.gender = const Value.absent(),
    this.age = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.hair = const Value.absent(),
    this.eyes = const Value.absent(),
    this.skin = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CharactersCompanion.insert({
    required String assetId,
    required String projectId,
    required String displayName,
    this.alias = const Value.absent(),
    this.biography = const Value.absent(),
    this.personality = const Value.absent(),
    this.gender = const Value.absent(),
    this.age = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.hair = const Value.absent(),
    this.eyes = const Value.absent(),
    this.skin = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : assetId = Value(assetId),
       projectId = Value(projectId),
       displayName = Value(displayName);
  static Insertable<Character> custom({
    Expression<String>? assetId,
    Expression<String>? projectId,
    Expression<String>? displayName,
    Expression<String>? alias,
    Expression<String>? biography,
    Expression<String>? personality,
    Expression<String>? gender,
    Expression<int>? age,
    Expression<double>? heightCm,
    Expression<String>? hair,
    Expression<String>? eyes,
    Expression<String>? skin,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (assetId != null) 'asset_id': assetId,
      if (projectId != null) 'project_id': projectId,
      if (displayName != null) 'display_name': displayName,
      if (alias != null) 'alias': alias,
      if (biography != null) 'biography': biography,
      if (personality != null) 'personality': personality,
      if (gender != null) 'gender': gender,
      if (age != null) 'age': age,
      if (heightCm != null) 'height_cm': heightCm,
      if (hair != null) 'hair': hair,
      if (eyes != null) 'eyes': eyes,
      if (skin != null) 'skin': skin,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CharactersCompanion copyWith({
    Value<String>? assetId,
    Value<String>? projectId,
    Value<String>? displayName,
    Value<String>? alias,
    Value<String>? biography,
    Value<String>? personality,
    Value<String>? gender,
    Value<int?>? age,
    Value<double?>? heightCm,
    Value<String>? hair,
    Value<String>? eyes,
    Value<String>? skin,
    Value<int>? rowid,
  }) {
    return CharactersCompanion(
      assetId: assetId ?? this.assetId,
      projectId: projectId ?? this.projectId,
      displayName: displayName ?? this.displayName,
      alias: alias ?? this.alias,
      biography: biography ?? this.biography,
      personality: personality ?? this.personality,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      hair: hair ?? this.hair,
      eyes: eyes ?? this.eyes,
      skin: skin ?? this.skin,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (alias.present) {
      map['alias'] = Variable<String>(alias.value);
    }
    if (biography.present) {
      map['biography'] = Variable<String>(biography.value);
    }
    if (personality.present) {
      map['personality'] = Variable<String>(personality.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (age.present) {
      map['age'] = Variable<int>(age.value);
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (hair.present) {
      map['hair'] = Variable<String>(hair.value);
    }
    if (eyes.present) {
      map['eyes'] = Variable<String>(eyes.value);
    }
    if (skin.present) {
      map['skin'] = Variable<String>(skin.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharactersCompanion(')
          ..write('assetId: $assetId, ')
          ..write('projectId: $projectId, ')
          ..write('displayName: $displayName, ')
          ..write('alias: $alias, ')
          ..write('biography: $biography, ')
          ..write('personality: $personality, ')
          ..write('gender: $gender, ')
          ..write('age: $age, ')
          ..write('heightCm: $heightCm, ')
          ..write('hair: $hair, ')
          ..write('eyes: $eyes, ')
          ..write('skin: $skin, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CharacterIdentityProfilesTable extends CharacterIdentityProfiles
    with TableInfo<$CharacterIdentityProfilesTable, CharacterIdentityProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharacterIdentityProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _characterIdMeta = const VerificationMeta(
    'characterId',
  );
  @override
  late final GeneratedColumn<String> characterId = GeneratedColumn<String>(
    'character_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _faceLockMeta = const VerificationMeta(
    'faceLock',
  );
  @override
  late final GeneratedColumn<bool> faceLock = GeneratedColumn<bool>(
    'face_lock',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("face_lock" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _hairLockMeta = const VerificationMeta(
    'hairLock',
  );
  @override
  late final GeneratedColumn<bool> hairLock = GeneratedColumn<bool>(
    'hair_lock',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hair_lock" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _bodyLockMeta = const VerificationMeta(
    'bodyLock',
  );
  @override
  late final GeneratedColumn<bool> bodyLock = GeneratedColumn<bool>(
    'body_lock',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("body_lock" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _colorLockMeta = const VerificationMeta(
    'colorLock',
  );
  @override
  late final GeneratedColumn<bool> colorLock = GeneratedColumn<bool>(
    'color_lock',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("color_lock" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _outfitLockMeta = const VerificationMeta(
    'outfitLock',
  );
  @override
  late final GeneratedColumn<bool> outfitLock = GeneratedColumn<bool>(
    'outfit_lock',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("outfit_lock" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _weaponLockMeta = const VerificationMeta(
    'weaponLock',
  );
  @override
  late final GeneratedColumn<bool> weaponLock = GeneratedColumn<bool>(
    'weapon_lock',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("weapon_lock" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    characterId,
    faceLock,
    hairLock,
    bodyLock,
    colorLock,
    outfitLock,
    weaponLock,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'character_identity_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<CharacterIdentityProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('character_id')) {
      context.handle(
        _characterIdMeta,
        characterId.isAcceptableOrUnknown(
          data['character_id']!,
          _characterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('face_lock')) {
      context.handle(
        _faceLockMeta,
        faceLock.isAcceptableOrUnknown(data['face_lock']!, _faceLockMeta),
      );
    }
    if (data.containsKey('hair_lock')) {
      context.handle(
        _hairLockMeta,
        hairLock.isAcceptableOrUnknown(data['hair_lock']!, _hairLockMeta),
      );
    }
    if (data.containsKey('body_lock')) {
      context.handle(
        _bodyLockMeta,
        bodyLock.isAcceptableOrUnknown(data['body_lock']!, _bodyLockMeta),
      );
    }
    if (data.containsKey('color_lock')) {
      context.handle(
        _colorLockMeta,
        colorLock.isAcceptableOrUnknown(data['color_lock']!, _colorLockMeta),
      );
    }
    if (data.containsKey('outfit_lock')) {
      context.handle(
        _outfitLockMeta,
        outfitLock.isAcceptableOrUnknown(data['outfit_lock']!, _outfitLockMeta),
      );
    }
    if (data.containsKey('weapon_lock')) {
      context.handle(
        _weaponLockMeta,
        weaponLock.isAcceptableOrUnknown(data['weapon_lock']!, _weaponLockMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {characterId};
  @override
  CharacterIdentityProfile map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CharacterIdentityProfile(
      characterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character_id'],
      )!,
      faceLock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}face_lock'],
      )!,
      hairLock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hair_lock'],
      )!,
      bodyLock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}body_lock'],
      )!,
      colorLock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}color_lock'],
      )!,
      outfitLock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}outfit_lock'],
      )!,
      weaponLock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}weapon_lock'],
      )!,
    );
  }

  @override
  $CharacterIdentityProfilesTable createAlias(String alias) {
    return $CharacterIdentityProfilesTable(attachedDatabase, alias);
  }
}

class CharacterIdentityProfile extends DataClass
    implements Insertable<CharacterIdentityProfile> {
  final String characterId;
  final bool faceLock;
  final bool hairLock;
  final bool bodyLock;
  final bool colorLock;
  final bool outfitLock;
  final bool weaponLock;
  const CharacterIdentityProfile({
    required this.characterId,
    required this.faceLock,
    required this.hairLock,
    required this.bodyLock,
    required this.colorLock,
    required this.outfitLock,
    required this.weaponLock,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['character_id'] = Variable<String>(characterId);
    map['face_lock'] = Variable<bool>(faceLock);
    map['hair_lock'] = Variable<bool>(hairLock);
    map['body_lock'] = Variable<bool>(bodyLock);
    map['color_lock'] = Variable<bool>(colorLock);
    map['outfit_lock'] = Variable<bool>(outfitLock);
    map['weapon_lock'] = Variable<bool>(weaponLock);
    return map;
  }

  CharacterIdentityProfilesCompanion toCompanion(bool nullToAbsent) {
    return CharacterIdentityProfilesCompanion(
      characterId: Value(characterId),
      faceLock: Value(faceLock),
      hairLock: Value(hairLock),
      bodyLock: Value(bodyLock),
      colorLock: Value(colorLock),
      outfitLock: Value(outfitLock),
      weaponLock: Value(weaponLock),
    );
  }

  factory CharacterIdentityProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CharacterIdentityProfile(
      characterId: serializer.fromJson<String>(json['characterId']),
      faceLock: serializer.fromJson<bool>(json['faceLock']),
      hairLock: serializer.fromJson<bool>(json['hairLock']),
      bodyLock: serializer.fromJson<bool>(json['bodyLock']),
      colorLock: serializer.fromJson<bool>(json['colorLock']),
      outfitLock: serializer.fromJson<bool>(json['outfitLock']),
      weaponLock: serializer.fromJson<bool>(json['weaponLock']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'characterId': serializer.toJson<String>(characterId),
      'faceLock': serializer.toJson<bool>(faceLock),
      'hairLock': serializer.toJson<bool>(hairLock),
      'bodyLock': serializer.toJson<bool>(bodyLock),
      'colorLock': serializer.toJson<bool>(colorLock),
      'outfitLock': serializer.toJson<bool>(outfitLock),
      'weaponLock': serializer.toJson<bool>(weaponLock),
    };
  }

  CharacterIdentityProfile copyWith({
    String? characterId,
    bool? faceLock,
    bool? hairLock,
    bool? bodyLock,
    bool? colorLock,
    bool? outfitLock,
    bool? weaponLock,
  }) => CharacterIdentityProfile(
    characterId: characterId ?? this.characterId,
    faceLock: faceLock ?? this.faceLock,
    hairLock: hairLock ?? this.hairLock,
    bodyLock: bodyLock ?? this.bodyLock,
    colorLock: colorLock ?? this.colorLock,
    outfitLock: outfitLock ?? this.outfitLock,
    weaponLock: weaponLock ?? this.weaponLock,
  );
  CharacterIdentityProfile copyWithCompanion(
    CharacterIdentityProfilesCompanion data,
  ) {
    return CharacterIdentityProfile(
      characterId: data.characterId.present
          ? data.characterId.value
          : this.characterId,
      faceLock: data.faceLock.present ? data.faceLock.value : this.faceLock,
      hairLock: data.hairLock.present ? data.hairLock.value : this.hairLock,
      bodyLock: data.bodyLock.present ? data.bodyLock.value : this.bodyLock,
      colorLock: data.colorLock.present ? data.colorLock.value : this.colorLock,
      outfitLock: data.outfitLock.present
          ? data.outfitLock.value
          : this.outfitLock,
      weaponLock: data.weaponLock.present
          ? data.weaponLock.value
          : this.weaponLock,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CharacterIdentityProfile(')
          ..write('characterId: $characterId, ')
          ..write('faceLock: $faceLock, ')
          ..write('hairLock: $hairLock, ')
          ..write('bodyLock: $bodyLock, ')
          ..write('colorLock: $colorLock, ')
          ..write('outfitLock: $outfitLock, ')
          ..write('weaponLock: $weaponLock')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    characterId,
    faceLock,
    hairLock,
    bodyLock,
    colorLock,
    outfitLock,
    weaponLock,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CharacterIdentityProfile &&
          other.characterId == this.characterId &&
          other.faceLock == this.faceLock &&
          other.hairLock == this.hairLock &&
          other.bodyLock == this.bodyLock &&
          other.colorLock == this.colorLock &&
          other.outfitLock == this.outfitLock &&
          other.weaponLock == this.weaponLock);
}

class CharacterIdentityProfilesCompanion
    extends UpdateCompanion<CharacterIdentityProfile> {
  final Value<String> characterId;
  final Value<bool> faceLock;
  final Value<bool> hairLock;
  final Value<bool> bodyLock;
  final Value<bool> colorLock;
  final Value<bool> outfitLock;
  final Value<bool> weaponLock;
  final Value<int> rowid;
  const CharacterIdentityProfilesCompanion({
    this.characterId = const Value.absent(),
    this.faceLock = const Value.absent(),
    this.hairLock = const Value.absent(),
    this.bodyLock = const Value.absent(),
    this.colorLock = const Value.absent(),
    this.outfitLock = const Value.absent(),
    this.weaponLock = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CharacterIdentityProfilesCompanion.insert({
    required String characterId,
    this.faceLock = const Value.absent(),
    this.hairLock = const Value.absent(),
    this.bodyLock = const Value.absent(),
    this.colorLock = const Value.absent(),
    this.outfitLock = const Value.absent(),
    this.weaponLock = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : characterId = Value(characterId);
  static Insertable<CharacterIdentityProfile> custom({
    Expression<String>? characterId,
    Expression<bool>? faceLock,
    Expression<bool>? hairLock,
    Expression<bool>? bodyLock,
    Expression<bool>? colorLock,
    Expression<bool>? outfitLock,
    Expression<bool>? weaponLock,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (characterId != null) 'character_id': characterId,
      if (faceLock != null) 'face_lock': faceLock,
      if (hairLock != null) 'hair_lock': hairLock,
      if (bodyLock != null) 'body_lock': bodyLock,
      if (colorLock != null) 'color_lock': colorLock,
      if (outfitLock != null) 'outfit_lock': outfitLock,
      if (weaponLock != null) 'weapon_lock': weaponLock,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CharacterIdentityProfilesCompanion copyWith({
    Value<String>? characterId,
    Value<bool>? faceLock,
    Value<bool>? hairLock,
    Value<bool>? bodyLock,
    Value<bool>? colorLock,
    Value<bool>? outfitLock,
    Value<bool>? weaponLock,
    Value<int>? rowid,
  }) {
    return CharacterIdentityProfilesCompanion(
      characterId: characterId ?? this.characterId,
      faceLock: faceLock ?? this.faceLock,
      hairLock: hairLock ?? this.hairLock,
      bodyLock: bodyLock ?? this.bodyLock,
      colorLock: colorLock ?? this.colorLock,
      outfitLock: outfitLock ?? this.outfitLock,
      weaponLock: weaponLock ?? this.weaponLock,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (characterId.present) {
      map['character_id'] = Variable<String>(characterId.value);
    }
    if (faceLock.present) {
      map['face_lock'] = Variable<bool>(faceLock.value);
    }
    if (hairLock.present) {
      map['hair_lock'] = Variable<bool>(hairLock.value);
    }
    if (bodyLock.present) {
      map['body_lock'] = Variable<bool>(bodyLock.value);
    }
    if (colorLock.present) {
      map['color_lock'] = Variable<bool>(colorLock.value);
    }
    if (outfitLock.present) {
      map['outfit_lock'] = Variable<bool>(outfitLock.value);
    }
    if (weaponLock.present) {
      map['weapon_lock'] = Variable<bool>(weaponLock.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharacterIdentityProfilesCompanion(')
          ..write('characterId: $characterId, ')
          ..write('faceLock: $faceLock, ')
          ..write('hairLock: $hairLock, ')
          ..write('bodyLock: $bodyLock, ')
          ..write('colorLock: $colorLock, ')
          ..write('outfitLock: $outfitLock, ')
          ..write('weaponLock: $weaponLock, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CharacterReferencesTable extends CharacterReferences
    with TableInfo<$CharacterReferencesTable, CharacterReference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharacterReferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _characterIdMeta = const VerificationMeta(
    'characterId',
  );
  @override
  late final GeneratedColumn<String> characterId = GeneratedColumn<String>(
    'character_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _primaryReferenceMeta = const VerificationMeta(
    'primaryReference',
  );
  @override
  late final GeneratedColumn<bool> primaryReference = GeneratedColumn<bool>(
    'primary_reference',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("primary_reference" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    characterId,
    type,
    filePath,
    priority,
    primaryReference,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'character_references';
  @override
  VerificationContext validateIntegrity(
    Insertable<CharacterReference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('character_id')) {
      context.handle(
        _characterIdMeta,
        characterId.isAcceptableOrUnknown(
          data['character_id']!,
          _characterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('primary_reference')) {
      context.handle(
        _primaryReferenceMeta,
        primaryReference.isAcceptableOrUnknown(
          data['primary_reference']!,
          _primaryReferenceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CharacterReference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CharacterReference(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      characterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      primaryReference: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}primary_reference'],
      )!,
    );
  }

  @override
  $CharacterReferencesTable createAlias(String alias) {
    return $CharacterReferencesTable(attachedDatabase, alias);
  }
}

class CharacterReference extends DataClass
    implements Insertable<CharacterReference> {
  final String id;
  final String characterId;
  final String type;
  final String filePath;
  final int priority;
  final bool primaryReference;
  const CharacterReference({
    required this.id,
    required this.characterId,
    required this.type,
    required this.filePath,
    required this.priority,
    required this.primaryReference,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['character_id'] = Variable<String>(characterId);
    map['type'] = Variable<String>(type);
    map['file_path'] = Variable<String>(filePath);
    map['priority'] = Variable<int>(priority);
    map['primary_reference'] = Variable<bool>(primaryReference);
    return map;
  }

  CharacterReferencesCompanion toCompanion(bool nullToAbsent) {
    return CharacterReferencesCompanion(
      id: Value(id),
      characterId: Value(characterId),
      type: Value(type),
      filePath: Value(filePath),
      priority: Value(priority),
      primaryReference: Value(primaryReference),
    );
  }

  factory CharacterReference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CharacterReference(
      id: serializer.fromJson<String>(json['id']),
      characterId: serializer.fromJson<String>(json['characterId']),
      type: serializer.fromJson<String>(json['type']),
      filePath: serializer.fromJson<String>(json['filePath']),
      priority: serializer.fromJson<int>(json['priority']),
      primaryReference: serializer.fromJson<bool>(json['primaryReference']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'characterId': serializer.toJson<String>(characterId),
      'type': serializer.toJson<String>(type),
      'filePath': serializer.toJson<String>(filePath),
      'priority': serializer.toJson<int>(priority),
      'primaryReference': serializer.toJson<bool>(primaryReference),
    };
  }

  CharacterReference copyWith({
    String? id,
    String? characterId,
    String? type,
    String? filePath,
    int? priority,
    bool? primaryReference,
  }) => CharacterReference(
    id: id ?? this.id,
    characterId: characterId ?? this.characterId,
    type: type ?? this.type,
    filePath: filePath ?? this.filePath,
    priority: priority ?? this.priority,
    primaryReference: primaryReference ?? this.primaryReference,
  );
  CharacterReference copyWithCompanion(CharacterReferencesCompanion data) {
    return CharacterReference(
      id: data.id.present ? data.id.value : this.id,
      characterId: data.characterId.present
          ? data.characterId.value
          : this.characterId,
      type: data.type.present ? data.type.value : this.type,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      priority: data.priority.present ? data.priority.value : this.priority,
      primaryReference: data.primaryReference.present
          ? data.primaryReference.value
          : this.primaryReference,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CharacterReference(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('type: $type, ')
          ..write('filePath: $filePath, ')
          ..write('priority: $priority, ')
          ..write('primaryReference: $primaryReference')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, characterId, type, filePath, priority, primaryReference);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CharacterReference &&
          other.id == this.id &&
          other.characterId == this.characterId &&
          other.type == this.type &&
          other.filePath == this.filePath &&
          other.priority == this.priority &&
          other.primaryReference == this.primaryReference);
}

class CharacterReferencesCompanion extends UpdateCompanion<CharacterReference> {
  final Value<String> id;
  final Value<String> characterId;
  final Value<String> type;
  final Value<String> filePath;
  final Value<int> priority;
  final Value<bool> primaryReference;
  final Value<int> rowid;
  const CharacterReferencesCompanion({
    this.id = const Value.absent(),
    this.characterId = const Value.absent(),
    this.type = const Value.absent(),
    this.filePath = const Value.absent(),
    this.priority = const Value.absent(),
    this.primaryReference = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CharacterReferencesCompanion.insert({
    required String id,
    required String characterId,
    required String type,
    required String filePath,
    this.priority = const Value.absent(),
    this.primaryReference = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       characterId = Value(characterId),
       type = Value(type),
       filePath = Value(filePath);
  static Insertable<CharacterReference> custom({
    Expression<String>? id,
    Expression<String>? characterId,
    Expression<String>? type,
    Expression<String>? filePath,
    Expression<int>? priority,
    Expression<bool>? primaryReference,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (characterId != null) 'character_id': characterId,
      if (type != null) 'type': type,
      if (filePath != null) 'file_path': filePath,
      if (priority != null) 'priority': priority,
      if (primaryReference != null) 'primary_reference': primaryReference,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CharacterReferencesCompanion copyWith({
    Value<String>? id,
    Value<String>? characterId,
    Value<String>? type,
    Value<String>? filePath,
    Value<int>? priority,
    Value<bool>? primaryReference,
    Value<int>? rowid,
  }) {
    return CharacterReferencesCompanion(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      type: type ?? this.type,
      filePath: filePath ?? this.filePath,
      priority: priority ?? this.priority,
      primaryReference: primaryReference ?? this.primaryReference,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (characterId.present) {
      map['character_id'] = Variable<String>(characterId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (primaryReference.present) {
      map['primary_reference'] = Variable<bool>(primaryReference.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharacterReferencesCompanion(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('type: $type, ')
          ..write('filePath: $filePath, ')
          ..write('priority: $priority, ')
          ..write('primaryReference: $primaryReference, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CharacterModesTable extends CharacterModes
    with TableInfo<$CharacterModesTable, CharacterMode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharacterModesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _characterIdMeta = const VerificationMeta(
    'characterId',
  );
  @override
  late final GeneratedColumn<String> characterId = GeneratedColumn<String>(
    'character_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _thumbnailPathMeta = const VerificationMeta(
    'thumbnailPath',
  );
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
    'thumbnail_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accentColorMeta = const VerificationMeta(
    'accentColor',
  );
  @override
  late final GeneratedColumn<String> accentColor = GeneratedColumn<String>(
    'accent_color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    characterId,
    name,
    description,
    isDefault,
    thumbnailPath,
    accentColor,
    tagsJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'character_modes';
  @override
  VerificationContext validateIntegrity(
    Insertable<CharacterMode> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('character_id')) {
      context.handle(
        _characterIdMeta,
        characterId.isAcceptableOrUnknown(
          data['character_id']!,
          _characterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
        _thumbnailPathMeta,
        thumbnailPath.isAcceptableOrUnknown(
          data['thumbnail_path']!,
          _thumbnailPathMeta,
        ),
      );
    }
    if (data.containsKey('accent_color')) {
      context.handle(
        _accentColorMeta,
        accentColor.isAcceptableOrUnknown(
          data['accent_color']!,
          _accentColorMeta,
        ),
      );
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CharacterMode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CharacterMode(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      characterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      thumbnailPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_path'],
      ),
      accentColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}accent_color'],
      ),
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CharacterModesTable createAlias(String alias) {
    return $CharacterModesTable(attachedDatabase, alias);
  }
}

class CharacterMode extends DataClass implements Insertable<CharacterMode> {
  final String id;
  final String projectId;
  final String characterId;
  final String name;
  final String description;
  final bool isDefault;
  final String? thumbnailPath;
  final String? accentColor;
  final String tagsJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CharacterMode({
    required this.id,
    required this.projectId,
    required this.characterId,
    required this.name,
    required this.description,
    required this.isDefault,
    this.thumbnailPath,
    this.accentColor,
    required this.tagsJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['character_id'] = Variable<String>(characterId);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['is_default'] = Variable<bool>(isDefault);
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    if (!nullToAbsent || accentColor != null) {
      map['accent_color'] = Variable<String>(accentColor);
    }
    map['tags_json'] = Variable<String>(tagsJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CharacterModesCompanion toCompanion(bool nullToAbsent) {
    return CharacterModesCompanion(
      id: Value(id),
      projectId: Value(projectId),
      characterId: Value(characterId),
      name: Value(name),
      description: Value(description),
      isDefault: Value(isDefault),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      accentColor: accentColor == null && nullToAbsent
          ? const Value.absent()
          : Value(accentColor),
      tagsJson: Value(tagsJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CharacterMode.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CharacterMode(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      characterId: serializer.fromJson<String>(json['characterId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      accentColor: serializer.fromJson<String?>(json['accentColor']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'characterId': serializer.toJson<String>(characterId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'isDefault': serializer.toJson<bool>(isDefault),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'accentColor': serializer.toJson<String?>(accentColor),
      'tagsJson': serializer.toJson<String>(tagsJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CharacterMode copyWith({
    String? id,
    String? projectId,
    String? characterId,
    String? name,
    String? description,
    bool? isDefault,
    Value<String?> thumbnailPath = const Value.absent(),
    Value<String?> accentColor = const Value.absent(),
    String? tagsJson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CharacterMode(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    characterId: characterId ?? this.characterId,
    name: name ?? this.name,
    description: description ?? this.description,
    isDefault: isDefault ?? this.isDefault,
    thumbnailPath: thumbnailPath.present
        ? thumbnailPath.value
        : this.thumbnailPath,
    accentColor: accentColor.present ? accentColor.value : this.accentColor,
    tagsJson: tagsJson ?? this.tagsJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CharacterMode copyWithCompanion(CharacterModesCompanion data) {
    return CharacterMode(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      characterId: data.characterId.present
          ? data.characterId.value
          : this.characterId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      accentColor: data.accentColor.present
          ? data.accentColor.value
          : this.accentColor,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CharacterMode(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('characterId: $characterId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('isDefault: $isDefault, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('accentColor: $accentColor, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    characterId,
    name,
    description,
    isDefault,
    thumbnailPath,
    accentColor,
    tagsJson,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CharacterMode &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.characterId == this.characterId &&
          other.name == this.name &&
          other.description == this.description &&
          other.isDefault == this.isDefault &&
          other.thumbnailPath == this.thumbnailPath &&
          other.accentColor == this.accentColor &&
          other.tagsJson == this.tagsJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CharacterModesCompanion extends UpdateCompanion<CharacterMode> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> characterId;
  final Value<String> name;
  final Value<String> description;
  final Value<bool> isDefault;
  final Value<String?> thumbnailPath;
  final Value<String?> accentColor;
  final Value<String> tagsJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CharacterModesCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.characterId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.accentColor = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CharacterModesCompanion.insert({
    required String id,
    required String projectId,
    required String characterId,
    required String name,
    this.description = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.accentColor = const Value.absent(),
    this.tagsJson = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       characterId = Value(characterId),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CharacterMode> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? characterId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<bool>? isDefault,
    Expression<String>? thumbnailPath,
    Expression<String>? accentColor,
    Expression<String>? tagsJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (characterId != null) 'character_id': characterId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (isDefault != null) 'is_default': isDefault,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (accentColor != null) 'accent_color': accentColor,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CharacterModesCompanion copyWith({
    Value<String>? id,
    Value<String>? projectId,
    Value<String>? characterId,
    Value<String>? name,
    Value<String>? description,
    Value<bool>? isDefault,
    Value<String?>? thumbnailPath,
    Value<String?>? accentColor,
    Value<String>? tagsJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CharacterModesCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      characterId: characterId ?? this.characterId,
      name: name ?? this.name,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      accentColor: accentColor ?? this.accentColor,
      tagsJson: tagsJson ?? this.tagsJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (characterId.present) {
      map['character_id'] = Variable<String>(characterId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (accentColor.present) {
      map['accent_color'] = Variable<String>(accentColor.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharacterModesCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('characterId: $characterId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('isDefault: $isDefault, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('accentColor: $accentColor, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CharacterLoadoutEntriesTable extends CharacterLoadoutEntries
    with TableInfo<$CharacterLoadoutEntriesTable, CharacterLoadoutEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharacterLoadoutEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeIdMeta = const VerificationMeta('modeId');
  @override
  late final GeneratedColumn<String> modeId = GeneratedColumn<String>(
    'mode_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<String> slot = GeneratedColumn<String>(
    'slot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    modeId,
    assetId,
    slot,
    quantity,
    sortOrder,
    enabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'character_loadout_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<CharacterLoadoutEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('mode_id')) {
      context.handle(
        _modeIdMeta,
        modeId.isAcceptableOrUnknown(data['mode_id']!, _modeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_modeIdMeta);
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('slot')) {
      context.handle(
        _slotMeta,
        slot.isAcceptableOrUnknown(data['slot']!, _slotMeta),
      );
    } else if (isInserting) {
      context.missing(_slotMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CharacterLoadoutEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CharacterLoadoutEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      modeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode_id'],
      )!,
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_id'],
      )!,
      slot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slot'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
    );
  }

  @override
  $CharacterLoadoutEntriesTable createAlias(String alias) {
    return $CharacterLoadoutEntriesTable(attachedDatabase, alias);
  }
}

class CharacterLoadoutEntry extends DataClass
    implements Insertable<CharacterLoadoutEntry> {
  final String id;
  final String modeId;
  final String assetId;
  final String slot;
  final int quantity;
  final int sortOrder;
  final bool enabled;
  const CharacterLoadoutEntry({
    required this.id,
    required this.modeId,
    required this.assetId,
    required this.slot,
    required this.quantity,
    required this.sortOrder,
    required this.enabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['mode_id'] = Variable<String>(modeId);
    map['asset_id'] = Variable<String>(assetId);
    map['slot'] = Variable<String>(slot);
    map['quantity'] = Variable<int>(quantity);
    map['sort_order'] = Variable<int>(sortOrder);
    map['enabled'] = Variable<bool>(enabled);
    return map;
  }

  CharacterLoadoutEntriesCompanion toCompanion(bool nullToAbsent) {
    return CharacterLoadoutEntriesCompanion(
      id: Value(id),
      modeId: Value(modeId),
      assetId: Value(assetId),
      slot: Value(slot),
      quantity: Value(quantity),
      sortOrder: Value(sortOrder),
      enabled: Value(enabled),
    );
  }

  factory CharacterLoadoutEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CharacterLoadoutEntry(
      id: serializer.fromJson<String>(json['id']),
      modeId: serializer.fromJson<String>(json['modeId']),
      assetId: serializer.fromJson<String>(json['assetId']),
      slot: serializer.fromJson<String>(json['slot']),
      quantity: serializer.fromJson<int>(json['quantity']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      enabled: serializer.fromJson<bool>(json['enabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'modeId': serializer.toJson<String>(modeId),
      'assetId': serializer.toJson<String>(assetId),
      'slot': serializer.toJson<String>(slot),
      'quantity': serializer.toJson<int>(quantity),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'enabled': serializer.toJson<bool>(enabled),
    };
  }

  CharacterLoadoutEntry copyWith({
    String? id,
    String? modeId,
    String? assetId,
    String? slot,
    int? quantity,
    int? sortOrder,
    bool? enabled,
  }) => CharacterLoadoutEntry(
    id: id ?? this.id,
    modeId: modeId ?? this.modeId,
    assetId: assetId ?? this.assetId,
    slot: slot ?? this.slot,
    quantity: quantity ?? this.quantity,
    sortOrder: sortOrder ?? this.sortOrder,
    enabled: enabled ?? this.enabled,
  );
  CharacterLoadoutEntry copyWithCompanion(
    CharacterLoadoutEntriesCompanion data,
  ) {
    return CharacterLoadoutEntry(
      id: data.id.present ? data.id.value : this.id,
      modeId: data.modeId.present ? data.modeId.value : this.modeId,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      slot: data.slot.present ? data.slot.value : this.slot,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CharacterLoadoutEntry(')
          ..write('id: $id, ')
          ..write('modeId: $modeId, ')
          ..write('assetId: $assetId, ')
          ..write('slot: $slot, ')
          ..write('quantity: $quantity, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, modeId, assetId, slot, quantity, sortOrder, enabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CharacterLoadoutEntry &&
          other.id == this.id &&
          other.modeId == this.modeId &&
          other.assetId == this.assetId &&
          other.slot == this.slot &&
          other.quantity == this.quantity &&
          other.sortOrder == this.sortOrder &&
          other.enabled == this.enabled);
}

class CharacterLoadoutEntriesCompanion
    extends UpdateCompanion<CharacterLoadoutEntry> {
  final Value<String> id;
  final Value<String> modeId;
  final Value<String> assetId;
  final Value<String> slot;
  final Value<int> quantity;
  final Value<int> sortOrder;
  final Value<bool> enabled;
  final Value<int> rowid;
  const CharacterLoadoutEntriesCompanion({
    this.id = const Value.absent(),
    this.modeId = const Value.absent(),
    this.assetId = const Value.absent(),
    this.slot = const Value.absent(),
    this.quantity = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CharacterLoadoutEntriesCompanion.insert({
    required String id,
    required String modeId,
    required String assetId,
    required String slot,
    this.quantity = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       modeId = Value(modeId),
       assetId = Value(assetId),
       slot = Value(slot);
  static Insertable<CharacterLoadoutEntry> custom({
    Expression<String>? id,
    Expression<String>? modeId,
    Expression<String>? assetId,
    Expression<String>? slot,
    Expression<int>? quantity,
    Expression<int>? sortOrder,
    Expression<bool>? enabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (modeId != null) 'mode_id': modeId,
      if (assetId != null) 'asset_id': assetId,
      if (slot != null) 'slot': slot,
      if (quantity != null) 'quantity': quantity,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (enabled != null) 'enabled': enabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CharacterLoadoutEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? modeId,
    Value<String>? assetId,
    Value<String>? slot,
    Value<int>? quantity,
    Value<int>? sortOrder,
    Value<bool>? enabled,
    Value<int>? rowid,
  }) {
    return CharacterLoadoutEntriesCompanion(
      id: id ?? this.id,
      modeId: modeId ?? this.modeId,
      assetId: assetId ?? this.assetId,
      slot: slot ?? this.slot,
      quantity: quantity ?? this.quantity,
      sortOrder: sortOrder ?? this.sortOrder,
      enabled: enabled ?? this.enabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (modeId.present) {
      map['mode_id'] = Variable<String>(modeId.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (slot.present) {
      map['slot'] = Variable<String>(slot.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharacterLoadoutEntriesCompanion(')
          ..write('id: $id, ')
          ..write('modeId: $modeId, ')
          ..write('assetId: $assetId, ')
          ..write('slot: $slot, ')
          ..write('quantity: $quantity, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('enabled: $enabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CharacterModeIdentityOverridesTable
    extends CharacterModeIdentityOverrides
    with
        TableInfo<
          $CharacterModeIdentityOverridesTable,
          CharacterModeIdentityOverride
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharacterModeIdentityOverridesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _modeIdMeta = const VerificationMeta('modeId');
  @override
  late final GeneratedColumn<String> modeId = GeneratedColumn<String>(
    'mode_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _faceLockMeta = const VerificationMeta(
    'faceLock',
  );
  @override
  late final GeneratedColumn<bool> faceLock = GeneratedColumn<bool>(
    'face_lock',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("face_lock" IN (0, 1))',
    ),
  );
  static const VerificationMeta _hairLockMeta = const VerificationMeta(
    'hairLock',
  );
  @override
  late final GeneratedColumn<bool> hairLock = GeneratedColumn<bool>(
    'hair_lock',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hair_lock" IN (0, 1))',
    ),
  );
  static const VerificationMeta _bodyLockMeta = const VerificationMeta(
    'bodyLock',
  );
  @override
  late final GeneratedColumn<bool> bodyLock = GeneratedColumn<bool>(
    'body_lock',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("body_lock" IN (0, 1))',
    ),
  );
  static const VerificationMeta _colorLockMeta = const VerificationMeta(
    'colorLock',
  );
  @override
  late final GeneratedColumn<bool> colorLock = GeneratedColumn<bool>(
    'color_lock',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("color_lock" IN (0, 1))',
    ),
  );
  static const VerificationMeta _outfitLockMeta = const VerificationMeta(
    'outfitLock',
  );
  @override
  late final GeneratedColumn<bool> outfitLock = GeneratedColumn<bool>(
    'outfit_lock',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("outfit_lock" IN (0, 1))',
    ),
  );
  static const VerificationMeta _weaponLockMeta = const VerificationMeta(
    'weaponLock',
  );
  @override
  late final GeneratedColumn<bool> weaponLock = GeneratedColumn<bool>(
    'weapon_lock',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("weapon_lock" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    modeId,
    faceLock,
    hairLock,
    bodyLock,
    colorLock,
    outfitLock,
    weaponLock,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'character_mode_identity_overrides';
  @override
  VerificationContext validateIntegrity(
    Insertable<CharacterModeIdentityOverride> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('mode_id')) {
      context.handle(
        _modeIdMeta,
        modeId.isAcceptableOrUnknown(data['mode_id']!, _modeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_modeIdMeta);
    }
    if (data.containsKey('face_lock')) {
      context.handle(
        _faceLockMeta,
        faceLock.isAcceptableOrUnknown(data['face_lock']!, _faceLockMeta),
      );
    }
    if (data.containsKey('hair_lock')) {
      context.handle(
        _hairLockMeta,
        hairLock.isAcceptableOrUnknown(data['hair_lock']!, _hairLockMeta),
      );
    }
    if (data.containsKey('body_lock')) {
      context.handle(
        _bodyLockMeta,
        bodyLock.isAcceptableOrUnknown(data['body_lock']!, _bodyLockMeta),
      );
    }
    if (data.containsKey('color_lock')) {
      context.handle(
        _colorLockMeta,
        colorLock.isAcceptableOrUnknown(data['color_lock']!, _colorLockMeta),
      );
    }
    if (data.containsKey('outfit_lock')) {
      context.handle(
        _outfitLockMeta,
        outfitLock.isAcceptableOrUnknown(data['outfit_lock']!, _outfitLockMeta),
      );
    }
    if (data.containsKey('weapon_lock')) {
      context.handle(
        _weaponLockMeta,
        weaponLock.isAcceptableOrUnknown(data['weapon_lock']!, _weaponLockMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {modeId};
  @override
  CharacterModeIdentityOverride map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CharacterModeIdentityOverride(
      modeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode_id'],
      )!,
      faceLock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}face_lock'],
      ),
      hairLock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hair_lock'],
      ),
      bodyLock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}body_lock'],
      ),
      colorLock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}color_lock'],
      ),
      outfitLock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}outfit_lock'],
      ),
      weaponLock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}weapon_lock'],
      ),
    );
  }

  @override
  $CharacterModeIdentityOverridesTable createAlias(String alias) {
    return $CharacterModeIdentityOverridesTable(attachedDatabase, alias);
  }
}

class CharacterModeIdentityOverride extends DataClass
    implements Insertable<CharacterModeIdentityOverride> {
  final String modeId;
  final bool? faceLock;
  final bool? hairLock;
  final bool? bodyLock;
  final bool? colorLock;
  final bool? outfitLock;
  final bool? weaponLock;
  const CharacterModeIdentityOverride({
    required this.modeId,
    this.faceLock,
    this.hairLock,
    this.bodyLock,
    this.colorLock,
    this.outfitLock,
    this.weaponLock,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['mode_id'] = Variable<String>(modeId);
    if (!nullToAbsent || faceLock != null) {
      map['face_lock'] = Variable<bool>(faceLock);
    }
    if (!nullToAbsent || hairLock != null) {
      map['hair_lock'] = Variable<bool>(hairLock);
    }
    if (!nullToAbsent || bodyLock != null) {
      map['body_lock'] = Variable<bool>(bodyLock);
    }
    if (!nullToAbsent || colorLock != null) {
      map['color_lock'] = Variable<bool>(colorLock);
    }
    if (!nullToAbsent || outfitLock != null) {
      map['outfit_lock'] = Variable<bool>(outfitLock);
    }
    if (!nullToAbsent || weaponLock != null) {
      map['weapon_lock'] = Variable<bool>(weaponLock);
    }
    return map;
  }

  CharacterModeIdentityOverridesCompanion toCompanion(bool nullToAbsent) {
    return CharacterModeIdentityOverridesCompanion(
      modeId: Value(modeId),
      faceLock: faceLock == null && nullToAbsent
          ? const Value.absent()
          : Value(faceLock),
      hairLock: hairLock == null && nullToAbsent
          ? const Value.absent()
          : Value(hairLock),
      bodyLock: bodyLock == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyLock),
      colorLock: colorLock == null && nullToAbsent
          ? const Value.absent()
          : Value(colorLock),
      outfitLock: outfitLock == null && nullToAbsent
          ? const Value.absent()
          : Value(outfitLock),
      weaponLock: weaponLock == null && nullToAbsent
          ? const Value.absent()
          : Value(weaponLock),
    );
  }

  factory CharacterModeIdentityOverride.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CharacterModeIdentityOverride(
      modeId: serializer.fromJson<String>(json['modeId']),
      faceLock: serializer.fromJson<bool?>(json['faceLock']),
      hairLock: serializer.fromJson<bool?>(json['hairLock']),
      bodyLock: serializer.fromJson<bool?>(json['bodyLock']),
      colorLock: serializer.fromJson<bool?>(json['colorLock']),
      outfitLock: serializer.fromJson<bool?>(json['outfitLock']),
      weaponLock: serializer.fromJson<bool?>(json['weaponLock']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'modeId': serializer.toJson<String>(modeId),
      'faceLock': serializer.toJson<bool?>(faceLock),
      'hairLock': serializer.toJson<bool?>(hairLock),
      'bodyLock': serializer.toJson<bool?>(bodyLock),
      'colorLock': serializer.toJson<bool?>(colorLock),
      'outfitLock': serializer.toJson<bool?>(outfitLock),
      'weaponLock': serializer.toJson<bool?>(weaponLock),
    };
  }

  CharacterModeIdentityOverride copyWith({
    String? modeId,
    Value<bool?> faceLock = const Value.absent(),
    Value<bool?> hairLock = const Value.absent(),
    Value<bool?> bodyLock = const Value.absent(),
    Value<bool?> colorLock = const Value.absent(),
    Value<bool?> outfitLock = const Value.absent(),
    Value<bool?> weaponLock = const Value.absent(),
  }) => CharacterModeIdentityOverride(
    modeId: modeId ?? this.modeId,
    faceLock: faceLock.present ? faceLock.value : this.faceLock,
    hairLock: hairLock.present ? hairLock.value : this.hairLock,
    bodyLock: bodyLock.present ? bodyLock.value : this.bodyLock,
    colorLock: colorLock.present ? colorLock.value : this.colorLock,
    outfitLock: outfitLock.present ? outfitLock.value : this.outfitLock,
    weaponLock: weaponLock.present ? weaponLock.value : this.weaponLock,
  );
  CharacterModeIdentityOverride copyWithCompanion(
    CharacterModeIdentityOverridesCompanion data,
  ) {
    return CharacterModeIdentityOverride(
      modeId: data.modeId.present ? data.modeId.value : this.modeId,
      faceLock: data.faceLock.present ? data.faceLock.value : this.faceLock,
      hairLock: data.hairLock.present ? data.hairLock.value : this.hairLock,
      bodyLock: data.bodyLock.present ? data.bodyLock.value : this.bodyLock,
      colorLock: data.colorLock.present ? data.colorLock.value : this.colorLock,
      outfitLock: data.outfitLock.present
          ? data.outfitLock.value
          : this.outfitLock,
      weaponLock: data.weaponLock.present
          ? data.weaponLock.value
          : this.weaponLock,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CharacterModeIdentityOverride(')
          ..write('modeId: $modeId, ')
          ..write('faceLock: $faceLock, ')
          ..write('hairLock: $hairLock, ')
          ..write('bodyLock: $bodyLock, ')
          ..write('colorLock: $colorLock, ')
          ..write('outfitLock: $outfitLock, ')
          ..write('weaponLock: $weaponLock')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    modeId,
    faceLock,
    hairLock,
    bodyLock,
    colorLock,
    outfitLock,
    weaponLock,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CharacterModeIdentityOverride &&
          other.modeId == this.modeId &&
          other.faceLock == this.faceLock &&
          other.hairLock == this.hairLock &&
          other.bodyLock == this.bodyLock &&
          other.colorLock == this.colorLock &&
          other.outfitLock == this.outfitLock &&
          other.weaponLock == this.weaponLock);
}

class CharacterModeIdentityOverridesCompanion
    extends UpdateCompanion<CharacterModeIdentityOverride> {
  final Value<String> modeId;
  final Value<bool?> faceLock;
  final Value<bool?> hairLock;
  final Value<bool?> bodyLock;
  final Value<bool?> colorLock;
  final Value<bool?> outfitLock;
  final Value<bool?> weaponLock;
  final Value<int> rowid;
  const CharacterModeIdentityOverridesCompanion({
    this.modeId = const Value.absent(),
    this.faceLock = const Value.absent(),
    this.hairLock = const Value.absent(),
    this.bodyLock = const Value.absent(),
    this.colorLock = const Value.absent(),
    this.outfitLock = const Value.absent(),
    this.weaponLock = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CharacterModeIdentityOverridesCompanion.insert({
    required String modeId,
    this.faceLock = const Value.absent(),
    this.hairLock = const Value.absent(),
    this.bodyLock = const Value.absent(),
    this.colorLock = const Value.absent(),
    this.outfitLock = const Value.absent(),
    this.weaponLock = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : modeId = Value(modeId);
  static Insertable<CharacterModeIdentityOverride> custom({
    Expression<String>? modeId,
    Expression<bool>? faceLock,
    Expression<bool>? hairLock,
    Expression<bool>? bodyLock,
    Expression<bool>? colorLock,
    Expression<bool>? outfitLock,
    Expression<bool>? weaponLock,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (modeId != null) 'mode_id': modeId,
      if (faceLock != null) 'face_lock': faceLock,
      if (hairLock != null) 'hair_lock': hairLock,
      if (bodyLock != null) 'body_lock': bodyLock,
      if (colorLock != null) 'color_lock': colorLock,
      if (outfitLock != null) 'outfit_lock': outfitLock,
      if (weaponLock != null) 'weapon_lock': weaponLock,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CharacterModeIdentityOverridesCompanion copyWith({
    Value<String>? modeId,
    Value<bool?>? faceLock,
    Value<bool?>? hairLock,
    Value<bool?>? bodyLock,
    Value<bool?>? colorLock,
    Value<bool?>? outfitLock,
    Value<bool?>? weaponLock,
    Value<int>? rowid,
  }) {
    return CharacterModeIdentityOverridesCompanion(
      modeId: modeId ?? this.modeId,
      faceLock: faceLock ?? this.faceLock,
      hairLock: hairLock ?? this.hairLock,
      bodyLock: bodyLock ?? this.bodyLock,
      colorLock: colorLock ?? this.colorLock,
      outfitLock: outfitLock ?? this.outfitLock,
      weaponLock: weaponLock ?? this.weaponLock,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (modeId.present) {
      map['mode_id'] = Variable<String>(modeId.value);
    }
    if (faceLock.present) {
      map['face_lock'] = Variable<bool>(faceLock.value);
    }
    if (hairLock.present) {
      map['hair_lock'] = Variable<bool>(hairLock.value);
    }
    if (bodyLock.present) {
      map['body_lock'] = Variable<bool>(bodyLock.value);
    }
    if (colorLock.present) {
      map['color_lock'] = Variable<bool>(colorLock.value);
    }
    if (outfitLock.present) {
      map['outfit_lock'] = Variable<bool>(outfitLock.value);
    }
    if (weaponLock.present) {
      map['weapon_lock'] = Variable<bool>(weaponLock.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharacterModeIdentityOverridesCompanion(')
          ..write('modeId: $modeId, ')
          ..write('faceLock: $faceLock, ')
          ..write('hairLock: $hairLock, ')
          ..write('bodyLock: $bodyLock, ')
          ..write('colorLock: $colorLock, ')
          ..write('outfitLock: $outfitLock, ')
          ..write('weaponLock: $weaponLock, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CharacterModeReferencesTable extends CharacterModeReferences
    with TableInfo<$CharacterModeReferencesTable, CharacterModeReference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharacterModeReferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeIdMeta = const VerificationMeta('modeId');
  @override
  late final GeneratedColumn<String> modeId = GeneratedColumn<String>(
    'mode_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceTypeMeta = const VerificationMeta(
    'referenceType',
  );
  @override
  late final GeneratedColumn<String> referenceType = GeneratedColumn<String>(
    'reference_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _primaryReferenceMeta = const VerificationMeta(
    'primaryReference',
  );
  @override
  late final GeneratedColumn<bool> primaryReference = GeneratedColumn<bool>(
    'primary_reference',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("primary_reference" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    modeId,
    referenceType,
    filePath,
    priority,
    primaryReference,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'character_mode_references';
  @override
  VerificationContext validateIntegrity(
    Insertable<CharacterModeReference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('mode_id')) {
      context.handle(
        _modeIdMeta,
        modeId.isAcceptableOrUnknown(data['mode_id']!, _modeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_modeIdMeta);
    }
    if (data.containsKey('reference_type')) {
      context.handle(
        _referenceTypeMeta,
        referenceType.isAcceptableOrUnknown(
          data['reference_type']!,
          _referenceTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_referenceTypeMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('primary_reference')) {
      context.handle(
        _primaryReferenceMeta,
        primaryReference.isAcceptableOrUnknown(
          data['primary_reference']!,
          _primaryReferenceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CharacterModeReference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CharacterModeReference(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      modeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode_id'],
      )!,
      referenceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_type'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      primaryReference: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}primary_reference'],
      )!,
    );
  }

  @override
  $CharacterModeReferencesTable createAlias(String alias) {
    return $CharacterModeReferencesTable(attachedDatabase, alias);
  }
}

class CharacterModeReference extends DataClass
    implements Insertable<CharacterModeReference> {
  final String id;
  final String modeId;
  final String referenceType;
  final String filePath;
  final int priority;
  final bool primaryReference;
  const CharacterModeReference({
    required this.id,
    required this.modeId,
    required this.referenceType,
    required this.filePath,
    required this.priority,
    required this.primaryReference,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['mode_id'] = Variable<String>(modeId);
    map['reference_type'] = Variable<String>(referenceType);
    map['file_path'] = Variable<String>(filePath);
    map['priority'] = Variable<int>(priority);
    map['primary_reference'] = Variable<bool>(primaryReference);
    return map;
  }

  CharacterModeReferencesCompanion toCompanion(bool nullToAbsent) {
    return CharacterModeReferencesCompanion(
      id: Value(id),
      modeId: Value(modeId),
      referenceType: Value(referenceType),
      filePath: Value(filePath),
      priority: Value(priority),
      primaryReference: Value(primaryReference),
    );
  }

  factory CharacterModeReference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CharacterModeReference(
      id: serializer.fromJson<String>(json['id']),
      modeId: serializer.fromJson<String>(json['modeId']),
      referenceType: serializer.fromJson<String>(json['referenceType']),
      filePath: serializer.fromJson<String>(json['filePath']),
      priority: serializer.fromJson<int>(json['priority']),
      primaryReference: serializer.fromJson<bool>(json['primaryReference']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'modeId': serializer.toJson<String>(modeId),
      'referenceType': serializer.toJson<String>(referenceType),
      'filePath': serializer.toJson<String>(filePath),
      'priority': serializer.toJson<int>(priority),
      'primaryReference': serializer.toJson<bool>(primaryReference),
    };
  }

  CharacterModeReference copyWith({
    String? id,
    String? modeId,
    String? referenceType,
    String? filePath,
    int? priority,
    bool? primaryReference,
  }) => CharacterModeReference(
    id: id ?? this.id,
    modeId: modeId ?? this.modeId,
    referenceType: referenceType ?? this.referenceType,
    filePath: filePath ?? this.filePath,
    priority: priority ?? this.priority,
    primaryReference: primaryReference ?? this.primaryReference,
  );
  CharacterModeReference copyWithCompanion(
    CharacterModeReferencesCompanion data,
  ) {
    return CharacterModeReference(
      id: data.id.present ? data.id.value : this.id,
      modeId: data.modeId.present ? data.modeId.value : this.modeId,
      referenceType: data.referenceType.present
          ? data.referenceType.value
          : this.referenceType,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      priority: data.priority.present ? data.priority.value : this.priority,
      primaryReference: data.primaryReference.present
          ? data.primaryReference.value
          : this.primaryReference,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CharacterModeReference(')
          ..write('id: $id, ')
          ..write('modeId: $modeId, ')
          ..write('referenceType: $referenceType, ')
          ..write('filePath: $filePath, ')
          ..write('priority: $priority, ')
          ..write('primaryReference: $primaryReference')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    modeId,
    referenceType,
    filePath,
    priority,
    primaryReference,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CharacterModeReference &&
          other.id == this.id &&
          other.modeId == this.modeId &&
          other.referenceType == this.referenceType &&
          other.filePath == this.filePath &&
          other.priority == this.priority &&
          other.primaryReference == this.primaryReference);
}

class CharacterModeReferencesCompanion
    extends UpdateCompanion<CharacterModeReference> {
  final Value<String> id;
  final Value<String> modeId;
  final Value<String> referenceType;
  final Value<String> filePath;
  final Value<int> priority;
  final Value<bool> primaryReference;
  final Value<int> rowid;
  const CharacterModeReferencesCompanion({
    this.id = const Value.absent(),
    this.modeId = const Value.absent(),
    this.referenceType = const Value.absent(),
    this.filePath = const Value.absent(),
    this.priority = const Value.absent(),
    this.primaryReference = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CharacterModeReferencesCompanion.insert({
    required String id,
    required String modeId,
    required String referenceType,
    required String filePath,
    this.priority = const Value.absent(),
    this.primaryReference = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       modeId = Value(modeId),
       referenceType = Value(referenceType),
       filePath = Value(filePath);
  static Insertable<CharacterModeReference> custom({
    Expression<String>? id,
    Expression<String>? modeId,
    Expression<String>? referenceType,
    Expression<String>? filePath,
    Expression<int>? priority,
    Expression<bool>? primaryReference,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (modeId != null) 'mode_id': modeId,
      if (referenceType != null) 'reference_type': referenceType,
      if (filePath != null) 'file_path': filePath,
      if (priority != null) 'priority': priority,
      if (primaryReference != null) 'primary_reference': primaryReference,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CharacterModeReferencesCompanion copyWith({
    Value<String>? id,
    Value<String>? modeId,
    Value<String>? referenceType,
    Value<String>? filePath,
    Value<int>? priority,
    Value<bool>? primaryReference,
    Value<int>? rowid,
  }) {
    return CharacterModeReferencesCompanion(
      id: id ?? this.id,
      modeId: modeId ?? this.modeId,
      referenceType: referenceType ?? this.referenceType,
      filePath: filePath ?? this.filePath,
      priority: priority ?? this.priority,
      primaryReference: primaryReference ?? this.primaryReference,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (modeId.present) {
      map['mode_id'] = Variable<String>(modeId.value);
    }
    if (referenceType.present) {
      map['reference_type'] = Variable<String>(referenceType.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (primaryReference.present) {
      map['primary_reference'] = Variable<bool>(primaryReference.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharacterModeReferencesCompanion(')
          ..write('id: $id, ')
          ..write('modeId: $modeId, ')
          ..write('referenceType: $referenceType, ')
          ..write('filePath: $filePath, ')
          ..write('priority: $priority, ')
          ..write('primaryReference: $primaryReference, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssetRelationsTable extends AssetRelations
    with TableInfo<$AssetRelationsTable, AssetRelation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetRelationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sourceAssetIdMeta = const VerificationMeta(
    'sourceAssetId',
  );
  @override
  late final GeneratedColumn<String> sourceAssetId = GeneratedColumn<String>(
    'source_asset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetAssetIdMeta = const VerificationMeta(
    'targetAssetId',
  );
  @override
  late final GeneratedColumn<String> targetAssetId = GeneratedColumn<String>(
    'target_asset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relationTypeMeta = const VerificationMeta(
    'relationType',
  );
  @override
  late final GeneratedColumn<String> relationType = GeneratedColumn<String>(
    'relation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relationOriginMeta = const VerificationMeta(
    'relationOrigin',
  );
  @override
  late final GeneratedColumn<String> relationOrigin = GeneratedColumn<String>(
    'relation_origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.fromMillisecondsSinceEpoch(0)),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    sourceAssetId,
    targetAssetId,
    relationType,
    relationOrigin,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'asset_relations';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssetRelation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    }
    if (data.containsKey('source_asset_id')) {
      context.handle(
        _sourceAssetIdMeta,
        sourceAssetId.isAcceptableOrUnknown(
          data['source_asset_id']!,
          _sourceAssetIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceAssetIdMeta);
    }
    if (data.containsKey('target_asset_id')) {
      context.handle(
        _targetAssetIdMeta,
        targetAssetId.isAcceptableOrUnknown(
          data['target_asset_id']!,
          _targetAssetIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetAssetIdMeta);
    }
    if (data.containsKey('relation_type')) {
      context.handle(
        _relationTypeMeta,
        relationType.isAcceptableOrUnknown(
          data['relation_type']!,
          _relationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relationTypeMeta);
    }
    if (data.containsKey('relation_origin')) {
      context.handle(
        _relationOriginMeta,
        relationOrigin.isAcceptableOrUnknown(
          data['relation_origin']!,
          _relationOriginMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AssetRelation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssetRelation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      sourceAssetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_asset_id'],
      )!,
      targetAssetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_asset_id'],
      )!,
      relationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relation_type'],
      )!,
      relationOrigin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relation_origin'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AssetRelationsTable createAlias(String alias) {
    return $AssetRelationsTable(attachedDatabase, alias);
  }
}

class AssetRelation extends DataClass implements Insertable<AssetRelation> {
  final String id;
  final String projectId;
  final String sourceAssetId;
  final String targetAssetId;
  final String relationType;
  final String relationOrigin;
  final DateTime createdAt;
  const AssetRelation({
    required this.id,
    required this.projectId,
    required this.sourceAssetId,
    required this.targetAssetId,
    required this.relationType,
    required this.relationOrigin,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['source_asset_id'] = Variable<String>(sourceAssetId);
    map['target_asset_id'] = Variable<String>(targetAssetId);
    map['relation_type'] = Variable<String>(relationType);
    map['relation_origin'] = Variable<String>(relationOrigin);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AssetRelationsCompanion toCompanion(bool nullToAbsent) {
    return AssetRelationsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      sourceAssetId: Value(sourceAssetId),
      targetAssetId: Value(targetAssetId),
      relationType: Value(relationType),
      relationOrigin: Value(relationOrigin),
      createdAt: Value(createdAt),
    );
  }

  factory AssetRelation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssetRelation(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      sourceAssetId: serializer.fromJson<String>(json['sourceAssetId']),
      targetAssetId: serializer.fromJson<String>(json['targetAssetId']),
      relationType: serializer.fromJson<String>(json['relationType']),
      relationOrigin: serializer.fromJson<String>(json['relationOrigin']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'sourceAssetId': serializer.toJson<String>(sourceAssetId),
      'targetAssetId': serializer.toJson<String>(targetAssetId),
      'relationType': serializer.toJson<String>(relationType),
      'relationOrigin': serializer.toJson<String>(relationOrigin),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AssetRelation copyWith({
    String? id,
    String? projectId,
    String? sourceAssetId,
    String? targetAssetId,
    String? relationType,
    String? relationOrigin,
    DateTime? createdAt,
  }) => AssetRelation(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    sourceAssetId: sourceAssetId ?? this.sourceAssetId,
    targetAssetId: targetAssetId ?? this.targetAssetId,
    relationType: relationType ?? this.relationType,
    relationOrigin: relationOrigin ?? this.relationOrigin,
    createdAt: createdAt ?? this.createdAt,
  );
  AssetRelation copyWithCompanion(AssetRelationsCompanion data) {
    return AssetRelation(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      sourceAssetId: data.sourceAssetId.present
          ? data.sourceAssetId.value
          : this.sourceAssetId,
      targetAssetId: data.targetAssetId.present
          ? data.targetAssetId.value
          : this.targetAssetId,
      relationType: data.relationType.present
          ? data.relationType.value
          : this.relationType,
      relationOrigin: data.relationOrigin.present
          ? data.relationOrigin.value
          : this.relationOrigin,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssetRelation(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('sourceAssetId: $sourceAssetId, ')
          ..write('targetAssetId: $targetAssetId, ')
          ..write('relationType: $relationType, ')
          ..write('relationOrigin: $relationOrigin, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    sourceAssetId,
    targetAssetId,
    relationType,
    relationOrigin,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetRelation &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.sourceAssetId == this.sourceAssetId &&
          other.targetAssetId == this.targetAssetId &&
          other.relationType == this.relationType &&
          other.relationOrigin == this.relationOrigin &&
          other.createdAt == this.createdAt);
}

class AssetRelationsCompanion extends UpdateCompanion<AssetRelation> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> sourceAssetId;
  final Value<String> targetAssetId;
  final Value<String> relationType;
  final Value<String> relationOrigin;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AssetRelationsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.sourceAssetId = const Value.absent(),
    this.targetAssetId = const Value.absent(),
    this.relationType = const Value.absent(),
    this.relationOrigin = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssetRelationsCompanion.insert({
    required String id,
    this.projectId = const Value.absent(),
    required String sourceAssetId,
    required String targetAssetId,
    required String relationType,
    this.relationOrigin = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceAssetId = Value(sourceAssetId),
       targetAssetId = Value(targetAssetId),
       relationType = Value(relationType);
  static Insertable<AssetRelation> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? sourceAssetId,
    Expression<String>? targetAssetId,
    Expression<String>? relationType,
    Expression<String>? relationOrigin,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (sourceAssetId != null) 'source_asset_id': sourceAssetId,
      if (targetAssetId != null) 'target_asset_id': targetAssetId,
      if (relationType != null) 'relation_type': relationType,
      if (relationOrigin != null) 'relation_origin': relationOrigin,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssetRelationsCompanion copyWith({
    Value<String>? id,
    Value<String>? projectId,
    Value<String>? sourceAssetId,
    Value<String>? targetAssetId,
    Value<String>? relationType,
    Value<String>? relationOrigin,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AssetRelationsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      sourceAssetId: sourceAssetId ?? this.sourceAssetId,
      targetAssetId: targetAssetId ?? this.targetAssetId,
      relationType: relationType ?? this.relationType,
      relationOrigin: relationOrigin ?? this.relationOrigin,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (sourceAssetId.present) {
      map['source_asset_id'] = Variable<String>(sourceAssetId.value);
    }
    if (targetAssetId.present) {
      map['target_asset_id'] = Variable<String>(targetAssetId.value);
    }
    if (relationType.present) {
      map['relation_type'] = Variable<String>(relationType.value);
    }
    if (relationOrigin.present) {
      map['relation_origin'] = Variable<String>(relationOrigin.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetRelationsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('sourceAssetId: $sourceAssetId, ')
          ..write('targetAssetId: $targetAssetId, ')
          ..write('relationType: $relationType, ')
          ..write('relationOrigin: $relationOrigin, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WardrobesTable extends Wardrobes
    with TableInfo<$WardrobesTable, Wardrobe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WardrobesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _primaryMaterialMeta = const VerificationMeta(
    'primaryMaterial',
  );
  @override
  late final GeneratedColumn<String> primaryMaterial = GeneratedColumn<String>(
    'primary_material',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _fabricMeta = const VerificationMeta('fabric');
  @override
  late final GeneratedColumn<String> fabric = GeneratedColumn<String>(
    'fabric',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _fitMeta = const VerificationMeta('fit');
  @override
  late final GeneratedColumn<String> fit = GeneratedColumn<String>(
    'fit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _styleMeta = const VerificationMeta('style');
  @override
  late final GeneratedColumn<String> style = GeneratedColumn<String>(
    'style',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    assetId,
    projectId,
    name,
    category,
    description,
    primaryMaterial,
    fabric,
    fit,
    style,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wardrobes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Wardrobe> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('primary_material')) {
      context.handle(
        _primaryMaterialMeta,
        primaryMaterial.isAcceptableOrUnknown(
          data['primary_material']!,
          _primaryMaterialMeta,
        ),
      );
    }
    if (data.containsKey('fabric')) {
      context.handle(
        _fabricMeta,
        fabric.isAcceptableOrUnknown(data['fabric']!, _fabricMeta),
      );
    }
    if (data.containsKey('fit')) {
      context.handle(
        _fitMeta,
        fit.isAcceptableOrUnknown(data['fit']!, _fitMeta),
      );
    }
    if (data.containsKey('style')) {
      context.handle(
        _styleMeta,
        style.isAcceptableOrUnknown(data['style']!, _styleMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {assetId};
  @override
  Wardrobe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Wardrobe(
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      primaryMaterial: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}primary_material'],
      )!,
      fabric: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fabric'],
      )!,
      fit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fit'],
      )!,
      style: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}style'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
    );
  }

  @override
  $WardrobesTable createAlias(String alias) {
    return $WardrobesTable(attachedDatabase, alias);
  }
}

class Wardrobe extends DataClass implements Insertable<Wardrobe> {
  final String assetId;
  final String projectId;
  final String name;
  final String category;
  final String description;
  final String primaryMaterial;
  final String fabric;
  final String fit;
  final String style;
  final String notes;
  const Wardrobe({
    required this.assetId,
    required this.projectId,
    required this.name,
    required this.category,
    required this.description,
    required this.primaryMaterial,
    required this.fabric,
    required this.fit,
    required this.style,
    required this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['asset_id'] = Variable<String>(assetId);
    map['project_id'] = Variable<String>(projectId);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    map['description'] = Variable<String>(description);
    map['primary_material'] = Variable<String>(primaryMaterial);
    map['fabric'] = Variable<String>(fabric);
    map['fit'] = Variable<String>(fit);
    map['style'] = Variable<String>(style);
    map['notes'] = Variable<String>(notes);
    return map;
  }

  WardrobesCompanion toCompanion(bool nullToAbsent) {
    return WardrobesCompanion(
      assetId: Value(assetId),
      projectId: Value(projectId),
      name: Value(name),
      category: Value(category),
      description: Value(description),
      primaryMaterial: Value(primaryMaterial),
      fabric: Value(fabric),
      fit: Value(fit),
      style: Value(style),
      notes: Value(notes),
    );
  }

  factory Wardrobe.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Wardrobe(
      assetId: serializer.fromJson<String>(json['assetId']),
      projectId: serializer.fromJson<String>(json['projectId']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      description: serializer.fromJson<String>(json['description']),
      primaryMaterial: serializer.fromJson<String>(json['primaryMaterial']),
      fabric: serializer.fromJson<String>(json['fabric']),
      fit: serializer.fromJson<String>(json['fit']),
      style: serializer.fromJson<String>(json['style']),
      notes: serializer.fromJson<String>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'assetId': serializer.toJson<String>(assetId),
      'projectId': serializer.toJson<String>(projectId),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'description': serializer.toJson<String>(description),
      'primaryMaterial': serializer.toJson<String>(primaryMaterial),
      'fabric': serializer.toJson<String>(fabric),
      'fit': serializer.toJson<String>(fit),
      'style': serializer.toJson<String>(style),
      'notes': serializer.toJson<String>(notes),
    };
  }

  Wardrobe copyWith({
    String? assetId,
    String? projectId,
    String? name,
    String? category,
    String? description,
    String? primaryMaterial,
    String? fabric,
    String? fit,
    String? style,
    String? notes,
  }) => Wardrobe(
    assetId: assetId ?? this.assetId,
    projectId: projectId ?? this.projectId,
    name: name ?? this.name,
    category: category ?? this.category,
    description: description ?? this.description,
    primaryMaterial: primaryMaterial ?? this.primaryMaterial,
    fabric: fabric ?? this.fabric,
    fit: fit ?? this.fit,
    style: style ?? this.style,
    notes: notes ?? this.notes,
  );
  Wardrobe copyWithCompanion(WardrobesCompanion data) {
    return Wardrobe(
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      description: data.description.present
          ? data.description.value
          : this.description,
      primaryMaterial: data.primaryMaterial.present
          ? data.primaryMaterial.value
          : this.primaryMaterial,
      fabric: data.fabric.present ? data.fabric.value : this.fabric,
      fit: data.fit.present ? data.fit.value : this.fit,
      style: data.style.present ? data.style.value : this.style,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Wardrobe(')
          ..write('assetId: $assetId, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('primaryMaterial: $primaryMaterial, ')
          ..write('fabric: $fabric, ')
          ..write('fit: $fit, ')
          ..write('style: $style, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    assetId,
    projectId,
    name,
    category,
    description,
    primaryMaterial,
    fabric,
    fit,
    style,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Wardrobe &&
          other.assetId == this.assetId &&
          other.projectId == this.projectId &&
          other.name == this.name &&
          other.category == this.category &&
          other.description == this.description &&
          other.primaryMaterial == this.primaryMaterial &&
          other.fabric == this.fabric &&
          other.fit == this.fit &&
          other.style == this.style &&
          other.notes == this.notes);
}

class WardrobesCompanion extends UpdateCompanion<Wardrobe> {
  final Value<String> assetId;
  final Value<String> projectId;
  final Value<String> name;
  final Value<String> category;
  final Value<String> description;
  final Value<String> primaryMaterial;
  final Value<String> fabric;
  final Value<String> fit;
  final Value<String> style;
  final Value<String> notes;
  final Value<int> rowid;
  const WardrobesCompanion({
    this.assetId = const Value.absent(),
    this.projectId = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.description = const Value.absent(),
    this.primaryMaterial = const Value.absent(),
    this.fabric = const Value.absent(),
    this.fit = const Value.absent(),
    this.style = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WardrobesCompanion.insert({
    required String assetId,
    required String projectId,
    required String name,
    this.category = const Value.absent(),
    this.description = const Value.absent(),
    this.primaryMaterial = const Value.absent(),
    this.fabric = const Value.absent(),
    this.fit = const Value.absent(),
    this.style = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : assetId = Value(assetId),
       projectId = Value(projectId),
       name = Value(name);
  static Insertable<Wardrobe> custom({
    Expression<String>? assetId,
    Expression<String>? projectId,
    Expression<String>? name,
    Expression<String>? category,
    Expression<String>? description,
    Expression<String>? primaryMaterial,
    Expression<String>? fabric,
    Expression<String>? fit,
    Expression<String>? style,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (assetId != null) 'asset_id': assetId,
      if (projectId != null) 'project_id': projectId,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (primaryMaterial != null) 'primary_material': primaryMaterial,
      if (fabric != null) 'fabric': fabric,
      if (fit != null) 'fit': fit,
      if (style != null) 'style': style,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WardrobesCompanion copyWith({
    Value<String>? assetId,
    Value<String>? projectId,
    Value<String>? name,
    Value<String>? category,
    Value<String>? description,
    Value<String>? primaryMaterial,
    Value<String>? fabric,
    Value<String>? fit,
    Value<String>? style,
    Value<String>? notes,
    Value<int>? rowid,
  }) {
    return WardrobesCompanion(
      assetId: assetId ?? this.assetId,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      primaryMaterial: primaryMaterial ?? this.primaryMaterial,
      fabric: fabric ?? this.fabric,
      fit: fit ?? this.fit,
      style: style ?? this.style,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (primaryMaterial.present) {
      map['primary_material'] = Variable<String>(primaryMaterial.value);
    }
    if (fabric.present) {
      map['fabric'] = Variable<String>(fabric.value);
    }
    if (fit.present) {
      map['fit'] = Variable<String>(fit.value);
    }
    if (style.present) {
      map['style'] = Variable<String>(style.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WardrobesCompanion(')
          ..write('assetId: $assetId, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('primaryMaterial: $primaryMaterial, ')
          ..write('fabric: $fabric, ')
          ..write('fit: $fit, ')
          ..write('style: $style, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WardrobeComponentsTable extends WardrobeComponents
    with TableInfo<$WardrobeComponentsTable, WardrobeComponent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WardrobeComponentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wardrobeIdMeta = const VerificationMeta(
    'wardrobeId',
  );
  @override
  late final GeneratedColumn<String> wardrobeId = GeneratedColumn<String>(
    'wardrobe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _componentTypeMeta = const VerificationMeta(
    'componentType',
  );
  @override
  late final GeneratedColumn<String> componentType = GeneratedColumn<String>(
    'component_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _materialMeta = const VerificationMeta(
    'material',
  );
  @override
  late final GeneratedColumn<String> material = GeneratedColumn<String>(
    'material',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _fabricMeta = const VerificationMeta('fabric');
  @override
  late final GeneratedColumn<String> fabric = GeneratedColumn<String>(
    'fabric',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    wardrobeId,
    name,
    componentType,
    material,
    fabric,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wardrobe_components';
  @override
  VerificationContext validateIntegrity(
    Insertable<WardrobeComponent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('wardrobe_id')) {
      context.handle(
        _wardrobeIdMeta,
        wardrobeId.isAcceptableOrUnknown(data['wardrobe_id']!, _wardrobeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wardrobeIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('component_type')) {
      context.handle(
        _componentTypeMeta,
        componentType.isAcceptableOrUnknown(
          data['component_type']!,
          _componentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_componentTypeMeta);
    }
    if (data.containsKey('material')) {
      context.handle(
        _materialMeta,
        material.isAcceptableOrUnknown(data['material']!, _materialMeta),
      );
    }
    if (data.containsKey('fabric')) {
      context.handle(
        _fabricMeta,
        fabric.isAcceptableOrUnknown(data['fabric']!, _fabricMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WardrobeComponent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WardrobeComponent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      wardrobeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wardrobe_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      componentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}component_type'],
      )!,
      material: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}material'],
      )!,
      fabric: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fabric'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $WardrobeComponentsTable createAlias(String alias) {
    return $WardrobeComponentsTable(attachedDatabase, alias);
  }
}

class WardrobeComponent extends DataClass
    implements Insertable<WardrobeComponent> {
  final String id;
  final String wardrobeId;
  final String name;
  final String componentType;
  final String material;
  final String fabric;
  final int sortOrder;
  const WardrobeComponent({
    required this.id,
    required this.wardrobeId,
    required this.name,
    required this.componentType,
    required this.material,
    required this.fabric,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['wardrobe_id'] = Variable<String>(wardrobeId);
    map['name'] = Variable<String>(name);
    map['component_type'] = Variable<String>(componentType);
    map['material'] = Variable<String>(material);
    map['fabric'] = Variable<String>(fabric);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  WardrobeComponentsCompanion toCompanion(bool nullToAbsent) {
    return WardrobeComponentsCompanion(
      id: Value(id),
      wardrobeId: Value(wardrobeId),
      name: Value(name),
      componentType: Value(componentType),
      material: Value(material),
      fabric: Value(fabric),
      sortOrder: Value(sortOrder),
    );
  }

  factory WardrobeComponent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WardrobeComponent(
      id: serializer.fromJson<String>(json['id']),
      wardrobeId: serializer.fromJson<String>(json['wardrobeId']),
      name: serializer.fromJson<String>(json['name']),
      componentType: serializer.fromJson<String>(json['componentType']),
      material: serializer.fromJson<String>(json['material']),
      fabric: serializer.fromJson<String>(json['fabric']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'wardrobeId': serializer.toJson<String>(wardrobeId),
      'name': serializer.toJson<String>(name),
      'componentType': serializer.toJson<String>(componentType),
      'material': serializer.toJson<String>(material),
      'fabric': serializer.toJson<String>(fabric),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  WardrobeComponent copyWith({
    String? id,
    String? wardrobeId,
    String? name,
    String? componentType,
    String? material,
    String? fabric,
    int? sortOrder,
  }) => WardrobeComponent(
    id: id ?? this.id,
    wardrobeId: wardrobeId ?? this.wardrobeId,
    name: name ?? this.name,
    componentType: componentType ?? this.componentType,
    material: material ?? this.material,
    fabric: fabric ?? this.fabric,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  WardrobeComponent copyWithCompanion(WardrobeComponentsCompanion data) {
    return WardrobeComponent(
      id: data.id.present ? data.id.value : this.id,
      wardrobeId: data.wardrobeId.present
          ? data.wardrobeId.value
          : this.wardrobeId,
      name: data.name.present ? data.name.value : this.name,
      componentType: data.componentType.present
          ? data.componentType.value
          : this.componentType,
      material: data.material.present ? data.material.value : this.material,
      fabric: data.fabric.present ? data.fabric.value : this.fabric,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WardrobeComponent(')
          ..write('id: $id, ')
          ..write('wardrobeId: $wardrobeId, ')
          ..write('name: $name, ')
          ..write('componentType: $componentType, ')
          ..write('material: $material, ')
          ..write('fabric: $fabric, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    wardrobeId,
    name,
    componentType,
    material,
    fabric,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WardrobeComponent &&
          other.id == this.id &&
          other.wardrobeId == this.wardrobeId &&
          other.name == this.name &&
          other.componentType == this.componentType &&
          other.material == this.material &&
          other.fabric == this.fabric &&
          other.sortOrder == this.sortOrder);
}

class WardrobeComponentsCompanion extends UpdateCompanion<WardrobeComponent> {
  final Value<String> id;
  final Value<String> wardrobeId;
  final Value<String> name;
  final Value<String> componentType;
  final Value<String> material;
  final Value<String> fabric;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const WardrobeComponentsCompanion({
    this.id = const Value.absent(),
    this.wardrobeId = const Value.absent(),
    this.name = const Value.absent(),
    this.componentType = const Value.absent(),
    this.material = const Value.absent(),
    this.fabric = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WardrobeComponentsCompanion.insert({
    required String id,
    required String wardrobeId,
    required String name,
    required String componentType,
    this.material = const Value.absent(),
    this.fabric = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       wardrobeId = Value(wardrobeId),
       name = Value(name),
       componentType = Value(componentType);
  static Insertable<WardrobeComponent> custom({
    Expression<String>? id,
    Expression<String>? wardrobeId,
    Expression<String>? name,
    Expression<String>? componentType,
    Expression<String>? material,
    Expression<String>? fabric,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wardrobeId != null) 'wardrobe_id': wardrobeId,
      if (name != null) 'name': name,
      if (componentType != null) 'component_type': componentType,
      if (material != null) 'material': material,
      if (fabric != null) 'fabric': fabric,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WardrobeComponentsCompanion copyWith({
    Value<String>? id,
    Value<String>? wardrobeId,
    Value<String>? name,
    Value<String>? componentType,
    Value<String>? material,
    Value<String>? fabric,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return WardrobeComponentsCompanion(
      id: id ?? this.id,
      wardrobeId: wardrobeId ?? this.wardrobeId,
      name: name ?? this.name,
      componentType: componentType ?? this.componentType,
      material: material ?? this.material,
      fabric: fabric ?? this.fabric,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (wardrobeId.present) {
      map['wardrobe_id'] = Variable<String>(wardrobeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (componentType.present) {
      map['component_type'] = Variable<String>(componentType.value);
    }
    if (material.present) {
      map['material'] = Variable<String>(material.value);
    }
    if (fabric.present) {
      map['fabric'] = Variable<String>(fabric.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WardrobeComponentsCompanion(')
          ..write('id: $id, ')
          ..write('wardrobeId: $wardrobeId, ')
          ..write('name: $name, ')
          ..write('componentType: $componentType, ')
          ..write('material: $material, ')
          ..write('fabric: $fabric, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WardrobeColorsTable extends WardrobeColors
    with TableInfo<$WardrobeColorsTable, WardrobeColor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WardrobeColorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wardrobeIdMeta = const VerificationMeta(
    'wardrobeId',
  );
  @override
  late final GeneratedColumn<String> wardrobeId = GeneratedColumn<String>(
    'wardrobe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hexValueMeta = const VerificationMeta(
    'hexValue',
  );
  @override
  late final GeneratedColumn<String> hexValue = GeneratedColumn<String>(
    'hex_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usageMeta = const VerificationMeta('usage');
  @override
  late final GeneratedColumn<String> usage = GeneratedColumn<String>(
    'usage',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    wardrobeId,
    name,
    hexValue,
    usage,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wardrobe_colors';
  @override
  VerificationContext validateIntegrity(
    Insertable<WardrobeColor> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('wardrobe_id')) {
      context.handle(
        _wardrobeIdMeta,
        wardrobeId.isAcceptableOrUnknown(data['wardrobe_id']!, _wardrobeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wardrobeIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('hex_value')) {
      context.handle(
        _hexValueMeta,
        hexValue.isAcceptableOrUnknown(data['hex_value']!, _hexValueMeta),
      );
    } else if (isInserting) {
      context.missing(_hexValueMeta);
    }
    if (data.containsKey('usage')) {
      context.handle(
        _usageMeta,
        usage.isAcceptableOrUnknown(data['usage']!, _usageMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WardrobeColor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WardrobeColor(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      wardrobeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wardrobe_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      hexValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hex_value'],
      )!,
      usage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}usage'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $WardrobeColorsTable createAlias(String alias) {
    return $WardrobeColorsTable(attachedDatabase, alias);
  }
}

class WardrobeColor extends DataClass implements Insertable<WardrobeColor> {
  final String id;
  final String wardrobeId;
  final String name;
  final String hexValue;
  final String usage;
  final int sortOrder;
  const WardrobeColor({
    required this.id,
    required this.wardrobeId,
    required this.name,
    required this.hexValue,
    required this.usage,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['wardrobe_id'] = Variable<String>(wardrobeId);
    map['name'] = Variable<String>(name);
    map['hex_value'] = Variable<String>(hexValue);
    map['usage'] = Variable<String>(usage);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  WardrobeColorsCompanion toCompanion(bool nullToAbsent) {
    return WardrobeColorsCompanion(
      id: Value(id),
      wardrobeId: Value(wardrobeId),
      name: Value(name),
      hexValue: Value(hexValue),
      usage: Value(usage),
      sortOrder: Value(sortOrder),
    );
  }

  factory WardrobeColor.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WardrobeColor(
      id: serializer.fromJson<String>(json['id']),
      wardrobeId: serializer.fromJson<String>(json['wardrobeId']),
      name: serializer.fromJson<String>(json['name']),
      hexValue: serializer.fromJson<String>(json['hexValue']),
      usage: serializer.fromJson<String>(json['usage']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'wardrobeId': serializer.toJson<String>(wardrobeId),
      'name': serializer.toJson<String>(name),
      'hexValue': serializer.toJson<String>(hexValue),
      'usage': serializer.toJson<String>(usage),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  WardrobeColor copyWith({
    String? id,
    String? wardrobeId,
    String? name,
    String? hexValue,
    String? usage,
    int? sortOrder,
  }) => WardrobeColor(
    id: id ?? this.id,
    wardrobeId: wardrobeId ?? this.wardrobeId,
    name: name ?? this.name,
    hexValue: hexValue ?? this.hexValue,
    usage: usage ?? this.usage,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  WardrobeColor copyWithCompanion(WardrobeColorsCompanion data) {
    return WardrobeColor(
      id: data.id.present ? data.id.value : this.id,
      wardrobeId: data.wardrobeId.present
          ? data.wardrobeId.value
          : this.wardrobeId,
      name: data.name.present ? data.name.value : this.name,
      hexValue: data.hexValue.present ? data.hexValue.value : this.hexValue,
      usage: data.usage.present ? data.usage.value : this.usage,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WardrobeColor(')
          ..write('id: $id, ')
          ..write('wardrobeId: $wardrobeId, ')
          ..write('name: $name, ')
          ..write('hexValue: $hexValue, ')
          ..write('usage: $usage, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, wardrobeId, name, hexValue, usage, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WardrobeColor &&
          other.id == this.id &&
          other.wardrobeId == this.wardrobeId &&
          other.name == this.name &&
          other.hexValue == this.hexValue &&
          other.usage == this.usage &&
          other.sortOrder == this.sortOrder);
}

class WardrobeColorsCompanion extends UpdateCompanion<WardrobeColor> {
  final Value<String> id;
  final Value<String> wardrobeId;
  final Value<String> name;
  final Value<String> hexValue;
  final Value<String> usage;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const WardrobeColorsCompanion({
    this.id = const Value.absent(),
    this.wardrobeId = const Value.absent(),
    this.name = const Value.absent(),
    this.hexValue = const Value.absent(),
    this.usage = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WardrobeColorsCompanion.insert({
    required String id,
    required String wardrobeId,
    required String name,
    required String hexValue,
    this.usage = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       wardrobeId = Value(wardrobeId),
       name = Value(name),
       hexValue = Value(hexValue);
  static Insertable<WardrobeColor> custom({
    Expression<String>? id,
    Expression<String>? wardrobeId,
    Expression<String>? name,
    Expression<String>? hexValue,
    Expression<String>? usage,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wardrobeId != null) 'wardrobe_id': wardrobeId,
      if (name != null) 'name': name,
      if (hexValue != null) 'hex_value': hexValue,
      if (usage != null) 'usage': usage,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WardrobeColorsCompanion copyWith({
    Value<String>? id,
    Value<String>? wardrobeId,
    Value<String>? name,
    Value<String>? hexValue,
    Value<String>? usage,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return WardrobeColorsCompanion(
      id: id ?? this.id,
      wardrobeId: wardrobeId ?? this.wardrobeId,
      name: name ?? this.name,
      hexValue: hexValue ?? this.hexValue,
      usage: usage ?? this.usage,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (wardrobeId.present) {
      map['wardrobe_id'] = Variable<String>(wardrobeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (hexValue.present) {
      map['hex_value'] = Variable<String>(hexValue.value);
    }
    if (usage.present) {
      map['usage'] = Variable<String>(usage.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WardrobeColorsCompanion(')
          ..write('id: $id, ')
          ..write('wardrobeId: $wardrobeId, ')
          ..write('name: $name, ')
          ..write('hexValue: $hexValue, ')
          ..write('usage: $usage, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WardrobeVariantsTable extends WardrobeVariants
    with TableInfo<$WardrobeVariantsTable, WardrobeVariant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WardrobeVariantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wardrobeIdMeta = const VerificationMeta(
    'wardrobeId',
  );
  @override
  late final GeneratedColumn<String> wardrobeId = GeneratedColumn<String>(
    'wardrobe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    wardrobeId,
    name,
    description,
    isDefault,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wardrobe_variants';
  @override
  VerificationContext validateIntegrity(
    Insertable<WardrobeVariant> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('wardrobe_id')) {
      context.handle(
        _wardrobeIdMeta,
        wardrobeId.isAcceptableOrUnknown(data['wardrobe_id']!, _wardrobeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wardrobeIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WardrobeVariant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WardrobeVariant(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      wardrobeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wardrobe_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
    );
  }

  @override
  $WardrobeVariantsTable createAlias(String alias) {
    return $WardrobeVariantsTable(attachedDatabase, alias);
  }
}

class WardrobeVariant extends DataClass implements Insertable<WardrobeVariant> {
  final String id;
  final String wardrobeId;
  final String name;
  final String description;
  final bool isDefault;
  const WardrobeVariant({
    required this.id,
    required this.wardrobeId,
    required this.name,
    required this.description,
    required this.isDefault,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['wardrobe_id'] = Variable<String>(wardrobeId);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['is_default'] = Variable<bool>(isDefault);
    return map;
  }

  WardrobeVariantsCompanion toCompanion(bool nullToAbsent) {
    return WardrobeVariantsCompanion(
      id: Value(id),
      wardrobeId: Value(wardrobeId),
      name: Value(name),
      description: Value(description),
      isDefault: Value(isDefault),
    );
  }

  factory WardrobeVariant.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WardrobeVariant(
      id: serializer.fromJson<String>(json['id']),
      wardrobeId: serializer.fromJson<String>(json['wardrobeId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'wardrobeId': serializer.toJson<String>(wardrobeId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'isDefault': serializer.toJson<bool>(isDefault),
    };
  }

  WardrobeVariant copyWith({
    String? id,
    String? wardrobeId,
    String? name,
    String? description,
    bool? isDefault,
  }) => WardrobeVariant(
    id: id ?? this.id,
    wardrobeId: wardrobeId ?? this.wardrobeId,
    name: name ?? this.name,
    description: description ?? this.description,
    isDefault: isDefault ?? this.isDefault,
  );
  WardrobeVariant copyWithCompanion(WardrobeVariantsCompanion data) {
    return WardrobeVariant(
      id: data.id.present ? data.id.value : this.id,
      wardrobeId: data.wardrobeId.present
          ? data.wardrobeId.value
          : this.wardrobeId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WardrobeVariant(')
          ..write('id: $id, ')
          ..write('wardrobeId: $wardrobeId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, wardrobeId, name, description, isDefault);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WardrobeVariant &&
          other.id == this.id &&
          other.wardrobeId == this.wardrobeId &&
          other.name == this.name &&
          other.description == this.description &&
          other.isDefault == this.isDefault);
}

class WardrobeVariantsCompanion extends UpdateCompanion<WardrobeVariant> {
  final Value<String> id;
  final Value<String> wardrobeId;
  final Value<String> name;
  final Value<String> description;
  final Value<bool> isDefault;
  final Value<int> rowid;
  const WardrobeVariantsCompanion({
    this.id = const Value.absent(),
    this.wardrobeId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WardrobeVariantsCompanion.insert({
    required String id,
    required String wardrobeId,
    required String name,
    this.description = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       wardrobeId = Value(wardrobeId),
       name = Value(name);
  static Insertable<WardrobeVariant> custom({
    Expression<String>? id,
    Expression<String>? wardrobeId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<bool>? isDefault,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wardrobeId != null) 'wardrobe_id': wardrobeId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (isDefault != null) 'is_default': isDefault,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WardrobeVariantsCompanion copyWith({
    Value<String>? id,
    Value<String>? wardrobeId,
    Value<String>? name,
    Value<String>? description,
    Value<bool>? isDefault,
    Value<int>? rowid,
  }) {
    return WardrobeVariantsCompanion(
      id: id ?? this.id,
      wardrobeId: wardrobeId ?? this.wardrobeId,
      name: name ?? this.name,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (wardrobeId.present) {
      map['wardrobe_id'] = Variable<String>(wardrobeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WardrobeVariantsCompanion(')
          ..write('id: $id, ')
          ..write('wardrobeId: $wardrobeId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('isDefault: $isDefault, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WardrobeReferencesTable extends WardrobeReferences
    with TableInfo<$WardrobeReferencesTable, WardrobeReference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WardrobeReferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wardrobeIdMeta = const VerificationMeta(
    'wardrobeId',
  );
  @override
  late final GeneratedColumn<String> wardrobeId = GeneratedColumn<String>(
    'wardrobe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceTypeMeta = const VerificationMeta(
    'referenceType',
  );
  @override
  late final GeneratedColumn<String> referenceType = GeneratedColumn<String>(
    'reference_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    wardrobeId,
    referenceType,
    filePath,
    priority,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wardrobe_references';
  @override
  VerificationContext validateIntegrity(
    Insertable<WardrobeReference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('wardrobe_id')) {
      context.handle(
        _wardrobeIdMeta,
        wardrobeId.isAcceptableOrUnknown(data['wardrobe_id']!, _wardrobeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wardrobeIdMeta);
    }
    if (data.containsKey('reference_type')) {
      context.handle(
        _referenceTypeMeta,
        referenceType.isAcceptableOrUnknown(
          data['reference_type']!,
          _referenceTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_referenceTypeMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WardrobeReference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WardrobeReference(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      wardrobeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wardrobe_id'],
      )!,
      referenceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_type'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
    );
  }

  @override
  $WardrobeReferencesTable createAlias(String alias) {
    return $WardrobeReferencesTable(attachedDatabase, alias);
  }
}

class WardrobeReference extends DataClass
    implements Insertable<WardrobeReference> {
  final String id;
  final String wardrobeId;
  final String referenceType;
  final String filePath;
  final int priority;
  const WardrobeReference({
    required this.id,
    required this.wardrobeId,
    required this.referenceType,
    required this.filePath,
    required this.priority,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['wardrobe_id'] = Variable<String>(wardrobeId);
    map['reference_type'] = Variable<String>(referenceType);
    map['file_path'] = Variable<String>(filePath);
    map['priority'] = Variable<int>(priority);
    return map;
  }

  WardrobeReferencesCompanion toCompanion(bool nullToAbsent) {
    return WardrobeReferencesCompanion(
      id: Value(id),
      wardrobeId: Value(wardrobeId),
      referenceType: Value(referenceType),
      filePath: Value(filePath),
      priority: Value(priority),
    );
  }

  factory WardrobeReference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WardrobeReference(
      id: serializer.fromJson<String>(json['id']),
      wardrobeId: serializer.fromJson<String>(json['wardrobeId']),
      referenceType: serializer.fromJson<String>(json['referenceType']),
      filePath: serializer.fromJson<String>(json['filePath']),
      priority: serializer.fromJson<int>(json['priority']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'wardrobeId': serializer.toJson<String>(wardrobeId),
      'referenceType': serializer.toJson<String>(referenceType),
      'filePath': serializer.toJson<String>(filePath),
      'priority': serializer.toJson<int>(priority),
    };
  }

  WardrobeReference copyWith({
    String? id,
    String? wardrobeId,
    String? referenceType,
    String? filePath,
    int? priority,
  }) => WardrobeReference(
    id: id ?? this.id,
    wardrobeId: wardrobeId ?? this.wardrobeId,
    referenceType: referenceType ?? this.referenceType,
    filePath: filePath ?? this.filePath,
    priority: priority ?? this.priority,
  );
  WardrobeReference copyWithCompanion(WardrobeReferencesCompanion data) {
    return WardrobeReference(
      id: data.id.present ? data.id.value : this.id,
      wardrobeId: data.wardrobeId.present
          ? data.wardrobeId.value
          : this.wardrobeId,
      referenceType: data.referenceType.present
          ? data.referenceType.value
          : this.referenceType,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      priority: data.priority.present ? data.priority.value : this.priority,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WardrobeReference(')
          ..write('id: $id, ')
          ..write('wardrobeId: $wardrobeId, ')
          ..write('referenceType: $referenceType, ')
          ..write('filePath: $filePath, ')
          ..write('priority: $priority')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, wardrobeId, referenceType, filePath, priority);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WardrobeReference &&
          other.id == this.id &&
          other.wardrobeId == this.wardrobeId &&
          other.referenceType == this.referenceType &&
          other.filePath == this.filePath &&
          other.priority == this.priority);
}

class WardrobeReferencesCompanion extends UpdateCompanion<WardrobeReference> {
  final Value<String> id;
  final Value<String> wardrobeId;
  final Value<String> referenceType;
  final Value<String> filePath;
  final Value<int> priority;
  final Value<int> rowid;
  const WardrobeReferencesCompanion({
    this.id = const Value.absent(),
    this.wardrobeId = const Value.absent(),
    this.referenceType = const Value.absent(),
    this.filePath = const Value.absent(),
    this.priority = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WardrobeReferencesCompanion.insert({
    required String id,
    required String wardrobeId,
    required String referenceType,
    required String filePath,
    this.priority = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       wardrobeId = Value(wardrobeId),
       referenceType = Value(referenceType),
       filePath = Value(filePath);
  static Insertable<WardrobeReference> custom({
    Expression<String>? id,
    Expression<String>? wardrobeId,
    Expression<String>? referenceType,
    Expression<String>? filePath,
    Expression<int>? priority,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wardrobeId != null) 'wardrobe_id': wardrobeId,
      if (referenceType != null) 'reference_type': referenceType,
      if (filePath != null) 'file_path': filePath,
      if (priority != null) 'priority': priority,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WardrobeReferencesCompanion copyWith({
    Value<String>? id,
    Value<String>? wardrobeId,
    Value<String>? referenceType,
    Value<String>? filePath,
    Value<int>? priority,
    Value<int>? rowid,
  }) {
    return WardrobeReferencesCompanion(
      id: id ?? this.id,
      wardrobeId: wardrobeId ?? this.wardrobeId,
      referenceType: referenceType ?? this.referenceType,
      filePath: filePath ?? this.filePath,
      priority: priority ?? this.priority,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (wardrobeId.present) {
      map['wardrobe_id'] = Variable<String>(wardrobeId.value);
    }
    if (referenceType.present) {
      map['reference_type'] = Variable<String>(referenceType.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WardrobeReferencesCompanion(')
          ..write('id: $id, ')
          ..write('wardrobeId: $wardrobeId, ')
          ..write('referenceType: $referenceType, ')
          ..write('filePath: $filePath, ')
          ..write('priority: $priority, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeaponsTable extends Weapons with TableInfo<$WeaponsTable, Weapon> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeaponsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weaponTypeMeta = const VerificationMeta(
    'weaponType',
  );
  @override
  late final GeneratedColumn<String> weaponType = GeneratedColumn<String>(
    'weapon_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _primaryMaterialMeta = const VerificationMeta(
    'primaryMaterial',
  );
  @override
  late final GeneratedColumn<String> primaryMaterial = GeneratedColumn<String>(
    'primary_material',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _secondaryMaterialMeta = const VerificationMeta(
    'secondaryMaterial',
  );
  @override
  late final GeneratedColumn<String> secondaryMaterial =
      GeneratedColumn<String>(
        'secondary_material',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _energyTypeMeta = const VerificationMeta(
    'energyType',
  );
  @override
  late final GeneratedColumn<String> energyType = GeneratedColumn<String>(
    'energy_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _coreTypeMeta = const VerificationMeta(
    'coreType',
  );
  @override
  late final GeneratedColumn<String> coreType = GeneratedColumn<String>(
    'core_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _lengthMmMeta = const VerificationMeta(
    'lengthMm',
  );
  @override
  late final GeneratedColumn<double> lengthMm = GeneratedColumn<double>(
    'length_mm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    assetId,
    projectId,
    name,
    weaponType,
    description,
    primaryMaterial,
    secondaryMaterial,
    energyType,
    coreType,
    lengthMm,
    weightKg,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weapons';
  @override
  VerificationContext validateIntegrity(
    Insertable<Weapon> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('weapon_type')) {
      context.handle(
        _weaponTypeMeta,
        weaponType.isAcceptableOrUnknown(data['weapon_type']!, _weaponTypeMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('primary_material')) {
      context.handle(
        _primaryMaterialMeta,
        primaryMaterial.isAcceptableOrUnknown(
          data['primary_material']!,
          _primaryMaterialMeta,
        ),
      );
    }
    if (data.containsKey('secondary_material')) {
      context.handle(
        _secondaryMaterialMeta,
        secondaryMaterial.isAcceptableOrUnknown(
          data['secondary_material']!,
          _secondaryMaterialMeta,
        ),
      );
    }
    if (data.containsKey('energy_type')) {
      context.handle(
        _energyTypeMeta,
        energyType.isAcceptableOrUnknown(data['energy_type']!, _energyTypeMeta),
      );
    }
    if (data.containsKey('core_type')) {
      context.handle(
        _coreTypeMeta,
        coreType.isAcceptableOrUnknown(data['core_type']!, _coreTypeMeta),
      );
    }
    if (data.containsKey('length_mm')) {
      context.handle(
        _lengthMmMeta,
        lengthMm.isAcceptableOrUnknown(data['length_mm']!, _lengthMmMeta),
      );
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {assetId};
  @override
  Weapon map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Weapon(
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      weaponType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weapon_type'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      primaryMaterial: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}primary_material'],
      )!,
      secondaryMaterial: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}secondary_material'],
      )!,
      energyType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}energy_type'],
      )!,
      coreType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}core_type'],
      )!,
      lengthMm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}length_mm'],
      ),
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
    );
  }

  @override
  $WeaponsTable createAlias(String alias) {
    return $WeaponsTable(attachedDatabase, alias);
  }
}

class Weapon extends DataClass implements Insertable<Weapon> {
  final String assetId;
  final String projectId;
  final String name;
  final String weaponType;
  final String description;
  final String primaryMaterial;
  final String secondaryMaterial;
  final String energyType;
  final String coreType;
  final double? lengthMm;
  final double? weightKg;
  final String notes;
  const Weapon({
    required this.assetId,
    required this.projectId,
    required this.name,
    required this.weaponType,
    required this.description,
    required this.primaryMaterial,
    required this.secondaryMaterial,
    required this.energyType,
    required this.coreType,
    this.lengthMm,
    this.weightKg,
    required this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['asset_id'] = Variable<String>(assetId);
    map['project_id'] = Variable<String>(projectId);
    map['name'] = Variable<String>(name);
    map['weapon_type'] = Variable<String>(weaponType);
    map['description'] = Variable<String>(description);
    map['primary_material'] = Variable<String>(primaryMaterial);
    map['secondary_material'] = Variable<String>(secondaryMaterial);
    map['energy_type'] = Variable<String>(energyType);
    map['core_type'] = Variable<String>(coreType);
    if (!nullToAbsent || lengthMm != null) {
      map['length_mm'] = Variable<double>(lengthMm);
    }
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    map['notes'] = Variable<String>(notes);
    return map;
  }

  WeaponsCompanion toCompanion(bool nullToAbsent) {
    return WeaponsCompanion(
      assetId: Value(assetId),
      projectId: Value(projectId),
      name: Value(name),
      weaponType: Value(weaponType),
      description: Value(description),
      primaryMaterial: Value(primaryMaterial),
      secondaryMaterial: Value(secondaryMaterial),
      energyType: Value(energyType),
      coreType: Value(coreType),
      lengthMm: lengthMm == null && nullToAbsent
          ? const Value.absent()
          : Value(lengthMm),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      notes: Value(notes),
    );
  }

  factory Weapon.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Weapon(
      assetId: serializer.fromJson<String>(json['assetId']),
      projectId: serializer.fromJson<String>(json['projectId']),
      name: serializer.fromJson<String>(json['name']),
      weaponType: serializer.fromJson<String>(json['weaponType']),
      description: serializer.fromJson<String>(json['description']),
      primaryMaterial: serializer.fromJson<String>(json['primaryMaterial']),
      secondaryMaterial: serializer.fromJson<String>(json['secondaryMaterial']),
      energyType: serializer.fromJson<String>(json['energyType']),
      coreType: serializer.fromJson<String>(json['coreType']),
      lengthMm: serializer.fromJson<double?>(json['lengthMm']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      notes: serializer.fromJson<String>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'assetId': serializer.toJson<String>(assetId),
      'projectId': serializer.toJson<String>(projectId),
      'name': serializer.toJson<String>(name),
      'weaponType': serializer.toJson<String>(weaponType),
      'description': serializer.toJson<String>(description),
      'primaryMaterial': serializer.toJson<String>(primaryMaterial),
      'secondaryMaterial': serializer.toJson<String>(secondaryMaterial),
      'energyType': serializer.toJson<String>(energyType),
      'coreType': serializer.toJson<String>(coreType),
      'lengthMm': serializer.toJson<double?>(lengthMm),
      'weightKg': serializer.toJson<double?>(weightKg),
      'notes': serializer.toJson<String>(notes),
    };
  }

  Weapon copyWith({
    String? assetId,
    String? projectId,
    String? name,
    String? weaponType,
    String? description,
    String? primaryMaterial,
    String? secondaryMaterial,
    String? energyType,
    String? coreType,
    Value<double?> lengthMm = const Value.absent(),
    Value<double?> weightKg = const Value.absent(),
    String? notes,
  }) => Weapon(
    assetId: assetId ?? this.assetId,
    projectId: projectId ?? this.projectId,
    name: name ?? this.name,
    weaponType: weaponType ?? this.weaponType,
    description: description ?? this.description,
    primaryMaterial: primaryMaterial ?? this.primaryMaterial,
    secondaryMaterial: secondaryMaterial ?? this.secondaryMaterial,
    energyType: energyType ?? this.energyType,
    coreType: coreType ?? this.coreType,
    lengthMm: lengthMm.present ? lengthMm.value : this.lengthMm,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    notes: notes ?? this.notes,
  );
  Weapon copyWithCompanion(WeaponsCompanion data) {
    return Weapon(
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      name: data.name.present ? data.name.value : this.name,
      weaponType: data.weaponType.present
          ? data.weaponType.value
          : this.weaponType,
      description: data.description.present
          ? data.description.value
          : this.description,
      primaryMaterial: data.primaryMaterial.present
          ? data.primaryMaterial.value
          : this.primaryMaterial,
      secondaryMaterial: data.secondaryMaterial.present
          ? data.secondaryMaterial.value
          : this.secondaryMaterial,
      energyType: data.energyType.present
          ? data.energyType.value
          : this.energyType,
      coreType: data.coreType.present ? data.coreType.value : this.coreType,
      lengthMm: data.lengthMm.present ? data.lengthMm.value : this.lengthMm,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Weapon(')
          ..write('assetId: $assetId, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('weaponType: $weaponType, ')
          ..write('description: $description, ')
          ..write('primaryMaterial: $primaryMaterial, ')
          ..write('secondaryMaterial: $secondaryMaterial, ')
          ..write('energyType: $energyType, ')
          ..write('coreType: $coreType, ')
          ..write('lengthMm: $lengthMm, ')
          ..write('weightKg: $weightKg, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    assetId,
    projectId,
    name,
    weaponType,
    description,
    primaryMaterial,
    secondaryMaterial,
    energyType,
    coreType,
    lengthMm,
    weightKg,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Weapon &&
          other.assetId == this.assetId &&
          other.projectId == this.projectId &&
          other.name == this.name &&
          other.weaponType == this.weaponType &&
          other.description == this.description &&
          other.primaryMaterial == this.primaryMaterial &&
          other.secondaryMaterial == this.secondaryMaterial &&
          other.energyType == this.energyType &&
          other.coreType == this.coreType &&
          other.lengthMm == this.lengthMm &&
          other.weightKg == this.weightKg &&
          other.notes == this.notes);
}

class WeaponsCompanion extends UpdateCompanion<Weapon> {
  final Value<String> assetId;
  final Value<String> projectId;
  final Value<String> name;
  final Value<String> weaponType;
  final Value<String> description;
  final Value<String> primaryMaterial;
  final Value<String> secondaryMaterial;
  final Value<String> energyType;
  final Value<String> coreType;
  final Value<double?> lengthMm;
  final Value<double?> weightKg;
  final Value<String> notes;
  final Value<int> rowid;
  const WeaponsCompanion({
    this.assetId = const Value.absent(),
    this.projectId = const Value.absent(),
    this.name = const Value.absent(),
    this.weaponType = const Value.absent(),
    this.description = const Value.absent(),
    this.primaryMaterial = const Value.absent(),
    this.secondaryMaterial = const Value.absent(),
    this.energyType = const Value.absent(),
    this.coreType = const Value.absent(),
    this.lengthMm = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeaponsCompanion.insert({
    required String assetId,
    required String projectId,
    required String name,
    this.weaponType = const Value.absent(),
    this.description = const Value.absent(),
    this.primaryMaterial = const Value.absent(),
    this.secondaryMaterial = const Value.absent(),
    this.energyType = const Value.absent(),
    this.coreType = const Value.absent(),
    this.lengthMm = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : assetId = Value(assetId),
       projectId = Value(projectId),
       name = Value(name);
  static Insertable<Weapon> custom({
    Expression<String>? assetId,
    Expression<String>? projectId,
    Expression<String>? name,
    Expression<String>? weaponType,
    Expression<String>? description,
    Expression<String>? primaryMaterial,
    Expression<String>? secondaryMaterial,
    Expression<String>? energyType,
    Expression<String>? coreType,
    Expression<double>? lengthMm,
    Expression<double>? weightKg,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (assetId != null) 'asset_id': assetId,
      if (projectId != null) 'project_id': projectId,
      if (name != null) 'name': name,
      if (weaponType != null) 'weapon_type': weaponType,
      if (description != null) 'description': description,
      if (primaryMaterial != null) 'primary_material': primaryMaterial,
      if (secondaryMaterial != null) 'secondary_material': secondaryMaterial,
      if (energyType != null) 'energy_type': energyType,
      if (coreType != null) 'core_type': coreType,
      if (lengthMm != null) 'length_mm': lengthMm,
      if (weightKg != null) 'weight_kg': weightKg,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeaponsCompanion copyWith({
    Value<String>? assetId,
    Value<String>? projectId,
    Value<String>? name,
    Value<String>? weaponType,
    Value<String>? description,
    Value<String>? primaryMaterial,
    Value<String>? secondaryMaterial,
    Value<String>? energyType,
    Value<String>? coreType,
    Value<double?>? lengthMm,
    Value<double?>? weightKg,
    Value<String>? notes,
    Value<int>? rowid,
  }) {
    return WeaponsCompanion(
      assetId: assetId ?? this.assetId,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      weaponType: weaponType ?? this.weaponType,
      description: description ?? this.description,
      primaryMaterial: primaryMaterial ?? this.primaryMaterial,
      secondaryMaterial: secondaryMaterial ?? this.secondaryMaterial,
      energyType: energyType ?? this.energyType,
      coreType: coreType ?? this.coreType,
      lengthMm: lengthMm ?? this.lengthMm,
      weightKg: weightKg ?? this.weightKg,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (weaponType.present) {
      map['weapon_type'] = Variable<String>(weaponType.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (primaryMaterial.present) {
      map['primary_material'] = Variable<String>(primaryMaterial.value);
    }
    if (secondaryMaterial.present) {
      map['secondary_material'] = Variable<String>(secondaryMaterial.value);
    }
    if (energyType.present) {
      map['energy_type'] = Variable<String>(energyType.value);
    }
    if (coreType.present) {
      map['core_type'] = Variable<String>(coreType.value);
    }
    if (lengthMm.present) {
      map['length_mm'] = Variable<double>(lengthMm.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeaponsCompanion(')
          ..write('assetId: $assetId, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('weaponType: $weaponType, ')
          ..write('description: $description, ')
          ..write('primaryMaterial: $primaryMaterial, ')
          ..write('secondaryMaterial: $secondaryMaterial, ')
          ..write('energyType: $energyType, ')
          ..write('coreType: $coreType, ')
          ..write('lengthMm: $lengthMm, ')
          ..write('weightKg: $weightKg, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeaponComponentsTable extends WeaponComponents
    with TableInfo<$WeaponComponentsTable, WeaponComponent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeaponComponentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weaponIdMeta = const VerificationMeta(
    'weaponId',
  );
  @override
  late final GeneratedColumn<String> weaponId = GeneratedColumn<String>(
    'weapon_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _componentTypeMeta = const VerificationMeta(
    'componentType',
  );
  @override
  late final GeneratedColumn<String> componentType = GeneratedColumn<String>(
    'component_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _materialMeta = const VerificationMeta(
    'material',
  );
  @override
  late final GeneratedColumn<String> material = GeneratedColumn<String>(
    'material',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    weaponId,
    name,
    componentType,
    material,
    description,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weapon_components';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeaponComponent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('weapon_id')) {
      context.handle(
        _weaponIdMeta,
        weaponId.isAcceptableOrUnknown(data['weapon_id']!, _weaponIdMeta),
      );
    } else if (isInserting) {
      context.missing(_weaponIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('component_type')) {
      context.handle(
        _componentTypeMeta,
        componentType.isAcceptableOrUnknown(
          data['component_type']!,
          _componentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_componentTypeMeta);
    }
    if (data.containsKey('material')) {
      context.handle(
        _materialMeta,
        material.isAcceptableOrUnknown(data['material']!, _materialMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeaponComponent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeaponComponent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      weaponId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weapon_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      componentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}component_type'],
      )!,
      material: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}material'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $WeaponComponentsTable createAlias(String alias) {
    return $WeaponComponentsTable(attachedDatabase, alias);
  }
}

class WeaponComponent extends DataClass implements Insertable<WeaponComponent> {
  final String id;
  final String weaponId;
  final String name;
  final String componentType;
  final String material;
  final String description;
  final int sortOrder;
  const WeaponComponent({
    required this.id,
    required this.weaponId,
    required this.name,
    required this.componentType,
    required this.material,
    required this.description,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['weapon_id'] = Variable<String>(weaponId);
    map['name'] = Variable<String>(name);
    map['component_type'] = Variable<String>(componentType);
    map['material'] = Variable<String>(material);
    map['description'] = Variable<String>(description);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  WeaponComponentsCompanion toCompanion(bool nullToAbsent) {
    return WeaponComponentsCompanion(
      id: Value(id),
      weaponId: Value(weaponId),
      name: Value(name),
      componentType: Value(componentType),
      material: Value(material),
      description: Value(description),
      sortOrder: Value(sortOrder),
    );
  }

  factory WeaponComponent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeaponComponent(
      id: serializer.fromJson<String>(json['id']),
      weaponId: serializer.fromJson<String>(json['weaponId']),
      name: serializer.fromJson<String>(json['name']),
      componentType: serializer.fromJson<String>(json['componentType']),
      material: serializer.fromJson<String>(json['material']),
      description: serializer.fromJson<String>(json['description']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'weaponId': serializer.toJson<String>(weaponId),
      'name': serializer.toJson<String>(name),
      'componentType': serializer.toJson<String>(componentType),
      'material': serializer.toJson<String>(material),
      'description': serializer.toJson<String>(description),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  WeaponComponent copyWith({
    String? id,
    String? weaponId,
    String? name,
    String? componentType,
    String? material,
    String? description,
    int? sortOrder,
  }) => WeaponComponent(
    id: id ?? this.id,
    weaponId: weaponId ?? this.weaponId,
    name: name ?? this.name,
    componentType: componentType ?? this.componentType,
    material: material ?? this.material,
    description: description ?? this.description,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  WeaponComponent copyWithCompanion(WeaponComponentsCompanion data) {
    return WeaponComponent(
      id: data.id.present ? data.id.value : this.id,
      weaponId: data.weaponId.present ? data.weaponId.value : this.weaponId,
      name: data.name.present ? data.name.value : this.name,
      componentType: data.componentType.present
          ? data.componentType.value
          : this.componentType,
      material: data.material.present ? data.material.value : this.material,
      description: data.description.present
          ? data.description.value
          : this.description,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeaponComponent(')
          ..write('id: $id, ')
          ..write('weaponId: $weaponId, ')
          ..write('name: $name, ')
          ..write('componentType: $componentType, ')
          ..write('material: $material, ')
          ..write('description: $description, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    weaponId,
    name,
    componentType,
    material,
    description,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeaponComponent &&
          other.id == this.id &&
          other.weaponId == this.weaponId &&
          other.name == this.name &&
          other.componentType == this.componentType &&
          other.material == this.material &&
          other.description == this.description &&
          other.sortOrder == this.sortOrder);
}

class WeaponComponentsCompanion extends UpdateCompanion<WeaponComponent> {
  final Value<String> id;
  final Value<String> weaponId;
  final Value<String> name;
  final Value<String> componentType;
  final Value<String> material;
  final Value<String> description;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const WeaponComponentsCompanion({
    this.id = const Value.absent(),
    this.weaponId = const Value.absent(),
    this.name = const Value.absent(),
    this.componentType = const Value.absent(),
    this.material = const Value.absent(),
    this.description = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeaponComponentsCompanion.insert({
    required String id,
    required String weaponId,
    required String name,
    required String componentType,
    this.material = const Value.absent(),
    this.description = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       weaponId = Value(weaponId),
       name = Value(name),
       componentType = Value(componentType);
  static Insertable<WeaponComponent> custom({
    Expression<String>? id,
    Expression<String>? weaponId,
    Expression<String>? name,
    Expression<String>? componentType,
    Expression<String>? material,
    Expression<String>? description,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (weaponId != null) 'weapon_id': weaponId,
      if (name != null) 'name': name,
      if (componentType != null) 'component_type': componentType,
      if (material != null) 'material': material,
      if (description != null) 'description': description,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeaponComponentsCompanion copyWith({
    Value<String>? id,
    Value<String>? weaponId,
    Value<String>? name,
    Value<String>? componentType,
    Value<String>? material,
    Value<String>? description,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return WeaponComponentsCompanion(
      id: id ?? this.id,
      weaponId: weaponId ?? this.weaponId,
      name: name ?? this.name,
      componentType: componentType ?? this.componentType,
      material: material ?? this.material,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (weaponId.present) {
      map['weapon_id'] = Variable<String>(weaponId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (componentType.present) {
      map['component_type'] = Variable<String>(componentType.value);
    }
    if (material.present) {
      map['material'] = Variable<String>(material.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeaponComponentsCompanion(')
          ..write('id: $id, ')
          ..write('weaponId: $weaponId, ')
          ..write('name: $name, ')
          ..write('componentType: $componentType, ')
          ..write('material: $material, ')
          ..write('description: $description, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeaponMeasurementsTable extends WeaponMeasurements
    with TableInfo<$WeaponMeasurementsTable, WeaponMeasurement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeaponMeasurementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weaponIdMeta = const VerificationMeta(
    'weaponId',
  );
  @override
  late final GeneratedColumn<String> weaponId = GeneratedColumn<String>(
    'weapon_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    weaponId,
    label,
    value,
    unit,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weapon_measurements';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeaponMeasurement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('weapon_id')) {
      context.handle(
        _weaponIdMeta,
        weaponId.isAcceptableOrUnknown(data['weapon_id']!, _weaponIdMeta),
      );
    } else if (isInserting) {
      context.missing(_weaponIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeaponMeasurement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeaponMeasurement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      weaponId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weapon_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $WeaponMeasurementsTable createAlias(String alias) {
    return $WeaponMeasurementsTable(attachedDatabase, alias);
  }
}

class WeaponMeasurement extends DataClass
    implements Insertable<WeaponMeasurement> {
  final String id;
  final String weaponId;
  final String label;
  final double value;
  final String unit;
  final int sortOrder;
  const WeaponMeasurement({
    required this.id,
    required this.weaponId,
    required this.label,
    required this.value,
    required this.unit,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['weapon_id'] = Variable<String>(weaponId);
    map['label'] = Variable<String>(label);
    map['value'] = Variable<double>(value);
    map['unit'] = Variable<String>(unit);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  WeaponMeasurementsCompanion toCompanion(bool nullToAbsent) {
    return WeaponMeasurementsCompanion(
      id: Value(id),
      weaponId: Value(weaponId),
      label: Value(label),
      value: Value(value),
      unit: Value(unit),
      sortOrder: Value(sortOrder),
    );
  }

  factory WeaponMeasurement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeaponMeasurement(
      id: serializer.fromJson<String>(json['id']),
      weaponId: serializer.fromJson<String>(json['weaponId']),
      label: serializer.fromJson<String>(json['label']),
      value: serializer.fromJson<double>(json['value']),
      unit: serializer.fromJson<String>(json['unit']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'weaponId': serializer.toJson<String>(weaponId),
      'label': serializer.toJson<String>(label),
      'value': serializer.toJson<double>(value),
      'unit': serializer.toJson<String>(unit),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  WeaponMeasurement copyWith({
    String? id,
    String? weaponId,
    String? label,
    double? value,
    String? unit,
    int? sortOrder,
  }) => WeaponMeasurement(
    id: id ?? this.id,
    weaponId: weaponId ?? this.weaponId,
    label: label ?? this.label,
    value: value ?? this.value,
    unit: unit ?? this.unit,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  WeaponMeasurement copyWithCompanion(WeaponMeasurementsCompanion data) {
    return WeaponMeasurement(
      id: data.id.present ? data.id.value : this.id,
      weaponId: data.weaponId.present ? data.weaponId.value : this.weaponId,
      label: data.label.present ? data.label.value : this.label,
      value: data.value.present ? data.value.value : this.value,
      unit: data.unit.present ? data.unit.value : this.unit,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeaponMeasurement(')
          ..write('id: $id, ')
          ..write('weaponId: $weaponId, ')
          ..write('label: $label, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, weaponId, label, value, unit, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeaponMeasurement &&
          other.id == this.id &&
          other.weaponId == this.weaponId &&
          other.label == this.label &&
          other.value == this.value &&
          other.unit == this.unit &&
          other.sortOrder == this.sortOrder);
}

class WeaponMeasurementsCompanion extends UpdateCompanion<WeaponMeasurement> {
  final Value<String> id;
  final Value<String> weaponId;
  final Value<String> label;
  final Value<double> value;
  final Value<String> unit;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const WeaponMeasurementsCompanion({
    this.id = const Value.absent(),
    this.weaponId = const Value.absent(),
    this.label = const Value.absent(),
    this.value = const Value.absent(),
    this.unit = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeaponMeasurementsCompanion.insert({
    required String id,
    required String weaponId,
    required String label,
    required double value,
    required String unit,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       weaponId = Value(weaponId),
       label = Value(label),
       value = Value(value),
       unit = Value(unit);
  static Insertable<WeaponMeasurement> custom({
    Expression<String>? id,
    Expression<String>? weaponId,
    Expression<String>? label,
    Expression<double>? value,
    Expression<String>? unit,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (weaponId != null) 'weapon_id': weaponId,
      if (label != null) 'label': label,
      if (value != null) 'value': value,
      if (unit != null) 'unit': unit,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeaponMeasurementsCompanion copyWith({
    Value<String>? id,
    Value<String>? weaponId,
    Value<String>? label,
    Value<double>? value,
    Value<String>? unit,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return WeaponMeasurementsCompanion(
      id: id ?? this.id,
      weaponId: weaponId ?? this.weaponId,
      label: label ?? this.label,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (weaponId.present) {
      map['weapon_id'] = Variable<String>(weaponId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeaponMeasurementsCompanion(')
          ..write('id: $id, ')
          ..write('weaponId: $weaponId, ')
          ..write('label: $label, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeaponColorsTable extends WeaponColors
    with TableInfo<$WeaponColorsTable, WeaponColor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeaponColorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weaponIdMeta = const VerificationMeta(
    'weaponId',
  );
  @override
  late final GeneratedColumn<String> weaponId = GeneratedColumn<String>(
    'weapon_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hexValueMeta = const VerificationMeta(
    'hexValue',
  );
  @override
  late final GeneratedColumn<String> hexValue = GeneratedColumn<String>(
    'hex_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usageMeta = const VerificationMeta('usage');
  @override
  late final GeneratedColumn<String> usage = GeneratedColumn<String>(
    'usage',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    weaponId,
    name,
    hexValue,
    usage,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weapon_colors';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeaponColor> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('weapon_id')) {
      context.handle(
        _weaponIdMeta,
        weaponId.isAcceptableOrUnknown(data['weapon_id']!, _weaponIdMeta),
      );
    } else if (isInserting) {
      context.missing(_weaponIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('hex_value')) {
      context.handle(
        _hexValueMeta,
        hexValue.isAcceptableOrUnknown(data['hex_value']!, _hexValueMeta),
      );
    } else if (isInserting) {
      context.missing(_hexValueMeta);
    }
    if (data.containsKey('usage')) {
      context.handle(
        _usageMeta,
        usage.isAcceptableOrUnknown(data['usage']!, _usageMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeaponColor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeaponColor(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      weaponId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weapon_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      hexValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hex_value'],
      )!,
      usage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}usage'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $WeaponColorsTable createAlias(String alias) {
    return $WeaponColorsTable(attachedDatabase, alias);
  }
}

class WeaponColor extends DataClass implements Insertable<WeaponColor> {
  final String id;
  final String weaponId;
  final String name;
  final String hexValue;
  final String usage;
  final int sortOrder;
  const WeaponColor({
    required this.id,
    required this.weaponId,
    required this.name,
    required this.hexValue,
    required this.usage,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['weapon_id'] = Variable<String>(weaponId);
    map['name'] = Variable<String>(name);
    map['hex_value'] = Variable<String>(hexValue);
    map['usage'] = Variable<String>(usage);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  WeaponColorsCompanion toCompanion(bool nullToAbsent) {
    return WeaponColorsCompanion(
      id: Value(id),
      weaponId: Value(weaponId),
      name: Value(name),
      hexValue: Value(hexValue),
      usage: Value(usage),
      sortOrder: Value(sortOrder),
    );
  }

  factory WeaponColor.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeaponColor(
      id: serializer.fromJson<String>(json['id']),
      weaponId: serializer.fromJson<String>(json['weaponId']),
      name: serializer.fromJson<String>(json['name']),
      hexValue: serializer.fromJson<String>(json['hexValue']),
      usage: serializer.fromJson<String>(json['usage']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'weaponId': serializer.toJson<String>(weaponId),
      'name': serializer.toJson<String>(name),
      'hexValue': serializer.toJson<String>(hexValue),
      'usage': serializer.toJson<String>(usage),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  WeaponColor copyWith({
    String? id,
    String? weaponId,
    String? name,
    String? hexValue,
    String? usage,
    int? sortOrder,
  }) => WeaponColor(
    id: id ?? this.id,
    weaponId: weaponId ?? this.weaponId,
    name: name ?? this.name,
    hexValue: hexValue ?? this.hexValue,
    usage: usage ?? this.usage,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  WeaponColor copyWithCompanion(WeaponColorsCompanion data) {
    return WeaponColor(
      id: data.id.present ? data.id.value : this.id,
      weaponId: data.weaponId.present ? data.weaponId.value : this.weaponId,
      name: data.name.present ? data.name.value : this.name,
      hexValue: data.hexValue.present ? data.hexValue.value : this.hexValue,
      usage: data.usage.present ? data.usage.value : this.usage,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeaponColor(')
          ..write('id: $id, ')
          ..write('weaponId: $weaponId, ')
          ..write('name: $name, ')
          ..write('hexValue: $hexValue, ')
          ..write('usage: $usage, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, weaponId, name, hexValue, usage, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeaponColor &&
          other.id == this.id &&
          other.weaponId == this.weaponId &&
          other.name == this.name &&
          other.hexValue == this.hexValue &&
          other.usage == this.usage &&
          other.sortOrder == this.sortOrder);
}

class WeaponColorsCompanion extends UpdateCompanion<WeaponColor> {
  final Value<String> id;
  final Value<String> weaponId;
  final Value<String> name;
  final Value<String> hexValue;
  final Value<String> usage;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const WeaponColorsCompanion({
    this.id = const Value.absent(),
    this.weaponId = const Value.absent(),
    this.name = const Value.absent(),
    this.hexValue = const Value.absent(),
    this.usage = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeaponColorsCompanion.insert({
    required String id,
    required String weaponId,
    required String name,
    required String hexValue,
    this.usage = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       weaponId = Value(weaponId),
       name = Value(name),
       hexValue = Value(hexValue);
  static Insertable<WeaponColor> custom({
    Expression<String>? id,
    Expression<String>? weaponId,
    Expression<String>? name,
    Expression<String>? hexValue,
    Expression<String>? usage,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (weaponId != null) 'weapon_id': weaponId,
      if (name != null) 'name': name,
      if (hexValue != null) 'hex_value': hexValue,
      if (usage != null) 'usage': usage,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeaponColorsCompanion copyWith({
    Value<String>? id,
    Value<String>? weaponId,
    Value<String>? name,
    Value<String>? hexValue,
    Value<String>? usage,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return WeaponColorsCompanion(
      id: id ?? this.id,
      weaponId: weaponId ?? this.weaponId,
      name: name ?? this.name,
      hexValue: hexValue ?? this.hexValue,
      usage: usage ?? this.usage,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (weaponId.present) {
      map['weapon_id'] = Variable<String>(weaponId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (hexValue.present) {
      map['hex_value'] = Variable<String>(hexValue.value);
    }
    if (usage.present) {
      map['usage'] = Variable<String>(usage.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeaponColorsCompanion(')
          ..write('id: $id, ')
          ..write('weaponId: $weaponId, ')
          ..write('name: $name, ')
          ..write('hexValue: $hexValue, ')
          ..write('usage: $usage, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeaponEnergyProfilesTable extends WeaponEnergyProfiles
    with TableInfo<$WeaponEnergyProfilesTable, WeaponEnergyProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeaponEnergyProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _weaponIdMeta = const VerificationMeta(
    'weaponId',
  );
  @override
  late final GeneratedColumn<String> weaponId = GeneratedColumn<String>(
    'weapon_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _energyTypeMeta = const VerificationMeta(
    'energyType',
  );
  @override
  late final GeneratedColumn<String> energyType = GeneratedColumn<String>(
    'energy_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _coreTypeMeta = const VerificationMeta(
    'coreType',
  );
  @override
  late final GeneratedColumn<String> coreType = GeneratedColumn<String>(
    'core_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _activationMeta = const VerificationMeta(
    'activation',
  );
  @override
  late final GeneratedColumn<String> activation = GeneratedColumn<String>(
    'activation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _emissionColorMeta = const VerificationMeta(
    'emissionColor',
  );
  @override
  late final GeneratedColumn<String> emissionColor = GeneratedColumn<String>(
    'emission_color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _behaviorMeta = const VerificationMeta(
    'behavior',
  );
  @override
  late final GeneratedColumn<String> behavior = GeneratedColumn<String>(
    'behavior',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    weaponId,
    energyType,
    coreType,
    activation,
    emissionColor,
    behavior,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weapon_energy_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeaponEnergyProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('weapon_id')) {
      context.handle(
        _weaponIdMeta,
        weaponId.isAcceptableOrUnknown(data['weapon_id']!, _weaponIdMeta),
      );
    } else if (isInserting) {
      context.missing(_weaponIdMeta);
    }
    if (data.containsKey('energy_type')) {
      context.handle(
        _energyTypeMeta,
        energyType.isAcceptableOrUnknown(data['energy_type']!, _energyTypeMeta),
      );
    }
    if (data.containsKey('core_type')) {
      context.handle(
        _coreTypeMeta,
        coreType.isAcceptableOrUnknown(data['core_type']!, _coreTypeMeta),
      );
    }
    if (data.containsKey('activation')) {
      context.handle(
        _activationMeta,
        activation.isAcceptableOrUnknown(data['activation']!, _activationMeta),
      );
    }
    if (data.containsKey('emission_color')) {
      context.handle(
        _emissionColorMeta,
        emissionColor.isAcceptableOrUnknown(
          data['emission_color']!,
          _emissionColorMeta,
        ),
      );
    }
    if (data.containsKey('behavior')) {
      context.handle(
        _behaviorMeta,
        behavior.isAcceptableOrUnknown(data['behavior']!, _behaviorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {weaponId};
  @override
  WeaponEnergyProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeaponEnergyProfile(
      weaponId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weapon_id'],
      )!,
      energyType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}energy_type'],
      )!,
      coreType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}core_type'],
      )!,
      activation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activation'],
      )!,
      emissionColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emission_color'],
      )!,
      behavior: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}behavior'],
      )!,
    );
  }

  @override
  $WeaponEnergyProfilesTable createAlias(String alias) {
    return $WeaponEnergyProfilesTable(attachedDatabase, alias);
  }
}

class WeaponEnergyProfile extends DataClass
    implements Insertable<WeaponEnergyProfile> {
  final String weaponId;
  final String energyType;
  final String coreType;
  final String activation;
  final String emissionColor;
  final String behavior;
  const WeaponEnergyProfile({
    required this.weaponId,
    required this.energyType,
    required this.coreType,
    required this.activation,
    required this.emissionColor,
    required this.behavior,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['weapon_id'] = Variable<String>(weaponId);
    map['energy_type'] = Variable<String>(energyType);
    map['core_type'] = Variable<String>(coreType);
    map['activation'] = Variable<String>(activation);
    map['emission_color'] = Variable<String>(emissionColor);
    map['behavior'] = Variable<String>(behavior);
    return map;
  }

  WeaponEnergyProfilesCompanion toCompanion(bool nullToAbsent) {
    return WeaponEnergyProfilesCompanion(
      weaponId: Value(weaponId),
      energyType: Value(energyType),
      coreType: Value(coreType),
      activation: Value(activation),
      emissionColor: Value(emissionColor),
      behavior: Value(behavior),
    );
  }

  factory WeaponEnergyProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeaponEnergyProfile(
      weaponId: serializer.fromJson<String>(json['weaponId']),
      energyType: serializer.fromJson<String>(json['energyType']),
      coreType: serializer.fromJson<String>(json['coreType']),
      activation: serializer.fromJson<String>(json['activation']),
      emissionColor: serializer.fromJson<String>(json['emissionColor']),
      behavior: serializer.fromJson<String>(json['behavior']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'weaponId': serializer.toJson<String>(weaponId),
      'energyType': serializer.toJson<String>(energyType),
      'coreType': serializer.toJson<String>(coreType),
      'activation': serializer.toJson<String>(activation),
      'emissionColor': serializer.toJson<String>(emissionColor),
      'behavior': serializer.toJson<String>(behavior),
    };
  }

  WeaponEnergyProfile copyWith({
    String? weaponId,
    String? energyType,
    String? coreType,
    String? activation,
    String? emissionColor,
    String? behavior,
  }) => WeaponEnergyProfile(
    weaponId: weaponId ?? this.weaponId,
    energyType: energyType ?? this.energyType,
    coreType: coreType ?? this.coreType,
    activation: activation ?? this.activation,
    emissionColor: emissionColor ?? this.emissionColor,
    behavior: behavior ?? this.behavior,
  );
  WeaponEnergyProfile copyWithCompanion(WeaponEnergyProfilesCompanion data) {
    return WeaponEnergyProfile(
      weaponId: data.weaponId.present ? data.weaponId.value : this.weaponId,
      energyType: data.energyType.present
          ? data.energyType.value
          : this.energyType,
      coreType: data.coreType.present ? data.coreType.value : this.coreType,
      activation: data.activation.present
          ? data.activation.value
          : this.activation,
      emissionColor: data.emissionColor.present
          ? data.emissionColor.value
          : this.emissionColor,
      behavior: data.behavior.present ? data.behavior.value : this.behavior,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeaponEnergyProfile(')
          ..write('weaponId: $weaponId, ')
          ..write('energyType: $energyType, ')
          ..write('coreType: $coreType, ')
          ..write('activation: $activation, ')
          ..write('emissionColor: $emissionColor, ')
          ..write('behavior: $behavior')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    weaponId,
    energyType,
    coreType,
    activation,
    emissionColor,
    behavior,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeaponEnergyProfile &&
          other.weaponId == this.weaponId &&
          other.energyType == this.energyType &&
          other.coreType == this.coreType &&
          other.activation == this.activation &&
          other.emissionColor == this.emissionColor &&
          other.behavior == this.behavior);
}

class WeaponEnergyProfilesCompanion
    extends UpdateCompanion<WeaponEnergyProfile> {
  final Value<String> weaponId;
  final Value<String> energyType;
  final Value<String> coreType;
  final Value<String> activation;
  final Value<String> emissionColor;
  final Value<String> behavior;
  final Value<int> rowid;
  const WeaponEnergyProfilesCompanion({
    this.weaponId = const Value.absent(),
    this.energyType = const Value.absent(),
    this.coreType = const Value.absent(),
    this.activation = const Value.absent(),
    this.emissionColor = const Value.absent(),
    this.behavior = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeaponEnergyProfilesCompanion.insert({
    required String weaponId,
    this.energyType = const Value.absent(),
    this.coreType = const Value.absent(),
    this.activation = const Value.absent(),
    this.emissionColor = const Value.absent(),
    this.behavior = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : weaponId = Value(weaponId);
  static Insertable<WeaponEnergyProfile> custom({
    Expression<String>? weaponId,
    Expression<String>? energyType,
    Expression<String>? coreType,
    Expression<String>? activation,
    Expression<String>? emissionColor,
    Expression<String>? behavior,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (weaponId != null) 'weapon_id': weaponId,
      if (energyType != null) 'energy_type': energyType,
      if (coreType != null) 'core_type': coreType,
      if (activation != null) 'activation': activation,
      if (emissionColor != null) 'emission_color': emissionColor,
      if (behavior != null) 'behavior': behavior,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeaponEnergyProfilesCompanion copyWith({
    Value<String>? weaponId,
    Value<String>? energyType,
    Value<String>? coreType,
    Value<String>? activation,
    Value<String>? emissionColor,
    Value<String>? behavior,
    Value<int>? rowid,
  }) {
    return WeaponEnergyProfilesCompanion(
      weaponId: weaponId ?? this.weaponId,
      energyType: energyType ?? this.energyType,
      coreType: coreType ?? this.coreType,
      activation: activation ?? this.activation,
      emissionColor: emissionColor ?? this.emissionColor,
      behavior: behavior ?? this.behavior,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (weaponId.present) {
      map['weapon_id'] = Variable<String>(weaponId.value);
    }
    if (energyType.present) {
      map['energy_type'] = Variable<String>(energyType.value);
    }
    if (coreType.present) {
      map['core_type'] = Variable<String>(coreType.value);
    }
    if (activation.present) {
      map['activation'] = Variable<String>(activation.value);
    }
    if (emissionColor.present) {
      map['emission_color'] = Variable<String>(emissionColor.value);
    }
    if (behavior.present) {
      map['behavior'] = Variable<String>(behavior.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeaponEnergyProfilesCompanion(')
          ..write('weaponId: $weaponId, ')
          ..write('energyType: $energyType, ')
          ..write('coreType: $coreType, ')
          ..write('activation: $activation, ')
          ..write('emissionColor: $emissionColor, ')
          ..write('behavior: $behavior, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeaponVariantsTable extends WeaponVariants
    with TableInfo<$WeaponVariantsTable, WeaponVariant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeaponVariantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weaponIdMeta = const VerificationMeta(
    'weaponId',
  );
  @override
  late final GeneratedColumn<String> weaponId = GeneratedColumn<String>(
    'weapon_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    weaponId,
    name,
    description,
    isDefault,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weapon_variants';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeaponVariant> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('weapon_id')) {
      context.handle(
        _weaponIdMeta,
        weaponId.isAcceptableOrUnknown(data['weapon_id']!, _weaponIdMeta),
      );
    } else if (isInserting) {
      context.missing(_weaponIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeaponVariant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeaponVariant(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      weaponId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weapon_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
    );
  }

  @override
  $WeaponVariantsTable createAlias(String alias) {
    return $WeaponVariantsTable(attachedDatabase, alias);
  }
}

class WeaponVariant extends DataClass implements Insertable<WeaponVariant> {
  final String id;
  final String weaponId;
  final String name;
  final String description;
  final bool isDefault;
  const WeaponVariant({
    required this.id,
    required this.weaponId,
    required this.name,
    required this.description,
    required this.isDefault,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['weapon_id'] = Variable<String>(weaponId);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['is_default'] = Variable<bool>(isDefault);
    return map;
  }

  WeaponVariantsCompanion toCompanion(bool nullToAbsent) {
    return WeaponVariantsCompanion(
      id: Value(id),
      weaponId: Value(weaponId),
      name: Value(name),
      description: Value(description),
      isDefault: Value(isDefault),
    );
  }

  factory WeaponVariant.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeaponVariant(
      id: serializer.fromJson<String>(json['id']),
      weaponId: serializer.fromJson<String>(json['weaponId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'weaponId': serializer.toJson<String>(weaponId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'isDefault': serializer.toJson<bool>(isDefault),
    };
  }

  WeaponVariant copyWith({
    String? id,
    String? weaponId,
    String? name,
    String? description,
    bool? isDefault,
  }) => WeaponVariant(
    id: id ?? this.id,
    weaponId: weaponId ?? this.weaponId,
    name: name ?? this.name,
    description: description ?? this.description,
    isDefault: isDefault ?? this.isDefault,
  );
  WeaponVariant copyWithCompanion(WeaponVariantsCompanion data) {
    return WeaponVariant(
      id: data.id.present ? data.id.value : this.id,
      weaponId: data.weaponId.present ? data.weaponId.value : this.weaponId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeaponVariant(')
          ..write('id: $id, ')
          ..write('weaponId: $weaponId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, weaponId, name, description, isDefault);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeaponVariant &&
          other.id == this.id &&
          other.weaponId == this.weaponId &&
          other.name == this.name &&
          other.description == this.description &&
          other.isDefault == this.isDefault);
}

class WeaponVariantsCompanion extends UpdateCompanion<WeaponVariant> {
  final Value<String> id;
  final Value<String> weaponId;
  final Value<String> name;
  final Value<String> description;
  final Value<bool> isDefault;
  final Value<int> rowid;
  const WeaponVariantsCompanion({
    this.id = const Value.absent(),
    this.weaponId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeaponVariantsCompanion.insert({
    required String id,
    required String weaponId,
    required String name,
    this.description = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       weaponId = Value(weaponId),
       name = Value(name);
  static Insertable<WeaponVariant> custom({
    Expression<String>? id,
    Expression<String>? weaponId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<bool>? isDefault,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (weaponId != null) 'weapon_id': weaponId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (isDefault != null) 'is_default': isDefault,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeaponVariantsCompanion copyWith({
    Value<String>? id,
    Value<String>? weaponId,
    Value<String>? name,
    Value<String>? description,
    Value<bool>? isDefault,
    Value<int>? rowid,
  }) {
    return WeaponVariantsCompanion(
      id: id ?? this.id,
      weaponId: weaponId ?? this.weaponId,
      name: name ?? this.name,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (weaponId.present) {
      map['weapon_id'] = Variable<String>(weaponId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeaponVariantsCompanion(')
          ..write('id: $id, ')
          ..write('weaponId: $weaponId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('isDefault: $isDefault, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeaponReferencesTable extends WeaponReferences
    with TableInfo<$WeaponReferencesTable, WeaponReference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeaponReferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weaponIdMeta = const VerificationMeta(
    'weaponId',
  );
  @override
  late final GeneratedColumn<String> weaponId = GeneratedColumn<String>(
    'weapon_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceTypeMeta = const VerificationMeta(
    'referenceType',
  );
  @override
  late final GeneratedColumn<String> referenceType = GeneratedColumn<String>(
    'reference_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _primaryReferenceMeta = const VerificationMeta(
    'primaryReference',
  );
  @override
  late final GeneratedColumn<bool> primaryReference = GeneratedColumn<bool>(
    'primary_reference',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("primary_reference" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    weaponId,
    referenceType,
    filePath,
    priority,
    primaryReference,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weapon_references';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeaponReference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('weapon_id')) {
      context.handle(
        _weaponIdMeta,
        weaponId.isAcceptableOrUnknown(data['weapon_id']!, _weaponIdMeta),
      );
    } else if (isInserting) {
      context.missing(_weaponIdMeta);
    }
    if (data.containsKey('reference_type')) {
      context.handle(
        _referenceTypeMeta,
        referenceType.isAcceptableOrUnknown(
          data['reference_type']!,
          _referenceTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_referenceTypeMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('primary_reference')) {
      context.handle(
        _primaryReferenceMeta,
        primaryReference.isAcceptableOrUnknown(
          data['primary_reference']!,
          _primaryReferenceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeaponReference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeaponReference(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      weaponId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weapon_id'],
      )!,
      referenceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_type'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      primaryReference: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}primary_reference'],
      )!,
    );
  }

  @override
  $WeaponReferencesTable createAlias(String alias) {
    return $WeaponReferencesTable(attachedDatabase, alias);
  }
}

class WeaponReference extends DataClass implements Insertable<WeaponReference> {
  final String id;
  final String weaponId;
  final String referenceType;
  final String filePath;
  final int priority;
  final bool primaryReference;
  const WeaponReference({
    required this.id,
    required this.weaponId,
    required this.referenceType,
    required this.filePath,
    required this.priority,
    required this.primaryReference,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['weapon_id'] = Variable<String>(weaponId);
    map['reference_type'] = Variable<String>(referenceType);
    map['file_path'] = Variable<String>(filePath);
    map['priority'] = Variable<int>(priority);
    map['primary_reference'] = Variable<bool>(primaryReference);
    return map;
  }

  WeaponReferencesCompanion toCompanion(bool nullToAbsent) {
    return WeaponReferencesCompanion(
      id: Value(id),
      weaponId: Value(weaponId),
      referenceType: Value(referenceType),
      filePath: Value(filePath),
      priority: Value(priority),
      primaryReference: Value(primaryReference),
    );
  }

  factory WeaponReference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeaponReference(
      id: serializer.fromJson<String>(json['id']),
      weaponId: serializer.fromJson<String>(json['weaponId']),
      referenceType: serializer.fromJson<String>(json['referenceType']),
      filePath: serializer.fromJson<String>(json['filePath']),
      priority: serializer.fromJson<int>(json['priority']),
      primaryReference: serializer.fromJson<bool>(json['primaryReference']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'weaponId': serializer.toJson<String>(weaponId),
      'referenceType': serializer.toJson<String>(referenceType),
      'filePath': serializer.toJson<String>(filePath),
      'priority': serializer.toJson<int>(priority),
      'primaryReference': serializer.toJson<bool>(primaryReference),
    };
  }

  WeaponReference copyWith({
    String? id,
    String? weaponId,
    String? referenceType,
    String? filePath,
    int? priority,
    bool? primaryReference,
  }) => WeaponReference(
    id: id ?? this.id,
    weaponId: weaponId ?? this.weaponId,
    referenceType: referenceType ?? this.referenceType,
    filePath: filePath ?? this.filePath,
    priority: priority ?? this.priority,
    primaryReference: primaryReference ?? this.primaryReference,
  );
  WeaponReference copyWithCompanion(WeaponReferencesCompanion data) {
    return WeaponReference(
      id: data.id.present ? data.id.value : this.id,
      weaponId: data.weaponId.present ? data.weaponId.value : this.weaponId,
      referenceType: data.referenceType.present
          ? data.referenceType.value
          : this.referenceType,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      priority: data.priority.present ? data.priority.value : this.priority,
      primaryReference: data.primaryReference.present
          ? data.primaryReference.value
          : this.primaryReference,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeaponReference(')
          ..write('id: $id, ')
          ..write('weaponId: $weaponId, ')
          ..write('referenceType: $referenceType, ')
          ..write('filePath: $filePath, ')
          ..write('priority: $priority, ')
          ..write('primaryReference: $primaryReference')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    weaponId,
    referenceType,
    filePath,
    priority,
    primaryReference,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeaponReference &&
          other.id == this.id &&
          other.weaponId == this.weaponId &&
          other.referenceType == this.referenceType &&
          other.filePath == this.filePath &&
          other.priority == this.priority &&
          other.primaryReference == this.primaryReference);
}

class WeaponReferencesCompanion extends UpdateCompanion<WeaponReference> {
  final Value<String> id;
  final Value<String> weaponId;
  final Value<String> referenceType;
  final Value<String> filePath;
  final Value<int> priority;
  final Value<bool> primaryReference;
  final Value<int> rowid;
  const WeaponReferencesCompanion({
    this.id = const Value.absent(),
    this.weaponId = const Value.absent(),
    this.referenceType = const Value.absent(),
    this.filePath = const Value.absent(),
    this.priority = const Value.absent(),
    this.primaryReference = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeaponReferencesCompanion.insert({
    required String id,
    required String weaponId,
    required String referenceType,
    required String filePath,
    this.priority = const Value.absent(),
    this.primaryReference = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       weaponId = Value(weaponId),
       referenceType = Value(referenceType),
       filePath = Value(filePath);
  static Insertable<WeaponReference> custom({
    Expression<String>? id,
    Expression<String>? weaponId,
    Expression<String>? referenceType,
    Expression<String>? filePath,
    Expression<int>? priority,
    Expression<bool>? primaryReference,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (weaponId != null) 'weapon_id': weaponId,
      if (referenceType != null) 'reference_type': referenceType,
      if (filePath != null) 'file_path': filePath,
      if (priority != null) 'priority': priority,
      if (primaryReference != null) 'primary_reference': primaryReference,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeaponReferencesCompanion copyWith({
    Value<String>? id,
    Value<String>? weaponId,
    Value<String>? referenceType,
    Value<String>? filePath,
    Value<int>? priority,
    Value<bool>? primaryReference,
    Value<int>? rowid,
  }) {
    return WeaponReferencesCompanion(
      id: id ?? this.id,
      weaponId: weaponId ?? this.weaponId,
      referenceType: referenceType ?? this.referenceType,
      filePath: filePath ?? this.filePath,
      priority: priority ?? this.priority,
      primaryReference: primaryReference ?? this.primaryReference,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (weaponId.present) {
      map['weapon_id'] = Variable<String>(weaponId.value);
    }
    if (referenceType.present) {
      map['reference_type'] = Variable<String>(referenceType.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (primaryReference.present) {
      map['primary_reference'] = Variable<bool>(primaryReference.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeaponReferencesCompanion(')
          ..write('id: $id, ')
          ..write('weaponId: $weaponId, ')
          ..write('referenceType: $referenceType, ')
          ..write('filePath: $filePath, ')
          ..write('priority: $priority, ')
          ..write('primaryReference: $primaryReference, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeaponPreservationProfilesTable extends WeaponPreservationProfiles
    with
        TableInfo<$WeaponPreservationProfilesTable, WeaponPreservationProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeaponPreservationProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _weaponIdMeta = const VerificationMeta(
    'weaponId',
  );
  @override
  late final GeneratedColumn<String> weaponId = GeneratedColumn<String>(
    'weapon_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _geometryLockMeta = const VerificationMeta(
    'geometryLock',
  );
  @override
  late final GeneratedColumn<bool> geometryLock = GeneratedColumn<bool>(
    'geometry_lock',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("geometry_lock" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _materialLockMeta = const VerificationMeta(
    'materialLock',
  );
  @override
  late final GeneratedColumn<bool> materialLock = GeneratedColumn<bool>(
    'material_lock',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("material_lock" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _colorLockMeta = const VerificationMeta(
    'colorLock',
  );
  @override
  late final GeneratedColumn<bool> colorLock = GeneratedColumn<bool>(
    'color_lock',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("color_lock" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _coreLockMeta = const VerificationMeta(
    'coreLock',
  );
  @override
  late final GeneratedColumn<bool> coreLock = GeneratedColumn<bool>(
    'core_lock',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("core_lock" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _scaleLockMeta = const VerificationMeta(
    'scaleLock',
  );
  @override
  late final GeneratedColumn<bool> scaleLock = GeneratedColumn<bool>(
    'scale_lock',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("scale_lock" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _effectLockMeta = const VerificationMeta(
    'effectLock',
  );
  @override
  late final GeneratedColumn<bool> effectLock = GeneratedColumn<bool>(
    'effect_lock',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("effect_lock" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    weaponId,
    geometryLock,
    materialLock,
    colorLock,
    coreLock,
    scaleLock,
    effectLock,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weapon_preservation_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeaponPreservationProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('weapon_id')) {
      context.handle(
        _weaponIdMeta,
        weaponId.isAcceptableOrUnknown(data['weapon_id']!, _weaponIdMeta),
      );
    } else if (isInserting) {
      context.missing(_weaponIdMeta);
    }
    if (data.containsKey('geometry_lock')) {
      context.handle(
        _geometryLockMeta,
        geometryLock.isAcceptableOrUnknown(
          data['geometry_lock']!,
          _geometryLockMeta,
        ),
      );
    }
    if (data.containsKey('material_lock')) {
      context.handle(
        _materialLockMeta,
        materialLock.isAcceptableOrUnknown(
          data['material_lock']!,
          _materialLockMeta,
        ),
      );
    }
    if (data.containsKey('color_lock')) {
      context.handle(
        _colorLockMeta,
        colorLock.isAcceptableOrUnknown(data['color_lock']!, _colorLockMeta),
      );
    }
    if (data.containsKey('core_lock')) {
      context.handle(
        _coreLockMeta,
        coreLock.isAcceptableOrUnknown(data['core_lock']!, _coreLockMeta),
      );
    }
    if (data.containsKey('scale_lock')) {
      context.handle(
        _scaleLockMeta,
        scaleLock.isAcceptableOrUnknown(data['scale_lock']!, _scaleLockMeta),
      );
    }
    if (data.containsKey('effect_lock')) {
      context.handle(
        _effectLockMeta,
        effectLock.isAcceptableOrUnknown(data['effect_lock']!, _effectLockMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {weaponId};
  @override
  WeaponPreservationProfile map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeaponPreservationProfile(
      weaponId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weapon_id'],
      )!,
      geometryLock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}geometry_lock'],
      )!,
      materialLock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}material_lock'],
      )!,
      colorLock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}color_lock'],
      )!,
      coreLock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}core_lock'],
      )!,
      scaleLock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}scale_lock'],
      )!,
      effectLock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}effect_lock'],
      )!,
    );
  }

  @override
  $WeaponPreservationProfilesTable createAlias(String alias) {
    return $WeaponPreservationProfilesTable(attachedDatabase, alias);
  }
}

class WeaponPreservationProfile extends DataClass
    implements Insertable<WeaponPreservationProfile> {
  final String weaponId;
  final bool geometryLock;
  final bool materialLock;
  final bool colorLock;
  final bool coreLock;
  final bool scaleLock;
  final bool effectLock;
  const WeaponPreservationProfile({
    required this.weaponId,
    required this.geometryLock,
    required this.materialLock,
    required this.colorLock,
    required this.coreLock,
    required this.scaleLock,
    required this.effectLock,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['weapon_id'] = Variable<String>(weaponId);
    map['geometry_lock'] = Variable<bool>(geometryLock);
    map['material_lock'] = Variable<bool>(materialLock);
    map['color_lock'] = Variable<bool>(colorLock);
    map['core_lock'] = Variable<bool>(coreLock);
    map['scale_lock'] = Variable<bool>(scaleLock);
    map['effect_lock'] = Variable<bool>(effectLock);
    return map;
  }

  WeaponPreservationProfilesCompanion toCompanion(bool nullToAbsent) {
    return WeaponPreservationProfilesCompanion(
      weaponId: Value(weaponId),
      geometryLock: Value(geometryLock),
      materialLock: Value(materialLock),
      colorLock: Value(colorLock),
      coreLock: Value(coreLock),
      scaleLock: Value(scaleLock),
      effectLock: Value(effectLock),
    );
  }

  factory WeaponPreservationProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeaponPreservationProfile(
      weaponId: serializer.fromJson<String>(json['weaponId']),
      geometryLock: serializer.fromJson<bool>(json['geometryLock']),
      materialLock: serializer.fromJson<bool>(json['materialLock']),
      colorLock: serializer.fromJson<bool>(json['colorLock']),
      coreLock: serializer.fromJson<bool>(json['coreLock']),
      scaleLock: serializer.fromJson<bool>(json['scaleLock']),
      effectLock: serializer.fromJson<bool>(json['effectLock']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'weaponId': serializer.toJson<String>(weaponId),
      'geometryLock': serializer.toJson<bool>(geometryLock),
      'materialLock': serializer.toJson<bool>(materialLock),
      'colorLock': serializer.toJson<bool>(colorLock),
      'coreLock': serializer.toJson<bool>(coreLock),
      'scaleLock': serializer.toJson<bool>(scaleLock),
      'effectLock': serializer.toJson<bool>(effectLock),
    };
  }

  WeaponPreservationProfile copyWith({
    String? weaponId,
    bool? geometryLock,
    bool? materialLock,
    bool? colorLock,
    bool? coreLock,
    bool? scaleLock,
    bool? effectLock,
  }) => WeaponPreservationProfile(
    weaponId: weaponId ?? this.weaponId,
    geometryLock: geometryLock ?? this.geometryLock,
    materialLock: materialLock ?? this.materialLock,
    colorLock: colorLock ?? this.colorLock,
    coreLock: coreLock ?? this.coreLock,
    scaleLock: scaleLock ?? this.scaleLock,
    effectLock: effectLock ?? this.effectLock,
  );
  WeaponPreservationProfile copyWithCompanion(
    WeaponPreservationProfilesCompanion data,
  ) {
    return WeaponPreservationProfile(
      weaponId: data.weaponId.present ? data.weaponId.value : this.weaponId,
      geometryLock: data.geometryLock.present
          ? data.geometryLock.value
          : this.geometryLock,
      materialLock: data.materialLock.present
          ? data.materialLock.value
          : this.materialLock,
      colorLock: data.colorLock.present ? data.colorLock.value : this.colorLock,
      coreLock: data.coreLock.present ? data.coreLock.value : this.coreLock,
      scaleLock: data.scaleLock.present ? data.scaleLock.value : this.scaleLock,
      effectLock: data.effectLock.present
          ? data.effectLock.value
          : this.effectLock,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeaponPreservationProfile(')
          ..write('weaponId: $weaponId, ')
          ..write('geometryLock: $geometryLock, ')
          ..write('materialLock: $materialLock, ')
          ..write('colorLock: $colorLock, ')
          ..write('coreLock: $coreLock, ')
          ..write('scaleLock: $scaleLock, ')
          ..write('effectLock: $effectLock')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    weaponId,
    geometryLock,
    materialLock,
    colorLock,
    coreLock,
    scaleLock,
    effectLock,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeaponPreservationProfile &&
          other.weaponId == this.weaponId &&
          other.geometryLock == this.geometryLock &&
          other.materialLock == this.materialLock &&
          other.colorLock == this.colorLock &&
          other.coreLock == this.coreLock &&
          other.scaleLock == this.scaleLock &&
          other.effectLock == this.effectLock);
}

class WeaponPreservationProfilesCompanion
    extends UpdateCompanion<WeaponPreservationProfile> {
  final Value<String> weaponId;
  final Value<bool> geometryLock;
  final Value<bool> materialLock;
  final Value<bool> colorLock;
  final Value<bool> coreLock;
  final Value<bool> scaleLock;
  final Value<bool> effectLock;
  final Value<int> rowid;
  const WeaponPreservationProfilesCompanion({
    this.weaponId = const Value.absent(),
    this.geometryLock = const Value.absent(),
    this.materialLock = const Value.absent(),
    this.colorLock = const Value.absent(),
    this.coreLock = const Value.absent(),
    this.scaleLock = const Value.absent(),
    this.effectLock = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeaponPreservationProfilesCompanion.insert({
    required String weaponId,
    this.geometryLock = const Value.absent(),
    this.materialLock = const Value.absent(),
    this.colorLock = const Value.absent(),
    this.coreLock = const Value.absent(),
    this.scaleLock = const Value.absent(),
    this.effectLock = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : weaponId = Value(weaponId);
  static Insertable<WeaponPreservationProfile> custom({
    Expression<String>? weaponId,
    Expression<bool>? geometryLock,
    Expression<bool>? materialLock,
    Expression<bool>? colorLock,
    Expression<bool>? coreLock,
    Expression<bool>? scaleLock,
    Expression<bool>? effectLock,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (weaponId != null) 'weapon_id': weaponId,
      if (geometryLock != null) 'geometry_lock': geometryLock,
      if (materialLock != null) 'material_lock': materialLock,
      if (colorLock != null) 'color_lock': colorLock,
      if (coreLock != null) 'core_lock': coreLock,
      if (scaleLock != null) 'scale_lock': scaleLock,
      if (effectLock != null) 'effect_lock': effectLock,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeaponPreservationProfilesCompanion copyWith({
    Value<String>? weaponId,
    Value<bool>? geometryLock,
    Value<bool>? materialLock,
    Value<bool>? colorLock,
    Value<bool>? coreLock,
    Value<bool>? scaleLock,
    Value<bool>? effectLock,
    Value<int>? rowid,
  }) {
    return WeaponPreservationProfilesCompanion(
      weaponId: weaponId ?? this.weaponId,
      geometryLock: geometryLock ?? this.geometryLock,
      materialLock: materialLock ?? this.materialLock,
      colorLock: colorLock ?? this.colorLock,
      coreLock: coreLock ?? this.coreLock,
      scaleLock: scaleLock ?? this.scaleLock,
      effectLock: effectLock ?? this.effectLock,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (weaponId.present) {
      map['weapon_id'] = Variable<String>(weaponId.value);
    }
    if (geometryLock.present) {
      map['geometry_lock'] = Variable<bool>(geometryLock.value);
    }
    if (materialLock.present) {
      map['material_lock'] = Variable<bool>(materialLock.value);
    }
    if (colorLock.present) {
      map['color_lock'] = Variable<bool>(colorLock.value);
    }
    if (coreLock.present) {
      map['core_lock'] = Variable<bool>(coreLock.value);
    }
    if (scaleLock.present) {
      map['scale_lock'] = Variable<bool>(scaleLock.value);
    }
    if (effectLock.present) {
      map['effect_lock'] = Variable<bool>(effectLock.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeaponPreservationProfilesCompanion(')
          ..write('weaponId: $weaponId, ')
          ..write('geometryLock: $geometryLock, ')
          ..write('materialLock: $materialLock, ')
          ..write('colorLock: $colorLock, ')
          ..write('coreLock: $coreLock, ')
          ..write('scaleLock: $scaleLock, ')
          ..write('effectLock: $effectLock, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EnvironmentsTable extends Environments
    with TableInfo<$EnvironmentsTable, Environment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EnvironmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _environmentTypeMeta = const VerificationMeta(
    'environmentType',
  );
  @override
  late final GeneratedColumn<String> environmentType = GeneratedColumn<String>(
    'environment_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _architectureMeta = const VerificationMeta(
    'architecture',
  );
  @override
  late final GeneratedColumn<String> architecture = GeneratedColumn<String>(
    'architecture',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _terrainMeta = const VerificationMeta(
    'terrain',
  );
  @override
  late final GeneratedColumn<String> terrain = GeneratedColumn<String>(
    'terrain',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    assetId,
    projectId,
    name,
    environmentType,
    description,
    location,
    architecture,
    terrain,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'environments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Environment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('environment_type')) {
      context.handle(
        _environmentTypeMeta,
        environmentType.isAcceptableOrUnknown(
          data['environment_type']!,
          _environmentTypeMeta,
        ),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('architecture')) {
      context.handle(
        _architectureMeta,
        architecture.isAcceptableOrUnknown(
          data['architecture']!,
          _architectureMeta,
        ),
      );
    }
    if (data.containsKey('terrain')) {
      context.handle(
        _terrainMeta,
        terrain.isAcceptableOrUnknown(data['terrain']!, _terrainMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {assetId};
  @override
  Environment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Environment(
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      environmentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}environment_type'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      )!,
      architecture: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}architecture'],
      )!,
      terrain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}terrain'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
    );
  }

  @override
  $EnvironmentsTable createAlias(String alias) {
    return $EnvironmentsTable(attachedDatabase, alias);
  }
}

class Environment extends DataClass implements Insertable<Environment> {
  final String assetId;
  final String projectId;
  final String name;
  final String environmentType;
  final String description;
  final String location;
  final String architecture;
  final String terrain;
  final String notes;
  const Environment({
    required this.assetId,
    required this.projectId,
    required this.name,
    required this.environmentType,
    required this.description,
    required this.location,
    required this.architecture,
    required this.terrain,
    required this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['asset_id'] = Variable<String>(assetId);
    map['project_id'] = Variable<String>(projectId);
    map['name'] = Variable<String>(name);
    map['environment_type'] = Variable<String>(environmentType);
    map['description'] = Variable<String>(description);
    map['location'] = Variable<String>(location);
    map['architecture'] = Variable<String>(architecture);
    map['terrain'] = Variable<String>(terrain);
    map['notes'] = Variable<String>(notes);
    return map;
  }

  EnvironmentsCompanion toCompanion(bool nullToAbsent) {
    return EnvironmentsCompanion(
      assetId: Value(assetId),
      projectId: Value(projectId),
      name: Value(name),
      environmentType: Value(environmentType),
      description: Value(description),
      location: Value(location),
      architecture: Value(architecture),
      terrain: Value(terrain),
      notes: Value(notes),
    );
  }

  factory Environment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Environment(
      assetId: serializer.fromJson<String>(json['assetId']),
      projectId: serializer.fromJson<String>(json['projectId']),
      name: serializer.fromJson<String>(json['name']),
      environmentType: serializer.fromJson<String>(json['environmentType']),
      description: serializer.fromJson<String>(json['description']),
      location: serializer.fromJson<String>(json['location']),
      architecture: serializer.fromJson<String>(json['architecture']),
      terrain: serializer.fromJson<String>(json['terrain']),
      notes: serializer.fromJson<String>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'assetId': serializer.toJson<String>(assetId),
      'projectId': serializer.toJson<String>(projectId),
      'name': serializer.toJson<String>(name),
      'environmentType': serializer.toJson<String>(environmentType),
      'description': serializer.toJson<String>(description),
      'location': serializer.toJson<String>(location),
      'architecture': serializer.toJson<String>(architecture),
      'terrain': serializer.toJson<String>(terrain),
      'notes': serializer.toJson<String>(notes),
    };
  }

  Environment copyWith({
    String? assetId,
    String? projectId,
    String? name,
    String? environmentType,
    String? description,
    String? location,
    String? architecture,
    String? terrain,
    String? notes,
  }) => Environment(
    assetId: assetId ?? this.assetId,
    projectId: projectId ?? this.projectId,
    name: name ?? this.name,
    environmentType: environmentType ?? this.environmentType,
    description: description ?? this.description,
    location: location ?? this.location,
    architecture: architecture ?? this.architecture,
    terrain: terrain ?? this.terrain,
    notes: notes ?? this.notes,
  );
  Environment copyWithCompanion(EnvironmentsCompanion data) {
    return Environment(
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      name: data.name.present ? data.name.value : this.name,
      environmentType: data.environmentType.present
          ? data.environmentType.value
          : this.environmentType,
      description: data.description.present
          ? data.description.value
          : this.description,
      location: data.location.present ? data.location.value : this.location,
      architecture: data.architecture.present
          ? data.architecture.value
          : this.architecture,
      terrain: data.terrain.present ? data.terrain.value : this.terrain,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Environment(')
          ..write('assetId: $assetId, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('environmentType: $environmentType, ')
          ..write('description: $description, ')
          ..write('location: $location, ')
          ..write('architecture: $architecture, ')
          ..write('terrain: $terrain, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    assetId,
    projectId,
    name,
    environmentType,
    description,
    location,
    architecture,
    terrain,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Environment &&
          other.assetId == this.assetId &&
          other.projectId == this.projectId &&
          other.name == this.name &&
          other.environmentType == this.environmentType &&
          other.description == this.description &&
          other.location == this.location &&
          other.architecture == this.architecture &&
          other.terrain == this.terrain &&
          other.notes == this.notes);
}

class EnvironmentsCompanion extends UpdateCompanion<Environment> {
  final Value<String> assetId;
  final Value<String> projectId;
  final Value<String> name;
  final Value<String> environmentType;
  final Value<String> description;
  final Value<String> location;
  final Value<String> architecture;
  final Value<String> terrain;
  final Value<String> notes;
  final Value<int> rowid;
  const EnvironmentsCompanion({
    this.assetId = const Value.absent(),
    this.projectId = const Value.absent(),
    this.name = const Value.absent(),
    this.environmentType = const Value.absent(),
    this.description = const Value.absent(),
    this.location = const Value.absent(),
    this.architecture = const Value.absent(),
    this.terrain = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EnvironmentsCompanion.insert({
    required String assetId,
    required String projectId,
    required String name,
    this.environmentType = const Value.absent(),
    this.description = const Value.absent(),
    this.location = const Value.absent(),
    this.architecture = const Value.absent(),
    this.terrain = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : assetId = Value(assetId),
       projectId = Value(projectId),
       name = Value(name);
  static Insertable<Environment> custom({
    Expression<String>? assetId,
    Expression<String>? projectId,
    Expression<String>? name,
    Expression<String>? environmentType,
    Expression<String>? description,
    Expression<String>? location,
    Expression<String>? architecture,
    Expression<String>? terrain,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (assetId != null) 'asset_id': assetId,
      if (projectId != null) 'project_id': projectId,
      if (name != null) 'name': name,
      if (environmentType != null) 'environment_type': environmentType,
      if (description != null) 'description': description,
      if (location != null) 'location': location,
      if (architecture != null) 'architecture': architecture,
      if (terrain != null) 'terrain': terrain,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EnvironmentsCompanion copyWith({
    Value<String>? assetId,
    Value<String>? projectId,
    Value<String>? name,
    Value<String>? environmentType,
    Value<String>? description,
    Value<String>? location,
    Value<String>? architecture,
    Value<String>? terrain,
    Value<String>? notes,
    Value<int>? rowid,
  }) {
    return EnvironmentsCompanion(
      assetId: assetId ?? this.assetId,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      environmentType: environmentType ?? this.environmentType,
      description: description ?? this.description,
      location: location ?? this.location,
      architecture: architecture ?? this.architecture,
      terrain: terrain ?? this.terrain,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (environmentType.present) {
      map['environment_type'] = Variable<String>(environmentType.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (architecture.present) {
      map['architecture'] = Variable<String>(architecture.value);
    }
    if (terrain.present) {
      map['terrain'] = Variable<String>(terrain.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnvironmentsCompanion(')
          ..write('assetId: $assetId, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('environmentType: $environmentType, ')
          ..write('description: $description, ')
          ..write('location: $location, ')
          ..write('architecture: $architecture, ')
          ..write('terrain: $terrain, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EnvironmentZonesTable extends EnvironmentZones
    with TableInfo<$EnvironmentZonesTable, EnvironmentZone> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EnvironmentZonesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _environmentIdMeta = const VerificationMeta(
    'environmentId',
  );
  @override
  late final GeneratedColumn<String> environmentId = GeneratedColumn<String>(
    'environment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _zoneTypeMeta = const VerificationMeta(
    'zoneType',
  );
  @override
  late final GeneratedColumn<String> zoneType = GeneratedColumn<String>(
    'zone_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    environmentId,
    name,
    description,
    zoneType,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'environment_zones';
  @override
  VerificationContext validateIntegrity(
    Insertable<EnvironmentZone> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('environment_id')) {
      context.handle(
        _environmentIdMeta,
        environmentId.isAcceptableOrUnknown(
          data['environment_id']!,
          _environmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_environmentIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('zone_type')) {
      context.handle(
        _zoneTypeMeta,
        zoneType.isAcceptableOrUnknown(data['zone_type']!, _zoneTypeMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EnvironmentZone map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EnvironmentZone(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      environmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}environment_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      zoneType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zone_type'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $EnvironmentZonesTable createAlias(String alias) {
    return $EnvironmentZonesTable(attachedDatabase, alias);
  }
}

class EnvironmentZone extends DataClass implements Insertable<EnvironmentZone> {
  final String id;
  final String environmentId;
  final String name;
  final String description;
  final String zoneType;
  final int sortOrder;
  const EnvironmentZone({
    required this.id,
    required this.environmentId,
    required this.name,
    required this.description,
    required this.zoneType,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['environment_id'] = Variable<String>(environmentId);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['zone_type'] = Variable<String>(zoneType);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  EnvironmentZonesCompanion toCompanion(bool nullToAbsent) {
    return EnvironmentZonesCompanion(
      id: Value(id),
      environmentId: Value(environmentId),
      name: Value(name),
      description: Value(description),
      zoneType: Value(zoneType),
      sortOrder: Value(sortOrder),
    );
  }

  factory EnvironmentZone.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EnvironmentZone(
      id: serializer.fromJson<String>(json['id']),
      environmentId: serializer.fromJson<String>(json['environmentId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      zoneType: serializer.fromJson<String>(json['zoneType']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'environmentId': serializer.toJson<String>(environmentId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'zoneType': serializer.toJson<String>(zoneType),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  EnvironmentZone copyWith({
    String? id,
    String? environmentId,
    String? name,
    String? description,
    String? zoneType,
    int? sortOrder,
  }) => EnvironmentZone(
    id: id ?? this.id,
    environmentId: environmentId ?? this.environmentId,
    name: name ?? this.name,
    description: description ?? this.description,
    zoneType: zoneType ?? this.zoneType,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  EnvironmentZone copyWithCompanion(EnvironmentZonesCompanion data) {
    return EnvironmentZone(
      id: data.id.present ? data.id.value : this.id,
      environmentId: data.environmentId.present
          ? data.environmentId.value
          : this.environmentId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      zoneType: data.zoneType.present ? data.zoneType.value : this.zoneType,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EnvironmentZone(')
          ..write('id: $id, ')
          ..write('environmentId: $environmentId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('zoneType: $zoneType, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, environmentId, name, description, zoneType, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EnvironmentZone &&
          other.id == this.id &&
          other.environmentId == this.environmentId &&
          other.name == this.name &&
          other.description == this.description &&
          other.zoneType == this.zoneType &&
          other.sortOrder == this.sortOrder);
}

class EnvironmentZonesCompanion extends UpdateCompanion<EnvironmentZone> {
  final Value<String> id;
  final Value<String> environmentId;
  final Value<String> name;
  final Value<String> description;
  final Value<String> zoneType;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const EnvironmentZonesCompanion({
    this.id = const Value.absent(),
    this.environmentId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.zoneType = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EnvironmentZonesCompanion.insert({
    required String id,
    required String environmentId,
    required String name,
    this.description = const Value.absent(),
    this.zoneType = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       environmentId = Value(environmentId),
       name = Value(name);
  static Insertable<EnvironmentZone> custom({
    Expression<String>? id,
    Expression<String>? environmentId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? zoneType,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (environmentId != null) 'environment_id': environmentId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (zoneType != null) 'zone_type': zoneType,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EnvironmentZonesCompanion copyWith({
    Value<String>? id,
    Value<String>? environmentId,
    Value<String>? name,
    Value<String>? description,
    Value<String>? zoneType,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return EnvironmentZonesCompanion(
      id: id ?? this.id,
      environmentId: environmentId ?? this.environmentId,
      name: name ?? this.name,
      description: description ?? this.description,
      zoneType: zoneType ?? this.zoneType,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (environmentId.present) {
      map['environment_id'] = Variable<String>(environmentId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (zoneType.present) {
      map['zone_type'] = Variable<String>(zoneType.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnvironmentZonesCompanion(')
          ..write('id: $id, ')
          ..write('environmentId: $environmentId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('zoneType: $zoneType, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EnvironmentArchitecturesTable extends EnvironmentArchitectures
    with TableInfo<$EnvironmentArchitecturesTable, EnvironmentArchitecture> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EnvironmentArchitecturesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _environmentIdMeta = const VerificationMeta(
    'environmentId',
  );
  @override
  late final GeneratedColumn<String> environmentId = GeneratedColumn<String>(
    'environment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _styleMeta = const VerificationMeta('style');
  @override
  late final GeneratedColumn<String> style = GeneratedColumn<String>(
    'style',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _structureMeta = const VerificationMeta(
    'structure',
  );
  @override
  late final GeneratedColumn<String> structure = GeneratedColumn<String>(
    'structure',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _materialsMeta = const VerificationMeta(
    'materials',
  );
  @override
  late final GeneratedColumn<String> materials = GeneratedColumn<String>(
    'materials',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _scaleMeta = const VerificationMeta('scale');
  @override
  late final GeneratedColumn<String> scale = GeneratedColumn<String>(
    'scale',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _conditionMeta = const VerificationMeta(
    'condition',
  );
  @override
  late final GeneratedColumn<String> condition = GeneratedColumn<String>(
    'condition',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    environmentId,
    style,
    structure,
    materials,
    scale,
    condition,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'environment_architectures';
  @override
  VerificationContext validateIntegrity(
    Insertable<EnvironmentArchitecture> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('environment_id')) {
      context.handle(
        _environmentIdMeta,
        environmentId.isAcceptableOrUnknown(
          data['environment_id']!,
          _environmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_environmentIdMeta);
    }
    if (data.containsKey('style')) {
      context.handle(
        _styleMeta,
        style.isAcceptableOrUnknown(data['style']!, _styleMeta),
      );
    }
    if (data.containsKey('structure')) {
      context.handle(
        _structureMeta,
        structure.isAcceptableOrUnknown(data['structure']!, _structureMeta),
      );
    }
    if (data.containsKey('materials')) {
      context.handle(
        _materialsMeta,
        materials.isAcceptableOrUnknown(data['materials']!, _materialsMeta),
      );
    }
    if (data.containsKey('scale')) {
      context.handle(
        _scaleMeta,
        scale.isAcceptableOrUnknown(data['scale']!, _scaleMeta),
      );
    }
    if (data.containsKey('condition')) {
      context.handle(
        _conditionMeta,
        condition.isAcceptableOrUnknown(data['condition']!, _conditionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {environmentId};
  @override
  EnvironmentArchitecture map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EnvironmentArchitecture(
      environmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}environment_id'],
      )!,
      style: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}style'],
      )!,
      structure: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}structure'],
      )!,
      materials: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}materials'],
      )!,
      scale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scale'],
      )!,
      condition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}condition'],
      )!,
    );
  }

  @override
  $EnvironmentArchitecturesTable createAlias(String alias) {
    return $EnvironmentArchitecturesTable(attachedDatabase, alias);
  }
}

class EnvironmentArchitecture extends DataClass
    implements Insertable<EnvironmentArchitecture> {
  final String environmentId;
  final String style;
  final String structure;
  final String materials;
  final String scale;
  final String condition;
  const EnvironmentArchitecture({
    required this.environmentId,
    required this.style,
    required this.structure,
    required this.materials,
    required this.scale,
    required this.condition,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['environment_id'] = Variable<String>(environmentId);
    map['style'] = Variable<String>(style);
    map['structure'] = Variable<String>(structure);
    map['materials'] = Variable<String>(materials);
    map['scale'] = Variable<String>(scale);
    map['condition'] = Variable<String>(condition);
    return map;
  }

  EnvironmentArchitecturesCompanion toCompanion(bool nullToAbsent) {
    return EnvironmentArchitecturesCompanion(
      environmentId: Value(environmentId),
      style: Value(style),
      structure: Value(structure),
      materials: Value(materials),
      scale: Value(scale),
      condition: Value(condition),
    );
  }

  factory EnvironmentArchitecture.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EnvironmentArchitecture(
      environmentId: serializer.fromJson<String>(json['environmentId']),
      style: serializer.fromJson<String>(json['style']),
      structure: serializer.fromJson<String>(json['structure']),
      materials: serializer.fromJson<String>(json['materials']),
      scale: serializer.fromJson<String>(json['scale']),
      condition: serializer.fromJson<String>(json['condition']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'environmentId': serializer.toJson<String>(environmentId),
      'style': serializer.toJson<String>(style),
      'structure': serializer.toJson<String>(structure),
      'materials': serializer.toJson<String>(materials),
      'scale': serializer.toJson<String>(scale),
      'condition': serializer.toJson<String>(condition),
    };
  }

  EnvironmentArchitecture copyWith({
    String? environmentId,
    String? style,
    String? structure,
    String? materials,
    String? scale,
    String? condition,
  }) => EnvironmentArchitecture(
    environmentId: environmentId ?? this.environmentId,
    style: style ?? this.style,
    structure: structure ?? this.structure,
    materials: materials ?? this.materials,
    scale: scale ?? this.scale,
    condition: condition ?? this.condition,
  );
  EnvironmentArchitecture copyWithCompanion(
    EnvironmentArchitecturesCompanion data,
  ) {
    return EnvironmentArchitecture(
      environmentId: data.environmentId.present
          ? data.environmentId.value
          : this.environmentId,
      style: data.style.present ? data.style.value : this.style,
      structure: data.structure.present ? data.structure.value : this.structure,
      materials: data.materials.present ? data.materials.value : this.materials,
      scale: data.scale.present ? data.scale.value : this.scale,
      condition: data.condition.present ? data.condition.value : this.condition,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EnvironmentArchitecture(')
          ..write('environmentId: $environmentId, ')
          ..write('style: $style, ')
          ..write('structure: $structure, ')
          ..write('materials: $materials, ')
          ..write('scale: $scale, ')
          ..write('condition: $condition')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(environmentId, style, structure, materials, scale, condition);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EnvironmentArchitecture &&
          other.environmentId == this.environmentId &&
          other.style == this.style &&
          other.structure == this.structure &&
          other.materials == this.materials &&
          other.scale == this.scale &&
          other.condition == this.condition);
}

class EnvironmentArchitecturesCompanion
    extends UpdateCompanion<EnvironmentArchitecture> {
  final Value<String> environmentId;
  final Value<String> style;
  final Value<String> structure;
  final Value<String> materials;
  final Value<String> scale;
  final Value<String> condition;
  final Value<int> rowid;
  const EnvironmentArchitecturesCompanion({
    this.environmentId = const Value.absent(),
    this.style = const Value.absent(),
    this.structure = const Value.absent(),
    this.materials = const Value.absent(),
    this.scale = const Value.absent(),
    this.condition = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EnvironmentArchitecturesCompanion.insert({
    required String environmentId,
    this.style = const Value.absent(),
    this.structure = const Value.absent(),
    this.materials = const Value.absent(),
    this.scale = const Value.absent(),
    this.condition = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : environmentId = Value(environmentId);
  static Insertable<EnvironmentArchitecture> custom({
    Expression<String>? environmentId,
    Expression<String>? style,
    Expression<String>? structure,
    Expression<String>? materials,
    Expression<String>? scale,
    Expression<String>? condition,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (environmentId != null) 'environment_id': environmentId,
      if (style != null) 'style': style,
      if (structure != null) 'structure': structure,
      if (materials != null) 'materials': materials,
      if (scale != null) 'scale': scale,
      if (condition != null) 'condition': condition,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EnvironmentArchitecturesCompanion copyWith({
    Value<String>? environmentId,
    Value<String>? style,
    Value<String>? structure,
    Value<String>? materials,
    Value<String>? scale,
    Value<String>? condition,
    Value<int>? rowid,
  }) {
    return EnvironmentArchitecturesCompanion(
      environmentId: environmentId ?? this.environmentId,
      style: style ?? this.style,
      structure: structure ?? this.structure,
      materials: materials ?? this.materials,
      scale: scale ?? this.scale,
      condition: condition ?? this.condition,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (environmentId.present) {
      map['environment_id'] = Variable<String>(environmentId.value);
    }
    if (style.present) {
      map['style'] = Variable<String>(style.value);
    }
    if (structure.present) {
      map['structure'] = Variable<String>(structure.value);
    }
    if (materials.present) {
      map['materials'] = Variable<String>(materials.value);
    }
    if (scale.present) {
      map['scale'] = Variable<String>(scale.value);
    }
    if (condition.present) {
      map['condition'] = Variable<String>(condition.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnvironmentArchitecturesCompanion(')
          ..write('environmentId: $environmentId, ')
          ..write('style: $style, ')
          ..write('structure: $structure, ')
          ..write('materials: $materials, ')
          ..write('scale: $scale, ')
          ..write('condition: $condition, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EnvironmentWeatherProfilesTable extends EnvironmentWeatherProfiles
    with
        TableInfo<$EnvironmentWeatherProfilesTable, EnvironmentWeatherProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EnvironmentWeatherProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _environmentIdMeta = const VerificationMeta(
    'environmentId',
  );
  @override
  late final GeneratedColumn<String> environmentId = GeneratedColumn<String>(
    'environment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weatherPresetMeta = const VerificationMeta(
    'weatherPreset',
  );
  @override
  late final GeneratedColumn<String> weatherPreset = GeneratedColumn<String>(
    'weather_preset',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intensityMeta = const VerificationMeta(
    'intensity',
  );
  @override
  late final GeneratedColumn<double> intensity = GeneratedColumn<double>(
    'intensity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _windStrengthMeta = const VerificationMeta(
    'windStrength',
  );
  @override
  late final GeneratedColumn<double> windStrength = GeneratedColumn<double>(
    'wind_strength',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _visibilityMeta = const VerificationMeta(
    'visibility',
  );
  @override
  late final GeneratedColumn<double> visibility = GeneratedColumn<double>(
    'visibility',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    environmentId,
    name,
    weatherPreset,
    intensity,
    windStrength,
    visibility,
    isDefault,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'environment_weather_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<EnvironmentWeatherProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('environment_id')) {
      context.handle(
        _environmentIdMeta,
        environmentId.isAcceptableOrUnknown(
          data['environment_id']!,
          _environmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_environmentIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('weather_preset')) {
      context.handle(
        _weatherPresetMeta,
        weatherPreset.isAcceptableOrUnknown(
          data['weather_preset']!,
          _weatherPresetMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_weatherPresetMeta);
    }
    if (data.containsKey('intensity')) {
      context.handle(
        _intensityMeta,
        intensity.isAcceptableOrUnknown(data['intensity']!, _intensityMeta),
      );
    }
    if (data.containsKey('wind_strength')) {
      context.handle(
        _windStrengthMeta,
        windStrength.isAcceptableOrUnknown(
          data['wind_strength']!,
          _windStrengthMeta,
        ),
      );
    }
    if (data.containsKey('visibility')) {
      context.handle(
        _visibilityMeta,
        visibility.isAcceptableOrUnknown(data['visibility']!, _visibilityMeta),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EnvironmentWeatherProfile map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EnvironmentWeatherProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      environmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}environment_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      weatherPreset: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weather_preset'],
      )!,
      intensity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}intensity'],
      )!,
      windStrength: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}wind_strength'],
      )!,
      visibility: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}visibility'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
    );
  }

  @override
  $EnvironmentWeatherProfilesTable createAlias(String alias) {
    return $EnvironmentWeatherProfilesTable(attachedDatabase, alias);
  }
}

class EnvironmentWeatherProfile extends DataClass
    implements Insertable<EnvironmentWeatherProfile> {
  final String id;
  final String environmentId;
  final String name;
  final String weatherPreset;
  final double intensity;
  final double windStrength;
  final double visibility;
  final bool isDefault;
  const EnvironmentWeatherProfile({
    required this.id,
    required this.environmentId,
    required this.name,
    required this.weatherPreset,
    required this.intensity,
    required this.windStrength,
    required this.visibility,
    required this.isDefault,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['environment_id'] = Variable<String>(environmentId);
    map['name'] = Variable<String>(name);
    map['weather_preset'] = Variable<String>(weatherPreset);
    map['intensity'] = Variable<double>(intensity);
    map['wind_strength'] = Variable<double>(windStrength);
    map['visibility'] = Variable<double>(visibility);
    map['is_default'] = Variable<bool>(isDefault);
    return map;
  }

  EnvironmentWeatherProfilesCompanion toCompanion(bool nullToAbsent) {
    return EnvironmentWeatherProfilesCompanion(
      id: Value(id),
      environmentId: Value(environmentId),
      name: Value(name),
      weatherPreset: Value(weatherPreset),
      intensity: Value(intensity),
      windStrength: Value(windStrength),
      visibility: Value(visibility),
      isDefault: Value(isDefault),
    );
  }

  factory EnvironmentWeatherProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EnvironmentWeatherProfile(
      id: serializer.fromJson<String>(json['id']),
      environmentId: serializer.fromJson<String>(json['environmentId']),
      name: serializer.fromJson<String>(json['name']),
      weatherPreset: serializer.fromJson<String>(json['weatherPreset']),
      intensity: serializer.fromJson<double>(json['intensity']),
      windStrength: serializer.fromJson<double>(json['windStrength']),
      visibility: serializer.fromJson<double>(json['visibility']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'environmentId': serializer.toJson<String>(environmentId),
      'name': serializer.toJson<String>(name),
      'weatherPreset': serializer.toJson<String>(weatherPreset),
      'intensity': serializer.toJson<double>(intensity),
      'windStrength': serializer.toJson<double>(windStrength),
      'visibility': serializer.toJson<double>(visibility),
      'isDefault': serializer.toJson<bool>(isDefault),
    };
  }

  EnvironmentWeatherProfile copyWith({
    String? id,
    String? environmentId,
    String? name,
    String? weatherPreset,
    double? intensity,
    double? windStrength,
    double? visibility,
    bool? isDefault,
  }) => EnvironmentWeatherProfile(
    id: id ?? this.id,
    environmentId: environmentId ?? this.environmentId,
    name: name ?? this.name,
    weatherPreset: weatherPreset ?? this.weatherPreset,
    intensity: intensity ?? this.intensity,
    windStrength: windStrength ?? this.windStrength,
    visibility: visibility ?? this.visibility,
    isDefault: isDefault ?? this.isDefault,
  );
  EnvironmentWeatherProfile copyWithCompanion(
    EnvironmentWeatherProfilesCompanion data,
  ) {
    return EnvironmentWeatherProfile(
      id: data.id.present ? data.id.value : this.id,
      environmentId: data.environmentId.present
          ? data.environmentId.value
          : this.environmentId,
      name: data.name.present ? data.name.value : this.name,
      weatherPreset: data.weatherPreset.present
          ? data.weatherPreset.value
          : this.weatherPreset,
      intensity: data.intensity.present ? data.intensity.value : this.intensity,
      windStrength: data.windStrength.present
          ? data.windStrength.value
          : this.windStrength,
      visibility: data.visibility.present
          ? data.visibility.value
          : this.visibility,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EnvironmentWeatherProfile(')
          ..write('id: $id, ')
          ..write('environmentId: $environmentId, ')
          ..write('name: $name, ')
          ..write('weatherPreset: $weatherPreset, ')
          ..write('intensity: $intensity, ')
          ..write('windStrength: $windStrength, ')
          ..write('visibility: $visibility, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    environmentId,
    name,
    weatherPreset,
    intensity,
    windStrength,
    visibility,
    isDefault,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EnvironmentWeatherProfile &&
          other.id == this.id &&
          other.environmentId == this.environmentId &&
          other.name == this.name &&
          other.weatherPreset == this.weatherPreset &&
          other.intensity == this.intensity &&
          other.windStrength == this.windStrength &&
          other.visibility == this.visibility &&
          other.isDefault == this.isDefault);
}

class EnvironmentWeatherProfilesCompanion
    extends UpdateCompanion<EnvironmentWeatherProfile> {
  final Value<String> id;
  final Value<String> environmentId;
  final Value<String> name;
  final Value<String> weatherPreset;
  final Value<double> intensity;
  final Value<double> windStrength;
  final Value<double> visibility;
  final Value<bool> isDefault;
  final Value<int> rowid;
  const EnvironmentWeatherProfilesCompanion({
    this.id = const Value.absent(),
    this.environmentId = const Value.absent(),
    this.name = const Value.absent(),
    this.weatherPreset = const Value.absent(),
    this.intensity = const Value.absent(),
    this.windStrength = const Value.absent(),
    this.visibility = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EnvironmentWeatherProfilesCompanion.insert({
    required String id,
    required String environmentId,
    required String name,
    required String weatherPreset,
    this.intensity = const Value.absent(),
    this.windStrength = const Value.absent(),
    this.visibility = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       environmentId = Value(environmentId),
       name = Value(name),
       weatherPreset = Value(weatherPreset);
  static Insertable<EnvironmentWeatherProfile> custom({
    Expression<String>? id,
    Expression<String>? environmentId,
    Expression<String>? name,
    Expression<String>? weatherPreset,
    Expression<double>? intensity,
    Expression<double>? windStrength,
    Expression<double>? visibility,
    Expression<bool>? isDefault,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (environmentId != null) 'environment_id': environmentId,
      if (name != null) 'name': name,
      if (weatherPreset != null) 'weather_preset': weatherPreset,
      if (intensity != null) 'intensity': intensity,
      if (windStrength != null) 'wind_strength': windStrength,
      if (visibility != null) 'visibility': visibility,
      if (isDefault != null) 'is_default': isDefault,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EnvironmentWeatherProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? environmentId,
    Value<String>? name,
    Value<String>? weatherPreset,
    Value<double>? intensity,
    Value<double>? windStrength,
    Value<double>? visibility,
    Value<bool>? isDefault,
    Value<int>? rowid,
  }) {
    return EnvironmentWeatherProfilesCompanion(
      id: id ?? this.id,
      environmentId: environmentId ?? this.environmentId,
      name: name ?? this.name,
      weatherPreset: weatherPreset ?? this.weatherPreset,
      intensity: intensity ?? this.intensity,
      windStrength: windStrength ?? this.windStrength,
      visibility: visibility ?? this.visibility,
      isDefault: isDefault ?? this.isDefault,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (environmentId.present) {
      map['environment_id'] = Variable<String>(environmentId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (weatherPreset.present) {
      map['weather_preset'] = Variable<String>(weatherPreset.value);
    }
    if (intensity.present) {
      map['intensity'] = Variable<double>(intensity.value);
    }
    if (windStrength.present) {
      map['wind_strength'] = Variable<double>(windStrength.value);
    }
    if (visibility.present) {
      map['visibility'] = Variable<double>(visibility.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnvironmentWeatherProfilesCompanion(')
          ..write('id: $id, ')
          ..write('environmentId: $environmentId, ')
          ..write('name: $name, ')
          ..write('weatherPreset: $weatherPreset, ')
          ..write('intensity: $intensity, ')
          ..write('windStrength: $windStrength, ')
          ..write('visibility: $visibility, ')
          ..write('isDefault: $isDefault, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EnvironmentLightingProfilesTable extends EnvironmentLightingProfiles
    with
        TableInfo<
          $EnvironmentLightingProfilesTable,
          EnvironmentLightingProfile
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EnvironmentLightingProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _environmentIdMeta = const VerificationMeta(
    'environmentId',
  );
  @override
  late final GeneratedColumn<String> environmentId = GeneratedColumn<String>(
    'environment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timePresetMeta = const VerificationMeta(
    'timePreset',
  );
  @override
  late final GeneratedColumn<String> timePreset = GeneratedColumn<String>(
    'time_preset',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyLightMeta = const VerificationMeta(
    'keyLight',
  );
  @override
  late final GeneratedColumn<String> keyLight = GeneratedColumn<String>(
    'key_light',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _fillLightMeta = const VerificationMeta(
    'fillLight',
  );
  @override
  late final GeneratedColumn<String> fillLight = GeneratedColumn<String>(
    'fill_light',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _rimLightMeta = const VerificationMeta(
    'rimLight',
  );
  @override
  late final GeneratedColumn<String> rimLight = GeneratedColumn<String>(
    'rim_light',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _environmentLightMeta = const VerificationMeta(
    'environmentLight',
  );
  @override
  late final GeneratedColumn<String> environmentLight = GeneratedColumn<String>(
    'environment_light',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _practicalLightsMeta = const VerificationMeta(
    'practicalLights',
  );
  @override
  late final GeneratedColumn<String> practicalLights = GeneratedColumn<String>(
    'practical_lights',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _fogDensityMeta = const VerificationMeta(
    'fogDensity',
  );
  @override
  late final GeneratedColumn<double> fogDensity = GeneratedColumn<double>(
    'fog_density',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _bloomIntensityMeta = const VerificationMeta(
    'bloomIntensity',
  );
  @override
  late final GeneratedColumn<double> bloomIntensity = GeneratedColumn<double>(
    'bloom_intensity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    environmentId,
    name,
    timePreset,
    keyLight,
    fillLight,
    rimLight,
    environmentLight,
    practicalLights,
    fogDensity,
    bloomIntensity,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'environment_lighting_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<EnvironmentLightingProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('environment_id')) {
      context.handle(
        _environmentIdMeta,
        environmentId.isAcceptableOrUnknown(
          data['environment_id']!,
          _environmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_environmentIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('time_preset')) {
      context.handle(
        _timePresetMeta,
        timePreset.isAcceptableOrUnknown(data['time_preset']!, _timePresetMeta),
      );
    } else if (isInserting) {
      context.missing(_timePresetMeta);
    }
    if (data.containsKey('key_light')) {
      context.handle(
        _keyLightMeta,
        keyLight.isAcceptableOrUnknown(data['key_light']!, _keyLightMeta),
      );
    }
    if (data.containsKey('fill_light')) {
      context.handle(
        _fillLightMeta,
        fillLight.isAcceptableOrUnknown(data['fill_light']!, _fillLightMeta),
      );
    }
    if (data.containsKey('rim_light')) {
      context.handle(
        _rimLightMeta,
        rimLight.isAcceptableOrUnknown(data['rim_light']!, _rimLightMeta),
      );
    }
    if (data.containsKey('environment_light')) {
      context.handle(
        _environmentLightMeta,
        environmentLight.isAcceptableOrUnknown(
          data['environment_light']!,
          _environmentLightMeta,
        ),
      );
    }
    if (data.containsKey('practical_lights')) {
      context.handle(
        _practicalLightsMeta,
        practicalLights.isAcceptableOrUnknown(
          data['practical_lights']!,
          _practicalLightsMeta,
        ),
      );
    }
    if (data.containsKey('fog_density')) {
      context.handle(
        _fogDensityMeta,
        fogDensity.isAcceptableOrUnknown(data['fog_density']!, _fogDensityMeta),
      );
    }
    if (data.containsKey('bloom_intensity')) {
      context.handle(
        _bloomIntensityMeta,
        bloomIntensity.isAcceptableOrUnknown(
          data['bloom_intensity']!,
          _bloomIntensityMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EnvironmentLightingProfile map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EnvironmentLightingProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      environmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}environment_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      timePreset: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_preset'],
      )!,
      keyLight: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_light'],
      )!,
      fillLight: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fill_light'],
      )!,
      rimLight: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rim_light'],
      )!,
      environmentLight: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}environment_light'],
      )!,
      practicalLights: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}practical_lights'],
      )!,
      fogDensity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fog_density'],
      )!,
      bloomIntensity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bloom_intensity'],
      )!,
    );
  }

  @override
  $EnvironmentLightingProfilesTable createAlias(String alias) {
    return $EnvironmentLightingProfilesTable(attachedDatabase, alias);
  }
}

class EnvironmentLightingProfile extends DataClass
    implements Insertable<EnvironmentLightingProfile> {
  final String id;
  final String environmentId;
  final String name;
  final String timePreset;
  final String keyLight;
  final String fillLight;
  final String rimLight;
  final String environmentLight;
  final String practicalLights;
  final double fogDensity;
  final double bloomIntensity;
  const EnvironmentLightingProfile({
    required this.id,
    required this.environmentId,
    required this.name,
    required this.timePreset,
    required this.keyLight,
    required this.fillLight,
    required this.rimLight,
    required this.environmentLight,
    required this.practicalLights,
    required this.fogDensity,
    required this.bloomIntensity,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['environment_id'] = Variable<String>(environmentId);
    map['name'] = Variable<String>(name);
    map['time_preset'] = Variable<String>(timePreset);
    map['key_light'] = Variable<String>(keyLight);
    map['fill_light'] = Variable<String>(fillLight);
    map['rim_light'] = Variable<String>(rimLight);
    map['environment_light'] = Variable<String>(environmentLight);
    map['practical_lights'] = Variable<String>(practicalLights);
    map['fog_density'] = Variable<double>(fogDensity);
    map['bloom_intensity'] = Variable<double>(bloomIntensity);
    return map;
  }

  EnvironmentLightingProfilesCompanion toCompanion(bool nullToAbsent) {
    return EnvironmentLightingProfilesCompanion(
      id: Value(id),
      environmentId: Value(environmentId),
      name: Value(name),
      timePreset: Value(timePreset),
      keyLight: Value(keyLight),
      fillLight: Value(fillLight),
      rimLight: Value(rimLight),
      environmentLight: Value(environmentLight),
      practicalLights: Value(practicalLights),
      fogDensity: Value(fogDensity),
      bloomIntensity: Value(bloomIntensity),
    );
  }

  factory EnvironmentLightingProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EnvironmentLightingProfile(
      id: serializer.fromJson<String>(json['id']),
      environmentId: serializer.fromJson<String>(json['environmentId']),
      name: serializer.fromJson<String>(json['name']),
      timePreset: serializer.fromJson<String>(json['timePreset']),
      keyLight: serializer.fromJson<String>(json['keyLight']),
      fillLight: serializer.fromJson<String>(json['fillLight']),
      rimLight: serializer.fromJson<String>(json['rimLight']),
      environmentLight: serializer.fromJson<String>(json['environmentLight']),
      practicalLights: serializer.fromJson<String>(json['practicalLights']),
      fogDensity: serializer.fromJson<double>(json['fogDensity']),
      bloomIntensity: serializer.fromJson<double>(json['bloomIntensity']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'environmentId': serializer.toJson<String>(environmentId),
      'name': serializer.toJson<String>(name),
      'timePreset': serializer.toJson<String>(timePreset),
      'keyLight': serializer.toJson<String>(keyLight),
      'fillLight': serializer.toJson<String>(fillLight),
      'rimLight': serializer.toJson<String>(rimLight),
      'environmentLight': serializer.toJson<String>(environmentLight),
      'practicalLights': serializer.toJson<String>(practicalLights),
      'fogDensity': serializer.toJson<double>(fogDensity),
      'bloomIntensity': serializer.toJson<double>(bloomIntensity),
    };
  }

  EnvironmentLightingProfile copyWith({
    String? id,
    String? environmentId,
    String? name,
    String? timePreset,
    String? keyLight,
    String? fillLight,
    String? rimLight,
    String? environmentLight,
    String? practicalLights,
    double? fogDensity,
    double? bloomIntensity,
  }) => EnvironmentLightingProfile(
    id: id ?? this.id,
    environmentId: environmentId ?? this.environmentId,
    name: name ?? this.name,
    timePreset: timePreset ?? this.timePreset,
    keyLight: keyLight ?? this.keyLight,
    fillLight: fillLight ?? this.fillLight,
    rimLight: rimLight ?? this.rimLight,
    environmentLight: environmentLight ?? this.environmentLight,
    practicalLights: practicalLights ?? this.practicalLights,
    fogDensity: fogDensity ?? this.fogDensity,
    bloomIntensity: bloomIntensity ?? this.bloomIntensity,
  );
  EnvironmentLightingProfile copyWithCompanion(
    EnvironmentLightingProfilesCompanion data,
  ) {
    return EnvironmentLightingProfile(
      id: data.id.present ? data.id.value : this.id,
      environmentId: data.environmentId.present
          ? data.environmentId.value
          : this.environmentId,
      name: data.name.present ? data.name.value : this.name,
      timePreset: data.timePreset.present
          ? data.timePreset.value
          : this.timePreset,
      keyLight: data.keyLight.present ? data.keyLight.value : this.keyLight,
      fillLight: data.fillLight.present ? data.fillLight.value : this.fillLight,
      rimLight: data.rimLight.present ? data.rimLight.value : this.rimLight,
      environmentLight: data.environmentLight.present
          ? data.environmentLight.value
          : this.environmentLight,
      practicalLights: data.practicalLights.present
          ? data.practicalLights.value
          : this.practicalLights,
      fogDensity: data.fogDensity.present
          ? data.fogDensity.value
          : this.fogDensity,
      bloomIntensity: data.bloomIntensity.present
          ? data.bloomIntensity.value
          : this.bloomIntensity,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EnvironmentLightingProfile(')
          ..write('id: $id, ')
          ..write('environmentId: $environmentId, ')
          ..write('name: $name, ')
          ..write('timePreset: $timePreset, ')
          ..write('keyLight: $keyLight, ')
          ..write('fillLight: $fillLight, ')
          ..write('rimLight: $rimLight, ')
          ..write('environmentLight: $environmentLight, ')
          ..write('practicalLights: $practicalLights, ')
          ..write('fogDensity: $fogDensity, ')
          ..write('bloomIntensity: $bloomIntensity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    environmentId,
    name,
    timePreset,
    keyLight,
    fillLight,
    rimLight,
    environmentLight,
    practicalLights,
    fogDensity,
    bloomIntensity,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EnvironmentLightingProfile &&
          other.id == this.id &&
          other.environmentId == this.environmentId &&
          other.name == this.name &&
          other.timePreset == this.timePreset &&
          other.keyLight == this.keyLight &&
          other.fillLight == this.fillLight &&
          other.rimLight == this.rimLight &&
          other.environmentLight == this.environmentLight &&
          other.practicalLights == this.practicalLights &&
          other.fogDensity == this.fogDensity &&
          other.bloomIntensity == this.bloomIntensity);
}

class EnvironmentLightingProfilesCompanion
    extends UpdateCompanion<EnvironmentLightingProfile> {
  final Value<String> id;
  final Value<String> environmentId;
  final Value<String> name;
  final Value<String> timePreset;
  final Value<String> keyLight;
  final Value<String> fillLight;
  final Value<String> rimLight;
  final Value<String> environmentLight;
  final Value<String> practicalLights;
  final Value<double> fogDensity;
  final Value<double> bloomIntensity;
  final Value<int> rowid;
  const EnvironmentLightingProfilesCompanion({
    this.id = const Value.absent(),
    this.environmentId = const Value.absent(),
    this.name = const Value.absent(),
    this.timePreset = const Value.absent(),
    this.keyLight = const Value.absent(),
    this.fillLight = const Value.absent(),
    this.rimLight = const Value.absent(),
    this.environmentLight = const Value.absent(),
    this.practicalLights = const Value.absent(),
    this.fogDensity = const Value.absent(),
    this.bloomIntensity = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EnvironmentLightingProfilesCompanion.insert({
    required String id,
    required String environmentId,
    required String name,
    required String timePreset,
    this.keyLight = const Value.absent(),
    this.fillLight = const Value.absent(),
    this.rimLight = const Value.absent(),
    this.environmentLight = const Value.absent(),
    this.practicalLights = const Value.absent(),
    this.fogDensity = const Value.absent(),
    this.bloomIntensity = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       environmentId = Value(environmentId),
       name = Value(name),
       timePreset = Value(timePreset);
  static Insertable<EnvironmentLightingProfile> custom({
    Expression<String>? id,
    Expression<String>? environmentId,
    Expression<String>? name,
    Expression<String>? timePreset,
    Expression<String>? keyLight,
    Expression<String>? fillLight,
    Expression<String>? rimLight,
    Expression<String>? environmentLight,
    Expression<String>? practicalLights,
    Expression<double>? fogDensity,
    Expression<double>? bloomIntensity,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (environmentId != null) 'environment_id': environmentId,
      if (name != null) 'name': name,
      if (timePreset != null) 'time_preset': timePreset,
      if (keyLight != null) 'key_light': keyLight,
      if (fillLight != null) 'fill_light': fillLight,
      if (rimLight != null) 'rim_light': rimLight,
      if (environmentLight != null) 'environment_light': environmentLight,
      if (practicalLights != null) 'practical_lights': practicalLights,
      if (fogDensity != null) 'fog_density': fogDensity,
      if (bloomIntensity != null) 'bloom_intensity': bloomIntensity,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EnvironmentLightingProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? environmentId,
    Value<String>? name,
    Value<String>? timePreset,
    Value<String>? keyLight,
    Value<String>? fillLight,
    Value<String>? rimLight,
    Value<String>? environmentLight,
    Value<String>? practicalLights,
    Value<double>? fogDensity,
    Value<double>? bloomIntensity,
    Value<int>? rowid,
  }) {
    return EnvironmentLightingProfilesCompanion(
      id: id ?? this.id,
      environmentId: environmentId ?? this.environmentId,
      name: name ?? this.name,
      timePreset: timePreset ?? this.timePreset,
      keyLight: keyLight ?? this.keyLight,
      fillLight: fillLight ?? this.fillLight,
      rimLight: rimLight ?? this.rimLight,
      environmentLight: environmentLight ?? this.environmentLight,
      practicalLights: practicalLights ?? this.practicalLights,
      fogDensity: fogDensity ?? this.fogDensity,
      bloomIntensity: bloomIntensity ?? this.bloomIntensity,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (environmentId.present) {
      map['environment_id'] = Variable<String>(environmentId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (timePreset.present) {
      map['time_preset'] = Variable<String>(timePreset.value);
    }
    if (keyLight.present) {
      map['key_light'] = Variable<String>(keyLight.value);
    }
    if (fillLight.present) {
      map['fill_light'] = Variable<String>(fillLight.value);
    }
    if (rimLight.present) {
      map['rim_light'] = Variable<String>(rimLight.value);
    }
    if (environmentLight.present) {
      map['environment_light'] = Variable<String>(environmentLight.value);
    }
    if (practicalLights.present) {
      map['practical_lights'] = Variable<String>(practicalLights.value);
    }
    if (fogDensity.present) {
      map['fog_density'] = Variable<double>(fogDensity.value);
    }
    if (bloomIntensity.present) {
      map['bloom_intensity'] = Variable<double>(bloomIntensity.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnvironmentLightingProfilesCompanion(')
          ..write('id: $id, ')
          ..write('environmentId: $environmentId, ')
          ..write('name: $name, ')
          ..write('timePreset: $timePreset, ')
          ..write('keyLight: $keyLight, ')
          ..write('fillLight: $fillLight, ')
          ..write('rimLight: $rimLight, ')
          ..write('environmentLight: $environmentLight, ')
          ..write('practicalLights: $practicalLights, ')
          ..write('fogDensity: $fogDensity, ')
          ..write('bloomIntensity: $bloomIntensity, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EnvironmentColorsTable extends EnvironmentColors
    with TableInfo<$EnvironmentColorsTable, EnvironmentColor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EnvironmentColorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _environmentIdMeta = const VerificationMeta(
    'environmentId',
  );
  @override
  late final GeneratedColumn<String> environmentId = GeneratedColumn<String>(
    'environment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hexValueMeta = const VerificationMeta(
    'hexValue',
  );
  @override
  late final GeneratedColumn<String> hexValue = GeneratedColumn<String>(
    'hex_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usageMeta = const VerificationMeta('usage');
  @override
  late final GeneratedColumn<String> usage = GeneratedColumn<String>(
    'usage',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    environmentId,
    name,
    hexValue,
    usage,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'environment_colors';
  @override
  VerificationContext validateIntegrity(
    Insertable<EnvironmentColor> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('environment_id')) {
      context.handle(
        _environmentIdMeta,
        environmentId.isAcceptableOrUnknown(
          data['environment_id']!,
          _environmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_environmentIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('hex_value')) {
      context.handle(
        _hexValueMeta,
        hexValue.isAcceptableOrUnknown(data['hex_value']!, _hexValueMeta),
      );
    } else if (isInserting) {
      context.missing(_hexValueMeta);
    }
    if (data.containsKey('usage')) {
      context.handle(
        _usageMeta,
        usage.isAcceptableOrUnknown(data['usage']!, _usageMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EnvironmentColor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EnvironmentColor(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      environmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}environment_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      hexValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hex_value'],
      )!,
      usage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}usage'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $EnvironmentColorsTable createAlias(String alias) {
    return $EnvironmentColorsTable(attachedDatabase, alias);
  }
}

class EnvironmentColor extends DataClass
    implements Insertable<EnvironmentColor> {
  final String id;
  final String environmentId;
  final String name;
  final String hexValue;
  final String usage;
  final int sortOrder;
  const EnvironmentColor({
    required this.id,
    required this.environmentId,
    required this.name,
    required this.hexValue,
    required this.usage,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['environment_id'] = Variable<String>(environmentId);
    map['name'] = Variable<String>(name);
    map['hex_value'] = Variable<String>(hexValue);
    map['usage'] = Variable<String>(usage);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  EnvironmentColorsCompanion toCompanion(bool nullToAbsent) {
    return EnvironmentColorsCompanion(
      id: Value(id),
      environmentId: Value(environmentId),
      name: Value(name),
      hexValue: Value(hexValue),
      usage: Value(usage),
      sortOrder: Value(sortOrder),
    );
  }

  factory EnvironmentColor.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EnvironmentColor(
      id: serializer.fromJson<String>(json['id']),
      environmentId: serializer.fromJson<String>(json['environmentId']),
      name: serializer.fromJson<String>(json['name']),
      hexValue: serializer.fromJson<String>(json['hexValue']),
      usage: serializer.fromJson<String>(json['usage']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'environmentId': serializer.toJson<String>(environmentId),
      'name': serializer.toJson<String>(name),
      'hexValue': serializer.toJson<String>(hexValue),
      'usage': serializer.toJson<String>(usage),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  EnvironmentColor copyWith({
    String? id,
    String? environmentId,
    String? name,
    String? hexValue,
    String? usage,
    int? sortOrder,
  }) => EnvironmentColor(
    id: id ?? this.id,
    environmentId: environmentId ?? this.environmentId,
    name: name ?? this.name,
    hexValue: hexValue ?? this.hexValue,
    usage: usage ?? this.usage,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  EnvironmentColor copyWithCompanion(EnvironmentColorsCompanion data) {
    return EnvironmentColor(
      id: data.id.present ? data.id.value : this.id,
      environmentId: data.environmentId.present
          ? data.environmentId.value
          : this.environmentId,
      name: data.name.present ? data.name.value : this.name,
      hexValue: data.hexValue.present ? data.hexValue.value : this.hexValue,
      usage: data.usage.present ? data.usage.value : this.usage,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EnvironmentColor(')
          ..write('id: $id, ')
          ..write('environmentId: $environmentId, ')
          ..write('name: $name, ')
          ..write('hexValue: $hexValue, ')
          ..write('usage: $usage, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, environmentId, name, hexValue, usage, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EnvironmentColor &&
          other.id == this.id &&
          other.environmentId == this.environmentId &&
          other.name == this.name &&
          other.hexValue == this.hexValue &&
          other.usage == this.usage &&
          other.sortOrder == this.sortOrder);
}

class EnvironmentColorsCompanion extends UpdateCompanion<EnvironmentColor> {
  final Value<String> id;
  final Value<String> environmentId;
  final Value<String> name;
  final Value<String> hexValue;
  final Value<String> usage;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const EnvironmentColorsCompanion({
    this.id = const Value.absent(),
    this.environmentId = const Value.absent(),
    this.name = const Value.absent(),
    this.hexValue = const Value.absent(),
    this.usage = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EnvironmentColorsCompanion.insert({
    required String id,
    required String environmentId,
    required String name,
    required String hexValue,
    this.usage = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       environmentId = Value(environmentId),
       name = Value(name),
       hexValue = Value(hexValue);
  static Insertable<EnvironmentColor> custom({
    Expression<String>? id,
    Expression<String>? environmentId,
    Expression<String>? name,
    Expression<String>? hexValue,
    Expression<String>? usage,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (environmentId != null) 'environment_id': environmentId,
      if (name != null) 'name': name,
      if (hexValue != null) 'hex_value': hexValue,
      if (usage != null) 'usage': usage,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EnvironmentColorsCompanion copyWith({
    Value<String>? id,
    Value<String>? environmentId,
    Value<String>? name,
    Value<String>? hexValue,
    Value<String>? usage,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return EnvironmentColorsCompanion(
      id: id ?? this.id,
      environmentId: environmentId ?? this.environmentId,
      name: name ?? this.name,
      hexValue: hexValue ?? this.hexValue,
      usage: usage ?? this.usage,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (environmentId.present) {
      map['environment_id'] = Variable<String>(environmentId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (hexValue.present) {
      map['hex_value'] = Variable<String>(hexValue.value);
    }
    if (usage.present) {
      map['usage'] = Variable<String>(usage.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnvironmentColorsCompanion(')
          ..write('id: $id, ')
          ..write('environmentId: $environmentId, ')
          ..write('name: $name, ')
          ..write('hexValue: $hexValue, ')
          ..write('usage: $usage, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EnvironmentPropsTable extends EnvironmentProps
    with TableInfo<$EnvironmentPropsTable, EnvironmentProp> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EnvironmentPropsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _environmentIdMeta = const VerificationMeta(
    'environmentId',
  );
  @override
  late final GeneratedColumn<String> environmentId = GeneratedColumn<String>(
    'environment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _zoneIdMeta = const VerificationMeta('zoneId');
  @override
  late final GeneratedColumn<String> zoneId = GeneratedColumn<String>(
    'zone_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _propTypeMeta = const VerificationMeta(
    'propType',
  );
  @override
  late final GeneratedColumn<String> propType = GeneratedColumn<String>(
    'prop_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _positionNoteMeta = const VerificationMeta(
    'positionNote',
  );
  @override
  late final GeneratedColumn<String> positionNote = GeneratedColumn<String>(
    'position_note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    environmentId,
    zoneId,
    name,
    propType,
    state,
    positionNote,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'environment_props';
  @override
  VerificationContext validateIntegrity(
    Insertable<EnvironmentProp> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('environment_id')) {
      context.handle(
        _environmentIdMeta,
        environmentId.isAcceptableOrUnknown(
          data['environment_id']!,
          _environmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_environmentIdMeta);
    }
    if (data.containsKey('zone_id')) {
      context.handle(
        _zoneIdMeta,
        zoneId.isAcceptableOrUnknown(data['zone_id']!, _zoneIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('prop_type')) {
      context.handle(
        _propTypeMeta,
        propType.isAcceptableOrUnknown(data['prop_type']!, _propTypeMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('position_note')) {
      context.handle(
        _positionNoteMeta,
        positionNote.isAcceptableOrUnknown(
          data['position_note']!,
          _positionNoteMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EnvironmentProp map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EnvironmentProp(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      environmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}environment_id'],
      )!,
      zoneId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zone_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      propType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prop_type'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      positionNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}position_note'],
      )!,
    );
  }

  @override
  $EnvironmentPropsTable createAlias(String alias) {
    return $EnvironmentPropsTable(attachedDatabase, alias);
  }
}

class EnvironmentProp extends DataClass implements Insertable<EnvironmentProp> {
  final String id;
  final String environmentId;
  final String? zoneId;
  final String name;
  final String propType;
  final String state;
  final String positionNote;
  const EnvironmentProp({
    required this.id,
    required this.environmentId,
    this.zoneId,
    required this.name,
    required this.propType,
    required this.state,
    required this.positionNote,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['environment_id'] = Variable<String>(environmentId);
    if (!nullToAbsent || zoneId != null) {
      map['zone_id'] = Variable<String>(zoneId);
    }
    map['name'] = Variable<String>(name);
    map['prop_type'] = Variable<String>(propType);
    map['state'] = Variable<String>(state);
    map['position_note'] = Variable<String>(positionNote);
    return map;
  }

  EnvironmentPropsCompanion toCompanion(bool nullToAbsent) {
    return EnvironmentPropsCompanion(
      id: Value(id),
      environmentId: Value(environmentId),
      zoneId: zoneId == null && nullToAbsent
          ? const Value.absent()
          : Value(zoneId),
      name: Value(name),
      propType: Value(propType),
      state: Value(state),
      positionNote: Value(positionNote),
    );
  }

  factory EnvironmentProp.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EnvironmentProp(
      id: serializer.fromJson<String>(json['id']),
      environmentId: serializer.fromJson<String>(json['environmentId']),
      zoneId: serializer.fromJson<String?>(json['zoneId']),
      name: serializer.fromJson<String>(json['name']),
      propType: serializer.fromJson<String>(json['propType']),
      state: serializer.fromJson<String>(json['state']),
      positionNote: serializer.fromJson<String>(json['positionNote']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'environmentId': serializer.toJson<String>(environmentId),
      'zoneId': serializer.toJson<String?>(zoneId),
      'name': serializer.toJson<String>(name),
      'propType': serializer.toJson<String>(propType),
      'state': serializer.toJson<String>(state),
      'positionNote': serializer.toJson<String>(positionNote),
    };
  }

  EnvironmentProp copyWith({
    String? id,
    String? environmentId,
    Value<String?> zoneId = const Value.absent(),
    String? name,
    String? propType,
    String? state,
    String? positionNote,
  }) => EnvironmentProp(
    id: id ?? this.id,
    environmentId: environmentId ?? this.environmentId,
    zoneId: zoneId.present ? zoneId.value : this.zoneId,
    name: name ?? this.name,
    propType: propType ?? this.propType,
    state: state ?? this.state,
    positionNote: positionNote ?? this.positionNote,
  );
  EnvironmentProp copyWithCompanion(EnvironmentPropsCompanion data) {
    return EnvironmentProp(
      id: data.id.present ? data.id.value : this.id,
      environmentId: data.environmentId.present
          ? data.environmentId.value
          : this.environmentId,
      zoneId: data.zoneId.present ? data.zoneId.value : this.zoneId,
      name: data.name.present ? data.name.value : this.name,
      propType: data.propType.present ? data.propType.value : this.propType,
      state: data.state.present ? data.state.value : this.state,
      positionNote: data.positionNote.present
          ? data.positionNote.value
          : this.positionNote,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EnvironmentProp(')
          ..write('id: $id, ')
          ..write('environmentId: $environmentId, ')
          ..write('zoneId: $zoneId, ')
          ..write('name: $name, ')
          ..write('propType: $propType, ')
          ..write('state: $state, ')
          ..write('positionNote: $positionNote')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    environmentId,
    zoneId,
    name,
    propType,
    state,
    positionNote,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EnvironmentProp &&
          other.id == this.id &&
          other.environmentId == this.environmentId &&
          other.zoneId == this.zoneId &&
          other.name == this.name &&
          other.propType == this.propType &&
          other.state == this.state &&
          other.positionNote == this.positionNote);
}

class EnvironmentPropsCompanion extends UpdateCompanion<EnvironmentProp> {
  final Value<String> id;
  final Value<String> environmentId;
  final Value<String?> zoneId;
  final Value<String> name;
  final Value<String> propType;
  final Value<String> state;
  final Value<String> positionNote;
  final Value<int> rowid;
  const EnvironmentPropsCompanion({
    this.id = const Value.absent(),
    this.environmentId = const Value.absent(),
    this.zoneId = const Value.absent(),
    this.name = const Value.absent(),
    this.propType = const Value.absent(),
    this.state = const Value.absent(),
    this.positionNote = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EnvironmentPropsCompanion.insert({
    required String id,
    required String environmentId,
    this.zoneId = const Value.absent(),
    required String name,
    this.propType = const Value.absent(),
    this.state = const Value.absent(),
    this.positionNote = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       environmentId = Value(environmentId),
       name = Value(name);
  static Insertable<EnvironmentProp> custom({
    Expression<String>? id,
    Expression<String>? environmentId,
    Expression<String>? zoneId,
    Expression<String>? name,
    Expression<String>? propType,
    Expression<String>? state,
    Expression<String>? positionNote,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (environmentId != null) 'environment_id': environmentId,
      if (zoneId != null) 'zone_id': zoneId,
      if (name != null) 'name': name,
      if (propType != null) 'prop_type': propType,
      if (state != null) 'state': state,
      if (positionNote != null) 'position_note': positionNote,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EnvironmentPropsCompanion copyWith({
    Value<String>? id,
    Value<String>? environmentId,
    Value<String?>? zoneId,
    Value<String>? name,
    Value<String>? propType,
    Value<String>? state,
    Value<String>? positionNote,
    Value<int>? rowid,
  }) {
    return EnvironmentPropsCompanion(
      id: id ?? this.id,
      environmentId: environmentId ?? this.environmentId,
      zoneId: zoneId ?? this.zoneId,
      name: name ?? this.name,
      propType: propType ?? this.propType,
      state: state ?? this.state,
      positionNote: positionNote ?? this.positionNote,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (environmentId.present) {
      map['environment_id'] = Variable<String>(environmentId.value);
    }
    if (zoneId.present) {
      map['zone_id'] = Variable<String>(zoneId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (propType.present) {
      map['prop_type'] = Variable<String>(propType.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (positionNote.present) {
      map['position_note'] = Variable<String>(positionNote.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnvironmentPropsCompanion(')
          ..write('id: $id, ')
          ..write('environmentId: $environmentId, ')
          ..write('zoneId: $zoneId, ')
          ..write('name: $name, ')
          ..write('propType: $propType, ')
          ..write('state: $state, ')
          ..write('positionNote: $positionNote, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EnvironmentContinuityStatesTable extends EnvironmentContinuityStates
    with
        TableInfo<
          $EnvironmentContinuityStatesTable,
          EnvironmentContinuityState
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EnvironmentContinuityStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _environmentIdMeta = const VerificationMeta(
    'environmentId',
  );
  @override
  late final GeneratedColumn<String> environmentId = GeneratedColumn<String>(
    'environment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    environmentId,
    name,
    description,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'environment_continuity_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<EnvironmentContinuityState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('environment_id')) {
      context.handle(
        _environmentIdMeta,
        environmentId.isAcceptableOrUnknown(
          data['environment_id']!,
          _environmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_environmentIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EnvironmentContinuityState map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EnvironmentContinuityState(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      environmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}environment_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $EnvironmentContinuityStatesTable createAlias(String alias) {
    return $EnvironmentContinuityStatesTable(attachedDatabase, alias);
  }
}

class EnvironmentContinuityState extends DataClass
    implements Insertable<EnvironmentContinuityState> {
  final String id;
  final String environmentId;
  final String name;
  final String description;
  final DateTime createdAt;
  const EnvironmentContinuityState({
    required this.id,
    required this.environmentId,
    required this.name,
    required this.description,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['environment_id'] = Variable<String>(environmentId);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EnvironmentContinuityStatesCompanion toCompanion(bool nullToAbsent) {
    return EnvironmentContinuityStatesCompanion(
      id: Value(id),
      environmentId: Value(environmentId),
      name: Value(name),
      description: Value(description),
      createdAt: Value(createdAt),
    );
  }

  factory EnvironmentContinuityState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EnvironmentContinuityState(
      id: serializer.fromJson<String>(json['id']),
      environmentId: serializer.fromJson<String>(json['environmentId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'environmentId': serializer.toJson<String>(environmentId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  EnvironmentContinuityState copyWith({
    String? id,
    String? environmentId,
    String? name,
    String? description,
    DateTime? createdAt,
  }) => EnvironmentContinuityState(
    id: id ?? this.id,
    environmentId: environmentId ?? this.environmentId,
    name: name ?? this.name,
    description: description ?? this.description,
    createdAt: createdAt ?? this.createdAt,
  );
  EnvironmentContinuityState copyWithCompanion(
    EnvironmentContinuityStatesCompanion data,
  ) {
    return EnvironmentContinuityState(
      id: data.id.present ? data.id.value : this.id,
      environmentId: data.environmentId.present
          ? data.environmentId.value
          : this.environmentId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EnvironmentContinuityState(')
          ..write('id: $id, ')
          ..write('environmentId: $environmentId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, environmentId, name, description, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EnvironmentContinuityState &&
          other.id == this.id &&
          other.environmentId == this.environmentId &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt);
}

class EnvironmentContinuityStatesCompanion
    extends UpdateCompanion<EnvironmentContinuityState> {
  final Value<String> id;
  final Value<String> environmentId;
  final Value<String> name;
  final Value<String> description;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const EnvironmentContinuityStatesCompanion({
    this.id = const Value.absent(),
    this.environmentId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EnvironmentContinuityStatesCompanion.insert({
    required String id,
    required String environmentId,
    required String name,
    this.description = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       environmentId = Value(environmentId),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<EnvironmentContinuityState> custom({
    Expression<String>? id,
    Expression<String>? environmentId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (environmentId != null) 'environment_id': environmentId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EnvironmentContinuityStatesCompanion copyWith({
    Value<String>? id,
    Value<String>? environmentId,
    Value<String>? name,
    Value<String>? description,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return EnvironmentContinuityStatesCompanion(
      id: id ?? this.id,
      environmentId: environmentId ?? this.environmentId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (environmentId.present) {
      map['environment_id'] = Variable<String>(environmentId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnvironmentContinuityStatesCompanion(')
          ..write('id: $id, ')
          ..write('environmentId: $environmentId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EnvironmentPhysicsProfilesTable extends EnvironmentPhysicsProfiles
    with
        TableInfo<$EnvironmentPhysicsProfilesTable, EnvironmentPhysicsProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EnvironmentPhysicsProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _environmentIdMeta = const VerificationMeta(
    'environmentId',
  );
  @override
  late final GeneratedColumn<String> environmentId = GeneratedColumn<String>(
    'environment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gravityMultiplierMeta = const VerificationMeta(
    'gravityMultiplier',
  );
  @override
  late final GeneratedColumn<double> gravityMultiplier =
      GeneratedColumn<double>(
        'gravity_multiplier',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(1.0),
      );
  static const VerificationMeta _floatingObjectsMeta = const VerificationMeta(
    'floatingObjects',
  );
  @override
  late final GeneratedColumn<bool> floatingObjects = GeneratedColumn<bool>(
    'floating_objects',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("floating_objects" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dimensionalDistortionMeta =
      const VerificationMeta('dimensionalDistortion');
  @override
  late final GeneratedColumn<String> dimensionalDistortion =
      GeneratedColumn<String>(
        'dimensional_distortion',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('none'),
      );
  static const VerificationMeta _portalBehaviorMeta = const VerificationMeta(
    'portalBehavior',
  );
  @override
  late final GeneratedColumn<String> portalBehavior = GeneratedColumn<String>(
    'portal_behavior',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('normal'),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    environmentId,
    gravityMultiplier,
    floatingObjects,
    dimensionalDistortion,
    portalBehavior,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'environment_physics_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<EnvironmentPhysicsProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('environment_id')) {
      context.handle(
        _environmentIdMeta,
        environmentId.isAcceptableOrUnknown(
          data['environment_id']!,
          _environmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_environmentIdMeta);
    }
    if (data.containsKey('gravity_multiplier')) {
      context.handle(
        _gravityMultiplierMeta,
        gravityMultiplier.isAcceptableOrUnknown(
          data['gravity_multiplier']!,
          _gravityMultiplierMeta,
        ),
      );
    }
    if (data.containsKey('floating_objects')) {
      context.handle(
        _floatingObjectsMeta,
        floatingObjects.isAcceptableOrUnknown(
          data['floating_objects']!,
          _floatingObjectsMeta,
        ),
      );
    }
    if (data.containsKey('dimensional_distortion')) {
      context.handle(
        _dimensionalDistortionMeta,
        dimensionalDistortion.isAcceptableOrUnknown(
          data['dimensional_distortion']!,
          _dimensionalDistortionMeta,
        ),
      );
    }
    if (data.containsKey('portal_behavior')) {
      context.handle(
        _portalBehaviorMeta,
        portalBehavior.isAcceptableOrUnknown(
          data['portal_behavior']!,
          _portalBehaviorMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {environmentId};
  @override
  EnvironmentPhysicsProfile map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EnvironmentPhysicsProfile(
      environmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}environment_id'],
      )!,
      gravityMultiplier: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gravity_multiplier'],
      )!,
      floatingObjects: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}floating_objects'],
      )!,
      dimensionalDistortion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dimensional_distortion'],
      )!,
      portalBehavior: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}portal_behavior'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
    );
  }

  @override
  $EnvironmentPhysicsProfilesTable createAlias(String alias) {
    return $EnvironmentPhysicsProfilesTable(attachedDatabase, alias);
  }
}

class EnvironmentPhysicsProfile extends DataClass
    implements Insertable<EnvironmentPhysicsProfile> {
  final String environmentId;
  final double gravityMultiplier;
  final bool floatingObjects;
  final String dimensionalDistortion;
  final String portalBehavior;
  final String notes;
  const EnvironmentPhysicsProfile({
    required this.environmentId,
    required this.gravityMultiplier,
    required this.floatingObjects,
    required this.dimensionalDistortion,
    required this.portalBehavior,
    required this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['environment_id'] = Variable<String>(environmentId);
    map['gravity_multiplier'] = Variable<double>(gravityMultiplier);
    map['floating_objects'] = Variable<bool>(floatingObjects);
    map['dimensional_distortion'] = Variable<String>(dimensionalDistortion);
    map['portal_behavior'] = Variable<String>(portalBehavior);
    map['notes'] = Variable<String>(notes);
    return map;
  }

  EnvironmentPhysicsProfilesCompanion toCompanion(bool nullToAbsent) {
    return EnvironmentPhysicsProfilesCompanion(
      environmentId: Value(environmentId),
      gravityMultiplier: Value(gravityMultiplier),
      floatingObjects: Value(floatingObjects),
      dimensionalDistortion: Value(dimensionalDistortion),
      portalBehavior: Value(portalBehavior),
      notes: Value(notes),
    );
  }

  factory EnvironmentPhysicsProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EnvironmentPhysicsProfile(
      environmentId: serializer.fromJson<String>(json['environmentId']),
      gravityMultiplier: serializer.fromJson<double>(json['gravityMultiplier']),
      floatingObjects: serializer.fromJson<bool>(json['floatingObjects']),
      dimensionalDistortion: serializer.fromJson<String>(
        json['dimensionalDistortion'],
      ),
      portalBehavior: serializer.fromJson<String>(json['portalBehavior']),
      notes: serializer.fromJson<String>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'environmentId': serializer.toJson<String>(environmentId),
      'gravityMultiplier': serializer.toJson<double>(gravityMultiplier),
      'floatingObjects': serializer.toJson<bool>(floatingObjects),
      'dimensionalDistortion': serializer.toJson<String>(dimensionalDistortion),
      'portalBehavior': serializer.toJson<String>(portalBehavior),
      'notes': serializer.toJson<String>(notes),
    };
  }

  EnvironmentPhysicsProfile copyWith({
    String? environmentId,
    double? gravityMultiplier,
    bool? floatingObjects,
    String? dimensionalDistortion,
    String? portalBehavior,
    String? notes,
  }) => EnvironmentPhysicsProfile(
    environmentId: environmentId ?? this.environmentId,
    gravityMultiplier: gravityMultiplier ?? this.gravityMultiplier,
    floatingObjects: floatingObjects ?? this.floatingObjects,
    dimensionalDistortion: dimensionalDistortion ?? this.dimensionalDistortion,
    portalBehavior: portalBehavior ?? this.portalBehavior,
    notes: notes ?? this.notes,
  );
  EnvironmentPhysicsProfile copyWithCompanion(
    EnvironmentPhysicsProfilesCompanion data,
  ) {
    return EnvironmentPhysicsProfile(
      environmentId: data.environmentId.present
          ? data.environmentId.value
          : this.environmentId,
      gravityMultiplier: data.gravityMultiplier.present
          ? data.gravityMultiplier.value
          : this.gravityMultiplier,
      floatingObjects: data.floatingObjects.present
          ? data.floatingObjects.value
          : this.floatingObjects,
      dimensionalDistortion: data.dimensionalDistortion.present
          ? data.dimensionalDistortion.value
          : this.dimensionalDistortion,
      portalBehavior: data.portalBehavior.present
          ? data.portalBehavior.value
          : this.portalBehavior,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EnvironmentPhysicsProfile(')
          ..write('environmentId: $environmentId, ')
          ..write('gravityMultiplier: $gravityMultiplier, ')
          ..write('floatingObjects: $floatingObjects, ')
          ..write('dimensionalDistortion: $dimensionalDistortion, ')
          ..write('portalBehavior: $portalBehavior, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    environmentId,
    gravityMultiplier,
    floatingObjects,
    dimensionalDistortion,
    portalBehavior,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EnvironmentPhysicsProfile &&
          other.environmentId == this.environmentId &&
          other.gravityMultiplier == this.gravityMultiplier &&
          other.floatingObjects == this.floatingObjects &&
          other.dimensionalDistortion == this.dimensionalDistortion &&
          other.portalBehavior == this.portalBehavior &&
          other.notes == this.notes);
}

class EnvironmentPhysicsProfilesCompanion
    extends UpdateCompanion<EnvironmentPhysicsProfile> {
  final Value<String> environmentId;
  final Value<double> gravityMultiplier;
  final Value<bool> floatingObjects;
  final Value<String> dimensionalDistortion;
  final Value<String> portalBehavior;
  final Value<String> notes;
  final Value<int> rowid;
  const EnvironmentPhysicsProfilesCompanion({
    this.environmentId = const Value.absent(),
    this.gravityMultiplier = const Value.absent(),
    this.floatingObjects = const Value.absent(),
    this.dimensionalDistortion = const Value.absent(),
    this.portalBehavior = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EnvironmentPhysicsProfilesCompanion.insert({
    required String environmentId,
    this.gravityMultiplier = const Value.absent(),
    this.floatingObjects = const Value.absent(),
    this.dimensionalDistortion = const Value.absent(),
    this.portalBehavior = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : environmentId = Value(environmentId);
  static Insertable<EnvironmentPhysicsProfile> custom({
    Expression<String>? environmentId,
    Expression<double>? gravityMultiplier,
    Expression<bool>? floatingObjects,
    Expression<String>? dimensionalDistortion,
    Expression<String>? portalBehavior,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (environmentId != null) 'environment_id': environmentId,
      if (gravityMultiplier != null) 'gravity_multiplier': gravityMultiplier,
      if (floatingObjects != null) 'floating_objects': floatingObjects,
      if (dimensionalDistortion != null)
        'dimensional_distortion': dimensionalDistortion,
      if (portalBehavior != null) 'portal_behavior': portalBehavior,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EnvironmentPhysicsProfilesCompanion copyWith({
    Value<String>? environmentId,
    Value<double>? gravityMultiplier,
    Value<bool>? floatingObjects,
    Value<String>? dimensionalDistortion,
    Value<String>? portalBehavior,
    Value<String>? notes,
    Value<int>? rowid,
  }) {
    return EnvironmentPhysicsProfilesCompanion(
      environmentId: environmentId ?? this.environmentId,
      gravityMultiplier: gravityMultiplier ?? this.gravityMultiplier,
      floatingObjects: floatingObjects ?? this.floatingObjects,
      dimensionalDistortion:
          dimensionalDistortion ?? this.dimensionalDistortion,
      portalBehavior: portalBehavior ?? this.portalBehavior,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (environmentId.present) {
      map['environment_id'] = Variable<String>(environmentId.value);
    }
    if (gravityMultiplier.present) {
      map['gravity_multiplier'] = Variable<double>(gravityMultiplier.value);
    }
    if (floatingObjects.present) {
      map['floating_objects'] = Variable<bool>(floatingObjects.value);
    }
    if (dimensionalDistortion.present) {
      map['dimensional_distortion'] = Variable<String>(
        dimensionalDistortion.value,
      );
    }
    if (portalBehavior.present) {
      map['portal_behavior'] = Variable<String>(portalBehavior.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnvironmentPhysicsProfilesCompanion(')
          ..write('environmentId: $environmentId, ')
          ..write('gravityMultiplier: $gravityMultiplier, ')
          ..write('floatingObjects: $floatingObjects, ')
          ..write('dimensionalDistortion: $dimensionalDistortion, ')
          ..write('portalBehavior: $portalBehavior, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EnvironmentReferencesTable extends EnvironmentReferences
    with TableInfo<$EnvironmentReferencesTable, EnvironmentReference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EnvironmentReferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _environmentIdMeta = const VerificationMeta(
    'environmentId',
  );
  @override
  late final GeneratedColumn<String> environmentId = GeneratedColumn<String>(
    'environment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceTypeMeta = const VerificationMeta(
    'referenceType',
  );
  @override
  late final GeneratedColumn<String> referenceType = GeneratedColumn<String>(
    'reference_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _primaryReferenceMeta = const VerificationMeta(
    'primaryReference',
  );
  @override
  late final GeneratedColumn<bool> primaryReference = GeneratedColumn<bool>(
    'primary_reference',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("primary_reference" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    environmentId,
    referenceType,
    filePath,
    priority,
    primaryReference,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'environment_references';
  @override
  VerificationContext validateIntegrity(
    Insertable<EnvironmentReference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('environment_id')) {
      context.handle(
        _environmentIdMeta,
        environmentId.isAcceptableOrUnknown(
          data['environment_id']!,
          _environmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_environmentIdMeta);
    }
    if (data.containsKey('reference_type')) {
      context.handle(
        _referenceTypeMeta,
        referenceType.isAcceptableOrUnknown(
          data['reference_type']!,
          _referenceTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_referenceTypeMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('primary_reference')) {
      context.handle(
        _primaryReferenceMeta,
        primaryReference.isAcceptableOrUnknown(
          data['primary_reference']!,
          _primaryReferenceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EnvironmentReference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EnvironmentReference(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      environmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}environment_id'],
      )!,
      referenceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_type'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      primaryReference: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}primary_reference'],
      )!,
    );
  }

  @override
  $EnvironmentReferencesTable createAlias(String alias) {
    return $EnvironmentReferencesTable(attachedDatabase, alias);
  }
}

class EnvironmentReference extends DataClass
    implements Insertable<EnvironmentReference> {
  final String id;
  final String environmentId;
  final String referenceType;
  final String filePath;
  final int priority;
  final bool primaryReference;
  const EnvironmentReference({
    required this.id,
    required this.environmentId,
    required this.referenceType,
    required this.filePath,
    required this.priority,
    required this.primaryReference,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['environment_id'] = Variable<String>(environmentId);
    map['reference_type'] = Variable<String>(referenceType);
    map['file_path'] = Variable<String>(filePath);
    map['priority'] = Variable<int>(priority);
    map['primary_reference'] = Variable<bool>(primaryReference);
    return map;
  }

  EnvironmentReferencesCompanion toCompanion(bool nullToAbsent) {
    return EnvironmentReferencesCompanion(
      id: Value(id),
      environmentId: Value(environmentId),
      referenceType: Value(referenceType),
      filePath: Value(filePath),
      priority: Value(priority),
      primaryReference: Value(primaryReference),
    );
  }

  factory EnvironmentReference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EnvironmentReference(
      id: serializer.fromJson<String>(json['id']),
      environmentId: serializer.fromJson<String>(json['environmentId']),
      referenceType: serializer.fromJson<String>(json['referenceType']),
      filePath: serializer.fromJson<String>(json['filePath']),
      priority: serializer.fromJson<int>(json['priority']),
      primaryReference: serializer.fromJson<bool>(json['primaryReference']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'environmentId': serializer.toJson<String>(environmentId),
      'referenceType': serializer.toJson<String>(referenceType),
      'filePath': serializer.toJson<String>(filePath),
      'priority': serializer.toJson<int>(priority),
      'primaryReference': serializer.toJson<bool>(primaryReference),
    };
  }

  EnvironmentReference copyWith({
    String? id,
    String? environmentId,
    String? referenceType,
    String? filePath,
    int? priority,
    bool? primaryReference,
  }) => EnvironmentReference(
    id: id ?? this.id,
    environmentId: environmentId ?? this.environmentId,
    referenceType: referenceType ?? this.referenceType,
    filePath: filePath ?? this.filePath,
    priority: priority ?? this.priority,
    primaryReference: primaryReference ?? this.primaryReference,
  );
  EnvironmentReference copyWithCompanion(EnvironmentReferencesCompanion data) {
    return EnvironmentReference(
      id: data.id.present ? data.id.value : this.id,
      environmentId: data.environmentId.present
          ? data.environmentId.value
          : this.environmentId,
      referenceType: data.referenceType.present
          ? data.referenceType.value
          : this.referenceType,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      priority: data.priority.present ? data.priority.value : this.priority,
      primaryReference: data.primaryReference.present
          ? data.primaryReference.value
          : this.primaryReference,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EnvironmentReference(')
          ..write('id: $id, ')
          ..write('environmentId: $environmentId, ')
          ..write('referenceType: $referenceType, ')
          ..write('filePath: $filePath, ')
          ..write('priority: $priority, ')
          ..write('primaryReference: $primaryReference')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    environmentId,
    referenceType,
    filePath,
    priority,
    primaryReference,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EnvironmentReference &&
          other.id == this.id &&
          other.environmentId == this.environmentId &&
          other.referenceType == this.referenceType &&
          other.filePath == this.filePath &&
          other.priority == this.priority &&
          other.primaryReference == this.primaryReference);
}

class EnvironmentReferencesCompanion
    extends UpdateCompanion<EnvironmentReference> {
  final Value<String> id;
  final Value<String> environmentId;
  final Value<String> referenceType;
  final Value<String> filePath;
  final Value<int> priority;
  final Value<bool> primaryReference;
  final Value<int> rowid;
  const EnvironmentReferencesCompanion({
    this.id = const Value.absent(),
    this.environmentId = const Value.absent(),
    this.referenceType = const Value.absent(),
    this.filePath = const Value.absent(),
    this.priority = const Value.absent(),
    this.primaryReference = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EnvironmentReferencesCompanion.insert({
    required String id,
    required String environmentId,
    required String referenceType,
    required String filePath,
    this.priority = const Value.absent(),
    this.primaryReference = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       environmentId = Value(environmentId),
       referenceType = Value(referenceType),
       filePath = Value(filePath);
  static Insertable<EnvironmentReference> custom({
    Expression<String>? id,
    Expression<String>? environmentId,
    Expression<String>? referenceType,
    Expression<String>? filePath,
    Expression<int>? priority,
    Expression<bool>? primaryReference,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (environmentId != null) 'environment_id': environmentId,
      if (referenceType != null) 'reference_type': referenceType,
      if (filePath != null) 'file_path': filePath,
      if (priority != null) 'priority': priority,
      if (primaryReference != null) 'primary_reference': primaryReference,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EnvironmentReferencesCompanion copyWith({
    Value<String>? id,
    Value<String>? environmentId,
    Value<String>? referenceType,
    Value<String>? filePath,
    Value<int>? priority,
    Value<bool>? primaryReference,
    Value<int>? rowid,
  }) {
    return EnvironmentReferencesCompanion(
      id: id ?? this.id,
      environmentId: environmentId ?? this.environmentId,
      referenceType: referenceType ?? this.referenceType,
      filePath: filePath ?? this.filePath,
      priority: priority ?? this.priority,
      primaryReference: primaryReference ?? this.primaryReference,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (environmentId.present) {
      map['environment_id'] = Variable<String>(environmentId.value);
    }
    if (referenceType.present) {
      map['reference_type'] = Variable<String>(referenceType.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (primaryReference.present) {
      map['primary_reference'] = Variable<bool>(primaryReference.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnvironmentReferencesCompanion(')
          ..write('id: $id, ')
          ..write('environmentId: $environmentId, ')
          ..write('referenceType: $referenceType, ')
          ..write('filePath: $filePath, ')
          ..write('priority: $priority, ')
          ..write('primaryReference: $primaryReference, ')
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
  late final $AssetsTable assets = $AssetsTable(this);
  late final $AssetTagsTable assetTags = $AssetTagsTable(this);
  late final $CharactersTable characters = $CharactersTable(this);
  late final $CharacterIdentityProfilesTable characterIdentityProfiles =
      $CharacterIdentityProfilesTable(this);
  late final $CharacterReferencesTable characterReferences =
      $CharacterReferencesTable(this);
  late final $CharacterModesTable characterModes = $CharacterModesTable(this);
  late final $CharacterLoadoutEntriesTable characterLoadoutEntries =
      $CharacterLoadoutEntriesTable(this);
  late final $CharacterModeIdentityOverridesTable
  characterModeIdentityOverrides = $CharacterModeIdentityOverridesTable(this);
  late final $CharacterModeReferencesTable characterModeReferences =
      $CharacterModeReferencesTable(this);
  late final $AssetRelationsTable assetRelations = $AssetRelationsTable(this);
  late final $WardrobesTable wardrobes = $WardrobesTable(this);
  late final $WardrobeComponentsTable wardrobeComponents =
      $WardrobeComponentsTable(this);
  late final $WardrobeColorsTable wardrobeColors = $WardrobeColorsTable(this);
  late final $WardrobeVariantsTable wardrobeVariants = $WardrobeVariantsTable(
    this,
  );
  late final $WardrobeReferencesTable wardrobeReferences =
      $WardrobeReferencesTable(this);
  late final $WeaponsTable weapons = $WeaponsTable(this);
  late final $WeaponComponentsTable weaponComponents = $WeaponComponentsTable(
    this,
  );
  late final $WeaponMeasurementsTable weaponMeasurements =
      $WeaponMeasurementsTable(this);
  late final $WeaponColorsTable weaponColors = $WeaponColorsTable(this);
  late final $WeaponEnergyProfilesTable weaponEnergyProfiles =
      $WeaponEnergyProfilesTable(this);
  late final $WeaponVariantsTable weaponVariants = $WeaponVariantsTable(this);
  late final $WeaponReferencesTable weaponReferences = $WeaponReferencesTable(
    this,
  );
  late final $WeaponPreservationProfilesTable weaponPreservationProfiles =
      $WeaponPreservationProfilesTable(this);
  late final $EnvironmentsTable environments = $EnvironmentsTable(this);
  late final $EnvironmentZonesTable environmentZones = $EnvironmentZonesTable(
    this,
  );
  late final $EnvironmentArchitecturesTable environmentArchitectures =
      $EnvironmentArchitecturesTable(this);
  late final $EnvironmentWeatherProfilesTable environmentWeatherProfiles =
      $EnvironmentWeatherProfilesTable(this);
  late final $EnvironmentLightingProfilesTable environmentLightingProfiles =
      $EnvironmentLightingProfilesTable(this);
  late final $EnvironmentColorsTable environmentColors =
      $EnvironmentColorsTable(this);
  late final $EnvironmentPropsTable environmentProps = $EnvironmentPropsTable(
    this,
  );
  late final $EnvironmentContinuityStatesTable environmentContinuityStates =
      $EnvironmentContinuityStatesTable(this);
  late final $EnvironmentPhysicsProfilesTable environmentPhysicsProfiles =
      $EnvironmentPhysicsProfilesTable(this);
  late final $EnvironmentReferencesTable environmentReferences =
      $EnvironmentReferencesTable(this);
  late final AssetDao assetDao = AssetDao(this as ProjectDatabase);
  late final CharacterDao characterDao = CharacterDao(this as ProjectDatabase);
  late final CharacterModeDao characterModeDao = CharacterModeDao(
    this as ProjectDatabase,
  );
  late final RelationDao relationDao = RelationDao(this as ProjectDatabase);
  late final WardrobeDao wardrobeDao = WardrobeDao(this as ProjectDatabase);
  late final WeaponDao weaponDao = WeaponDao(this as ProjectDatabase);
  late final EnvironmentDao environmentDao = EnvironmentDao(
    this as ProjectDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    projectMetadata,
    assets,
    assetTags,
    characters,
    characterIdentityProfiles,
    characterReferences,
    characterModes,
    characterLoadoutEntries,
    characterModeIdentityOverrides,
    characterModeReferences,
    assetRelations,
    wardrobes,
    wardrobeComponents,
    wardrobeColors,
    wardrobeVariants,
    wardrobeReferences,
    weapons,
    weaponComponents,
    weaponMeasurements,
    weaponColors,
    weaponEnergyProfiles,
    weaponVariants,
    weaponReferences,
    weaponPreservationProfiles,
    environments,
    environmentZones,
    environmentArchitectures,
    environmentWeatherProfiles,
    environmentLightingProfiles,
    environmentColors,
    environmentProps,
    environmentContinuityStates,
    environmentPhysicsProfiles,
    environmentReferences,
  ];
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
typedef $$AssetsTableCreateCompanionBuilder =
    AssetsCompanion Function({
      required String id,
      required String projectId,
      required String name,
      Value<String> description,
      required String type,
      Value<String> version,
      Value<String?> thumbnailPath,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AssetsTableUpdateCompanionBuilder =
    AssetsCompanion Function({
      Value<String> id,
      Value<String> projectId,
      Value<String> name,
      Value<String> description,
      Value<String> type,
      Value<String> version,
      Value<String?> thumbnailPath,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AssetsTableFilterComposer
    extends Composer<_$ProjectDatabase, $AssetsTable> {
  $$AssetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AssetsTableOrderingComposer
    extends Composer<_$ProjectDatabase, $AssetsTable> {
  $$AssetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AssetsTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $AssetsTable> {
  $$AssetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AssetsTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $AssetsTable,
          Asset,
          $$AssetsTableFilterComposer,
          $$AssetsTableOrderingComposer,
          $$AssetsTableAnnotationComposer,
          $$AssetsTableCreateCompanionBuilder,
          $$AssetsTableUpdateCompanionBuilder,
          (Asset, BaseReferences<_$ProjectDatabase, $AssetsTable, Asset>),
          Asset,
          PrefetchHooks Function()
        > {
  $$AssetsTableTableManager(_$ProjectDatabase db, $AssetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> version = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetsCompanion(
                id: id,
                projectId: projectId,
                name: name,
                description: description,
                type: type,
                version: version,
                thumbnailPath: thumbnailPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String projectId,
                required String name,
                Value<String> description = const Value.absent(),
                required String type,
                Value<String> version = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AssetsCompanion.insert(
                id: id,
                projectId: projectId,
                name: name,
                description: description,
                type: type,
                version: version,
                thumbnailPath: thumbnailPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AssetsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $AssetsTable,
      Asset,
      $$AssetsTableFilterComposer,
      $$AssetsTableOrderingComposer,
      $$AssetsTableAnnotationComposer,
      $$AssetsTableCreateCompanionBuilder,
      $$AssetsTableUpdateCompanionBuilder,
      (Asset, BaseReferences<_$ProjectDatabase, $AssetsTable, Asset>),
      Asset,
      PrefetchHooks Function()
    >;
typedef $$AssetTagsTableCreateCompanionBuilder =
    AssetTagsCompanion Function({
      Value<int> id,
      required String assetId,
      required String tag,
    });
typedef $$AssetTagsTableUpdateCompanionBuilder =
    AssetTagsCompanion Function({
      Value<int> id,
      Value<String> assetId,
      Value<String> tag,
    });

class $$AssetTagsTableFilterComposer
    extends Composer<_$ProjectDatabase, $AssetTagsTable> {
  $$AssetTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AssetTagsTableOrderingComposer
    extends Composer<_$ProjectDatabase, $AssetTagsTable> {
  $$AssetTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AssetTagsTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $AssetTagsTable> {
  $$AssetTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get assetId =>
      $composableBuilder(column: $table.assetId, builder: (column) => column);

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);
}

class $$AssetTagsTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $AssetTagsTable,
          AssetTag,
          $$AssetTagsTableFilterComposer,
          $$AssetTagsTableOrderingComposer,
          $$AssetTagsTableAnnotationComposer,
          $$AssetTagsTableCreateCompanionBuilder,
          $$AssetTagsTableUpdateCompanionBuilder,
          (
            AssetTag,
            BaseReferences<_$ProjectDatabase, $AssetTagsTable, AssetTag>,
          ),
          AssetTag,
          PrefetchHooks Function()
        > {
  $$AssetTagsTableTableManager(_$ProjectDatabase db, $AssetTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> assetId = const Value.absent(),
                Value<String> tag = const Value.absent(),
              }) => AssetTagsCompanion(id: id, assetId: assetId, tag: tag),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String assetId,
                required String tag,
              }) =>
                  AssetTagsCompanion.insert(id: id, assetId: assetId, tag: tag),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AssetTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $AssetTagsTable,
      AssetTag,
      $$AssetTagsTableFilterComposer,
      $$AssetTagsTableOrderingComposer,
      $$AssetTagsTableAnnotationComposer,
      $$AssetTagsTableCreateCompanionBuilder,
      $$AssetTagsTableUpdateCompanionBuilder,
      (AssetTag, BaseReferences<_$ProjectDatabase, $AssetTagsTable, AssetTag>),
      AssetTag,
      PrefetchHooks Function()
    >;
typedef $$CharactersTableCreateCompanionBuilder =
    CharactersCompanion Function({
      required String assetId,
      required String projectId,
      required String displayName,
      Value<String> alias,
      Value<String> biography,
      Value<String> personality,
      Value<String> gender,
      Value<int?> age,
      Value<double?> heightCm,
      Value<String> hair,
      Value<String> eyes,
      Value<String> skin,
      Value<int> rowid,
    });
typedef $$CharactersTableUpdateCompanionBuilder =
    CharactersCompanion Function({
      Value<String> assetId,
      Value<String> projectId,
      Value<String> displayName,
      Value<String> alias,
      Value<String> biography,
      Value<String> personality,
      Value<String> gender,
      Value<int?> age,
      Value<double?> heightCm,
      Value<String> hair,
      Value<String> eyes,
      Value<String> skin,
      Value<int> rowid,
    });

class $$CharactersTableFilterComposer
    extends Composer<_$ProjectDatabase, $CharactersTable> {
  $$CharactersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alias => $composableBuilder(
    column: $table.alias,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get biography => $composableBuilder(
    column: $table.biography,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personality => $composableBuilder(
    column: $table.personality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get age => $composableBuilder(
    column: $table.age,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hair => $composableBuilder(
    column: $table.hair,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eyes => $composableBuilder(
    column: $table.eyes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get skin => $composableBuilder(
    column: $table.skin,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CharactersTableOrderingComposer
    extends Composer<_$ProjectDatabase, $CharactersTable> {
  $$CharactersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alias => $composableBuilder(
    column: $table.alias,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get biography => $composableBuilder(
    column: $table.biography,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personality => $composableBuilder(
    column: $table.personality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get age => $composableBuilder(
    column: $table.age,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hair => $composableBuilder(
    column: $table.hair,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eyes => $composableBuilder(
    column: $table.eyes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skin => $composableBuilder(
    column: $table.skin,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CharactersTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $CharactersTable> {
  $$CharactersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get assetId =>
      $composableBuilder(column: $table.assetId, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get alias =>
      $composableBuilder(column: $table.alias, builder: (column) => column);

  GeneratedColumn<String> get biography =>
      $composableBuilder(column: $table.biography, builder: (column) => column);

  GeneratedColumn<String> get personality => $composableBuilder(
    column: $table.personality,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<int> get age =>
      $composableBuilder(column: $table.age, builder: (column) => column);

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<String> get hair =>
      $composableBuilder(column: $table.hair, builder: (column) => column);

  GeneratedColumn<String> get eyes =>
      $composableBuilder(column: $table.eyes, builder: (column) => column);

  GeneratedColumn<String> get skin =>
      $composableBuilder(column: $table.skin, builder: (column) => column);
}

class $$CharactersTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $CharactersTable,
          Character,
          $$CharactersTableFilterComposer,
          $$CharactersTableOrderingComposer,
          $$CharactersTableAnnotationComposer,
          $$CharactersTableCreateCompanionBuilder,
          $$CharactersTableUpdateCompanionBuilder,
          (
            Character,
            BaseReferences<_$ProjectDatabase, $CharactersTable, Character>,
          ),
          Character,
          PrefetchHooks Function()
        > {
  $$CharactersTableTableManager(_$ProjectDatabase db, $CharactersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharactersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CharactersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CharactersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> assetId = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> alias = const Value.absent(),
                Value<String> biography = const Value.absent(),
                Value<String> personality = const Value.absent(),
                Value<String> gender = const Value.absent(),
                Value<int?> age = const Value.absent(),
                Value<double?> heightCm = const Value.absent(),
                Value<String> hair = const Value.absent(),
                Value<String> eyes = const Value.absent(),
                Value<String> skin = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharactersCompanion(
                assetId: assetId,
                projectId: projectId,
                displayName: displayName,
                alias: alias,
                biography: biography,
                personality: personality,
                gender: gender,
                age: age,
                heightCm: heightCm,
                hair: hair,
                eyes: eyes,
                skin: skin,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String assetId,
                required String projectId,
                required String displayName,
                Value<String> alias = const Value.absent(),
                Value<String> biography = const Value.absent(),
                Value<String> personality = const Value.absent(),
                Value<String> gender = const Value.absent(),
                Value<int?> age = const Value.absent(),
                Value<double?> heightCm = const Value.absent(),
                Value<String> hair = const Value.absent(),
                Value<String> eyes = const Value.absent(),
                Value<String> skin = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharactersCompanion.insert(
                assetId: assetId,
                projectId: projectId,
                displayName: displayName,
                alias: alias,
                biography: biography,
                personality: personality,
                gender: gender,
                age: age,
                heightCm: heightCm,
                hair: hair,
                eyes: eyes,
                skin: skin,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CharactersTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $CharactersTable,
      Character,
      $$CharactersTableFilterComposer,
      $$CharactersTableOrderingComposer,
      $$CharactersTableAnnotationComposer,
      $$CharactersTableCreateCompanionBuilder,
      $$CharactersTableUpdateCompanionBuilder,
      (
        Character,
        BaseReferences<_$ProjectDatabase, $CharactersTable, Character>,
      ),
      Character,
      PrefetchHooks Function()
    >;
typedef $$CharacterIdentityProfilesTableCreateCompanionBuilder =
    CharacterIdentityProfilesCompanion Function({
      required String characterId,
      Value<bool> faceLock,
      Value<bool> hairLock,
      Value<bool> bodyLock,
      Value<bool> colorLock,
      Value<bool> outfitLock,
      Value<bool> weaponLock,
      Value<int> rowid,
    });
typedef $$CharacterIdentityProfilesTableUpdateCompanionBuilder =
    CharacterIdentityProfilesCompanion Function({
      Value<String> characterId,
      Value<bool> faceLock,
      Value<bool> hairLock,
      Value<bool> bodyLock,
      Value<bool> colorLock,
      Value<bool> outfitLock,
      Value<bool> weaponLock,
      Value<int> rowid,
    });

class $$CharacterIdentityProfilesTableFilterComposer
    extends Composer<_$ProjectDatabase, $CharacterIdentityProfilesTable> {
  $$CharacterIdentityProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get faceLock => $composableBuilder(
    column: $table.faceLock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hairLock => $composableBuilder(
    column: $table.hairLock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get bodyLock => $composableBuilder(
    column: $table.bodyLock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get colorLock => $composableBuilder(
    column: $table.colorLock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get outfitLock => $composableBuilder(
    column: $table.outfitLock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get weaponLock => $composableBuilder(
    column: $table.weaponLock,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CharacterIdentityProfilesTableOrderingComposer
    extends Composer<_$ProjectDatabase, $CharacterIdentityProfilesTable> {
  $$CharacterIdentityProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get faceLock => $composableBuilder(
    column: $table.faceLock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hairLock => $composableBuilder(
    column: $table.hairLock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get bodyLock => $composableBuilder(
    column: $table.bodyLock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get colorLock => $composableBuilder(
    column: $table.colorLock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get outfitLock => $composableBuilder(
    column: $table.outfitLock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get weaponLock => $composableBuilder(
    column: $table.weaponLock,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CharacterIdentityProfilesTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $CharacterIdentityProfilesTable> {
  $$CharacterIdentityProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get faceLock =>
      $composableBuilder(column: $table.faceLock, builder: (column) => column);

  GeneratedColumn<bool> get hairLock =>
      $composableBuilder(column: $table.hairLock, builder: (column) => column);

  GeneratedColumn<bool> get bodyLock =>
      $composableBuilder(column: $table.bodyLock, builder: (column) => column);

  GeneratedColumn<bool> get colorLock =>
      $composableBuilder(column: $table.colorLock, builder: (column) => column);

  GeneratedColumn<bool> get outfitLock => $composableBuilder(
    column: $table.outfitLock,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get weaponLock => $composableBuilder(
    column: $table.weaponLock,
    builder: (column) => column,
  );
}

class $$CharacterIdentityProfilesTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $CharacterIdentityProfilesTable,
          CharacterIdentityProfile,
          $$CharacterIdentityProfilesTableFilterComposer,
          $$CharacterIdentityProfilesTableOrderingComposer,
          $$CharacterIdentityProfilesTableAnnotationComposer,
          $$CharacterIdentityProfilesTableCreateCompanionBuilder,
          $$CharacterIdentityProfilesTableUpdateCompanionBuilder,
          (
            CharacterIdentityProfile,
            BaseReferences<
              _$ProjectDatabase,
              $CharacterIdentityProfilesTable,
              CharacterIdentityProfile
            >,
          ),
          CharacterIdentityProfile,
          PrefetchHooks Function()
        > {
  $$CharacterIdentityProfilesTableTableManager(
    _$ProjectDatabase db,
    $CharacterIdentityProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharacterIdentityProfilesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CharacterIdentityProfilesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CharacterIdentityProfilesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> characterId = const Value.absent(),
                Value<bool> faceLock = const Value.absent(),
                Value<bool> hairLock = const Value.absent(),
                Value<bool> bodyLock = const Value.absent(),
                Value<bool> colorLock = const Value.absent(),
                Value<bool> outfitLock = const Value.absent(),
                Value<bool> weaponLock = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharacterIdentityProfilesCompanion(
                characterId: characterId,
                faceLock: faceLock,
                hairLock: hairLock,
                bodyLock: bodyLock,
                colorLock: colorLock,
                outfitLock: outfitLock,
                weaponLock: weaponLock,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String characterId,
                Value<bool> faceLock = const Value.absent(),
                Value<bool> hairLock = const Value.absent(),
                Value<bool> bodyLock = const Value.absent(),
                Value<bool> colorLock = const Value.absent(),
                Value<bool> outfitLock = const Value.absent(),
                Value<bool> weaponLock = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharacterIdentityProfilesCompanion.insert(
                characterId: characterId,
                faceLock: faceLock,
                hairLock: hairLock,
                bodyLock: bodyLock,
                colorLock: colorLock,
                outfitLock: outfitLock,
                weaponLock: weaponLock,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CharacterIdentityProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $CharacterIdentityProfilesTable,
      CharacterIdentityProfile,
      $$CharacterIdentityProfilesTableFilterComposer,
      $$CharacterIdentityProfilesTableOrderingComposer,
      $$CharacterIdentityProfilesTableAnnotationComposer,
      $$CharacterIdentityProfilesTableCreateCompanionBuilder,
      $$CharacterIdentityProfilesTableUpdateCompanionBuilder,
      (
        CharacterIdentityProfile,
        BaseReferences<
          _$ProjectDatabase,
          $CharacterIdentityProfilesTable,
          CharacterIdentityProfile
        >,
      ),
      CharacterIdentityProfile,
      PrefetchHooks Function()
    >;
typedef $$CharacterReferencesTableCreateCompanionBuilder =
    CharacterReferencesCompanion Function({
      required String id,
      required String characterId,
      required String type,
      required String filePath,
      Value<int> priority,
      Value<bool> primaryReference,
      Value<int> rowid,
    });
typedef $$CharacterReferencesTableUpdateCompanionBuilder =
    CharacterReferencesCompanion Function({
      Value<String> id,
      Value<String> characterId,
      Value<String> type,
      Value<String> filePath,
      Value<int> priority,
      Value<bool> primaryReference,
      Value<int> rowid,
    });

class $$CharacterReferencesTableFilterComposer
    extends Composer<_$ProjectDatabase, $CharacterReferencesTable> {
  $$CharacterReferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get primaryReference => $composableBuilder(
    column: $table.primaryReference,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CharacterReferencesTableOrderingComposer
    extends Composer<_$ProjectDatabase, $CharacterReferencesTable> {
  $$CharacterReferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get primaryReference => $composableBuilder(
    column: $table.primaryReference,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CharacterReferencesTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $CharacterReferencesTable> {
  $$CharacterReferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<bool> get primaryReference => $composableBuilder(
    column: $table.primaryReference,
    builder: (column) => column,
  );
}

class $$CharacterReferencesTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $CharacterReferencesTable,
          CharacterReference,
          $$CharacterReferencesTableFilterComposer,
          $$CharacterReferencesTableOrderingComposer,
          $$CharacterReferencesTableAnnotationComposer,
          $$CharacterReferencesTableCreateCompanionBuilder,
          $$CharacterReferencesTableUpdateCompanionBuilder,
          (
            CharacterReference,
            BaseReferences<
              _$ProjectDatabase,
              $CharacterReferencesTable,
              CharacterReference
            >,
          ),
          CharacterReference,
          PrefetchHooks Function()
        > {
  $$CharacterReferencesTableTableManager(
    _$ProjectDatabase db,
    $CharacterReferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharacterReferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CharacterReferencesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CharacterReferencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> characterId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<bool> primaryReference = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharacterReferencesCompanion(
                id: id,
                characterId: characterId,
                type: type,
                filePath: filePath,
                priority: priority,
                primaryReference: primaryReference,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String characterId,
                required String type,
                required String filePath,
                Value<int> priority = const Value.absent(),
                Value<bool> primaryReference = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharacterReferencesCompanion.insert(
                id: id,
                characterId: characterId,
                type: type,
                filePath: filePath,
                priority: priority,
                primaryReference: primaryReference,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CharacterReferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $CharacterReferencesTable,
      CharacterReference,
      $$CharacterReferencesTableFilterComposer,
      $$CharacterReferencesTableOrderingComposer,
      $$CharacterReferencesTableAnnotationComposer,
      $$CharacterReferencesTableCreateCompanionBuilder,
      $$CharacterReferencesTableUpdateCompanionBuilder,
      (
        CharacterReference,
        BaseReferences<
          _$ProjectDatabase,
          $CharacterReferencesTable,
          CharacterReference
        >,
      ),
      CharacterReference,
      PrefetchHooks Function()
    >;
typedef $$CharacterModesTableCreateCompanionBuilder =
    CharacterModesCompanion Function({
      required String id,
      required String projectId,
      required String characterId,
      required String name,
      Value<String> description,
      Value<bool> isDefault,
      Value<String?> thumbnailPath,
      Value<String?> accentColor,
      Value<String> tagsJson,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CharacterModesTableUpdateCompanionBuilder =
    CharacterModesCompanion Function({
      Value<String> id,
      Value<String> projectId,
      Value<String> characterId,
      Value<String> name,
      Value<String> description,
      Value<bool> isDefault,
      Value<String?> thumbnailPath,
      Value<String?> accentColor,
      Value<String> tagsJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CharacterModesTableFilterComposer
    extends Composer<_$ProjectDatabase, $CharacterModesTable> {
  $$CharacterModesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accentColor => $composableBuilder(
    column: $table.accentColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CharacterModesTableOrderingComposer
    extends Composer<_$ProjectDatabase, $CharacterModesTable> {
  $$CharacterModesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accentColor => $composableBuilder(
    column: $table.accentColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CharacterModesTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $CharacterModesTable> {
  $$CharacterModesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accentColor => $composableBuilder(
    column: $table.accentColor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CharacterModesTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $CharacterModesTable,
          CharacterMode,
          $$CharacterModesTableFilterComposer,
          $$CharacterModesTableOrderingComposer,
          $$CharacterModesTableAnnotationComposer,
          $$CharacterModesTableCreateCompanionBuilder,
          $$CharacterModesTableUpdateCompanionBuilder,
          (
            CharacterMode,
            BaseReferences<
              _$ProjectDatabase,
              $CharacterModesTable,
              CharacterMode
            >,
          ),
          CharacterMode,
          PrefetchHooks Function()
        > {
  $$CharacterModesTableTableManager(
    _$ProjectDatabase db,
    $CharacterModesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharacterModesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CharacterModesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CharacterModesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> characterId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                Value<String?> accentColor = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharacterModesCompanion(
                id: id,
                projectId: projectId,
                characterId: characterId,
                name: name,
                description: description,
                isDefault: isDefault,
                thumbnailPath: thumbnailPath,
                accentColor: accentColor,
                tagsJson: tagsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String projectId,
                required String characterId,
                required String name,
                Value<String> description = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                Value<String?> accentColor = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CharacterModesCompanion.insert(
                id: id,
                projectId: projectId,
                characterId: characterId,
                name: name,
                description: description,
                isDefault: isDefault,
                thumbnailPath: thumbnailPath,
                accentColor: accentColor,
                tagsJson: tagsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CharacterModesTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $CharacterModesTable,
      CharacterMode,
      $$CharacterModesTableFilterComposer,
      $$CharacterModesTableOrderingComposer,
      $$CharacterModesTableAnnotationComposer,
      $$CharacterModesTableCreateCompanionBuilder,
      $$CharacterModesTableUpdateCompanionBuilder,
      (
        CharacterMode,
        BaseReferences<_$ProjectDatabase, $CharacterModesTable, CharacterMode>,
      ),
      CharacterMode,
      PrefetchHooks Function()
    >;
typedef $$CharacterLoadoutEntriesTableCreateCompanionBuilder =
    CharacterLoadoutEntriesCompanion Function({
      required String id,
      required String modeId,
      required String assetId,
      required String slot,
      Value<int> quantity,
      Value<int> sortOrder,
      Value<bool> enabled,
      Value<int> rowid,
    });
typedef $$CharacterLoadoutEntriesTableUpdateCompanionBuilder =
    CharacterLoadoutEntriesCompanion Function({
      Value<String> id,
      Value<String> modeId,
      Value<String> assetId,
      Value<String> slot,
      Value<int> quantity,
      Value<int> sortOrder,
      Value<bool> enabled,
      Value<int> rowid,
    });

class $$CharacterLoadoutEntriesTableFilterComposer
    extends Composer<_$ProjectDatabase, $CharacterLoadoutEntriesTable> {
  $$CharacterLoadoutEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modeId => $composableBuilder(
    column: $table.modeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CharacterLoadoutEntriesTableOrderingComposer
    extends Composer<_$ProjectDatabase, $CharacterLoadoutEntriesTable> {
  $$CharacterLoadoutEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modeId => $composableBuilder(
    column: $table.modeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CharacterLoadoutEntriesTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $CharacterLoadoutEntriesTable> {
  $$CharacterLoadoutEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get modeId =>
      $composableBuilder(column: $table.modeId, builder: (column) => column);

  GeneratedColumn<String> get assetId =>
      $composableBuilder(column: $table.assetId, builder: (column) => column);

  GeneratedColumn<String> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);
}

class $$CharacterLoadoutEntriesTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $CharacterLoadoutEntriesTable,
          CharacterLoadoutEntry,
          $$CharacterLoadoutEntriesTableFilterComposer,
          $$CharacterLoadoutEntriesTableOrderingComposer,
          $$CharacterLoadoutEntriesTableAnnotationComposer,
          $$CharacterLoadoutEntriesTableCreateCompanionBuilder,
          $$CharacterLoadoutEntriesTableUpdateCompanionBuilder,
          (
            CharacterLoadoutEntry,
            BaseReferences<
              _$ProjectDatabase,
              $CharacterLoadoutEntriesTable,
              CharacterLoadoutEntry
            >,
          ),
          CharacterLoadoutEntry,
          PrefetchHooks Function()
        > {
  $$CharacterLoadoutEntriesTableTableManager(
    _$ProjectDatabase db,
    $CharacterLoadoutEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharacterLoadoutEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CharacterLoadoutEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CharacterLoadoutEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> modeId = const Value.absent(),
                Value<String> assetId = const Value.absent(),
                Value<String> slot = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharacterLoadoutEntriesCompanion(
                id: id,
                modeId: modeId,
                assetId: assetId,
                slot: slot,
                quantity: quantity,
                sortOrder: sortOrder,
                enabled: enabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String modeId,
                required String assetId,
                required String slot,
                Value<int> quantity = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharacterLoadoutEntriesCompanion.insert(
                id: id,
                modeId: modeId,
                assetId: assetId,
                slot: slot,
                quantity: quantity,
                sortOrder: sortOrder,
                enabled: enabled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CharacterLoadoutEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $CharacterLoadoutEntriesTable,
      CharacterLoadoutEntry,
      $$CharacterLoadoutEntriesTableFilterComposer,
      $$CharacterLoadoutEntriesTableOrderingComposer,
      $$CharacterLoadoutEntriesTableAnnotationComposer,
      $$CharacterLoadoutEntriesTableCreateCompanionBuilder,
      $$CharacterLoadoutEntriesTableUpdateCompanionBuilder,
      (
        CharacterLoadoutEntry,
        BaseReferences<
          _$ProjectDatabase,
          $CharacterLoadoutEntriesTable,
          CharacterLoadoutEntry
        >,
      ),
      CharacterLoadoutEntry,
      PrefetchHooks Function()
    >;
typedef $$CharacterModeIdentityOverridesTableCreateCompanionBuilder =
    CharacterModeIdentityOverridesCompanion Function({
      required String modeId,
      Value<bool?> faceLock,
      Value<bool?> hairLock,
      Value<bool?> bodyLock,
      Value<bool?> colorLock,
      Value<bool?> outfitLock,
      Value<bool?> weaponLock,
      Value<int> rowid,
    });
typedef $$CharacterModeIdentityOverridesTableUpdateCompanionBuilder =
    CharacterModeIdentityOverridesCompanion Function({
      Value<String> modeId,
      Value<bool?> faceLock,
      Value<bool?> hairLock,
      Value<bool?> bodyLock,
      Value<bool?> colorLock,
      Value<bool?> outfitLock,
      Value<bool?> weaponLock,
      Value<int> rowid,
    });

class $$CharacterModeIdentityOverridesTableFilterComposer
    extends Composer<_$ProjectDatabase, $CharacterModeIdentityOverridesTable> {
  $$CharacterModeIdentityOverridesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get modeId => $composableBuilder(
    column: $table.modeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get faceLock => $composableBuilder(
    column: $table.faceLock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hairLock => $composableBuilder(
    column: $table.hairLock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get bodyLock => $composableBuilder(
    column: $table.bodyLock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get colorLock => $composableBuilder(
    column: $table.colorLock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get outfitLock => $composableBuilder(
    column: $table.outfitLock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get weaponLock => $composableBuilder(
    column: $table.weaponLock,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CharacterModeIdentityOverridesTableOrderingComposer
    extends Composer<_$ProjectDatabase, $CharacterModeIdentityOverridesTable> {
  $$CharacterModeIdentityOverridesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get modeId => $composableBuilder(
    column: $table.modeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get faceLock => $composableBuilder(
    column: $table.faceLock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hairLock => $composableBuilder(
    column: $table.hairLock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get bodyLock => $composableBuilder(
    column: $table.bodyLock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get colorLock => $composableBuilder(
    column: $table.colorLock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get outfitLock => $composableBuilder(
    column: $table.outfitLock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get weaponLock => $composableBuilder(
    column: $table.weaponLock,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CharacterModeIdentityOverridesTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $CharacterModeIdentityOverridesTable> {
  $$CharacterModeIdentityOverridesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get modeId =>
      $composableBuilder(column: $table.modeId, builder: (column) => column);

  GeneratedColumn<bool> get faceLock =>
      $composableBuilder(column: $table.faceLock, builder: (column) => column);

  GeneratedColumn<bool> get hairLock =>
      $composableBuilder(column: $table.hairLock, builder: (column) => column);

  GeneratedColumn<bool> get bodyLock =>
      $composableBuilder(column: $table.bodyLock, builder: (column) => column);

  GeneratedColumn<bool> get colorLock =>
      $composableBuilder(column: $table.colorLock, builder: (column) => column);

  GeneratedColumn<bool> get outfitLock => $composableBuilder(
    column: $table.outfitLock,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get weaponLock => $composableBuilder(
    column: $table.weaponLock,
    builder: (column) => column,
  );
}

class $$CharacterModeIdentityOverridesTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $CharacterModeIdentityOverridesTable,
          CharacterModeIdentityOverride,
          $$CharacterModeIdentityOverridesTableFilterComposer,
          $$CharacterModeIdentityOverridesTableOrderingComposer,
          $$CharacterModeIdentityOverridesTableAnnotationComposer,
          $$CharacterModeIdentityOverridesTableCreateCompanionBuilder,
          $$CharacterModeIdentityOverridesTableUpdateCompanionBuilder,
          (
            CharacterModeIdentityOverride,
            BaseReferences<
              _$ProjectDatabase,
              $CharacterModeIdentityOverridesTable,
              CharacterModeIdentityOverride
            >,
          ),
          CharacterModeIdentityOverride,
          PrefetchHooks Function()
        > {
  $$CharacterModeIdentityOverridesTableTableManager(
    _$ProjectDatabase db,
    $CharacterModeIdentityOverridesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharacterModeIdentityOverridesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CharacterModeIdentityOverridesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CharacterModeIdentityOverridesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> modeId = const Value.absent(),
                Value<bool?> faceLock = const Value.absent(),
                Value<bool?> hairLock = const Value.absent(),
                Value<bool?> bodyLock = const Value.absent(),
                Value<bool?> colorLock = const Value.absent(),
                Value<bool?> outfitLock = const Value.absent(),
                Value<bool?> weaponLock = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharacterModeIdentityOverridesCompanion(
                modeId: modeId,
                faceLock: faceLock,
                hairLock: hairLock,
                bodyLock: bodyLock,
                colorLock: colorLock,
                outfitLock: outfitLock,
                weaponLock: weaponLock,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String modeId,
                Value<bool?> faceLock = const Value.absent(),
                Value<bool?> hairLock = const Value.absent(),
                Value<bool?> bodyLock = const Value.absent(),
                Value<bool?> colorLock = const Value.absent(),
                Value<bool?> outfitLock = const Value.absent(),
                Value<bool?> weaponLock = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharacterModeIdentityOverridesCompanion.insert(
                modeId: modeId,
                faceLock: faceLock,
                hairLock: hairLock,
                bodyLock: bodyLock,
                colorLock: colorLock,
                outfitLock: outfitLock,
                weaponLock: weaponLock,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CharacterModeIdentityOverridesTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $CharacterModeIdentityOverridesTable,
      CharacterModeIdentityOverride,
      $$CharacterModeIdentityOverridesTableFilterComposer,
      $$CharacterModeIdentityOverridesTableOrderingComposer,
      $$CharacterModeIdentityOverridesTableAnnotationComposer,
      $$CharacterModeIdentityOverridesTableCreateCompanionBuilder,
      $$CharacterModeIdentityOverridesTableUpdateCompanionBuilder,
      (
        CharacterModeIdentityOverride,
        BaseReferences<
          _$ProjectDatabase,
          $CharacterModeIdentityOverridesTable,
          CharacterModeIdentityOverride
        >,
      ),
      CharacterModeIdentityOverride,
      PrefetchHooks Function()
    >;
typedef $$CharacterModeReferencesTableCreateCompanionBuilder =
    CharacterModeReferencesCompanion Function({
      required String id,
      required String modeId,
      required String referenceType,
      required String filePath,
      Value<int> priority,
      Value<bool> primaryReference,
      Value<int> rowid,
    });
typedef $$CharacterModeReferencesTableUpdateCompanionBuilder =
    CharacterModeReferencesCompanion Function({
      Value<String> id,
      Value<String> modeId,
      Value<String> referenceType,
      Value<String> filePath,
      Value<int> priority,
      Value<bool> primaryReference,
      Value<int> rowid,
    });

class $$CharacterModeReferencesTableFilterComposer
    extends Composer<_$ProjectDatabase, $CharacterModeReferencesTable> {
  $$CharacterModeReferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modeId => $composableBuilder(
    column: $table.modeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get primaryReference => $composableBuilder(
    column: $table.primaryReference,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CharacterModeReferencesTableOrderingComposer
    extends Composer<_$ProjectDatabase, $CharacterModeReferencesTable> {
  $$CharacterModeReferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modeId => $composableBuilder(
    column: $table.modeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get primaryReference => $composableBuilder(
    column: $table.primaryReference,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CharacterModeReferencesTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $CharacterModeReferencesTable> {
  $$CharacterModeReferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get modeId =>
      $composableBuilder(column: $table.modeId, builder: (column) => column);

  GeneratedColumn<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<bool> get primaryReference => $composableBuilder(
    column: $table.primaryReference,
    builder: (column) => column,
  );
}

class $$CharacterModeReferencesTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $CharacterModeReferencesTable,
          CharacterModeReference,
          $$CharacterModeReferencesTableFilterComposer,
          $$CharacterModeReferencesTableOrderingComposer,
          $$CharacterModeReferencesTableAnnotationComposer,
          $$CharacterModeReferencesTableCreateCompanionBuilder,
          $$CharacterModeReferencesTableUpdateCompanionBuilder,
          (
            CharacterModeReference,
            BaseReferences<
              _$ProjectDatabase,
              $CharacterModeReferencesTable,
              CharacterModeReference
            >,
          ),
          CharacterModeReference,
          PrefetchHooks Function()
        > {
  $$CharacterModeReferencesTableTableManager(
    _$ProjectDatabase db,
    $CharacterModeReferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharacterModeReferencesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CharacterModeReferencesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CharacterModeReferencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> modeId = const Value.absent(),
                Value<String> referenceType = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<bool> primaryReference = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharacterModeReferencesCompanion(
                id: id,
                modeId: modeId,
                referenceType: referenceType,
                filePath: filePath,
                priority: priority,
                primaryReference: primaryReference,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String modeId,
                required String referenceType,
                required String filePath,
                Value<int> priority = const Value.absent(),
                Value<bool> primaryReference = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharacterModeReferencesCompanion.insert(
                id: id,
                modeId: modeId,
                referenceType: referenceType,
                filePath: filePath,
                priority: priority,
                primaryReference: primaryReference,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CharacterModeReferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $CharacterModeReferencesTable,
      CharacterModeReference,
      $$CharacterModeReferencesTableFilterComposer,
      $$CharacterModeReferencesTableOrderingComposer,
      $$CharacterModeReferencesTableAnnotationComposer,
      $$CharacterModeReferencesTableCreateCompanionBuilder,
      $$CharacterModeReferencesTableUpdateCompanionBuilder,
      (
        CharacterModeReference,
        BaseReferences<
          _$ProjectDatabase,
          $CharacterModeReferencesTable,
          CharacterModeReference
        >,
      ),
      CharacterModeReference,
      PrefetchHooks Function()
    >;
typedef $$AssetRelationsTableCreateCompanionBuilder =
    AssetRelationsCompanion Function({
      required String id,
      Value<String> projectId,
      required String sourceAssetId,
      required String targetAssetId,
      required String relationType,
      Value<String> relationOrigin,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$AssetRelationsTableUpdateCompanionBuilder =
    AssetRelationsCompanion Function({
      Value<String> id,
      Value<String> projectId,
      Value<String> sourceAssetId,
      Value<String> targetAssetId,
      Value<String> relationType,
      Value<String> relationOrigin,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$AssetRelationsTableFilterComposer
    extends Composer<_$ProjectDatabase, $AssetRelationsTable> {
  $$AssetRelationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceAssetId => $composableBuilder(
    column: $table.sourceAssetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetAssetId => $composableBuilder(
    column: $table.targetAssetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relationType => $composableBuilder(
    column: $table.relationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relationOrigin => $composableBuilder(
    column: $table.relationOrigin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AssetRelationsTableOrderingComposer
    extends Composer<_$ProjectDatabase, $AssetRelationsTable> {
  $$AssetRelationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceAssetId => $composableBuilder(
    column: $table.sourceAssetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetAssetId => $composableBuilder(
    column: $table.targetAssetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relationType => $composableBuilder(
    column: $table.relationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relationOrigin => $composableBuilder(
    column: $table.relationOrigin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AssetRelationsTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $AssetRelationsTable> {
  $$AssetRelationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get sourceAssetId => $composableBuilder(
    column: $table.sourceAssetId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetAssetId => $composableBuilder(
    column: $table.targetAssetId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relationType => $composableBuilder(
    column: $table.relationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relationOrigin => $composableBuilder(
    column: $table.relationOrigin,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AssetRelationsTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $AssetRelationsTable,
          AssetRelation,
          $$AssetRelationsTableFilterComposer,
          $$AssetRelationsTableOrderingComposer,
          $$AssetRelationsTableAnnotationComposer,
          $$AssetRelationsTableCreateCompanionBuilder,
          $$AssetRelationsTableUpdateCompanionBuilder,
          (
            AssetRelation,
            BaseReferences<
              _$ProjectDatabase,
              $AssetRelationsTable,
              AssetRelation
            >,
          ),
          AssetRelation,
          PrefetchHooks Function()
        > {
  $$AssetRelationsTableTableManager(
    _$ProjectDatabase db,
    $AssetRelationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetRelationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetRelationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetRelationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> sourceAssetId = const Value.absent(),
                Value<String> targetAssetId = const Value.absent(),
                Value<String> relationType = const Value.absent(),
                Value<String> relationOrigin = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetRelationsCompanion(
                id: id,
                projectId: projectId,
                sourceAssetId: sourceAssetId,
                targetAssetId: targetAssetId,
                relationType: relationType,
                relationOrigin: relationOrigin,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> projectId = const Value.absent(),
                required String sourceAssetId,
                required String targetAssetId,
                required String relationType,
                Value<String> relationOrigin = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetRelationsCompanion.insert(
                id: id,
                projectId: projectId,
                sourceAssetId: sourceAssetId,
                targetAssetId: targetAssetId,
                relationType: relationType,
                relationOrigin: relationOrigin,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AssetRelationsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $AssetRelationsTable,
      AssetRelation,
      $$AssetRelationsTableFilterComposer,
      $$AssetRelationsTableOrderingComposer,
      $$AssetRelationsTableAnnotationComposer,
      $$AssetRelationsTableCreateCompanionBuilder,
      $$AssetRelationsTableUpdateCompanionBuilder,
      (
        AssetRelation,
        BaseReferences<_$ProjectDatabase, $AssetRelationsTable, AssetRelation>,
      ),
      AssetRelation,
      PrefetchHooks Function()
    >;
typedef $$WardrobesTableCreateCompanionBuilder =
    WardrobesCompanion Function({
      required String assetId,
      required String projectId,
      required String name,
      Value<String> category,
      Value<String> description,
      Value<String> primaryMaterial,
      Value<String> fabric,
      Value<String> fit,
      Value<String> style,
      Value<String> notes,
      Value<int> rowid,
    });
typedef $$WardrobesTableUpdateCompanionBuilder =
    WardrobesCompanion Function({
      Value<String> assetId,
      Value<String> projectId,
      Value<String> name,
      Value<String> category,
      Value<String> description,
      Value<String> primaryMaterial,
      Value<String> fabric,
      Value<String> fit,
      Value<String> style,
      Value<String> notes,
      Value<int> rowid,
    });

class $$WardrobesTableFilterComposer
    extends Composer<_$ProjectDatabase, $WardrobesTable> {
  $$WardrobesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get primaryMaterial => $composableBuilder(
    column: $table.primaryMaterial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fabric => $composableBuilder(
    column: $table.fabric,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fit => $composableBuilder(
    column: $table.fit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WardrobesTableOrderingComposer
    extends Composer<_$ProjectDatabase, $WardrobesTable> {
  $$WardrobesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get primaryMaterial => $composableBuilder(
    column: $table.primaryMaterial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fabric => $composableBuilder(
    column: $table.fabric,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fit => $composableBuilder(
    column: $table.fit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WardrobesTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $WardrobesTable> {
  $$WardrobesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get assetId =>
      $composableBuilder(column: $table.assetId, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get primaryMaterial => $composableBuilder(
    column: $table.primaryMaterial,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fabric =>
      $composableBuilder(column: $table.fabric, builder: (column) => column);

  GeneratedColumn<String> get fit =>
      $composableBuilder(column: $table.fit, builder: (column) => column);

  GeneratedColumn<String> get style =>
      $composableBuilder(column: $table.style, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$WardrobesTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $WardrobesTable,
          Wardrobe,
          $$WardrobesTableFilterComposer,
          $$WardrobesTableOrderingComposer,
          $$WardrobesTableAnnotationComposer,
          $$WardrobesTableCreateCompanionBuilder,
          $$WardrobesTableUpdateCompanionBuilder,
          (
            Wardrobe,
            BaseReferences<_$ProjectDatabase, $WardrobesTable, Wardrobe>,
          ),
          Wardrobe,
          PrefetchHooks Function()
        > {
  $$WardrobesTableTableManager(_$ProjectDatabase db, $WardrobesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WardrobesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WardrobesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WardrobesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> assetId = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> primaryMaterial = const Value.absent(),
                Value<String> fabric = const Value.absent(),
                Value<String> fit = const Value.absent(),
                Value<String> style = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WardrobesCompanion(
                assetId: assetId,
                projectId: projectId,
                name: name,
                category: category,
                description: description,
                primaryMaterial: primaryMaterial,
                fabric: fabric,
                fit: fit,
                style: style,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String assetId,
                required String projectId,
                required String name,
                Value<String> category = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> primaryMaterial = const Value.absent(),
                Value<String> fabric = const Value.absent(),
                Value<String> fit = const Value.absent(),
                Value<String> style = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WardrobesCompanion.insert(
                assetId: assetId,
                projectId: projectId,
                name: name,
                category: category,
                description: description,
                primaryMaterial: primaryMaterial,
                fabric: fabric,
                fit: fit,
                style: style,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WardrobesTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $WardrobesTable,
      Wardrobe,
      $$WardrobesTableFilterComposer,
      $$WardrobesTableOrderingComposer,
      $$WardrobesTableAnnotationComposer,
      $$WardrobesTableCreateCompanionBuilder,
      $$WardrobesTableUpdateCompanionBuilder,
      (Wardrobe, BaseReferences<_$ProjectDatabase, $WardrobesTable, Wardrobe>),
      Wardrobe,
      PrefetchHooks Function()
    >;
typedef $$WardrobeComponentsTableCreateCompanionBuilder =
    WardrobeComponentsCompanion Function({
      required String id,
      required String wardrobeId,
      required String name,
      required String componentType,
      Value<String> material,
      Value<String> fabric,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$WardrobeComponentsTableUpdateCompanionBuilder =
    WardrobeComponentsCompanion Function({
      Value<String> id,
      Value<String> wardrobeId,
      Value<String> name,
      Value<String> componentType,
      Value<String> material,
      Value<String> fabric,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$WardrobeComponentsTableFilterComposer
    extends Composer<_$ProjectDatabase, $WardrobeComponentsTable> {
  $$WardrobeComponentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wardrobeId => $composableBuilder(
    column: $table.wardrobeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get componentType => $composableBuilder(
    column: $table.componentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get material => $composableBuilder(
    column: $table.material,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fabric => $composableBuilder(
    column: $table.fabric,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WardrobeComponentsTableOrderingComposer
    extends Composer<_$ProjectDatabase, $WardrobeComponentsTable> {
  $$WardrobeComponentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wardrobeId => $composableBuilder(
    column: $table.wardrobeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get componentType => $composableBuilder(
    column: $table.componentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get material => $composableBuilder(
    column: $table.material,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fabric => $composableBuilder(
    column: $table.fabric,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WardrobeComponentsTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $WardrobeComponentsTable> {
  $$WardrobeComponentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get wardrobeId => $composableBuilder(
    column: $table.wardrobeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get componentType => $composableBuilder(
    column: $table.componentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get material =>
      $composableBuilder(column: $table.material, builder: (column) => column);

  GeneratedColumn<String> get fabric =>
      $composableBuilder(column: $table.fabric, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$WardrobeComponentsTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $WardrobeComponentsTable,
          WardrobeComponent,
          $$WardrobeComponentsTableFilterComposer,
          $$WardrobeComponentsTableOrderingComposer,
          $$WardrobeComponentsTableAnnotationComposer,
          $$WardrobeComponentsTableCreateCompanionBuilder,
          $$WardrobeComponentsTableUpdateCompanionBuilder,
          (
            WardrobeComponent,
            BaseReferences<
              _$ProjectDatabase,
              $WardrobeComponentsTable,
              WardrobeComponent
            >,
          ),
          WardrobeComponent,
          PrefetchHooks Function()
        > {
  $$WardrobeComponentsTableTableManager(
    _$ProjectDatabase db,
    $WardrobeComponentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WardrobeComponentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WardrobeComponentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WardrobeComponentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> wardrobeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> componentType = const Value.absent(),
                Value<String> material = const Value.absent(),
                Value<String> fabric = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WardrobeComponentsCompanion(
                id: id,
                wardrobeId: wardrobeId,
                name: name,
                componentType: componentType,
                material: material,
                fabric: fabric,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String wardrobeId,
                required String name,
                required String componentType,
                Value<String> material = const Value.absent(),
                Value<String> fabric = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WardrobeComponentsCompanion.insert(
                id: id,
                wardrobeId: wardrobeId,
                name: name,
                componentType: componentType,
                material: material,
                fabric: fabric,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WardrobeComponentsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $WardrobeComponentsTable,
      WardrobeComponent,
      $$WardrobeComponentsTableFilterComposer,
      $$WardrobeComponentsTableOrderingComposer,
      $$WardrobeComponentsTableAnnotationComposer,
      $$WardrobeComponentsTableCreateCompanionBuilder,
      $$WardrobeComponentsTableUpdateCompanionBuilder,
      (
        WardrobeComponent,
        BaseReferences<
          _$ProjectDatabase,
          $WardrobeComponentsTable,
          WardrobeComponent
        >,
      ),
      WardrobeComponent,
      PrefetchHooks Function()
    >;
typedef $$WardrobeColorsTableCreateCompanionBuilder =
    WardrobeColorsCompanion Function({
      required String id,
      required String wardrobeId,
      required String name,
      required String hexValue,
      Value<String> usage,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$WardrobeColorsTableUpdateCompanionBuilder =
    WardrobeColorsCompanion Function({
      Value<String> id,
      Value<String> wardrobeId,
      Value<String> name,
      Value<String> hexValue,
      Value<String> usage,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$WardrobeColorsTableFilterComposer
    extends Composer<_$ProjectDatabase, $WardrobeColorsTable> {
  $$WardrobeColorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wardrobeId => $composableBuilder(
    column: $table.wardrobeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hexValue => $composableBuilder(
    column: $table.hexValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get usage => $composableBuilder(
    column: $table.usage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WardrobeColorsTableOrderingComposer
    extends Composer<_$ProjectDatabase, $WardrobeColorsTable> {
  $$WardrobeColorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wardrobeId => $composableBuilder(
    column: $table.wardrobeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hexValue => $composableBuilder(
    column: $table.hexValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get usage => $composableBuilder(
    column: $table.usage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WardrobeColorsTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $WardrobeColorsTable> {
  $$WardrobeColorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get wardrobeId => $composableBuilder(
    column: $table.wardrobeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get hexValue =>
      $composableBuilder(column: $table.hexValue, builder: (column) => column);

  GeneratedColumn<String> get usage =>
      $composableBuilder(column: $table.usage, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$WardrobeColorsTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $WardrobeColorsTable,
          WardrobeColor,
          $$WardrobeColorsTableFilterComposer,
          $$WardrobeColorsTableOrderingComposer,
          $$WardrobeColorsTableAnnotationComposer,
          $$WardrobeColorsTableCreateCompanionBuilder,
          $$WardrobeColorsTableUpdateCompanionBuilder,
          (
            WardrobeColor,
            BaseReferences<
              _$ProjectDatabase,
              $WardrobeColorsTable,
              WardrobeColor
            >,
          ),
          WardrobeColor,
          PrefetchHooks Function()
        > {
  $$WardrobeColorsTableTableManager(
    _$ProjectDatabase db,
    $WardrobeColorsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WardrobeColorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WardrobeColorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WardrobeColorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> wardrobeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> hexValue = const Value.absent(),
                Value<String> usage = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WardrobeColorsCompanion(
                id: id,
                wardrobeId: wardrobeId,
                name: name,
                hexValue: hexValue,
                usage: usage,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String wardrobeId,
                required String name,
                required String hexValue,
                Value<String> usage = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WardrobeColorsCompanion.insert(
                id: id,
                wardrobeId: wardrobeId,
                name: name,
                hexValue: hexValue,
                usage: usage,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WardrobeColorsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $WardrobeColorsTable,
      WardrobeColor,
      $$WardrobeColorsTableFilterComposer,
      $$WardrobeColorsTableOrderingComposer,
      $$WardrobeColorsTableAnnotationComposer,
      $$WardrobeColorsTableCreateCompanionBuilder,
      $$WardrobeColorsTableUpdateCompanionBuilder,
      (
        WardrobeColor,
        BaseReferences<_$ProjectDatabase, $WardrobeColorsTable, WardrobeColor>,
      ),
      WardrobeColor,
      PrefetchHooks Function()
    >;
typedef $$WardrobeVariantsTableCreateCompanionBuilder =
    WardrobeVariantsCompanion Function({
      required String id,
      required String wardrobeId,
      required String name,
      Value<String> description,
      Value<bool> isDefault,
      Value<int> rowid,
    });
typedef $$WardrobeVariantsTableUpdateCompanionBuilder =
    WardrobeVariantsCompanion Function({
      Value<String> id,
      Value<String> wardrobeId,
      Value<String> name,
      Value<String> description,
      Value<bool> isDefault,
      Value<int> rowid,
    });

class $$WardrobeVariantsTableFilterComposer
    extends Composer<_$ProjectDatabase, $WardrobeVariantsTable> {
  $$WardrobeVariantsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wardrobeId => $composableBuilder(
    column: $table.wardrobeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WardrobeVariantsTableOrderingComposer
    extends Composer<_$ProjectDatabase, $WardrobeVariantsTable> {
  $$WardrobeVariantsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wardrobeId => $composableBuilder(
    column: $table.wardrobeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WardrobeVariantsTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $WardrobeVariantsTable> {
  $$WardrobeVariantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get wardrobeId => $composableBuilder(
    column: $table.wardrobeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);
}

class $$WardrobeVariantsTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $WardrobeVariantsTable,
          WardrobeVariant,
          $$WardrobeVariantsTableFilterComposer,
          $$WardrobeVariantsTableOrderingComposer,
          $$WardrobeVariantsTableAnnotationComposer,
          $$WardrobeVariantsTableCreateCompanionBuilder,
          $$WardrobeVariantsTableUpdateCompanionBuilder,
          (
            WardrobeVariant,
            BaseReferences<
              _$ProjectDatabase,
              $WardrobeVariantsTable,
              WardrobeVariant
            >,
          ),
          WardrobeVariant,
          PrefetchHooks Function()
        > {
  $$WardrobeVariantsTableTableManager(
    _$ProjectDatabase db,
    $WardrobeVariantsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WardrobeVariantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WardrobeVariantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WardrobeVariantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> wardrobeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WardrobeVariantsCompanion(
                id: id,
                wardrobeId: wardrobeId,
                name: name,
                description: description,
                isDefault: isDefault,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String wardrobeId,
                required String name,
                Value<String> description = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WardrobeVariantsCompanion.insert(
                id: id,
                wardrobeId: wardrobeId,
                name: name,
                description: description,
                isDefault: isDefault,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WardrobeVariantsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $WardrobeVariantsTable,
      WardrobeVariant,
      $$WardrobeVariantsTableFilterComposer,
      $$WardrobeVariantsTableOrderingComposer,
      $$WardrobeVariantsTableAnnotationComposer,
      $$WardrobeVariantsTableCreateCompanionBuilder,
      $$WardrobeVariantsTableUpdateCompanionBuilder,
      (
        WardrobeVariant,
        BaseReferences<
          _$ProjectDatabase,
          $WardrobeVariantsTable,
          WardrobeVariant
        >,
      ),
      WardrobeVariant,
      PrefetchHooks Function()
    >;
typedef $$WardrobeReferencesTableCreateCompanionBuilder =
    WardrobeReferencesCompanion Function({
      required String id,
      required String wardrobeId,
      required String referenceType,
      required String filePath,
      Value<int> priority,
      Value<int> rowid,
    });
typedef $$WardrobeReferencesTableUpdateCompanionBuilder =
    WardrobeReferencesCompanion Function({
      Value<String> id,
      Value<String> wardrobeId,
      Value<String> referenceType,
      Value<String> filePath,
      Value<int> priority,
      Value<int> rowid,
    });

class $$WardrobeReferencesTableFilterComposer
    extends Composer<_$ProjectDatabase, $WardrobeReferencesTable> {
  $$WardrobeReferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wardrobeId => $composableBuilder(
    column: $table.wardrobeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WardrobeReferencesTableOrderingComposer
    extends Composer<_$ProjectDatabase, $WardrobeReferencesTable> {
  $$WardrobeReferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wardrobeId => $composableBuilder(
    column: $table.wardrobeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WardrobeReferencesTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $WardrobeReferencesTable> {
  $$WardrobeReferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get wardrobeId => $composableBuilder(
    column: $table.wardrobeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);
}

class $$WardrobeReferencesTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $WardrobeReferencesTable,
          WardrobeReference,
          $$WardrobeReferencesTableFilterComposer,
          $$WardrobeReferencesTableOrderingComposer,
          $$WardrobeReferencesTableAnnotationComposer,
          $$WardrobeReferencesTableCreateCompanionBuilder,
          $$WardrobeReferencesTableUpdateCompanionBuilder,
          (
            WardrobeReference,
            BaseReferences<
              _$ProjectDatabase,
              $WardrobeReferencesTable,
              WardrobeReference
            >,
          ),
          WardrobeReference,
          PrefetchHooks Function()
        > {
  $$WardrobeReferencesTableTableManager(
    _$ProjectDatabase db,
    $WardrobeReferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WardrobeReferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WardrobeReferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WardrobeReferencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> wardrobeId = const Value.absent(),
                Value<String> referenceType = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WardrobeReferencesCompanion(
                id: id,
                wardrobeId: wardrobeId,
                referenceType: referenceType,
                filePath: filePath,
                priority: priority,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String wardrobeId,
                required String referenceType,
                required String filePath,
                Value<int> priority = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WardrobeReferencesCompanion.insert(
                id: id,
                wardrobeId: wardrobeId,
                referenceType: referenceType,
                filePath: filePath,
                priority: priority,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WardrobeReferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $WardrobeReferencesTable,
      WardrobeReference,
      $$WardrobeReferencesTableFilterComposer,
      $$WardrobeReferencesTableOrderingComposer,
      $$WardrobeReferencesTableAnnotationComposer,
      $$WardrobeReferencesTableCreateCompanionBuilder,
      $$WardrobeReferencesTableUpdateCompanionBuilder,
      (
        WardrobeReference,
        BaseReferences<
          _$ProjectDatabase,
          $WardrobeReferencesTable,
          WardrobeReference
        >,
      ),
      WardrobeReference,
      PrefetchHooks Function()
    >;
typedef $$WeaponsTableCreateCompanionBuilder =
    WeaponsCompanion Function({
      required String assetId,
      required String projectId,
      required String name,
      Value<String> weaponType,
      Value<String> description,
      Value<String> primaryMaterial,
      Value<String> secondaryMaterial,
      Value<String> energyType,
      Value<String> coreType,
      Value<double?> lengthMm,
      Value<double?> weightKg,
      Value<String> notes,
      Value<int> rowid,
    });
typedef $$WeaponsTableUpdateCompanionBuilder =
    WeaponsCompanion Function({
      Value<String> assetId,
      Value<String> projectId,
      Value<String> name,
      Value<String> weaponType,
      Value<String> description,
      Value<String> primaryMaterial,
      Value<String> secondaryMaterial,
      Value<String> energyType,
      Value<String> coreType,
      Value<double?> lengthMm,
      Value<double?> weightKg,
      Value<String> notes,
      Value<int> rowid,
    });

class $$WeaponsTableFilterComposer
    extends Composer<_$ProjectDatabase, $WeaponsTable> {
  $$WeaponsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weaponType => $composableBuilder(
    column: $table.weaponType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get primaryMaterial => $composableBuilder(
    column: $table.primaryMaterial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get secondaryMaterial => $composableBuilder(
    column: $table.secondaryMaterial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get energyType => $composableBuilder(
    column: $table.energyType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coreType => $composableBuilder(
    column: $table.coreType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lengthMm => $composableBuilder(
    column: $table.lengthMm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeaponsTableOrderingComposer
    extends Composer<_$ProjectDatabase, $WeaponsTable> {
  $$WeaponsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weaponType => $composableBuilder(
    column: $table.weaponType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get primaryMaterial => $composableBuilder(
    column: $table.primaryMaterial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get secondaryMaterial => $composableBuilder(
    column: $table.secondaryMaterial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get energyType => $composableBuilder(
    column: $table.energyType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coreType => $composableBuilder(
    column: $table.coreType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lengthMm => $composableBuilder(
    column: $table.lengthMm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeaponsTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $WeaponsTable> {
  $$WeaponsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get assetId =>
      $composableBuilder(column: $table.assetId, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get weaponType => $composableBuilder(
    column: $table.weaponType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get primaryMaterial => $composableBuilder(
    column: $table.primaryMaterial,
    builder: (column) => column,
  );

  GeneratedColumn<String> get secondaryMaterial => $composableBuilder(
    column: $table.secondaryMaterial,
    builder: (column) => column,
  );

  GeneratedColumn<String> get energyType => $composableBuilder(
    column: $table.energyType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coreType =>
      $composableBuilder(column: $table.coreType, builder: (column) => column);

  GeneratedColumn<double> get lengthMm =>
      $composableBuilder(column: $table.lengthMm, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$WeaponsTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $WeaponsTable,
          Weapon,
          $$WeaponsTableFilterComposer,
          $$WeaponsTableOrderingComposer,
          $$WeaponsTableAnnotationComposer,
          $$WeaponsTableCreateCompanionBuilder,
          $$WeaponsTableUpdateCompanionBuilder,
          (Weapon, BaseReferences<_$ProjectDatabase, $WeaponsTable, Weapon>),
          Weapon,
          PrefetchHooks Function()
        > {
  $$WeaponsTableTableManager(_$ProjectDatabase db, $WeaponsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeaponsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeaponsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeaponsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> assetId = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> weaponType = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> primaryMaterial = const Value.absent(),
                Value<String> secondaryMaterial = const Value.absent(),
                Value<String> energyType = const Value.absent(),
                Value<String> coreType = const Value.absent(),
                Value<double?> lengthMm = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeaponsCompanion(
                assetId: assetId,
                projectId: projectId,
                name: name,
                weaponType: weaponType,
                description: description,
                primaryMaterial: primaryMaterial,
                secondaryMaterial: secondaryMaterial,
                energyType: energyType,
                coreType: coreType,
                lengthMm: lengthMm,
                weightKg: weightKg,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String assetId,
                required String projectId,
                required String name,
                Value<String> weaponType = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> primaryMaterial = const Value.absent(),
                Value<String> secondaryMaterial = const Value.absent(),
                Value<String> energyType = const Value.absent(),
                Value<String> coreType = const Value.absent(),
                Value<double?> lengthMm = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeaponsCompanion.insert(
                assetId: assetId,
                projectId: projectId,
                name: name,
                weaponType: weaponType,
                description: description,
                primaryMaterial: primaryMaterial,
                secondaryMaterial: secondaryMaterial,
                energyType: energyType,
                coreType: coreType,
                lengthMm: lengthMm,
                weightKg: weightKg,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeaponsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $WeaponsTable,
      Weapon,
      $$WeaponsTableFilterComposer,
      $$WeaponsTableOrderingComposer,
      $$WeaponsTableAnnotationComposer,
      $$WeaponsTableCreateCompanionBuilder,
      $$WeaponsTableUpdateCompanionBuilder,
      (Weapon, BaseReferences<_$ProjectDatabase, $WeaponsTable, Weapon>),
      Weapon,
      PrefetchHooks Function()
    >;
typedef $$WeaponComponentsTableCreateCompanionBuilder =
    WeaponComponentsCompanion Function({
      required String id,
      required String weaponId,
      required String name,
      required String componentType,
      Value<String> material,
      Value<String> description,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$WeaponComponentsTableUpdateCompanionBuilder =
    WeaponComponentsCompanion Function({
      Value<String> id,
      Value<String> weaponId,
      Value<String> name,
      Value<String> componentType,
      Value<String> material,
      Value<String> description,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$WeaponComponentsTableFilterComposer
    extends Composer<_$ProjectDatabase, $WeaponComponentsTable> {
  $$WeaponComponentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weaponId => $composableBuilder(
    column: $table.weaponId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get componentType => $composableBuilder(
    column: $table.componentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get material => $composableBuilder(
    column: $table.material,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeaponComponentsTableOrderingComposer
    extends Composer<_$ProjectDatabase, $WeaponComponentsTable> {
  $$WeaponComponentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weaponId => $composableBuilder(
    column: $table.weaponId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get componentType => $composableBuilder(
    column: $table.componentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get material => $composableBuilder(
    column: $table.material,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeaponComponentsTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $WeaponComponentsTable> {
  $$WeaponComponentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get weaponId =>
      $composableBuilder(column: $table.weaponId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get componentType => $composableBuilder(
    column: $table.componentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get material =>
      $composableBuilder(column: $table.material, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$WeaponComponentsTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $WeaponComponentsTable,
          WeaponComponent,
          $$WeaponComponentsTableFilterComposer,
          $$WeaponComponentsTableOrderingComposer,
          $$WeaponComponentsTableAnnotationComposer,
          $$WeaponComponentsTableCreateCompanionBuilder,
          $$WeaponComponentsTableUpdateCompanionBuilder,
          (
            WeaponComponent,
            BaseReferences<
              _$ProjectDatabase,
              $WeaponComponentsTable,
              WeaponComponent
            >,
          ),
          WeaponComponent,
          PrefetchHooks Function()
        > {
  $$WeaponComponentsTableTableManager(
    _$ProjectDatabase db,
    $WeaponComponentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeaponComponentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeaponComponentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeaponComponentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> weaponId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> componentType = const Value.absent(),
                Value<String> material = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeaponComponentsCompanion(
                id: id,
                weaponId: weaponId,
                name: name,
                componentType: componentType,
                material: material,
                description: description,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String weaponId,
                required String name,
                required String componentType,
                Value<String> material = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeaponComponentsCompanion.insert(
                id: id,
                weaponId: weaponId,
                name: name,
                componentType: componentType,
                material: material,
                description: description,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeaponComponentsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $WeaponComponentsTable,
      WeaponComponent,
      $$WeaponComponentsTableFilterComposer,
      $$WeaponComponentsTableOrderingComposer,
      $$WeaponComponentsTableAnnotationComposer,
      $$WeaponComponentsTableCreateCompanionBuilder,
      $$WeaponComponentsTableUpdateCompanionBuilder,
      (
        WeaponComponent,
        BaseReferences<
          _$ProjectDatabase,
          $WeaponComponentsTable,
          WeaponComponent
        >,
      ),
      WeaponComponent,
      PrefetchHooks Function()
    >;
typedef $$WeaponMeasurementsTableCreateCompanionBuilder =
    WeaponMeasurementsCompanion Function({
      required String id,
      required String weaponId,
      required String label,
      required double value,
      required String unit,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$WeaponMeasurementsTableUpdateCompanionBuilder =
    WeaponMeasurementsCompanion Function({
      Value<String> id,
      Value<String> weaponId,
      Value<String> label,
      Value<double> value,
      Value<String> unit,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$WeaponMeasurementsTableFilterComposer
    extends Composer<_$ProjectDatabase, $WeaponMeasurementsTable> {
  $$WeaponMeasurementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weaponId => $composableBuilder(
    column: $table.weaponId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeaponMeasurementsTableOrderingComposer
    extends Composer<_$ProjectDatabase, $WeaponMeasurementsTable> {
  $$WeaponMeasurementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weaponId => $composableBuilder(
    column: $table.weaponId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeaponMeasurementsTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $WeaponMeasurementsTable> {
  $$WeaponMeasurementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get weaponId =>
      $composableBuilder(column: $table.weaponId, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$WeaponMeasurementsTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $WeaponMeasurementsTable,
          WeaponMeasurement,
          $$WeaponMeasurementsTableFilterComposer,
          $$WeaponMeasurementsTableOrderingComposer,
          $$WeaponMeasurementsTableAnnotationComposer,
          $$WeaponMeasurementsTableCreateCompanionBuilder,
          $$WeaponMeasurementsTableUpdateCompanionBuilder,
          (
            WeaponMeasurement,
            BaseReferences<
              _$ProjectDatabase,
              $WeaponMeasurementsTable,
              WeaponMeasurement
            >,
          ),
          WeaponMeasurement,
          PrefetchHooks Function()
        > {
  $$WeaponMeasurementsTableTableManager(
    _$ProjectDatabase db,
    $WeaponMeasurementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeaponMeasurementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeaponMeasurementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeaponMeasurementsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> weaponId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeaponMeasurementsCompanion(
                id: id,
                weaponId: weaponId,
                label: label,
                value: value,
                unit: unit,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String weaponId,
                required String label,
                required double value,
                required String unit,
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeaponMeasurementsCompanion.insert(
                id: id,
                weaponId: weaponId,
                label: label,
                value: value,
                unit: unit,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeaponMeasurementsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $WeaponMeasurementsTable,
      WeaponMeasurement,
      $$WeaponMeasurementsTableFilterComposer,
      $$WeaponMeasurementsTableOrderingComposer,
      $$WeaponMeasurementsTableAnnotationComposer,
      $$WeaponMeasurementsTableCreateCompanionBuilder,
      $$WeaponMeasurementsTableUpdateCompanionBuilder,
      (
        WeaponMeasurement,
        BaseReferences<
          _$ProjectDatabase,
          $WeaponMeasurementsTable,
          WeaponMeasurement
        >,
      ),
      WeaponMeasurement,
      PrefetchHooks Function()
    >;
typedef $$WeaponColorsTableCreateCompanionBuilder =
    WeaponColorsCompanion Function({
      required String id,
      required String weaponId,
      required String name,
      required String hexValue,
      Value<String> usage,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$WeaponColorsTableUpdateCompanionBuilder =
    WeaponColorsCompanion Function({
      Value<String> id,
      Value<String> weaponId,
      Value<String> name,
      Value<String> hexValue,
      Value<String> usage,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$WeaponColorsTableFilterComposer
    extends Composer<_$ProjectDatabase, $WeaponColorsTable> {
  $$WeaponColorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weaponId => $composableBuilder(
    column: $table.weaponId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hexValue => $composableBuilder(
    column: $table.hexValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get usage => $composableBuilder(
    column: $table.usage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeaponColorsTableOrderingComposer
    extends Composer<_$ProjectDatabase, $WeaponColorsTable> {
  $$WeaponColorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weaponId => $composableBuilder(
    column: $table.weaponId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hexValue => $composableBuilder(
    column: $table.hexValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get usage => $composableBuilder(
    column: $table.usage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeaponColorsTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $WeaponColorsTable> {
  $$WeaponColorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get weaponId =>
      $composableBuilder(column: $table.weaponId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get hexValue =>
      $composableBuilder(column: $table.hexValue, builder: (column) => column);

  GeneratedColumn<String> get usage =>
      $composableBuilder(column: $table.usage, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$WeaponColorsTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $WeaponColorsTable,
          WeaponColor,
          $$WeaponColorsTableFilterComposer,
          $$WeaponColorsTableOrderingComposer,
          $$WeaponColorsTableAnnotationComposer,
          $$WeaponColorsTableCreateCompanionBuilder,
          $$WeaponColorsTableUpdateCompanionBuilder,
          (
            WeaponColor,
            BaseReferences<_$ProjectDatabase, $WeaponColorsTable, WeaponColor>,
          ),
          WeaponColor,
          PrefetchHooks Function()
        > {
  $$WeaponColorsTableTableManager(
    _$ProjectDatabase db,
    $WeaponColorsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeaponColorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeaponColorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeaponColorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> weaponId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> hexValue = const Value.absent(),
                Value<String> usage = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeaponColorsCompanion(
                id: id,
                weaponId: weaponId,
                name: name,
                hexValue: hexValue,
                usage: usage,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String weaponId,
                required String name,
                required String hexValue,
                Value<String> usage = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeaponColorsCompanion.insert(
                id: id,
                weaponId: weaponId,
                name: name,
                hexValue: hexValue,
                usage: usage,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeaponColorsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $WeaponColorsTable,
      WeaponColor,
      $$WeaponColorsTableFilterComposer,
      $$WeaponColorsTableOrderingComposer,
      $$WeaponColorsTableAnnotationComposer,
      $$WeaponColorsTableCreateCompanionBuilder,
      $$WeaponColorsTableUpdateCompanionBuilder,
      (
        WeaponColor,
        BaseReferences<_$ProjectDatabase, $WeaponColorsTable, WeaponColor>,
      ),
      WeaponColor,
      PrefetchHooks Function()
    >;
typedef $$WeaponEnergyProfilesTableCreateCompanionBuilder =
    WeaponEnergyProfilesCompanion Function({
      required String weaponId,
      Value<String> energyType,
      Value<String> coreType,
      Value<String> activation,
      Value<String> emissionColor,
      Value<String> behavior,
      Value<int> rowid,
    });
typedef $$WeaponEnergyProfilesTableUpdateCompanionBuilder =
    WeaponEnergyProfilesCompanion Function({
      Value<String> weaponId,
      Value<String> energyType,
      Value<String> coreType,
      Value<String> activation,
      Value<String> emissionColor,
      Value<String> behavior,
      Value<int> rowid,
    });

class $$WeaponEnergyProfilesTableFilterComposer
    extends Composer<_$ProjectDatabase, $WeaponEnergyProfilesTable> {
  $$WeaponEnergyProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get weaponId => $composableBuilder(
    column: $table.weaponId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get energyType => $composableBuilder(
    column: $table.energyType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coreType => $composableBuilder(
    column: $table.coreType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activation => $composableBuilder(
    column: $table.activation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emissionColor => $composableBuilder(
    column: $table.emissionColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get behavior => $composableBuilder(
    column: $table.behavior,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeaponEnergyProfilesTableOrderingComposer
    extends Composer<_$ProjectDatabase, $WeaponEnergyProfilesTable> {
  $$WeaponEnergyProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get weaponId => $composableBuilder(
    column: $table.weaponId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get energyType => $composableBuilder(
    column: $table.energyType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coreType => $composableBuilder(
    column: $table.coreType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activation => $composableBuilder(
    column: $table.activation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emissionColor => $composableBuilder(
    column: $table.emissionColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get behavior => $composableBuilder(
    column: $table.behavior,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeaponEnergyProfilesTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $WeaponEnergyProfilesTable> {
  $$WeaponEnergyProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get weaponId =>
      $composableBuilder(column: $table.weaponId, builder: (column) => column);

  GeneratedColumn<String> get energyType => $composableBuilder(
    column: $table.energyType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coreType =>
      $composableBuilder(column: $table.coreType, builder: (column) => column);

  GeneratedColumn<String> get activation => $composableBuilder(
    column: $table.activation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get emissionColor => $composableBuilder(
    column: $table.emissionColor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get behavior =>
      $composableBuilder(column: $table.behavior, builder: (column) => column);
}

class $$WeaponEnergyProfilesTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $WeaponEnergyProfilesTable,
          WeaponEnergyProfile,
          $$WeaponEnergyProfilesTableFilterComposer,
          $$WeaponEnergyProfilesTableOrderingComposer,
          $$WeaponEnergyProfilesTableAnnotationComposer,
          $$WeaponEnergyProfilesTableCreateCompanionBuilder,
          $$WeaponEnergyProfilesTableUpdateCompanionBuilder,
          (
            WeaponEnergyProfile,
            BaseReferences<
              _$ProjectDatabase,
              $WeaponEnergyProfilesTable,
              WeaponEnergyProfile
            >,
          ),
          WeaponEnergyProfile,
          PrefetchHooks Function()
        > {
  $$WeaponEnergyProfilesTableTableManager(
    _$ProjectDatabase db,
    $WeaponEnergyProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeaponEnergyProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeaponEnergyProfilesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WeaponEnergyProfilesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> weaponId = const Value.absent(),
                Value<String> energyType = const Value.absent(),
                Value<String> coreType = const Value.absent(),
                Value<String> activation = const Value.absent(),
                Value<String> emissionColor = const Value.absent(),
                Value<String> behavior = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeaponEnergyProfilesCompanion(
                weaponId: weaponId,
                energyType: energyType,
                coreType: coreType,
                activation: activation,
                emissionColor: emissionColor,
                behavior: behavior,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String weaponId,
                Value<String> energyType = const Value.absent(),
                Value<String> coreType = const Value.absent(),
                Value<String> activation = const Value.absent(),
                Value<String> emissionColor = const Value.absent(),
                Value<String> behavior = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeaponEnergyProfilesCompanion.insert(
                weaponId: weaponId,
                energyType: energyType,
                coreType: coreType,
                activation: activation,
                emissionColor: emissionColor,
                behavior: behavior,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeaponEnergyProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $WeaponEnergyProfilesTable,
      WeaponEnergyProfile,
      $$WeaponEnergyProfilesTableFilterComposer,
      $$WeaponEnergyProfilesTableOrderingComposer,
      $$WeaponEnergyProfilesTableAnnotationComposer,
      $$WeaponEnergyProfilesTableCreateCompanionBuilder,
      $$WeaponEnergyProfilesTableUpdateCompanionBuilder,
      (
        WeaponEnergyProfile,
        BaseReferences<
          _$ProjectDatabase,
          $WeaponEnergyProfilesTable,
          WeaponEnergyProfile
        >,
      ),
      WeaponEnergyProfile,
      PrefetchHooks Function()
    >;
typedef $$WeaponVariantsTableCreateCompanionBuilder =
    WeaponVariantsCompanion Function({
      required String id,
      required String weaponId,
      required String name,
      Value<String> description,
      Value<bool> isDefault,
      Value<int> rowid,
    });
typedef $$WeaponVariantsTableUpdateCompanionBuilder =
    WeaponVariantsCompanion Function({
      Value<String> id,
      Value<String> weaponId,
      Value<String> name,
      Value<String> description,
      Value<bool> isDefault,
      Value<int> rowid,
    });

class $$WeaponVariantsTableFilterComposer
    extends Composer<_$ProjectDatabase, $WeaponVariantsTable> {
  $$WeaponVariantsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weaponId => $composableBuilder(
    column: $table.weaponId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeaponVariantsTableOrderingComposer
    extends Composer<_$ProjectDatabase, $WeaponVariantsTable> {
  $$WeaponVariantsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weaponId => $composableBuilder(
    column: $table.weaponId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeaponVariantsTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $WeaponVariantsTable> {
  $$WeaponVariantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get weaponId =>
      $composableBuilder(column: $table.weaponId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);
}

class $$WeaponVariantsTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $WeaponVariantsTable,
          WeaponVariant,
          $$WeaponVariantsTableFilterComposer,
          $$WeaponVariantsTableOrderingComposer,
          $$WeaponVariantsTableAnnotationComposer,
          $$WeaponVariantsTableCreateCompanionBuilder,
          $$WeaponVariantsTableUpdateCompanionBuilder,
          (
            WeaponVariant,
            BaseReferences<
              _$ProjectDatabase,
              $WeaponVariantsTable,
              WeaponVariant
            >,
          ),
          WeaponVariant,
          PrefetchHooks Function()
        > {
  $$WeaponVariantsTableTableManager(
    _$ProjectDatabase db,
    $WeaponVariantsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeaponVariantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeaponVariantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeaponVariantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> weaponId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeaponVariantsCompanion(
                id: id,
                weaponId: weaponId,
                name: name,
                description: description,
                isDefault: isDefault,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String weaponId,
                required String name,
                Value<String> description = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeaponVariantsCompanion.insert(
                id: id,
                weaponId: weaponId,
                name: name,
                description: description,
                isDefault: isDefault,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeaponVariantsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $WeaponVariantsTable,
      WeaponVariant,
      $$WeaponVariantsTableFilterComposer,
      $$WeaponVariantsTableOrderingComposer,
      $$WeaponVariantsTableAnnotationComposer,
      $$WeaponVariantsTableCreateCompanionBuilder,
      $$WeaponVariantsTableUpdateCompanionBuilder,
      (
        WeaponVariant,
        BaseReferences<_$ProjectDatabase, $WeaponVariantsTable, WeaponVariant>,
      ),
      WeaponVariant,
      PrefetchHooks Function()
    >;
typedef $$WeaponReferencesTableCreateCompanionBuilder =
    WeaponReferencesCompanion Function({
      required String id,
      required String weaponId,
      required String referenceType,
      required String filePath,
      Value<int> priority,
      Value<bool> primaryReference,
      Value<int> rowid,
    });
typedef $$WeaponReferencesTableUpdateCompanionBuilder =
    WeaponReferencesCompanion Function({
      Value<String> id,
      Value<String> weaponId,
      Value<String> referenceType,
      Value<String> filePath,
      Value<int> priority,
      Value<bool> primaryReference,
      Value<int> rowid,
    });

class $$WeaponReferencesTableFilterComposer
    extends Composer<_$ProjectDatabase, $WeaponReferencesTable> {
  $$WeaponReferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weaponId => $composableBuilder(
    column: $table.weaponId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get primaryReference => $composableBuilder(
    column: $table.primaryReference,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeaponReferencesTableOrderingComposer
    extends Composer<_$ProjectDatabase, $WeaponReferencesTable> {
  $$WeaponReferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weaponId => $composableBuilder(
    column: $table.weaponId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get primaryReference => $composableBuilder(
    column: $table.primaryReference,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeaponReferencesTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $WeaponReferencesTable> {
  $$WeaponReferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get weaponId =>
      $composableBuilder(column: $table.weaponId, builder: (column) => column);

  GeneratedColumn<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<bool> get primaryReference => $composableBuilder(
    column: $table.primaryReference,
    builder: (column) => column,
  );
}

class $$WeaponReferencesTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $WeaponReferencesTable,
          WeaponReference,
          $$WeaponReferencesTableFilterComposer,
          $$WeaponReferencesTableOrderingComposer,
          $$WeaponReferencesTableAnnotationComposer,
          $$WeaponReferencesTableCreateCompanionBuilder,
          $$WeaponReferencesTableUpdateCompanionBuilder,
          (
            WeaponReference,
            BaseReferences<
              _$ProjectDatabase,
              $WeaponReferencesTable,
              WeaponReference
            >,
          ),
          WeaponReference,
          PrefetchHooks Function()
        > {
  $$WeaponReferencesTableTableManager(
    _$ProjectDatabase db,
    $WeaponReferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeaponReferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeaponReferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeaponReferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> weaponId = const Value.absent(),
                Value<String> referenceType = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<bool> primaryReference = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeaponReferencesCompanion(
                id: id,
                weaponId: weaponId,
                referenceType: referenceType,
                filePath: filePath,
                priority: priority,
                primaryReference: primaryReference,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String weaponId,
                required String referenceType,
                required String filePath,
                Value<int> priority = const Value.absent(),
                Value<bool> primaryReference = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeaponReferencesCompanion.insert(
                id: id,
                weaponId: weaponId,
                referenceType: referenceType,
                filePath: filePath,
                priority: priority,
                primaryReference: primaryReference,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeaponReferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $WeaponReferencesTable,
      WeaponReference,
      $$WeaponReferencesTableFilterComposer,
      $$WeaponReferencesTableOrderingComposer,
      $$WeaponReferencesTableAnnotationComposer,
      $$WeaponReferencesTableCreateCompanionBuilder,
      $$WeaponReferencesTableUpdateCompanionBuilder,
      (
        WeaponReference,
        BaseReferences<
          _$ProjectDatabase,
          $WeaponReferencesTable,
          WeaponReference
        >,
      ),
      WeaponReference,
      PrefetchHooks Function()
    >;
typedef $$WeaponPreservationProfilesTableCreateCompanionBuilder =
    WeaponPreservationProfilesCompanion Function({
      required String weaponId,
      Value<bool> geometryLock,
      Value<bool> materialLock,
      Value<bool> colorLock,
      Value<bool> coreLock,
      Value<bool> scaleLock,
      Value<bool> effectLock,
      Value<int> rowid,
    });
typedef $$WeaponPreservationProfilesTableUpdateCompanionBuilder =
    WeaponPreservationProfilesCompanion Function({
      Value<String> weaponId,
      Value<bool> geometryLock,
      Value<bool> materialLock,
      Value<bool> colorLock,
      Value<bool> coreLock,
      Value<bool> scaleLock,
      Value<bool> effectLock,
      Value<int> rowid,
    });

class $$WeaponPreservationProfilesTableFilterComposer
    extends Composer<_$ProjectDatabase, $WeaponPreservationProfilesTable> {
  $$WeaponPreservationProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get weaponId => $composableBuilder(
    column: $table.weaponId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get geometryLock => $composableBuilder(
    column: $table.geometryLock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get materialLock => $composableBuilder(
    column: $table.materialLock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get colorLock => $composableBuilder(
    column: $table.colorLock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get coreLock => $composableBuilder(
    column: $table.coreLock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get scaleLock => $composableBuilder(
    column: $table.scaleLock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get effectLock => $composableBuilder(
    column: $table.effectLock,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeaponPreservationProfilesTableOrderingComposer
    extends Composer<_$ProjectDatabase, $WeaponPreservationProfilesTable> {
  $$WeaponPreservationProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get weaponId => $composableBuilder(
    column: $table.weaponId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get geometryLock => $composableBuilder(
    column: $table.geometryLock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get materialLock => $composableBuilder(
    column: $table.materialLock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get colorLock => $composableBuilder(
    column: $table.colorLock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get coreLock => $composableBuilder(
    column: $table.coreLock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get scaleLock => $composableBuilder(
    column: $table.scaleLock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get effectLock => $composableBuilder(
    column: $table.effectLock,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeaponPreservationProfilesTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $WeaponPreservationProfilesTable> {
  $$WeaponPreservationProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get weaponId =>
      $composableBuilder(column: $table.weaponId, builder: (column) => column);

  GeneratedColumn<bool> get geometryLock => $composableBuilder(
    column: $table.geometryLock,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get materialLock => $composableBuilder(
    column: $table.materialLock,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get colorLock =>
      $composableBuilder(column: $table.colorLock, builder: (column) => column);

  GeneratedColumn<bool> get coreLock =>
      $composableBuilder(column: $table.coreLock, builder: (column) => column);

  GeneratedColumn<bool> get scaleLock =>
      $composableBuilder(column: $table.scaleLock, builder: (column) => column);

  GeneratedColumn<bool> get effectLock => $composableBuilder(
    column: $table.effectLock,
    builder: (column) => column,
  );
}

class $$WeaponPreservationProfilesTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $WeaponPreservationProfilesTable,
          WeaponPreservationProfile,
          $$WeaponPreservationProfilesTableFilterComposer,
          $$WeaponPreservationProfilesTableOrderingComposer,
          $$WeaponPreservationProfilesTableAnnotationComposer,
          $$WeaponPreservationProfilesTableCreateCompanionBuilder,
          $$WeaponPreservationProfilesTableUpdateCompanionBuilder,
          (
            WeaponPreservationProfile,
            BaseReferences<
              _$ProjectDatabase,
              $WeaponPreservationProfilesTable,
              WeaponPreservationProfile
            >,
          ),
          WeaponPreservationProfile,
          PrefetchHooks Function()
        > {
  $$WeaponPreservationProfilesTableTableManager(
    _$ProjectDatabase db,
    $WeaponPreservationProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeaponPreservationProfilesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$WeaponPreservationProfilesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WeaponPreservationProfilesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> weaponId = const Value.absent(),
                Value<bool> geometryLock = const Value.absent(),
                Value<bool> materialLock = const Value.absent(),
                Value<bool> colorLock = const Value.absent(),
                Value<bool> coreLock = const Value.absent(),
                Value<bool> scaleLock = const Value.absent(),
                Value<bool> effectLock = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeaponPreservationProfilesCompanion(
                weaponId: weaponId,
                geometryLock: geometryLock,
                materialLock: materialLock,
                colorLock: colorLock,
                coreLock: coreLock,
                scaleLock: scaleLock,
                effectLock: effectLock,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String weaponId,
                Value<bool> geometryLock = const Value.absent(),
                Value<bool> materialLock = const Value.absent(),
                Value<bool> colorLock = const Value.absent(),
                Value<bool> coreLock = const Value.absent(),
                Value<bool> scaleLock = const Value.absent(),
                Value<bool> effectLock = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeaponPreservationProfilesCompanion.insert(
                weaponId: weaponId,
                geometryLock: geometryLock,
                materialLock: materialLock,
                colorLock: colorLock,
                coreLock: coreLock,
                scaleLock: scaleLock,
                effectLock: effectLock,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeaponPreservationProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $WeaponPreservationProfilesTable,
      WeaponPreservationProfile,
      $$WeaponPreservationProfilesTableFilterComposer,
      $$WeaponPreservationProfilesTableOrderingComposer,
      $$WeaponPreservationProfilesTableAnnotationComposer,
      $$WeaponPreservationProfilesTableCreateCompanionBuilder,
      $$WeaponPreservationProfilesTableUpdateCompanionBuilder,
      (
        WeaponPreservationProfile,
        BaseReferences<
          _$ProjectDatabase,
          $WeaponPreservationProfilesTable,
          WeaponPreservationProfile
        >,
      ),
      WeaponPreservationProfile,
      PrefetchHooks Function()
    >;
typedef $$EnvironmentsTableCreateCompanionBuilder =
    EnvironmentsCompanion Function({
      required String assetId,
      required String projectId,
      required String name,
      Value<String> environmentType,
      Value<String> description,
      Value<String> location,
      Value<String> architecture,
      Value<String> terrain,
      Value<String> notes,
      Value<int> rowid,
    });
typedef $$EnvironmentsTableUpdateCompanionBuilder =
    EnvironmentsCompanion Function({
      Value<String> assetId,
      Value<String> projectId,
      Value<String> name,
      Value<String> environmentType,
      Value<String> description,
      Value<String> location,
      Value<String> architecture,
      Value<String> terrain,
      Value<String> notes,
      Value<int> rowid,
    });

class $$EnvironmentsTableFilterComposer
    extends Composer<_$ProjectDatabase, $EnvironmentsTable> {
  $$EnvironmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get environmentType => $composableBuilder(
    column: $table.environmentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get architecture => $composableBuilder(
    column: $table.architecture,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get terrain => $composableBuilder(
    column: $table.terrain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EnvironmentsTableOrderingComposer
    extends Composer<_$ProjectDatabase, $EnvironmentsTable> {
  $$EnvironmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get environmentType => $composableBuilder(
    column: $table.environmentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get architecture => $composableBuilder(
    column: $table.architecture,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get terrain => $composableBuilder(
    column: $table.terrain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EnvironmentsTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $EnvironmentsTable> {
  $$EnvironmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get assetId =>
      $composableBuilder(column: $table.assetId, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get environmentType => $composableBuilder(
    column: $table.environmentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get architecture => $composableBuilder(
    column: $table.architecture,
    builder: (column) => column,
  );

  GeneratedColumn<String> get terrain =>
      $composableBuilder(column: $table.terrain, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$EnvironmentsTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $EnvironmentsTable,
          Environment,
          $$EnvironmentsTableFilterComposer,
          $$EnvironmentsTableOrderingComposer,
          $$EnvironmentsTableAnnotationComposer,
          $$EnvironmentsTableCreateCompanionBuilder,
          $$EnvironmentsTableUpdateCompanionBuilder,
          (
            Environment,
            BaseReferences<_$ProjectDatabase, $EnvironmentsTable, Environment>,
          ),
          Environment,
          PrefetchHooks Function()
        > {
  $$EnvironmentsTableTableManager(
    _$ProjectDatabase db,
    $EnvironmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EnvironmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EnvironmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EnvironmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> assetId = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> environmentType = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<String> architecture = const Value.absent(),
                Value<String> terrain = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EnvironmentsCompanion(
                assetId: assetId,
                projectId: projectId,
                name: name,
                environmentType: environmentType,
                description: description,
                location: location,
                architecture: architecture,
                terrain: terrain,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String assetId,
                required String projectId,
                required String name,
                Value<String> environmentType = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<String> architecture = const Value.absent(),
                Value<String> terrain = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EnvironmentsCompanion.insert(
                assetId: assetId,
                projectId: projectId,
                name: name,
                environmentType: environmentType,
                description: description,
                location: location,
                architecture: architecture,
                terrain: terrain,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EnvironmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $EnvironmentsTable,
      Environment,
      $$EnvironmentsTableFilterComposer,
      $$EnvironmentsTableOrderingComposer,
      $$EnvironmentsTableAnnotationComposer,
      $$EnvironmentsTableCreateCompanionBuilder,
      $$EnvironmentsTableUpdateCompanionBuilder,
      (
        Environment,
        BaseReferences<_$ProjectDatabase, $EnvironmentsTable, Environment>,
      ),
      Environment,
      PrefetchHooks Function()
    >;
typedef $$EnvironmentZonesTableCreateCompanionBuilder =
    EnvironmentZonesCompanion Function({
      required String id,
      required String environmentId,
      required String name,
      Value<String> description,
      Value<String> zoneType,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$EnvironmentZonesTableUpdateCompanionBuilder =
    EnvironmentZonesCompanion Function({
      Value<String> id,
      Value<String> environmentId,
      Value<String> name,
      Value<String> description,
      Value<String> zoneType,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$EnvironmentZonesTableFilterComposer
    extends Composer<_$ProjectDatabase, $EnvironmentZonesTable> {
  $$EnvironmentZonesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get environmentId => $composableBuilder(
    column: $table.environmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zoneType => $composableBuilder(
    column: $table.zoneType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EnvironmentZonesTableOrderingComposer
    extends Composer<_$ProjectDatabase, $EnvironmentZonesTable> {
  $$EnvironmentZonesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get environmentId => $composableBuilder(
    column: $table.environmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zoneType => $composableBuilder(
    column: $table.zoneType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EnvironmentZonesTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $EnvironmentZonesTable> {
  $$EnvironmentZonesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get environmentId => $composableBuilder(
    column: $table.environmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get zoneType =>
      $composableBuilder(column: $table.zoneType, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$EnvironmentZonesTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $EnvironmentZonesTable,
          EnvironmentZone,
          $$EnvironmentZonesTableFilterComposer,
          $$EnvironmentZonesTableOrderingComposer,
          $$EnvironmentZonesTableAnnotationComposer,
          $$EnvironmentZonesTableCreateCompanionBuilder,
          $$EnvironmentZonesTableUpdateCompanionBuilder,
          (
            EnvironmentZone,
            BaseReferences<
              _$ProjectDatabase,
              $EnvironmentZonesTable,
              EnvironmentZone
            >,
          ),
          EnvironmentZone,
          PrefetchHooks Function()
        > {
  $$EnvironmentZonesTableTableManager(
    _$ProjectDatabase db,
    $EnvironmentZonesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EnvironmentZonesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EnvironmentZonesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EnvironmentZonesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> environmentId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> zoneType = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EnvironmentZonesCompanion(
                id: id,
                environmentId: environmentId,
                name: name,
                description: description,
                zoneType: zoneType,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String environmentId,
                required String name,
                Value<String> description = const Value.absent(),
                Value<String> zoneType = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EnvironmentZonesCompanion.insert(
                id: id,
                environmentId: environmentId,
                name: name,
                description: description,
                zoneType: zoneType,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EnvironmentZonesTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $EnvironmentZonesTable,
      EnvironmentZone,
      $$EnvironmentZonesTableFilterComposer,
      $$EnvironmentZonesTableOrderingComposer,
      $$EnvironmentZonesTableAnnotationComposer,
      $$EnvironmentZonesTableCreateCompanionBuilder,
      $$EnvironmentZonesTableUpdateCompanionBuilder,
      (
        EnvironmentZone,
        BaseReferences<
          _$ProjectDatabase,
          $EnvironmentZonesTable,
          EnvironmentZone
        >,
      ),
      EnvironmentZone,
      PrefetchHooks Function()
    >;
typedef $$EnvironmentArchitecturesTableCreateCompanionBuilder =
    EnvironmentArchitecturesCompanion Function({
      required String environmentId,
      Value<String> style,
      Value<String> structure,
      Value<String> materials,
      Value<String> scale,
      Value<String> condition,
      Value<int> rowid,
    });
typedef $$EnvironmentArchitecturesTableUpdateCompanionBuilder =
    EnvironmentArchitecturesCompanion Function({
      Value<String> environmentId,
      Value<String> style,
      Value<String> structure,
      Value<String> materials,
      Value<String> scale,
      Value<String> condition,
      Value<int> rowid,
    });

class $$EnvironmentArchitecturesTableFilterComposer
    extends Composer<_$ProjectDatabase, $EnvironmentArchitecturesTable> {
  $$EnvironmentArchitecturesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get environmentId => $composableBuilder(
    column: $table.environmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get structure => $composableBuilder(
    column: $table.structure,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get materials => $composableBuilder(
    column: $table.materials,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scale => $composableBuilder(
    column: $table.scale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EnvironmentArchitecturesTableOrderingComposer
    extends Composer<_$ProjectDatabase, $EnvironmentArchitecturesTable> {
  $$EnvironmentArchitecturesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get environmentId => $composableBuilder(
    column: $table.environmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get structure => $composableBuilder(
    column: $table.structure,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get materials => $composableBuilder(
    column: $table.materials,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scale => $composableBuilder(
    column: $table.scale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EnvironmentArchitecturesTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $EnvironmentArchitecturesTable> {
  $$EnvironmentArchitecturesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get environmentId => $composableBuilder(
    column: $table.environmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get style =>
      $composableBuilder(column: $table.style, builder: (column) => column);

  GeneratedColumn<String> get structure =>
      $composableBuilder(column: $table.structure, builder: (column) => column);

  GeneratedColumn<String> get materials =>
      $composableBuilder(column: $table.materials, builder: (column) => column);

  GeneratedColumn<String> get scale =>
      $composableBuilder(column: $table.scale, builder: (column) => column);

  GeneratedColumn<String> get condition =>
      $composableBuilder(column: $table.condition, builder: (column) => column);
}

class $$EnvironmentArchitecturesTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $EnvironmentArchitecturesTable,
          EnvironmentArchitecture,
          $$EnvironmentArchitecturesTableFilterComposer,
          $$EnvironmentArchitecturesTableOrderingComposer,
          $$EnvironmentArchitecturesTableAnnotationComposer,
          $$EnvironmentArchitecturesTableCreateCompanionBuilder,
          $$EnvironmentArchitecturesTableUpdateCompanionBuilder,
          (
            EnvironmentArchitecture,
            BaseReferences<
              _$ProjectDatabase,
              $EnvironmentArchitecturesTable,
              EnvironmentArchitecture
            >,
          ),
          EnvironmentArchitecture,
          PrefetchHooks Function()
        > {
  $$EnvironmentArchitecturesTableTableManager(
    _$ProjectDatabase db,
    $EnvironmentArchitecturesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EnvironmentArchitecturesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$EnvironmentArchitecturesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$EnvironmentArchitecturesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> environmentId = const Value.absent(),
                Value<String> style = const Value.absent(),
                Value<String> structure = const Value.absent(),
                Value<String> materials = const Value.absent(),
                Value<String> scale = const Value.absent(),
                Value<String> condition = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EnvironmentArchitecturesCompanion(
                environmentId: environmentId,
                style: style,
                structure: structure,
                materials: materials,
                scale: scale,
                condition: condition,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String environmentId,
                Value<String> style = const Value.absent(),
                Value<String> structure = const Value.absent(),
                Value<String> materials = const Value.absent(),
                Value<String> scale = const Value.absent(),
                Value<String> condition = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EnvironmentArchitecturesCompanion.insert(
                environmentId: environmentId,
                style: style,
                structure: structure,
                materials: materials,
                scale: scale,
                condition: condition,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EnvironmentArchitecturesTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $EnvironmentArchitecturesTable,
      EnvironmentArchitecture,
      $$EnvironmentArchitecturesTableFilterComposer,
      $$EnvironmentArchitecturesTableOrderingComposer,
      $$EnvironmentArchitecturesTableAnnotationComposer,
      $$EnvironmentArchitecturesTableCreateCompanionBuilder,
      $$EnvironmentArchitecturesTableUpdateCompanionBuilder,
      (
        EnvironmentArchitecture,
        BaseReferences<
          _$ProjectDatabase,
          $EnvironmentArchitecturesTable,
          EnvironmentArchitecture
        >,
      ),
      EnvironmentArchitecture,
      PrefetchHooks Function()
    >;
typedef $$EnvironmentWeatherProfilesTableCreateCompanionBuilder =
    EnvironmentWeatherProfilesCompanion Function({
      required String id,
      required String environmentId,
      required String name,
      required String weatherPreset,
      Value<double> intensity,
      Value<double> windStrength,
      Value<double> visibility,
      Value<bool> isDefault,
      Value<int> rowid,
    });
typedef $$EnvironmentWeatherProfilesTableUpdateCompanionBuilder =
    EnvironmentWeatherProfilesCompanion Function({
      Value<String> id,
      Value<String> environmentId,
      Value<String> name,
      Value<String> weatherPreset,
      Value<double> intensity,
      Value<double> windStrength,
      Value<double> visibility,
      Value<bool> isDefault,
      Value<int> rowid,
    });

class $$EnvironmentWeatherProfilesTableFilterComposer
    extends Composer<_$ProjectDatabase, $EnvironmentWeatherProfilesTable> {
  $$EnvironmentWeatherProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get environmentId => $composableBuilder(
    column: $table.environmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weatherPreset => $composableBuilder(
    column: $table.weatherPreset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get intensity => $composableBuilder(
    column: $table.intensity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get windStrength => $composableBuilder(
    column: $table.windStrength,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EnvironmentWeatherProfilesTableOrderingComposer
    extends Composer<_$ProjectDatabase, $EnvironmentWeatherProfilesTable> {
  $$EnvironmentWeatherProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get environmentId => $composableBuilder(
    column: $table.environmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weatherPreset => $composableBuilder(
    column: $table.weatherPreset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get intensity => $composableBuilder(
    column: $table.intensity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get windStrength => $composableBuilder(
    column: $table.windStrength,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EnvironmentWeatherProfilesTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $EnvironmentWeatherProfilesTable> {
  $$EnvironmentWeatherProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get environmentId => $composableBuilder(
    column: $table.environmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get weatherPreset => $composableBuilder(
    column: $table.weatherPreset,
    builder: (column) => column,
  );

  GeneratedColumn<double> get intensity =>
      $composableBuilder(column: $table.intensity, builder: (column) => column);

  GeneratedColumn<double> get windStrength => $composableBuilder(
    column: $table.windStrength,
    builder: (column) => column,
  );

  GeneratedColumn<double> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);
}

class $$EnvironmentWeatherProfilesTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $EnvironmentWeatherProfilesTable,
          EnvironmentWeatherProfile,
          $$EnvironmentWeatherProfilesTableFilterComposer,
          $$EnvironmentWeatherProfilesTableOrderingComposer,
          $$EnvironmentWeatherProfilesTableAnnotationComposer,
          $$EnvironmentWeatherProfilesTableCreateCompanionBuilder,
          $$EnvironmentWeatherProfilesTableUpdateCompanionBuilder,
          (
            EnvironmentWeatherProfile,
            BaseReferences<
              _$ProjectDatabase,
              $EnvironmentWeatherProfilesTable,
              EnvironmentWeatherProfile
            >,
          ),
          EnvironmentWeatherProfile,
          PrefetchHooks Function()
        > {
  $$EnvironmentWeatherProfilesTableTableManager(
    _$ProjectDatabase db,
    $EnvironmentWeatherProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EnvironmentWeatherProfilesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$EnvironmentWeatherProfilesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$EnvironmentWeatherProfilesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> environmentId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> weatherPreset = const Value.absent(),
                Value<double> intensity = const Value.absent(),
                Value<double> windStrength = const Value.absent(),
                Value<double> visibility = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EnvironmentWeatherProfilesCompanion(
                id: id,
                environmentId: environmentId,
                name: name,
                weatherPreset: weatherPreset,
                intensity: intensity,
                windStrength: windStrength,
                visibility: visibility,
                isDefault: isDefault,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String environmentId,
                required String name,
                required String weatherPreset,
                Value<double> intensity = const Value.absent(),
                Value<double> windStrength = const Value.absent(),
                Value<double> visibility = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EnvironmentWeatherProfilesCompanion.insert(
                id: id,
                environmentId: environmentId,
                name: name,
                weatherPreset: weatherPreset,
                intensity: intensity,
                windStrength: windStrength,
                visibility: visibility,
                isDefault: isDefault,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EnvironmentWeatherProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $EnvironmentWeatherProfilesTable,
      EnvironmentWeatherProfile,
      $$EnvironmentWeatherProfilesTableFilterComposer,
      $$EnvironmentWeatherProfilesTableOrderingComposer,
      $$EnvironmentWeatherProfilesTableAnnotationComposer,
      $$EnvironmentWeatherProfilesTableCreateCompanionBuilder,
      $$EnvironmentWeatherProfilesTableUpdateCompanionBuilder,
      (
        EnvironmentWeatherProfile,
        BaseReferences<
          _$ProjectDatabase,
          $EnvironmentWeatherProfilesTable,
          EnvironmentWeatherProfile
        >,
      ),
      EnvironmentWeatherProfile,
      PrefetchHooks Function()
    >;
typedef $$EnvironmentLightingProfilesTableCreateCompanionBuilder =
    EnvironmentLightingProfilesCompanion Function({
      required String id,
      required String environmentId,
      required String name,
      required String timePreset,
      Value<String> keyLight,
      Value<String> fillLight,
      Value<String> rimLight,
      Value<String> environmentLight,
      Value<String> practicalLights,
      Value<double> fogDensity,
      Value<double> bloomIntensity,
      Value<int> rowid,
    });
typedef $$EnvironmentLightingProfilesTableUpdateCompanionBuilder =
    EnvironmentLightingProfilesCompanion Function({
      Value<String> id,
      Value<String> environmentId,
      Value<String> name,
      Value<String> timePreset,
      Value<String> keyLight,
      Value<String> fillLight,
      Value<String> rimLight,
      Value<String> environmentLight,
      Value<String> practicalLights,
      Value<double> fogDensity,
      Value<double> bloomIntensity,
      Value<int> rowid,
    });

class $$EnvironmentLightingProfilesTableFilterComposer
    extends Composer<_$ProjectDatabase, $EnvironmentLightingProfilesTable> {
  $$EnvironmentLightingProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get environmentId => $composableBuilder(
    column: $table.environmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timePreset => $composableBuilder(
    column: $table.timePreset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keyLight => $composableBuilder(
    column: $table.keyLight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fillLight => $composableBuilder(
    column: $table.fillLight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rimLight => $composableBuilder(
    column: $table.rimLight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get environmentLight => $composableBuilder(
    column: $table.environmentLight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get practicalLights => $composableBuilder(
    column: $table.practicalLights,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fogDensity => $composableBuilder(
    column: $table.fogDensity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bloomIntensity => $composableBuilder(
    column: $table.bloomIntensity,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EnvironmentLightingProfilesTableOrderingComposer
    extends Composer<_$ProjectDatabase, $EnvironmentLightingProfilesTable> {
  $$EnvironmentLightingProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get environmentId => $composableBuilder(
    column: $table.environmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timePreset => $composableBuilder(
    column: $table.timePreset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keyLight => $composableBuilder(
    column: $table.keyLight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fillLight => $composableBuilder(
    column: $table.fillLight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rimLight => $composableBuilder(
    column: $table.rimLight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get environmentLight => $composableBuilder(
    column: $table.environmentLight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get practicalLights => $composableBuilder(
    column: $table.practicalLights,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fogDensity => $composableBuilder(
    column: $table.fogDensity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bloomIntensity => $composableBuilder(
    column: $table.bloomIntensity,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EnvironmentLightingProfilesTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $EnvironmentLightingProfilesTable> {
  $$EnvironmentLightingProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get environmentId => $composableBuilder(
    column: $table.environmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get timePreset => $composableBuilder(
    column: $table.timePreset,
    builder: (column) => column,
  );

  GeneratedColumn<String> get keyLight =>
      $composableBuilder(column: $table.keyLight, builder: (column) => column);

  GeneratedColumn<String> get fillLight =>
      $composableBuilder(column: $table.fillLight, builder: (column) => column);

  GeneratedColumn<String> get rimLight =>
      $composableBuilder(column: $table.rimLight, builder: (column) => column);

  GeneratedColumn<String> get environmentLight => $composableBuilder(
    column: $table.environmentLight,
    builder: (column) => column,
  );

  GeneratedColumn<String> get practicalLights => $composableBuilder(
    column: $table.practicalLights,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fogDensity => $composableBuilder(
    column: $table.fogDensity,
    builder: (column) => column,
  );

  GeneratedColumn<double> get bloomIntensity => $composableBuilder(
    column: $table.bloomIntensity,
    builder: (column) => column,
  );
}

class $$EnvironmentLightingProfilesTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $EnvironmentLightingProfilesTable,
          EnvironmentLightingProfile,
          $$EnvironmentLightingProfilesTableFilterComposer,
          $$EnvironmentLightingProfilesTableOrderingComposer,
          $$EnvironmentLightingProfilesTableAnnotationComposer,
          $$EnvironmentLightingProfilesTableCreateCompanionBuilder,
          $$EnvironmentLightingProfilesTableUpdateCompanionBuilder,
          (
            EnvironmentLightingProfile,
            BaseReferences<
              _$ProjectDatabase,
              $EnvironmentLightingProfilesTable,
              EnvironmentLightingProfile
            >,
          ),
          EnvironmentLightingProfile,
          PrefetchHooks Function()
        > {
  $$EnvironmentLightingProfilesTableTableManager(
    _$ProjectDatabase db,
    $EnvironmentLightingProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EnvironmentLightingProfilesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$EnvironmentLightingProfilesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$EnvironmentLightingProfilesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> environmentId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> timePreset = const Value.absent(),
                Value<String> keyLight = const Value.absent(),
                Value<String> fillLight = const Value.absent(),
                Value<String> rimLight = const Value.absent(),
                Value<String> environmentLight = const Value.absent(),
                Value<String> practicalLights = const Value.absent(),
                Value<double> fogDensity = const Value.absent(),
                Value<double> bloomIntensity = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EnvironmentLightingProfilesCompanion(
                id: id,
                environmentId: environmentId,
                name: name,
                timePreset: timePreset,
                keyLight: keyLight,
                fillLight: fillLight,
                rimLight: rimLight,
                environmentLight: environmentLight,
                practicalLights: practicalLights,
                fogDensity: fogDensity,
                bloomIntensity: bloomIntensity,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String environmentId,
                required String name,
                required String timePreset,
                Value<String> keyLight = const Value.absent(),
                Value<String> fillLight = const Value.absent(),
                Value<String> rimLight = const Value.absent(),
                Value<String> environmentLight = const Value.absent(),
                Value<String> practicalLights = const Value.absent(),
                Value<double> fogDensity = const Value.absent(),
                Value<double> bloomIntensity = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EnvironmentLightingProfilesCompanion.insert(
                id: id,
                environmentId: environmentId,
                name: name,
                timePreset: timePreset,
                keyLight: keyLight,
                fillLight: fillLight,
                rimLight: rimLight,
                environmentLight: environmentLight,
                practicalLights: practicalLights,
                fogDensity: fogDensity,
                bloomIntensity: bloomIntensity,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EnvironmentLightingProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $EnvironmentLightingProfilesTable,
      EnvironmentLightingProfile,
      $$EnvironmentLightingProfilesTableFilterComposer,
      $$EnvironmentLightingProfilesTableOrderingComposer,
      $$EnvironmentLightingProfilesTableAnnotationComposer,
      $$EnvironmentLightingProfilesTableCreateCompanionBuilder,
      $$EnvironmentLightingProfilesTableUpdateCompanionBuilder,
      (
        EnvironmentLightingProfile,
        BaseReferences<
          _$ProjectDatabase,
          $EnvironmentLightingProfilesTable,
          EnvironmentLightingProfile
        >,
      ),
      EnvironmentLightingProfile,
      PrefetchHooks Function()
    >;
typedef $$EnvironmentColorsTableCreateCompanionBuilder =
    EnvironmentColorsCompanion Function({
      required String id,
      required String environmentId,
      required String name,
      required String hexValue,
      Value<String> usage,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$EnvironmentColorsTableUpdateCompanionBuilder =
    EnvironmentColorsCompanion Function({
      Value<String> id,
      Value<String> environmentId,
      Value<String> name,
      Value<String> hexValue,
      Value<String> usage,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$EnvironmentColorsTableFilterComposer
    extends Composer<_$ProjectDatabase, $EnvironmentColorsTable> {
  $$EnvironmentColorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get environmentId => $composableBuilder(
    column: $table.environmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hexValue => $composableBuilder(
    column: $table.hexValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get usage => $composableBuilder(
    column: $table.usage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EnvironmentColorsTableOrderingComposer
    extends Composer<_$ProjectDatabase, $EnvironmentColorsTable> {
  $$EnvironmentColorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get environmentId => $composableBuilder(
    column: $table.environmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hexValue => $composableBuilder(
    column: $table.hexValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get usage => $composableBuilder(
    column: $table.usage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EnvironmentColorsTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $EnvironmentColorsTable> {
  $$EnvironmentColorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get environmentId => $composableBuilder(
    column: $table.environmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get hexValue =>
      $composableBuilder(column: $table.hexValue, builder: (column) => column);

  GeneratedColumn<String> get usage =>
      $composableBuilder(column: $table.usage, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$EnvironmentColorsTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $EnvironmentColorsTable,
          EnvironmentColor,
          $$EnvironmentColorsTableFilterComposer,
          $$EnvironmentColorsTableOrderingComposer,
          $$EnvironmentColorsTableAnnotationComposer,
          $$EnvironmentColorsTableCreateCompanionBuilder,
          $$EnvironmentColorsTableUpdateCompanionBuilder,
          (
            EnvironmentColor,
            BaseReferences<
              _$ProjectDatabase,
              $EnvironmentColorsTable,
              EnvironmentColor
            >,
          ),
          EnvironmentColor,
          PrefetchHooks Function()
        > {
  $$EnvironmentColorsTableTableManager(
    _$ProjectDatabase db,
    $EnvironmentColorsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EnvironmentColorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EnvironmentColorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EnvironmentColorsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> environmentId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> hexValue = const Value.absent(),
                Value<String> usage = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EnvironmentColorsCompanion(
                id: id,
                environmentId: environmentId,
                name: name,
                hexValue: hexValue,
                usage: usage,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String environmentId,
                required String name,
                required String hexValue,
                Value<String> usage = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EnvironmentColorsCompanion.insert(
                id: id,
                environmentId: environmentId,
                name: name,
                hexValue: hexValue,
                usage: usage,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EnvironmentColorsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $EnvironmentColorsTable,
      EnvironmentColor,
      $$EnvironmentColorsTableFilterComposer,
      $$EnvironmentColorsTableOrderingComposer,
      $$EnvironmentColorsTableAnnotationComposer,
      $$EnvironmentColorsTableCreateCompanionBuilder,
      $$EnvironmentColorsTableUpdateCompanionBuilder,
      (
        EnvironmentColor,
        BaseReferences<
          _$ProjectDatabase,
          $EnvironmentColorsTable,
          EnvironmentColor
        >,
      ),
      EnvironmentColor,
      PrefetchHooks Function()
    >;
typedef $$EnvironmentPropsTableCreateCompanionBuilder =
    EnvironmentPropsCompanion Function({
      required String id,
      required String environmentId,
      Value<String?> zoneId,
      required String name,
      Value<String> propType,
      Value<String> state,
      Value<String> positionNote,
      Value<int> rowid,
    });
typedef $$EnvironmentPropsTableUpdateCompanionBuilder =
    EnvironmentPropsCompanion Function({
      Value<String> id,
      Value<String> environmentId,
      Value<String?> zoneId,
      Value<String> name,
      Value<String> propType,
      Value<String> state,
      Value<String> positionNote,
      Value<int> rowid,
    });

class $$EnvironmentPropsTableFilterComposer
    extends Composer<_$ProjectDatabase, $EnvironmentPropsTable> {
  $$EnvironmentPropsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get environmentId => $composableBuilder(
    column: $table.environmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zoneId => $composableBuilder(
    column: $table.zoneId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get propType => $composableBuilder(
    column: $table.propType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get positionNote => $composableBuilder(
    column: $table.positionNote,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EnvironmentPropsTableOrderingComposer
    extends Composer<_$ProjectDatabase, $EnvironmentPropsTable> {
  $$EnvironmentPropsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get environmentId => $composableBuilder(
    column: $table.environmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zoneId => $composableBuilder(
    column: $table.zoneId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get propType => $composableBuilder(
    column: $table.propType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get positionNote => $composableBuilder(
    column: $table.positionNote,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EnvironmentPropsTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $EnvironmentPropsTable> {
  $$EnvironmentPropsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get environmentId => $composableBuilder(
    column: $table.environmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get zoneId =>
      $composableBuilder(column: $table.zoneId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get propType =>
      $composableBuilder(column: $table.propType, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get positionNote => $composableBuilder(
    column: $table.positionNote,
    builder: (column) => column,
  );
}

class $$EnvironmentPropsTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $EnvironmentPropsTable,
          EnvironmentProp,
          $$EnvironmentPropsTableFilterComposer,
          $$EnvironmentPropsTableOrderingComposer,
          $$EnvironmentPropsTableAnnotationComposer,
          $$EnvironmentPropsTableCreateCompanionBuilder,
          $$EnvironmentPropsTableUpdateCompanionBuilder,
          (
            EnvironmentProp,
            BaseReferences<
              _$ProjectDatabase,
              $EnvironmentPropsTable,
              EnvironmentProp
            >,
          ),
          EnvironmentProp,
          PrefetchHooks Function()
        > {
  $$EnvironmentPropsTableTableManager(
    _$ProjectDatabase db,
    $EnvironmentPropsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EnvironmentPropsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EnvironmentPropsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EnvironmentPropsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> environmentId = const Value.absent(),
                Value<String?> zoneId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> propType = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String> positionNote = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EnvironmentPropsCompanion(
                id: id,
                environmentId: environmentId,
                zoneId: zoneId,
                name: name,
                propType: propType,
                state: state,
                positionNote: positionNote,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String environmentId,
                Value<String?> zoneId = const Value.absent(),
                required String name,
                Value<String> propType = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String> positionNote = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EnvironmentPropsCompanion.insert(
                id: id,
                environmentId: environmentId,
                zoneId: zoneId,
                name: name,
                propType: propType,
                state: state,
                positionNote: positionNote,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EnvironmentPropsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $EnvironmentPropsTable,
      EnvironmentProp,
      $$EnvironmentPropsTableFilterComposer,
      $$EnvironmentPropsTableOrderingComposer,
      $$EnvironmentPropsTableAnnotationComposer,
      $$EnvironmentPropsTableCreateCompanionBuilder,
      $$EnvironmentPropsTableUpdateCompanionBuilder,
      (
        EnvironmentProp,
        BaseReferences<
          _$ProjectDatabase,
          $EnvironmentPropsTable,
          EnvironmentProp
        >,
      ),
      EnvironmentProp,
      PrefetchHooks Function()
    >;
typedef $$EnvironmentContinuityStatesTableCreateCompanionBuilder =
    EnvironmentContinuityStatesCompanion Function({
      required String id,
      required String environmentId,
      required String name,
      Value<String> description,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$EnvironmentContinuityStatesTableUpdateCompanionBuilder =
    EnvironmentContinuityStatesCompanion Function({
      Value<String> id,
      Value<String> environmentId,
      Value<String> name,
      Value<String> description,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$EnvironmentContinuityStatesTableFilterComposer
    extends Composer<_$ProjectDatabase, $EnvironmentContinuityStatesTable> {
  $$EnvironmentContinuityStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get environmentId => $composableBuilder(
    column: $table.environmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EnvironmentContinuityStatesTableOrderingComposer
    extends Composer<_$ProjectDatabase, $EnvironmentContinuityStatesTable> {
  $$EnvironmentContinuityStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get environmentId => $composableBuilder(
    column: $table.environmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EnvironmentContinuityStatesTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $EnvironmentContinuityStatesTable> {
  $$EnvironmentContinuityStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get environmentId => $composableBuilder(
    column: $table.environmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$EnvironmentContinuityStatesTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $EnvironmentContinuityStatesTable,
          EnvironmentContinuityState,
          $$EnvironmentContinuityStatesTableFilterComposer,
          $$EnvironmentContinuityStatesTableOrderingComposer,
          $$EnvironmentContinuityStatesTableAnnotationComposer,
          $$EnvironmentContinuityStatesTableCreateCompanionBuilder,
          $$EnvironmentContinuityStatesTableUpdateCompanionBuilder,
          (
            EnvironmentContinuityState,
            BaseReferences<
              _$ProjectDatabase,
              $EnvironmentContinuityStatesTable,
              EnvironmentContinuityState
            >,
          ),
          EnvironmentContinuityState,
          PrefetchHooks Function()
        > {
  $$EnvironmentContinuityStatesTableTableManager(
    _$ProjectDatabase db,
    $EnvironmentContinuityStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EnvironmentContinuityStatesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$EnvironmentContinuityStatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$EnvironmentContinuityStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> environmentId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EnvironmentContinuityStatesCompanion(
                id: id,
                environmentId: environmentId,
                name: name,
                description: description,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String environmentId,
                required String name,
                Value<String> description = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => EnvironmentContinuityStatesCompanion.insert(
                id: id,
                environmentId: environmentId,
                name: name,
                description: description,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EnvironmentContinuityStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $EnvironmentContinuityStatesTable,
      EnvironmentContinuityState,
      $$EnvironmentContinuityStatesTableFilterComposer,
      $$EnvironmentContinuityStatesTableOrderingComposer,
      $$EnvironmentContinuityStatesTableAnnotationComposer,
      $$EnvironmentContinuityStatesTableCreateCompanionBuilder,
      $$EnvironmentContinuityStatesTableUpdateCompanionBuilder,
      (
        EnvironmentContinuityState,
        BaseReferences<
          _$ProjectDatabase,
          $EnvironmentContinuityStatesTable,
          EnvironmentContinuityState
        >,
      ),
      EnvironmentContinuityState,
      PrefetchHooks Function()
    >;
typedef $$EnvironmentPhysicsProfilesTableCreateCompanionBuilder =
    EnvironmentPhysicsProfilesCompanion Function({
      required String environmentId,
      Value<double> gravityMultiplier,
      Value<bool> floatingObjects,
      Value<String> dimensionalDistortion,
      Value<String> portalBehavior,
      Value<String> notes,
      Value<int> rowid,
    });
typedef $$EnvironmentPhysicsProfilesTableUpdateCompanionBuilder =
    EnvironmentPhysicsProfilesCompanion Function({
      Value<String> environmentId,
      Value<double> gravityMultiplier,
      Value<bool> floatingObjects,
      Value<String> dimensionalDistortion,
      Value<String> portalBehavior,
      Value<String> notes,
      Value<int> rowid,
    });

class $$EnvironmentPhysicsProfilesTableFilterComposer
    extends Composer<_$ProjectDatabase, $EnvironmentPhysicsProfilesTable> {
  $$EnvironmentPhysicsProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get environmentId => $composableBuilder(
    column: $table.environmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get gravityMultiplier => $composableBuilder(
    column: $table.gravityMultiplier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get floatingObjects => $composableBuilder(
    column: $table.floatingObjects,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dimensionalDistortion => $composableBuilder(
    column: $table.dimensionalDistortion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get portalBehavior => $composableBuilder(
    column: $table.portalBehavior,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EnvironmentPhysicsProfilesTableOrderingComposer
    extends Composer<_$ProjectDatabase, $EnvironmentPhysicsProfilesTable> {
  $$EnvironmentPhysicsProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get environmentId => $composableBuilder(
    column: $table.environmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gravityMultiplier => $composableBuilder(
    column: $table.gravityMultiplier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get floatingObjects => $composableBuilder(
    column: $table.floatingObjects,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dimensionalDistortion => $composableBuilder(
    column: $table.dimensionalDistortion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get portalBehavior => $composableBuilder(
    column: $table.portalBehavior,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EnvironmentPhysicsProfilesTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $EnvironmentPhysicsProfilesTable> {
  $$EnvironmentPhysicsProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get environmentId => $composableBuilder(
    column: $table.environmentId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get gravityMultiplier => $composableBuilder(
    column: $table.gravityMultiplier,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get floatingObjects => $composableBuilder(
    column: $table.floatingObjects,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dimensionalDistortion => $composableBuilder(
    column: $table.dimensionalDistortion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get portalBehavior => $composableBuilder(
    column: $table.portalBehavior,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$EnvironmentPhysicsProfilesTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $EnvironmentPhysicsProfilesTable,
          EnvironmentPhysicsProfile,
          $$EnvironmentPhysicsProfilesTableFilterComposer,
          $$EnvironmentPhysicsProfilesTableOrderingComposer,
          $$EnvironmentPhysicsProfilesTableAnnotationComposer,
          $$EnvironmentPhysicsProfilesTableCreateCompanionBuilder,
          $$EnvironmentPhysicsProfilesTableUpdateCompanionBuilder,
          (
            EnvironmentPhysicsProfile,
            BaseReferences<
              _$ProjectDatabase,
              $EnvironmentPhysicsProfilesTable,
              EnvironmentPhysicsProfile
            >,
          ),
          EnvironmentPhysicsProfile,
          PrefetchHooks Function()
        > {
  $$EnvironmentPhysicsProfilesTableTableManager(
    _$ProjectDatabase db,
    $EnvironmentPhysicsProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EnvironmentPhysicsProfilesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$EnvironmentPhysicsProfilesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$EnvironmentPhysicsProfilesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> environmentId = const Value.absent(),
                Value<double> gravityMultiplier = const Value.absent(),
                Value<bool> floatingObjects = const Value.absent(),
                Value<String> dimensionalDistortion = const Value.absent(),
                Value<String> portalBehavior = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EnvironmentPhysicsProfilesCompanion(
                environmentId: environmentId,
                gravityMultiplier: gravityMultiplier,
                floatingObjects: floatingObjects,
                dimensionalDistortion: dimensionalDistortion,
                portalBehavior: portalBehavior,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String environmentId,
                Value<double> gravityMultiplier = const Value.absent(),
                Value<bool> floatingObjects = const Value.absent(),
                Value<String> dimensionalDistortion = const Value.absent(),
                Value<String> portalBehavior = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EnvironmentPhysicsProfilesCompanion.insert(
                environmentId: environmentId,
                gravityMultiplier: gravityMultiplier,
                floatingObjects: floatingObjects,
                dimensionalDistortion: dimensionalDistortion,
                portalBehavior: portalBehavior,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EnvironmentPhysicsProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $EnvironmentPhysicsProfilesTable,
      EnvironmentPhysicsProfile,
      $$EnvironmentPhysicsProfilesTableFilterComposer,
      $$EnvironmentPhysicsProfilesTableOrderingComposer,
      $$EnvironmentPhysicsProfilesTableAnnotationComposer,
      $$EnvironmentPhysicsProfilesTableCreateCompanionBuilder,
      $$EnvironmentPhysicsProfilesTableUpdateCompanionBuilder,
      (
        EnvironmentPhysicsProfile,
        BaseReferences<
          _$ProjectDatabase,
          $EnvironmentPhysicsProfilesTable,
          EnvironmentPhysicsProfile
        >,
      ),
      EnvironmentPhysicsProfile,
      PrefetchHooks Function()
    >;
typedef $$EnvironmentReferencesTableCreateCompanionBuilder =
    EnvironmentReferencesCompanion Function({
      required String id,
      required String environmentId,
      required String referenceType,
      required String filePath,
      Value<int> priority,
      Value<bool> primaryReference,
      Value<int> rowid,
    });
typedef $$EnvironmentReferencesTableUpdateCompanionBuilder =
    EnvironmentReferencesCompanion Function({
      Value<String> id,
      Value<String> environmentId,
      Value<String> referenceType,
      Value<String> filePath,
      Value<int> priority,
      Value<bool> primaryReference,
      Value<int> rowid,
    });

class $$EnvironmentReferencesTableFilterComposer
    extends Composer<_$ProjectDatabase, $EnvironmentReferencesTable> {
  $$EnvironmentReferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get environmentId => $composableBuilder(
    column: $table.environmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get primaryReference => $composableBuilder(
    column: $table.primaryReference,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EnvironmentReferencesTableOrderingComposer
    extends Composer<_$ProjectDatabase, $EnvironmentReferencesTable> {
  $$EnvironmentReferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get environmentId => $composableBuilder(
    column: $table.environmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get primaryReference => $composableBuilder(
    column: $table.primaryReference,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EnvironmentReferencesTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $EnvironmentReferencesTable> {
  $$EnvironmentReferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get environmentId => $composableBuilder(
    column: $table.environmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<bool> get primaryReference => $composableBuilder(
    column: $table.primaryReference,
    builder: (column) => column,
  );
}

class $$EnvironmentReferencesTableTableManager
    extends
        RootTableManager<
          _$ProjectDatabase,
          $EnvironmentReferencesTable,
          EnvironmentReference,
          $$EnvironmentReferencesTableFilterComposer,
          $$EnvironmentReferencesTableOrderingComposer,
          $$EnvironmentReferencesTableAnnotationComposer,
          $$EnvironmentReferencesTableCreateCompanionBuilder,
          $$EnvironmentReferencesTableUpdateCompanionBuilder,
          (
            EnvironmentReference,
            BaseReferences<
              _$ProjectDatabase,
              $EnvironmentReferencesTable,
              EnvironmentReference
            >,
          ),
          EnvironmentReference,
          PrefetchHooks Function()
        > {
  $$EnvironmentReferencesTableTableManager(
    _$ProjectDatabase db,
    $EnvironmentReferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EnvironmentReferencesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$EnvironmentReferencesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$EnvironmentReferencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> environmentId = const Value.absent(),
                Value<String> referenceType = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<bool> primaryReference = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EnvironmentReferencesCompanion(
                id: id,
                environmentId: environmentId,
                referenceType: referenceType,
                filePath: filePath,
                priority: priority,
                primaryReference: primaryReference,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String environmentId,
                required String referenceType,
                required String filePath,
                Value<int> priority = const Value.absent(),
                Value<bool> primaryReference = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EnvironmentReferencesCompanion.insert(
                id: id,
                environmentId: environmentId,
                referenceType: referenceType,
                filePath: filePath,
                priority: priority,
                primaryReference: primaryReference,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EnvironmentReferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$ProjectDatabase,
      $EnvironmentReferencesTable,
      EnvironmentReference,
      $$EnvironmentReferencesTableFilterComposer,
      $$EnvironmentReferencesTableOrderingComposer,
      $$EnvironmentReferencesTableAnnotationComposer,
      $$EnvironmentReferencesTableCreateCompanionBuilder,
      $$EnvironmentReferencesTableUpdateCompanionBuilder,
      (
        EnvironmentReference,
        BaseReferences<
          _$ProjectDatabase,
          $EnvironmentReferencesTable,
          EnvironmentReference
        >,
      ),
      EnvironmentReference,
      PrefetchHooks Function()
    >;

class $ProjectDatabaseManager {
  final _$ProjectDatabase _db;
  $ProjectDatabaseManager(this._db);
  $$ProjectMetadataTableTableManager get projectMetadata =>
      $$ProjectMetadataTableTableManager(_db, _db.projectMetadata);
  $$AssetsTableTableManager get assets =>
      $$AssetsTableTableManager(_db, _db.assets);
  $$AssetTagsTableTableManager get assetTags =>
      $$AssetTagsTableTableManager(_db, _db.assetTags);
  $$CharactersTableTableManager get characters =>
      $$CharactersTableTableManager(_db, _db.characters);
  $$CharacterIdentityProfilesTableTableManager get characterIdentityProfiles =>
      $$CharacterIdentityProfilesTableTableManager(
        _db,
        _db.characterIdentityProfiles,
      );
  $$CharacterReferencesTableTableManager get characterReferences =>
      $$CharacterReferencesTableTableManager(_db, _db.characterReferences);
  $$CharacterModesTableTableManager get characterModes =>
      $$CharacterModesTableTableManager(_db, _db.characterModes);
  $$CharacterLoadoutEntriesTableTableManager get characterLoadoutEntries =>
      $$CharacterLoadoutEntriesTableTableManager(
        _db,
        _db.characterLoadoutEntries,
      );
  $$CharacterModeIdentityOverridesTableTableManager
  get characterModeIdentityOverrides =>
      $$CharacterModeIdentityOverridesTableTableManager(
        _db,
        _db.characterModeIdentityOverrides,
      );
  $$CharacterModeReferencesTableTableManager get characterModeReferences =>
      $$CharacterModeReferencesTableTableManager(
        _db,
        _db.characterModeReferences,
      );
  $$AssetRelationsTableTableManager get assetRelations =>
      $$AssetRelationsTableTableManager(_db, _db.assetRelations);
  $$WardrobesTableTableManager get wardrobes =>
      $$WardrobesTableTableManager(_db, _db.wardrobes);
  $$WardrobeComponentsTableTableManager get wardrobeComponents =>
      $$WardrobeComponentsTableTableManager(_db, _db.wardrobeComponents);
  $$WardrobeColorsTableTableManager get wardrobeColors =>
      $$WardrobeColorsTableTableManager(_db, _db.wardrobeColors);
  $$WardrobeVariantsTableTableManager get wardrobeVariants =>
      $$WardrobeVariantsTableTableManager(_db, _db.wardrobeVariants);
  $$WardrobeReferencesTableTableManager get wardrobeReferences =>
      $$WardrobeReferencesTableTableManager(_db, _db.wardrobeReferences);
  $$WeaponsTableTableManager get weapons =>
      $$WeaponsTableTableManager(_db, _db.weapons);
  $$WeaponComponentsTableTableManager get weaponComponents =>
      $$WeaponComponentsTableTableManager(_db, _db.weaponComponents);
  $$WeaponMeasurementsTableTableManager get weaponMeasurements =>
      $$WeaponMeasurementsTableTableManager(_db, _db.weaponMeasurements);
  $$WeaponColorsTableTableManager get weaponColors =>
      $$WeaponColorsTableTableManager(_db, _db.weaponColors);
  $$WeaponEnergyProfilesTableTableManager get weaponEnergyProfiles =>
      $$WeaponEnergyProfilesTableTableManager(_db, _db.weaponEnergyProfiles);
  $$WeaponVariantsTableTableManager get weaponVariants =>
      $$WeaponVariantsTableTableManager(_db, _db.weaponVariants);
  $$WeaponReferencesTableTableManager get weaponReferences =>
      $$WeaponReferencesTableTableManager(_db, _db.weaponReferences);
  $$WeaponPreservationProfilesTableTableManager
  get weaponPreservationProfiles =>
      $$WeaponPreservationProfilesTableTableManager(
        _db,
        _db.weaponPreservationProfiles,
      );
  $$EnvironmentsTableTableManager get environments =>
      $$EnvironmentsTableTableManager(_db, _db.environments);
  $$EnvironmentZonesTableTableManager get environmentZones =>
      $$EnvironmentZonesTableTableManager(_db, _db.environmentZones);
  $$EnvironmentArchitecturesTableTableManager get environmentArchitectures =>
      $$EnvironmentArchitecturesTableTableManager(
        _db,
        _db.environmentArchitectures,
      );
  $$EnvironmentWeatherProfilesTableTableManager
  get environmentWeatherProfiles =>
      $$EnvironmentWeatherProfilesTableTableManager(
        _db,
        _db.environmentWeatherProfiles,
      );
  $$EnvironmentLightingProfilesTableTableManager
  get environmentLightingProfiles =>
      $$EnvironmentLightingProfilesTableTableManager(
        _db,
        _db.environmentLightingProfiles,
      );
  $$EnvironmentColorsTableTableManager get environmentColors =>
      $$EnvironmentColorsTableTableManager(_db, _db.environmentColors);
  $$EnvironmentPropsTableTableManager get environmentProps =>
      $$EnvironmentPropsTableTableManager(_db, _db.environmentProps);
  $$EnvironmentContinuityStatesTableTableManager
  get environmentContinuityStates =>
      $$EnvironmentContinuityStatesTableTableManager(
        _db,
        _db.environmentContinuityStates,
      );
  $$EnvironmentPhysicsProfilesTableTableManager
  get environmentPhysicsProfiles =>
      $$EnvironmentPhysicsProfilesTableTableManager(
        _db,
        _db.environmentPhysicsProfiles,
      );
  $$EnvironmentReferencesTableTableManager get environmentReferences =>
      $$EnvironmentReferencesTableTableManager(_db, _db.environmentReferences);
}
