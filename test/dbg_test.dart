import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/domain/ai_streaming.dart';
import 'package:void_scriptor/features/ai/presentation/streaming_output_view.dart';

void main() {
  testWidgets('debug', (tester) async {
    final controller = StreamController<AiStreamingChunk>();
    addTearDown(controller.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StreamingOutputView(stream: controller.stream)),
      ),
    );
    controller.add(const AiStreamingChunk.progress(0.5));
    await tester.pump();
    await tester.pump();
    debugPrint(
      'COUNT: ${find.byType(LinearProgressIndicator).evaluate().length}',
    );
  });
}
