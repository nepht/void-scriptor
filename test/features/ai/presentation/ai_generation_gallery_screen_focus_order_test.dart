// WCAG 2.2 - 2.4.3 Focus Order untuk AI Generation Gallery.
// Probe nyata 2026-10-03, viewport 1536x1024, devicePixelRatio 1.0:
// 0 Use as Reference: Rect(32, 286, 281.6, 326)
// 1 Compare with Primary: Rect(32, 330, 288, 386)
// Traversal kembali ke stop 0 setelah stop 1.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/presentation/ai_generation_gallery_screen.dart';

String _textUnder(Element element) {
  var result = '';
  element.visitChildElements((child) {
    if (result.isNotEmpty) return;
    final widget = child.widget;
    if (widget is Text && (widget.data?.isNotEmpty ?? false)) {
      result = widget.data!;
    } else {
      result = _textUnder(child);
    }
  });
  return result;
}

class _Stop {
  const _Stop(this.label, this.rect);

  final String label;
  final Rect rect;
}

Future<List<_Stop>> _tabOrder(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: AiGenerationGalleryScreen(
        outputs: const [
          GenerationGalleryItem(
            id: 'output-1',
            path: 'missing.png',
            outputType: 'image',
          ),
        ],
        onUseAsReference: (_) async {},
        onCompareWithPrimary: (_) async {},
      ),
    ),
  );
  await tester.pump();

  final seen = <FocusNode>{};
  final stops = <_Stop>[];
  for (var i = 0; i < 20; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final node = FocusManager.instance.primaryFocus;
    if (node == null || !seen.add(node)) break;

    var label = 'unknown';
    final context = node.context;
    if (context != null) {
      context.visitAncestorElements((element) {
        if (element.widget is TextButton) {
          label = _textUnder(element);
          return false;
        }
        return true;
      });
    }
    final renderObject = context?.findRenderObject();
    final rect = renderObject is RenderBox && renderObject.hasSize
        ? renderObject.localToGlobal(Offset.zero) & renderObject.size
        : Rect.zero;
    stops.add(_Stop(label, rect));
  }
  return stops;
}

void main() {
  testWidgets('gallery follows visual focus order', (tester) async {
    final stops = await _tabOrder(tester);

    expect(stops.map((stop) => stop.label).toList(), <String>[
      'Use as Reference',
      'Compare with Primary',
    ]);
    expect(stops, hasLength(2));
    for (final stop in stops) {
      expect(stop.rect.width, greaterThan(0));
      expect(stop.rect.height, greaterThan(0));
    }

    expect(stops[1].rect.top, greaterThan(stops[0].rect.top));
    expect(stops[1].rect.left, greaterThanOrEqualTo(stops[0].rect.left));
  });
}
