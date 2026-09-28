import 'dart:convert';
import 'dart:io';

enum Sprint116AdobeCanvaState { pass, fail, blocked }

class Sprint116AdobeCanvaRecord {
  Sprint116AdobeCanvaRecord({
    required this.providerId,
    required this.actualApis,
    required this.supportedCapabilities,
    required this.licensing,
    required this.scopes,
    required this.regionPlanLimits,
    required this.unavailableStates,
  });

  final String providerId;
  final String actualApis;
  final String supportedCapabilities;
  final String licensing;
  final String scopes;
  final String regionPlanLimits;
  final String unavailableStates;
}

class Sprint116AdobeCanvaReport {
  Sprint116AdobeCanvaReport({
    required this.state,
    required this.invalidRecords,
  });

  final Sprint116AdobeCanvaState state;
  final List<String> invalidRecords;
  String get externalGates => Sprint116AdobeCanvaContract.externalGates;
}

abstract final class Sprint116AdobeCanvaContract {
  static const String canonicalStep = '116.33';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_adobe_canva_certification.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredFields = <String>[
    'provider_id',
    'actual_apis',
    'supported_capabilities',
    'licensing',
    'scopes',
    'region_plan_limits',
    'unavailable_states',
  ];
}

class Sprint116AdobeCanvaCertification {
  Sprint116AdobeCanvaReport evaluate([
    List<Sprint116AdobeCanvaRecord>? records,
  ]) {
    final effective = records ?? _readManifestRecords();
    if (effective.isEmpty) {
      return Sprint116AdobeCanvaReport(
        state: Sprint116AdobeCanvaState.blocked,
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
      final fields = <String, String>{
        'actual_apis': record.actualApis,
        'supported_capabilities': record.supportedCapabilities,
        'licensing': record.licensing,
        'scopes': record.scopes,
        'region_plan_limits': record.regionPlanLimits,
        'unavailable_states': record.unavailableStates,
      };
      for (final entry in fields.entries) {
        if (entry.value.trim().isEmpty) invalid.add('${entry.key}:$id');
      }
    }
    return Sprint116AdobeCanvaReport(
      state: invalid.isEmpty
          ? Sprint116AdobeCanvaState.pass
          : Sprint116AdobeCanvaState.fail,
      invalidRecords: invalid,
    );
  }

  List<Sprint116AdobeCanvaRecord> _readManifestRecords() {
    final file = File(Sprint116AdobeCanvaContract.manifestPath);
    if (!file.existsSync()) return <Sprint116AdobeCanvaRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116AdobeCanvaRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map(
            (item) => Sprint116AdobeCanvaRecord(
              providerId: item['provider_id']?.toString() ?? '',
              actualApis: item['actual_apis']?.toString() ?? '',
              supportedCapabilities:
                  item['supported_capabilities']?.toString() ?? '',
              licensing: item['licensing']?.toString() ?? '',
              scopes: item['scopes']?.toString() ?? '',
              regionPlanLimits: item['region_plan_limits']?.toString() ?? '',
              unavailableStates: item['unavailable_states']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
    } on FormatException {
      return <Sprint116AdobeCanvaRecord>[];
    }
  }
}
