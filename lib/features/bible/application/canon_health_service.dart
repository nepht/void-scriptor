import '../domain/canon_conflict.dart';

class CanonHealthSummary {
  const CanonHealthSummary({
    required this.healthPercent,
    required this.info,
    required this.critical,
    required this.errors,
    required this.warnings,
    required this.unresolvedWeight,
  });

  final int healthPercent;
  final int info;
  final int critical;
  final int errors;
  final int warnings;
  final int unresolvedWeight;
}

class CanonHealthService {
  CanonHealthSummary summarize(Iterable<CanonConflict> conflicts) {
    var info = 0;
    var critical = 0;
    var errors = 0;
    var warnings = 0;
    var weight = 0;
    for (final conflict in conflicts.where((item) => !item.resolved)) {
      switch (conflict.severity) {
        case CanonConflictSeverity.info:
          info++;
          weight += 1;
        case CanonConflictSeverity.warning:
          warnings++;
          weight += 2;
        case CanonConflictSeverity.error:
          errors++;
          weight += 3;
        case CanonConflictSeverity.critical:
          critical++;
          weight += 5;
      }
    }
    return CanonHealthSummary(
      healthPercent: (100 - weight).clamp(0, 100),
      info: info,
      critical: critical,
      errors: errors,
      warnings: warnings,
      unresolvedWeight: weight,
    );
  }
}
