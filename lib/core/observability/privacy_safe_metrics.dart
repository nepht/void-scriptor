/// Privacy-safe aggregate metrics for Void Scriptor v1.2 (Sprint 110.8).
///
/// Privacy contract: local-only, opt-in (default OFF). Records ONLY aggregate
/// counters (flag/outcome/surface/count) - never titles, excerpts, or any
/// creative content. An increment for an unknown flag is silently dropped
/// (deny-by-default), so enabling metrics cannot leak content through
/// unknown feature keys.
library;

import "dart:convert";
import "dart:io";

const Set<String> kAllowedMetricKeys = <String>{
  "flag",
  "outcome",
  "surface",
  "count",
};

const Set<String> kAllowedMetricOutcomes = <String>{
  "viewed",
  "used",
  "succeeded",
  "failed",
  "skipped",
  "denied",
};

class PrivacySafeMetrics {
  final Set<String> knownFlags;
  final Map<String, int> _counters = <String, int>{};
  bool optIn = false;

  PrivacySafeMetrics({this.knownFlags = const <String>{}});

  bool get isOptIn => optIn;

  void increment({
    required String flag,
    required String surface,
    required String outcome,
    int by = 1,
  }) {
    if (!optIn) return;
    if (!knownFlags.contains(flag)) return;
    if (!kAllowedMetricOutcomes.contains(outcome)) return;
    final key = "$flag|$surface|$outcome";
    _counters[key] = (_counters[key] ?? 0) + by;
  }

  List<Map<String, dynamic>> snapshot() {
    return _counters.entries.map((e) {
      final parts = e.key.split("|");
      return <String, dynamic>{
        "flag": parts[0],
        "surface": parts[1],
        "outcome": parts[2],
        "count": e.value,
      };
    }).toList();
  }

  String toJsonString() => jsonEncode(snapshot());

  static Future<List<Map<String, dynamic>>> loadFrom(Directory dir) async {
    final file = File("${dir.path}/metrics.json");
    if (!file.existsSync()) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is List) {
        return decoded.whereType<Map<String, dynamic>>().toList();
      }
    } on FormatException {
      // corrupt -> degrade to empty, non-fatal
    }
    return <Map<String, dynamic>>[];
  }

  Future<void> saveTo(Directory dir) async {
    await dir.create(recursive: true);
    final file = File("${dir.path}/metrics.json");
    await file.writeAsString(toJsonString());
  }
}

class KillSwitch {
  final Set<String> _killed = <String>{};

  bool isKilled(String flag) => _killed.contains(flag);
  void kill(String flag) => _killed.add(flag);
  void unkill(String flag) => _killed.remove(flag);

  Future<void> saveTo(Directory dir) async {
    await dir.create(recursive: true);
    final file = File("${dir.path}/kill_switch.json");
    await file.writeAsString(jsonEncode(_killed.toList()));
  }

  static Future<KillSwitch> loadFrom(Directory dir) async {
    final ks = KillSwitch();
    final file = File("${dir.path}/kill_switch.json");
    if (!file.existsSync()) return ks;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is List) {
        for (final f in decoded.whereType<String>()) {
          ks.kill(f);
        }
      }
    } on FormatException {
      // corrupt -> empty kill-switch, non-fatal
    }
    return ks;
  }

  void apply(KnownFlagRegistry registry) {
    for (final flag in _killed) {
      registry.forceOff(flag);
    }
  }
}

abstract class KnownFlagRegistry {
  void forceOff(String flag);
  bool isEnabled(String flag);
}
