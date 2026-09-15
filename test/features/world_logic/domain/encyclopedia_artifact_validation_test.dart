// Sprint 111.23 - Artifact Usage & Authenticity Validation.
//
// RED regression tests for the domain validator that detects: usage by the
// wrong party (owner_check), unauthorized activation (activation_check),
// impossible location (location_check), fake/disputed artifacts
// (authenticity_check), human-readable warnings (explain_warning), and
// explicit manual exceptions (manual_exception).
//
// Mirrors the validator shape proven by Sprint 111.13
// (encyclopedia_alchemy_validation.dart): validated factories, ArgumentError
// on blank ids, deterministic issue ids, report describe(), and
// exception-scoped suppression.
//
// No persistence, UI, locale, network, wall clock, or random input.
import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/features/world_logic/domain/encyclopedia_activation_rules.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_artifact.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_artifact_validation.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_ownership_lineage.dart';

ArtifactRecord _artifact({
  String id = 'art-blade',
  ArtifactAuthenticity? authenticity = ArtifactAuthenticity.authentic,
  ArtifactCondition? condition = ArtifactCondition.good,
}) {
  return ArtifactRecord.validated(
    artifactId: id,
    name: 'Nightglass Blade',
    type: ArtifactType.weapon,
    condition: condition,
    authenticity: authenticity,
  );
}

OwnershipLineageRecord _lineage({
  String artifactId = 'art-blade',
  List<OwnershipPeriod> periods = const [],
  List<CustodyArrangement> custody = const [],
  List<LocationRecord> locations = const [],
}) {
  return OwnershipLineageRecord.validated(
    artifactId: artifactId,
    periods: periods,
    custody: custody,
    locations: locations,
  );
}

OwnershipPeriod _period(String holderId, {String? endMarker}) {
  return OwnershipPeriod.validated(
    periodId: 'p-$holderId',
    holderId: holderId,
    holderName: 'Holder $holderId',
    endMarker: endMarker,
  );
}

ArtifactUsageEvent _usage({
  String artifactId = 'art-blade',
  String actorId = 'h-keryn',
  String? locationId,
  String? abilityId,
  int? atTick,
  int useCount = 1,
}) {
  return ArtifactUsageEvent.validated(
    usageId: 'u-$artifactId-$actorId',
    artifactId: artifactId,
    actorId: actorId,
    locationId: locationId,
    abilityId: abilityId,
    atTick: atTick,
    useCount: useCount,
  );
}

void main() {
  group('ArtifactUsageEvent contract', () {
    test('rejects blank artifactId', () {
      expect(
        () => ArtifactUsageEvent.validated(
          usageId: 'u1',
          artifactId: '  ',
          actorId: 'h-a',
        ),
        throwsArgumentError,
      );
    });

    test('rejects negative useCount', () {
      expect(
        () => ArtifactUsageEvent.validated(
          usageId: 'u1',
          artifactId: 'art-blade',
          actorId: 'h-a',
          useCount: -1,
        ),
        throwsArgumentError,
      );
    });

    test('optional fields reject blank strings but accept null', () {
      expect(
        () => ArtifactUsageEvent.validated(
          usageId: 'u1',
          artifactId: 'art-blade',
          actorId: 'h-a',
          locationId: '   ',
        ),
        throwsArgumentError,
      );
      final ok = ArtifactUsageEvent.validated(
        usageId: 'u1',
        artifactId: 'art-blade',
        actorId: 'h-a',
      );
      expect(ok.locationId, isNull);
      expect(ok.abilityId, isNull);
      expect(ok.atTick, isNull);
    });
  });

  group('ArtifactUsageValidator owner_check', () {
    test('RED: actor who is neither holder nor custodian is flagged', () {
      final report = const ArtifactUsageValidator().validate(
        artifact: _artifact(),
        lineage: _lineage(periods: [_period('h-keryn')]),
        usage: _usage(actorId: 'h-thief'),
      );
      expect(report.kinds, contains(ArtifactValidationKind.ownerMismatch));
    });

    test('holder from an open period passes owner_check', () {
      final report = const ArtifactUsageValidator().validate(
        artifact: _artifact(),
        lineage: _lineage(periods: [_period('h-keryn')]),
        usage: _usage(actorId: 'h-keryn'),
      );
      expect(
        report.kinds,
        isNot(contains(ArtifactValidationKind.ownerMismatch)),
      );
    });

    test('custodian passes owner_check even without an ownership period', () {
      final report = const ArtifactUsageValidator().validate(
        artifact: _artifact(),
        lineage: _lineage(
          custody: [
            CustodyArrangement.validated(
              custodyId: 'c-vault',
              custodianId: 's-warden',
              custodianName: 'Vault Warden',
              role: CustodyRole.vaultWarden,
            ),
          ],
        ),
        usage: _usage(actorId: 's-warden'),
      );
      expect(
        report.kinds,
        isNot(contains(ArtifactValidationKind.ownerMismatch)),
      );
    });

    test(
      'missing lineage reports unknownOwner instead of passing silently',
      () {
        final report = const ArtifactUsageValidator().validate(
          artifact: _artifact(),
          usage: _usage(actorId: 'h-keryn'),
        );
        expect(report.kinds, contains(ArtifactValidationKind.unknownOwner));
      },
    );
  });

  group('ArtifactUsageValidator activation_check', () {
    test('ability absent from declared rules is unauthorized activation', () {
      final rules = ArtifactRules.validated(
        artifactId: 'art-blade',
        abilities: [
          AbilityRule.validated(abilityId: 'ab-shear', name: 'Shear Shadow'),
        ],
      );
      final report = const ArtifactUsageValidator().validate(
        artifact: _artifact(),
        lineage: _lineage(periods: [_period('h-keryn')]),
        usage: _usage(abilityId: 'ab-burn'),
        rules: rules,
      );
      expect(
        report.kinds,
        contains(ArtifactValidationKind.unauthorizedActivation),
      );
    });

    test('cooldown not elapsed at atTick is unauthorized activation', () {
      final rules = ArtifactRules.validated(
        artifactId: 'art-blade',
        abilities: [
          AbilityRule.validated(abilityId: 'ab-shear', name: 'Shear Shadow'),
        ],
        cooldowns: [
          CooldownRule.validated(cooldownId: 'cd-shear', durationTicks: 100),
        ],
      );
      final report = const ArtifactUsageValidator().validate(
        artifact: _artifact(),
        lineage: _lineage(periods: [_period('h-keryn')]),
        usage: _usage(abilityId: 'ab-shear', atTick: 50),
        rules: rules,
        lastUseTickByCooldown: const {'cd-shear': 10},
      );
      expect(
        report.kinds,
        contains(ArtifactValidationKind.unauthorizedActivation),
      );
      expect(report.issues.first.message, contains('cooldown'));
    });

    test('cooldown elapsed at atTick passes activation_check', () {
      final rules = ArtifactRules.validated(
        artifactId: 'art-blade',
        abilities: [
          AbilityRule.validated(abilityId: 'ab-shear', name: 'Shear Shadow'),
        ],
        cooldowns: [
          CooldownRule.validated(cooldownId: 'cd-shear', durationTicks: 100),
        ],
      );
      final report = const ArtifactUsageValidator().validate(
        artifact: _artifact(),
        lineage: _lineage(periods: [_period('h-keryn')]),
        usage: _usage(abilityId: 'ab-shear', atTick: 110),
        rules: rules,
        lastUseTickByCooldown: const {'cd-shear': 10},
      );
      expect(
        report.kinds,
        isNot(contains(ArtifactValidationKind.unauthorizedActivation)),
      );
    });

    test('use beyond limitation cap is unauthorized activation', () {
      final rules = ArtifactRules.validated(
        artifactId: 'art-blade',
        limitations: [
          LimitationRule.validated(
            limitationId: 'lim-thrice',
            description: 'Three draws only',
            maxUses: 3,
          ),
        ],
      );
      final report = const ArtifactUsageValidator().validate(
        artifact: _artifact(),
        lineage: _lineage(periods: [_period('h-keryn')]),
        usage: _usage(useCount: 4),
        rules: rules,
      );
      expect(
        report.kinds,
        contains(ArtifactValidationKind.unauthorizedActivation),
      );
      expect(report.issues.first.message, contains('exhausted'));
    });
  });

  group('ArtifactUsageValidator location_check', () {
    test(
      'usage outside the allowed-location set is an impossible location',
      () {
        final report = const ArtifactUsageValidator().validate(
          artifact: _artifact(),
          lineage: _lineage(periods: [_period('h-keryn')]),
          usage: _usage(locationId: 'loc-ashfell'),
          allowedLocationIds: {'loc-vault', 'loc-keep'},
        );
        expect(
          report.kinds,
          contains(ArtifactValidationKind.impossibleLocation),
        );
      },
    );

    test('usage at the current recorded residence is consistent', () {
      final lineage = _lineage(
        periods: [_period('h-keryn')],
        locations: [
          LocationRecord.validated(
            locationId: 'lr-1',
            placeId: 'loc-vault',
            placeName: 'Deep Vault',
          ),
        ],
      );
      final report = const ArtifactUsageValidator().validate(
        artifact: _artifact(),
        lineage: lineage,
        usage: _usage(locationId: 'loc-vault'),
      );
      expect(
        report.kinds,
        isNot(contains(ArtifactValidationKind.impossibleLocation)),
      );
    });

    test('usage at a place other than the current residence '
        'is an impossible location', () {
      final lineage = _lineage(
        periods: [_period('h-keryn')],
        locations: [
          LocationRecord.validated(
            locationId: 'lr-1',
            placeId: 'loc-vault',
            placeName: 'Deep Vault',
          ),
        ],
      );
      final report = const ArtifactUsageValidator().validate(
        artifact: _artifact(),
        lineage: lineage,
        usage: _usage(locationId: 'loc-bazaar'),
      );
      expect(report.kinds, contains(ArtifactValidationKind.impossibleLocation));
      expect(report.issues.first.message, contains('current residence'));
    });
  });

  group('ArtifactUsageValidator authenticity_check', () {
    test('forged artifact is flagged as inauthentic', () {
      final report = const ArtifactUsageValidator().validate(
        artifact: _artifact(authenticity: ArtifactAuthenticity.forged),
        lineage: _lineage(periods: [_period('h-keryn')]),
        usage: _usage(),
      );
      expect(report.kinds, contains(ArtifactValidationKind.inauthentic));
    });

    test('disputed and suspected artifacts are flagged as questionable', () {
      final disputed = const ArtifactUsageValidator().validate(
        artifact: _artifact(authenticity: ArtifactAuthenticity.disputed),
        lineage: _lineage(periods: [_period('h-keryn')]),
        usage: _usage(),
      );
      expect(
        disputed.kinds,
        contains(ArtifactValidationKind.questionableAuthenticity),
      );
      final suspected = const ArtifactUsageValidator().validate(
        artifact: _artifact(authenticity: ArtifactAuthenticity.suspected),
        lineage: _lineage(periods: [_period('h-keryn')]),
        usage: _usage(),
      );
      expect(
        suspected.kinds,
        contains(ArtifactValidationKind.questionableAuthenticity),
      );
    });

    test('unknown authenticity is flagged as questionable', () {
      final report = const ArtifactUsageValidator().validate(
        artifact: _artifact(authenticity: ArtifactAuthenticity.unknown),
        lineage: _lineage(periods: [_period('h-keryn')]),
        usage: _usage(),
      );
      expect(
        report.kinds,
        contains(ArtifactValidationKind.questionableAuthenticity),
      );
    });

    test('verified/authentic artifacts pass authenticity_check', () {
      for (final status in [
        ArtifactAuthenticity.verified,
        ArtifactAuthenticity.authentic,
      ]) {
        final report = const ArtifactUsageValidator().validate(
          artifact: _artifact(authenticity: status),
          lineage: _lineage(periods: [_period('h-keryn')]),
          usage: _usage(),
        );
        expect(
          report.kinds,
          isNot(contains(ArtifactValidationKind.inauthentic)),
        );
        expect(
          report.kinds,
          isNot(contains(ArtifactValidationKind.questionableAuthenticity)),
        );
      }
    });
  });

  group('ArtifactValidationReport explain_warning', () {
    test('clean report explains as no warnings', () {
      final report = const ArtifactUsageValidator().validate(
        artifact: _artifact(),
        lineage: _lineage(periods: [_period('h-keryn')]),
        usage: _usage(),
      );
      expect(report.hasIssues, isFalse);
      expect(report.describe(), 'No usage warnings.');
    });

    test('describe() names every active issue kind and message', () {
      final report = const ArtifactUsageValidator().validate(
        artifact: _artifact(authenticity: ArtifactAuthenticity.forged),
        lineage: _lineage(periods: [_period('h-keryn')]),
        usage: _usage(actorId: 'h-thief'),
      );
      expect(report.hasIssues, isTrue);
      final text = report.describe();
      expect(text, contains(ArtifactValidationKind.ownerMismatch.label));
      expect(text, contains(ArtifactValidationKind.inauthentic.label));
      for (final issue in report.issues) {
        expect(text, contains(issue.message));
      }
    });
  });

  group('ArtifactManualException manual_exception', () {
    test('exception scoped to artifact+kind suppresses that issue only', () {
      final exception = ArtifactManualException.validated(
        exceptionId: 'x-owner',
        artifactId: 'art-blade',
        kind: ArtifactValidationKind.ownerMismatch,
        reason: 'Borrowed under chapter 7 truce',
      );
      final report = const ArtifactUsageValidator().validate(
        artifact: _artifact(authenticity: ArtifactAuthenticity.forged),
        lineage: _lineage(periods: [_period('h-keryn')]),
        usage: _usage(actorId: 'h-thief'),
        exceptions: [exception],
      );
      expect(
        report.kinds,
        isNot(contains(ArtifactValidationKind.ownerMismatch)),
      );
      expect(report.kinds, contains(ArtifactValidationKind.inauthentic));
    });

    test('exception for a different artifact does not suppress', () {
      final exception = ArtifactManualException.validated(
        exceptionId: 'x-other',
        artifactId: 'art-lantern',
        kind: ArtifactValidationKind.ownerMismatch,
        reason: 'belongs to a different record',
      );
      final report = const ArtifactUsageValidator().validate(
        artifact: _artifact(),
        lineage: _lineage(periods: [_period('h-keryn')]),
        usage: _usage(actorId: 'h-thief'),
        exceptions: [exception],
      );
      expect(report.kinds, contains(ArtifactValidationKind.ownerMismatch));
    });

    test('exception requires a non-empty reason', () {
      expect(
        () => ArtifactManualException.validated(
          exceptionId: 'x1',
          artifactId: 'art-blade',
          kind: ArtifactValidationKind.impossibleLocation,
          reason: '   ',
        ),
        throwsArgumentError,
      );
    });
  });

  group('determinism and guards', () {
    test('issue ids are stable for identical inputs', () {
      const v = ArtifactUsageValidator();
      final a = v.validate(
        artifact: _artifact(authenticity: ArtifactAuthenticity.forged),
        lineage: _lineage(periods: [_period('h-keryn')]),
        usage: _usage(actorId: 'h-thief'),
      );
      final b = v.validate(
        artifact: _artifact(authenticity: ArtifactAuthenticity.forged),
        lineage: _lineage(periods: [_period('h-keryn')]),
        usage: _usage(actorId: 'h-thief'),
      );
      expect(
        a.issues.map((i) => i.issueId).toList(),
        b.issues.map((i) => i.issueId).toList(),
      );
    });

    test('report issues are sorted by issueId', () {
      final report = const ArtifactUsageValidator().validate(
        artifact: _artifact(authenticity: ArtifactAuthenticity.forged),
        usage: _usage(actorId: 'h-thief'),
      );
      final ids = report.issues.map((i) => i.issueId).toList();
      final sorted = [...ids]..sort();
      expect(ids, sorted);
    });

    test('usage artifactId mismatch against record is rejected', () {
      expect(
        () => const ArtifactUsageValidator().validate(
          artifact: _artifact(id: 'art-blade'),
          lineage: _lineage(periods: [_period('h-keryn')]),
          usage: _usage(artifactId: 'art-lantern'),
        ),
        throwsArgumentError,
      );
    });

    test('lineage artifactId mismatch against record is rejected', () {
      expect(
        () => const ArtifactUsageValidator().validate(
          artifact: _artifact(id: 'art-blade'),
          lineage: _lineage(
            artifactId: 'art-lantern',
            periods: [_period('h-keryn')],
          ),
          usage: _usage(),
        ),
        throwsArgumentError,
      );
    });
  });
}
