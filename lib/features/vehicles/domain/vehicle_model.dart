enum VehicleCategory {
  ground,
  motorcycle,
  car,
  truck,
  aircraft,
  spacecraft,
  watercraft,
  mech,
  hover,
  portalTransport,
  other,
}

class VehicleModel {
  const VehicleModel({
    required this.assetId,
    required this.projectId,
    required this.name,
    required this.category,
    this.description = '',
    this.manufacturer = '',
    this.role = '',
  });
  final String assetId, projectId, name, description, manufacturer, role;
  final VehicleCategory category;
}

class VehicleSpecification {
  const VehicleSpecification({
    required this.vehicleId,
    this.lengthMeters,
    this.widthMeters,
    this.heightMeters,
    this.crew,
    this.passengers,
    this.propulsion = '',
    this.powerSource = '',
    this.maximumSpeed = '',
  });
  final String vehicleId, propulsion, powerSource, maximumSpeed;
  final double? lengthMeters, widthMeters, heightMeters;
  final int? crew, passengers;
}

class VehicleComponentModel {
  const VehicleComponentModel({
    required this.id,
    required this.vehicleId,
    required this.name,
    this.category = '',
    this.description = '',
    this.sortOrder = 0,
  });
  final String id, vehicleId, name, category, description;
  final int sortOrder;
}

class VehicleWeaponMountModel {
  const VehicleWeaponMountModel({
    required this.id,
    required this.vehicleId,
    required this.weaponId,
    required this.mountName,
    this.quantity = 1,
  });
  final String id, vehicleId, weaponId, mountName;
  final int quantity;
}

class VehicleVariantModel {
  const VehicleVariantModel({
    required this.id,
    required this.vehicleId,
    required this.name,
    this.description = '',
    this.referenceSetId,
  });
  final String id, vehicleId, name, description;
  final String? referenceSetId;
}
