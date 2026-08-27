import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/shared_world_data_schema.dart';

void main() {
  test(
    'schema memisahkan namespace dan mempertahankan stable cross-workspace ref',
    () {
      final schema = SharedWorldDataSchema();
      final ref = schema.register(
        WorldDataRecord(
          id: 'char-1',
          workspace: WorldWorkspace.character,
          owner: DataOwner.characterCanon,
          validFrom: 1,
          validUntil: 9,
          sourceLinks: ['scene-1'],
          version: 2,
          branchId: 'main',
        ),
      );
      expect(ref, 'character:char-1');
      expect(schema.resolve(ref)?.id, 'char-1');
      expect(schema.resolve('novel:char-1'), isNull);
    },
  );

  test('validity, source, version, branch, and ownership are explicit', () {
    final schema = SharedWorldDataSchema();
    expect(
      () => schema.register(
        WorldDataRecord(
          id: 'x',
          workspace: WorldWorkspace.novel,
          owner: DataOwner.characterCanon,
          validFrom: 5,
          validUntil: 4,
          sourceLinks: [],
          version: 1,
          branchId: 'main',
        ),
      ),
      throwsArgumentError,
    );
    final record = WorldDataRecord(
      id: 'state-1',
      workspace: WorldWorkspace.novel,
      owner: DataOwner.novelState,
      validFrom: 0,
      version: 3,
      sourceLinks: ['chapter-1'],
      branchId: 'what-if',
    );
    schema.register(record);
    expect(schema.at('novel:state-1', 10)?.branchId, 'what-if');
    expect(record.sourceLinks, ['chapter-1']);
  });
}
