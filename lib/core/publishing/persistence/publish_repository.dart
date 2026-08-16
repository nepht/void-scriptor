import 'package:drift/drift.dart';

import '../../../database/project/project_database.dart';

/// Persists publish records (Step 36.14).
class PublishRepository {
  PublishRepository({required this.database});

  final ProjectDatabase database;

  Future<void> saveRecord({
    required String id,
    required String channel,
    required String version,
    required String state,
    required String checksum,
    String changelog = '',
  }) async {
    await database
        .into(database.publishRecords)
        .insertOnConflictUpdate(
          PublishRecordsCompanion.insert(
            id: id,
            channel: channel,
            version: version,
            state: state,
            checksum: checksum,
            changelog: Value(changelog),
          ),
        );
  }

  Future<List<PublishRecord>> listRecords(String channel) async {
    final query = database.select(database.publishRecords)
      ..where((row) => row.channel.equals(channel));
    return query.get();
  }
}
