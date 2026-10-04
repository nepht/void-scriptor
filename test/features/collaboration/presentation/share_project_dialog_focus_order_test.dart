import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/collaboration/domain/collaborator.dart';
import 'package:void_scriptor/features/collaboration/presentation/share_project_dialog.dart';

const _expectedLabels = <String>['Email', 'owner', 'Cancel', 'Invite'];

/// Resolve a human label for the focused subtree.
///
/// Preference order:
/// 1. first non-icon [Text] descendant (buttons, dropdown values, list rows);
/// 2. the [InputDecoration.labelText] of the nearest enclosing field, because a
///    text field renders its label inside an [InputDecorator] that sits outside
///    the focus node subtree;
/// 3. the runtime type, so a missing label is visibly unlabelled rather than
///    silently attributed to a neighbouring widget.
String _labelOf(BuildContext context) {
  var text = '';
  void visit(Element element) {
    if (text.isNotEmpty) return;
    final widget = element.widget;
    if (widget is Icon) return;
    if (widget is Text && widget.data?.trim().isNotEmpty == true) {
      text = widget.data!.trim();
      return;
    }
    element.visitChildren(visit);
  }

  visit(context as Element);
  if (text.isNotEmpty) return text;

  final root = context;
  var fieldLabel = '';
  root.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    if (widget is TextField) {
      final label = widget.decoration?.labelText;
      if (label != null && label.trim().isNotEmpty) {
        fieldLabel = label.trim();
        return false;
      }
    }
    return true;
  });
  if (fieldLabel.isNotEmpty) return fieldLabel;
  return 'widget:${root.widget.runtimeType}';
}

Future<List<({String label, Rect rect})>> _stops(WidgetTester tester) async {
  final stops = <({String label, Rect rect})>[];
  final seen = <String>{};
  for (var i = 0; i < 8; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) break;
    final object = context.findRenderObject();
    final rect = object is RenderBox && object.hasSize
        ? object.localToGlobal(Offset.zero) & object.size
        : Rect.zero;
    final key = '${rect.left}|${rect.top}|${rect.width}|${rect.height}';
    if (!seen.add(key)) break;
    stops.add((label: _labelOf(context), rect: rect));
  }
  return stops;
}

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _dialog() => MaterialApp(
  home: Scaffold(body: ShareProjectDialog(onInvite: _noop)),
);

void _noop(String email, CollaboratorRole role) {}

void main() {
  testWidgets(
    'Share Project Dialog follows the measured WCAG 2.4.3 focus order',
    (tester) async {
      _viewport(tester);
      await tester.pumpWidget(_dialog());
      await tester.pumpAndSettle();

      final stops = await _stops(tester);

      expect(stops, hasLength(4));
      expect(
        stops.map((stop) => stop.label).toList(),
        _expectedLabels,
        reason:
            'Tab order must follow the visible dialog order: email field, role '
            'dropdown, then the Cancel/Invite action row.',
      );
      expect(
        stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
        isTrue,
        reason: 'Every focus stop must have a non-zero focus area.',
      );
      expect(
        stops[0].rect.top,
        lessThan(stops[1].rect.top),
        reason: 'The email field sits above the role dropdown.',
      );
      expect(
        stops[1].rect.top,
        lessThan(stops[2].rect.top),
        reason: 'The role dropdown sits above the action row.',
      );
      expect(
        stops[2].rect.left,
        lessThan(stops[3].rect.left),
        reason: 'Cancel is the left action, Invite is the right action.',
      );
      expect(
        stops[2].rect.top,
        closeTo(stops[3].rect.top, 1),
        reason: 'Both actions share one horizontal row.',
      );
      expect(
        stops[1].label,
        CollaboratorRole.owner.name,
        reason:
            'The role dropdown must expose its initial value so a keyboard '
            'user knows which role is selected before changing it.',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
