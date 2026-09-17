/// Sprint 112.17 domain integration for character chronology and identity.
///
/// This is deliberately a pure, deterministic boundary. Persistence and UI may
/// consume the result later, but cannot alter the historical rules here.
enum FamilyRelationKind { biological, adopted, guardian }

enum IdentityLinkKind { alias, reincarnation, historicalRecord }

class CharacterLifespan {
  const CharacterLifespan({required this.birthTick, this.deathTick})
    : assert(birthTick >= 0),
      assert(deathTick == null || deathTick >= birthTick);

  final int birthTick;
  final int? deathTick;

  bool get isAlive => true;
  bool isAliveAt(int tick) =>
      tick >= birthTick && (deathTick == null || tick <= deathTick!);
}

class FamilyRelation {
  const FamilyRelation({
    required this.parentId,
    required this.childId,
    required this.kind,
  });
  final String parentId;
  final String childId;
  final FamilyRelationKind kind;
}

class HistoricalCharacterName {
  const HistoricalCharacterName({
    required this.name,
    required this.validFrom,
    this.validUntil,
  }) : assert(validFrom >= 0),
       assert(validUntil == null || validUntil >= validFrom);
  final String name;
  final int validFrom;
  final int? validUntil;

  bool isActiveAt(int tick) =>
      tick >= validFrom && (validUntil == null || tick <= validUntil!);
}

class IdentityLink {
  const IdentityLink({
    required this.sourceId,
    required this.targetId,
    required this.kind,
  });
  final String sourceId;
  final String targetId;
  final IdentityLinkKind kind;
}

class FamilyRuleViolation implements Exception {
  const FamilyRuleViolation(this.message);
  final String message;
  @override
  String toString() => 'FamilyRuleViolation: $message';
}

class GenealogyAgeCharacterIdentityScenario {
  const GenealogyAgeCharacterIdentityScenario({
    required this.lifespans,
    required this.familyRelations,
    required this.names,
    required this.inheritance,
    required this.identityLinks,
  });
  final Map<String, CharacterLifespan> lifespans;
  final List<FamilyRelation> familyRelations;
  final Map<String, List<HistoricalCharacterName>> names;
  final Map<String, List<String>> inheritance;
  final List<IdentityLink> identityLinks;
}

class GenealogyAgeCharacterIdentityResult {
  const GenealogyAgeCharacterIdentityResult(this.scenario, this.atTick);
  final GenealogyAgeCharacterIdentityScenario scenario;
  final int atTick;

  CharacterLifespan? lifespan(String id) => scenario.lifespans[id];

  int? ageOf(String id) {
    final life = lifespan(id);
    if (life == null || atTick < life.birthTick) return null;
    return atTick - life.birthTick;
  }

  List<String> parentsOf(String id) => scenario.familyRelations
      .where((r) => r.childId == id)
      .map((r) => r.parentId)
      .toList(growable: false);

  String? nameOf(String id) {
    final active = (scenario.names[id] ?? const <HistoricalCharacterName>[])
        .where((name) => name.isActiveAt(atTick))
        .toList();
    if (active.isEmpty) return null;
    active.sort((a, b) => a.validFrom.compareTo(b.validFrom));
    return active.last.name;
  }

  List<String> inheritanceOrderFor(String id) =>
      List<String>.unmodifiable(scenario.inheritance[id] ?? const <String>[]);

  List<IdentityLink> linksFor(String id) => scenario.identityLinks
      .where((link) => link.sourceId == id)
      .toList(growable: false);
}

class GenealogyAgeCharacterIdentityIntegration {
  const GenealogyAgeCharacterIdentityIntegration();

  GenealogyAgeCharacterIdentityResult evaluate(
    GenealogyAgeCharacterIdentityScenario scenario, {
    required int atTick,
  }) {
    if (atTick < 0) {
      throw ArgumentError.value(atTick, 'atTick', 'must be non-negative');
    }
    validateLifespans(scenario.lifespans);
    validateRelations(scenario.familyRelations);
    return GenealogyAgeCharacterIdentityResult(scenario, atTick);
  }

  void validateLifespans(Map<String, CharacterLifespan> lifespans) {
    for (final entry in lifespans.entries) {
      final life = entry.value;
      if (life.deathTick != null && life.deathTick! < life.birthTick) {
        throw FamilyRuleViolation('death precedes birth for ${entry.key}');
      }
    }
  }

  void validateRelations(List<FamilyRelation> relations) {
    final children = <String, List<String>>{};
    for (final relation in relations) {
      if (relation.parentId == relation.childId) {
        throw const FamilyRuleViolation(
          'family relation cannot self-reference',
        );
      }
      if (relation.kind == FamilyRelationKind.biological ||
          relation.kind == FamilyRelationKind.adopted) {
        children
            .putIfAbsent(relation.parentId, () => <String>[])
            .add(relation.childId);
      }
    }
    final visiting = <String>{};
    final visited = <String>{};
    void visit(String id) {
      if (!visiting.add(id)) {
        throw const FamilyRuleViolation('family relation cycle detected');
      }
      if (!visited.add(id)) {
        visiting.remove(id);
        return;
      }
      for (final child in children[id] ?? const <String>[]) {
        visit(child);
      }
      visiting.remove(id);
    }

    for (final id in children.keys) {
      if (!visited.contains(id)) visit(id);
    }
  }
}
