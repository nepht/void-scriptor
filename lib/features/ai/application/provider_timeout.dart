import 'dart:async';

import '../domain/ai_provider.dart';
import '../domain/ai_streaming.dart';

class AiProviderTimeoutException implements Exception {
  const AiProviderTimeoutException(this.providerId, this.timeout);

  final String providerId;
  final Duration timeout;

  @override
  String toString() => 'AI provider operation timed out.';
}

class AiProviderWithTimeout implements AiProvider {
  AiProviderWithTimeout(this.delegate, {required this.timeout}) {
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(
        timeout,
        'timeout',
        'Timeout must be positive.',
      );
    }
  }

  final AiProvider delegate;
  final Duration timeout;

  @override
  String get id => delegate.id;

  @override
  String get displayName => delegate.displayName;

  @override
  Set<AiCapability> get capabilities => delegate.capabilities;

  @override
  Future<List<AiModelInfo>> listModels() => _withTimeout(delegate.listModels());

  @override
  Future<AiGenerationResult> generate(AiGenerationRequest request) =>
      _withTimeout(delegate.generate(request));

  @override
  Future<void> cancel(String requestId) => delegate.cancel(requestId);

  @override
  bool validateTarget(PromptTarget target) => delegate.validateTarget(target);

  @override
  Stream<AiStreamingChunk> streamGenerate(AiGenerationRequest request) async* {
    try {
      yield* delegate.streamGenerate(request).timeout(timeout);
    } on TimeoutException {
      throw AiProviderTimeoutException(id, timeout);
    }
  }

  Future<T> _withTimeout<T>(Future<T> operation) async {
    try {
      return await operation.timeout(timeout);
    } on TimeoutException {
      throw AiProviderTimeoutException(id, timeout);
    }
  }
}
