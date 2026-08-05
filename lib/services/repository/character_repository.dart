// Character Repository — v1.0.0
// JSON-based persistence with upsertEvent/upsertCharacter/upsertChapter support.

import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import '../../models/character/character.dart';

class CharacterRepository {
  final Directory _dataDir;
  static const String _charactersFile = 'characters.json';

  CharacterRepository(Directory dataDir) : _dataDir = dataDir;

  Future<List<Character>> getAll() async {
    final file = File(p.join(_dataDir.path, _charactersFile));
    if (!await file.exists()) return [];
    final raw = jsonDecode(await file.readAsString()) as List;
    return raw.map((e) => Character.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Character> getById(String id) async {
    final all = await getAll();
    return all.firstWhere((c) => c.id == id);
  }

  Future<void> upsertCharacter(Character character) async {
    final all = await getAll();
    final index = all.indexWhere((c) => c.id == character.id);
    if (index >= 0) {
      all[index] = character;
    } else {
      all.add(character);
    }
    await _saveAll(all);
  }

  Future<void> deleteCharacter(String id) async {
    final all = await getAll();
    all.removeWhere((c) => c.id == id);
    await _saveAll(all);
  }

  Future<void> _saveAll(List<Character> characters) async {
    final file = File(p.join(_dataDir.path, _charactersFile));
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode(characters.map((c) => c.toJson()).toList()),
    );
  }
}
