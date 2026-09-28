import 'dart:convert';
import 'dart:io';

enum Sprint116OneDriveState { pass, fail, blocked }

class Sprint116OneDriveRecord {
  Sprint116OneDriveRecord({
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

class Sprint116OneDriveReport {
  Sprint116OneDriveReport({required this.state, required this.invalidRecords});

  final Sprint116OneDriveState state;
  final List<String> invalidRecords;
  String get externalGates => Sprint116OneDriveContract.externalGates;
}

abstract final class Sprint116OneDriveContract {
  static const String canonicalStep = '116.16';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_onedrive_certification.json';
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

class Sprint116OneDriveCertification {
  Sprint116OneDriveReport evaluate([List<Sprint116OneDriveRecord>? records]) {
    final effective = records ?? _readManifestRecords();
    if (effective.isEmpty) {
      return Sprint116OneDriveReport(
        state: Sprint116OneDriveState.blocked,
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
    return Sprint116OneDriveReport(
      state: invalid.isEmpty
          ? Sprint116OneDriveState.pass
          : Sprint116OneDriveState.fail,
      invalidRecords: invalid,
    );
  }

  List<Sprint116OneDriveRecord> _readManifestRecords() {
    final file = File(Sprint116OneDriveContract.manifestPath);
    if (!file.existsSync()) return <Sprint116OneDriveRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116OneDriveRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map(
            (item) => Sprint116OneDriveRecord(
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
      return <Sprint116OneDriveRecord>[];
    }
  }
}
