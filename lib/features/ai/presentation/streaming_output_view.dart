import 'package:flutter/material.dart';

import '../domain/ai_streaming.dart';

/// Streams AI generation chunks to the UI (Step 28.3).
///
/// Accumulates text chunks, surfaces progress, and renders error/done states.
class StreamingOutputView extends StatefulWidget {
  const StreamingOutputView({super.key, required this.stream});

  final Stream<AiStreamingChunk> stream;

  @override
  State<StreamingOutputView> createState() => _StreamingOutputViewState();
}

class _StreamingOutputViewState extends State<StreamingOutputView> {
  final StringBuffer _buffer = StringBuffer();
  double? _progress;
  bool _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.stream.listen(
      _onChunk,
      onError: (Object error) {
        setState(() => _error = error.toString());
      },
    );
  }

  void _onChunk(AiStreamingChunk chunk) {
    if (!mounted) return;
    setState(() {
      switch (chunk.type) {
        case AiStreamChunkType.text:
          _buffer.write(chunk.text ?? '');
        case AiStreamChunkType.progress:
          _progress = chunk.progress;
        case AiStreamChunkType.error:
          _error = chunk.error;
        case AiStreamChunkType.done:
          _done = true;
        case AiStreamChunkType.image:
        case AiStreamChunkType.video:
        case AiStreamChunkType.audio:
        case AiStreamChunkType.file:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: SelectableText(_buffer.toString()),
          ),
        ),
        if (_progress != null && !_done)
          LinearProgressIndicator(value: _progress),
      ],
    );
  }
}
