import '../domain/character_model.dart';

/// Applies one extracted trait value to a fresh [CharacterModel] copy.
///
/// Field names come from the strict extractor whitelist, so unknown names
/// throw rather than silently dropping a user-ticked proposal.
CharacterModel applyTraitToModel(
  CharacterModel model,
  String field,
  String value,
) {
  switch (field) {
    case 'gender':
      return model.copyWith(gender: value);
    case 'age':
      final parsed = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
      return model.copyWith(age: parsed);
    case 'heightCm':
      final parsed = double.tryParse(
        value.replaceAll(RegExp(r'[^0-9.,]'), '').replaceAll(',', '.'),
      );
      return model.copyWith(heightCm: parsed);
    case 'hair':
      return model.copyWith(hair: value);
    case 'eyes':
      return model.copyWith(eyes: value);
    case 'skin':
      return model.copyWith(skin: value);
    case 'voice':
      return model.copyWith(voice: value);
    case 'personality':
      return model.copyWith(personality: value);
    default:
      throw StateError('Unknown trait field "$field".');
  }
}
