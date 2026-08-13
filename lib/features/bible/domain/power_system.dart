class PowerSystemModel {
  const PowerSystemModel({
    required this.assetId,
    required this.projectId,
    required this.name,
    this.description = '',
    this.source = '',
    this.rules = '',
    this.limitations = '',
    this.visualLanguage = '',
  });

  final String assetId;
  final String projectId;
  final String name;
  final String description;
  final String source;
  final String rules;
  final String limitations;
  final String visualLanguage;
}

class PowerAbilityModel {
  const PowerAbilityModel({
    required this.id,
    required this.powerSystemId,
    required this.name,
    this.description = '',
    this.limitations = '',
    this.sortOrder = 0,
  });

  final String id;
  final String powerSystemId;
  final String name;
  final String description;
  final String limitations;
  final int sortOrder;
}
