import 'package:drift/drift.dart';

/// Per-project security settings (Step 30.14).
class SecuritySettings extends Table {
  TextColumn get projectId => text()();
  BoolColumn get encryptionEnabled =>
      boolean().withDefault(const Constant(false))();
  IntColumn get kdfIterations =>
      integer().withDefault(const Constant(100000))();
  TextColumn get passphraseSalt => text().nullable()();
  TextColumn get passphraseHash => text().nullable()();
  BoolColumn get locked => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {projectId};
}
