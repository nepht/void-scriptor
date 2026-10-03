import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/references/domain/reference_models.dart';
import 'package:void_scriptor/features/references/presentation/reference_management_screen.dart';

/// K Walking the Tab traversal until the cycle repeats.
const int _maxStops = 14;

Future<List<({String label, Rect rect})>> _stops(WidgetTester tester) async {
  final stops = <({String label, Rect rect})>[];
  final seen = <String>{};
  for (var i = 0; i < _maxStops; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) break;
    final object = context.findRenderObject();
    final rect = object is RenderBox && object.hasSize
        ? object.localToGlobal(Offset.zero) & object.size
        : Rect.zero;
    if (!seen.add('${rect.top}|${rect.left}')) break;
    var label = '?';
    void visit(Element element) {
      if (label != '?') return;
      final widget = element.widget;
      if (widget is Icon) return;
      if (widget is Text && widget.data?.trim().isNotEmpty == true) {
        label = widget.data!.trim();
        return;
      }
      element.visitChildren(visit);
    }

    visit(context as Element);
    stops.add((label: label, rect: rect));
  }
  return stops;
}

Widget _screen({int initialTab = 0}) => MaterialApp(
  home: ReferenceManagementScreen(
    initialTab: initialTab,
    onCreateSet: () {},
    onCreateLock: () {},
    onCreateRule: () {},
    ownerAssetId: 'qowner',
    sets: const [
      ReferenceSetModel(
        id: 'set-a',
        projectId: 'p',
        ownerAssetId: 'qowner',
        name: 'Combat Look',
        defaultSet: true,
        referenceIds: ['face', 'hair'],
      ),
      ReferenceSetModel(
        id: 'set-b',
        projectId: 'p',
        ownerAssetId: 'qowner',
        name: 'Travel Look',
        defaultSet: false,
        referenceIds: ['face'],
      ),
    ],
    locks: const [
      PreservationLockModel(
        id: 'lock-a',
        assetId: 'qowner',
        type: PreservationLockType.face,
        enabled: true,
        priority: 100,
        instruction: 'Preserve jawline.',
      ),
    ],
    rules: const [
      ConsistencyRuleModel(
        id: 'rule-a',
        assetId: 'qowner',
        type: ConsistencyRuleType.identity,
        description: 'Face must match canon',
        severity: ConsistencySeverity.critical,
      ),
    ],
    reviews: const [
      ConsistencyReviewModel(
        id: 'review-a',
        generationOutputId: 'out-1',
        assetId: 'qowner',
        status: ConsistencyReviewStatus.reviewRequired,
        notes: 'Needs recheck.',
      ),
    ],
  ),
);

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

List<String> _labels(List<({String label, Rect rect})> stops) =>
    stops.map((stop) => stop.label).toList();

/// Tab strip dibaca sebagai satu siklus: kiri ke kanan, lalu wrap ke tab
/// pertama. Kontrak ini menolak urutan yang misalnya melompat ke tengah strip.
bool _tabStripIsCyclic(List<({String label, Rect rect})> stops) {
  if (stops.length < 2) return false;
  if (!stops.every((stop) => stop.rect.top == stops.first.rect.top)) {
    return false;
  }
  var wraps = 0;
  for (var i = 1; i < stops.length; i++) {
    if (stops[i - 1].rect.left < stops[i].rect.left) continue;
    if (stops[i - 1].rect.left == stops[i].rect.left) continue;
    wraps++;
    if (stops[i].rect.left !=
        stops.map((s) => s.rect.left).reduce((a, b) => a < b ? a : b)) {
      return false;
    }
  }
  return wraps <= 1;
}

void main() {
  group('Reference Management Screen — kontrak focus order 2.4.3', () {
    testWidgets('tab strip traversed left to right before content action', (
      tester,
    ) async {
      _viewport(tester);
      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();

      final stops = await _stops(tester);

      expect(_labels(stops), [
        'Reference Sets',
        'Identity Locks',
        'Consistency Rules',
        'Reports',
        'Create Set',
      ]);
      expect(
        stops.take(4).every((stop) => stop.rect.top == stops.first.rect.top),
        isTrue,
        reason: 'Keempat tab harus berbagi satu baris fokus.',
      );
      for (var i = 1; i < 4; i++) {
        expect(
          stops[i - 1].rect.left,
          lessThan(stops[i].rect.left),
          reason: 'Urutan tab harus kiri ke kanan pada baris yang sama.',
        );
      }
      expect(
        stops.last.rect.top,
        greaterThan(stops[3].rect.top),
        reason: 'Aksi konten harus berada di bawah tab strip.',
      );
      expect(
        stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
        isTrue,
        reason: 'Setiap stop fokus harus punya area non-zero.',
      );
    });

    testWidgets('tab Reports tidak menambah stop aksi konten', (tester) async {
      _viewport(tester);
      await tester.pumpWidget(_screen(initialTab: 3));
      await tester.pumpAndSettle();

      final stops = await _stops(tester);

      expect(_labels(stops), [
        'Reference Sets',
        'Identity Locks',
        'Consistency Rules',
        'Reports',
      ]);
      expect(
        stops.every((stop) => stop.rect.top == stops.first.rect.top),
        isTrue,
        reason: 'Tanpa aksi konten, traversal hanya menyisakan tab strip.',
      );
      expect(
        stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
        isTrue,
      );
    });

    testWidgets(
      'tab Identity Locks dan Consistency Rules mengekspos satu aksi masing-masing',
      (tester) async {
        _viewport(tester);
        await tester.pumpWidget(_screen());
        await tester.pumpAndSettle();

        final expected = <String, String>{
          'Identity Locks': 'Add Lock',
          'Consistency Rules': 'Add Rule',
        };
        for (final entry in expected.entries) {
          await tester.tap(find.text(entry.key));
          await tester.pumpAndSettle();

          final stops = await _stops(tester);
          final labels = _labels(stops);

          expect(labels, contains(entry.value));
          final action = stops[labels.indexOf(entry.value)];
          expect(
            action.rect.top,
            greaterThan(stops.first.rect.top),
            reason: 'Aksi konten harus berada di bawah tab strip.',
          );
          final tabStops = stops
              .where((stop) => stop.rect.top < action.rect.top)
              .toList(growable: false);
          expect(tabStops, isNotEmpty);
          expect(
            tabStops.toSet().length,
            tabStops.length,
            reason: 'Setiap tab hanya boleh muncul satu kali per traversal.',
          );
          expect(
            _tabStripIsCyclic(tabStops),
            isTrue,
            reason: 'Tab strip harus berupa siklus kiri ke kanan lalu wrap.',
          );
          expect(
            stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
            isTrue,
          );
        }
      },
    );
  });
}
