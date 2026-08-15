import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';
import 'package:void_scriptor/features/ai/domain/ai_streaming.dart';

void main() {
  test('AiStreamingChunk has type, text, and progress', () {
    const chunk = AiStreamingChunk(
      type: AiStreamChunkType.text,
      text: 'hello',
      progress: 0.5,
    );
    expect(chunk.type, AiStreamChunkType.text);
    expect(chunk.text, 'hello');
    expect(chunk.progress, 0.5);
    expect(chunk.error, isNull);
  });

  test('AiStreamingChunk error carries message', () {
    const chunk = AiStreamingChunk.error('boom');
    expect(chunk.type, AiStreamChunkType.error);
    expect(chunk.error, 'boom');
  });

  test('AiStreamingResult aggregates chunks into text', () {
    const result = AiStreamingResult(
      outputs: [
        AiGeneratedOutput(type: AiOutputType.text, text: 'part1 '),
        AiGeneratedOutput(type: AiOutputType.text, text: 'part2'),
      ],
    );
    expect(result.aggregatedText, 'part1 part2');
  });
}
