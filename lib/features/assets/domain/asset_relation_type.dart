enum AssetRelationType {
  uses,
  wears,
  owns,
  appearsIn,
  locatedIn,
  takesPlaceIn,
  createdBy,
  memberOf,
  enemyOf,
  allyOf,
  relatedTo,
}

extension AssetRelationTypeValue on AssetRelationType {
  String get value => switch (this) {
    AssetRelationType.uses => 'uses',
    AssetRelationType.wears => 'wears',
    AssetRelationType.owns => 'owns',
    AssetRelationType.appearsIn => 'appears_in',
    AssetRelationType.locatedIn => 'located_in',
    AssetRelationType.takesPlaceIn => 'takes_place_in',
    AssetRelationType.createdBy => 'created_by',
    AssetRelationType.memberOf => 'member_of',
    AssetRelationType.enemyOf => 'enemy_of',
    AssetRelationType.allyOf => 'ally_of',
    AssetRelationType.relatedTo => 'related_to',
  };
}
