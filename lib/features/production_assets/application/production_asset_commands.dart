import '../../../core/commands/command_registry.dart';
import '../presentation/production_asset_workspace_screen.dart';

List<PaletteCommand> productionAssetCommands({
  required Future<void> Function(String route) open,
  required Future<void> Function(ProductionAssetKind kind) create,
}) => [
  for (final entry in {
    ProductionAssetKind.creature: '/creatures',
    ProductionAssetKind.vehicle: '/vehicles',
    ProductionAssetKind.prop: '/props',
  }.entries) ...[
    PaletteCommand(
      id: 'open-${entry.key.name}',
      label: 'Open ${_label(entry.key)}',
      keywords: ['open', entry.key.name, 'assets'],
      execute: () => open(entry.value),
    ),
    PaletteCommand(
      id: 'create-${entry.key.name}',
      label: 'Create ${_singular(entry.key)}',
      keywords: ['new', 'create', entry.key.name],
      execute: () => create(entry.key),
    ),
  ],
];

String _label(ProductionAssetKind kind) => switch (kind) {
  ProductionAssetKind.creature => 'Creatures',
  ProductionAssetKind.vehicle => 'Vehicles',
  ProductionAssetKind.prop => 'Props',
};

String _singular(ProductionAssetKind kind) => switch (kind) {
  ProductionAssetKind.creature => 'Creature',
  ProductionAssetKind.vehicle => 'Vehicle',
  ProductionAssetKind.prop => 'Prop',
};
