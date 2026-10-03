import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/security/credential_store.dart';
import 'package:void_scriptor/features/ai/infrastructure/providers/openai/openai_provider.dart';
import 'package:void_scriptor/features/ai/presentation/ai_provider_workspace_screen.dart';

/// AI Providers — kontrak focus order WCAG 2.4.3.
///
/// Diverifikasi dengan probe pada viewport 1536x1024 / dpr 1.0 memakai
/// `MemoryCredentialStore` (tanpa database/network, tanpa platform channel).
///
/// Urutan Tab (state default, semua provider belum dikonfigurasi):
///   Configure OpenAI -> Configure Gemini -> Configure Ollama ->
///   Configure ComfyUI -> (wrap) Configure OpenAI
///
/// Catatan label: ketiga tombol pada tiap kartu sama-sama berlabel
/// `Configure` (state default tidak punya `Test connection`), jadi identitas
/// stop dikunci lewat judul `ListTile` yang membungkus pusat area fokus —
/// bukan lewat teks tombolnya.
const _expectedProviders = <String>['OpenAI', 'Gemini', 'Ollama', 'ComfyUI'];

/// Ambil label stop: teks non-Icon pertama di subpohon fokus; jika tidak ada,
/// pakai `ValueKey<String>` terdekat pada rantai leluhur.
String _labelOf(BuildContext context) {
  final element = context as Element;
  var label = '';
  void visit(Element node) {
    if (label.isNotEmpty) return;
    final widget = node.widget;
    if (widget is Icon) return;
    if (widget is Text && widget.data?.trim().isNotEmpty == true) {
      label = widget.data!.trim();
      return;
    }
    node.visitChildren(visit);
  }

  visit(element);
  if (label.isEmpty) {
    element.visitAncestorElements((ancestor) {
      final key = ancestor.widget.key;
      if (key is ValueKey<String> && key.value.isNotEmpty) {
        label = key.value;
        return false;
      }
      return true;
    });
  }
  return label.isEmpty ? 'widget:${element.widget.runtimeType}' : label;
}

({String label, Rect rect})? _currentStop() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return null;
  final object = context.findRenderObject();
  final rect = object is RenderBox && object.hasSize
      ? object.localToGlobal(Offset.zero) & object.size
      : Rect.zero;
  return (label: _labelOf(context), rect: rect);
}

/// Provider mana yang kartunya memuat pusat area fokus stop ini.
String _providerAt(WidgetTester tester, Rect stop) {
  final center = stop.center;
  for (final element in find.byType(ListTile).evaluate()) {
    final box = element.findRenderObject();
    if (box is! RenderBox || !box.hasSize) continue;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (!rect.contains(center)) continue;
    final tile = element.widget;
    if (tile is ListTile && tile.title is Text) {
      return ((tile.title as Text).data ?? '').trim();
    }
  }
  return '<no-provider>';
}

/// Tekan Tab sampai rect pertama berulang; berhenti TEPAT pada stop pertama
/// siklus kedua sehingga `stops` memuat urutan lengkap satu putaran.
Future<List<({String label, Rect rect})>> _stops(WidgetTester tester) async {
  final stops = <({String label, Rect rect})>[];
  Rect? first;
  for (var i = 0; i < 24; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final stop = _currentStop();
    if (stop == null) break;
    if (first != null && stop.rect == first) break;
    first ??= stop.rect;
    stops.add(stop);
  }
  return stops;
}

Future<void> _pump(WidgetTester tester, CredentialStore store) async {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(home: AiProviderWorkspaceScreen(credentialStore: store)),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AI Providers — kontrak focus order 2.4.3', () {
    testWidgets('1. empat stop, urutan provider terkunci, area non-zero', (
      tester,
    ) async {
      await _pump(tester, MemoryCredentialStore());
      expect(find.byType(OutlinedButton), findsNWidgets(4));
      final stops = await _stops(tester);
      expect(stops, hasLength(4));
      expect(
        stops.map((stop) => _providerAt(tester, stop.rect)).toList(),
        _expectedProviders,
        reason:
            'Tab must walk the Configure action of each provider card '
            'top-to-bottom: OpenAI, Gemini, Ollama, ComfyUI.',
      );
      expect(
        stops.every((stop) => stop.label == 'Configure'),
        isTrue,
        reason: 'Every default stop is the Configure button of its card.',
      );
      expect(
        stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
        isTrue,
        reason: 'Every focus stop must have a non-zero focus area.',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. kartu menumpuk atas-ke-bawah pada kolom tombol yang sama', (
      tester,
    ) async {
      await _pump(tester, MemoryCredentialStore());
      final stops = await _stops(tester);
      expect(stops, hasLength(4));
      for (var i = 1; i < stops.length; i++) {
        expect(
          stops[i].rect.top,
          greaterThan(stops[i - 1].rect.top),
          reason: 'Provider cards must stack top-to-bottom (stop $i).',
        );
        expect(
          stops[i].rect.left,
          closeTo(stops[i - 1].rect.left, 0.5),
          reason:
              'Configure buttons share one right-hand column (stop $i vs '
              '${i - 1}).',
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '3. state terkonfigurasi menambah stop Test connection di depan '
      'Configure',
      (tester) async {
        final store = MemoryCredentialStore();
        await store.write(
          key: OpenAiProvider.credentialKey,
          value: 'sk-credential-value',
        );
        await _pump(tester, store);
        expect(find.text('Test connection'), findsOneWidget);
        final stops = await _stops(tester);
        expect(stops, hasLength(5));
        expect(stops.first.label, 'Test connection');
        expect(_providerAt(tester, stops.first.rect), 'OpenAI');
        expect(stops[1].label, 'Configure');
        expect(_providerAt(tester, stops[1].rect), 'OpenAI');
        // Test connection ada di kiri Configure dalam baris kartu yang sama.
        expect(stops.first.rect.left, lessThan(stops[1].rect.left));
        expect(
          (stops.first.rect.center.dy - stops[1].rect.center.dy).abs(),
          lessThanOrEqualTo(1.0),
          reason: 'Test connection and Configure share one card row.',
        );
        expect(
          stops.skip(2).map((stop) => _providerAt(tester, stop.rect)).toList(),
          const ['Gemini', 'Ollama', 'ComfyUI'],
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('4. Tab setelah stop terakhir kembali ke stop pertama', (
      tester,
    ) async {
      await _pump(tester, MemoryCredentialStore());
      final stops = await _stops(tester);
      expect(stops, hasLength(4));
      final wrapped = _currentStop();
      expect(wrapped, isNotNull);
      expect(wrapped!.rect, stops.first.rect);
      expect(_providerAt(tester, wrapped.rect), 'OpenAI');
      // Satu Tab lagi lanjut ke kartu kedua — siklus benar-benar utuh.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final next = _currentStop();
      expect(next, isNotNull);
      expect(_providerAt(tester, next!.rect), 'Gemini');
      expect(tester.takeException(), isNull);
    });
  });
}
