import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_provider_rollback_drill.dart';

/// Canonical step 117.8 — Provider Rollback Drill.
///
/// Objective (external canonical JSON): test connector kill switch, token
/// revoke, queue stop, cached-state handling, artifact rollback, and
/// communication.
///
/// The failure mode of a rollback drill is not being missing — it is looking
/// rehearsed. 113.7 records a five-step drill whose kill switch names
/// `vs12_world_logic_shared`, whose withdrawal targets `void_spector.exe`, and
/// whose zip never existed; 116.50 records two provider kill switches with
/// `drill_verified: false`. A plan that reads as complete in a review is
/// exactly the artifact this gate refuses to accept, so every control here is
/// checked against the shipped implementation or the filesystem rather than
/// against the prose that describes it.
///
/// The suite protects one distinction, and it is the same one 117.5 through
/// 117.7 drew:
///
/// * A control the sources never exercised is *undetermined*, not broken. No
///   provider has been killed, no token revoked, no queue stopped, no artifact
///   withdrawn, and no message sent. Those stay open items.
/// * A control that IS exercised and then contradicted is a violation. A drill
///   step naming a flag the registry rejects, a withdrawal target that does not
///   exist, a kill switch that leaves a flag enabled, or a message sent before
///   it was drafted are contradictions, not gaps.
void main() {
  const step = Sprint117RollbackContract.canonicalStep;

  group('contract surface', () {
    test('covers the six canonical controls in canonical order', () {
      expect(Sprint117RollbackContract.requiredControls, <String>[
        'kill_switch',
        'token_revoke',
        'queue_stop',
        'cache_handling',
        'artifact_rollback',
        'communication',
      ]);
    });

    test('declares the canonical step as 117.8', () {
      expect(step, '117.8');
    });

    test('every source manifest it depends on is a committed file', () {
      for (final path in Sprint117RollbackContract.sourceManifests) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: 'source manifest $path must exist to be a real source',
        );
      }
    });
  });

  group('live drill', () {
    late Sprint117RollbackReport report;

    setUpAll(() {
      report = const Sprint117RollbackGate().evaluate();
    });

    test('reaches a decided verdict on the committed evidence', () {
      expect(
        report.state,
        Sprint117RollbackState.pass,
        reason:
            'live violations=${report.violations} '
            'missing=${report.missingFields}',
      );
      expect(report.verdict, Sprint117RollbackContract.passVerdict);
      expect(report.missingFields, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('decides every canonical control exactly once', () {
      expect(report.controls, isNotEmpty);
      expect(
        report.controls.map((control) => control.controlId).toSet(),
        Sprint117RollbackContract.requiredControls.toSet(),
      );
      expect(
        report.controls.length,
        Sprint117RollbackContract.requiredControls.length,
        reason: 'a duplicated control row is one control wearing two faces',
      );
    });

    test(
      'every control names a source and a drill step that can be executed',
      () {
        for (final control in report.controls) {
          expect(
            control.sourceManifest,
            isNotEmpty,
            reason: '${control.controlId} is not traceable to a source',
          );
          expect(
            Sprint117RollbackContract.sourceManifests,
            contains(control.sourceManifest),
            reason:
                '${control.controlId} points at ${control.sourceManifest}, '
                'which is not one of this drill\'s declared sources',
          );
          expect(
            control.drillStep,
            isNotEmpty,
            reason: '${control.controlId} names no executable drill step',
          );
          expect(
            control.expectedOutcome,
            isNotEmpty,
            reason: '${control.controlId} names no expected outcome',
          );
        }
      },
    );

    test('the drill has never been executed against live providers', () {
      expect(
        report.drillExecuted,
        isFalse,
        reason: 'no provider kill, revoke, or rollback has ever been run live',
      );
      expect(report.undeterminedControls, isNotEmpty);
      for (final control in report.controls) {
        expect(
          control.observedOutcome,
          isNull,
          reason:
              '${control.controlId} carries an observed outcome no drill '
              'produced',
        );
      }
    });

    test('every undetermined control survives as an owned open item', () {
      for (final control in report.undeterminedControls) {
        expect(
          report.openItems.any((item) => item.contains(control)),
          isTrue,
          reason: 'undetermined control $control is not owned anywhere',
        );
      }
    });

    test('a control whose recorded subject cannot be resolved is a violation, '
        'not an open item', () {
      // 113.7 disables `vs12_world_logic_shared` and withdraws
      // `void_spector.exe`. Neither exists in the shipped registry or on
      // disk, so a drill run verbatim would disable nothing and withdraw
      // nothing while still reporting success.
      expect(report.unresolvableReferences, isNotEmpty);
      for (final reference in report.unresolvableReferences) {
        expect(report.openItems, contains('unresolvable_reference:$reference'));
      }
    });

    test('no drill step may claim a live provider result', () {
      // 116.50 records every provider kill switch as drill_verified: false and
      // every communication as sent_at_epoch_ms 0. A step that reported a
      // successful live kill would be fabricating the one observation this
      // gate exists to keep out of the record.
      for (final control in report.controls) {
        expect(control.liveProviderResult, isFalse);
        expect(control.drilledAgainstLiveProvider, isFalse);
      }
    });

    test(
      'artifact rollback resolves recorded targets and reports the rest',
      () {
        final rollback = report.controls.firstWhere(
          (control) => control.controlId == 'artifact_rollback',
        );
        expect(rollback.artifacts, isNotEmpty);
        // 113.7's own withdrawal targets cannot be "found" in the checksum
        // manifest — they were never shipped, and pretending otherwise would
        // make an unresolvable reference look verified. So the manifest is
        // checked only for artifacts it actually recorded, and the rest are
        // required to surface as unresolvable references.
        for (final artifact in rollback.artifacts.where(
          (a) => a.recordedInChecksumManifest,
        )) {
          // The manifest FILE is the authority, not its name: the check is that
          // the recorded path really appears in that file, so a loader that
          // reported "recorded" from the 113.38 JSON alone would be caught.
          expect(
            File(Sprint117RollbackContract.checksumManifest).readAsLinesSync(),
            anyElement(contains('  ${artifact.recordedPath}')),
            reason:
                '${artifact.recordedPath} is reported as recorded in the '
                'checksum manifest but the manifest does not list it',
          );
        }
        final unrecorded = rollback.artifacts
            .where((a) => !a.recordedInChecksumManifest)
            .map((a) => a.recordedPath)
            .toList(growable: false);
        expect(
          unrecorded,
          isNotEmpty,
          reason:
              '113.7 withdraws artifacts the checksum manifest never recorded; '
              'if this list empties, either the manifest changed or the loader '
              'stopped reading it, and either way the gate must be re-read',
        );
        for (final path in unrecorded) {
          expect(
            report.unresolvableReferences,
            contains(path),
            reason:
                '$path was never shipped but is not reported as unresolvable',
          );
        }
      },
    );

    test('communication is drafted for every rollback trigger, never sent', () {
      final comms = report.controls
          .where((control) => control.controlId == 'communication')
          .toList();
      expect(comms, isNotEmpty);
      final control = comms.first;
      expect(control.messages, isNotEmpty);
      for (final message in control.messages) {
        expect(message.template, isNotEmpty);
        expect(message.channel, isNotEmpty);
        expect(message.audience, isNotEmpty);
        expect(
          message.sentAtEpochMs,
          0,
          reason:
              '${message.messageId} records a send that never happened; '
              'drafted_at is set and sent_at is 0 in 116.50',
        );
        expect(message.draftedAtEpochMs, greaterThan(0));
      }
    });

    test('every external gate stays deferred and is named as such', () {
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
      expect(report.limitations, isNotEmpty);
    });
  });

  group('local drill execution', () {
    // The gate above decides whether the recorded drill is coherent. These
    // tests actually run it, because a description of a kill switch is not a
    // kill switch: if the drill only asserted its own prose, every control
    // would pass while no mechanism was ever engaged.
    late Sprint117DrillRun run;

    setUpAll(() async {
      run = await const Sprint117RollbackDrill().run();
    });

    test('runs every canonical control exactly once', () {
      expect(
        run.observations.map((o) => o.controlId).toList(),
        Sprint117RollbackContract.requiredControls,
      );
    });

    test('never touches a live provider', () {
      expect(run.liveProviderTouched, isFalse);
      for (final observation in run.observations) {
        expect(observation.outcome, endsWith('_locally'));
      }
    });

    test('every control responds as its contract expects', () {
      expect(
        run.allPassed,
        isTrue,
        reason:
            'failing controls: '
            '${run.observations.where((o) => !o.passed).map((o) => '${o.controlId}=${o.facts}').toList()}',
      );
    });

    test('the kill switch genuinely disables every registry flag', () {
      final observation = run.observations.firstWhere(
        (o) => o.controlId == 'kill_switch',
      );
      final facts = observation.facts;
      expect(facts['known_flags'], 13);
      expect(
        facts['enabled_before'],
        13,
        reason: 'all flags on before the drill',
      );
      expect(facts['enabled_after'], 0);
      expect(facts['still_enabled'], isEmpty);
      expect(facts['kill_switch_active'], isTrue);
      expect(facts['all_at_defaults'], isTrue);
    });

    test('the token revoke removes the secret and leaks none in audit', () {
      final facts = run.observations
          .firstWhere((o) => o.controlId == 'token_revoke')
          .facts;
      expect(facts['present_before'], isTrue);
      expect(facts['present_after'], isFalse);
      expect(facts['revoke_audited'], isTrue);
      expect(
        facts['audit_carried_secret'],
        isFalse,
        reason: 'a revoke audit record must never carry secret material',
      );
    });

    test('the queue stop actually stops the queue', () {
      final facts = run.observations
          .firstWhere((o) => o.controlId == 'queue_stop')
          .facts;
      expect(facts['cancel_accepted'], isTrue);
      expect(facts['cancelled_status'], 'cancelled');
      // The cancelled job never ran, and exactly one later job did — the stop
      // removed one job rather than halting the whole queue.
      expect(facts['ran_before_stop'], 1);
      expect(facts['ran_after_stop'], 1);
    });

    test('cache handling certifies the drill records, not manifest fixtures', () {
      final facts = run.observations
          .firstWhere((o) => o.controlId == 'cache_handling')
          .facts;
      expect(facts['invalid_records'], isEmpty);
      expect(facts['covered_areas'], isNotEmpty);
      // Every one of 116.44's six acceptance areas is covered by the drill's own
      // records, so a clear that only worked against the manifest's fixtures
      // would show up here as missing coverage.
      expect(
        facts['covered_areas'],
        containsAll(<String>[
          'freshness_label',
          'stale_state',
          'remote_disable',
          'local_actions',
          'reconnect',
          'cache_clear',
        ]),
      );
      expect(facts['stale_entry_ids'], contains('drill_entry_stale'));
    });

    test(
      'artifact rollback reports the misspelled targets instead of repairing '
      'them',
      () {
        final observation = run.observations.firstWhere(
          (o) => o.controlId == 'artifact_rollback',
        );
        // 113.7 spells the executable `void_spector.exe` and names a zip that
        // never shipped. The drill reports both exactly as recorded; the real
        // executable is recorded under its correct name.
        expect(
          observation.unresolvable,
          contains('build/windows/x64/runner/Release/void_spector.exe'),
        );
        expect(
          observation.unresolvable,
          contains('void_spector-1.2.0-rc.1.zip'),
        );
        expect(
          observation.unresolvable,
          isNot(contains('build/windows/x64/runner/Release/void_scriptor.exe')),
        );
      },
    );

    test(
      'the drill finds the same unresolvable references the gate reports',
      () {
        final gate = const Sprint117RollbackGate().evaluate();
        expect(
          run.unresolvableReferences,
          containsAll(gate.unresolvableReferences),
          reason:
              'the drill runs the mechanisms; the gate reads the record. A '
              'reference only one of them can see is a hole in the other.',
        );
        expect(run.unresolvableReferences, isNotEmpty);
      },
    );

    test('communication is drafted for every trigger and none is sent', () {
      final facts = run.observations
          .firstWhere((o) => o.controlId == 'communication')
          .facts;
      expect(facts['messages'] as int, greaterThan(0));
      expect(facts['drafted_not_sent'], facts['messages']);
      expect(
        (facts['triggers'] as List<String?>).cast<String>(),
        containsAll(<String>[
          'stage_advance',
          'stop_condition_hit',
          'rollback_executed',
          'kill_switch_used',
        ]),
        reason: 'every 116.50 trigger needs a drafted message before a drill',
      );
    });
  });

  group('fail-closed rules', () {
    Sprint117RollbackInput baseInput() =>
        const Sprint117RollbackLoader().load();

    /// The gate derives its violations from `rows` and its policy from
    /// `anchor`, so an override must reach both — an anchor-only override
    /// leaves the loader's rows untouched and the rule never runs.
    Sprint117RollbackReport evaluateWithOverride({
      required Sprint117ControlRecord replaceFirst,
      bool? anchorLastStableBuild,
    }) {
      final base = baseInput();
      Sprint117RollbackAnchor anchorFor(
        Sprint117ControlRecord first,
        bool lastStableBuild,
      ) => Sprint117RollbackAnchor(
        drillVerdict: base.anchor!.drillVerdict,
        readinessVerdict: base.anchor!.readinessVerdict,
        stopShipVerdict: base.anchor!.stopShipVerdict,
        controls: <Sprint117ControlRecord>[
          first,
          for (final other in base.anchor!.controls.skip(1)) other,
        ],
        sourceManifests: base.anchor!.sourceManifests,
        defaultFlagState: base.anchor!.defaultFlagState,
        killSwitchResolvable: base.anchor!.killSwitchResolvable,
        lastStableBuild: lastStableBuild,
        localProjectDataTouched: base.anchor!.localProjectDataTouched,
        carriedOpenItems: base.anchor!.carriedOpenItems,
      );
      final anchor = anchorFor(replaceFirst, anchorLastStableBuild ?? true);
      return const Sprint117RollbackGate().evaluateWith(
        Sprint117RollbackInput(rows: anchor.controls, anchor: anchor),
      );
    }

    /// Blank means blank here, so the `??` defaults are applied to the ORIGINAL
    /// value before the override rather than after it. Writing
    /// `expectedOutcome ?? control.expectedOutcome` would silently discard an
    /// intentional empty string — a blank-field test that never tests a blank
    /// field, which is how a fail-closed rule ships untested.
    Sprint117ControlRecord mutatedFirst(
      Sprint117ControlRecord control, {
      String? sourceManifest,
      String? expectedOutcome,
      List<Sprint117ArtifactRef>? artifacts,
    }) => Sprint117ControlRecord(
      controlId: control.controlId,
      drillStep: control.drillStep,
      expectedOutcome: expectedOutcome ?? control.expectedOutcome,
      observedOutcome: control.observedOutcome,
      sourceManifest: sourceManifest ?? control.sourceManifest,
      liveProviderResult: control.liveProviderResult,
      drilledAgainstLiveProvider: control.drilledAgainstLiveProvider,
      artifacts: artifacts ?? control.artifacts,
      messages: control.messages,
    );

    test('a control that reports a live provider result is a violation', () {
      final base = baseInput();
      final report = evaluateWithOverride(
        replaceFirst: Sprint117ControlRecord(
          controlId: base.anchor!.controls.first.controlId,
          drillStep: base.anchor!.controls.first.drillStep,
          expectedOutcome: base.anchor!.controls.first.expectedOutcome,
          observedOutcome: 'kill_switch_engaged_live',
          sourceManifest: base.anchor!.controls.first.sourceManifest,
          liveProviderResult: true,
          drilledAgainstLiveProvider: true,
          artifacts: base.anchor!.controls.first.artifacts,
          messages: base.anchor!.controls.first.messages,
        ),
      );
      expect(report.state, Sprint117RollbackState.fail);
      expect(
        report.violations,
        contains(
          'control_live_provider_claim:${base.anchor!.controls.first.controlId}',
        ),
      );
    });

    test('a control sourced outside the declared manifests is a violation', () {
      final base = baseInput();
      final control = base.anchor!.controls.first;
      final report = evaluateWithOverride(
        replaceFirst: mutatedFirst(
          control,
          sourceManifest: 'docs/planning/v1.2/sprint_999_invented.json',
        ),
      );
      expect(report.state, Sprint117RollbackState.fail);
      expect(
        report.violations,
        contains(
          'control_unsourced:${control.controlId}:'
          'docs/planning/v1.2/sprint_999_invented.json',
        ),
      );
    });

    test('a duplicated control row is a violation', () {
      final base = baseInput();
      final control = base.anchor!.controls.first;
      final anchor = Sprint117RollbackAnchor(
        drillVerdict: base.anchor!.drillVerdict,
        readinessVerdict: base.anchor!.readinessVerdict,
        stopShipVerdict: base.anchor!.stopShipVerdict,
        controls: <Sprint117ControlRecord>[control, control],
        sourceManifests: base.anchor!.sourceManifests,
        defaultFlagState: base.anchor!.defaultFlagState,
        killSwitchResolvable: base.anchor!.killSwitchResolvable,
        lastStableBuild: base.anchor!.lastStableBuild,
        localProjectDataTouched: base.anchor!.localProjectDataTouched,
        carriedOpenItems: base.anchor!.carriedOpenItems,
      );
      final report = const Sprint117RollbackGate().evaluateWith(
        Sprint117RollbackInput(rows: anchor.controls, anchor: anchor),
      );
      expect(report.state, Sprint117RollbackState.fail);
      expect(
        report.violations,
        contains('control_duplicate:${control.controlId}'),
      );
    });

    test('a canonical control no source defines is a violation', () {
      final base = baseInput();
      final anchor = Sprint117RollbackAnchor(
        drillVerdict: base.anchor!.drillVerdict,
        readinessVerdict: base.anchor!.readinessVerdict,
        stopShipVerdict: base.anchor!.stopShipVerdict,
        controls: <Sprint117ControlRecord>[
          for (final control in base.anchor!.controls.skip(1)) control,
        ],
        sourceManifests: base.anchor!.sourceManifests,
        defaultFlagState: base.anchor!.defaultFlagState,
        killSwitchResolvable: base.anchor!.killSwitchResolvable,
        lastStableBuild: base.anchor!.lastStableBuild,
        localProjectDataTouched: base.anchor!.localProjectDataTouched,
        carriedOpenItems: base.anchor!.carriedOpenItems,
      );
      final report = const Sprint117RollbackGate().evaluateWith(
        Sprint117RollbackInput(rows: anchor.controls, anchor: anchor),
      );
      expect(report.state, Sprint117RollbackState.fail);
      expect(report.violations, contains('control_unmapped:kill_switch'));
    });

    test('a blank drill step is missing evidence, not a violation', () {
      final base = baseInput();
      final control = base.anchor!.controls.first;
      final report = evaluateWithOverride(
        replaceFirst: Sprint117ControlRecord(
          controlId: control.controlId,
          drillStep: '',
          expectedOutcome: control.expectedOutcome,
          observedOutcome: control.observedOutcome,
          sourceManifest: control.sourceManifest,
          liveProviderResult: control.liveProviderResult,
          drilledAgainstLiveProvider: control.drilledAgainstLiveProvider,
          artifacts: control.artifacts,
          messages: control.messages,
        ),
      );
      expect(report.state, Sprint117RollbackState.blocked);
      expect(
        report.missingFields,
        contains('control_drill_step:${control.controlId}'),
      );
      expect(report.violations, isEmpty);
    });

    test('a blank expected outcome is missing evidence, not a violation', () {
      final base = baseInput();
      final control = base.anchor!.controls.first;
      final report = evaluateWithOverride(
        replaceFirst: mutatedFirst(control, expectedOutcome: ''),
      );
      expect(report.state, Sprint117RollbackState.blocked);
      expect(
        report.missingFields,
        contains('control_expected_outcome:${control.controlId}'),
      );
      expect(report.violations, isEmpty);
    });

    test('a rollback with no last stable build is a violation', () {
      final base = baseInput();
      final report = evaluateWithOverride(
        replaceFirst: base.anchor!.controls.first,
        anchorLastStableBuild: false,
      );
      expect(report.state, Sprint117RollbackState.fail);
      expect(report.violations, contains('rollback_target_missing'));
    });

    test('the gate blocks when no anchor can be derived from the sources', () {
      final report = const Sprint117RollbackGate().evaluateWith(
        const Sprint117RollbackInput(rows: <Sprint117ControlRecord>[]),
      );
      expect(report.state, Sprint117RollbackState.blocked);
      expect(report.missingFields, contains('rollback_anchor'));
      expect(report.controls, isEmpty);
    });
  });
}
