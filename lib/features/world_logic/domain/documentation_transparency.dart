/// Domain library for Sprint 110.48 Documentation & Model Transparency.
///
/// Models Wave-2 modules documentation as immutable, validated records that
/// describe their inputs, assumptions, units, uncertainty, override path,
/// recovery path, and known limits. Used to render the six canonical
/// documentation artefacts (feature_guides, model_cards, assumption_guides,
/// override_guide, recovery_guide, known_limits).
///
/// Domain-only, deterministic, no persistence, no UI, no wall clock,
/// no random, no network.
library;

enum TransparencyEntryKind {
  featureGuide,
  modelCard,
  assumptionGuide,
  overrideGuide,
  recoveryGuide,
  knownLimit;

  String get label {
    switch (this) {
      case TransparencyEntryKind.featureGuide:
        return "feature_guide";
      case TransparencyEntryKind.modelCard:
        return "model_card";
      case TransparencyEntryKind.assumptionGuide:
        return "assumption_guide";
      case TransparencyEntryKind.overrideGuide:
        return "override_guide";
      case TransparencyEntryKind.recoveryGuide:
        return "recovery_guide";
      case TransparencyEntryKind.knownLimit:
        return "known_limit";
    }
  }

  static const List<TransparencyEntryKind> canonicalKinds =
      <TransparencyEntryKind>[
        TransparencyEntryKind.featureGuide,
        TransparencyEntryKind.modelCard,
        TransparencyEntryKind.assumptionGuide,
        TransparencyEntryKind.overrideGuide,
        TransparencyEntryKind.recoveryGuide,
        TransparencyEntryKind.knownLimit,
      ];
}

class TransparencyEntry {
  final String id;
  final TransparencyEntryKind kind;
  final String title;
  final String subjectId;
  final String summary;
  final List<String> inputs;
  final List<String> assumptions;
  final Map<String, String> units;
  final double uncertainty;
  final String overridePath;
  final String recoveryPath;
  final List<String> limits;
  final List<String> sources;

  TransparencyEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.subjectId,
    required this.summary,
    List<String>? inputs,
    List<String>? assumptions,
    Map<String, String>? units,
    this.uncertainty = 0.0,
    this.overridePath = "",
    this.recoveryPath = "",
    List<String>? limits,
    List<String>? sources,
  }) : inputs = List<String>.unmodifiable(inputs ?? const <String>[]),
       assumptions = List<String>.unmodifiable(assumptions ?? const <String>[]),
       units = Map<String, String>.unmodifiable(
         units ?? const <String, String>{},
       ),
       limits = List<String>.unmodifiable(limits ?? const <String>[]),
       sources = List<String>.unmodifiable(sources ?? const <String>[]) {
    if (id.isEmpty) throw ArgumentError.value(id, "id", "id must be non-empty");
    if (title.isEmpty) {
      throw ArgumentError.value(title, "title", "title must be non-empty");
    }
    if (subjectId.isEmpty) {
      throw ArgumentError.value(
        subjectId,
        "subjectId",
        "subjectId must be non-empty",
      );
    }
    if (summary.isEmpty) {
      throw ArgumentError.value(
        summary,
        "summary",
        "summary must be non-empty",
      );
    }
    if (uncertainty < 0.0 || uncertainty > 1.0) {
      throw ArgumentError.value(
        uncertainty,
        "uncertainty",
        "uncertainty must be in [0,1], got $uncertainty",
      );
    }
  }
}

class TransparencyCatalog {
  final List<TransparencyEntry> _entries;
  final Map<TransparencyEntryKind, List<TransparencyEntry>> _byKind;
  final Map<String, List<TransparencyEntry>> _bySubject;

  TransparencyCatalog._(this._entries)
    : _byKind = _groupByKind(_entries),
      _bySubject = _groupBySubject(_entries);

  factory TransparencyCatalog.fromList(List<TransparencyEntry> entries) {
    final sorted = List<TransparencyEntry>.from(entries)
      ..sort((a, b) {
        final kindCmp = a.kind.index.compareTo(b.kind.index);
        if (kindCmp != 0) return kindCmp;
        return a.id.compareTo(b.id);
      });
    return TransparencyCatalog._(sorted);
  }

  static Map<TransparencyEntryKind, List<TransparencyEntry>> _groupByKind(
    List<TransparencyEntry> entries,
  ) {
    final map = <TransparencyEntryKind, List<TransparencyEntry>>{};
    for (final e in entries) {
      map.putIfAbsent(e.kind, () => <TransparencyEntry>[]).add(e);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.id.compareTo(b.id));
    }
    return Map<TransparencyEntryKind, List<TransparencyEntry>>.unmodifiable(
      map,
    );
  }

  static Map<String, List<TransparencyEntry>> _groupBySubject(
    List<TransparencyEntry> entries,
  ) {
    final map = <String, List<TransparencyEntry>>{};
    for (final e in entries) {
      map.putIfAbsent(e.subjectId, () => <TransparencyEntry>[]).add(e);
    }
    for (final list in map.values) {
      list.sort((a, b) {
        final kindCmp = a.kind.index.compareTo(b.kind.index);
        if (kindCmp != 0) return kindCmp;
        return a.id.compareTo(b.id);
      });
    }
    return Map<String, List<TransparencyEntry>>.unmodifiable(map);
  }

  int get length => _entries.length;
  List<TransparencyEntry> get entries => List.unmodifiable(_entries);
  Map<TransparencyEntryKind, List<TransparencyEntry>> get entriesByKind =>
      _byKind;

  List<TransparencyEntry> byKind(TransparencyEntryKind kind) =>
      List.unmodifiable(_byKind[kind] ?? const <TransparencyEntry>[]);

  List<TransparencyEntry> bySubject(String subjectId) =>
      List.unmodifiable(_bySubject[subjectId] ?? const <TransparencyEntry>[]);

  bool allKindsCovered({
    required String subjectId,
    required List<TransparencyEntryKind> kinds,
  }) {
    final entries = _bySubject[subjectId];
    if (entries == null) return false;
    final present = entries.map((e) => e.kind).toSet();
    return kinds.every(present.contains);
  }
}

class TransparencyCatalogBuilder {
  final List<TransparencyEntry> _entries = <TransparencyEntry>[];

  TransparencyCatalogBuilder add(TransparencyEntry entry) {
    _entries.add(entry);
    return this;
  }

  TransparencyCatalog build() => TransparencyCatalog.fromList(_entries);
}

class TransparencyReport {
  final TransparencyCatalog catalog;

  TransparencyReport.fromCatalog(this.catalog);

  String explain() {
    final buf = StringBuffer();
    buf.writeln("Transparency Catalog Report");
    buf.writeln("entries: ${catalog.length}");
    for (final entry in catalog.entries) {
      buf.writeln(
        "--- ${entry.kind.label} ${entry.id} (${entry.subjectId}) ---",
      );
      buf.writeln("title: ${entry.title}");
      buf.writeln("summary: ${entry.summary}");
      if (entry.inputs.isNotEmpty) {
        buf.writeln("inputs: ${entry.inputs.join(", ")}");
      }
      if (entry.assumptions.isNotEmpty) {
        buf.writeln("assumptions: ${entry.assumptions.join(", ")}");
      }
      if (entry.units.isNotEmpty) {
        final pairs = entry.units.entries
            .map((kv) => "${kv.key}=${kv.value}")
            .join(", ");
        buf.writeln("units: $pairs");
      }
      if (entry.uncertainty > 0) {
        buf.writeln("uncertainty: ${entry.uncertainty}");
      }
      if (entry.overridePath.isNotEmpty) {
        buf.writeln("override_path: ${entry.overridePath}");
      }
      if (entry.recoveryPath.isNotEmpty) {
        buf.writeln("recovery_path: ${entry.recoveryPath}");
      }
      if (entry.limits.isNotEmpty) {
        buf.writeln("limits: ${entry.limits.join(", ")}");
      }
      if (entry.sources.isNotEmpty) {
        buf.writeln("sources: ${entry.sources.join(", ")}");
      }
    }
    return buf.toString();
  }

  List<TransparencyEntryKind> missingKinds({
    required String subjectId,
    required List<TransparencyEntryKind> kinds,
  }) {
    final entries = catalog.bySubject(subjectId);
    final present = entries.map((e) => e.kind).toSet();
    return kinds.where((k) => !present.contains(k)).toList();
  }
}

class Wave2TransparencySnapshot {
  static const List<String> subjectIds = <String>[
    "world_clock",
    "route_network",
    "calendar_system",
    "genealogy_model",
    "power_system",
    "economy_model",
    "communication_channel",
    "rumor_propagation",
    "technology_tree",
    "cross_simulation",
  ];

  static TransparencyCatalog build() {
    final b = TransparencyCatalogBuilder();
    for (final subject in subjectIds) {
      b
        ..add(
          TransparencyEntry(
            id: "feat.$subject",
            kind: TransparencyEntryKind.featureGuide,
            title: _title(subject),
            subjectId: subject,
            summary: _summary(subject),
            inputs: _inputs(subject),
            assumptions: _assumptions(subject),
            sources: const <String>["sprint_110.json:110.3-110.47"],
          ),
        )
        ..add(
          TransparencyEntry(
            id: "m.$subject",
            kind: TransparencyEntryKind.modelCard,
            title: _title(subject),
            subjectId: subject,
            summary: _summary(subject),
            inputs: _inputs(subject),
            assumptions: _assumptions(subject),
            units: _units(subject),
            uncertainty: _uncertainty(subject),
            sources: _sources(subject),
          ),
        )
        ..add(
          TransparencyEntry(
            id: "a.$subject",
            kind: TransparencyEntryKind.assumptionGuide,
            title: "${_title(subject)} assumptions",
            subjectId: subject,
            summary: _assumptions(subject).join("; "),
            assumptions: _assumptions(subject),
            sources: const <String>["sprint_110.json:110.3-110.47"],
          ),
        )
        ..add(
          TransparencyEntry(
            id: "o.$subject",
            kind: TransparencyEntryKind.overrideGuide,
            title: "${_title(subject)} override",
            subjectId: subject,
            summary: "Editor may override with reason; provenance recorded.",
            overridePath: "doc/features/world_logic/override_guide.md#$subject",
            assumptions: const <String>[
              "override must include non-empty reason",
              "override is recorded as provenance",
            ],
            sources: const <String>[
              "sprint_110.json:110.7",
              "sprint_110.json:110.41",
            ],
          ),
        )
        ..add(
          TransparencyEntry(
            id: "r.$subject",
            kind: TransparencyEntryKind.recoveryGuide,
            title: "${_title(subject)} recovery",
            subjectId: subject,
            summary:
                "Restore last persisted state from project db; rebuild derived view.",
            recoveryPath: "doc/features/world_logic/recovery_guide.md#$subject",
            assumptions: const <String>[
              "project.db is the single sync authority",
              "recovery is idempotent",
            ],
            sources: const <String>[
              "sprint_110.json:110.6",
              "sprint_110.json:110.42",
            ],
          ),
        )
        ..add(
          TransparencyEntry(
            id: "l.$subject",
            kind: TransparencyEntryKind.knownLimit,
            title: "${_title(subject)} known limits",
            subjectId: subject,
            summary: _limits(subject).join("; "),
            limits: _limits(subject),
            sources: const <String>[
              "sprint_110.json:110.45",
              "sprint_110.json:110.47",
            ],
          ),
        );
    }
    return b.build();
  }

  static String _title(String subject) {
    switch (subject) {
      case "world_clock":
        return "World Clock";
      case "route_network":
        return "Route Network";
      case "calendar_system":
        return "Calendar System";
      case "genealogy_model":
        return "Genealogy Model";
      case "power_system":
        return "Power System";
      case "economy_model":
        return "Economy Model";
      case "communication_channel":
        return "Communication Channel";
      case "rumor_propagation":
        return "Rumor Propagation";
      case "technology_tree":
        return "Technology Tree";
      case "cross_simulation":
        return "Cross Simulation";
    }
    return subject;
  }

  static String _summary(String subject) {
    switch (subject) {
      case "world_clock":
        return "Deterministic monotonic clock authority for the world.";
      case "route_network":
        return "Graph of routes with terrain and seasonal costs.";
      case "calendar_system":
        return "Custom calendars and celestial cycles.";
      case "genealogy_model":
        return "Family relationships, inheritance, and dynasty tree.";
      case "power_system":
        return "Power usage, rulebook, and escalation signals.";
      case "economy_model":
        return "Currency, prices, wages, and inflation index.";
      case "communication_channel":
        return "Couriers, signals, printing, magic/tech channels.";
      case "rumor_propagation":
        return "Rumor spread with delay, reliability, distortion.";
      case "technology_tree":
        return "Tech nodes with prerequisites, infrastructure, scope.";
      case "cross_simulation":
        return "Shared clock, locations, and ownership across modules.";
    }
    return subject;
  }

  static List<String> _inputs(String subject) {
    return const <String>["absolute_tick", "project_id"];
  }

  static List<String> _assumptions(String subject) {
    switch (subject) {
      case "world_clock":
        return const <String>["tick is non-negative integer", "epoch is fixed"];
      case "route_network":
        return const <String>[
          "edges have non-negative distance",
          "terrain modifiers are deterministic",
        ];
      case "calendar_system":
        return const <String>[
          "month names are unique per calendar",
          "daysPerMonth sum equals daysPerYear",
        ];
      case "genealogy_model":
        return const <String>[
          "parent-child links are acyclic",
          "person ids are unique within a project",
        ];
      case "power_system":
        return const <String>[
          "abilities belong to at most one rulebook",
          "events are append-only",
        ];
      case "economy_model":
        return const <String>[
          "currency ids are unique",
          "reference units are validated",
        ];
      case "communication_channel":
        return const <String>[
          "channels have unique ids",
          "reliability is in [0,10]",
        ];
      case "rumor_propagation":
        return const <String>[
          "propagation is deterministic per seed",
          "distortion capped at 1.0",
        ];
      case "technology_tree":
        return const <String>[
          "prerequisites do not self-reference",
          "tier values start at 1",
        ];
      case "cross_simulation":
        return const <String>[
          "shared clock is single source of truth",
          "no circular ownership edges",
        ];
    }
    return const <String>[];
  }

  static Map<String, String> _units(String subject) {
    switch (subject) {
      case "world_clock":
        return const <String, String>{"tick": "integer", "duration": "ticks"};
      case "route_network":
        return const <String, String>{
          "distance": "distance units",
          "cost": "multiplier",
        };
      case "calendar_system":
        return const <String, String>{
          "daysPerMonth": "integer",
          "daysPerYear": "integer",
        };
      case "genealogy_model":
        return const <String, String>{
          "generation": "integer",
          "validFrom": "tick",
        };
      case "power_system":
        return const <String, String>{
          "cooldownTicks": "integer",
          "magnitude": "real",
        };
      case "economy_model":
        return const <String, String>{
          "price": "currency units",
          "wage": "currency/hour",
        };
      case "communication_channel":
        return const <String, String>{
          "latencyTicks": "integer",
          "reliability": "0..10",
        };
      case "rumor_propagation":
        return const <String, String>{
          "confidence": "0..1",
          "distortion": "0..1",
        };
      case "technology_tree":
        return const <String, String>{"tier": "integer", "capacity": "amount"};
      case "cross_simulation":
        return const <String, String>{"cyclePath": "node ids"};
    }
    return const <String, String>{};
  }

  static double _uncertainty(String subject) {
    switch (subject) {
      case "world_clock":
        return 0.0;
      case "route_network":
        return 0.1;
      case "calendar_system":
        return 0.05;
      case "genealogy_model":
        return 0.15;
      case "power_system":
        return 0.2;
      case "economy_model":
        return 0.25;
      case "communication_channel":
        return 0.2;
      case "rumor_propagation":
        return 0.3;
      case "technology_tree":
        return 0.1;
      case "cross_simulation":
        return 0.1;
    }
    return 0.1;
  }

  static List<String> _limits(String subject) {
    switch (subject) {
      case "world_clock":
        return const <String>["no wall-clock conversion", "no real-time sync"];
      case "route_network":
        return const <String>["route graph is in-memory; not yet persisted"];
      case "calendar_system":
        return const <String>[
          "no locale-aware weekday names",
          "leap rules not modelled",
        ];
      case "genealogy_model":
        return const <String>[
          "cycle detection excludes manual exceptions by default",
        ];
      case "power_system":
        return const <String>[
          "unknown abilities emit unknownAbility but no remediation",
        ];
      case "economy_model":
        return const <String>[
          "equal-weight inflation index; no spend weighting",
        ];
      case "communication_channel":
        return const <String>["no cost model per message"];
      case "rumor_propagation":
        return const <String>["recipients beyond upToTick are dropped"];
      case "technology_tree":
        return const <String>["large trees fall back to compressed layout"];
      case "cross_simulation":
        return const <String>[
          "partial results exposed when dependencies missing",
        ];
    }
    return const <String>[];
  }

  static List<String> _sources(String subject) {
    return const <String>[
      "sprint_110.json:110.3",
      "sprint_110.json:110.7",
      "sprint_110.json:110.45",
    ];
  }
}
