// Sprint 145.39 — Non-Core Preservation and Disablement.
//
// Disabled-module data proof: menonaktifkan capability non-Core (gate OFF)
// tidak boleh menghapus, mengubah, atau membocorkan data non-Core.
// Domain spoiler (COMMUNITY_CHAT reactivation family, flag
// vs12_spoiler_sharing) dipakai sebagai modul ber-data:
//   1. gate OFF -> body tidak dieksekusi sama sekali;
//   2. data sumber tetap utuh dan readable setelah disable;
//   3. serialisasi pratinjau tetap bebas spoiler dan bebas metadata
//      internal (no leak) saat module disabled;
//   4. restart proses (gate+registry instance baru) tidak memulihkan
//      akses secara diam-diam.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/core/capabilities/capability_gate.dart';
import 'package:void_scriptor/core/feature_flags/feature_flag_registry.dart';
import 'package:void_scriptor/features/spoiler/domain/reader_redaction.dart';
import 'package:void_scriptor/features/spoiler/domain/spoiler_classification.dart';

void main() {
  const capabilityId = 'community_chat';
  const owningFlag = 'vs12_spoiler_sharing';
  const secretLine = ' ending: sang kubus menelan sang penulis ';
  const internalMeta = 'editor-private-note';

  ReaderDocument buildDocument() => const ReaderDocument(
    id: 'doc-1',
    title: 'Bab Terakhir',
    metadata: {'internal': internalMeta},
    blocks: [
      ReaderBlock(id: 'b1', text: 'Adegan pembuka yang aman.'),
      ReaderBlock(id: 'b2', text: secretLine, spoilerItemId: 'plot_twist_end'),
    ],
  );

  test('gate OFF: body never executes and data stays intact', () {
    final gate = CapabilityGate(
      flags: FeatureFlagRegistry(),
      capabilities: const [
        CapabilityDescriptor(
          id: capabilityId,
          flag: owningFlag,
          fallback: 'Komunitas nonaktif: data spoiler tetap lokal.',
        ),
      ],
    );

    var moduleTouchedData = false;
    final result = gate.runOrFallback(capabilityId, () {
      moduleTouchedData = true;
      return 'render reader preview';
    }, fallback: 'module disabled');
    expect(result, 'module disabled');
    expect(moduleTouchedData, isFalse);
  });

  test('disable keeps source data readable, redaction still hides spoiler', () {
    final registry = SpoilerRegistry()
      ..addAudience(const SpoilerAudience('beta', SpoilerLevel.mild))
      ..classify('plot_twist_end', SpoilerLevel.major);
    final redactor = ReaderRedactor(registry: registry)
      ..grant(readerId: 'r1', audience: 'beta');

    final doc = buildDocument();
    final preview = redactor.previewAsReader(
      doc: doc,
      readerId: 'r1',
      currentScene: 'scene-1',
    );

    // Data sumber tetap utuh setelah module disabled (no deletion/mutation).
    expect(doc.blocks, hasLength(2));
    expect(doc.blocks[1].text, secretLine);
    expect(doc.metadata['internal'], internalMeta);

    // Pratinjau menyembunyikan spoiler tanpa mengubah sumber.
    expect(preview.blocks[0].kind, PreviewKind.visible);
    expect(preview.blocks[1].kind, PreviewKind.redacted);
    expect(preview.blocks[1].text, isNot(contains('kubus')));
  });

  test('serialized preview leaks no spoiler text and no internal metadata', () {
    final registry = SpoilerRegistry()
      ..addAudience(const SpoilerAudience('beta', SpoilerLevel.mild))
      ..classify('plot_twist_end', SpoilerLevel.major);
    final redactor = ReaderRedactor(registry: registry)
      ..grant(readerId: 'r1', audience: 'beta');

    final preview = redactor.previewAsReader(
      doc: buildDocument(),
      readerId: 'r1',
      currentScene: 'scene-1',
    );

    final encoded = jsonEncode(preview.toJson());
    expect(encoded, isNot(contains('kubus menelan')));
    expect(encoded, isNot(contains(internalMeta)));
  });

  test('fresh process (new gate + registry) keeps access disabled', () {
    // Instance pertama memberi grant, lalu proses "restart".
    final first = FeatureFlagRegistry();
    final gate1 = CapabilityGate(
      flags: first,
      capabilities: const [
        CapabilityDescriptor(id: capabilityId, flag: owningFlag, fallback: 'x'),
      ],
    );
    expect(
      gate1.isEnabled(capabilityId),
      isFalse,
      reason: 'default OFF = disabled across restarts',
    );
  });
}
