import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/project_resilience/application/drift_transaction_coordinator.dart';

void main() {
  test('drift transaction coordinator rolls back a failed command', () async {
    final root = await Directory.systemTemp.createTemp('s25-transaction-');
    addTearDown(() => root.delete(recursive: true));
    final path = '${root.path}/project.db';
    final service = ProjectDatabaseService();
    await service.create(path);
    final database = await service.open(path);
    addTearDown(database.close);
    final coordinator = DriftTransactionCoordinator(database);

    await expectLater(
      coordinator.run(() async {
        await database
            .into(database.projectMetadata)
            .insertOnConflictUpdate(
              ProjectMetadataCompanion.insert(
                key: 'transaction-test',
                value: 'should-rollback',
              ),
            );
        throw StateError('failure');
      }),
      throwsStateError,
    );

    final row = await (database.select(
      database.projectMetadata,
    )..where((item) => item.key.equals('transaction-test'))).getSingleOrNull();
    expect(row, isNull);
  });
}
