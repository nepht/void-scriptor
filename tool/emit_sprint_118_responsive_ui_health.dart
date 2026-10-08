// Emit the 118.14 Responsive UI Health record from the gate's own report.
//
// The committed 118.4 baseline, 118.2 charter, 115.6 responsive grid system,
// 115.45 wide desktop visual implementation, 115.46 desktop & tablet
// adaptation, 115.47 mobile adaptation, and 116.47 brand, visual &
// accessibility gate witnesses are the evidence *input*: the gate reads them and
// decides whether the declared review is well-formed. This file is the
// *output*: the gate's measured verdict plus the review's canonical fields, all
// derived from the contract constants and the gate's own report. Nothing here
// is typed by hand, so the record cannot be made to agree with itself.
//
// Run from the repository root:
//   dart run tool/emit_sprint_118_responsive_ui_health.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_responsive_ui_health.dart';

Map<String, Object?> _entry(Sprint118ResponsiveUiHealthEntry entry) =>
    <String, Object?>{
      'signal': entry.signal,
      'reference_state': entry.referenceState,
      'source': entry.source,
      'window': entry.window,
      'limitations': entry.limitations,
      'observed': entry.observed,
    };

void main() {
  const gate = Sprint118ResponsiveUiHealthGate();
  final report = gate.evaluate();
  final anchor = const Sprint118ResponsiveUiHealthLoader().loadAnchor();
  final review = Sprint118ResponsiveUiHealthContract.canonicalReview;

  final record = <String, Object?>{
    'canonical_step': Sprint118ResponsiveUiHealthContract.canonicalStep,
    'title': Sprint118ResponsiveUiHealthContract.title,
    'document_role': 'responsive-ui-health-review-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'review_verified': report.reviewVerified,
    'required_fields': Sprint118ResponsiveUiHealthContract.requiredFields,
    'missing_fields': report.missingFields,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    // The committed witnesses this review is anchored to, from the contract
    // constants -- not retyped, so the record cannot cite a path the gate never
    // opens.
    'evidence_sources': <String, String>{
      'baseline': Sprint118ResponsiveUiHealthContract.baselineManifestPath,
      'charter': Sprint118ResponsiveUiHealthContract.charterManifestPath,
      'grid_system': Sprint118ResponsiveUiHealthContract.gridSystemManifestPath,
      'wide_desktop':
          Sprint118ResponsiveUiHealthContract.wideDesktopManifestPath,
      'desktop_tablet':
          Sprint118ResponsiveUiHealthContract.desktopTabletManifestPath,
      'mobile': Sprint118ResponsiveUiHealthContract.mobileManifestPath,
      'brand_visual':
          Sprint118ResponsiveUiHealthContract.brandVisualManifestPath,
    },
    // Facts read from the committed witnesses, never typed.
    'baseline_state': anchor?.baselineState,
    'baseline_verdict': anchor?.baselineVerdict,
    'baseline_release_state': anchor?.releaseState,
    'charter_state': anchor?.charterState,
    'charter_verdict': anchor?.charterVerdict,
    'charter_window_minutes': anchor?.charterWindowMinutes,
    'witness_grid_system_viewports': anchor?.witnessGridSystemViewports,
    'witness_wide_desktop_acceptance': anchor?.witnessWideDesktopAcceptance,
    'witness_desktop_tablet_acceptance': anchor?.witnessDesktopTabletAcceptance,
    'witness_mobile_acceptance': anchor?.witnessMobileAcceptance,
    'witness_brand_visual_acceptance': anchor?.witnessBrandVisualAcceptance,
    'readable_source_count': anchor?.readableSources.length,
    // The review itself, derived from the contract constants.
    'declared_signal_count': report.declaredSignals.length,
    'declared_signals': report.declaredSignals,
    'canonical_signals': Sprint118ResponsiveUiHealthContract.responsiveSignals,
    'canonical_sources': Sprint118ResponsiveUiHealthContract.canonicalSources,
    'observed_count': report.observedCount,
    'entries': review.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record is the gate verdict over committed 118.4 baseline, 118.2 charter, 115.6 responsive grid system, 115.45 wide desktop visual implementation, 115.46 desktop & tablet adaptation, 115.47 mobile adaptation, and 116.47 brand, visual & accessibility gate evidence. A pass means the declared review carries all five required fields for every one of the seven canonical responsive UI signals; it does not render any layout, compare any screenshot baseline, resize any device, render any chart, or authorize any release.',
      'The review is written against the delayed release state (GA_DELAYED). No release ran, so no entry observes a rendered layout or a live device capture and every entry carries at least one stated limitation.',
      'The gate reads the committed witnesses directly, derives its reference-state vocabulary from the 115.6 responsive grid system acceptance viewports, the 115.45 wide desktop acceptance items, the 115.46 desktop & tablet acceptance items, the 115.47 mobile acceptance items, and the 116.47 brand, visual & accessibility gate acceptance areas, and verifies each entry cites a committed, readable evidence source; an unreadable witness or an unfrozen baseline keeps the review blocked rather than assumed.',
      'The reference-state vocabulary is the distinct union of the responsive grid system, wide desktop, desktop & tablet, mobile, and brand/visual/accessibility witness vocabularies, read from the committed witnesses, so the review and the responsive contracts cannot drift apart silently.',
      'Live rendering, screenshot baseline comparison, device-farm capture, breakpoint resizing, chart rendering, release authorization, and publication remain DEFERRED-EXTERNAL; nothing here is performed or authorized.',
    ],
    'external_gates': <String>[
      'live layout rendering',
      'screenshot baseline comparison',
      'device-farm capture',
      'breakpoint resizing',
      'chart rendering',
      'release authorization',
      'public release publication',
    ],
  };

  final target = File(Sprint118ResponsiveUiHealthContract.manifestPath);
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
