/// Sprint 112.19 domain integration: economy, technology, and civilization.
/// Deterministic and persistence/UI independent.
class CivilizationSource {
  final String revision;
  final String reason;
  const CivilizationSource({required this.revision, required this.reason});
}

enum CivilizationFindingKind {
  resourceDependency,
  productionScale,
  technologyPrerequisite,
  trade,
  era,
}

class CivilizationFinding {
  final CivilizationFindingKind kind;
  final String subjectId;
  const CivilizationFinding(this.kind, this.subjectId);
}

class CivilizationResource {
  final String id;
  final num available;
  final CivilizationSource source;
  const CivilizationResource({
    required this.id,
    required this.available,
    required this.source,
  });
}

class CivilizationProduction {
  final String id;
  final String outputId;
  final num scale;
  final Map<String, num> requiredResources;
  final num capacity;
  final CivilizationSource source;
  const CivilizationProduction({
    required this.id,
    required this.outputId,
    required this.scale,
    required this.requiredResources,
    required this.capacity,
    required this.source,
  });
}

class CivilizationPriceEffect {
  final String goodId;
  final num multiplier;
  final int validFrom;
  final int? validUntil;
  final CivilizationSource source;
  const CivilizationPriceEffect({
    required this.goodId,
    required this.multiplier,
    required this.validFrom,
    required this.validUntil,
    required this.source,
  });
  bool isActiveAt(int tick) =>
      tick >= validFrom && (validUntil == null || tick <= validUntil!);
}

class CivilizationTradeEffect {
  final String id;
  final String fromFactionId;
  final String toFactionId;
  final String commodity;
  final num quantity;
  final int validFrom;
  final int? validUntil;
  final CivilizationSource source;
  const CivilizationTradeEffect({
    required this.id,
    required this.fromFactionId,
    required this.toFactionId,
    required this.commodity,
    required this.quantity,
    required this.validFrom,
    required this.validUntil,
    required this.source,
  });
  bool isActiveAt(int tick) =>
      tick >= validFrom && (validUntil == null || tick <= validUntil!);
}

class CivilizationTechnology {
  final String id;
  final List<String> prerequisites;
  final int discoveredAt;
  final CivilizationSource source;
  const CivilizationTechnology({
    required this.id,
    required this.prerequisites,
    required this.discoveredAt,
    required this.source,
  });
}

class CivilizationEra {
  final String id;
  final int startTick;
  final int endTick;
  final CivilizationSource source;
  const CivilizationEra({
    required this.id,
    required this.startTick,
    required this.endTick,
    required this.source,
  });
  bool contains(int tick) => tick >= startTick && tick <= endTick;
}

class EconomyTechnologyCivilizationResult {
  final bool resourceDependenciesSatisfied;
  final List<CivilizationPriceEffect> activePriceEffects;
  final List<CivilizationTradeEffect> activeTradeEffects;
  final List<CivilizationFinding> findings;
  const EconomyTechnologyCivilizationResult({
    required this.resourceDependenciesSatisfied,
    required this.activePriceEffects,
    required this.activeTradeEffects,
    required this.findings,
  });
}

class EconomyTechnologyCivilizationIntegration {
  const EconomyTechnologyCivilizationIntegration();

  EconomyTechnologyCivilizationResult evaluate({
    required List<CivilizationResource> resources,
    required CivilizationProduction? production,
    required List<CivilizationPriceEffect> prices,
    required List<CivilizationTechnology> technologies,
    required List<CivilizationTradeEffect> tradeLinks,
    required CivilizationEra era,
    required int atTick,
  }) {
    if (atTick < 0) {
      throw ArgumentError.value(atTick, 'atTick', 'must be non-negative');
    }
    final available = <String, num>{
      for (final r in resources) r.id: r.available,
    };
    final findings = <CivilizationFinding>[];
    var dependenciesSatisfied = true;
    if (production != null) {
      for (final entry in production.requiredResources.entries) {
        if ((available[entry.key] ?? 0) < entry.value * production.scale) {
          dependenciesSatisfied = false;
          findings.add(
            CivilizationFinding(
              CivilizationFindingKind.resourceDependency,
              entry.key,
            ),
          );
        }
      }
      if (production.scale > production.capacity) {
        findings.add(
          CivilizationFinding(
            CivilizationFindingKind.productionScale,
            production.id,
          ),
        );
      }
    }
    for (final technology in technologies) {
      if (technology.discoveredAt > atTick) {
        findings.add(
          CivilizationFinding(
            CivilizationFindingKind.technologyPrerequisite,
            technology.id,
          ),
        );
      }
      for (final prerequisite in technology.prerequisites) {
        final dependency = technologies
            .where((t) => t.id == prerequisite)
            .firstOrNull;
        if (dependency == null || dependency.discoveredAt > atTick) {
          findings.add(
            CivilizationFinding(
              CivilizationFindingKind.technologyPrerequisite,
              technology.id,
            ),
          );
          break;
        }
      }
    }
    if (!era.contains(atTick)) {
      findings.add(CivilizationFinding(CivilizationFindingKind.era, era.id));
    }
    final activePrices = prices
        .where((p) => p.isActiveAt(atTick))
        .toList(growable: false);
    final activeTrades = tradeLinks
        .where((t) => t.isActiveAt(atTick))
        .toList(growable: false);
    return EconomyTechnologyCivilizationResult(
      resourceDependenciesSatisfied: dependenciesSatisfied,
      activePriceEffects: activePrices,
      activeTradeEffects: activeTrades,
      findings: List.unmodifiable(findings),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
