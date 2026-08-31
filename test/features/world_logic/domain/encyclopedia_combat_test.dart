// Sprint 111.17 - Weakness, Defense and Combat Reference.
import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/encyclopedia_combat.dart";

void main() {
  group("CombatWeakness", () {
    test("rejects empty weakness id", () {
      expect(
        () => CombatWeakness.validated(weaknessId: " ", name: "Cold"),
        throwsArgumentError,
      );
    });
    test("rejects empty name", () {
      expect(
        () => CombatWeakness.validated(weaknessId: "cold", name: ""),
        throwsArgumentError,
      );
    });
    test("keeps weakness fields", () {
      final w = CombatWeakness.validated(
        weaknessId: "cold",
        name: "Cold",
        description: "Slows movement",
      );
      expect(w.weaknessId, "cold");
      expect(w.name, "Cold");
      expect(w.description, "Slows movement");
    });
    test("accepts weakness without description", () {
      final w = CombatWeakness.validated(weaknessId: "cold", name: "Cold");
      expect(w.description, isNull);
    });
  });

  group("CombatResistance", () {
    test("rejects empty resistance id", () {
      expect(
        () => CombatResistance.validated(resistanceId: " ", name: "Fire"),
        throwsArgumentError,
      );
    });
    test("rejects empty name", () {
      expect(
        () => CombatResistance.validated(resistanceId: "fire", name: "  "),
        throwsArgumentError,
      );
    });
    test("keeps resistance fields", () {
      final r = CombatResistance.validated(
        resistanceId: "fire",
        name: "Fire",
        level: "Immune",
      );
      expect(r.resistanceId, "fire");
      expect(r.name, "Fire");
      expect(r.level, "Immune");
    });
    test("accepts resistance without level", () {
      final r = CombatResistance.validated(resistanceId: "fire", name: "Fire");
      expect(r.level, isNull);
    });
  });

  group("AttackPattern", () {
    test("rejects empty pattern id", () {
      expect(
        () => AttackPattern.validated(patternId: " ", name: "Tail sweep"),
        throwsArgumentError,
      );
    });
    test("rejects empty name", () {
      expect(
        () => AttackPattern.validated(patternId: "tail", name: ""),
        throwsArgumentError,
      );
    });
    test("keeps pattern fields", () {
      final p = AttackPattern.validated(
        patternId: "tail",
        name: "Tail sweep",
        description: "Wide arc behind",
      );
      expect(p.patternId, "tail");
      expect(p.name, "Tail sweep");
      expect(p.description, "Wide arc behind");
    });
    test("accepts pattern without description", () {
      final p = AttackPattern.validated(patternId: "tail", name: "Tail sweep");
      expect(p.description, isNull);
    });
  });

  group("WarningSign", () {
    test("rejects empty sign id", () {
      expect(
        () => WarningSign.validated(signId: " ", description: "Hissing"),
        throwsArgumentError,
      );
    });
    test("rejects empty description", () {
      expect(
        () => WarningSign.validated(signId: "hiss", description: " "),
        throwsArgumentError,
      );
    });
    test("keeps warning sign fields", () {
      final s = WarningSign.validated(
        signId: "hiss",
        description: "Loud hiss before strike",
      );
      expect(s.signId, "hiss");
      expect(s.description, "Loud hiss before strike");
    });
  });

  group("CombatTactic", () {
    test("rejects empty tactic id", () {
      expect(
        () => CombatTactic.validated(tacticId: " ", name: "Kite"),
        throwsArgumentError,
      );
    });
    test("rejects empty name", () {
      expect(
        () => CombatTactic.validated(tacticId: "kite", name: ""),
        throwsArgumentError,
      );
    });
    test("keeps tactic fields", () {
      final t = CombatTactic.validated(
        tacticId: "kite",
        name: "Kite with ranged fire",
        description: "Keep distance",
      );
      expect(t.tacticId, "kite");
      expect(t.name, "Kite with ranged fire");
      expect(t.description, "Keep distance");
    });
    test("accepts tactic without description", () {
      final t = CombatTactic.validated(tacticId: "kite", name: "Kite");
      expect(t.description, isNull);
    });
  });

  group("SourceEvidence", () {
    test("rejects empty evidence id", () {
      expect(
        () => SourceEvidence.validated(
          evidenceId: " ",
          reference: "Bestiary p.12",
        ),
        throwsArgumentError,
      );
    });
    test("rejects empty reference", () {
      expect(
        () => SourceEvidence.validated(evidenceId: "e1", reference: ""),
        throwsArgumentError,
      );
    });
    test("keeps evidence fields", () {
      final e = SourceEvidence.validated(
        evidenceId: "e1",
        reference: "Bestiary p.12",
        note: "Witnessed by ranger",
      );
      expect(e.evidenceId, "e1");
      expect(e.reference, "Bestiary p.12");
      expect(e.note, "Witnessed by ranger");
    });
    test("accepts evidence without note", () {
      final e = SourceEvidence.validated(
        evidenceId: "e1",
        reference: "Bestiary p.12",
      );
      expect(e.note, isNull);
    });
  });

  group("CombatProfile validated", () {
    test("rejects empty species id", () {
      expect(
        () => CombatProfile.validated(speciesId: " "),
        throwsArgumentError,
      );
    });
    test("stores basic fields with empty collections", () {
      final c = CombatProfile.validated(speciesId: "fw");
      expect(c.speciesId, "fw");
      expect(c.weaknesses, isEmpty);
      expect(c.resistances, isEmpty);
      expect(c.attackPatterns, isEmpty);
      expect(c.warningSigns, isEmpty);
      expect(c.tactics, isEmpty);
      expect(c.sourceEvidence, isEmpty);
    });
    test("stores a complete combat profile", () {
      final c = CombatProfile.validated(
        speciesId: "fw",
        weaknesses: [
          CombatWeakness.validated(weaknessId: "cold", name: "Cold"),
        ],
        resistances: [
          CombatResistance.validated(resistanceId: "fire", name: "Fire"),
        ],
        attackPatterns: [
          AttackPattern.validated(patternId: "tail", name: "Tail sweep"),
        ],
        warningSigns: [
          WarningSign.validated(signId: "hiss", description: "Hiss"),
        ],
        tactics: [CombatTactic.validated(tacticId: "kite", name: "Kite")],
        sourceEvidence: [
          SourceEvidence.validated(
            evidenceId: "e1",
            reference: "Bestiary p.12",
          ),
        ],
      );
      expect(c.weaknesses, hasLength(1));
      expect(c.resistances, hasLength(1));
      expect(c.attackPatterns, hasLength(1));
      expect(c.warningSigns, hasLength(1));
      expect(c.tactics, hasLength(1));
      expect(c.sourceEvidence, hasLength(1));
    });
  });

  group("CombatProfile duplicate guards", () {
    test("rejects duplicate weakness ids", () {
      expect(
        () => CombatProfile.validated(
          speciesId: "fw",
          weaknesses: [
            CombatWeakness.validated(weaknessId: "cold", name: "A"),
            CombatWeakness.validated(weaknessId: "cold", name: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate resistance ids", () {
      expect(
        () => CombatProfile.validated(
          speciesId: "fw",
          resistances: [
            CombatResistance.validated(resistanceId: "fire", name: "A"),
            CombatResistance.validated(resistanceId: "fire", name: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate attack pattern ids", () {
      expect(
        () => CombatProfile.validated(
          speciesId: "fw",
          attackPatterns: [
            AttackPattern.validated(patternId: "tail", name: "A"),
            AttackPattern.validated(patternId: "tail", name: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate warning sign ids", () {
      expect(
        () => CombatProfile.validated(
          speciesId: "fw",
          warningSigns: [
            WarningSign.validated(signId: "hiss", description: "A"),
            WarningSign.validated(signId: "hiss", description: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate tactic ids", () {
      expect(
        () => CombatProfile.validated(
          speciesId: "fw",
          tactics: [
            CombatTactic.validated(tacticId: "kite", name: "A"),
            CombatTactic.validated(tacticId: "kite", name: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate evidence ids", () {
      expect(
        () => CombatProfile.validated(
          speciesId: "fw",
          sourceEvidence: [
            SourceEvidence.validated(evidenceId: "e1", reference: "A"),
            SourceEvidence.validated(evidenceId: "e1", reference: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
  });

  group("CombatProfile behavior", () {
    test("hasWeakness detects membership", () {
      final c = CombatProfile.validated(
        speciesId: "fw",
        weaknesses: [
          CombatWeakness.validated(weaknessId: "cold", name: "Cold"),
        ],
      );
      expect(c.hasWeakness("cold"), isTrue);
      expect(c.hasWeakness("silver"), isFalse);
    });
    test("hasResistance detects membership", () {
      final c = CombatProfile.validated(
        speciesId: "fw",
        resistances: [
          CombatResistance.validated(resistanceId: "fire", name: "Fire"),
        ],
      );
      expect(c.hasResistance("fire"), isTrue);
      expect(c.hasResistance("ice"), isFalse);
    });
    test("hasAttackPattern detects membership", () {
      final c = CombatProfile.validated(
        speciesId: "fw",
        attackPatterns: [
          AttackPattern.validated(patternId: "tail", name: "Tail"),
        ],
      );
      expect(c.hasAttackPattern("tail"), isTrue);
      expect(c.hasAttackPattern("bite"), isFalse);
    });
    test("hasWarningSign detects membership", () {
      final c = CombatProfile.validated(
        speciesId: "fw",
        warningSigns: [
          WarningSign.validated(signId: "hiss", description: "Hiss"),
        ],
      );
      expect(c.hasWarningSign("hiss"), isTrue);
      expect(c.hasWarningSign("growl"), isFalse);
    });
  });

  group("CombatCatalog", () {
    test("empty catalog has no profiles", () {
      final c = CombatCatalog.empty();
      expect(c.length, 0);
      expect(c.profileFor("fw"), isNull);
    });
    test("withProfiles guards duplicate species ids", () {
      final c = CombatProfile.validated(speciesId: "fw");
      final cat = CombatCatalog.withProfiles([c]);
      expect(cat.length, 1);
      expect(cat.profileFor("fw"), same(c));
      expect(() => CombatCatalog.withProfiles([c, c]), throwsArgumentError);
    });
    test("weakTo returns sorted by species id", () {
      final z = CombatProfile.validated(
        speciesId: "z",
        weaknesses: [
          CombatWeakness.validated(weaknessId: "cold", name: "Cold"),
        ],
      );
      final a = CombatProfile.validated(
        speciesId: "a",
        weaknesses: [
          CombatWeakness.validated(weaknessId: "cold", name: "Cold"),
        ],
      );
      final m = CombatProfile.validated(speciesId: "m");
      final cat = CombatCatalog.withProfiles([z, a, m]);
      expect(cat.weakTo("cold").map((p) => p.speciesId).toList(), ["a", "z"]);
    });
  });
}
