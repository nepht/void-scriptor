import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/project_resilience/application/backup_retention_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_resilience_repository.dart';

void main() {
  test('prunes automatic backups beyond retention limit (oldest first)', () {
    final backups = [
      _backup('b1', 'automatic', DateTime(2026, 1, 1)),
      _backup('b2', 'automatic', DateTime(2026, 1, 2)),
      _backup('b3', 'automatic', DateTime(2026, 1, 3)),
    ];
    const service = BackupRetentionService(
      policy: BackupRetentionPolicy(maxAutomatic: 2, maxManual: 50),
    );

    final toPrune = service.selectForPrune(backups);

    expect(toPrune.map((b) => b.id), ['b1']);
  });

  test('never prunes manual backups within their limit', () {
    final backups = [
      _backup('m1', 'manual', DateTime(2026, 1, 1)),
      _backup('m2', 'manual', DateTime(2026, 1, 2)),
      _backup('m3', 'manual', DateTime(2026, 1, 3)),
      _backup('m4', 'manual', DateTime(2026, 1, 4)),
    ];
    const service = BackupRetentionService(
      policy: BackupRetentionPolicy(maxAutomatic: 20, maxManual: 3),
    );

    final toPrune = service.selectForPrune(backups);

    expect(toPrune.map((b) => b.id), ['m1']);
  });

  test('keeps newest backups and returns nothing when under limit', () {
    final backups = [_backup('b1', 'automatic', DateTime(2026, 1, 1))];
    const service = BackupRetentionService(
      policy: BackupRetentionPolicy(maxAutomatic: 2, maxManual: 50),
    );
    expect(service.selectForPrune(backups), isEmpty);
  });
}

BackupInfo _backup(String id, String type, DateTime createdAt) =>
    BackupInfo(id: id, type: type, createdAt: createdAt);
