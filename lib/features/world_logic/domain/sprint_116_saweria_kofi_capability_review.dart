import 'dart:convert';
import 'dart:io';

enum Sprint116CapabilityState { pass, fail, blocked }

class Sprint116CapabilityRecord {
  Sprint116CapabilityRecord({
    required this.providerId,
    required this.apiContract,
    required this.termsReference,
    required this.regionLimits,
    required this.webhookSurface,
    required this.connectorVerdict,
    required this.evidenceRefs,
  });

  final String providerId;
  final String apiContract;
  final String termsReference;
  final String regionLimits;
  final String webhookSurface;
  final String connectorVerdict;
  final String evidenceRefs;
}

class Sprint116CapabilityReport {
  Sprint116CapabilityReport({
    required this.state,
    required this.invalidRecords,
  });

  final Sprint116CapabilityState state;
  final List<String> invalidRecords;
  String get externalGates => Sprint116CapabilityContract.externalGates;
}

abstract final class Sprint116CapabilityContract {
  static const String canonicalStep = '116.39';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_saweria_kofi_capability_review.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredFields = <String>[
    'api_contract',
    'terms_reference',
    'region_limits',
    'webhook_surface',
    'connector_verdict',
    'evidence_refs',
  ];
  static const List<String> allowedVerdicts = <String>[
    'BLOCKED',
    'LIMITED',
    'SUPPORTED',
  ];
  static const String supportedVerdict = 'SUPPORTED';
  static const String verifiedMarker = 'VERIFIED';
}

class Sprint116CapabilityReview {
  Sprint116CapabilityReport evaluate([
    List<Sprint116CapabilityRecord>? records,
  ]) {
    final effective = records ?? _readManifestRecords();
    if (effective.isEmpty) {
      return Sprint116CapabilityReport(
        state: Sprint116CapabilityState.blocked,
        invalidRecords: const <String>['records'],
      );
    }
    final invalid = <String>[];
    for (final record in effective) {
      final label = record.providerId.trim();
      final fields = <String, String>{
        'api_contract': record.apiContract,
        'terms_reference': record.termsReference,
        'region_limits': record.regionLimits,
        'webhook_surface': record.webhookSurface,
        'evidence_refs': record.evidenceRefs,
      };
      for (final entry in fields.entries) {
        if (entry.value.trim().isEmpty) {
          invalid.add('${entry.key}:$label');
        }
      }
      final verdict = record.connectorVerdict.trim();
      if (!Sprint116CapabilityContract.allowedVerdicts.contains(verdict)) {
        invalid.add('connector_verdict:$label');
        continue;
      }
      // Fail-closed: a connector may only be SUPPORTED when both the API
      // contract and the terms reference are explicitly VERIFIED, so an
      // unverified webhook-only surface can never ship as a fake connector.
      if (verdict == Sprint116CapabilityContract.supportedVerdict &&
          (record.apiContract.trim() !=
                  Sprint116CapabilityContract.verifiedMarker ||
              record.termsReference.trim() !=
                  Sprint116CapabilityContract.verifiedMarker)) {
        invalid.add('connector_verdict:$label');
      }
    }
    return Sprint116CapabilityReport(
      state: invalid.isEmpty
          ? Sprint116CapabilityState.pass
          : Sprint116CapabilityState.fail,
      invalidRecords: invalid,
    );
  }

  List<Sprint116CapabilityRecord> _readManifestRecords() {
    final file = File(Sprint116CapabilityContract.manifestPath);
    if (!file.existsSync()) return <Sprint116CapabilityRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116CapabilityRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map(
            (item) => Sprint116CapabilityRecord(
              providerId: item['provider_id']?.toString() ?? '',
              apiContract: item['api_contract']?.toString() ?? '',
              termsReference: item['terms_reference']?.toString() ?? '',
              regionLimits: item['region_limits']?.toString() ?? '',
              webhookSurface: item['webhook_surface']?.toString() ?? '',
              connectorVerdict: item['connector_verdict']?.toString() ?? '',
              evidenceRefs: item['evidence_refs']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
    } on FormatException {
      return <Sprint116CapabilityRecord>[];
    }
  }
}
