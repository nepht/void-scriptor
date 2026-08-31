// Sprint 111.11 - Effect, Toxicity and Interaction Model.
import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/encyclopedia_effect.dart";

void main() {
  group("EffectKind", () {
    test("has a defined set of effect kinds with labels", () {
      expect(EffectKind.values.length, greaterThanOrEqualTo(5));
      for (final k in EffectKind.values) {
        expect(k.label, isNotEmpty);
      }
    });
  });

  group("EffectEntry", () {
    test("rejects empty effect id", () {
      expect(
        () => EffectEntry.validated(
          effectId: "  ",
          description: "Calms nerves",
          kind: EffectKind.restorative,
        ),
        throwsArgumentError,
      );
    });
    test("rejects empty description", () {
      expect(
        () => EffectEntry.validated(
          effectId: "e1",
          description: " ",
          kind: EffectKind.restorative,
        ),
        throwsArgumentError,
      );
    });
    test("rejects intensity out of range 1..5", () {
      expect(
        () => EffectEntry.validated(
          effectId: "e1",
          description: "Calms nerves",
          kind: EffectKind.restorative,
          intensity: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => EffectEntry.validated(
          effectId: "e1",
          description: "Calms nerves",
          kind: EffectKind.restorative,
          intensity: 6,
        ),
        throwsArgumentError,
      );
    });
    test("keeps effect fields", () {
      final e = EffectEntry.validated(
        effectId: "calm",
        description: "Calms nerves",
        kind: EffectKind.restorative,
        intensity: 2,
      );
      expect(e.effectId, "calm");
      expect(e.description, "Calms nerves");
      expect(e.kind, EffectKind.restorative);
      expect(e.intensity, 2);
    });
    test("accepts effect without intensity", () {
      final e = EffectEntry.validated(
        effectId: "calm",
        description: "Calms nerves",
        kind: EffectKind.restorative,
      );
      expect(e.intensity, isNull);
    });
  });

  group("DoseRange", () {
    test("rejects empty unit", () {
      expect(
        () => DoseRange.validated(unit: "  ", minAmount: 1),
        throwsArgumentError,
      );
    });
    test("rejects when no bound is provided", () {
      expect(() => DoseRange.validated(unit: "grams"), throwsArgumentError);
    });
    test("rejects max below min", () {
      expect(
        () => DoseRange.validated(unit: "grams", minAmount: 5, maxAmount: 2),
        throwsArgumentError,
      );
    });
    test("keeps min and max bounds", () {
      final d = DoseRange.validated(unit: "grams", minAmount: 1, maxAmount: 3);
      expect(d.unit, "grams");
      expect(d.minAmount, 1);
      expect(d.maxAmount, 3);
    });
    test("accepts a single lower bound", () {
      final d = DoseRange.validated(unit: "drops", minAmount: 2);
      expect(d.minAmount, 2);
      expect(d.maxAmount, isNull);
    });
    test("accepts a single upper bound", () {
      final d = DoseRange.validated(unit: "drops", maxAmount: 9);
      expect(d.minAmount, isNull);
      expect(d.maxAmount, 9);
    });
  });

  group("OnsetWindow", () {
    test("rejects empty description", () {
      expect(
        () => OnsetWindow.validated(description: " "),
        throwsArgumentError,
      );
    });
    test("rejects max below min when both provided", () {
      expect(
        () => OnsetWindow.validated(
          description: "Rapid",
          minMinutes: 30,
          maxMinutes: 5,
        ),
        throwsArgumentError,
      );
    });
    test("keeps description with optional bounds", () {
      final w = OnsetWindow.validated(
        description: "5-15 minutes",
        minMinutes: 5,
        maxMinutes: 15,
      );
      expect(w.description, "5-15 minutes");
      expect(w.minMinutes, 5);
      expect(w.maxMinutes, 15);
    });
    test("accepts description without numeric bounds", () {
      final w = OnsetWindow.validated(description: "After ingestion");
      expect(w.description, "After ingestion");
      expect(w.minMinutes, isNull);
      expect(w.maxMinutes, isNull);
    });
  });

  group("DurationWindow", () {
    test("rejects empty description", () {
      expect(
        () => DurationWindow.validated(description: ""),
        throwsArgumentError,
      );
    });
    test("rejects max below min", () {
      expect(
        () => DurationWindow.validated(
          description: "Long",
          minMinutes: 20,
          maxMinutes: 10,
        ),
        throwsArgumentError,
      );
    });
    test("keeps duration fields", () {
      final d = DurationWindow.validated(
        description: "Up to an hour",
        maxMinutes: 60,
      );
      expect(d.description, "Up to an hour");
      expect(d.minMinutes, isNull);
      expect(d.maxMinutes, 60);
    });
  });

  group("ToxicityLevel", () {
    test("has a defined ladder with labels", () {
      expect(ToxicityLevel.values.length, greaterThanOrEqualTo(5));
      for (final l in ToxicityLevel.values) {
        expect(l.label, isNotEmpty);
      }
    });
  });

  group("ToxicityProfile", () {
    test("rejects empty symptoms when provided", () {
      expect(
        () => ToxicityProfile.validated(
          level: ToxicityLevel.moderate,
          symptoms: "  ",
        ),
        throwsArgumentError,
      );
    });
    test("keeps level, symptoms and threshold", () {
      final t = ToxicityProfile.validated(
        level: ToxicityLevel.high,
        symptoms: "Convulsions, sweating",
        thresholdDose: "10 grams",
      );
      expect(t.level, ToxicityLevel.high);
      expect(t.symptoms, "Convulsions, sweating");
      expect(t.thresholdDose, "10 grams");
    });
    test("accepts profile without symptoms and threshold", () {
      final t = ToxicityProfile.validated(level: ToxicityLevel.none);
      expect(t.symptoms, isNull);
      expect(t.thresholdDose, isNull);
    });
  });

  group("SubstanceInteraction", () {
    test("rejects empty interaction id", () {
      expect(
        () => SubstanceInteraction.validated(
          interactionId: " ",
          targetId: "alc",
          description: "Amplifies drowsiness",
          kind: InteractionKind.synergistic,
        ),
        throwsArgumentError,
      );
    });
    test("rejects empty target id", () {
      expect(
        () => SubstanceInteraction.validated(
          interactionId: "i1",
          targetId: "  ",
          description: "Amplifies drowsiness",
          kind: InteractionKind.synergistic,
        ),
        throwsArgumentError,
      );
    });
    test("rejects empty description", () {
      expect(
        () => SubstanceInteraction.validated(
          interactionId: "i1",
          targetId: "alc",
          description: "",
          kind: InteractionKind.synergistic,
        ),
        throwsArgumentError,
      );
    });
    test("rejects severity out of 1..5", () {
      expect(
        () => SubstanceInteraction.validated(
          interactionId: "i1",
          targetId: "alc",
          description: "A",
          kind: InteractionKind.synergistic,
          severity: 7,
        ),
        throwsArgumentError,
      );
    });
    test("keeps interaction fields", () {
      final i = SubstanceInteraction.validated(
        interactionId: "with_alc",
        targetId: "alc",
        description: "Amplifies drowsiness",
        kind: InteractionKind.antagonistic,
        severity: 4,
      );
      expect(i.interactionId, "with_alc");
      expect(i.targetId, "alc");
      expect(i.description, "Amplifies drowsiness");
      expect(i.kind, InteractionKind.antagonistic);
      expect(i.severity, 4);
    });
    test("accepts interaction without severity", () {
      final i = SubstanceInteraction.validated(
        interactionId: "i1",
        targetId: "alc",
        description: "A",
        kind: InteractionKind.neutral,
      );
      expect(i.severity, isNull);
    });
  });

  group("EffectRecord validated", () {
    test("rejects empty ingredient id", () {
      expect(
        () => EffectRecord.validated(ingredientId: " "),
        throwsArgumentError,
      );
    });
    test("stores basic fields with empty collections", () {
      final r = EffectRecord.validated(ingredientId: "vb");
      expect(r.ingredientId, "vb");
      expect(r.effects, isEmpty);
      expect(r.interactions, isEmpty);
      expect(r.doseRange, isNull);
      expect(r.onset, isNull);
      expect(r.duration, isNull);
      expect(r.toxicity, isNull);
    });
    test("stores a complete profile", () {
      final r = EffectRecord.validated(
        ingredientId: "vb",
        effects: [
          EffectEntry.validated(
            effectId: "calm",
            description: "Calms nerves",
            kind: EffectKind.restorative,
          ),
        ],
        doseRange: DoseRange.validated(
          unit: "grams",
          minAmount: 1,
          maxAmount: 3,
        ),
        onset: OnsetWindow.validated(
          description: "5-15 minutes",
          minMinutes: 5,
        ),
        duration: DurationWindow.validated(description: "Up to an hour"),
        toxicity: ToxicityProfile.validated(
          level: ToxicityLevel.low,
          symptoms: "Drowsiness",
        ),
        interactions: [
          SubstanceInteraction.validated(
            interactionId: "i1",
            targetId: "alc",
            description: "Amplifies drowsiness",
            kind: InteractionKind.synergistic,
          ),
        ],
      );
      expect(r.effects, hasLength(1));
      expect(r.interactions, hasLength(1));
      expect(r.toxicity!.level, ToxicityLevel.low);
    });
  });

  group("EffectRecord duplicate guards", () {
    test("rejects duplicate effect ids", () {
      expect(
        () => EffectRecord.validated(
          ingredientId: "vb",
          effects: [
            EffectEntry.validated(
              effectId: "calm",
              description: "A",
              kind: EffectKind.restorative,
            ),
            EffectEntry.validated(
              effectId: "calm",
              description: "B",
              kind: EffectKind.restorative,
            ),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate interaction ids", () {
      expect(
        () => EffectRecord.validated(
          ingredientId: "vb",
          interactions: [
            SubstanceInteraction.validated(
              interactionId: "i1",
              targetId: "alc",
              description: "A",
              kind: InteractionKind.synergistic,
            ),
            SubstanceInteraction.validated(
              interactionId: "i1",
              targetId: "herb",
              description: "B",
              kind: InteractionKind.antagonistic,
            ),
          ],
        ),
        throwsArgumentError,
      );
    });
  });

  group("EffectRecord behavior", () {
    test("hasKind detects a matching effect kind", () {
      final r = EffectRecord.validated(
        ingredientId: "vb",
        effects: [
          EffectEntry.validated(
            effectId: "pain",
            description: "Deadens pain",
            kind: EffectKind.harmful,
          ),
        ],
      );
      expect(r.hasKind(EffectKind.harmful), isTrue);
      expect(r.hasKind(EffectKind.restorative), isFalse);
    });
    test("hasHarmfulEffect true when a harmful effect exists", () {
      final r = EffectRecord.validated(
        ingredientId: "vb",
        effects: [
          EffectEntry.validated(
            effectId: "pain",
            description: "Deadens pain",
            kind: EffectKind.harmful,
          ),
        ],
      );
      expect(r.hasHarmfulEffect(), isTrue);
    });
    test("isToxicAtLeast compares toxicity ladder", () {
      final r = EffectRecord.validated(
        ingredientId: "vb",
        toxicity: ToxicityProfile.validated(level: ToxicityLevel.moderate),
      );
      expect(r.isToxicAtLeast(ToxicityLevel.low), isTrue);
      expect(r.isToxicAtLeast(ToxicityLevel.moderate), isTrue);
      expect(r.isToxicAtLeast(ToxicityLevel.high), isFalse);
    });
    test("isToxicAtLeast false when no toxicity declared", () {
      final r = EffectRecord.validated(ingredientId: "vb");
      expect(r.isToxicAtLeast(ToxicityLevel.low), isFalse);
    });
    test("interactsWith detects a matching target", () {
      final r = EffectRecord.validated(
        ingredientId: "vb",
        interactions: [
          SubstanceInteraction.validated(
            interactionId: "i1",
            targetId: "alc",
            description: "A",
            kind: InteractionKind.synergistic,
          ),
        ],
      );
      expect(r.interactsWith("alc"), isTrue);
      expect(r.interactsWith("herb"), isFalse);
    });
  });
}
