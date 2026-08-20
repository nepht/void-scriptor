class StudioEntity {
  const StudioEntity({required this.id, required this.name});

  final String id;
  final String name;

  StudioEntity copyWith({String? id, String? name}) =>
      StudioEntity(id: id ?? this.id, name: name ?? this.name);

  @override
  bool operator ==(Object other) =>
      other is StudioEntity && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}
