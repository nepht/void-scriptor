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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceAssetId,
    targetAssetId,
    relationType,
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
    );
  }

  @override
  $AssetRelationsTable createAlias(String alias) {
    return $AssetRelationsTable(attachedDatabase, alias);
  }
}

class AssetRelation extends DataClass implements Insertable<AssetRelation> {
  final String id;
  final String sourceAssetId;
  final String targetAssetId;
  final String relationType;
  const AssetRelation({
    required this.id,
    required this.sourceAssetId,
    required this.targetAssetId,
    required this.relationType,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_asset_id'] = Variable<String>(sourceAssetId);
    map['target_asset_id'] = Variable<String>(targetAssetId);
    map['relation_type'] = Variable<String>(relationType);
    return map;
  }

  AssetRelationsCompanion toCompanion(bool nullToAbsent) {
    return AssetRelationsCompanion(
      id: Value(id),
      sourceAssetId: Value(sourceAssetId),
      targetAssetId: Value(targetAssetId),
      relationType: Value(relationType),
    );
  }

  factory AssetRelation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssetRelation(
      id: serializer.fromJson<String>(json['id']),
      sourceAssetId: serializer.fromJson<String>(json['sourceAssetId']),
      targetAssetId: serializer.fromJson<String>(json['targetAssetId']),
      relationType: serializer.fromJson<String>(json['relationType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceAssetId': serializer.toJson<String>(sourceAssetId),
      'targetAssetId': serializer.toJson<String>(targetAssetId),
      'relationType': serializer.toJson<String>(relationType),
    };
  }

  AssetRelation copyWith({
    String? id,
    String? sourceAssetId,
    String? targetAssetId,
    String? relationType,
  }) => AssetRelation(
    id: id ?? this.id,
    sourceAssetId: sourceAssetId ?? this.sourceAssetId,
    targetAssetId: targetAssetId ?? this.targetAssetId,
    relationType: relationType ?? this.relationType,
  );
  AssetRelation copyWithCompanion(AssetRelationsCompanion data) {
    return AssetRelation(
      id: data.id.present ? data.id.value : this.id,
      sourceAssetId: data.sourceAssetId.present
          ? data.sourceAssetId.value
          : this.sourceAssetId,
      targetAssetId: data.targetAssetId.present
          ? data.targetAssetId.value
          : this.targetAssetId,
      relationType: data.relationType.present
          ? data.relationType.value
          : this.relationType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssetRelation(')
          ..write('id: $id, ')
          ..write('sourceAssetId: $sourceAssetId, ')
          ..write('targetAssetId: $targetAssetId, ')
          ..write('relationType: $relationType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sourceAssetId, targetAssetId, relationType);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetRelation &&
          other.id == this.id &&
          other.sourceAssetId == this.sourceAssetId &&
          other.targetAssetId == this.targetAssetId &&
          other.relationType == this.relationType);
}

class AssetRelationsCompanion extends UpdateCompanion<AssetRelation> {
  final Value<String> id;
  final Value<String> sourceAssetId;
  final Value<String> targetAssetId;
  final Value<String> relationType;
  final Value<int> rowid;
  const AssetRelationsCompanion({
    this.id = const Value.absent(),
    this.sourceAssetId = const Value.absent(),
    this.targetAssetId = const Value.absent(),
    this.relationType = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssetRelationsCompanion.insert({
    required String id,
    required String sourceAssetId,
    required String targetAssetId,
    required String relationType,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceAssetId = Value(sourceAssetId),
       targetAssetId = Value(targetAssetId),
       relationType = Value(relationType);
  static Insertable<AssetRelation> custom({
    Expression<String>? id,
    Expression<String>? sourceAssetId,
    Expression<String>? targetAssetId,
    Expression<String>? relationType,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceAssetId != null) 'source_asset_id': sourceAssetId,
      if (targetAssetId != null) 'target_asset_id': targetAssetId,
      if (relationType != null) 'relation_type': relationType,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssetRelationsCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceAssetId,
    Value<String>? targetAssetId,
    Value<String>? relationType,
    Value<int>? rowid,
  }) {
    return AssetRelationsCompanion(
      id: id ?? this.id,
      sourceAssetId: sourceAssetId ?? this.sourceAssetId,
      targetAssetId: targetAssetId ?? this.targetAssetId,
      relationType: relationType ?? this.relationType,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
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
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetRelationsCompanion(')
          ..write('id: $id, ')
          ..write('sourceAssetId: $sourceAssetId, ')
          ..write('targetAssetId: $targetAssetId, ')
          ..write('relationType: $relationType, ')
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
  late final AssetDao assetDao = AssetDao(this as ProjectDatabase);
  late final CharacterDao characterDao = CharacterDao(this as ProjectDatabase);
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
      required String sourceAssetId,
      required String targetAssetId,
      required String relationType,
      Value<int> rowid,
    });
typedef $$AssetRelationsTableUpdateCompanionBuilder =
    AssetRelationsCompanion Function({
      Value<String> id,
      Value<String> sourceAssetId,
      Value<String> targetAssetId,
      Value<String> relationType,
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
                Value<String> sourceAssetId = const Value.absent(),
                Value<String> targetAssetId = const Value.absent(),
                Value<String> relationType = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetRelationsCompanion(
                id: id,
                sourceAssetId: sourceAssetId,
                targetAssetId: targetAssetId,
                relationType: relationType,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceAssetId,
                required String targetAssetId,
                required String relationType,
                Value<int> rowid = const Value.absent(),
              }) => AssetRelationsCompanion.insert(
                id: id,
                sourceAssetId: sourceAssetId,
                targetAssetId: targetAssetId,
                relationType: relationType,
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
}
