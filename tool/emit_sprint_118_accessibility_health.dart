// Emit the 118.15 Accessibility Health record from the gate's own report.
//
// The committed 118.4 baseline, 118.2 charter, 115.7 accessibility interaction
// baseline, 115.48 keyboard & screen reader verification, 114.20 accessibility
// health, 116.47 brand, visual & accessibility gate, and 115.19 storage usage
// cards witnesses are the evidence *input*: the gate reads them and decides
// whether the declared review is well-formed. This file is the *output*: the
// gate's measured verdict plus the review's canonical fields, all derived from
// the contract constants and the gate's own report. Nothing here is typed by
// hand, so the record cannot be made to agree with itself.
//
// Run from the repository root:
//   dart run tool/emit_sprint_118_accessibility_health.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_accessibility_health.dart';

Map<String, Object?> _entry(Sprint118AccessibilityHealthEntry entry) =>
    <String, Object?>{
      'signal': entry.signal,
      'reference_state': entry.referenceState,
      'source': entry.source,
      'window': entry.window,
      'limitations': entry.limitations,
      'observed': entry.observed,
    };

void main() {
  const gate = Sprint118AccessibilityHealthGate();
  final report = gate.evaluate();
  final anchor = const Sprint118AccessibilityHealthLoader().loadAnchor();
  final review = Sprint118AccessibilityHealthContract.canonicalReview;

  final record = <String, Object?>{
    'canonical_step': Sprint118AccessibilityHealthContract.canonicalStep,
    'title': Sprint118AccessibilityHealthContract.title,
    'document_role': 'accessibility-health-review-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'review_verified': report.reviewVerified,
    'required_fields': Sprint118AccessibilityHealthContract.requiredFields,
    'missing_fields': report.missingFields,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    // The committed witnesses this review is anchored to, from the contract
    // constants -- not retyped, so the record cannot cite a path the gate never
    // opens.
    'evidence_sources': <String, String>{
      'baseline': Sprint118AccessibilityHealthContract.baselineManifestPath,
      'charter': Sprint118AccessibilityHealthContract.charterManifestPath,
      'interaction_baseline':
          Sprint118AccessibilityHealthContract.interactionBaselineManifestPath,
      'keyboard_screen_reader':
          Sprint118AccessibilityHealthContract.keyboardScreenReaderManifestPath,
      'accessibility_health':
          Sprint118AccessibilityHealthContract.accessibilityHealthManifestPath,
      'brand_visual':
          Sprint118AccessibilityHealthContract.brandVisualManifestPath,
      'storage_usage_cards':
          Sprint118AccessibilityHealthContract.storageUsageCardsManifestPath,
    },
    // Facts read from the committed witnesses, never typed.
    'baseline_state': anchor?.baselineState,
    'baseline_verdict': anchor?.baselineVerdict,
    'baseline_release_state': anchor?.releaseState,
    'charter_state': anchor?.charterState,
    'charter_verdict': anchor?.charterVerdict,
    'charter_window_minutes': anchor?.charterWindowMinutes,
    'witness_interaction_baseline': anchor?.witnessInteractionBaseline,
    'witness_keyboard_screen_reader': anchor?.witnessKeyboardScreenReader,
    'witness_accessibility_health': anchor?.witnessAccessibilityHealth,
    'witness_brand_visual': anchor?.witnessBrandVisual,
    'witness_storage_usage_cards': anchor?.witnessStorageUsageCards,
    'readable_source_count': anchor?.readableSources.length,
    // The review itself, derived from the contract constants.
    'declared_signal_count': report.declaredSignals.length,
    'declared_signals': report.declaredSignals,
    'canonical_signals':
        Sprint118AccessibilityHealthContract.accessibilitySignals,
    'canonical_sources': Sprint118AccessibilityHealthContract.canonicalSources,
    'observed_count': report.observedCount,
    'entries': review.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record is the gate verdict over committed 118.4 baseline, 118.2 charter, 115.7 accessibility interaction baseline, 115.48 keyboard & screen reader verification, 114.20 accessibility health, 116.47 brand, visual & accessibility gate, and 115.19 storage usage cards evidence. A pass means the declared review carries all five required fields for every one of the eight canonical accessibility signals; it does not run any assistive technology, measure any contrast ratio, measure any touch target, render any scaled layout, or authorize any release.',
      'The review is written against the delayed release state (GA_DELAYED). No release ran, so no entry observes a live assistive-technology run or a real user interaction and every entry carries at least one stated limitation.',
      'The gate reads the committed witnesses directly, derives its reference-state vocabulary from the 115.7 accessibility interaction baseline acceptance items, the 115.48 keyboard & screen reader verification required evidence, the 114.20 accessibility health required evidence, the 116.47 brand, visual & accessibility gate acceptance areas, and the 115.19 storage usage cards acceptance items, and verifies each entry cites a committed, readable evidence source; an unreadable witness or an unfrozen baseline keeps the review blocked rather than assumed.',
      'The reference-state vocabulary is the distinct union of the accessibility interaction baseline, keyboard & screen reader verification, accessibility health, brand/visual/accessibility, and storage usage cards witness vocabularies, read from the committed witnesses, so the review and the accessibility contracts cannot drift apart silently.',
      'Live assistive-technology runs, screen reader verification, contrast measurement, touch-target measurement, scale rendering, release authorization, and publication remain DEFERRED-EXTERNAL; nothing here is performed or authorized.',
    ],
    'external_gates': <String>[
      'live assistive-technology runs',
      'screen reader verification',
      'contrast measurement',
      'touch-target measurement',
      'scale rendering',
      'release authorization',
      'public release publication',
    ],
  };

  final target = File(Sprint118AccessibilityHealthContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(record)}\n',
  );

  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('release_state=${report.releaseState}');
  stdout.writeln('declared_signals=${report.declaredSignals.length}');
  stdout.writeln('observed_count=${report.observedCount}');
  stdout.writeln(
    'readable_source_count=${anchor?.readableSources.length ?? 0}',
  );
  stdout.writeln('blockers=${report.blockers.length}');
  stdout.writeln('violations=${report.violations.length}');
  stdout.writeln('open_items=${report.openItems.length}');
  stdout.writeln('written=${target.path}');
}
