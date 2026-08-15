import 'ai_provider.dart';

/// Streaming chunk emitted during a generation (Step 28.1).
enum AiStreamChunkType {
  text,
  progress,
  image,
  video,
  audio,
  file,
  error,
  done,
}

class AiStreamingChunk {
  const AiStreamingChunk({
    required this.type,
    this.text,
    this.progress,
    this.error,
    this.remoteUrl,
    this.localPath,
    this.mimeType,
  });

  const AiStreamingChunk.text(String value)
    : type = AiStreamChunkType.text,
      text = value,
      progress = null,
      error = null,
      remoteUrl = null,
      localPath = null,
      mimeType = null;

  const AiStreamingChunk.progress(double value)
    : type = AiStreamChunkType.progress,
      text = null,
      progress = value,
      error = null,
      remoteUrl = null,
      localPath = null,
      mimeType = null;

  const AiStreamingChunk.error(String message)
    : type = AiStreamChunkType.error,
      text = null,
      progress = null,
      error = message,
      remoteUrl = null,
      localPath = null,
      mimeType = null;

  const AiStreamingChunk.done()
    : type = AiStreamChunkType.done,
      text = null,
      progress = null,
      error = null,
      remoteUrl = null,
      localPath = null,
      mimeType = null;

  final AiStreamChunkType type;
  final String? text;
  final double? progress;
  final String? error;
  final String? remoteUrl;
  final String? localPath;
  final String? mimeType;
}

/// The terminal result of a streamed generation.
class AiStreamingResult {
  const AiStreamingResult({
    required this.outputs,
    this.providerRequestId,
    this.metadata = const {},
  });

  final List<AiGeneratedOutput> outputs;
  final String? providerRequestId;
  final Map<String, Object?> metadata;

  String get aggregatedText =>
      outputs.map((output) => output.text ?? '').join();
}
