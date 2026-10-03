import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/workflow/presentation/workflow_library_screen.dart';
import 'package:void_scriptor/workflow/workflow_definition.dart';
import 'package:void_scriptor/workflow/workflow_templates.dart';
import 'package:void_scriptor/workflow/workflow_validation.dart';

/// Workflow Library — kontrak focus order WCAG 2.4.3.
///
/// Layar ini hanya punya dua elemen interaktif: tombol `Instantiate & run`
/// (IconButton trailing) pada tiap baris template. AppBar di sini tanpa
/// tombol kembali (home route), jadi tidak ada stop sebelum baris pertama.
/// Urutan diverifikasi dengan probe pada viewport 1536x1024 / dpr 1.0.
const _expectedLabels = <String>['backup-startup@1', 'rename-asset@2'];

WorkflowDefinition _template(String id, int version, String name) {
  final now = DateTime.utc(2026, 8, 24);
  return WorkflowDefinition(
    workflowId: id,
    name: name,
    version: version,
    steps: [WorkflowStep(stepId: 'do-$id', commandType: 'a.cmd')],
    policy: const WorkflowPolicy(allowedCapabilities: {'fs.read'}),
    createdAt: now,
    updatedAt: now,
  );
}

/// Ambil label tile: Text pertama di bawah ListTile terdekat milik stop fokus.
String _labelOf(BuildContext context) {
  final element = context as Element;
  Element? tile;
  element.visitAncestorElements((candidate) {
    if (candidate.widget is ListTile) {
      tile = candidate;
      return false;
    }
    return true;
  });
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

  visit(tile ?? element);
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

Future<List<({String label, Rect rect})>> _stops(WidgetTester tester) async {
  final stops = <({String label, Rect rect})>[];
  final seen = <String>{};
  for (var i = 0; i < 16; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final stop = _currentStop();
    if (stop == null) break;
    final key =
        '${stop.rect.left}|${stop.rect.top}|'
        '${stop.rect.width}|${stop.rect.height}';
    if (!seen.add(key)) break;
    stops.add(stop);
  }
  return stops;
}

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final registry =
      WorkflowTemplateRegistry(
          validationService: WorkflowValidationService(
            knownCommands: const {'a.cmd'},
            commandCapabilities: const {
              'a.cmd': {'fs.read'},
            },
          ),
        )
        ..register(_template('backup-startup', 1, 'Backup at startup'))
        ..register(_template('rename-asset', 2, 'Rename asset'));
  await tester.pumpWidget(
    MaterialApp(home: WorkflowLibraryScreen(registry: registry)),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Workflow Library — kontrak focus order 2.4.3', () {
    testWidgets('1. dua stop dengan urutan label template', (tester) async {
      await _pump(tester);
      expect(find.byType(IconButton), findsNWidgets(2));
      final stops = await _stops(tester);
      expect(stops, hasLength(2));
      expect(
        stops.map((stop) => stop.label).toList(),
        _expectedLabels,
        reason:
            'Tab must walk the two Instantiate & run buttons in list '
            'order (registry sorts template ids).',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. area fokus non-zero dan ditumpuk atas-bawah', (
      tester,
    ) async {
      await _pump(tester);
      final stops = await _stops(tester);
      expect(stops, hasLength(2));
      expect(
        stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
        isTrue,
        reason: 'Every focus stop must have a non-zero focus area.',
      );
      expect(
        stops[1].rect.top,
        greaterThan(stops[0].rect.top),
        reason: 'Focus must move top-to-bottom down the template list.',
      );
      expect(
        stops[1].rect.left,
        stops[0].rect.left,
        reason: 'Both trailing action buttons share the same left edge.',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('3. Tab setelah baris terakhir kembali ke baris pertama', (
      tester,
    ) async {
      await _pump(tester);
      final stops = await _stops(tester);
      expect(stops, hasLength(2));
      // _stops berhenti tepat saat rect berulang, jadi fokus sudah kembali
      // ke baris pertama dengan rect sama.
      final wrapped = _currentStop();
      expect(wrapped, isNotNull);
      expect(wrapped!.label, _expectedLabels.first);
      expect(wrapped.rect, stops.first.rect);
      // Satu Tab lagi melanjutkan ke baris kedua — siklus benar-benar utuh.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(_currentStop()!.label, _expectedLabels[1]);
      expect(tester.takeException(), isNull);
    });
  });
}
