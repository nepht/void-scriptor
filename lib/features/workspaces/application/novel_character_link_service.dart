import '../domain/novel_character_link.dart';

class NovelCharacterLinkService {
  final Map<String, NovelCharacterLink> _links = {};
  final Set<String> _knownCharacterSources = {};

  NovelCharacterLink create({
    required String linkId,
    required String novelWorkspaceId,
    required String characterWorkspaceId,
    required String characterId,
    required String role,
    required String visibility,
    LinkMode mode = LinkMode.reference,
  }) {
    if (_links.containsKey(linkId)) {
      throw StateError('Link already exists: $linkId');
    }
    final link = NovelCharacterLink.create(
      linkId: linkId,
      novelWorkspaceId: novelWorkspaceId,
      characterWorkspaceId: characterWorkspaceId,
      characterId: characterId,
      role: role,
      visibility: visibility,
      mode: mode,
    );
    _links[linkId] = link;
    _knownCharacterSources.add(characterId);
    return link;
  }

  List<NovelCharacterLink> listForNovel(String novelWorkspaceId) => _links
      .values
      .where((link) => link.novelWorkspaceId == novelWorkspaceId)
      .toList(growable: false);

  bool unlink(String linkId) => _links.remove(linkId) != null;

  bool characterSourceStillExists(String characterId) =>
      _knownCharacterSources.contains(characterId);
}
