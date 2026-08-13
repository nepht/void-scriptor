import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/routing/app_router.dart';
import 'package:void_scriptor/app/routing/app_routes.dart';
import 'package:void_scriptor/features/assets/domain/asset_search_query.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';

void main() {
  testWidgets('production asset routes open collection and detail workspaces', (
    tester,
  ) async {
    for (final route in [
      AppRoutes.creatures,
      '${AppRoutes.vehicles}/neo',
      AppRoutes.props,
    ]) {
      final router = createAppRouter(initialLocation: route);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      expect(
        find.text(
          route.startsWith(AppRoutes.creatures)
              ? 'CREATURES'
              : route.startsWith(AppRoutes.vehicles)
              ? 'VEHICLES'
              : 'PROPS',
        ),
        findsOneWidget,
      );
      router.dispose();
    }
  });

  test('asset query parser supports production asset filters', () {
    const parser = SearchQueryParser();
    expect(parser.parse('type:creature byte').types, {AssetType.creature});
    expect(parser.parse('type:vehicle').types, {AssetType.vehicle});
    expect(parser.parse('type:prop tag:story-critical').types, {
      AssetType.prop,
    });
    expect(parser.parse('type:prop tag:story-critical').tags, {
      'story-critical',
    });
  });
}
