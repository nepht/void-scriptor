import 'package:drift/drift.dart';

class AudioFiles extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get filePath => text()();
  TextColumn get contentHash => text().nullable()();
  RealColumn get durationSeconds => real().nullable()();
  IntColumn get sampleRate => integer().nullable()();
  IntColumn get channels => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SoundEffects extends Table {
  TextColumn get assetId => text()();
  TextColumn get projectId => text()();
  TextColumn get audioFileId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  BoolColumn get loopable => boolean().withDefault(const Constant(false))();
  @override
  Set<Column<Object>> get primaryKey => {assetId};
}

class SoundEffectVariations extends Table {
  TextColumn get id => text()();
  TextColumn get soundEffectId => text()();
  TextColumn get audioFileId => text()();
  TextColumn get label => text().withDefault(const Constant(''))();
  RealColumn get weight => real().withDefault(const Constant(1))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AmbienceAssets extends Table {
  TextColumn get assetId => text()();
  TextColumn get projectId => text()();
  TextColumn get audioFileId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  BoolColumn get loopable => boolean().withDefault(const Constant(true))();
  @override
  Set<Column<Object>> get primaryKey => {assetId};
}

class AmbienceLayers extends Table {
  TextColumn get id => text()();
  TextColumn get ambienceId => text()();
  TextColumn get audioFileId => text()();
  TextColumn get name => text()();
  RealColumn get defaultGainDb => real().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AmbienceVariants extends Table {
  TextColumn get id => text()();
  TextColumn get ambienceId => text()();
  TextColumn get name => text()();
  TextColumn get referenceAudioFileId => text().nullable()();
  TextColumn get conditions => text().withDefault(const Constant(''))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class MusicCues extends Table {
  TextColumn get assetId => text()();
  TextColumn get projectId => text()();
  TextColumn get audioFileId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get mood => text()();
  RealColumn get bpm => real().nullable()();
  TextColumn get musicalKey => text().nullable()();
  TextColumn get description => text().withDefault(const Constant(''))();
  BoolColumn get loopable => boolean().withDefault(const Constant(false))();
  @override
  Set<Column<Object>> get primaryKey => {assetId};
}

class MusicSections extends Table {
  TextColumn get id => text()();
  TextColumn get musicId => text()();
  TextColumn get name => text()();
  RealColumn get startSeconds => real()();
  RealColumn get endSeconds => real()();
  TextColumn get mood => text().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}
