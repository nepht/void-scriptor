import 'package:drift/drift.dart';

import '../../../database/project/project_database.dart' as db;
import '../domain/effective_identity_profile.dart';

class CharacterModeIdentityRepository {
  CharacterModeIdentityRepository(this.database);

  final db.ProjectDatabase database;

  Future<CharacterModeIdentityOverride?> getOverride(String modeId) async {
    final row = await database.characterModeDao.getIdentityOverride(modeId);
    if (row == null) return null;
    return CharacterModeIdentityOverride(
      modeId: row.modeId,
      faceLock: row.faceLock,
      hairLock: row.hairLock,
      bodyLock: row.bodyLock,
      colorLock: row.colorLock,
      outfitLock: row.outfitLock,
      weaponLock: row.weaponLock,
    );
  }

  Future<void> saveOverride(CharacterModeIdentityOverride override) {
    return database.characterModeDao.upsertIdentityOverride(
      db.CharacterModeIdentityOverridesCompanion(
        modeId: Value(override.modeId),
        faceLock: Value(override.faceLock),
        hairLock: Value(override.hairLock),
        bodyLock: Value(override.bodyLock),
        colorLock: Value(override.colorLock),
        outfitLock: Value(override.outfitLock),
        weaponLock: Value(override.weaponLock),
      ),
    );
  }
}
