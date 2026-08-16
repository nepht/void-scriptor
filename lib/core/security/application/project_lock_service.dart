import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../../../database/project/project_database.dart';
import '../crypto/key_derivation.dart';
import '../crypto/encryption_cipher.dart';

enum ProjectLockState { unlocked, locked }

/// Passphrase-based project lock (Step 30.13).
class ProjectLockService {
  ProjectLockService({
    required this.database,
    required this.deriver,
    required this.integrity,
    this.defaultIterations = 100000,
  });

  final ProjectDatabase database;
  final Pbkdf2KeyDeriver deriver;
  final HmacIntegrity integrity;
  final int defaultIterations;

  static final _random = Random.secure();

  Future<void> setPassphrase(String projectId, String passphrase) async {
    final salt = List<int>.generate(16, (_) => _random.nextInt(256));
    final key = await deriver.derive(
      passphrase: passphrase,
      salt: salt,
      iterations: defaultIterations,
      length: 32,
    );
    final hash = await integrity.sign(key, utf8.encode(projectId));
    await _upsert(
      projectId,
      encryptionEnabled: true,
      locked: true,
      salt: base64Encode(salt),
      passphraseHash: base64Encode(hash),
    );
  }

  Future<bool> unlock(String projectId, String passphrase) async {
    final row = await _row(projectId);
    if (row == null ||
        row.passphraseSalt == null ||
        row.passphraseHash == null) {
      return false;
    }
    final salt = base64Decode(row.passphraseSalt!);
    final key = await deriver.derive(
      passphrase: passphrase,
      salt: salt,
      iterations: defaultIterations,
      length: 32,
    );
    final hash = await integrity.sign(key, utf8.encode(projectId));
    if (base64Encode(hash) != row.passphraseHash) return false;
    await _setLocked(projectId, false);
    return true;
  }

  Future<void> lock(String projectId) async {
    await _setLocked(projectId, true);
  }

  Future<bool> isLocked(String projectId) async {
    final row = await _row(projectId);
    if (row == null) return false;
    // A project with a passphrase set but no explicit lock state is locked.
    return row.passphraseHash != null && row.locked;
  }

  Future<SecuritySetting?> _row(String projectId) async {
    final query = database.select(database.securitySettings)
      ..where((row) => row.projectId.equals(projectId));
    final rows = await query.get();
    return rows.isEmpty ? null : rows.single;
  }

  Future<void> _setLocked(String projectId, bool locked) async {
    await (database.update(database.securitySettings)
          ..where((row) => row.projectId.equals(projectId)))
        .write(SecuritySettingsCompanion(locked: Value(locked)));
  }

  Future<void> _upsert(
    String projectId, {
    required bool encryptionEnabled,
    required bool locked,
    String? salt,
    String? passphraseHash,
  }) async {
    await database
        .into(database.securitySettings)
        .insertOnConflictUpdate(
          SecuritySettingsCompanion.insert(
            projectId: projectId,
            encryptionEnabled: Value(encryptionEnabled),
            locked: Value(locked),
            passphraseSalt: Value(salt),
            passphraseHash: Value(passphraseHash),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
  }
}
