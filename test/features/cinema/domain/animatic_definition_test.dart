// Sprint 78 -- Step 78.81 (BAGIAN LXXIII -- Animatic Definition).
//
// Source: full_sprint_sources/SPRINT_078.md, BAGIAN LXXIII.
// Canonical formula:
//   Storyboard Images + Timing + Camera simulation foundation + Temporary Audio
//   = ANIMATIC
//
// This test pins the four required animatic definition components, their
// canonical display labels, the immutable order, and the formula string so
// downstream animatic preview, editor and persistence layers can rely on a
// single source of truth.

import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/cinema/domain/animatic_definition.dart";

void main() {
  group("AnimaticDefinition (Step 78.81 -- BAGIAN LXXIII)", () {
    test("canonical components are exactly four in blueprint order", () {
      expect(AnimaticComponent.canonical, hasLength(4));
      expect(
        AnimaticComponent.canonical.map((c) => c.label).toList(),
        const <String>[
          "Storyboard Images",
          "Timing",
          "Camera simulation foundation",
          "Temporary Audio",
        ],
      );
    });

    test("every component exposes its blueprint display label", () {
      for (final component in AnimaticComponent.canonical) {
        expect(component.label, isNotEmpty);
      }
    });

    test("canonical list is immutable", () {
      expect(
        () =>
            AnimaticComponent.canonical.add(AnimaticComponent.storyboardImages),
        throwsUnsupportedError,
      );
    });

    test("formula equals blueprint concatenation", () {
      expect(
        AnimaticDefinition.formula,
        "Storyboard Images + Timing + Camera simulation foundation + Temporary Audio = ANIMATIC",
      );
    });

    test("default definition yields four components in blueprint order", () {
      const definition = AnimaticDefinition.canonical;
      expect(definition.components, AnimaticComponent.canonical);
    });
  });
}
