// Sprint 111.22 - Activation, Cost, Curse & Limitation Rules.

//
// Domain-only contract for how an artifact behaves once it exists: activation
// requirements, granted abilities, costs paid per use, curses carried,
// cooldown windows, use limitations, and links to power systems, plus a
// deterministic catalog query.
//
// No persistence, UI, locale, network, wall clock, or random input.

library;

/// What an activation requirement demands, free-form but non-empty.
class ActivationRequirement {
  const ActivationRequirement._({
    required this.requirementId,
    required this.description,
    this.condition,
    this.note,
  });

  factory ActivationRequirement.validated({
    required String requirementId,
    required String description,
    String? condition,
    String? note,
  }) {
    final id = requirementId.trim();
    if (id.isEmpty) {
      throw ArgumentError('requirementId must not be empty');
    }
    final desc = description.trim();
    if (desc.isEmpty) {
      throw ArgumentError('description must not be empty');
    }
    final cond = _optional(condition, 'condition');
    final n = _optional(note, 'note');
    return ActivationRequirement._(
      requirementId: id,
      description: desc,
      condition: cond,
      note: n,
    );
  }

  final String requirementId;
  final String description;
  final String? condition;
  final String? note;

  /// True only when the requirement carries an explicit condition.
  bool get isConditional => condition != null;
}

/// A power the artifact grants when its rules are satisfied.
class AbilityRule {
  const AbilityRule._({
    required this.abilityId,
    required this.name,
    this.description,
  });

  factory AbilityRule.validated({
    required String abilityId,
    required String name,
    String? description,
  }) {
    final id = abilityId.trim();
    if (id.isEmpty) {
      throw ArgumentError('abilityId must not be empty');
    }
    final n = name.trim();
    if (n.isEmpty) {
      throw ArgumentError('name must not be empty');
    }
    final desc = _optional(description, 'description');
    return AbilityRule._(abilityId: id, name: n, description: desc);
  }

  final String abilityId;
  final String name;
  final String? description;
}

/// Canonical resource families a cost can drain. Custom resources are
/// allowed via [CostEntry.resourceName] when the enum is absent.
enum CostResource {
  life('Life force'),
  stamina('Stamina'),
  mana('Mana'),
  memory('Memory'),
  luck('Luck'),
  bond('Bond'),
  senses('Senses'),
  years('Years of life'),
  other('Other');

  const CostResource(this.label);
  final String label;
}

/// A price paid each time an ability is used. Amounts are always positive.
class CostEntry {
  const CostEntry._({
    required this.costId,
    required this.amount,
    this.resource,
    this.resourceName,
    this.note,
  });

  factory CostEntry.validated({
    required String costId,
    required int amount,
    CostResource? resource,
    String? resourceName,
    String? note,
  }) {
    final id = costId.trim();
    if (id.isEmpty) {
      throw ArgumentError('costId must not be empty');
    }
    if (amount <= 0) {
      throw ArgumentError('amount must be positive');
    }
    String? custom;
    if (resource == null) {
      final rn = resourceName == null ? '' : resourceName.trim();
      if (rn.isEmpty) {
        throw ArgumentError('resource or resourceName must be provided');
      }
      custom = rn;
    } else if (resourceName != null && resourceName.trim().isNotEmpty) {
      custom = resourceName.trim();
    }
    final n = _optional(note, 'note');
    return CostEntry._(
      costId: id,
      amount: amount,
      resource: resource,
      resourceName: custom,
      note: n,
    );
  }

  final String costId;
  final CostResource? resource;
  final String? resourceName;
  final int amount;
  final String? note;

  /// Human-readable resource label; enum label wins when both exist.
  String get resourceLabel => resource?.label ?? resourceName!;
}

/// How heavy a curse is. Higher [weight] means worse.
enum CurseSeverity {
  nuisance('Nuisance', 1),
  burden('Burden', 2),
  toll('Toll', 3),
  blight('Blight', 4),
  doom('Doom', 5);

  const CurseSeverity(this.label, this.weight);
  final String label;
  final int weight;
}

/// A lasting harm the artifact inflicts on bearer or world.
class CurseRule {
  const CurseRule._({
    required this.curseId,
    required this.description,
    this.severity,
    this.bearerHint,
  });

  factory CurseRule.validated({
    required String curseId,
    required String description,
    int? severity,
    String? bearerHint,
  }) {
    final id = curseId.trim();
    if (id.isEmpty) {
      throw ArgumentError('curseId must not be empty');
    }
    final desc = description.trim();
    if (desc.isEmpty) {
      throw ArgumentError('description must not be empty');
    }
    if (severity != null && (severity < 1 || severity > 5)) {
      throw ArgumentError('severity must be within 1..5');
    }
    final hint = _optional(bearerHint, 'bearerHint');
    return CurseRule._(
      curseId: id,
      description: desc,
      severity: severity,
      bearerHint: hint,
    );
  }

  final String curseId;
  final String description;
  final int? severity;
  final String? bearerHint;
}

/// Re-use delay measured in canonical world ticks (same clock as Sprint 110
/// world time). The window is half-open: ready again at start + duration.
class CooldownRule {
  const CooldownRule._({
    required this.cooldownId,
    required this.durationTicks,
    this.label,
    this.note,
  });

  factory CooldownRule.validated({
    required String cooldownId,
    required int durationTicks,
    String? label,
    String? note,
  }) {
    final id = cooldownId.trim();
    if (id.isEmpty) {
      throw ArgumentError('cooldownId must not be empty');
    }
    if (durationTicks < 0) {
      throw ArgumentError('durationTicks must not be negative');
    }
    final l = _optional(label, 'label');
    final n = _optional(note, 'note');
    return CooldownRule._(
      cooldownId: id,
      durationTicks: durationTicks,
      label: l,
      note: n,
    );
  }

  final String cooldownId;
  final int durationTicks;
  final String? label;
  final String? note;

  /// Zero-duration cooldowns never block re-use.
  bool get isImmediate => durationTicks == 0;

  /// Half-open readiness window: ready once currentTick reaches
  /// lastUseTick + durationTicks.
  bool isReadyAt({required int lastUseTick, required int currentTick}) {
    if (currentTick < lastUseTick) {
      throw ArgumentError('currentTick must not precede lastUseTick');
    }
    return currentTick - lastUseTick >= durationTicks;
  }
}

/// A hard or contextual bound on how the artifact may be used.
class LimitationRule {
  const LimitationRule._({
    required this.limitationId,
    required this.description,
    this.context,
    this.maxUses,
  });

  factory LimitationRule.validated({
    required String limitationId,
    required String description,
    String? context,
    int? maxUses,
  }) {
    final id = limitationId.trim();
    if (id.isEmpty) {
      throw ArgumentError('limitationId must not be empty');
    }
    final desc = description.trim();
    if (desc.isEmpty) {
      throw ArgumentError('description must not be empty');
    }
    if (maxUses != null && maxUses <= 0) {
      throw ArgumentError('maxUses must be positive when provided');
    }
    final ctx = _optional(context, 'context');
    return LimitationRule._(
      limitationId: id,
      description: desc,
      context: ctx,
      maxUses: maxUses,
    );
  }

  final String limitationId;
  final String description;
  final String? context;
  final int? maxUses;

  /// True when no usage cap is declared.
  bool get allowsAnyUseCount => maxUses == null;

  bool get hasUseCap => maxUses != null;

  /// Remaining allowed uses, floored at zero; null when no cap is declared.
  int? remainingUses({required int usedCount}) {
    final cap = maxUses;
    if (cap == null) {
      return null;
    }
    final left = cap - usedCount;
    return left < 0 ? 0 : left;
  }

  bool isExhausted({required int usedCount}) {
    final cap = maxUses;
    if (cap == null) {
      return false;
    }
    return usedCount >= cap;
  }
}

/// Binding between an artifact and a power system from Sprint 111.6/111.7.
class PowerSystemLink {
  const PowerSystemLink._({
    required this.systemId,
    this.systemName,
    this.role,
    this.note,
  });

  factory PowerSystemLink.validated({
    required String systemId,
    String? systemName,
    String? role,
    String? note,
  }) {
    final id = systemId.trim();
    if (id.isEmpty) {
      throw ArgumentError('systemId must not be empty');
    }
    return PowerSystemLink._(
      systemId: id,
      systemName: _optional(systemName, 'systemName'),
      role: _optional(role, 'role'),
      note: _optional(note, 'note'),
    );
  }

  final String systemId;
  final String? systemName;
  final String? role;
  final String? note;
}

/// The complete rule set for one artifact. Recovers nothing and persists
/// nothing; catalogs (111.20) and validators (111.23) consume this.
class ArtifactRules {
  const ArtifactRules._({
    required this.artifactId,
    required this.requirements,
    required this.abilities,
    required this.costs,
    required this.curses,
    required this.cooldowns,
    required this.limitations,
    required this.powerSystemLinks,
  });

  factory ArtifactRules.validated({
    required String artifactId,
    List<ActivationRequirement> requirements = const [],
    List<AbilityRule> abilities = const [],
    List<CostEntry> costs = const [],
    List<CurseRule> curses = const [],
    List<CooldownRule> cooldowns = const [],
    List<LimitationRule> limitations = const [],
    List<PowerSystemLink> powerSystemLinks = const [],
  }) {
    final id = artifactId.trim();
    if (id.isEmpty) {
      throw ArgumentError('artifactId must not be empty');
    }
    _guardUnique(requirements.map((e) => e.requirementId), 'requirementId');
    _guardUnique(abilities.map((e) => e.abilityId), 'abilityId');
    _guardUnique(costs.map((e) => e.costId), 'costId');
    _guardUnique(curses.map((e) => e.curseId), 'curseId');
    _guardUnique(cooldowns.map((e) => e.cooldownId), 'cooldownId');
    _guardUnique(limitations.map((e) => e.limitationId), 'limitationId');
    _guardUnique(powerSystemLinks.map((e) => e.systemId), 'systemId');
    return ArtifactRules._(
      artifactId: id,
      requirements: List.unmodifiable(requirements),
      abilities: List.unmodifiable(abilities),
      costs: List.unmodifiable(costs),
      curses: List.unmodifiable(curses),
      cooldowns: List.unmodifiable(cooldowns),
      limitations: List.unmodifiable(limitations),
      powerSystemLinks: List.unmodifiable(powerSystemLinks),
    );
  }

  final String artifactId;
  final List<ActivationRequirement> requirements;
  final List<AbilityRule> abilities;
  final List<CostEntry> costs;
  final List<CurseRule> curses;
  final List<CooldownRule> cooldowns;
  final List<LimitationRule> limitations;
  final List<PowerSystemLink> powerSystemLinks;

  int get requirementCount => requirements.length;
  int get abilityCount => abilities.length;
  int get costCount => costs.length;
  int get curseCount => curses.length;
  int get cooldownCount => cooldowns.length;
  int get limitationCount => limitations.length;
  int get linkCount => powerSystemLinks.length;

  /// True when no rule family carries any record at all.
  bool get isActiveRulesEmpty =>
      requirementCount == 0 &&
      abilityCount == 0 &&
      costCount == 0 &&
      curseCount == 0 &&
      cooldownCount == 0 &&
      limitationCount == 0 &&
      linkCount == 0;

  bool get requiresActivation => requirements.isNotEmpty;

  bool hasAbility(String abilityId) =>
      abilities.any((a) => a.abilityId == abilityId);

  String? abilityNameFor(String abilityId) {
    for (final a in abilities) {
      if (a.abilityId == abilityId) {
        return a.name;
      }
    }
    return null;
  }

  /// Sum of costs for one resource family. Provide either [resource] or a
  /// [resourceName] (case-insensitive) for custom resources, not both.
  int totalCostFor({CostResource? resource, String? resourceName}) {
    if (resource == null && (resourceName == null || resourceName.isEmpty)) {
      throw ArgumentError('resource or resourceName must be provided');
    }
    if (resource != null) {
      return costs
          .where((c) => c.resource == resource)
          .fold<int>(0, (sum, c) => sum + c.amount);
    }
    final needle = resourceName!.trim().toLowerCase();
    return costs
        .where(
          (c) =>
              c.resource == null &&
              c.resourceName != null &&
              c.resourceName!.toLowerCase() == needle,
        )
        .fold<int>(0, (sum, c) => sum + c.amount);
  }

  /// Highest declared curse severity in the ladder, 0 when none is declared.
  int get maxCurseSeverity {
    var max = 0;
    for (final c in curses) {
      final s = c.severity ?? 0;
      if (s > max) {
        max = s;
      }
    }
    return max;
  }

  bool isCursedAtLeast(int severity) {
    if (severity < 1 || severity > 5) {
      throw ArgumentError('severity must be within 1..5');
    }
    return maxCurseSeverity >= severity;
  }

  bool linksToSystem(String systemId) =>
      powerSystemLinks.any((l) => l.systemId == systemId);

  /// Sorted, de-duplicated view of linked system ids.
  List<String> get systemIds {
    final set = powerSystemLinks.map((l) => l.systemId).toSet().toList()
      ..sort();
    return List.unmodifiable(set);
  }

  /// Every declared cooldown must be ready at [currentTick]. A cooldown with
  /// no recorded last-use tick counts as ready.
  bool cooldownsReadyAt({
    required Map<String, int> lastUseTickByCooldown,
    required int currentTick,
  }) {
    for (final d in cooldowns) {
      final last = lastUseTickByCooldown[d.cooldownId];
      if (last == null) {
        continue;
      }
      if (!d.isReadyAt(lastUseTick: last, currentTick: currentTick)) {
        return false;
      }
    }
    return true;
  }
}

/// Deterministic cross-artifact catalog of rule sets.
class ArtifactRulesCatalog {
  const ArtifactRulesCatalog._(this._records);

  factory ArtifactRulesCatalog.empty() => const ArtifactRulesCatalog._([]);

  factory ArtifactRulesCatalog.withRecords(List<ArtifactRules> records) {
    final seen = <String>{};
    for (final r in records) {
      if (!seen.add(r.artifactId)) {
        throw ArgumentError('duplicate artifactId: ${r.artifactId}');
      }
    }
    final sorted = [...records]
      ..sort((a, b) => a.artifactId.compareTo(b.artifactId));
    return ArtifactRulesCatalog._(List.unmodifiable(sorted));
  }

  final List<ArtifactRules> _records;

  List<ArtifactRules> get records => _records;
  int get count => _records.length;

  List<String> get artifactIds =>
      _records.map((r) => r.artifactId).toList(growable: false);

  ArtifactRules? rulesFor(String artifactId) {
    for (final r in _records) {
      if (r.artifactId == artifactId) {
        return r;
      }
    }
    return null;
  }

  /// Artifact ids (sorted) whose rules link the given power system.
  List<String> artifactsUsingPowerSystem(String systemId) {
    final hits =
        _records
            .where((r) => r.linksToSystem(systemId))
            .map((r) => r.artifactId)
            .toList()
          ..sort();
    return List.unmodifiable(hits);
  }

  /// Id of the artifact carrying the single worst declared curse severity,
  /// or null when no curse has a declared severity. Ties break on artifact id.
  String? get mostCursedArtifactId {
    String? best;
    var bestSeverity = 0;
    for (final r in _records) {
      final s = r.maxCurseSeverity;
      if (s > bestSeverity) {
        bestSeverity = s;
        best = r.artifactId;
      }
    }
    return best;
  }

  /// Sum of one resource family's cost across the whole catalog.
  int totalCostAcross({required CostResource resource}) {
    var total = 0;
    for (final r in _records) {
      total += r.totalCostFor(resource: resource);
    }
    return total;
  }
}

String? _optional(String? value, String field) {
  if (value == null) {
    return null;
  }
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError('$field must not be blank when provided');
  }
  return trimmed;
}

void _guardUnique(Iterable<String> ids, String field) {
  final seen = <String>{};
  for (final id in ids) {
    if (!seen.add(id)) {
      throw ArgumentError('duplicate $field: $id');
    }
  }
}
