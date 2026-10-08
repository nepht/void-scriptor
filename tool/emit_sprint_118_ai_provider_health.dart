// Emit the 118.11 AI Provider Health record from the gate's own report.
//
// The committed 118.4 baseline, 118.2 charter, 116.26 local AI certification,
// 116.21 OpenAI connector certification, 116.25 OpenRouter connector
// certification, 114.25 provider & external dependency health, and 115.25 AI
// connection & model settings witnesses are the evidence *input*: the gate
// reads them and decides whether the declared review is well-formed. This file
// is the *output*: the gate's measured verdict plus the review's canonical
// fields, all derived from the contract constants and the gate's own report.
// Nothing here is typed by hand, so the record cannot be made to agree with
// itself.
//
// Run from the repository root:
//   dart run tool/emit_sprint_118_ai_provider_health.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_ai_provider_health.dart';

Map<String, Object?> _entry(Sprint118AiProviderHealthEntry entry) =>
    <String, Object?>{
      'signal': entry.signal,
      'reference_state': entry.referenceState,
      'source': entry.source,
      'window': entry.window,
      'limitations': entry.limitations,
      'observed': entry.observed,
    };

void main() {
  const gate = Sprint118AiProviderHealthGate();
  final report = gate.evaluate();
  final anchor = const Sprint118AiProviderHealthLoader().loadAnchor();
  final review = Sprint118AiProviderHealthContract.canonicalReview;

  final record = <String, Object?>{
    'canonical_step': Sprint118AiProviderHealthContract.canonicalStep,
    'title': Sprint118AiProviderHealthContract.title,
    'document_role': 'ai-provider-health-review-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'review_verified': report.reviewVerified,
    'required_fields': Sprint118AiProviderHealthContract.requiredFields,
    'missing_fields': report.missingFields,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    // The committed witnesses this review is anchored to, from the contract
    // constants -- not retyped, so the record cannot cite a path the gate never
    // opens.
    'evidence_sources': <String, String>{
      'baseline': Sprint118AiProviderHealthContract.baselineManifestPath,
      'charter': Sprint118AiProviderHealthContract.charterManifestPath,
      'local_ai': Sprint118AiProviderHealthContract.localAiManifestPath,
      'openai': Sprint118AiProviderHealthContract.openaiManifestPath,
      'openrouter': Sprint118AiProviderHealthContract.openrouterManifestPath,
      'external_dependency':
          Sprint118AiProviderHealthContract.externalDependencyManifestPath,
      'model_settings':
          Sprint118AiProviderHealthContract.modelSettingsManifestPath,
    },
    // Facts read from the committed witnesses, never typed.
    'baseline_state': anchor?.baselineState,
    'baseline_verdict': anchor?.baselineVerdict,
    'baseline_release_state': anchor?.releaseState,
    'charter_state': anchor?.charterState,
    'charter_verdict': anchor?.charterVerdict,
    'charter_window_minutes': anchor?.charterWindowMinutes,
    'witness_local_ai_fields': anchor?.witnessLocalAiFields,
    'witness_openai_fields': anchor?.witnessOpenaiFields,
    'witness_openrouter_fields': anchor?.witnessOpenrouterFields,
    'witness_external_dependency_signals':
        anchor?.witnessExternalDependencySignals,
    'witness_model_settings_acceptance': anchor?.witnessModelSettingsAcceptance,
    'readable_source_count': anchor?.readableSources.length,
    // The review itself, derived from the contract constants.
    'declared_signal_count': report.declaredSignals.length,
    'declared_signals': report.declaredSignals,
    'canonical_signals': Sprint118AiProviderHealthContract.aiProviderSignals,
    'canonical_sources': Sprint118AiProviderHealthContract.canonicalSources,
    'no_reference_state_marker':
        Sprint118AiProviderHealthContract.noReferenceState,
    'observed_count': report.observedCount,
    'entries': review.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record is the gate verdict over committed 118.4 baseline, 118.2 charter, 116.26 local AI certification, 116.21 OpenAI connector certification, 116.25 OpenRouter connector certification, 114.25 provider & external dependency health, and 115.25 AI connection & model settings evidence. A pass means the declared review carries all five required fields for every one of the eight canonical AI provider signals; it does not run any model discovery, job submission, cancellation, usage fetch, cost read, fallback, throttling probe, or credential access, and it does not authorize any release.',
      'The review is written against the delayed release state (GA_DELAYED). No release ran, so no entry observes an AI provider reading and every entry carries at least one stated limitation.',
      'The gate reads the committed witnesses directly, derives its reference-state vocabulary from the 116.26 local AI required fields, the 116.21 OpenAI required fields, the 116.25 OpenRouter required fields, the 114.25 external dependency signals, and the 115.25 model settings acceptance items, and verifies each entry cites a committed, readable evidence source; an unreadable witness or an unfrozen baseline keeps the review blocked rather than assumed.',
      'The reference-state vocabulary is the distinct union of the local AI, OpenAI, OpenRouter, external dependency, and model settings witness vocabularies, read from the committed witnesses, so the review and the AI provider contracts cannot drift apart silently.',
      'The objective names job_success, but the committed AI provider witnesses declare no success state for an AI generation job. The review carries the declared no_reference_state marker and the gate records the upstream omission as an open item (upstream_state_vocabulary_gap:job_success) rather than widening the gate or dropping the requirement.',
      'Live model discovery, job submission, cancellation, usage fetch, cost read, provider fallback, throttling probe, credential access, connector certification, provider exposure, and publication remain DEFERRED-EXTERNAL; nothing here is performed or authorized.',
    ],
    'external_gates': <String>[
      'live model discovery',
      'AI generation job submission',
      'job cancellation',
      'usage metadata fetch',
      'provider cost read',
      'provider fallback execution',
      'throttling probe',
      'credential and token access',
      'connector certification evidence',
      'provider exposure',
      'public release publication',
    ],
  };

  final target = File(Sprint118AiProviderHealthContract.manifestPath);
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
