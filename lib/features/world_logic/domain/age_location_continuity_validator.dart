library;

import "character_location_history.dart";

enum ContinuityAlertCode { notBorn, afterDeath, impossibleTravel, overlap }

class ScenePresence {
  const ScenePresence._({
    required this.sceneId,
    required this.personId,
    required this.tick,
    required this.locationId,
    required this.sourceId,
  });
  factory ScenePresence.validated({
    required String sceneId,
    required String personId,
    required int tick,
    required String locationId,
    required String sourceId,
  }) {
    if ([sceneId, personId, locationId, sourceId].any((id) => id.isEmpty)) {
      throw ArgumentError("scene presence ids must be non-empty");
    }
    if (tick < 0) throw ArgumentError.value(tick, "tick", "must be >= 0");
    return ScenePresence._(
      sceneId: sceneId,
      personId: personId,
      tick: tick,
      locationId: locationId,
      sourceId: sourceId,
    );
  }
  final String sceneId, personId, locationId, sourceId;
  final int tick;
}

class ContinuityAlert {
  const ContinuityAlert({
    required this.code,
    required this.explanation,
    required this.relatedSceneIds,
  });
  final ContinuityAlertCode code;
  final String explanation;
  final List<String> relatedSceneIds;
}

class ContinuityValidationResult {
  const ContinuityValidationResult({
    required this.personId,
    required this.alerts,
    required this.explanation,
  });
  final String personId, explanation;
  final List<ContinuityAlert> alerts;
  bool get isConsistent => alerts.isEmpty;
  List<ContinuityAlertCode> get codes =>
      List.unmodifiable(alerts.map((alert) => alert.code));
}

class AgeLocationContinuityValidator {
  const AgeLocationContinuityValidator._();
  static ContinuityValidationResult validate({
    required String personId,
    required int? birthTick,
    int? deathTick,
    required List<ScenePresence> scenes,
    CharacterLocationTimeline? timeline,
  }) {
    if (personId.isEmpty) {
      throw ArgumentError.value(personId, "personId", "must be non-empty");
    }
    if (birthTick != null && birthTick < 0) {
      throw ArgumentError.value(birthTick, "birthTick", "must be >= 0");
    }
    if (deathTick != null && (birthTick == null || deathTick < birthTick)) {
      throw ArgumentError.value(deathTick, "deathTick", "must follow birth");
    }
    if (scenes.any((scene) => scene.personId != personId)) {
      throw ArgumentError("every scene must belong to $personId");
    }
    final ordered = [...scenes]
      ..sort((a, b) {
        final tickOrder = a.tick.compareTo(b.tick);
        return tickOrder != 0 ? tickOrder : a.sceneId.compareTo(b.sceneId);
      });
    final alerts = <ContinuityAlert>[];
    for (final scene in ordered) {
      if (birthTick != null && scene.tick < birthTick) {
        alerts.add(
          ContinuityAlert(
            code: ContinuityAlertCode.notBorn,
            explanation:
                "${scene.sceneId} occurs at tick ${scene.tick} before birth tick $birthTick",
            relatedSceneIds: [scene.sceneId],
          ),
        );
      }
      if (deathTick != null && scene.tick >= deathTick) {
        alerts.add(
          ContinuityAlert(
            code: ContinuityAlertCode.afterDeath,
            explanation:
                "${scene.sceneId} occurs at tick ${scene.tick} at or after death tick $deathTick",
            relatedSceneIds: [scene.sceneId],
          ),
        );
      }
    }
    for (var i = 1; i < ordered.length; i++) {
      final previous = ordered[i - 1], current = ordered[i];
      if (previous.tick == current.tick &&
          previous.locationId != current.locationId) {
        alerts.add(
          ContinuityAlert(
            code: ContinuityAlertCode.overlap,
            explanation:
                "${previous.sceneId} and ${current.sceneId} place $personId in incompatible locations at tick ${current.tick}",
            relatedSceneIds: [previous.sceneId, current.sceneId],
          ),
        );
      } else if (previous.locationId != current.locationId &&
          !(timeline?.hasTravelBetween(
                fromLocationId: previous.locationId,
                toLocationId: current.locationId,
                fromTick: previous.tick,
                toTick: current.tick,
              ) ??
              false)) {
        alerts.add(
          ContinuityAlert(
            code: ContinuityAlertCode.impossibleTravel,
            explanation:
                "No recorded travel explains $personId moving from ${previous.locationId} to ${current.locationId} between ticks ${previous.tick} and ${current.tick}",
            relatedSceneIds: [previous.sceneId, current.sceneId],
          ),
        );
      }
    }
    final count = scenes.length;
    final suffix = count == 1 ? "" : "s";
    final explanation = alerts.isEmpty
        ? "$personId has consistent age and location continuity across $count scene$suffix"
        : "$personId has ${alerts.length} continuity alerts across $count scene$suffix";
    return ContinuityValidationResult(
      personId: personId,
      alerts: List.unmodifiable(alerts),
      explanation: explanation,
    );
  }
}
