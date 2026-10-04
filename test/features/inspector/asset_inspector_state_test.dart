import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/inspector/presentation/inspectors/wardrobe_inspector.dart';
import 'package:void_scriptor/features/inspector/presentation/inspectors/weapon_inspector.dart';

/// Regression coverage for vs-hunt-20260913-inspector INS-BUG-02 and
/// INS-BUG-03: WardrobeInspector and WeaponInspector rendered the raw
/// asset UUID while their provider was still loading or had errored, and
/// WardrobeInspector also fell back to the raw UUID for missing data.
/// The loadout UX contract forbids surfacing raw UUID tokens; loading must
/// show a real progress indicator, errors a visible message, and an
/// unresolvable asset must read 'Unknown asset'.
///
/// Finders are scoped below the inspector widget because RelationSection
/// legitimately carries the id in its own internals (OUTSIDE this fix's
/// queue, tracked as a separate INS-BUG scope concern).
void main() {
  const wardrobeId = 'wardrobe-1';
  const weaponId = 'weapon-1';

  const wardrobeData = WardrobeInspectorData(
    name: 'Coat of Quiet Ash',
    category: 'outerwear',
    material: 'wool',
    fabric: 'twill',
    fit: 'relaxed',
    style: 'travel',
    variants: ['field'],
    incomingRelationCount: 0,
  );

  const weaponData = WeaponInspectorData(
    name: 'Pale Verdict',
    weaponType: 'blade',
    material: 'steel',
    length: '420 mm',
    energy: 'none',
    core: 'solid',
    variant: 'default',
    incomingRelationCount: 0,
  );

  Future<void> pumpWith(
    WidgetTester tester,
    List<Override> overrides,
    Widget inspector,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 1280, height: 900, child: inspector),
          ),
        ),
      ),
    );
  }

  // ---------- WardrobeInspector ----------

  testWidgets('wardrobe header shows a loading indicator, not the raw id', (
    tester,
  ) async {
    final completer = Completer<WardrobeInspectorData?>();
    addTearDown(() {
      if (!completer.isCompleted) completer.complete(null);
    });
    await pumpWith(tester, [
      wardrobeInspectorProvider(
        wardrobeId,
      ).overrideWith((ref) => completer.future),
    ], const WardrobeInspector(wardrobeId: wardrobeId));

    expect(
      find.descendant(
        of: find.byType(WardrobeInspector),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(WardrobeInspector),
        matching: find.text(wardrobeId),
      ),
      findsNothing,
    );
  });

  testWidgets('wardrobe header surfaces the provider error visibly', (
    tester,
  ) async {
    await pumpWith(tester, [
      wardrobeInspectorProvider(wardrobeId).overrideWith((ref) async {
        throw StateError('wardrobe catalog unavailable');
      }),
    ], const WardrobeInspector(wardrobeId: wardrobeId));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.descendant(
        of: find.byType(WardrobeInspector),
        matching: find.textContaining('wardrobe catalog unavailable'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(WardrobeInspector),
        matching: find.text(wardrobeId),
      ),
      findsNothing,
    );
  });

  testWidgets('missing wardrobe data renders Unknown asset, not the id', (
    tester,
  ) async {
    await pumpWith(tester, [
      wardrobeInspectorProvider(wardrobeId).overrideWith((ref) async => null),
    ], const WardrobeInspector(wardrobeId: wardrobeId));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.descendant(
        of: find.byType(WardrobeInspector),
        matching: find.text('Unknown asset'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(WardrobeInspector),
        matching: find.text(wardrobeId),
      ),
      findsNothing,
    );
  });

  testWidgets('resolved wardrobe data still renders its real name', (
    tester,
  ) async {
    await pumpWith(tester, [
      wardrobeInspectorProvider(
        wardrobeId,
      ).overrideWith((ref) async => wardrobeData),
    ], const WardrobeInspector(wardrobeId: wardrobeId));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.descendant(
        of: find.byType(WardrobeInspector),
        matching: find.text('Coat of Quiet Ash'),
      ),
      findsOneWidget,
    );
  });

  // ---------- WeaponInspector ----------

  testWidgets('weapon header shows a loading indicator, not the raw id', (
    tester,
  ) async {
    final completer = Completer<WeaponInspectorData?>();
    addTearDown(() {
      if (!completer.isCompleted) completer.complete(null);
    });
    await pumpWith(tester, [
      weaponInspectorProvider(weaponId).overrideWith((ref) => completer.future),
    ], const WeaponInspector(weaponId: weaponId));

    expect(
      find.descendant(
        of: find.byType(WeaponInspector),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(WeaponInspector),
        matching: find.text(weaponId),
      ),
      findsNothing,
    );
  });

  testWidgets('weapon header surfaces the provider error visibly', (
    tester,
  ) async {
    await pumpWith(tester, [
      weaponInspectorProvider(weaponId).overrideWith((ref) async {
        throw StateError('weapon catalog unavailable');
      }),
    ], const WeaponInspector(weaponId: weaponId));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.descendant(
        of: find.byType(WeaponInspector),
        matching: find.textContaining('weapon catalog unavailable'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(WeaponInspector),
        matching: find.text(weaponId),
      ),
      findsNothing,
    );
  });

  testWidgets('missing weapon data renders Unknown asset, not the id', (
    tester,
  ) async {
    await pumpWith(tester, [
      weaponInspectorProvider(weaponId).overrideWith((ref) async => null),
    ], const WeaponInspector(weaponId: weaponId));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.descendant(
        of: find.byType(WeaponInspector),
        matching: find.text('Unknown asset'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(WeaponInspector),
        matching: find.text(weaponId),
      ),
      findsNothing,
    );
  });

  testWidgets('resolved weapon data still renders its real name', (
    tester,
  ) async {
    await pumpWith(tester, [
      weaponInspectorProvider(weaponId).overrideWith((ref) async => weaponData),
    ], const WeaponInspector(weaponId: weaponId));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.descendant(
        of: find.byType(WeaponInspector),
        matching: find.text('Pale Verdict'),
      ),
      findsOneWidget,
    );
  });
}
