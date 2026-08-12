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
  @override
  List<GeneratedColumn> get $columns => [
    characterId,
    faceLock,
    hairLock,
    bodyLock,
    colorLock,
    outfitLock,
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
  const CharacterIdentityProfile({
    required this.characterId,
    required this.faceLock,
    required this.hairLock,
    required this.bodyLock,
    required this.colorLock,
    required this.outfitLock,
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
    };
  }

  CharacterIdentityProfile copyWith({
    String? characterId,
    bool? faceLock,
    bool? hairLock,
    bool? bodyLock,
    bool? colorLock,
    bool? outfitLock,
  }) => CharacterIdentityProfile(
    characterId: characterId ?? this.characterId,
    faceLock: faceLock ?? this.faceLock,
    hairLock: hairLock ?? this.hairLock,
    bodyLock: bodyLock ?? this.bodyLock,
    colorLock: colorLock ?? this.colorLock,
    outfitLock: outfitLock ?? this.outfitLock,
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
          ..write('outfitLock: $outfitLock')
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
          other.outfitLock == this.outfitLock);
}

class CharacterIdentityProfilesCompanion
    extends UpdateCompanion<CharacterIdentityProfile> {
  final Value<String> characterId;
  final Value<bool> faceLock;
  final Value<bool> hairLock;
  final Value<bool> bodyLock;
  final Value<bool> colorLock;
  final Value<bool> outfitLock;
  final Value<int> rowid;
  const CharacterIdentityProfilesCompanion({
    this.characterId = const Value.absent(),
    this.faceLock = const Value.absent(),
    this.hairLock = const Value.absent(),
    this.bodyLock = const Value.absent(),
    this.colorLock = const Value.absent(),
    this.outfitLock = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CharacterIdentityProfilesCompanion.insert({
    required String characterId,
    this.faceLock = const Value.absent(),
    this.hairLock = const Value.absent(),
    this.bodyLock = const Value.absent(),
    this.colorLock = const Value.absent(),
    this.outfitLock = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : characterId = Value(characterId);
  static Insertable<CharacterIdentityProfile> custom({
    Expression<String>? characterId,
    Expression<bool>? faceLock,
    Expression<bool>? hairLock,
    Expression<bool>? bodyLock,
    Expression<bool>? colorLock,
    Expression<bool>? outfitLock,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (characterId != null) 'character_id': characterId,
      if (faceLock != null) 'face_lock': faceLock,
      if (hairLock != null) 'hair_lock': hairLock,
      if (bodyLock != null) 'body_lock': bodyLock,
      if (colorLock != null) 'color_lock': colorLock,
      if (outfitLock != null) 'outfit_lock': outfitLock,
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
    Value<int>? rowid,
  }) {
    return CharacterIdentityProfilesCompanion(
      characterId: characterId ?? this.characterId,
      faceLock: faceLock ?? this.faceLock,
      hairLock: hairLock ?? this.hairLock,
      bodyLock: bodyLock ?? this.bodyLock,
      colorLock: colorLock ?? this.colorLock,
      outfitLock: outfitLock ?? this.outfitLock,
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
  final DateTime createdAt;
  const AssetRelation({
    required this.id,
    required this.projectId,
    required this.sourceAssetId,
    required this.targetAssetId,
    required this.relationType,
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
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AssetRelation copyWith({
    String? id,
    String? projectId,
    String? sourceAssetId,
    String? targetAssetId,
    String? relationType,
    DateTime? createdAt,
  }) => AssetRelation(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    sourceAssetId: sourceAssetId ?? this.sourceAssetId,
    targetAssetId: targetAssetId ?? this.targetAssetId,
    relationType: relationType ?? this.relationType,
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
          other.createdAt == this.createdAt);
}

class AssetRelationsCompanion extends UpdateCompanion<AssetRelation> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> sourceAssetId;
  final Value<String> targetAssetId;
  final Value<String> relationType;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AssetRelationsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.sourceAssetId = const Value.absent(),
    this.targetAssetId = const Value.absent(),
    this.relationType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssetRelationsCompanion.insert({
    required String id,
    this.projectId = const Value.absent(),
    required String sourceAssetId,
    required String targetAssetId,
    required String relationType,
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
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (sourceAssetId != null) 'source_asset_id': sourceAssetId,
      if (targetAssetId != null) 'target_asset_id': targetAssetId,
      if (relationType != null) 'relation_type': relationType,
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
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AssetRelationsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      sourceAssetId: sourceAssetId ?? this.sourceAssetId,
      targetAssetId: targetAssetId ?? this.targetAssetId,
      relationType: relationType ?? this.relationType,
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
  late final AssetDao assetDao = AssetDao(this as ProjectDatabase);
  late final CharacterDao characterDao = CharacterDao(this as ProjectDatabase);
  late final RelationDao relationDao = RelationDao(this as ProjectDatabase);
  late final WardrobeDao wardrobeDao = WardrobeDao(this as ProjectDatabase);
  late final WeaponDao weaponDao = WeaponDao(this as ProjectDatabase);
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
                Value<int> rowid = const Value.absent(),
              }) => CharacterIdentityProfilesCompanion(
                characterId: characterId,
                faceLock: faceLock,
                hairLock: hairLock,
                bodyLock: bodyLock,
                colorLock: colorLock,
                outfitLock: outfitLock,
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
                Value<int> rowid = const Value.absent(),
              }) => CharacterIdentityProfilesCompanion.insert(
                characterId: characterId,
                faceLock: faceLock,
                hairLock: hairLock,
                bodyLock: bodyLock,
                colorLock: colorLock,
                outfitLock: outfitLock,
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
typedef $$AssetRelationsTableCreateCompanionBuilder =
    AssetRelationsCompanion Function({
      required String id,
      Value<String> projectId,
      required String sourceAssetId,
      required String targetAssetId,
      required String relationType,
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
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetRelationsCompanion(
                id: id,
                projectId: projectId,
                sourceAssetId: sourceAssetId,
                targetAssetId: targetAssetId,
                relationType: relationType,
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
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetRelationsCompanion.insert(
                id: id,
                projectId: projectId,
                sourceAssetId: sourceAssetId,
                targetAssetId: targetAssetId,
                relationType: relationType,
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
}
