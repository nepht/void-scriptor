/// Domain validator for Sprint 110 step 110.41: Era Alignment & Technology
/// Validation.
///
/// Detects technologies that appear in scenes without their prerequisites
/// discovered, before their canonical discovery tick, or at a production
/// scale that exceeds the node documented capacity. Manual exceptions
/// suppress specific warnings and retain source evidence.
///
/// Domain-only, deterministic, no persistence, UI, wall clock, locale,
/// randomness, or network.
library;

import "technology_node_prerequisite_model.dart";

enum EraTechnologyWarningKind {
  missingPrerequisite,
  earlyUse,
  productionScale,
  unknownTechnology,
}

class SceneTechnologyReference {
  final String sceneId;
  final int tick;
  final String technologyId;
  final int productionScale;

  const SceneTechnologyReference._({
    required this.sceneId,
    required this.tick,
    required this.technologyId,
    required this.productionScale,
  });

  factory SceneTechnologyReference.validated({
    required String sceneId,
    required int tick,
    required String technologyId,
    required int productionScale,
  }) {
    if (sceneId.isEmpty) {
      throw ArgumentError.value(sceneId, "sceneId", "must not be empty");
    }
    if (tick < 0) {
      throw ArgumentError.value(tick, "tick", "must be >= 0");
    }
    if (technologyId.isEmpty) {
      throw ArgumentError.value(
        technologyId,
        "technologyId",
        "must not be empty",
      );
    }
    if (productionScale < 0) {
      throw ArgumentError.value(
        productionScale,
        "productionScale",
        "must be >= 0",
      );
    }
    return SceneTechnologyReference._(
      sceneId: sceneId,
      tick: tick,
      technologyId: technologyId,
      productionScale: productionScale,
    );
  }
}

class ManualTechnologyException {
  final String sceneId;
  final String technologyId;
  final EraTechnologyWarningKind kind;
  final String reason;

  const ManualTechnologyException._({
    required this.sceneId,
    required this.technologyId,
    required this.kind,
    required this.reason,
  });

  factory ManualTechnologyException({
    required String sceneId,
    required String technologyId,
    required EraTechnologyWarningKind kind,
    required String reason,
  }) {
    if (reason.isEmpty) {
      throw ArgumentError.value(reason, 'reason', 'must not be empty');
    }
    return ManualTechnologyException._(
      sceneId: sceneId,
      technologyId: technologyId,
      kind: kind,
      reason: reason,
    );
  }
}

class EraTechnologyFinding {
  final EraTechnologyWarningKind kind;
  final String sceneId;
  final String technologyId;
  final String? prerequisiteId;
  final int? discoveryTick;
  final int? productionScale;
  final int? productionCapacity;
  final TechnologySource source;

  const EraTechnologyFinding({
    required this.kind,
    required this.sceneId,
    required this.technologyId,
    required this.source,
    this.prerequisiteId,
    this.discoveryTick,
    this.productionScale,
    this.productionCapacity,
  });
}

class SuppressedEraTechnologyFinding {
  final EraTechnologyFinding finding;
  final String reason;

  const SuppressedEraTechnologyFinding({
    required this.finding,
    required this.reason,
  });
}

class EraTechnologyReport {
  final List<EraTechnologyFinding> findings;
  final List<SuppressedEraTechnologyFinding> suppressed;

  const EraTechnologyReport._({
    required this.findings,
    required this.suppressed,
  });

  bool get isClean => findings.isEmpty;

  String explain() {
    if (findings.isEmpty && suppressed.isEmpty) {
      return "EraTechnologyReport: clean";
    }
    final buf = StringBuffer("EraTechnologyReport:");
    for (final f in findings) {
      buf.write("\n  finding scene=");
      buf.write(f.sceneId);
      buf.write(" tech=");
      buf.write(f.technologyId);
      buf.write(" kind=");
      buf.write(f.kind.name);
      buf.write(" source=");
      buf.write(f.source.revision);
    }
    for (final s in suppressed) {
      buf.write("\n  suppressed scene=");
      buf.write(s.finding.sceneId);
      buf.write(" tech=");
      buf.write(s.finding.technologyId);
      buf.write(" kind=");
      buf.write(s.finding.kind.name);
      buf.write(" reason=");
      buf.write(s.reason);
    }
    return buf.toString();
  }
}

int _productionCapacityOf(TechnologyNode node) {
  var total = 0;
  for (final infra in node.infrastructure) {
    total += infra.capacity;
  }
  return total;
}

TechnologySource _registrySource(TechnologyRegistry registry) {
  // Registry source not exposed; synthesize from a placeholder revision.
  // Authoring-level provenance belongs to node.source; registry-level
  // provenance is intentionally omitted from the 110.39 contract.
  return TechnologySource.validated(
    revision: 'registry',
    reason: 'unknown technology reference',
  );
}

String _key({
  required String sceneId,
  required String technologyId,
  required EraTechnologyWarningKind kind,
}) {
  return "$sceneId|$technologyId|${kind.name}";
}

class EraTechnologyValidator {
  final TechnologyRegistry registry;
  final TechnologyDiscoveryTimeline timeline;
  final List<ManualTechnologyException> exceptions;

  EraTechnologyValidator({
    required this.registry,
    required this.timeline,
    this.exceptions = const [],
  });

  EraTechnologyReport validate({
    required List<SceneTechnologyReference> references,
  }) {
    final findings = <EraTechnologyFinding>[];
    final suppressed = <SuppressedEraTechnologyFinding>[];
    final exceptionMap = <String, ManualTechnologyException>{};
    for (final e in exceptions) {
      exceptionMap[_key(
            sceneId: e.sceneId,
            technologyId: e.technologyId,
            kind: e.kind,
          )] =
          e;
    }
    for (final ref in references) {
      final node = registry.nodeById(ref.technologyId);
      if (node == null) {
        final finding = EraTechnologyFinding(
          kind: EraTechnologyWarningKind.unknownTechnology,
          sceneId: ref.sceneId,
          technologyId: ref.technologyId,
          source: _registrySource(registry),
        );
        _emit(
          finding: finding,
          exceptionMap: exceptionMap,
          findings: findings,
          suppressed: suppressed,
        );
        continue;
      }
      int? discoveryTick;
      for (final ev in timeline.events) {
        if (ev.technologyId != ref.technologyId) continue;
        if (discoveryTick == null || ev.tick > discoveryTick) {
          discoveryTick = ev.tick;
        }
      }
      if (discoveryTick == null || discoveryTick > ref.tick) {
        final finding = EraTechnologyFinding(
          kind: EraTechnologyWarningKind.earlyUse,
          sceneId: ref.sceneId,
          technologyId: ref.technologyId,
          source: node.source,
          discoveryTick: discoveryTick,
        );
        _emit(
          finding: finding,
          exceptionMap: exceptionMap,
          findings: findings,
          suppressed: suppressed,
        );
      }
      for (final prereqId in node.prerequisites) {
        final prereqNode = registry.nodeById(prereqId);
        if (prereqNode == null) {
          final finding = EraTechnologyFinding(
            kind: EraTechnologyWarningKind.missingPrerequisite,
            sceneId: ref.sceneId,
            technologyId: ref.technologyId,
            prerequisiteId: prereqId,
            source: node.source,
          );
          _emit(
            finding: finding,
            exceptionMap: exceptionMap,
            findings: findings,
            suppressed: suppressed,
          );
          continue;
        }
        bool prereqDiscovered = false;
        for (final ev in timeline.events) {
          if (ev.technologyId != prereqId) continue;
          if (ev.tick <= ref.tick) {
            prereqDiscovered = true;
            break;
          }
        }
        if (!prereqDiscovered) {
          final finding = EraTechnologyFinding(
            kind: EraTechnologyWarningKind.missingPrerequisite,
            sceneId: ref.sceneId,
            technologyId: ref.technologyId,
            prerequisiteId: prereqId,
            source: node.source,
          );
          _emit(
            finding: finding,
            exceptionMap: exceptionMap,
            findings: findings,
            suppressed: suppressed,
          );
        }
      }
      if (_productionCapacityOf(node) > 0 &&
          ref.productionScale > _productionCapacityOf(node)) {
        final finding = EraTechnologyFinding(
          kind: EraTechnologyWarningKind.productionScale,
          sceneId: ref.sceneId,
          technologyId: ref.technologyId,
          productionScale: ref.productionScale,
          productionCapacity: _productionCapacityOf(node),
          source: node.source,
        );
        _emit(
          finding: finding,
          exceptionMap: exceptionMap,
          findings: findings,
          suppressed: suppressed,
        );
      }
    }
    findings.sort((a, b) {
      // EraTechnologyFinding does not carry tick directly; sort by sceneId then technologyId.
      final s = a.sceneId.compareTo(b.sceneId);
      if (s != 0) return s;
      final t = a.technologyId.compareTo(b.technologyId);
      if (t != 0) return t;
      return a.kind.index.compareTo(b.kind.index);
    });
    return EraTechnologyReport._(
      findings: List.unmodifiable(findings),
      suppressed: List.unmodifiable(suppressed),
    );
  }

  void _emit({
    required EraTechnologyFinding finding,
    required Map<String, ManualTechnologyException> exceptionMap,
    required List<EraTechnologyFinding> findings,
    required List<SuppressedEraTechnologyFinding> suppressed,
  }) {
    final key = _key(
      sceneId: finding.sceneId,
      technologyId: finding.technologyId,
      kind: finding.kind,
    );
    final exc = exceptionMap[key];
    if (exc != null) {
      suppressed.add(
        SuppressedEraTechnologyFinding(finding: finding, reason: exc.reason),
      );
    } else {
      findings.add(finding);
    }
  }
}
