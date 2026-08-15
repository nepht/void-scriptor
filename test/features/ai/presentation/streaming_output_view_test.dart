import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/domain/ai_streaming.dart';
import 'package:void_scriptor/features/ai/presentation/streaming_output_view.dart';

void main() {
  testWidgets('renders streamed text and progress', (tester) async {
    final controller = StreamController<AiStreamingChunk>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StreamingOutputView(stream: controller.stream)),
      ),
    );

    controller.add(const AiStreamingChunk.text('Hello'));
    controller.add(const AiStreamingChunk.text(' world'));
    await tester.pump();

    expect(find.textContaining('Hello world'), findsOneWidget);

    controller.add(const AiStreamingChunk.progress(0.5));
    await tester.pump();
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('shows done state and stops progress', (tester) async {
    final controller = StreamController<AiStreamingChunk>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StreamingOutputView(stream: controller.stream)),
      ),
    );

    controller.add(const AiStreamingChunk.text('final'));
    controller.add(const AiStreamingChunk.done());
    await tester.pump();

    expect(find.textContaining('final'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('shows error chunk message', (tester) async {
    final controller = StreamController<AiStreamingChunk>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StreamingOutputView(stream: controller.stream)),
      ),
    );

    controller.add(const AiStreamingChunk.error('rate limit exceeded'));
    await tester.pump();

    expect(find.textContaining('rate limit exceeded'), findsOneWidget);
  });
}
