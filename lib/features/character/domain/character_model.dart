class CharacterModel {
  const CharacterModel({
    required this.assetId,
    required this.projectId,
    required this.displayName,
    this.alias = '',
    this.biography = '',
    this.personality = '',
    this.gender = '',
    this.age,
    this.heightCm,
    this.hair = '',
    this.eyes = '',
    this.skin = '',
  });

  final String assetId;
  final String projectId;
  final String displayName;
  final String alias;
  final String biography;
  final String personality;
  final String gender;
  final int? age;
  final double? heightCm;
  final String hair;
  final String eyes;
  final String skin;

  CharacterModel copyWith({
    String? displayName,
    String? alias,
    String? biography,
    String? personality,
    String? gender,
    int? age,
    double? heightCm,
    String? hair,
    String? eyes,
    String? skin,
  }) => CharacterModel(
    assetId: assetId,
    projectId: projectId,
    displayName: displayName ?? this.displayName,
    alias: alias ?? this.alias,
    biography: biography ?? this.biography,
    personality: personality ?? this.personality,
    gender: gender ?? this.gender,
    age: age ?? this.age,
    heightCm: heightCm ?? this.heightCm,
    hair: hair ?? this.hair,
    eyes: eyes ?? this.eyes,
    skin: skin ?? this.skin,
  );

  CharacterModel copyWithName(String name) => copyWith(displayName: name);
}
