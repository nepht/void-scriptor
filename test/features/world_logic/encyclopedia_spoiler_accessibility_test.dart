// Sprint 111.8 - Spoiler, Feature Flags & Accessibility Baseline.
//
// Domain-only contract for reveal state, safe rollout flags, keyboard
// navigation mapping, screen reader labels, and nonvisual fallbacks.
//
// No persistence, UI, locale, network, wall clock, or random input.
import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/encyclopedia_spoiler_accessibility.dart";

void main() {
  group("SpoilerPolicy", () {
    test("spoiler levels have a defined escalation order", () {
      expect(SpoilerLevel.values.length, 4);
      expect(SpoilerLevel.safe.index, lessThan(SpoilerLevel.mild.index));
      expect(SpoilerLevel.mild.index, lessThan(SpoilerLevel.major.index));
      expect(SpoilerLevel.major.index, lessThan(SpoilerLevel.ending.index));
    });

    test("spoiler policy defaults to the safest level", () {
      final policy = SpoilerPolicy();
      expect(policy.defaultLevel, SpoilerLevel.safe);
      expect(policy.overrides, isEmpty);
    });

    test("spoiler policy allows content at or below the audience level", () {
      final policy = SpoilerPolicy(defaultLevel: SpoilerLevel.mild);
      expect(policy.allows(SpoilerLevel.safe), isTrue);
      expect(policy.allows(SpoilerLevel.mild), isTrue);
      expect(policy.allows(SpoilerLevel.major), isFalse);
      expect(policy.allows(SpoilerLevel.ending), isFalse);
    });

    test("per-record overrides beat the default level", () {
      final policy = SpoilerPolicy(
        defaultLevel: SpoilerLevel.safe,
        overrides: {"creature:void-drake": SpoilerLevel.ending},
      );
      expect(
        policy.allows(SpoilerLevel.ending, recordKey: "creature:void-drake"),
        isTrue,
      );
      expect(
        policy.allows(SpoilerLevel.ending, recordKey: "creature:other"),
        isFalse,
      );
    });

    test("spoiler policy rejects empty override keys", () {
      expect(
        () => SpoilerPolicy(overrides: {"  ": SpoilerLevel.safe}),
        throwsArgumentError,
      );
    });
  });

  group("RevealPoint", () {
    test("rejects empty reveal id or story link", () {
      expect(
        () => RevealPoint.validated(revealId: " ", storyLink: "story:1"),
        throwsArgumentError,
      );
      expect(
        () => RevealPoint.validated(revealId: "r1", storyLink: ""),
        throwsArgumentError,
      );
    });

    test("keeps spoiler level and chronological tick", () {
      final point = RevealPoint.validated(
        revealId: "r1",
        storyLink: "story:twist-1",
        tick: 420,
        level: SpoilerLevel.major,
      );
      expect(point.revealId, "r1");
      expect(point.storyLink, "story:twist-1");
      expect(point.tick, 420);
      expect(point.level, SpoilerLevel.major);
      expect(point.revealed, isFalse);
    });

    test("markRevealed returns an immutable revealed copy", () {
      final point = RevealPoint.validated(revealId: "r1", storyLink: "story:1");
      final revealed = point.markRevealed();
      expect(revealed.revealed, isTrue);
      expect(point.revealed, isFalse);
    });

    test("registering the same reveal id twice is rejected", () {
      final registry = RevealRegistry();
      registry.register(
        RevealPoint.validated(revealId: "r1", storyLink: "story:1"),
      );
      expect(
        () => registry.register(
          RevealPoint.validated(revealId: "r1", storyLink: "story:2"),
        ),
        throwsArgumentError,
      );
      expect(registry.pendingIds, ["r1"]);
    });
  });

  group("EncyclopediaFeatureFlags", () {
    test("wave 3 catalog covers the six canonical capabilities", () {
      expect(
        EncyclopediaFeatureFlags.wave3Catalog,
        unorderedEquals(["F23", "F24", "F26", "F27", "F28", "F29"]),
      );
    });

    test("unknown feature ids are rejected", () {
      expect(
        () => const EncyclopediaFeatureFlags().withFlag("F99", true),
        throwsArgumentError,
      );
    });

    test("flags default to disabled for safe rollout", () {
      const flags = EncyclopediaFeatureFlags();
      expect(flags.isEnabled("F23"), isFalse);
      expect(flags.isEnabled("F29"), isFalse);
    });

    test("withFlag enables only the targeted feature", () {
      const base = EncyclopediaFeatureFlags();
      final enabled = base.withFlag("F24", true);
      expect(enabled.isEnabled("F24"), isTrue);
      expect(enabled.isEnabled("F23"), isFalse);
      expect(base.isEnabled("F24"), isFalse);
    });

    test("withFlag is idempotent for the same value", () {
      final flags = const EncyclopediaFeatureFlags().withFlag("F23", true);
      expect(identical(flags, flags.withFlag("F23", true)), isTrue);
    });
  });

  group("KeyboardNavigationMap", () {
    test("rejects empty action or key labels", () {
      expect(
        () => KeyboardNavigationMap().add(
          const KeyboardShortcut(action: " ", key: "K", control: true),
        ),
        throwsArgumentError,
      );
      expect(
        () => KeyboardNavigationMap().add(
          const KeyboardShortcut(action: "search", key: "  "),
        ),
        throwsArgumentError,
      );
    });

    test("rejects duplicate actions and conflicting bindings", () {
      final map = KeyboardNavigationMap().add(
        const KeyboardShortcut(action: "search", key: "K", control: true),
      );
      expect(
        () => map.add(const KeyboardShortcut(action: "search", key: "F")),
        throwsArgumentError,
      );
      expect(
        () => map.add(
          const KeyboardShortcut(
            action: "focusExplorer",
            key: "K",
            control: true,
          ),
        ),
        throwsArgumentError,
      );
      expect(map.shortcuts.single.action, "search");
    });

    test("different modifier sets are distinct bindings", () {
      final map = KeyboardNavigationMap()
          .add(
            const KeyboardShortcut(action: "search", key: "K", control: true),
          )
          .add(
            const KeyboardShortcut(
              action: "commandPalette",
              key: "K",
              control: true,
              shift: true,
            ),
          );
      expect(map.shortcuts, hasLength(2));
      expect(map.bindingFor("search")!.describe(), "Ctrl+K");
      expect(map.bindingFor("commandPalette")!.describe(), "Ctrl+Shift+K");
    });
  });

  group("ScreenReaderLabels", () {
    test("rejects empty element keys or labels", () {
      expect(
        () => const ScreenReaderLabels().add("  ", "Search"),
        throwsArgumentError,
      );
      expect(
        () => const ScreenReaderLabels().add("search", "  "),
        throwsArgumentError,
      );
    });

    test("stores and resolves explicit labels", () {
      final labels = const ScreenReaderLabels().add(
        "encyclopedia.search",
        "Cari ensiklopedia",
      );
      expect(labels.labelFor("encyclopedia.search"), "Cari ensiklopedia");
    });

    test("missing labels fall back to the explicit fallback", () {
      const labels = ScreenReaderLabels(fallback: "tanpa label");
      expect(labels.labelFor("unknown.element"), "tanpa label");
    });
  });

  group("NonvisualFallback", () {
    test("rejects empty element keys or descriptions", () {
      expect(
        () => NonvisualFallback().register("  ", "graph"),
        throwsArgumentError,
      );
      expect(
        () => NonvisualFallback().register("graph", ""),
        throwsArgumentError,
      );
    });

    test("requires a nonvisual description for required elements", () {
      final fallback = NonvisualFallback().register(
        "encyclopedia.graph",
        "Graf relasi: 3 simpul, 2 sisi",
      );
      expect(
        fallback.describe("encyclopedia.graph"),
        "Graf relasi: 3 simpul, 2 sisi",
      );
      expect(
        () => fallback.requireDescription("encyclopedia.map"),
        throwsArgumentError,
      );
    });
  });
}
