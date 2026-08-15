/// Chunking helpers for large imports (Step 26.59).
///
/// A single giant transaction for 100,000 files is also harmful; chunk records
/// into bounded slices (250-1000 records depending on data) so each chunk is
/// one reasonable transaction with progress reporting.
library;

const int defaultImportChunkSize = 500;

List<List<T>> chunkRecords<T>(
  List<T> records, {
  int chunkSize = defaultImportChunkSize,
}) {
  if (records.isEmpty) return const [];
  final size = chunkSize <= 0 ? defaultImportChunkSize : chunkSize;
  final chunks = <List<T>>[];
  for (var i = 0; i < records.length; i += size) {
    final end = (i + size).clamp(0, records.length);
    chunks.add(records.sublist(i, end));
  }
  return chunks;
}

/// Progressive import progress in [0, 1] (Step 26.59 job progress).
double importProgress({
  required int completedChunks,
  required int totalChunks,
}) {
  if (totalChunks <= 0) return 1;
  return (completedChunks / totalChunks).clamp(0.0, 1.0);
}
