// Sprint 113.17 — Beta Reader & Spoiler Validation.
//
// Required evidence: audience_results, redaction_results, share_results,
// revocation_results, leakage_results, acceptance.
//
// Validates that:
// 1. Audience policies and spoiler levels work correctly
// 2. Redaction replaces spoiler blocks with placeholders
// 3. Export service produces spoiler-safe output
// 4. Revocation blocks access
// 5. No spoiler or metadata leakage in output

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/spoiler/domain/spoiler_classification.dart'
    as sc;
import 'package:void_scriptor/features/spoiler/domain/reader_redaction.dart';
import 'package:void_scriptor/features/world_logic/domain/spoiler_safe_manuscript_knowledge_export.dart';
import 'package:void_scriptor/features/world_logic/domain/beta_reader_spoiler_validation.dart';

void main() {
  group('manifest_validation', () {
    test('domain class validates the manifest structure', () {
      final result = BetaReaderSpoilerValidation.validate();
      expect(result.isValid, isTrue, reason: result.errors.join('; '));
      expect(result.errors, isEmpty);
    });

    test('manifest has all required evidence sections', () {
      final result = BetaReaderSpoilerValidation.validate();
      expect(result.isValid, isTrue, reason: result.errors.join('; '));
    });
  });

  group('audience_results', () {
    sc.SpoilerRegistry makeRegistry() {
      final registry = sc.SpoilerRegistry();
      registry.addAudience(
        const sc.SpoilerAudience('beta_basic', sc.SpoilerLevel.mild),
      );
      registry.addAudience(
        const sc.SpoilerAudience('beta_full', sc.SpoilerLevel.major),
      );
      registry.classify('lore_character_a', sc.SpoilerLevel.clean);
      registry.classify('lore_twist_ending', sc.SpoilerLevel.major);
      registry.createGroup('faction_group', sc.SpoilerLevel.mild);
      registry.assignToGroup('faction_member', 'faction_group');
      return registry;
    }

    test('audience registration works', () {
      final registry = makeRegistry();
      expect(registry.hasAudience('beta_basic'), isTrue);
      expect(registry.hasAudience('nonexistent'), isFalse);
    });

    test('effective level resolves: explicit > group > default', () {
      final registry = makeRegistry();
      // Explicit classification
      expect(
        registry.effectiveLevel('lore_character_a'),
        sc.SpoilerLevel.clean,
      );
      // Group inheritance
      expect(registry.effectiveLevel('faction_member'), sc.SpoilerLevel.mild);
      // Default: major
      expect(registry.effectiveLevel('unknown_item'), sc.SpoilerLevel.major);
    });

    test('visibility respects audience level and reveal points', () {
      final registry = makeRegistry();
      registry.setRevealPoint('lore_twist_ending', 'scene_10');

      // beta_basic (max=mild) cannot see major items
      expect(
        registry.isVisible(
          itemId: 'lore_twist_ending',
          audience: 'beta_basic',
          currentScene: 'scene_10',
        ),
        isFalse,
      );
      // beta_full (max=major) can see major items
      expect(
        registry.isVisible(
          itemId: 'lore_twist_ending',
          audience: 'beta_full',
          currentScene: 'scene_10',
        ),
        isTrue,
      );
      // Before reveal point, even beta_full cannot see
      registry.setRevealPoint('secret_ending', 'scene_20');
      expect(
        registry.isVisible(
          itemId: 'secret_ending',
          audience: 'beta_full',
          currentScene: 'scene_05',
        ),
        isFalse,
      );
    });

    test('safe default: unclassified items are major', () {
      final registry = sc.SpoilerRegistry();
      registry.addAudience(
        const sc.SpoilerAudience('reader', sc.SpoilerLevel.mild),
      );
      // No classification → default major → not visible for mild reader
      expect(
        registry.isVisible(
          itemId: 'unclassified',
          audience: 'reader',
          currentScene: 'scene_1',
        ),
        isFalse,
      );
    });
  });

  group('redaction_results', () {
    test('preview_as_reader shows visible blocks', () {
      final registry = sc.SpoilerRegistry();
      registry.addAudience(
        const sc.SpoilerAudience('beta', sc.SpoilerLevel.mild),
      );
      registry.classify('safe_item', sc.SpoilerLevel.clean);

      final redactor = ReaderRedactor(registry: registry);
      redactor.grant(readerId: 'reader1', audience: 'beta');

      const doc = ReaderDocument(
        id: 'doc1',
        title: 'Test Document',
        blocks: [
          ReaderBlock(
            id: 'b1',
            text: 'This is safe text.',
            spoilerItemId: 'safe_item',
          ),
        ],
      );
      final preview = redactor.previewAsReader(
        doc: doc,
        readerId: 'reader1',
        currentScene: 'scene_1',
      );
      expect(preview.blocks, hasLength(1));
      expect(preview.blocks.first.kind, PreviewKind.visible);
      expect(preview.blocks.first.text, 'This is safe text.');
    });

    test('preview_as_reader redacts spoiler blocks', () {
      final registry = sc.SpoilerRegistry();
      registry.addAudience(
        const sc.SpoilerAudience('beta', sc.SpoilerLevel.mild),
      );
      registry.classify('major_spoiler', sc.SpoilerLevel.major);

      final redactor = ReaderRedactor(registry: registry);
      redactor.grant(readerId: 'reader1', audience: 'beta');

      const doc = ReaderDocument(
        id: 'doc1',
        title: 'Test',
        blocks: [
          ReaderBlock(
            id: 'b1',
            text: 'Spoiler text here',
            spoilerItemId: 'major_spoiler',
          ),
        ],
      );
      final preview = redactor.previewAsReader(
        doc: doc,
        readerId: 'reader1',
        currentScene: 'scene_1',
      );
      expect(preview.blocks.first.kind, PreviewKind.redacted);
      expect(preview.blocks.first.text, '[disensor]');
    });

    test('hidden links are removed from redacted blocks', () {
      final registry = sc.SpoilerRegistry();
      registry.addAudience(
        const sc.SpoilerAudience('beta', sc.SpoilerLevel.mild),
      );
      registry.classify('secret_link', sc.SpoilerLevel.major);

      final redactor = ReaderRedactor(registry: registry);
      redactor.grant(readerId: 'reader1', audience: 'beta');

      const doc = ReaderDocument(
        id: 'doc1',
        title: 'Test',
        blocks: [
          ReaderBlock(
            id: 'b1',
            text: 'Text with link',
            links: [
              InternalLink(label: 'Secret Link', targetItemId: 'secret_link'),
            ],
          ),
        ],
      );
      final preview = redactor.previewAsReader(
        doc: doc,
        readerId: 'reader1',
        currentScene: 'scene_1',
      );
      // The block is visible (no spoilerItemId), but the link is hidden
      expect(preview.blocks.first.links, isEmpty);
    });
  });

  group('share_results', () {
    test('export preflight validates request', () {
      final registry = sc.SpoilerRegistry();
      registry.addAudience(
        const sc.SpoilerAudience('beta', sc.SpoilerLevel.mild),
      );
      final redactor = ReaderRedactor(registry: registry);
      final service = SpoilerSafeExportService(redactor: redactor);
      redactor.grant(readerId: 'reader1', audience: 'beta');

      const request = SpoilerSafeExportRequest(
        documentId: 'doc1',
        title: 'Test',
        readerId: 'reader1',
        currentScene: 'scene_1',
        format: ExportFormat.plainText,
        sections: [ExportSection(id: 's1', title: 'Intro', text: 'Hello')],
      );
      final report = service.preflight(request);
      expect(report.isReady, isTrue);
    });

    test('export preflight catches empty document id', () {
      final registry = sc.SpoilerRegistry();
      registry.addAudience(
        const sc.SpoilerAudience('beta', sc.SpoilerLevel.mild),
      );
      final redactor = ReaderRedactor(registry: registry);
      final service = SpoilerSafeExportService(redactor: redactor);

      const request = SpoilerSafeExportRequest(
        documentId: '',
        title: 'Test',
        readerId: 'r1',
        currentScene: 'scene_1',
        format: ExportFormat.plainText,
        sections: [],
      );
      final report = service.preflight(request);
      expect(report.isReady, isFalse);
      expect(report.issues, isNotEmpty);
    });
  });

  group('revocation_results', () {
    test('revoke removes access', () {
      final registry = sc.SpoilerRegistry();
      registry.addAudience(
        const sc.SpoilerAudience('beta', sc.SpoilerLevel.mild),
      );
      final redactor = ReaderRedactor(registry: registry);
      redactor.grant(readerId: 'r1', audience: 'beta');
      expect(redactor.hasAccess('r1'), isTrue);

      redactor.revoke('r1');
      expect(redactor.hasAccess('r1'), isFalse);
    });

    test('preview after revoke throws', () {
      final registry = sc.SpoilerRegistry();
      registry.addAudience(
        const sc.SpoilerAudience('beta', sc.SpoilerLevel.mild),
      );
      final redactor = ReaderRedactor(registry: registry);
      redactor.grant(readerId: 'r1', audience: 'beta');
      redactor.revoke('r1');

      const doc = ReaderDocument(
        id: 'd1',
        title: 'Test',
        blocks: [ReaderBlock(id: 'b1', text: 'Hello')],
      );
      expect(
        () => redactor.previewAsReader(
          doc: doc,
          readerId: 'r1',
          currentScene: 's1',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('grant after revoke restores access', () {
      final registry = sc.SpoilerRegistry();
      registry.addAudience(
        const sc.SpoilerAudience('beta', sc.SpoilerLevel.mild),
      );
      final redactor = ReaderRedactor(registry: registry);
      redactor.grant(readerId: 'r1', audience: 'beta');
      redactor.revoke('r1');
      redactor.grant(readerId: 'r1', audience: 'beta');
      expect(redactor.hasAccess('r1'), isTrue);
    });
  });

  group('leakage_results', () {
    test('no spoiler text in redacted blocks', () {
      final registry = sc.SpoilerRegistry();
      registry.addAudience(
        const sc.SpoilerAudience('reader', sc.SpoilerLevel.clean),
      );
      registry.classify('death_spoiler', sc.SpoilerLevel.major);

      final redactor = ReaderRedactor(registry: registry);
      redactor.grant(readerId: 'r1', audience: 'reader');

      const doc = ReaderDocument(
        id: 'd1',
        title: 'The Story',
        blocks: [
          ReaderBlock(
            id: 'b1',
            text: 'The hero dies in chapter 5.',
            spoilerItemId: 'death_spoiler',
          ),
        ],
      );
      final preview = redactor.previewAsReader(
        doc: doc,
        readerId: 'r1',
        currentScene: 'chapter_1',
      );
      expect(preview.blocks.first.text, isNot(contains('dies')));
      expect(preview.blocks.first.text, '[disensor]');
    });

    test('no internal links in redacted output', () {
      final registry = sc.SpoilerRegistry();
      registry.addAudience(
        const sc.SpoilerAudience('reader', sc.SpoilerLevel.clean),
      );
      registry.classify('secret_target', sc.SpoilerLevel.major);

      final redactor = ReaderRedactor(registry: registry);
      redactor.grant(readerId: 'r1', audience: 'reader');

      const doc = ReaderDocument(
        id: 'd1',
        title: 'Test',
        blocks: [
          ReaderBlock(
            id: 'b1',
            text: 'Some text',
            links: [
              InternalLink(label: 'Secret', targetItemId: 'secret_target'),
            ],
          ),
        ],
      );
      final preview = redactor.previewAsReader(
        doc: doc,
        readerId: 'r1',
        currentScene: 'ch1',
      );
      expect(preview.blocks.first.links, isEmpty);
    });

    test('metadata never appears in serialized preview', () {
      final registry = sc.SpoilerRegistry();
      registry.addAudience(
        const sc.SpoilerAudience('beta', sc.SpoilerLevel.mild),
      );
      final redactor = ReaderRedactor(registry: registry);
      redactor.grant(readerId: 'r1', audience: 'beta');

      const doc = ReaderDocument(
        id: 'd1',
        title: 'Test',
        blocks: [ReaderBlock(id: 'b1', text: 'Content')],
        metadata: {'internal_note': 'secret stuff', 'editor': 'Choirudin'},
      );
      final preview = redactor.previewAsReader(
        doc: doc,
        readerId: 'r1',
        currentScene: 'ch1',
      );
      final json = preview.toJson().toString();
      expect(json, isNot(contains('internal_note')));
      expect(json, isNot(contains('secret stuff')));
    });

    test('reveal point before scene stays hidden', () {
      final registry = sc.SpoilerRegistry();
      registry.addAudience(
        const sc.SpoilerAudience('beta', sc.SpoilerLevel.major),
      );
      registry.classify('big_reveal', sc.SpoilerLevel.major);
      registry.setRevealPoint('big_reveal', 'chapter_10');

      final redactor = ReaderRedactor(registry: registry);
      redactor.grant(readerId: 'r1', audience: 'beta');

      const doc = ReaderDocument(
        id: 'd1',
        title: 'Test',
        blocks: [
          ReaderBlock(
            id: 'b1',
            text: 'The truth is revealed.',
            spoilerItemId: 'big_reveal',
          ),
        ],
      );
      final preview = redactor.previewAsReader(
        doc: doc,
        readerId: 'r1',
        currentScene: 'chapter_05',
      );
      expect(preview.blocks.first.kind, PreviewKind.redacted);
    });
  });

  group('acceptance', () {
    test('audience_policy_enforced', () {
      final registry = sc.SpoilerRegistry();
      registry.addAudience(
        const sc.SpoilerAudience('basic', sc.SpoilerLevel.clean),
      );
      registry.addAudience(
        const sc.SpoilerAudience('full', sc.SpoilerLevel.major),
      );
      registry.classify('item', sc.SpoilerLevel.mild);
      expect(
        registry.isVisible(
          itemId: 'item',
          audience: 'basic',
          currentScene: 's1',
        ),
        isFalse,
      );
      expect(
        registry.isVisible(
          itemId: 'item',
          audience: 'full',
          currentScene: 's1',
        ),
        isTrue,
      );
    });

    test('redaction_works', () {
      final registry = sc.SpoilerRegistry();
      registry.addAudience(
        const sc.SpoilerAudience('beta', sc.SpoilerLevel.clean),
      );
      registry.classify('spoiler', sc.SpoilerLevel.mild);
      final redactor = ReaderRedactor(registry: registry);
      redactor.grant(readerId: 'r1', audience: 'beta');
      const doc = ReaderDocument(
        id: 'd1',
        title: 'T',
        blocks: [
          ReaderBlock(id: 'b1', text: 'Secret', spoilerItemId: 'spoiler'),
        ],
      );
      final preview = redactor.previewAsReader(
        doc: doc,
        readerId: 'r1',
        currentScene: 's1',
      );
      expect(preview.blocks.first.kind, PreviewKind.redacted);
    });

    test('share_safe', () {
      final registry = sc.SpoilerRegistry();
      registry.addAudience(
        const sc.SpoilerAudience('beta', sc.SpoilerLevel.mild),
      );
      final redactor = ReaderRedactor(registry: registry);
      redactor.grant(readerId: 'r1', audience: 'beta');
      final service = SpoilerSafeExportService(redactor: redactor);
      final report = service.preflight(
        const SpoilerSafeExportRequest(
          documentId: 'd1',
          title: 'T',
          readerId: 'r1',
          currentScene: 's1',
          format: ExportFormat.plainText,
          sections: [ExportSection(id: 's1', title: 'Ch1', text: 'Hello')],
        ),
      );
      expect(report.isReady, isTrue);
    });

    test('revocation_enforced', () {
      final registry = sc.SpoilerRegistry();
      registry.addAudience(
        const sc.SpoilerAudience('beta', sc.SpoilerLevel.mild),
      );
      final redactor = ReaderRedactor(registry: registry);
      redactor.grant(readerId: 'r1', audience: 'beta');
      redactor.revoke('r1');
      expect(redactor.hasAccess('r1'), isFalse);
    });

    test('no_leakage', () {
      final registry = sc.SpoilerRegistry();
      registry.addAudience(
        const sc.SpoilerAudience('reader', sc.SpoilerLevel.clean),
      );
      registry.classify('secret', sc.SpoilerLevel.major);
      final redactor = ReaderRedactor(registry: registry);
      redactor.grant(readerId: 'r1', audience: 'reader');
      const doc = ReaderDocument(
        id: 'd1',
        title: 'Story',
        blocks: [
          ReaderBlock(
            id: 'b1',
            text: 'Hero dies.',
            spoilerItemId: 'secret',
            links: [InternalLink(label: 'Details', targetItemId: 'secret')],
          ),
        ],
        metadata: {'note': 'internal'},
      );
      final preview = redactor.previewAsReader(
        doc: doc,
        readerId: 'r1',
        currentScene: 'ch1',
      );
      final json = preview.toJson().toString();
      expect(json, isNot(contains('Hero dies')));
      expect(json, isNot(contains('Details')));
      expect(json, isNot(contains('internal')));
    });
  });
}
