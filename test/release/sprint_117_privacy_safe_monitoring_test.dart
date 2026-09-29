import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_privacy_safe_monitoring.dart';

/// Canonical step 117.7 — Privacy-Safe Monitoring Plan.
///
/// Objective (external canonical JSON): monitor connection, quota refresh, sync,
/// usage, billing, errors, and workflow outcomes without creative content.
///
/// The plan's failure mode is not being incomplete — it is being *quietly*
/// wrong in one of two directions. It can name signals it cannot actually
/// collect, in which case "we monitor privacy-safe telemetry" is a sentence
/// with no collection behind it. Or it can collect the very thing it promises
/// to exclude, in which case the privacy claim is the defect.
///
/// Both directions are load-bearing, so the suite protects three distinctions:
///
/// * A signal the sources never recorded is *undecided*, not wrong. 114.4 is
///   DELAYED and 113.42 has no live collector, so no signal can have an observed
///   reading. Those stay null with an open item, exactly as 117.5 and 117.6
///   reported undecided exposure and escalation.
/// * A signal that IS recorded and then contradicted is incoherent, and that is
///   a violation: a privacy_safe signal that carries creative content, a signal
///   collected by default with no consent gate, a retention window of zero.
/// * The exclusion set is enforced against the plan's own rows, not against a
///   promise in prose. 113.4 enumerates what must never be collected; a plan
///   whose rows quietly re-admit one of those is violating its own contract.
void main() {
  const step = Sprint117MonitoringContract.canonicalStep;

  group('contract surface', () {
    test('covers the seven canonical signals in canonical order', () {
      expect(Sprint117MonitoringContract.requiredSignals, <String>[
        'connection_outcome',
        'quota_refresh',
        'sync_outcome',
        'provider_error',
        'usage_metadata',
        'billing_state',
        'workflow_completion',
      ]);
    });

    test('declares the canonical step as 117.7', () {
      expect(step, '117.7');
    });

    test('every source manifest it depends on is a committed file', () {
      for (final path in Sprint117MonitoringContract.sourceManifests) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: 'source manifest $path must exist to be a real source',
        );
      }
    });
  });

  group('live evidence', () {
    late Sprint117MonitoringReport report;

    setUpAll(() {
      report = const Sprint117MonitoringGate().evaluate();
    });

    test('reaches a decided verdict on the committed evidence', () {
      expect(
        report.state,
        Sprint117MonitoringState.pass,
        reason:
            'live violations=${report.violations} '
            'missing=${report.missingFields}',
      );
      expect(report.verdict, Sprint117MonitoringContract.passVerdict);
      expect(report.missingFields, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('decides every canonical signal exactly once', () {
      expect(report.signals, isNotEmpty);
      expect(
        report.signals.map((signal) => signal.signalId).toSet(),
        Sprint117MonitoringContract.requiredSignals.toSet(),
      );
      expect(
        report.signals.length,
        Sprint117MonitoringContract.requiredSignals.length,
        reason: 'a duplicated signal row is one signal wearing two faces',
      );
    });

    test('every signal is privacy-safe and collects no creative content', () {
      for (final signal in report.signals) {
        expect(
          signal.collectsCreativeContent,
          isFalse,
          reason: '${signal.signalId} collects creative content',
        );
        expect(
          signal.privacySafe,
          isTrue,
          reason: '${signal.signalId} is not recorded privacy-safe',
        );
      }
    });

    test(
      'every signal names a source that can actually produce the reading',
      () {
        for (final signal in report.signals) {
          expect(
            signal.collectionMethod,
            isNotEmpty,
            reason: '${signal.signalId} names no collection method',
          );
          expect(
            signal.sourceManifest,
            isNotEmpty,
            reason: '${signal.signalId} is not traceable to a source',
          );
          expect(
            signal.unitKind,
            isNotEmpty,
            reason: '${signal.signalId} declares no unit',
          );
        }
      },
    );

    test('every signal carries a bounded retention window', () {
      for (final signal in report.signals) {
        expect(
          signal.retentionDays,
          greaterThan(0),
          reason: '${signal.signalId} keeps evidence forever or not at all',
        );
        expect(
          signal.retentionDays,
          lessThanOrEqualTo(Sprint117MonitoringContract.maxRetentionDays),
          reason: '${signal.signalId} outranks the recorded retention policy',
        );
      }
    });

    test('consent is required and nothing is collected by default', () {
      expect(report.consentGate, isNotEmpty);
      expect(
        report.defaultCollection,
        isFalse,
        reason: 'telemetry that starts collecting before consent is a breach',
      );
      for (final signal in report.signals) {
        expect(
          signal.requiresExplicitConsent,
          isTrue,
          reason:
              '${signal.signalId} collects without an explicit consent gate',
        );
      }
    });

    test('every signal is traceable to the upstream source that defines it', () {
      // Undetermined is not the same as unmapped. Every signal is deliberately
      // unobserved because no collector has ever run, so that list is expected
      // to be complete; what must be empty is the set a source failed to
      // define, because an unmapped signal is a promise nobody backs.
      expect(report.unmappedSignals, isEmpty);
      expect(
        report.undeterminedSignals,
        Sprint117MonitoringContract.requiredSignals,
        reason:
            'no collector has ever run, so every signal is undecided; a '
            'signal with a reading here would be a fabricated observation',
      );
      for (final signal in report.signals) {
        expect(
          Sprint117MonitoringContract.sourceManifests,
          contains(signal.sourceManifest),
          reason:
              '${signal.signalId} points at ${signal.sourceManifest}, which '
              'is not one of this plan\'s declared sources',
        );
      }
    });

    test('the exclusion set is enforced, not merely promised', () {
      expect(report.excludedCategories, isNotEmpty);
      for (final signal in report.signals) {
        for (final field in signal.collectedFields) {
          expect(
            report.excludedCategories.any(
              (category) =>
                  field.toLowerCase().contains(category.toLowerCase()),
            ),
            isFalse,
            reason: '${signal.signalId} collects the excluded field `$field`',
          );
        }
      }
    });

    test('no observed reading is invented where no collector exists', () {
      expect(
        report.telemetryExecuted,
        isFalse,
        reason: 'no collector has ever reported a reading',
      );
      for (final signal in report.signals) {
        expect(
          signal.observedStatus,
          isNull,
          reason:
              '${signal.signalId} carries an observed reading that no '
              'collector produced',
        );
      }
    });

    test('the enforced exclusion set is the full declared set, not the '
        'subset 113.4 echoes in Indonesian', () {
      // 113.4 states its exclusions in Indonesian; the contract enforces an
      // English token set. Narrowing enforcement to whichever tokens the prose
      // happens to contain would silently drop chapter, credential, and
      // project-file contents — so the whole declared set is enforced and the
      // wording drift is reported as an owned open item instead.
      expect(
        report.excludedCategories,
        Sprint117MonitoringContract.excludedFieldTokens,
      );
      final uncorroborated = Sprint117MonitoringLoader.uncorroboratedExclusions;
      expect(uncorroborated, isNotEmpty);
      // Every token 113.4's wording does not corroborate is owned explicitly;
      // a token it does corroborate must NOT be reported as drift.
      for (final token in uncorroborated) {
        expect(
          report.openItems,
          contains('exclusion_wording_uncorroborated:$token'),
          reason: 'exclusion token $token is enforced but unowned',
        );
      }
      for (final token in Sprint117MonitoringContract.excludedFieldTokens) {
        if (uncorroborated.contains(token)) continue;
        expect(
          report.openItems,
          isNot(contains('exclusion_wording_uncorroborated:$token')),
          reason: '$token is corroborated by 113.4 and must not be flagged',
        );
      }
    });

    test('every undetermined signal survives as an owned open item', () {
      for (final final_ in report.undeterminedSignals) {
        expect(
          report.openItems.any((item) => item.contains(final_)),
          isTrue,
          reason: 'undetermined signal $final_ is not owned anywhere',
        );
      }
    });
  });
  group('fail-closed rules', () {
    Sprint117MonitoringInput baseInput() =>
        const Sprint117MonitoringLoader().load();

    /// The gate derives its violations from `rows` and its policy from `anchor`,
    /// so an override has to reach both. Building a new anchor alone leaves the
    /// loader's rows untouched and the rule under test silently never runs —
    /// which is exactly how the three rules below first shipped unexercised.
    Sprint117MonitoringReport evaluateWithOverride({
      required Sprint117SignalRecord replaceFirst,
      bool? anchorDefaultCollection,
    }) {
      final base = baseInput();
      final original = base.anchor!.signals.first;
      final anchor = Sprint117MonitoringAnchor(
        readinessVerdict: base.anchor!.readinessVerdict,
        evidencePlanVerdict: base.anchor!.evidencePlanVerdict,
        monitoringVerdict: base.anchor!.monitoringVerdict,
        rolloutVerdict: base.anchor!.rolloutVerdict,
        signals: <Sprint117SignalRecord>[
          replaceFirst,
          for (final other in base.anchor!.signals.skip(1)) other,
        ],
        excludedCategories: base.anchor!.excludedCategories,
        liveCollectorAvailable: base.anchor!.liveCollectorAvailable,
        defaultCollection:
            anchorDefaultCollection ?? base.anchor!.defaultCollection,
        consentGate: base.anchor!.consentGate,
        maxRetentionDays: base.anchor!.maxRetentionDays,
        carriedOpenItems: base.anchor!.carriedOpenItems,
      );
      // `original` is unused by design: the row list is rebuilt from the anchor
      // so the mutated row is the one the gate actually evaluates.
      assert(original.signalId == replaceFirst.signalId);
      return const Sprint117MonitoringGate().evaluateWith(
        Sprint117MonitoringInput(rows: anchor.signals, anchor: anchor),
      );
    }

    Sprint117SignalRecord mutatedFirst(
      Sprint117SignalRecord signal, {
      bool? collectsCreativeContent,
      bool? requiresExplicitConsent,
      int? retentionDays,
      String? sourceManifest,
      List<String>? collectedFields,
    }) => Sprint117SignalRecord(
      signalId: signal.signalId,
      description: signal.description,
      collectionMethod: signal.collectionMethod,
      unitKind: signal.unitKind,
      privacyLevel: signal.privacyLevel,
      collectsCreativeContent:
          collectsCreativeContent ?? signal.collectsCreativeContent,
      requiresExplicitConsent:
          requiresExplicitConsent ?? signal.requiresExplicitConsent,
      retentionDays: retentionDays ?? signal.retentionDays,
      observedStatus: signal.observedStatus,
      sourceManifest: sourceManifest ?? signal.sourceManifest,
      collectedFields: collectedFields ?? signal.collectedFields,
    );

    test('a signal that carries creative content is a violation', () {
      final base = baseInput();
      final signal = base.anchor!.signals.first;
      final report = evaluateWithOverride(
        replaceFirst: mutatedFirst(signal, collectsCreativeContent: true),
      );
      expect(report.state, Sprint117MonitoringState.fail);
      expect(
        report.violations,
        contains('signal_creative_content:${signal.signalId}'),
      );
    });

    test('a signal that collects an excluded field is a violation', () {
      final base = baseInput();
      final signal = base.anchor!.signals.first;
      final report = evaluateWithOverride(
        replaceFirst: mutatedFirst(
          signal,
          collectedFields: <String>[
            ...signal.collectedFields,
            'chapter_text_preview',
          ],
        ),
      );
      expect(report.state, Sprint117MonitoringState.fail);
      expect(
        report.violations,
        contains(
          'signal_collects_excluded:${signal.signalId}:chapter_text_preview',
        ),
      );
    });

    test(
      'a retention window longer than the recorded policy is a violation',
      () {
        final base = baseInput();
        final signal = base.anchor!.signals.first;
        final report = evaluateWithOverride(
          replaceFirst: mutatedFirst(
            signal,
            retentionDays: base.anchor!.maxRetentionDays + 1,
          ),
        );
        expect(report.state, Sprint117MonitoringState.fail);
        expect(
          report.violations,
          contains(
            'signal_retention_exceeds_policy:${signal.signalId}:'
            '${base.anchor!.maxRetentionDays + 1}:'
            '${base.anchor!.maxRetentionDays}',
          ),
        );
      },
    );

    test('a signal collected without consent is a violation', () {
      final base = baseInput();
      final signal = base.anchor!.signals.first;
      final report = evaluateWithOverride(
        replaceFirst: mutatedFirst(signal, requiresExplicitConsent: false),
      );
      expect(report.state, Sprint117MonitoringState.fail);
      expect(
        report.violations,
        contains('signal_consent_bypassed:${signal.signalId}'),
      );
    });

    test('collection that starts before consent is a violation', () {
      final base = baseInput();
      final signal = base.anchor!.signals.first;
      final report = evaluateWithOverride(
        replaceFirst: signal,
        anchorDefaultCollection: true,
      );
      expect(report.state, Sprint117MonitoringState.fail);
      expect(report.violations, contains('collection_default_on'));
    });

    test('a signal sourced outside the declared manifests is a violation', () {
      final base = baseInput();
      final signal = base.anchor!.signals.first;
      final report = evaluateWithOverride(
        replaceFirst: mutatedFirst(
          signal,
          sourceManifest: 'docs/planning/v1.2/sprint_999_invented.json',
        ),
      );
      expect(report.state, Sprint117MonitoringState.fail);
      expect(
        report.violations,
        contains(
          'signal_unsourced:${signal.signalId}:'
          'docs/planning/v1.2/sprint_999_invented.json',
        ),
      );
    });

    test('a duplicated signal row is a violation', () {
      final base = baseInput();
      final signal = base.anchor!.signals.first;
      final anchor = Sprint117MonitoringAnchor(
        readinessVerdict: base.anchor!.readinessVerdict,
        evidencePlanVerdict: base.anchor!.evidencePlanVerdict,
        monitoringVerdict: base.anchor!.monitoringVerdict,
        rolloutVerdict: base.anchor!.rolloutVerdict,
        signals: <Sprint117SignalRecord>[signal, signal],
        excludedCategories: base.anchor!.excludedCategories,
        liveCollectorAvailable: base.anchor!.liveCollectorAvailable,
        defaultCollection: base.anchor!.defaultCollection,
        consentGate: base.anchor!.consentGate,
        maxRetentionDays: base.anchor!.maxRetentionDays,
        carriedOpenItems: base.anchor!.carriedOpenItems,
      );
      final report = const Sprint117MonitoringGate().evaluateWith(
        Sprint117MonitoringInput(rows: anchor.signals, anchor: anchor),
      );
      expect(report.state, Sprint117MonitoringState.fail);
      expect(
        report.violations,
        contains('signal_duplicate:${signal.signalId}'),
      );
    });

    test('a canonical signal no source defines is a violation', () {
      final base = baseInput();
      final anchor = Sprint117MonitoringAnchor(
        readinessVerdict: base.anchor!.readinessVerdict,
        evidencePlanVerdict: base.anchor!.evidencePlanVerdict,
        monitoringVerdict: base.anchor!.monitoringVerdict,
        rolloutVerdict: base.anchor!.rolloutVerdict,
        signals: <Sprint117SignalRecord>[
          for (final signal in base.anchor!.signals.skip(1)) signal,
        ],
        excludedCategories: base.anchor!.excludedCategories,
        liveCollectorAvailable: base.anchor!.liveCollectorAvailable,
        defaultCollection: base.anchor!.defaultCollection,
        consentGate: base.anchor!.consentGate,
        maxRetentionDays: base.anchor!.maxRetentionDays,
        carriedOpenItems: base.anchor!.carriedOpenItems,
      );
      final report = const Sprint117MonitoringGate().evaluateWith(
        Sprint117MonitoringInput(rows: anchor.signals, anchor: anchor),
      );
      expect(report.state, Sprint117MonitoringState.fail);
      expect(report.violations, contains('signal_unmapped:connection_outcome'));
    });

    test('the gate blocks when no anchor can be derived from the sources', () {
      final report = const Sprint117MonitoringGate().evaluateWith(
        const Sprint117MonitoringInput(rows: <Sprint117SignalRecord>[]),
      );
      expect(report.state, Sprint117MonitoringState.blocked);
      expect(report.missingFields, contains('monitoring_anchor'));
      expect(report.signals, isEmpty);
    });

    test('a blank retention window is missing evidence, not a violation', () {
      final base = baseInput();
      final signal = base.anchor!.signals.first;
      final report = evaluateWithOverride(
        replaceFirst: mutatedFirst(signal, retentionDays: 0),
      );
      expect(report.state, Sprint117MonitoringState.blocked);
      expect(
        report.missingFields,
        contains('signal_retention:${signal.signalId}'),
      );
      expect(report.violations, isEmpty);
    });

    test('a blank collection method is missing evidence, not a violation', () {
      final base = baseInput();
      final signal = base.anchor!.signals.first;
      final report = evaluateWithOverride(
        replaceFirst: Sprint117SignalRecord(
          signalId: signal.signalId,
          description: signal.description,
          collectionMethod: '',
          unitKind: signal.unitKind,
          privacyLevel: signal.privacyLevel,
          collectsCreativeContent: signal.collectsCreativeContent,
          requiresExplicitConsent: signal.requiresExplicitConsent,
          retentionDays: signal.retentionDays,
          observedStatus: signal.observedStatus,
          sourceManifest: signal.sourceManifest,
          collectedFields: signal.collectedFields,
        ),
      );
      expect(report.state, Sprint117MonitoringState.blocked);
      expect(
        report.missingFields,
        contains('signal_collection_method:${signal.signalId}'),
      );
      expect(report.violations, isEmpty);
    });
  });
}
