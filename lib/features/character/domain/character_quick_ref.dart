/// Quick reference kanonik karakter (Step 145.25).
///
/// Kartu ringkas satu-paragraf per karakter pada suatu adegan: fakta
/// profil canon + catatan identitas + konteks keanggotaan scene (role).
/// Murni domain, tanpa DB/UI, sehingga bisa dipakai repository, AI
/// context resolver, dan UI tanpa saling bergantung.
class CharacterQuickRef {
  const CharacterQuickRef({
    required this.characterId,
    required this.name,
    required this.compactDescription,
    required this.role,
    this.alias,
  });

  /// Asset ID karakter (identitas stabil lintas scene).
  final String characterId;
  final String name;
  final String? alias;

  /// Deskripsi ringkas: biography, personality, fakta fisik, lalu notes
  /// identitas. Baris kosong tidak ikut.
  final String compactDescription;

  /// Role karakter di scene ini ('participant' default).
  final String role;

  /// Ringkasan untuk prompt AI (identik dengan compactDescription).
  String get summary => compactDescription;
}
