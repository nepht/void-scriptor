// Sprint 111.3 - Shared Encyclopedia Taxonomy.
//
// Domain-only contract covering controlled categories, free-form tags,
// aliases, localized names, cross-domain links, and taxonomy versioning.
// No persistence, UI, locale, network, wall clock, or random input.

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/shared_encyclopedia_taxonomy.dart';

void main() {
  group('111.3 controlled categories', () {
    test('validated factory rejects empty id or label', () {
      expect(
        () => EncyclopediaCategory.validated(id: '', label: 'Plant'),
        throwsArgumentError,
      );
      expect(
        () => EncyclopediaCategory.validated(id: 'plant', label: ''),
        throwsArgumentError,
      );
    });

    test('normalizes category id to lowercase + trims', () {
      final cat = EncyclopediaCategory.validated(
        id: '  Plant  ',
        label: 'Plant',
      );
      expect(cat.id, 'plant');
      expect(cat.label, 'Plant');
    });
  });

  group('111.3 free tags', () {
    test('normalized to lowercase + trim, rejects empty', () {
      expect(() => EncyclopediaTag.validated('  '), throwsArgumentError);
      expect(EncyclopediaTag.validated('  Rare ').value, 'rare');
    });

    test('two tags with same normalized value compare equal', () {
      final a = EncyclopediaTag.validated('Forest');
      final b = EncyclopediaTag.validated('  forest ');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('111.3 aliases', () {
    test('validated factory rejects empty alias', () {
      expect(
        () => EncyclopediaAlias.validated(alias: '', categoryId: 'plant'),
        throwsArgumentError,
      );
    });

    test('alias trims whitespace, categoryId normalized to lowercase', () {
      final a = EncyclopediaAlias.validated(
        alias: '  Moon Lily ',
        categoryId: '  Plant  ',
      );
      expect(a.alias, 'Moon Lily');
      expect(a.categoryId, 'plant');
    });
  });

  group('111.3 localized names', () {
    test('validated rejects empty locale or displayName', () {
      expect(
        () => LocalizedName.validated(locale: '', displayName: 'Aetherblume'),
        throwsArgumentError,
      );
      expect(
        () => LocalizedName.validated(locale: 'en', displayName: ''),
        throwsArgumentError,
      );
    });

    test('originalScript may be null but not empty', () {
      expect(
        () => LocalizedName.validated(
          locale: 'en',
          displayName: 'Aetherblume',
          originalScript: '',
        ),
        throwsArgumentError,
      );
    });
  });

  group('111.3 cross-domain links', () {
    test('validated rejects same-domain link and empty ids', () {
      expect(
        () => EncyclopediaCrossDomainLink.validated(
          fromCategoryId: 'plant',
          fromEntryId: 'aetherblume',
          toCategoryId: 'plant',
          toEntryId: 'silverroot',
          linkKind: CrossDomainLinkKind.symbiotic,
        ),
        throwsArgumentError,
      );
      expect(
        () => EncyclopediaCrossDomainLink.validated(
          fromCategoryId: '',
          fromEntryId: 'a',
          toCategoryId: 'creature',
          toEntryId: 'b',
          linkKind: CrossDomainLinkKind.symbiotic,
        ),
        throwsArgumentError,
      );
    });
  });

  group('111.3 taxonomy versioning', () {
    test('initial version is 1, bump increments by one', () {
      const v1 = TaxonomyVersion.initial();
      expect(v1.major, 1);
      expect(v1.minor, 0);

      final v2 = v1.bumpMinor();
      expect(v2.major, 1);
      expect(v2.minor, 1);

      final v3 = v2.bumpMajor();
      expect(v3.major, 2);
      expect(v3.minor, 0);
    });

    test('version equality + comparison', () {
      const a = TaxonomyVersion(major: 1, minor: 0);
      const b = TaxonomyVersion(major: 1, minor: 0);
      const c = TaxonomyVersion(major: 1, minor: 1);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a.isAtLeast(c), isFalse);
      expect(c.isAtLeast(a), isTrue);
    });
  });

  group('111.3 registry integrity', () {
    test('addCategory rejects duplicate normalized id', () {
      final reg = EncyclopediaTaxonomy();
      reg.addCategory(
        EncyclopediaCategory.validated(id: 'plant', label: 'Plant'),
      );
      expect(
        () => reg.addCategory(
          EncyclopediaCategory.validated(id: '  Plant ', label: 'X'),
        ),
        throwsStateError,
      );
    });

    test('addAlias rejects alias referencing unknown category', () {
      final reg = EncyclopediaTaxonomy()
        ..addCategory(
          EncyclopediaCategory.validated(id: 'plant', label: 'Plant'),
        );
      expect(
        () => reg.addAlias(
          EncyclopediaAlias.validated(
            alias: 'Moon Lily',
            categoryId: 'mineral',
          ),
        ),
        throwsStateError,
      );
    });

    test('addLink rejects link referencing unknown category or entry', () {
      final reg = EncyclopediaTaxonomy()
        ..addCategory(
          EncyclopediaCategory.validated(id: 'plant', label: 'Plant'),
        )
        ..addEntry(
          EncyclopediaEntry.validated(
            id: 'aetherblume',
            categoryId: 'plant',
            displayName: 'Aetherblume',
          ),
        );
      expect(
        () => reg.addLink(
          EncyclopediaCrossDomainLink.validated(
            fromCategoryId: 'plant',
            fromEntryId: 'aetherblume',
            toCategoryId: 'creature',
            toEntryId: 'moonstag',
            linkKind: CrossDomainLinkKind.symbiotic,
          ),
        ),
        throwsStateError,
      );
    });

    test('currentVersion reflects bumps applied through adds', () {
      final reg = EncyclopediaTaxonomy();
      reg.bumpMinor();
      reg.bumpMinor();
      expect(reg.currentVersion.minor, 2);
      expect(reg.history.length, 3);
    });
  });
}
