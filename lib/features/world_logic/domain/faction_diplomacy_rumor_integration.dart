import 'faction_diplomacy.dart';
import 'rumor_propagation.dart';

/// A world event that may change what a faction knows at a given tick.
class FactionDiplomacyEvent {
  final String id;
  final String factionId;
  final int tick;
  final String description;

  const FactionDiplomacyEvent({
    required this.id,
    required this.factionId,
    required this.tick,
    required this.description,
  });
}

/// Inputs for the deterministic faction/diplomacy/rumor integration boundary.
class FactionDiplomacyRumorScenario {
  final List<FactionDiplomacyEntry> diplomacy;
  final List<FactionDiplomacyEvent> events;
  final Map<String, Set<String>> knowledgeByFaction;
  final RumorSeed rumorSeed;
  final RumorNetwork rumorNetwork;

  const FactionDiplomacyRumorScenario({
    required this.diplomacy,
    required this.events,
    required this.knowledgeByFaction,
    required this.rumorSeed,
    required this.rumorNetwork,
  });
}

class FactionDiplomacyRumorResult {
  final int atTick;
  final String observerId;
  final List<FactionDiplomacyEntry> activeDiplomacy;
  final List<FactionDiplomacyEvent> eventsAtOrBeforeTick;
  final Set<String> knownEventIds;
  final RumorResult rumor;
  final FactionDiplomacyEntry? primaryDiplomacy;
  final Map<String, Set<String>> knowledgeByFaction;

  const FactionDiplomacyRumorResult._internal({
    required this.atTick,
    required this.observerId,
    required this.activeDiplomacy,
    required this.eventsAtOrBeforeTick,
    required this.knownEventIds,
    required this.rumor,
    required this.primaryDiplomacy,
    required this.knowledgeByFaction,
  });

  bool canObserverSeeSecret(String observer) =>
      primaryDiplomacy?.canObserverSeeSecret(observer) ?? false;

  DiplomacyStance? visibleStance(String observer) =>
      primaryDiplomacy?.perceivedStance(
        forObserver: observer,
        perspective: observer == observerId
            ? DiplomacyPerspective.writer
            : DiplomacyPerspective.reader,
      );

  Set<String> knowledgeFor(String factionId) => knownEventIdsFor(factionId);

  Set<String> knownEventIdsFor(String factionId) => Set.unmodifiable(
    _knowledgeForFaction(
      factionId,
    ).where((eventId) => eventsAtOrBeforeTick.any((e) => e.id == eventId)),
  );

  Set<String> _knowledgeForFaction(String factionId) =>
      knowledgeByFaction[factionId] ?? const <String>{};
}

class FactionDiplomacyRumorIntegration {
  const FactionDiplomacyRumorIntegration();

  FactionDiplomacyRumorResult evaluate(
    FactionDiplomacyRumorScenario scenario, {
    required int atTick,
    required String observerId,
  }) {
    if (atTick < 0) {
      throw ArgumentError.value(atTick, 'atTick', 'must be non-negative');
    }
    final active = scenario.diplomacy
        .where((entry) => entry.isActiveAt(atTick))
        .toList(growable: false);
    final events = scenario.events
        .where((event) => event.tick <= atTick)
        .toList(growable: false);
    final known = scenario.knowledgeByFaction[observerId] ?? const <String>{};
    final primary = active.isEmpty ? null : active.first;
    final rumor = const RumorPropagationSimulator().simulate(
      seed: scenario.rumorSeed,
      network: scenario.rumorNetwork,
      traits: const RumorTraits(),
      upToTick: atTick,
    );
    return FactionDiplomacyRumorResult._internal(
      atTick: atTick,
      observerId: observerId,
      activeDiplomacy: active,
      eventsAtOrBeforeTick: events,
      knownEventIds: Set.unmodifiable(known),
      rumor: rumor,
      primaryDiplomacy: primary,
      knowledgeByFaction: scenario.knowledgeByFaction,
    );
  }
}
