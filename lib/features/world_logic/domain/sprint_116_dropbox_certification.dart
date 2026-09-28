import 'dart:convert';
import 'dart:io';

enum Sprint116DropboxState { pass, fail, blocked }

class Sprint116DropboxRecord {
  Sprint116DropboxRecord({
    required this.providerId,
    required this.appScope,
    required this.uploadDownload,
    required this.cursorDelta,
    required this.quota,
    required this.revoke,
    required this.errors,
    required this.limitations,
  });

  final String providerId;
  final String appScope;
  final String uploadDownload;
  final String cursorDelta;
  final String quota;
  final String revoke;
  final String errors;
  final String limitations;
}

class Sprint116DropboxReport {
  Sprint116DropboxReport({required this.state, required this.invalidRecords});

  final Sprint116DropboxState state;
  final List<String> invalidRecords;
  String get externalGates => Sprint116DropboxContract.externalGates;
}

abstract final class Sprint116DropboxContract {
  static const String canonicalStep = '116.17';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_dropbox_certification.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredFields = <String>[
    'provider_id',
    'app_scope',
    'upload_download',
    'cursor_delta',
    'quota',
    'revoke',
    'errors',
    'limitations',
  ];
}

class Sprint116DropboxCertification {
  Sprint116DropboxReport evaluate([List<Sprint116DropboxRecord>? records]) {
    final effective = records ?? _readManifestRecords();
    if (effective.isEmpty) {
      return Sprint116DropboxReport(
        state: Sprint116DropboxState.blocked,
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
      if (record.appScope.trim().isEmpty) invalid.add('app_scope:$id');
      if (record.uploadDownload.trim().isEmpty) {
        invalid.add('upload_download:$id');
      }
      if (record.cursorDelta.trim().isEmpty) {
        invalid.add('cursor_delta:$id');
      }
      if (record.quota.trim().isEmpty) invalid.add('quota:$id');
      if (record.revoke.trim().isEmpty) invalid.add('revoke:$id');
      if (record.errors.trim().isEmpty) invalid.add('errors:$id');
      if (record.limitations.trim().isEmpty) {
        invalid.add('limitations:$id');
      }
    }
    return Sprint116DropboxReport(
      state: invalid.isEmpty
          ? Sprint116DropboxState.pass
          : Sprint116DropboxState.fail,
      invalidRecords: invalid,
    );
  }

  List<Sprint116DropboxRecord> _readManifestRecords() {
    final file = File(Sprint116DropboxContract.manifestPath);
    if (!file.existsSync()) return <Sprint116DropboxRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116DropboxRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map(
            (item) => Sprint116DropboxRecord(
              providerId: item['provider_id']?.toString() ?? '',
              appScope: item['app_scope']?.toString() ?? '',
              uploadDownload: item['upload_download']?.toString() ?? '',
              cursorDelta: item['cursor_delta']?.toString() ?? '',
              quota: item['quota']?.toString() ?? '',
              revoke: item['revoke']?.toString() ?? '',
              errors: item['errors']?.toString() ?? '',
              limitations: item['limitations']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
    } on FormatException {
      return <Sprint116DropboxRecord>[];
    }
  }
}
