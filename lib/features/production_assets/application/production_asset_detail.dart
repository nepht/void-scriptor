import '../../creatures/domain/creature_model.dart';
import '../../props/domain/prop_model.dart';
import '../../vehicles/domain/vehicle_model.dart';
import '../presentation/production_asset_workspace_screen.dart';

class DetailSection {
  const DetailSection(this.title, this.rows);

  final String title;
  final List<DetailRow> rows;
}

class DetailRow {
  const DetailRow(this.label, this.value);

  final String label;
  final String value;
}

class ProductionAssetDetail {
  const ProductionAssetDetail({
    required this.title,
    required this.subtitle,
    required this.sections,
  });

  final String title;
  final String subtitle;
  final Map<String, DetailSection> sections;

  String? value(String section, String label) {
    final rows = sections[section]?.rows;
    if (rows == null) return null;
    for (final row in rows) {
      if (row.label == label) return row.value;
    }
    return null;
  }
}

/// Maps production asset domain models into display-ready detail sheets
/// (Steps 22.9, 22.21, 22.47). The workspace delegates here instead of
/// hardcoding names, so a real entity renders its persisted data.
class ProductionAssetDetailResolver {
  const ProductionAssetDetailResolver._();

  static ProductionAssetDetail resolve({
    required ProductionAssetKind kind,
    CreatureModel? creature,
    CreaturePhysicalProfile? profile,
    Iterable<CreatureAbilityModel> abilities = const [],
    Iterable<CreatureModeModel> modes = const [],
    VehicleModel? vehicle,
    VehicleSpecification? specification,
    Iterable<VehicleWeaponMountModel> mounts = const [],
    PropModel? prop,
    PropSpecification? propSpec,
    Iterable<PropStateModel> states = const [],
  }) {
    return switch (kind) {
      ProductionAssetKind.creature => _creature(
        creature,
        profile,
        abilities,
        modes,
      ),
      ProductionAssetKind.vehicle => _vehicle(vehicle, specification, mounts),
      ProductionAssetKind.prop => _prop(prop, propSpec, states),
    };
  }

  static ProductionAssetDetail _creature(
    CreatureModel? creature,
    CreaturePhysicalProfile? profile,
    Iterable<CreatureAbilityModel> abilities,
    Iterable<CreatureModeModel> modes,
  ) {
    final sections = <String, DetailSection>{};
    if (creature != null) {
      sections['Identity'] = DetailSection('Identity', [
        if (creature.description.isNotEmpty)
          DetailRow('Description', creature.description),
        if (creature.behavior.isNotEmpty)
          DetailRow('Behavior', creature.behavior),
        if (creature.origin.isNotEmpty) DetailRow('Origin', creature.origin),
      ]);
    }
    if (profile != null) {
      sections['Physical'] = DetailSection('Physical', [
        if (profile.heightCm != null)
          DetailRow('Height', '${profile.heightCm} cm'),
        if (profile.lengthCm != null)
          DetailRow('Length', '${profile.lengthCm} cm'),
        if (profile.weightKg != null)
          DetailRow('Weight', '${profile.weightKg} kg'),
        if (profile.bodyStructure.isNotEmpty)
          DetailRow('Body structure', profile.bodyStructure),
        if (profile.skinMaterial.isNotEmpty)
          DetailRow('Skin material', profile.skinMaterial),
        if (profile.eyeDescription.isNotEmpty)
          DetailRow('Eyes', profile.eyeDescription),
      ]);
    }
    if (abilities.isNotEmpty) {
      sections['Abilities'] = DetailSection(
        'Abilities',
        abilities
            .map(
              (a) => DetailRow(
                a.name,
                a.description.isEmpty ? '—' : a.description,
              ),
            )
            .toList(),
      );
    }
    if (modes.isNotEmpty) {
      sections['Modes'] = DetailSection(
        'Modes',
        modes
            .map((m) => DetailRow(m.name, m.defaultMode ? 'default' : ''))
            .toList(),
      );
    }
    return ProductionAssetDetail(
      title: creature?.name ?? 'Unnamed Creature',
      subtitle: creature?.category.name ?? 'creature',
      sections: sections,
    );
  }

  static ProductionAssetDetail _vehicle(
    VehicleModel? vehicle,
    VehicleSpecification? specification,
    Iterable<VehicleWeaponMountModel> mounts,
  ) {
    final sections = <String, DetailSection>{};
    if (vehicle != null) {
      sections['Overview'] = DetailSection('Overview', [
        if (vehicle.description.isNotEmpty)
          DetailRow('Description', vehicle.description),
        if (vehicle.manufacturer.isNotEmpty)
          DetailRow('Manufacturer', vehicle.manufacturer),
        if (vehicle.role.isNotEmpty) DetailRow('Role', vehicle.role),
      ]);
    }
    if (specification != null) {
      sections['Specifications'] = DetailSection('Specifications', [
        if (specification.lengthMeters != null)
          DetailRow('Length', '${specification.lengthMeters} m'),
        if (specification.widthMeters != null)
          DetailRow('Width', '${specification.widthMeters} m'),
        if (specification.heightMeters != null)
          DetailRow('Height', '${specification.heightMeters} m'),
        if (specification.crew != null)
          DetailRow('Crew', '${specification.crew}'),
        if (specification.passengers != null)
          DetailRow('Passengers', '${specification.passengers}'),
        if (specification.propulsion.isNotEmpty)
          DetailRow('Propulsion', specification.propulsion),
        if (specification.powerSource.isNotEmpty)
          DetailRow('Power source', specification.powerSource),
        if (specification.maximumSpeed.isNotEmpty)
          DetailRow('Maximum speed', specification.maximumSpeed),
      ]);
    }
    if (mounts.isNotEmpty) {
      sections['Weapons'] = DetailSection(
        'Weapons',
        mounts.map((m) => DetailRow(m.mountName, m.weaponId)).toList(),
      );
    }
    return ProductionAssetDetail(
      title: vehicle?.name ?? 'Unnamed Vehicle',
      subtitle: vehicle?.category.name ?? 'vehicle',
      sections: sections,
    );
  }

  static ProductionAssetDetail _prop(
    PropModel? prop,
    PropSpecification? spec,
    Iterable<PropStateModel> states,
  ) {
    final sections = <String, DetailSection>{};
    if (prop != null) {
      sections['Overview'] = DetailSection('Overview', [
        if (prop.description.isNotEmpty)
          DetailRow('Description', prop.description),
        if (prop.function.isNotEmpty) DetailRow('Function', prop.function),
        if (prop.storyCritical) const DetailRow('Story critical', 'yes'),
      ]);
    }
    if (spec != null) {
      sections['Materials'] = DetailSection('Materials', [
        if (spec.material.isNotEmpty) DetailRow('Material', spec.material),
        if (spec.color.isNotEmpty) DetailRow('Color', spec.color),
        if (spec.widthCm != null) DetailRow('Width', '${spec.widthCm} cm'),
        if (spec.heightCm != null) DetailRow('Height', '${spec.heightCm} cm'),
        if (spec.weightKg != null) DetailRow('Weight', '${spec.weightKg} kg'),
      ]);
    }
    if (states.isNotEmpty) {
      sections['States'] = DetailSection(
        'States',
        states.map((s) => DetailRow(s.name, s.description)).toList(),
      );
    }
    return ProductionAssetDetail(
      title: prop?.name ?? 'Unnamed Prop',
      subtitle: prop?.category.name ?? 'prop',
      sections: sections,
    );
  }
}
