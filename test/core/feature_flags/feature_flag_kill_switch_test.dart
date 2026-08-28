// Sprint 110.8 — kill-switch contract for v1.2 feature flags.
//
// Scope: per Sprint 110 scope contract, step 110.8 owns per-feature flags
// plus kill-switch behavior. The registry must provide an emergency global
// disable that forces every flag back to its default OFF state in a single
// call. The kill-switch must be idempotent and observable to diagnostics.

import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/core/feature_flags/feature_flag_registry.dart";

void main() {
  group("feature_flag_kill_switch", () {
    test("engages kill-switch and disables every enabled flag", () {
      final registry = FeatureFlagRegistry();
      registry.enable("vs12_lore_links");
      registry.enable("vs12_quests");
      registry.enable("vs12_export");
      expect(registry.enabledFlags, hasLength(3));

      registry.engageKillSwitch();

      expect(registry.killSwitchActive, isTrue);
      expect(registry.allAtDefaults, isTrue);
      expect(registry.enabledFlags, isEmpty);
      expect(registry.isEnabled("vs12_lore_links"), isFalse);
    });

    test("kill-switch is idempotent", () {
      final registry = FeatureFlagRegistry();
      registry.engageKillSwitch();
      registry.engageKillSwitch();
      expect(registry.killSwitchActive, isTrue);
      expect(registry.allAtDefaults, isTrue);
    });

    test(
      "re-enabling a flag while kill-switch is active auto-disengages it",
      () {
        final registry = FeatureFlagRegistry();
        registry.enable("vs12_lore_links");
        registry.engageKillSwitch();
        expect(registry.allAtDefaults, isTrue);

        registry.enable("vs12_quests");

        expect(registry.killSwitchActive, isFalse);
        expect(registry.isEnabled("vs12_quests"), isTrue);
        expect(registry.isEnabled("vs12_lore_links"), isFalse);
      },
    );

    test("resetToDefaults is a soft reset that keeps kill-switch off", () {
      final registry = FeatureFlagRegistry();
      registry.enable("vs12_lore_links");
      registry.enable("vs12_export");
      registry.engageKillSwitch();
      expect(registry.allAtDefaults, isTrue);

      registry.enable("vs12_lore_links");
      registry.resetToDefaults();

      expect(registry.killSwitchActive, isFalse);
      expect(registry.allAtDefaults, isTrue);
    });

    test("disengageKillSwitch returns to default OFF for all flags", () {
      final registry = FeatureFlagRegistry();
      registry.enable("vs12_lore_links");
      registry.enable("vs12_export");
      registry.engageKillSwitch();

      registry.disengageKillSwitch();

      expect(registry.killSwitchActive, isFalse);
      expect(registry.allAtDefaults, isTrue);
      expect(registry.isEnabled("vs12_lore_links"), isFalse);
    });
  });
}
