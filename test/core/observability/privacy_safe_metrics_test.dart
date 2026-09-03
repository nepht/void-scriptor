import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/core/observability/privacy_safe_metrics.dart";

void main() {
  group("PrivacySafeMetrics (Sprint 110.8)", () {
    test("default OFF: increment is silently dropped", () {
      final m = PrivacySafeMetrics(knownFlags: {"vs12_lore_links"});
      // optIn stays false
      m.increment(
        flag: "vs12_lore_links",
        surface: "story_panel",
        outcome: "viewed",
      );
      expect(m.snapshot(), isEmpty);
    });

    test("opt-in: only known flags are recorded (deny-by-default)", () {
      final m = PrivacySafeMetrics(knownFlags: {"vs12_lore_links"})
        ..optIn = true;
      m.increment(
        flag: "vs12_lore_links",
        surface: "story_panel",
        outcome: "viewed",
      );
      m.increment(flag: "unknown_flag", surface: "x", outcome: "used");
      final snap = m.snapshot();
      expect(snap.length, 1);
      expect(snap.first["flag"], "vs12_lore_links");
      expect(snap.first["surface"], "story_panel");
      expect(snap.first["outcome"], "viewed");
      expect(snap.first["count"], 1);
    });

    test("aggregates by (flag, surface, outcome) tuple", () {
      final m = PrivacySafeMetrics(knownFlags: {"vs12_lore_links"})
        ..optIn = true;
      m.increment(
        flag: "vs12_lore_links",
        surface: "story_panel",
        outcome: "viewed",
      );
      m.increment(
        flag: "vs12_lore_links",
        surface: "story_panel",
        outcome: "viewed",
      );
      m.increment(
        flag: "vs12_lore_links",
        surface: "story_panel",
        outcome: "viewed",
        by: 3,
      );
      final snap = m.snapshot();
      expect(snap.length, 1);
      expect(snap.first["count"], 5);
    });

    test("rejects unknown outcome values", () {
      final m = PrivacySafeMetrics(knownFlags: {"vs12_lore_links"})
        ..optIn = true;
      m.increment(
        flag: "vs12_lore_links",
        surface: "x",
        outcome: "leaked_outcome",
      );
      expect(m.snapshot(), isEmpty);
    });

    test("save and load roundtrip", () async {
      final dir = await Directory.systemTemp.createTemp("psm_test_");
      try {
        final m = PrivacySafeMetrics(knownFlags: {"vs12_lore_links"})
          ..optIn = true;
        m.increment(flag: "vs12_lore_links", surface: "x", outcome: "used");
        await m.saveTo(dir);
        final loaded = await PrivacySafeMetrics.loadFrom(dir);
        expect(loaded.length, 1);
        expect(loaded.first["flag"], "vs12_lore_links");
      } finally {
        if (await dir.exists()) await dir.delete(recursive: true);
      }
    });

    test("corrupt file degrades to empty (non-fatal)", () async {
      final dir = await Directory.systemTemp.createTemp("psm_test_");
      try {
        final file = File("${dir.path}/metrics.json");
        await file.writeAsString("{not json");
        final loaded = await PrivacySafeMetrics.loadFrom(dir);
        expect(loaded, isEmpty);
      } finally {
        if (await dir.exists()) await dir.delete(recursive: true);
      }
    });

    test("snapshot has no creative-content fields", () {
      final m = PrivacySafeMetrics(knownFlags: {"vs12_lore_links"})
        ..optIn = true;
      m.increment(
        flag: "vs12_lore_links",
        surface: "story_panel",
        outcome: "viewed",
      );
      final snap = m.snapshot().first;
      // Only whitelisted keys can appear.
      final keys = snap.keys.toSet();
      expect(
        keys.difference({"flag", "surface", "outcome", "count"}),
        isEmpty,
        reason: "snapshot leaked keys: $keys",
      );
    });
  });

  group("KillSwitch (Sprint 110.8)", () {
    test("default empty: no flag is killed", () {
      final ks = KillSwitch();
      expect(ks.isKilled("vs12_lore_links"), isFalse);
    });

    test("kill and unkill", () {
      final ks = KillSwitch()..kill("vs12_lore_links");
      expect(ks.isKilled("vs12_lore_links"), isTrue);
      ks.unkill("vs12_lore_links");
      expect(ks.isKilled("vs12_lore_links"), isFalse);
    });

    test("save and load roundtrip", () async {
      final dir = await Directory.systemTemp.createTemp("ks_test_");
      try {
        final ks = KillSwitch()
          ..kill("vs12_lore_links")
          ..kill("vs12_export");
        await ks.saveTo(dir);
        final loaded = await KillSwitch.loadFrom(dir);
        expect(loaded.isKilled("vs12_lore_links"), isTrue);
        expect(loaded.isKilled("vs12_export"), isTrue);
        expect(loaded.isKilled("vs12_quests"), isFalse);
      } finally {
        if (await dir.exists()) await dir.delete(recursive: true);
      }
    });

    test("apply forces killed flags OFF via registry shim", () {
      final fakeReg = _FakeRegistry();
      final ks = KillSwitch()
        ..kill("vs12_lore_links")
        ..kill("vs12_export");
      ks.apply(fakeReg);
      expect(fakeReg.forcedOff, {"vs12_lore_links", "vs12_export"});
    });
  });
}

class _FakeRegistry implements KnownFlagRegistry {
  final Set<String> forcedOff = <String>{};
  @override
  bool isEnabled(String flag) => !forcedOff.contains(flag);
  @override
  void forceOff(String flag) => forcedOff.add(flag);
}
