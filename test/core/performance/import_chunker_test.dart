import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/performance/import_chunker.dart';

void main() {
  test('chunks a large list into bounded slices', () {
    final items = List.generate(1000, (i) => i);
    final chunks = chunkRecords(items, chunkSize: 250);

    expect(chunks, hasLength(4));
    expect(chunks.first, hasLength(250));
    expect(chunks.last, hasLength(250));
    expect(chunks.expand((c) => c).toList(), items);
  });

  test('chunkSize 0 falls back to a sane default', () {
    final items = List.generate(100, (i) => i);
    final chunks = chunkRecords(items, chunkSize: 0);
    expect(chunks, hasLength(1));
    expect(chunks.first, items);
  });

  test('empty input produces no chunks', () {
    expect(chunkRecords(<int>[]), isEmpty);
  });

  test('reports progressive percentages matching chunk boundaries', () {
    final items = List.generate(500, (i) => i);
    final chunks = chunkRecords(items, chunkSize: 100);
    expect(chunks, hasLength(5));

    for (var i = 0; i < chunks.length; i++) {
      final progress = importProgress(
        completedChunks: i,
        totalChunks: chunks.length,
      );
      expect(progress, (i / chunks.length).clamp(0.0, 1.0));
    }
  });
}
