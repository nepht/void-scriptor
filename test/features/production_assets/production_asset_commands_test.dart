import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/production_assets/application/production_asset_commands.dart';
import 'package:void_scriptor/features/production_assets/presentation/production_asset_workspace_screen.dart';

void main() {
  test(
    'production command catalog opens and creates all asset families',
    () async {
      String? route;
      ProductionAssetKind? created;
      final commands = productionAssetCommands(
        open: (value) async => route = value,
        create: (kind) async => created = kind,
      );
      expect(
        commands.map((command) => command.label),
        containsAll([
          'Open Creatures',
          'Create Creature',
          'Open Vehicles',
          'Create Vehicle',
          'Open Props',
          'Create Prop',
        ]),
      );
      await commands
          .singleWhere((command) => command.id == 'open-creature')
          .execute();
      expect(route, '/creatures');
      await commands
          .singleWhere((command) => command.id == 'create-prop')
          .execute();
      expect(created, ProductionAssetKind.prop);
    },
  );
}
