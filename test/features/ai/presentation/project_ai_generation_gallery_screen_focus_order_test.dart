// WCAG 2.2 - 2.4.3 Focus Order untuk ProjectAiGenerationGalleryScreen.
// Probe nyata 2026-10-04, viewport 1536x1024, devicePixelRatio 1.0:
// 0 Use as Reference: Rect(32, 286, 249.6, 40)      kartu kiri, baris 1
// 1 Use as Reference: Rect(336, 286, 249.6, 40)     kartu kanan, baris 1
// 2 Compare with Primary: Rect(32, 330, 260, 56)    kartu kiri, baris 2
// 3 Compare with Primary: Rect(336, 330, 256, 56)   kartu kanan, baris 2
// 4 = stop 0 (wrap).
// Traversal membaca baris demi baris di seluruh grid (bukan per kartu),
// kebijakan ReadingOrder bawaan MaterialApp.
//
// Fixture: `projectSessionProvider` mengembalikan session non-null palsu
// (hanya penanda project terbuka; tanpa database, tanpa file system, tanpa
// network) supaya callback galeri non-null dan tombolnya fokus-able, dan
// `projectGenerationOutputsProvider` di-override dengan dua item in-memory
// berpath sengaja tidak ada (render ColoredBox, tanpa decode gambar).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/presentation/ai_generation_gallery_screen.dart';
import 'package:void_scriptor/features/ai/presentation/project_ai_generation_gallery_screen.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

const _expectedLabels = <String>[
  'Use as Reference',
  'Use as Reference',
  'Compare with Primary',
  'Compare with Primary',
];

/// Session non-null palsu: hanya penanda "project terbuka". Tidak ada anggota
/// yang diakses saat render galeri (callback dipanggil hanya saat tombol ditekan).
class _FakeSession implements ProjectSession {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SessionController extends ProjectSessionController {
  @override
  Future<ProjectSession?> build() async => _FakeSession();
}

String _labelOf(BuildContext context) {
  var label = '';
  void visit(Element element) {
    if (label.isNotEmpty) return;
    final widget = element.widget;
    if (widget is Icon) return;
    if (widget is Text && widget.data?.trim().isNotEmpty == true) {
      label = widget.data!.trim();
      return;
    }
    element.visitChildren(visit);
  }

  visit(context as Element);
  return label.isEmpty ? 'widget:${context.widget.runtimeType}' : label;
}

Future<List<({String label, Rect rect})>> _stops(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        projectSessionProvider.overrideWith(_SessionController.new),
        projectGenerationOutputsProvider.overrideWith(
          (ref) async => const [
            GenerationGalleryItem(
              id: 'output-1',
              path: 'missing.png',
              outputType: 'image',
            ),
            GenerationGalleryItem(
              id: 'output-2',
              path: 'missing2.png',
              outputType: 'image',
            ),
          ],
        ),
      ],
      child: const MaterialApp(home: ProjectAiGenerationGalleryScreen()),
    ),
  );
  await tester.pumpAndSettle();

  final stops = <({String label, Rect rect})>[];
  // Satu Tab ekstra untuk membuktikan rantai fokus berputar ke stop pertama.
  for (var i = 0; i < _expectedLabels.length + 1; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final context = FocusManager.instance.primaryFocus?.context;
    expect(context, isNotNull, reason: 'Setiap Tab harus punya fokus.');
    final object = context!.findRenderObject();
    final rect = object is RenderBox && object.hasSize
        ? object.localToGlobal(Offset.zero) & object.size
        : Rect.zero;
    stops.add((label: _labelOf(context), rect: rect));
  }
  return stops;
}

void main() {
  testWidgets('mengunci urutan focus order 2.4.3', (tester) async {
    final stops = await _stops(tester);

    // 1. Jumlah stop = 4 tombol (2 kartu x 2 aksi) lalu wrap ke stop pertama.
    expect(stops, hasLength(_expectedLabels.length + 1));
    expect(stops.map((stop) => stop.label).toList(), [
      ..._expectedLabels,
      _expectedLabels.first,
    ]);

    // 2. Setiap area fokus non-zero.
    for (final stop in stops) {
      expect(stop.rect.width, greaterThan(0), reason: stop.label);
      expect(stop.rect.height, greaterThan(0), reason: stop.label);
    }

    // 3. Traversal baris demi baris: baris 1 (dua "Use as Reference") dulu,
    //    kiri ke kanan, baru baris 2 (dua "Compare with Primary").
    expect(stops[0].rect.top, stops[1].rect.top);
    expect(stops[1].rect.left, greaterThan(stops[0].rect.left));
    expect(stops[2].rect.top, greaterThan(stops[0].rect.top));
    expect(stops[3].rect.top, greaterThan(stops[1].rect.top));

    // 4. Kolom kiri dan kanan tetap: stop 2 sejajar dengan 0, stop 3 dengan 1.
    expect(stops[2].rect.left, stops[0].rect.left);
    expect(stops[3].rect.left, stops[1].rect.left);
    expect(stops[3].rect.top, stops[2].rect.top);
  });
}
