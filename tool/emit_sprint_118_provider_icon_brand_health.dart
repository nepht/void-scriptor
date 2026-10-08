// Emit the 118.13 Provider Icon & Brand Health record from the gate's own
// report.
//
// The committed 118.4 baseline, 118.2 charter, 115.8 provider icon registry,
// 116.7 brand asset & icon certification, and 116.47 brand, visual &
// accessibility gate witnesses are the evidence *input*: the gate reads them and
// decides whether the declared review is well-formed. This file is the
// *output*: the gate's measured verdict plus the review's canonical fields, all
// derived from the contract constants and the gate's own report. Nothing here
// is typed by hand, so the record cannot be made to agree with itself.
//
// Run from the repository root:
//   dart run tool/emit_sprint_118_provider_icon_brand_health.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_provider_icon_brand_health.dart';

Map<String, Object?> _entry(Sprint118ProviderIconBrandHealthEntry entry) =>
    <String, Object?>{
      'signal': entry.signal,
      'reference_state': entry.referenceState,
      'source': entry.source,
      'window': entry.window,
      'limitations': entry.limitations,
      'observed': entry.observed,
    };

void main() {
  const gate = Sprint118ProviderIconBrandHealthGate();
  final report = gate.evaluate();
  final anchor = const Sprint118ProviderIconBrandHealthLoader().loadAnchor();
  final review = Sprint118ProviderIconBrandHealthContract.canonicalReview;

  final record = <String, Object?>{
    'canonical_step': Sprint118ProviderIconBrandHealthContract.canonicalStep,
    'title': Sprint118ProviderIconBrandHealthContract.title,
    'document_role': 'provider-icon-brand-health-review-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'review_verified': report.reviewVerified,
    'required_fields': Sprint118ProviderIconBrandHealthContract.requiredFields,
    'missing_fields': report.missingFields,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    // The committed witnesses this review is anchored to, from the contract
    // constants -- not retyped, so the record cannot cite a path the gate never
    // opens.
    'evidence_sources': <String, String>{
      'baseline': Sprint118ProviderIconBrandHealthContract.baselineManifestPath,
      'charter': Sprint118ProviderIconBrandHealthContract.charterManifestPath,
      'icon_registry':
          Sprint118ProviderIconBrandHealthContract.iconRegistryManifestPath,
      'brand_certification': Sprint118ProviderIconBrandHealthContract
          .brandCertificationManifestPath,
      'brand_visual':
          Sprint118ProviderIconBrandHealthContract.brandVisualManifestPath,
    },
    // Facts read from the committed witnesses, never typed.
    'baseline_state': anchor?.baselineState,
    'baseline_verdict': anchor?.baselineVerdict,
    'baseline_release_state': anchor?.releaseState,
    'charter_state': anchor?.charterState,
    'charter_verdict': anchor?.charterVerdict,
    'charter_window_minutes': anchor?.charterWindowMinutes,
    'witness_icon_registry_fields': anchor?.witnessIconRegistryFields,
    'witness_icon_registry_acceptance': anchor?.witnessIconRegistryAcceptance,
    'witness_brand_certification_fields':
        anchor?.witnessBrandCertificationFields,
    'witness_brand_visual_acceptance': anchor?.witnessBrandVisualAcceptance,
    'readable_source_count': anchor?.readableSources.length,
    // The review itself, derived from the contract constants.
    'declared_signal_count': report.declaredSignals.length,
    'declared_signals': report.declaredSignals,
    'canonical_signals':
        Sprint118ProviderIconBrandHealthContract.iconBrandSignals,
    'canonical_sources':
        Sprint118ProviderIconBrandHealthContract.canonicalSources,
    'observed_count': report.observedCount,
    'entries': review.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record is the gate verdict over committed 118.4 baseline, 118.2 charter, 115.8 provider icon registry, 116.7 brand asset & icon certification, and 116.47 brand, visual & accessibility gate evidence. A pass means the declared review carries all five required fields for every one of the six canonical provider icon & brand signals; it does not render any icon, compare any screenshot baseline, collect any brand complaint, or authorize any release.',
      'The review is written against the delayed release state (GA_DELAYED). No release ran, so no entry observes an icon or brand reading and every entry carries at least one stated limitation.',
      'The gate reads the committed witnesses directly, derives its reference-state vocabulary from the 115.8 provider icon registry required fields and acceptance items, the 116.7 brand asset & icon certification required fields, and the 116.47 brand, visual & accessibility gate acceptance areas, and verifies each entry cites a committed, readable evidence source; an unreadable witness or an unfrozen baseline keeps the review blocked rather than assumed.',
      'The reference-state vocabulary is the distinct union of the provider icon registry, brand asset & icon certification, and brand, visual & accessibility gate witness vocabularies, read from the committed witnesses, so the review and the icon & brand contracts cannot drift apart silently.',
      'The brand_issue signal carries the no_reference_state marker because the committed icon & brand witnesses declare no state for a brand complaint; the gate records that upstream gap as an open item rather than inventing a state or widening the gate.',
      'Live icon rendering, screenshot baseline comparison, per-provider brand approval, brand complaint intake, connector certification, provider exposure, and publication remain DEFERRED-EXTERNAL; nothing here is performed or authorized.',
    ],
    'external_gates': <String>[
      'live icon rendering',
      'screenshot baseline comparison',
      'per-provider brand approval',
      'brand complaint intake and resolution',
      'connector certification evidence',
      'provider exposure',
      'public release publication',
    ],
  };

  final target = File(Sprint118ProviderIconBrandHealthContract.manifestPath);
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
