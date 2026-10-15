/// Local, fail-closed AI connector interface contract for roadmap step 119.14.
///
/// This file defines opaque model references, modality-filtered model listing,
/// destination-gated execution, streaming order rules, fail-closed
/// cancellation, validated cost metadata, and deterministic health. It does
/// not issue an inference request, consume a live token stream, read a usage
/// meter, or trust a provider pricing feed.
library;

import 'dart:convert';
import 'dart:io';

/// Data modality a model can accept or produce.
enum AiModality { text, image, audio, video, embedding, unknown }

/// Where prompt and completion data is allowed to travel.
enum AiDataDestination {
  providerOnly,
  providerAndSubprocessors,
  localRuntime,
  unknown,
}

/// Permission a caller must hold before an AI operation is allowed.
enum AiPermission { listModels, execute, stream, cancel, readUsage, readCost }

/// Deterministic health of an AI connection.
enum AiHealthStatus { ok, degraded, unavailable }

/// Result of a gated AI operation.
enum AiOperationResult {
  ok,
  deniedMissingPermission,
  deniedUnknownDestination,
  deniedUnknownModel,
  unknownOperation,
}

/// Opaque, non-secret model handle.
///
/// Models are references only: diagnostics never echo the raw value.
final class AiModelRef {
  const AiModelRef(this.value);

  static final RegExp _pattern = RegExp(
    r'^modelref:[a-z][a-z0-9._-]{2,63}:[a-z0-9._-]{1,63}$',
  );

  final String value;

  static AiModelRef? tryParse(String raw) =>
      _pattern.hasMatch(raw) ? AiModelRef(raw) : null;

  @override
  String toString() => '[REDACTED]';
}

/// Provider-neutral model capabilities.
final class AiModelDescriptor {
  const AiModelDescriptor({
    required this.ref,
    required this.modalities,
    required this.supportsStreaming,
    required this.supportsCancellation,
    required this.contextWindowTokens,
  });

  final AiModelRef ref;
  final Set<AiModality> modalities;
  final bool supportsStreaming;
  final bool supportsCancellation;
  final int contextWindowTokens;

  /// Serializes capabilities without echoing the model reference.
  Map<String, Object?> toJson() => <String, Object?>{
    'model_ref': '[REDACTED]',
    'modalities': modalities.map((modality) => modality.name).toList()..sort(),
    'supports_streaming': supportsStreaming,
    'supports_cancellation': supportsCancellation,
    'context_window_tokens': contextWindowTokens,
  };
}

/// Cost metadata for a model. Never a bill, never a credential.
final class AiCostMetadata {
  const AiCostMetadata({
    required this.currency,
    required this.unitLabel,
    required this.unitCost,
    required this.isEstimate,
  });

  final String currency;
  final String unitLabel;
  final double unitCost;

  /// Estimated pricing must never be presented as a settled charge.
  final bool isEstimate;

  Map<String, Object?> toJson() => <String, Object?>{
    'currency': currency,
    'unit_label': unitLabel,
    'unit_cost': unitCost,
    'is_estimate': isEstimate,
  };
}

/// One chunk of a streamed completion.
final class AiStreamChunk {
  const AiStreamChunk({required this.sequence, this.isFinal = false});

  final int sequence;
  final bool isFinal;
}

/// Manifest validation and fail-closed helpers for the 119.14 contract.
abstract final class AiConnectorInterface {
  static const String canonicalStep = '119.14';
  static const String manifestPath =
      'docs/planning/v1.3/sprint_119_ai_connector_interface.json';

  static const List<String> requiredMethods = <String>[
    'list_models',
    'execute',
    'stream',
    'cancel',
    'usage',
    'cost_metadata',
    'destination',
    'health',
  ];

  static const List<String> requiredAcceptance = requiredMethods;

  static final RegExp _opaqueReference = RegExp(
    r'\b(?:modelref|storageref|jobref|credref):[a-z][a-z0-9._-]{2,63}:[a-z0-9._-]{1,63}',
  );

  static final RegExp _iso4217 = RegExp(r'^[A-Z]{3}$');

  /// Returns models declaring every required modality.
  static List<AiModelDescriptor> listModels(
    Iterable<AiModelDescriptor> models, {
    required Set<AiModality> requiredModalities,
  }) => models
      .where((model) => model.modalities.containsAll(requiredModalities))
      .toList(growable: false);

  /// Every operation is denied unless its declared permission is granted.
  static AiOperationResult authorize(
    AiPermission permission,
    Set<AiPermission> granted,
  ) => granted.contains(permission)
      ? AiOperationResult.ok
      : AiOperationResult.deniedMissingPermission;

  /// Execution is denied without permission, a known model, and an explicit
  /// destination.
  static AiOperationResult execute({
    required AiModelRef? model,
    required AiDataDestination destination,
    required Set<AiPermission> granted,
  }) {
    if (authorize(AiPermission.execute, granted) != AiOperationResult.ok) {
      return AiOperationResult.deniedMissingPermission;
    }
    if (model == null) return AiOperationResult.deniedUnknownModel;
    if (destination == AiDataDestination.unknown) {
      return AiOperationResult.deniedUnknownDestination;
    }
    return AiOperationResult.ok;
  }

  /// Streaming requires permission, declared streaming support, and an
  /// explicit destination.
  static AiOperationResult stream({
    required AiModelDescriptor model,
    required AiDataDestination destination,
    required Set<AiPermission> granted,
  }) {
    if (authorize(AiPermission.stream, granted) != AiOperationResult.ok) {
      return AiOperationResult.deniedMissingPermission;
    }
    if (!model.supportsStreaming) return AiOperationResult.unknownOperation;
    if (destination == AiDataDestination.unknown) {
      return AiOperationResult.deniedUnknownDestination;
    }
    return AiOperationResult.ok;
  }

  /// Cancellation fails closed without reauthentication and is unsupported
  /// for models that do not declare cancellation.
  static AiOperationResult cancel({
    required AiModelDescriptor model,
    required bool reauthenticated,
  }) {
    if (!model.supportsCancellation) return AiOperationResult.unknownOperation;
    return reauthenticated
        ? AiOperationResult.ok
        : AiOperationResult.deniedMissingPermission;
  }

  /// True only for a non-empty stream of strictly increasing sequences ending
  /// in exactly one final chunk.
  static bool isOrderedStream(Iterable<AiStreamChunk> chunks) {
    var previous = -1;
    var count = 0;
    var seenFinal = false;
    for (final chunk in chunks) {
      if (seenFinal) return false;
      if (chunk.sequence <= previous) return false;
      previous = chunk.sequence;
      count++;
      if (chunk.isFinal) seenFinal = true;
    }
    return count > 0 && seenFinal;
  }

  /// Reports invalid cost metadata. An empty list means valid.
  static List<String> validateCost(AiCostMetadata cost) {
    final diagnostics = <String>[];
    if (!_iso4217.hasMatch(cost.currency)) {
      diagnostics.add('currency_not_iso4217');
    }
    if (cost.unitLabel.trim().isEmpty) diagnostics.add('unit_label_missing');
    if (!cost.unitCost.isFinite) {
      diagnostics.add('unit_cost_not_finite');
    } else if (cost.unitCost < 0) {
      diagnostics.add('unit_cost_negative');
    }
    return diagnostics;
  }

  /// Deterministic health from caller-supplied local signals.
  static AiHealthStatus health({
    required bool reachable,
    required bool authorized,
    required bool withinQuota,
  }) {
    if (!reachable) return AiHealthStatus.unavailable;
    if (!authorized || !withinQuota) return AiHealthStatus.degraded;
    return AiHealthStatus.ok;
  }

  /// Redacts opaque references from diagnostics.
  static String redact(String message) =>
      message.replaceAll(_opaqueReference, '[REDACTED]');

  static List<String> validateManifest(Map<String, dynamic> manifest) {
    final diagnostics = <String>[];
    if (manifest['canonical_step'] != canonicalStep) {
      diagnostics.add('canonical_step_invalid');
    }
    if (manifest['unknown_field_policy'] != 'REJECT') {
      diagnostics.add('unknown_field_policy_invalid');
    }

    final declared = manifest['required_methods'];
    final declaredSet = declared is List
        ? declared.whereType<String>().toSet()
        : <String>{};
    for (final method in requiredMethods) {
      if (!declaredSet.contains(method)) {
        diagnostics.add('method_missing:$method');
      }
    }

    final acceptance = manifest['acceptance'];
    if (acceptance is! Map<String, dynamic>) {
      for (final key in requiredAcceptance) {
        diagnostics.add('acceptance_missing:$key');
      }
      return diagnostics;
    }
    for (final key in requiredAcceptance) {
      if (!acceptance.containsKey(key)) {
        diagnostics.add('acceptance_missing:$key');
      }
    }
    return diagnostics;
  }

  static List<String> validateCanonicalManifest() {
    final file = File(manifestPath);
    if (!file.existsSync()) return <String>['manifest_missing'];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map<String, dynamic>
          ? validateManifest(decoded)
          : <String>['manifest_root_invalid'];
    } on Object {
      return <String>['manifest_unreadable'];
    }
  }
}
