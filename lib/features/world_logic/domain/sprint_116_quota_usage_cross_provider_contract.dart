import 'dart:convert';
import 'dart:io';

enum Sprint116QuotaState { pass, fail, blocked }

/// Classification of a single quota/usage observation.
///
/// [unavailable] means the provider reported no value; it is deliberately
/// distinct from a numeric zero so callers can never render a fabricated
/// amount for a missing reading.
enum Sprint116QuotaStatus { available, unavailable, stale }

class Sprint116QuotaRecord {
  const Sprint116QuotaRecord({
    required this.recordId,
    required this.providerId,
    required this.unitKind,
    required this.observedAtEpochMs,
    required this.source,
    this.rawUnits,
    this.evidenceRef,
  });

  final String recordId;
  final String providerId;
  final String unitKind;
  final int observedAtEpochMs;
  final String source;
  final num? rawUnits;
  final String? evidenceRef;
}

class Sprint116QuotaReading {
  Sprint116QuotaReading({
    required this.record,
    required this.status,
    required this.ageMs,
    required this.staleWarning,
    required this.displayValue,
  });

  final Sprint116QuotaRecord record;
  final Sprint116QuotaStatus status;
  final int ageMs;
  final bool staleWarning;
  final String? displayValue;

  num? get rawUnits => record.rawUnits;
}

class Sprint116QuotaTotal {
  Sprint116QuotaTotal({
    required this.unitKind,
    required this.rawTotal,
    required this.displayTotal,
    required this.availableCount,
    required this.unavailableCount,
  });

  final String unitKind;
  final num? rawTotal;
  final String? displayTotal;
  final int availableCount;
  final int unavailableCount;

  bool get partial => unavailableCount > 0;
}

class Sprint116QuotaReport {
  Sprint116QuotaReport({
    required this.state,
    required this.invalidRecords,
    required this.readings,
    required this.staleWarningIds,
    required this.unavailableIds,
    required this.totals,
  });

  final Sprint116QuotaState state;
  final List<String> invalidRecords;
  final List<Sprint116QuotaReading> readings;
  final List<String> staleWarningIds;
  final List<String> unavailableIds;
  final Map<String, Sprint116QuotaTotal> totals;

  String get externalGates => Sprint116QuotaContract.externalGates;
}

abstract final class Sprint116QuotaContract {
  static const String canonicalStep = '116.41';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_quota_usage_cross_provider_contract.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredAcceptance = <String>[
    'raw_units',
    'display_units',
    'freshness',
    'unavailable',
    'partial_total',
    'stale_warning',
    'no_mock_values',
  ];
  static const List<String> supportedUnitKinds = <String>[
    'bytes',
    'percent',
    'requests',
    'tokens',
  ];
  static const List<String> supportedSources = <String>[
    'synthetic_local',
    'live',
  ];
  static const int freshTtlSeconds = 3600;
  static const List<String> binaryUnits = <String>[
    'B',
    'KiB',
    'MiB',
    'GiB',
    'TiB',
  ];

  /// Derives a display string from [rawUnits] only.
  ///
  /// Returns null when the value cannot be displayed honestly: unknown unit
  /// kinds, out-of-range percent, and fractional byte/count values. The
  /// formatter never adds precision the raw value does not carry.
  static String? displayUnits(num rawUnits, String unitKind) {
    switch (unitKind) {
      case 'bytes':
        if (rawUnits != rawUnits.roundToDouble()) return null;
        var value = rawUnits.toDouble();
        var index = 0;
        while (value >= 1024 && index < binaryUnits.length - 1) {
          value /= 1024;
          index += 1;
        }
        var scaled = value.toStringAsFixed(1);
        if (scaled.endsWith('.0')) {
          scaled = scaled.substring(0, scaled.length - 2);
        }
        return '$scaled ${binaryUnits[index]}';
      case 'percent':
        if (rawUnits < 0 || rawUnits > 100) return null;
        if (rawUnits == rawUnits.roundToDouble()) {
          return '${rawUnits.toInt()}%';
        }
        return '${rawUnits.toStringAsFixed(1)}%';
      case 'requests':
      case 'tokens':
        if (rawUnits != rawUnits.roundToDouble()) return null;
        return rawUnits.toInt().toString();
      default:
        return null;
    }
  }
}

class _Sprint116QuotaBucket {
  int available = 0;
  int unavailable = 0;
  num sum = 0;
}

class Sprint116QuotaUsageCertification {
  /// Certifies quota/usage records against the cross-provider contract.
  ///
  /// Manifest fixtures are consulted only when [records] is omitted: callers
  /// that pass explicit records must also get an as-of derived from those
  /// records, so a real reading can never borrow a fixture timestamp.
  Sprint116QuotaReport certify({
    List<Sprint116QuotaRecord>? records,
    int? asOfEpochMs,
    bool requireComplete = false,
  }) {
    final manifestMode = records == null;
    final effective = records ?? _readManifestRecords();

    if (effective.isEmpty) {
      return Sprint116QuotaReport(
        state: Sprint116QuotaState.blocked,
        invalidRecords: const <String>['records'],
        readings: const <Sprint116QuotaReading>[],
        staleWarningIds: const <String>[],
        unavailableIds: const <String>[],
        totals: const <String, Sprint116QuotaTotal>{},
      );
    }

    var maxObserved = 0;
    for (final record in effective) {
      if (record.observedAtEpochMs > maxObserved) {
        maxObserved = record.observedAtEpochMs;
      }
    }

    final int asOf;
    if (asOfEpochMs != null) {
      asOf = asOfEpochMs;
    } else if (manifestMode) {
      asOf = _readManifestAsOfEpochMs() ?? maxObserved;
    } else {
      asOf = maxObserved;
    }

    const ttlMs = Sprint116QuotaContract.freshTtlSeconds * 1000;
    final invalid = <String>[];
    final staleIds = <String>[];
    final unavailableIds = <String>[];
    final readings = <Sprint116QuotaReading>[];

    for (var index = 0; index < effective.length; index++) {
      final record = effective[index];
      final id = record.recordId.trim();
      if (id.isEmpty) {
        invalid.add('record_id:$index');
        continue;
      }

      final kind = record.unitKind.trim();
      final kindSupported = Sprint116QuotaContract.supportedUnitKinds.contains(
        kind,
      );
      final raw = record.rawUnits;
      var valueValid = true;

      if (raw != null) {
        if (raw < 0 || (kind == 'bytes' && raw != raw.roundToDouble())) {
          invalid.add('raw_units:$id');
          valueValid = false;
        } else if (!kindSupported) {
          invalid.add('display_units:$id');
          valueValid = false;
        } else if (kind == 'percent' && raw > 100) {
          invalid.add('display_units:$id');
          valueValid = false;
        } else if ((kind == 'requests' || kind == 'tokens') &&
            raw != raw.roundToDouble()) {
          invalid.add('display_units:$id');
          valueValid = false;
        }
      }

      // Source honesty: a live claim must carry evidence, and unknown
      // sources are rejected so a mock number cannot masquerade as telemetry.
      final source = record.source.trim();
      final evidence = record.evidenceRef?.trim();
      if (!Sprint116QuotaContract.supportedSources.contains(source) ||
          (source == 'live' && (evidence == null || evidence.isEmpty))) {
        invalid.add('no_mock_values:$id');
      }

      var ageMs = 0;
      var staleWarning = false;
      var status = raw == null
          ? Sprint116QuotaStatus.unavailable
          : Sprint116QuotaStatus.available;
      if (record.observedAtEpochMs <= 0) {
        invalid.add('freshness:$id');
        status = raw == null
            ? Sprint116QuotaStatus.unavailable
            : Sprint116QuotaStatus.stale;
      } else {
        ageMs = asOf - record.observedAtEpochMs;
        if (ageMs < 0) {
          // The observation postdates the as-of point; the clock relationship
          // itself is broken, so no stale label is fabricated for it.
          invalid.add('freshness:$id');
          status = raw == null
              ? Sprint116QuotaStatus.unavailable
              : Sprint116QuotaStatus.stale;
        } else if (ageMs > ttlMs) {
          staleWarning = true;
          staleIds.add(id);
          invalid.add('stale_warning:$id');
          status = Sprint116QuotaStatus.stale;
        } else {
          status = raw == null
              ? Sprint116QuotaStatus.unavailable
              : Sprint116QuotaStatus.available;
        }
      }

      if (raw == null) {
        unavailableIds.add(id);
        if (requireComplete) {
          invalid.add('partial_total:$id');
        }
      }

      String? display;
      if (raw != null && valueValid && kindSupported) {
        display = Sprint116QuotaContract.displayUnits(raw, kind);
      }

      readings.add(
        Sprint116QuotaReading(
          record: record,
          status: status,
          ageMs: ageMs,
          staleWarning: staleWarning,
          displayValue: display,
        ),
      );
    }

    final buckets = <String, _Sprint116QuotaBucket>{};
    for (final reading in readings) {
      final kind = reading.record.unitKind.trim();
      if (!Sprint116QuotaContract.supportedUnitKinds.contains(kind)) {
        continue;
      }
      final bucket = buckets.putIfAbsent(kind, () => _Sprint116QuotaBucket());
      final raw = reading.record.rawUnits;
      if (raw == null) {
        bucket.unavailable += 1;
      } else if (reading.displayValue != null) {
        bucket.available += 1;
        bucket.sum += raw;
      }
    }

    final totals = <String, Sprint116QuotaTotal>{
      for (final entry in buckets.entries)
        entry.key: Sprint116QuotaTotal(
          unitKind: entry.key,
          rawTotal: entry.value.available == 0 ? null : entry.value.sum,
          displayTotal: entry.value.available == 0
              ? null
              : Sprint116QuotaContract.displayUnits(entry.value.sum, entry.key),
          availableCount: entry.value.available,
          unavailableCount: entry.value.unavailable,
        ),
    };

    return Sprint116QuotaReport(
      state: invalid.isEmpty
          ? Sprint116QuotaState.pass
          : Sprint116QuotaState.fail,
      invalidRecords: invalid,
      readings: readings,
      staleWarningIds: staleIds,
      unavailableIds: unavailableIds,
      totals: totals,
    );
  }

  Map<String, dynamic>? _readManifest() {
    final file = File(Sprint116QuotaContract.manifestPath);
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  List<Sprint116QuotaRecord> _readManifestRecords() {
    final raw = _readManifest()?['records'];
    if (raw is! List) return <Sprint116QuotaRecord>[];
    return raw
        .whereType<Map>()
        .map(
          (item) => Sprint116QuotaRecord(
            recordId: item['record_id']?.toString() ?? '',
            providerId: item['provider_id']?.toString() ?? '',
            unitKind: item['unit_kind']?.toString() ?? '',
            observedAtEpochMs:
                (item['observed_at_epoch_ms'] as num?)?.toInt() ?? 0,
            source: item['source']?.toString() ?? '',
            rawUnits: item['raw_units'] as num?,
            evidenceRef: item['evidence_ref']?.toString(),
          ),
        )
        .toList(growable: false);
  }

  int? _readManifestAsOfEpochMs() {
    final raw = _readManifest()?['as_of_epoch_ms'];
    return raw is num ? raw.toInt() : null;
  }
}
