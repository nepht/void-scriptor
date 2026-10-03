import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/settings/presentation/settings_hub_screen.dart';

/// Settings Hub — kontrak focus order WCAG 2.4.3.
///
/// Diverifikasi dengan probe pada viewport 1536x1024 / dpr 1.0 memakai
/// `projectSessionProvider` di-override ke sesi null (tanpa database/network).
///
/// Urutan Tab:
///   General -> Appearance -> Sidebar & Workspace -> About & Diagnostics
///   -> Lokasi penyimpanan kustom -> (wrap) General ...
///
/// Catatan: hanya header empat `ExpansionTile` yang punya stop. Judul anak di
/// dalam `ExpansionTile` yang collapsed tidak punya stop; pada kondisi sesi
/// null hanya `About & Diagnostics` yang `initiallyExpanded`, sehingga satu
/// anaknya — `Lokasi penyimpanan kustom` (ListTile bertap) — ikut berhenti.
/// ListTile tanpa `onTap` (Versi, Platform, Storage diagnostik) bukan stop.
const _expectedLabels = <String>[
  'General',
  'Appearance',
  'Sidebar & Workspace',
  'About & Diagnostics',
  'Lokasi penyimpanan kustom',
];

/// Ambil label stop: teks non-Icon pertama di subpohon fokus.
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

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        projectSessionProvider.overrideWith(() => _NullSessionController()),
      ],
      child: const MaterialApp(home: SettingsHubScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

class _NullSessionController extends ProjectSessionController {
  @override
  Future<ProjectSession?> build() async => null;
}

void main() {
  group('Settings Hub — kontrak focus order 2.4.3', () {
    testWidgets('1. lima stop dengan urutan label yang dikunci', (
      tester,
    ) async {
      await _pump(tester);
      // Empat header section + satu ListTile bertap di About.
      expect(find.byType(ExpansionTile), findsNWidgets(4));
      final stops = await _stops(tester);
      expect(stops, hasLength(5));
      expect(
        stops.map((stop) => stop.label).toList(),
        _expectedLabels,
        reason:
            'Tab must walk the four section headers top-to-bottom, then the '
            'single tappable ListTile inside the expanded About section.',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. area fokus non-zero dan menurun atas-bawah', (
      tester,
    ) async {
      await _pump(tester);
      final stops = await _stops(tester);
      expect(stops, hasLength(5));
      expect(
        stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
        isTrue,
        reason: 'Every focus stop must have a non-zero focus area.',
      );
      for (var i = 1; i < stops.length; i++) {
        expect(
          stops[i].rect.top,
          greaterThan(stops[i - 1].rect.top),
          reason:
              'Focus must move top-to-bottom through the settings list '
              '(stop $i "${stops[i].label}" must sit below '
              '"${stops[i - 1].label}").',
        );
      }
      for (var i = 1; i < stops.length; i++) {
        expect(
          stops[i].rect.left,
          stops[0].rect.left,
          reason: 'All rows share the same left edge in the settings list.',
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('3. Tab setelah stop terakhir kembali ke General', (
      tester,
    ) async {
      await _pump(tester);
      final stops = await _stops(tester);
      expect(stops, hasLength(5));
      // _stops berhenti tepat saat rect General berulang.
      final wrapped = _currentStop();
      expect(wrapped, isNotNull);
      expect(wrapped!.label, _expectedLabels.first);
      expect(wrapped.rect, stops.first.rect);
      // Satu Tab lagi lanjut ke Appearance — siklus benar-benar utuh.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(_currentStop()!.label, _expectedLabels[1]);
      expect(tester.takeException(), isNull);
    });
  });
}
