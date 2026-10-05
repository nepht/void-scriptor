library;

import 'power_rulebook.dart';
import 'power_usage_ledger.dart';

/// Deterministic, domain-only escalation and deus-ex-machina signals.
///
/// Scans a [PowerUsageLedger] for narrative signals that the writer's draft
/// may need to justify: brand-new ability used without setup, magnitude jump
/// beyond a configurable threshold, and unearned exceptions. Every signal can
/// be dismissed with a non-empty reason. The detector contains no persistence,
/// clock, randomness, or UI.

enum PowerEscalationKind { newPower, unearnedException, scaleJump }

class PowerEscalationDismissal {
  const PowerEscalationDismissal({required this.kind, required this.reason});
  final PowerEscalationKind kind;
  final String reason;
}

class PowerEscalationSignal {
  const PowerEscalationSignal({
    required this.kind,
    required this.abilityId,
    required this.explanation,
  });
  final PowerEscalationKind kind;
  final String abilityId;
  final String explanation;
}

class PowerEscalationReport {
  const PowerEscalationReport._(this.signals, this.dismissals);
  final List<PowerEscalationSignal> signals;
  final List<PowerEscalationDismissal> dismissals;

  bool get isClean => signals.isEmpty;

  String explain() {
    if (signals.isEmpty) return 'No escalation signals detected.';
    final buffer = StringBuffer('Escalation signals:');
    for (final s in signals) {
      buffer.write(' ability=');
      buffer.write(s.abilityId);
      buffer.write(' kind=');
      buffer.write(s.kind.name);
      buffer.write(' reason="');
      buffer.write(s.explanation);
      buffer.write('"');
    }
    return buffer.toString();
  }
}

class PowerEscalationSignals {
  const PowerEscalationSignals({
    required this.rulebook,
    this.scaleJumpThreshold = 4,
    this.unearnedExceptionTickFloor = 50,
  }) : assert(scaleJumpThreshold > 0);

  final PowerRulebook rulebook;
  final int scaleJumpThreshold;
  final int unearnedExceptionTickFloor;

  PowerEscalationReport evaluate({
    required PowerUsageLedger ledger,
    required Map<String, PowerEscalationDismissal> dismissal,
    Map<String, List<String>> contextPrerequisitesForAbility =
        const <String, List<String>>{},
  }) {
    final signals = <PowerEscalationSignal>[];
    final dismissedReasons = <PowerEscalationDismissal>[];
    final seenAbilities = <String>{};
    final magnitudeByAbility = <String, num>{};

    for (final event in ledger.events) {
      // new_power_signal
      if (seenAbilities.add(event.abilityId)) {
        final dismiss = dismissal[event.abilityId];
        if (dismiss != null && dismiss.kind == PowerEscalationKind.newPower) {
          dismissedReasons.add(dismiss);
        } else {
          signals.add(
            PowerEscalationSignal(
              kind: PowerEscalationKind.newPower,
              abilityId: event.abilityId,
              explanation:
                  'ability "${event.abilityId}" first used at tick ${event.tick}',
            ),
          );
        }
      }
      // scale_jump_signal
      final magnitude = event.resourceChanges.fold<num>(
        0,
        (sum, c) => sum + c.amount.abs(),
      );
      final prior = magnitudeByAbility[event.abilityId] ?? 0;
      if (prior > 0 && magnitude - prior >= scaleJumpThreshold) {
        final dismiss = dismissal[event.abilityId];
        if (dismiss != null && dismiss.kind == PowerEscalationKind.scaleJump) {
          dismissedReasons.add(dismiss);
        } else {
          signals.add(
            PowerEscalationSignal(
              kind: PowerEscalationKind.scaleJump,
              abilityId: event.abilityId,
              explanation:
                  'magnitude jumped from $prior to $magnitude at tick ${event.tick}',
            ),
          );
        }
      }
      magnitudeByAbility[event.abilityId] = magnitude;
      // unearned_exception_signal
      final unearnedPrereqs =
          contextPrerequisitesForAbility[event.abilityId] ?? const [];
      if (unearnedPrereqs.isNotEmpty &&
          event.tick >= unearnedExceptionTickFloor) {
        final dismiss = dismissal[event.abilityId];
        if (dismiss != null &&
            dismiss.kind == PowerEscalationKind.unearnedException) {
          dismissedReasons.add(dismiss);
        } else {
          signals.add(
            PowerEscalationSignal(
              kind: PowerEscalationKind.unearnedException,
              abilityId: event.abilityId,
              explanation:
                  'ability "${event.abilityId}" used at tick ${event.tick} with no recorded prerequisite',
            ),
          );
        }
      }
    }

    final sorted = [...signals]
      ..sort((a, b) {
        final byAbility = a.abilityId.compareTo(b.abilityId);
        if (byAbility != 0) return byAbility;
        return a.kind.index.compareTo(b.kind.index);
      });
    return PowerEscalationReport._(
      List.unmodifiable(sorted),
      List.unmodifiable(dismissedReasons),
    );
  }
}
