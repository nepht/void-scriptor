library;

enum WorldWorkspace { character, novel }

enum DataOwner { characterCanon, novelState }

class WorldDataRecord {
  WorldDataRecord({
    required this.id,
    required this.workspace,
    required this.owner,
    required this.validFrom,
    this.validUntil,
    required List<String> sourceLinks,
    required this.version,
    required this.branchId,
  }) : sourceLinks = List.unmodifiable(sourceLinks);

  final String id;
  final WorldWorkspace workspace;
  final DataOwner owner;
  final int validFrom;
  final int? validUntil;
  final List<String> sourceLinks;
  final int version;
  final String branchId;
}

class SharedWorldDataSchema {
  final Map<String, WorldDataRecord> _records = {};

  String register(WorldDataRecord record) {
    if (record.id.isEmpty || record.branchId.isEmpty || record.version < 1) {
      throw ArgumentError('id, branch, and version are required');
    }
    if (record.validFrom < 0 ||
        (record.validUntil != null && record.validUntil! < record.validFrom)) {
      throw ArgumentError('invalid validity range');
    }
    final ref = _reference(record.workspace, record.id);
    if (_records.containsKey(ref)) {
      throw StateError('duplicate reference: $ref');
    }
    _records[ref] = record;
    return ref;
  }

  WorldDataRecord? resolve(String reference) => _records[reference];

  WorldDataRecord? at(String reference, int tick) {
    final record = resolve(reference);
    if (record == null || tick < record.validFrom) return null;
    if (record.validUntil != null && tick > record.validUntil!) return null;
    return record;
  }

  static String _reference(WorldWorkspace workspace, String id) =>
      '${workspace.name}:$id';
}
