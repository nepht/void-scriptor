import 'dart:convert';
import 'dart:io';

enum Sprint116GoogleDriveState { pass, fail, blocked }

class Sprint116GoogleDriveRecord {
  Sprint116GoogleDriveRecord({
    required this.providerId,
    required this.fileScope,
    required this.appFolderRootChoice,
    required this.uploadDownload,
    required this.delta,
    required this.quota,
    required this.revoke,
    required this.errors,
  });

  final String providerId;
  final String fileScope;
  final String appFolderRootChoice;
  final String uploadDownload;
  final String delta;
  final String quota;
  final String revoke;
  final String errors;
}

class Sprint116GoogleDriveReport {
  Sprint116GoogleDriveReport({
    required this.state,
    required this.invalidRecords,
  });

  final Sprint116GoogleDriveState state;
  final List<String> invalidRecords;
  String get externalGates => Sprint116GoogleDriveContract.externalGates;
}

abstract final class Sprint116GoogleDriveContract {
  static const String canonicalStep = '116.15';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_google_drive_certification.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredFields = <String>[
    'provider_id',
    'file_scope',
    'app_folder_root_choice',
    'upload_download',
    'delta',
    'quota',
    'revoke',
    'errors',
  ];
}

class Sprint116GoogleDriveCertification {
  Sprint116GoogleDriveReport evaluate([
    List<Sprint116GoogleDriveRecord>? records,
  ]) {
    final effective = records ?? _readManifestRecords();
    if (effective.isEmpty) {
      return Sprint116GoogleDriveReport(
        state: Sprint116GoogleDriveState.blocked,
        invalidRecords: const <String>['records'],
      );
    }
    final invalid = <String>[];
    for (final record in effective) {
      final id = record.providerId.trim();
      if (id.isEmpty) {
        invalid.add('provider_id');
        continue;
      }
      if (record.fileScope.trim().isEmpty) invalid.add('file_scope:$id');
      if (record.appFolderRootChoice.trim().isEmpty) {
        invalid.add('app_folder_root_choice:$id');
      }
      if (record.uploadDownload.trim().isEmpty) {
        invalid.add('upload_download:$id');
      }
      if (record.delta.trim().isEmpty) invalid.add('delta:$id');
      if (record.quota.trim().isEmpty) invalid.add('quota:$id');
      if (record.revoke.trim().isEmpty) invalid.add('revoke:$id');
      if (record.errors.trim().isEmpty) invalid.add('errors:$id');
    }
    return Sprint116GoogleDriveReport(
      state: invalid.isEmpty
          ? Sprint116GoogleDriveState.pass
          : Sprint116GoogleDriveState.fail,
      invalidRecords: invalid,
    );
  }

  List<Sprint116GoogleDriveRecord> _readManifestRecords() {
    final file = File(Sprint116GoogleDriveContract.manifestPath);
    if (!file.existsSync()) return <Sprint116GoogleDriveRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116GoogleDriveRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map(
            (item) => Sprint116GoogleDriveRecord(
              providerId: item['provider_id']?.toString() ?? '',
              fileScope: item['file_scope']?.toString() ?? '',
              appFolderRootChoice:
                  item['app_folder_root_choice']?.toString() ?? '',
              uploadDownload: item['upload_download']?.toString() ?? '',
              delta: item['delta']?.toString() ?? '',
              quota: item['quota']?.toString() ?? '',
              revoke: item['revoke']?.toString() ?? '',
              errors: item['errors']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
    } on FormatException {
      return <Sprint116GoogleDriveRecord>[];
    }
  }
}
