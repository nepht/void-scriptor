import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/environment/presentation/environment_workspace_screen.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

const String _deferredTip = 'More environment actions (deferred)';

const double _viewportWidth = 1536;
const double _viewportHeight = 1024;

class _BoundSession extends ProjectSessionController {
  _BoundSession(this.session);

  final ProjectSession session;

  @override
  Future<ProjectSession?> build() async => session;
}

Future<ProjectSession> _openSession(WidgetTester tester) async {
  late ProjectSession session;
  await tester.runAsync(() async {
    final root = await Directory.systemTemp.createTemp('env-focus-');
    addTearDown(() => root.delete(recursive: true));
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Env Focus');
    session = await ProjectSessionManager().open(package);
    addTearDown(session.database.close);
  });
  return session;
}

String _labelFor(FocusNode? node) {
  final context = node?.context;
  if (context == null) return '<no-focus>';
  var sawIconish = false;

  void visit(Element element, void Function(String) assign) {
    final widget = element.widget;
    if (widget is IconButton) {
      sawIconish = true;
      final tip = widget.tooltip;
      if (tip != null && tip.isNotEmpty) {
        assign(tip);
        return;
      }
    } else if (widget is Tooltip && (widget.message ?? '').isNotEmpty) {
      assign(widget.message!);
      return;
    } else if (widget is Icon) {
      sawIconish = true;
    } else if (widget is Text && (widget.data ?? '').trim().isNotEmpty) {
      assign(widget.data!.trim());
      return;
    }
    element.visitChildren((child) => visit(child, assign));
  }

  var label = '?';
  visit(context as Element, (value) {
    if (label == '?') label = value;
  });
  if (label == '?') label = sawIconish ? '<icon-button>' : '<no-text>';
  return label;
}

Future<List<({String label, Rect rect})>> _tabThrough(
  WidgetTester tester,
) async {
  final stops = <({String label, Rect rect})>[];
  var last = tester.binding.focusManager.primaryFocus;
  for (var i = 0; i < 25; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final node = tester.binding.focusManager.primaryFocus;
    // Fokus tidak bergerak lagi = tidak ada kontrol berikutnya.
    if (identical(node, last)) break;
    last = node;
    // FocusScopeNode adalah scope layar, bukan stop kontrol.
    if (node is FocusScopeNode) continue;
    final ro = node?.context?.findRenderObject();
    if (ro is! RenderBox || !ro.attached || !ro.hasSize) continue;
    final rect = ro.localToGlobal(Offset.zero) & ro.size;
    final stop = (label: _labelFor(node), rect: rect);
    if (stops.any((s) => s.label == stop.label && s.rect == stop.rect)) break;
    stops.add(stop);
  }
  return stops;
}

Future<void> _pumpEnvironment(
  WidgetTester tester, {
  required bool withSession,
}) async {
  tester.view.physicalSize = const Size(_viewportWidth, _viewportHeight);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  Widget home = const EnvironmentWorkspaceScreen(
    environmentId: 'environment-1',
  );
  if (withSession) {
    final session = await _openSession(tester);
    home = ProviderScope(
      overrides: [
        projectSessionProvider.overrideWith(() => _BoundSession(session)),
      ],
      child: home,
    );
    await tester.pumpWidget(MaterialApp(home: home));
  } else {
    await tester.pumpWidget(ProviderScope(child: MaterialApp(home: home)));
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Focus order: session aktif = satu stop konten, aksi deferred tidak ikut',
    (tester) async {
      await _pumpEnvironment(tester, withSession: true);

      expect(find.text('LOCATION PREVIEW'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Add Image'), findsOneWidget);
      expect(find.byTooltip(_deferredTip), findsOneWidget);
      final deferred = tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip(_deferredTip),
          matching: find.byType(IconButton),
        ),
      );
      expect(deferred.onPressed, isNull);

      final stops = await _tabThrough(tester);
      final labels = stops.map((s) => s.label).toList(growable: false);
      // ignore: avoid_print
      print('FOCUS_STOPS=$labels rects=${stops.map((s) => s.rect)}');

      expect(labels, ['Add Image']);
      expect(labels, isNot(contains(_deferredTip)));

      final stop = stops.single;
      expect(stop.rect.width, greaterThan(0));
      expect(stop.rect.height, greaterThan(0));
      expect(stop.rect.left, greaterThanOrEqualTo(0));
      expect(stop.rect.top, greaterThanOrEqualTo(0));
      expect(stop.rect.right, lessThanOrEqualTo(_viewportWidth));
      expect(stop.rect.bottom, lessThanOrEqualTo(_viewportHeight));
      // Header memakan ~96px; stop harus ada di bawahnya (area konten).
      expect(stop.rect.top, greaterThan(96));
      // Lebar 1536 = layout Row: kartu preview di kolom kiri.
      expect(stop.rect.left, lessThan(_viewportWidth / 2));

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Focus order: tanpa project session = nol stop konten, preview tetap ada',
    (tester) async {
      await _pumpEnvironment(tester, withSession: false);

      expect(find.text('LOCATION PREVIEW'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Add Image'), findsNothing);
      expect(find.byTooltip(_deferredTip), findsOneWidget);

      final stops = await _tabThrough(tester);
      final labels = stops.map((s) => s.label).toList(growable: false);
      // ignore: avoid_print
      print('FOCUS_STOPS_NO_SESSION=$labels');

      expect(labels, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
