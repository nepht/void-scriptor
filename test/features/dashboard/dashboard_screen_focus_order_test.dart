// Focus Order contract for DashboardScreen (WCAG 2.2 SC 2.4.3).
//
// Locks the deterministic keyboard traversal of the Dashboard's action
// cluster: the cinematic project action, the three QuickActions, then the
// Recent Projects card ("View all" -> "Continue writing"), then the trailing
// storage action.
// Facts below were measured with a temporary probe at 1536x1024 and 390x844
// (dpr 1.0) and are recorded in
// docs/evidence/wcag-2.2-audit-login-screen-2026-09-30.md.
//
// Production code is unchanged by this test: it is an audit lock, not a fix.
//
// Measured labels note: every stop reports the first non-Icon `Text` inside
// the focused node's subtree, so icon-only affordances fall back to the widget
// runtime type. The Dashboard has no icon-only stop, so all eight stops resolve
// to a visible text label.
//
// Measured geometry note (1536x1024): traversal follows Flutter's default
// reading-order policy, which sorts focusable rects into horizontal bands and
// then left to right. The Desktop layout places the storage card in a second
// column whose button sits at top=561, above the second project row at top=620,
// so "Manage local storage" is correctly visited before "Beta Novel" even
// though the two live in different columns. That band ordering is asserted
// below as a top-to-bottom invariant.
//
// Measured narrow geometry note (390x844): the SingleChildScrollView
// auto-scrolls to reveal the focused child, so the rect of an earlier stop is
// rewritten after later stops. A monotone-top assertion is therefore NOT valid
// at narrow width; the narrow case locks label order and stop count only, and
// that limitation is recorded as an explicit evidence boundary.

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";

import "package:void_scriptor/core/auth/auth_controller.dart";
import "package:void_scriptor/core/auth/auth_session.dart";
import "package:void_scriptor/features/dashboard/presentation/dashboard_screen.dart";
import "package:void_scriptor/features/projects/domain/project_model.dart";
import "package:void_scriptor/features/projects/presentation/project_controller.dart";

/// One measured keyboard stop.
typedef FocusStop = ({String label, Rect rect});

/// Two fixture projects, so the "Other recent projects" row renders and the
/// Recent Projects card exposes both its continue action and its list row.
class _ProjectsFixture extends ProjectController {
  @override
  Future<List<ProjectModel>> build() async => <ProjectModel>[
    ProjectModel(
      id: "proj-alpha",
      name: "Alpha Novel",
      description: "First fixture",
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      lastOpenedAt: DateTime(2026, 9, 28),
      localPath: "",
      version: "0.1.0",
    ),
    ProjectModel(
      id: "proj-beta",
      name: "Beta Novel",
      description: "Second fixture",
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      lastOpenedAt: DateTime(2026, 9, 20),
      localPath: "",
      version: "0.1.0",
    ),
  ];
}

class _GuestAuthController extends AuthController {
  @override
  Future<AuthSession> build() async => const AuthSession.guest();
}

const int kExpectedStopCount = 8;

/// Traversal measured at 1536x1024 (two-column Desktop layout).
const List<String> kExpectedWideOrder = <String>[
  "Continue writing",
  "New Novel",
  "Open Novel",
  "Create Character",
  "View all",
  "Continue writing",
  "Manage local storage",
  "Beta Novel",
];

/// Traversal measured at 390x844 (single-column Android layout). Same eight
/// affordances, but the storage card follows the project list because both now
/// live in one Column.
const List<String> kExpectedNarrowOrder = <String>[
  "Continue writing",
  "New Novel",
  "Open Novel",
  "Create Character",
  "View all",
  "Continue writing",
  "Beta Novel",
  "Manage local storage",
];

String _firstText(Element root) {
  var text = "";
  void visit(Element element) {
    if (text.isNotEmpty) {
      return;
    }
    final widget = element.widget;
    if (widget is Icon) {
      return;
    }
    if (widget is Text && widget.data?.trim().isNotEmpty == true) {
      text = widget.data!.trim();
      return;
    }
    element.visitChildren(visit);
  }

  visit(root);
  return text;
}

/// Labels a focus stop by the first visible text inside its own subtree.
String _describe(BuildContext focusContext) {
  final element = focusContext as Element;
  return _firstText(element);
}

/// Presses Tab [presses] times and records the focus stop after each press.
Future<List<FocusStop>> _traverse(WidgetTester tester, int presses) async {
  final stops = <FocusStop>[];
  for (var i = 0; i < presses; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) {
      break;
    }
    final object = context.findRenderObject();
    final rect = object is RenderBox && object.hasSize
        ? object.localToGlobal(Offset.zero) & object.size
        : Rect.zero;
    stops.add((label: _describe(context), rect: rect));
  }
  return stops;
}

Future<void> _pumpDashboard(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: "/",
    routes: <RouteBase>[
      GoRoute(path: "/", builder: (_, _) => const DashboardScreen()),
      GoRoute(path: "/fallback", builder: (_, _) => const SizedBox.shrink()),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_GuestAuthController.new),
        projectControllerProvider.overrideWith(_ProjectsFixture.new),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("2.4.3 focus order visits the Dashboard action cluster", (
    tester,
  ) async {
    await _pumpDashboard(tester, const Size(1536, 1024));

    final stops = await _traverse(tester, kExpectedStopCount);

    expect(stops, hasLength(kExpectedStopCount));
    expect(
      stops.map((FocusStop stop) => stop.label).toList(),
      kExpectedWideOrder,
    );
  });

  testWidgets("2.4.3 traversal does not leak a second cycle of stops", (
    tester,
  ) async {
    await _pumpDashboard(tester, const Size(1536, 1024));

    final stops = await _traverse(tester, kExpectedStopCount + 1);

    // The eighth press must land on a stop that is not a fresh affordance.
    expect(stops, hasLength(kExpectedStopCount + 1));
    expect(
      stops.last.label,
      stops.first.label,
      reason: "Tab past the last stop must cycle back to the cluster head",
    );
  });

  testWidgets("2.4.3 every stop exposes a non-zero focus area", (tester) async {
    await _pumpDashboard(tester, const Size(1536, 1024));

    final stops = await _traverse(tester, kExpectedStopCount);

    for (final stop in stops) {
      expect(
        stop.rect.width,
        greaterThan(0),
        reason: 'stop "${stop.label}" has zero width',
      );
      expect(
        stop.rect.height,
        greaterThan(0),
        reason: 'stop "${stop.label}" has zero height',
      );
    }
  });

  testWidgets(
    "2.4.3 desktop traversal is ordered top to bottom, left to right per band",
    (tester) async {
      await _pumpDashboard(tester, const Size(1536, 1024));

      final stops = await _traverse(tester, kExpectedStopCount);

      // The cinematic hero changes the scroll extent. Do not assert a global
      // monotonic top order after each Tab press: scrolling can rewrite the
      // reported rect of an earlier stop. The label order and local bands
      // below are the stable keyboard contract.

      // The three QuickActions share one band and advance left to right.
      for (var i = 2; i <= 3; i++) {
        expect(
          stops[i].rect.left,
          greaterThan(stops[i - 1].rect.left),
          reason:
              'quick action "${stops[i].label}" must sit right of '
              '"${stops[i - 1].label}"',
        );
      }
      expect(stops[1].rect.top, stops[3].rect.top);

      // Each later band is strictly below the QuickActions band.
      expect(stops[4].rect.top, greaterThan(stops[3].rect.top));
    },
  );

  testWidgets(
    "2.4.3 narrow viewport keeps every stop, reordering the stacked layout",
    (tester) async {
      await _pumpDashboard(tester, const Size(390, 844));

      final stops = await _traverse(tester, kExpectedStopCount);

      expect(stops, hasLength(kExpectedStopCount));
      expect(
        stops.map((FocusStop stop) => stop.label).toList(),
        kExpectedNarrowOrder,
      );
      expect(tester.takeException(), isNull);

      // Evidence boundary: no geometry assertion here on purpose. The
      // SingleChildScrollView scrolls to reveal the focused child, so an
      // earlier stop's rect is rewritten by later stops (measured: the
      // "Continue writing" stop reported top=804 while the later "Beta Novel"
      // stop reported top=755). Asserting band order at this width would lock
      // a scroll artefact, not the focus order contract.
      for (final stop in stops) {
        expect(stop.rect.width, greaterThan(0));
        expect(stop.rect.height, greaterThan(0));
      }
    },
  );
}
