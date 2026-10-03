// WCAG 2.2 - 2.4.3 Focus Order untuk AI Generation Queue (image target).
//
// Probe nyata 2026-10-04, viewport 1536x1024, devicePixelRatio 1.0, fixture
// 3 job (queued / failed / completed) + submission card aktif. Traversal
// kembali ke stop 0 setelah stop 5:
// 0 Run Queue (AppBar action) Rect(1355.1, 8.0, 180.9, 40.0)
// 1 Image prompt (TextField)    Rect(56.0, 148.0, 1424.0, 96.0)
// 2 openai | comfyui (Dropdown) Rect(40.0, 272.0, 137.1, 48.0)
// 3 Generate Image (FilledButton) Rect(189.1, 276.0, 263.4, 40.0)
// 4 Cancel job-queued (IconButton tooltip) Rect(1444.0, 376.0, 40.0, 40.0)
// 5 Retry job-failed (IconButton tooltip) Rect(1444.0, 460.0, 40.0, 40.0)
//
// Job completed sengaja tidak punya aksi (UI hanya menampilkan status), jadi
// tidak muncul sebagai stop fokus - bukan control yang hilang.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/domain/generation_job.dart';
import 'package:void_scriptor/features/ai/presentation/ai_generation_queue_screen.dart';

/// Label stop fokus dalam urutan Tab yang terukur.
const _expectedLabels = <String>[
  'Text:Run Queue',
  'TextField:Image prompt',
  'Text:openai | Text:comfyui',
  'Text:Generate Image',
  'Tooltip:Cancel job-queued',
  'Tooltip:Retry job-failed',
];

/// Batas area fokus per stop; semua kontrol nyata punya tinggi/luas >= 40 px.
const _minFocusArea = 40.0;

/// Geometri stop fokus pertama (Run Queue di AppBar) hasil probe.
const _firstStopGeometry = '1355,8,181,40';

/// Kunci identik sebuah stop fokus: dipakai untuk mendeteksi traversal yang
/// kembali ke stop sebelumnya (jebakan fokus / traversal tidak%).
String _geometryOf(Rect rect) =>
    '${rect.left.round()},${rect.top.round()},'
    '${rect.width.round()},${rect.height.round()}';

GenerationJob _job(String id, GenerationJobStatus status, {String? error}) =>
    GenerationJob(
      id: id,
      projectId: 'project-1',
      providerId: 'openai',
      promptHistoryId: 'history-1',
      status: status,
      createdAt: DateTime(2026, 10, 4),
      error: error,
    );

/// Label deterministik dari widget yang difokuskan: subtree Text/Tooltip dulu,
/// lalu label TextField dan Tooltip di ancestor (IconButton menyimpan tooltip
/// sebagai ancestor, bukan descendant).
String _labelOf(BuildContext context) {
  final element = context as Element;
  final buffer = StringBuffer();
  void visit(Element node) {
    final widget = node.widget;
    final data = switch (widget) {
      Text() => (widget.data ?? '').trim(),
      Tooltip() => (widget.message ?? '').trim(),
      _ => '',
    };
    if (data.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write(' | ');
      buffer.write('${widget.runtimeType}:$data');
    }
    node.visitChildren(visit);
  }

  visit(element);
  if (buffer.isNotEmpty) return buffer.toString();

  String? ancestorLabel;
  element.visitAncestorElements((candidate) {
    final widget = candidate.widget;
    if (widget is TextField) {
      final decoration = widget.decoration;
      final label = decoration?.labelText ?? decoration?.hintText ?? '';
      if (label.trim().isNotEmpty) {
        ancestorLabel = 'TextField:${label.trim()}';
        return false;
      }
    }
    if (widget is Tooltip && (widget.message ?? '').trim().isNotEmpty) {
      ancestorLabel = 'Tooltip:${(widget.message ?? '').trim()}';
      return false;
    }
    return true;
  });
  return ancestorLabel ?? 'widget:${element.widget.runtimeType}';
}

({String label, Rect rect})? _currentStop() {
  final node = FocusManager.instance.primaryFocus;
  if (node == null || node.context == null) return null;
  final object = node.context!.findRenderObject();
  final rect = object is RenderBox && object.hasSize
      ? object.localToGlobal(Offset.zero) & object.size
      : Rect.zero;
  return (label: _labelOf(node.context!), rect: rect);
}

Future<List<({String label, Rect rect})>> _tabStops(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: AiGenerationQueueScreen(
        jobs: [
          _job('job-queued', GenerationJobStatus.queued),
          _job('job-failed', GenerationJobStatus.failed, error: 'boom'),
          _job('job-completed', GenerationJobStatus.completed),
        ],
        onCancel: (_) async {},
        onRetry: (_) async {},
        onRunQueue: () async {},
        onSubmitImage: ({required prompt, required providerId}) async {},
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);

  final seen = <String>{};
  final stops = <({String label, Rect rect})>[];
  for (var i = 0; i < 40; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final stop = _currentStop();
    if (stop == null) continue;
    final geometry =
        '${stop.rect.left.round()},${stop.rect.top.round()},'
        '${stop.rect.width.round()},${stop.rect.height.round()}';
    if (seen.contains(geometry)) break;
    seen.add(geometry);
    stops.add(stop);
  }
  return stops;
}

void main() {
  testWidgets(
    '2.4.3 focus order mengikuti urutan baca: AppBar, prompt, provider, '
    'submit, lalu aksi job',
    (tester) async {
      final stops = await _tabStops(tester);

      expect(stops.map((s) => s.label).toList(), _expectedLabels);
      expect(stops.length, 6);
    },
  );

  testWidgets('2.4.3 setiap stop fokus punya area bukan nol', (tester) async {
    final stops = await _tabStops(tester);

    for (final stop in stops) {
      expect(
        stop.rect.width > 0 && stop.rect.height > 0,
        isTrue,
        reason: 'stop ${stop.label} punya Rect nol',
      );
      expect(
        stop.rect.shortestSide >= _minFocusArea,
        isTrue,
        reason: 'stop ${stop.label} terlalu kecil: ${stop.rect}',
      );
    }
  });

  testWidgets(
    '2.4.3 traversal kembali ke stop pertama sehingga tidak ada jebakan fokus '
    'setelah aksi job terakhir',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: AiGenerationQueueScreen(
            jobs: [_job('job-queued', GenerationJobStatus.queued)],
            onCancel: (_) async {},
            onRunQueue: () async {},
            onSubmitImage: ({required prompt, required providerId}) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final seen = <String>{};
      for (var i = 0; i < 40; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        final stop = _currentStop();
        if (stop == null) continue;
        final geometry = _geometryOf(stop.rect);
        if (seen.contains(geometry)) {
          expect(geometry, _firstStopGeometry);
          return;
        }
        seen.add(geometry);
      }
      fail('focus traversal tidak pernah kembali ke stop pertama');
    },
  );

  testWidgets('2.4.3 job tanpa aksi (completed) tidak menambah stop fokus', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: AiGenerationQueueScreen(
          jobs: [_job('job-completed', GenerationJobStatus.completed)],
          onCancel: (_) async {},
          onRunQueue: () async {},
          onSubmitImage: ({required prompt, required providerId}) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final seen = <String>{};
    final labels = <String>[];
    for (var i = 0; i < 40; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final stop = _currentStop();
      if (stop == null) continue;
      final geometry = _geometryOf(stop.rect);
      if (seen.contains(geometry)) break;
      seen.add(geometry);
      labels.add(stop.label);
    }

    expect(labels, _expectedLabels.take(4).toList());
  });
}
