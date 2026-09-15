// Sprint 111.30 - Cultural Name Profiles (domain-only).
//
// Acceptance canonical dipetakan:
// - culture             -> CulturalNameProfile.cultureId (trim, non-empty)
// - language            -> CulturalNameProfile.languageId (rujuk konlang 109.17)
// - era                 -> NameEra (marker cerita + sequence opsional, konvensi 111.26/111.27)
// - social_context      -> SocialContext enum + defaultContext profil
// - titles              -> NameTitle (posisi pre/post, per tipe entitas + konteks)
// - entity_types        -> NameEntityType enum + whitelist profil, subset guard
// - prefix_suffix_rules -> NameAffixRule (prefix/suffix, decorate deterministik)
//
// Domain murni: tanpa persistence, UI, locale, jaringan, wall-clock, random.
// D-SCHEMA-01 tetap OPEN.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_name_profiles.dart';

NameEra era(
  String id, {
  String label = 'Age of Ash',
  String fromMarker = 'age-ash-start',
  String? toMarker,
  int? sequence,
}) => NameEra.validated(
  eraId: id,
  label: label,
  fromMarker: fromMarker,
  toMarker: toMarker,
  sequence: sequence,
);

NameTitle title(
  String id, {
  String text = 'Lady',
  TitlePosition position = TitlePosition.preName,
  Set<NameEntityType> entityTypes = const {NameEntityType.person},
  Set<SocialContext> contexts = const {SocialContext.formal},
}) => NameTitle.validated(
  id: id,
  text: text,
  position: position,
  entityTypes: entityTypes,
  contexts: contexts,
);

NameAffixRule affix(
  String id, {
  NameAffixKind kind = NameAffixKind.prefix,
  String text = 'ne',
  Set<NameEntityType> entityTypes = const {NameEntityType.place},
  Set<SocialContext> contexts = const {SocialContext.everyday},
  bool optional = false,
}) => NameAffixRule.validated(
  id: id,
  kind: kind,
  text: text,
  entityTypes: entityTypes,
  contexts: contexts,
  optional: optional,
);

CulturalNameProfile profile({
  String profileId = 'profile-north',
  String cultureId = 'northfolk',
  String languageId = 'lang-north',
  NameEra? eraSection,
  Set<NameEntityType> entityTypes = const {
    NameEntityType.person,
    NameEntityType.place,
  },
  SocialContext defaultContext = SocialContext.everyday,
  List<NameTitle> titles = const [],
  List<NameAffixRule> affixRules = const [],
}) => CulturalNameProfile.validated(
  profileId: profileId,
  cultureId: cultureId,
  languageId: languageId,
  era: eraSection,
  entityTypes: entityTypes,
  defaultContext: defaultContext,
  titles: titles,
  affixRules: affixRules,
);

void main() {
  group('NameEntityType (entity_types)', () {
    test('canonical enum members exist', () {
      expect(NameEntityType.values, contains(NameEntityType.person));
      expect(NameEntityType.values, contains(NameEntityType.place));
      expect(NameEntityType.values, contains(NameEntityType.family));
      expect(NameEntityType.values, contains(NameEntityType.deity));
      expect(NameEntityType.values, contains(NameEntityType.creature));
      expect(NameEntityType.values, contains(NameEntityType.artifact));
      expect(NameEntityType.values, contains(NameEntityType.organization));
    });
  });

  group('SocialContext (social_context)', () {
    test('canonical enum members exist', () {
      expect(SocialContext.values, contains(SocialContext.everyday));
      expect(SocialContext.values, contains(SocialContext.formal));
      expect(SocialContext.values, contains(SocialContext.ceremonial));
      expect(SocialContext.values, contains(SocialContext.sacred));
      expect(SocialContext.values, contains(SocialContext.secret));
    });
  });

  group('NameEra (era)', () {
    test('trims ids and markers', () {
      final e = NameEra.validated(
        eraId: ' e1 ',
        label: '  Age ',
        fromMarker: ' from ',
        toMarker: ' to ',
      );
      expect(e.eraId, 'e1');
      expect(e.label, 'Age');
      expect(e.fromMarker, 'from');
      expect(e.toMarker, 'to');
    });

    test('rejects empty eraId, label, and fromMarker', () {
      expect(
        () => NameEra.validated(eraId: '', label: 'x', fromMarker: 'f'),
        throwsArgumentError,
      );
      expect(
        () => NameEra.validated(eraId: 'e', label: '  ', fromMarker: 'f'),
        throwsArgumentError,
      );
      expect(
        () => NameEra.validated(eraId: 'e', label: 'x', fromMarker: ''),
        throwsArgumentError,
      );
    });

    test('rejects blank toMarker instead of silently nulling', () {
      expect(
        () => NameEra.validated(
          eraId: 'e',
          label: 'x',
          fromMarker: 'f',
          toMarker: '   ',
        ),
        throwsArgumentError,
      );
    });

    test('ongoing when toMarker null, closed otherwise', () {
      expect(era('e1').isOngoing, isTrue);
      expect(era('e2', toMarker: 'end').isOngoing, isFalse);
    });

    test('describe shows ongoing vs closed span', () {
      expect(era('e1').describe(), contains('ongoing'));
      expect(era('e1').describe(), contains('age-ash-start'));
      expect(era('e1', toMarker: 'z').describe(), contains('..z'));
    });

    test('compare orders by sequence, nulls last, then eraId', () {
      final a = era('a', sequence: 1);
      final b = era('b', sequence: 2);
      final n = era('n');
      expect(NameEra.compare(a, b), lessThan(0));
      expect(NameEra.compare(b, a), greaterThan(0));
      expect(NameEra.compare(a, n), lessThan(0));
      expect(NameEra.compare(n, a), greaterThan(0));
      expect(NameEra.compare(n, era('m')), greaterThan(0));
      expect(NameEra.compare(a, era('a', sequence: 1)), 0);
    });

    test('covers marker within inclusive bounds', () {
      final e = era('e', fromMarker: 'm1', toMarker: 'm5');
      expect(e.coversMarker('m1'), isTrue);
      expect(e.coversMarker('m3'), isTrue);
      expect(e.coversMarker('m5'), isTrue);
      expect(e.coversMarker('m6'), isFalse);
      expect(e.coversMarker('m0'), isFalse);
    });

    test('ongoing era covers everything from its start marker on', () {
      final e = era('e', fromMarker: 'm1');
      expect(e.coversMarker('m2'), isTrue);
      expect(e.coversMarker('m1'), isTrue);
      expect(e.coversMarker('m0'), isFalse);
    });

    test('json roundtrip is stable', () {
      final e = era('e1', toMarker: 'end', sequence: 3);
      expect(NameEra.fromJson(jsonDecode(jsonEncode(e.toJson()))), e);
    });
  });

  group('NameTitle (titles)', () {
    test('trims id and text', () {
      final t = NameTitle.validated(
        id: ' t ',
        text: ' Lord ',
        position: TitlePosition.postName,
        entityTypes: const {NameEntityType.person},
        contexts: const {SocialContext.formal},
      );
      expect(t.id, 't');
      expect(t.text, 'Lord');
      expect(t.position, TitlePosition.postName);
    });

    test('rejects empty id or text', () {
      expect(
        () => NameTitle.validated(
          id: '',
          text: 'x',
          position: TitlePosition.preName,
          entityTypes: const {NameEntityType.person},
          contexts: const {SocialContext.formal},
        ),
        throwsArgumentError,
      );
      expect(
        () => NameTitle.validated(
          id: 't',
          text: ' ',
          position: TitlePosition.preName,
          entityTypes: const {NameEntityType.person},
          contexts: const {SocialContext.formal},
        ),
        throwsArgumentError,
      );
    });

    test('rejects empty entityTypes or contexts', () {
      expect(
        () => NameTitle.validated(
          id: 't',
          text: 'x',
          position: TitlePosition.preName,
          entityTypes: const {},
          contexts: const {SocialContext.formal},
        ),
        throwsArgumentError,
      );
      expect(
        () => NameTitle.validated(
          id: 't',
          text: 'x',
          position: TitlePosition.preName,
          entityTypes: const {NameEntityType.person},
          contexts: const {},
        ),
        throwsArgumentError,
      );
    });

    test('appliesTo matches declared type+context only', () {
      final t = title('t');
      expect(t.appliesTo(NameEntityType.person, SocialContext.formal), isTrue);
      expect(
        t.appliesTo(NameEntityType.person, SocialContext.everyday),
        isFalse,
      );
      expect(t.appliesTo(NameEntityType.place, SocialContext.formal), isFalse);
    });

    test('entityTypes and contexts are canonically ordered and immutable', () {
      final t = NameTitle.validated(
        id: 't',
        text: 'x',
        position: TitlePosition.preName,
        entityTypes: const {NameEntityType.place, NameEntityType.person},
        contexts: const {SocialContext.sacred, SocialContext.formal},
      );
      expect(t.entityTypes.first, NameEntityType.person);
      expect(t.contexts.first, SocialContext.formal);
      expect(
        () => t.entityTypes.add(NameEntityType.deity),
        throwsUnsupportedError,
      );
    });

    test('apply places text by position', () {
      expect(title('p', text: 'Lady').applyTo('Anya'), 'Lady Anya');
      expect(
        title(
          's',
          text: 'the Pious',
          position: TitlePosition.postName,
        ).applyTo('Anya'),
        'Anya the Pious',
      );
    });

    test('json roundtrip equality', () {
      final t = title(
        't',
        contexts: const {SocialContext.formal, SocialContext.ceremonial},
      );
      expect(NameTitle.fromJson(jsonDecode(jsonEncode(t.toJson()))), t);
    });
  });

  group('NameAffixRule (prefix_suffix_rules)', () {
    test('trims id and text', () {
      final r = NameAffixRule.validated(
        id: ' r ',
        kind: NameAffixKind.suffix,
        text: ' ham ',
        entityTypes: const {NameEntityType.place},
        contexts: const {SocialContext.everyday},
      );
      expect(r.id, 'r');
      expect(r.text, 'ham');
      expect(r.kind, NameAffixKind.suffix);
    });

    test('rejects empty id or text', () {
      expect(
        () => NameAffixRule.validated(
          id: '',
          kind: NameAffixKind.prefix,
          text: 'x',
          entityTypes: const {NameEntityType.place},
          contexts: const {SocialContext.everyday},
        ),
        throwsArgumentError,
      );
      expect(
        () => NameAffixRule.validated(
          id: 'r',
          kind: NameAffixKind.prefix,
          text: '  ',
          entityTypes: const {NameEntityType.place},
          contexts: const {SocialContext.everyday},
        ),
        throwsArgumentError,
      );
    });

    test('rejects empty entityTypes or contexts', () {
      expect(
        () => NameAffixRule.validated(
          id: 'r',
          kind: NameAffixKind.prefix,
          text: 'x',
          entityTypes: const {},
          contexts: const {SocialContext.everyday},
        ),
        throwsArgumentError,
      );
      expect(
        () => NameAffixRule.validated(
          id: 'r',
          kind: NameAffixKind.prefix,
          text: 'x',
          entityTypes: const {NameEntityType.place},
          contexts: const {},
        ),
        throwsArgumentError,
      );
    });

    test('appliesTo matches type and context', () {
      final r = affix('r');
      expect(r.appliesTo(NameEntityType.place, SocialContext.everyday), isTrue);
      expect(r.appliesTo(NameEntityType.place, SocialContext.formal), isFalse);
      expect(
        r.appliesTo(NameEntityType.person, SocialContext.everyday),
        isFalse,
      );
    });

    test('attach prepends prefix and appends suffix', () {
      expect(affix('p', text: 'ne').attachTo('wick'), 'newick');
      expect(
        affix('s', kind: NameAffixKind.suffix, text: 'heim').attachTo('Nor'),
        'Norheim',
      );
    });

    test('optional flag defaults false and roundtrips', () {
      expect(affix('r').optional, isFalse);
      final o = affix('o', optional: true);
      expect(o.optional, isTrue);
      expect(NameAffixRule.fromJson(jsonDecode(jsonEncode(o.toJson()))), o);
    });

    test('json roundtrip equality', () {
      final r = affix(
        'r',
        entityTypes: const {NameEntityType.place, NameEntityType.organization},
      );
      expect(NameAffixRule.fromJson(jsonDecode(jsonEncode(r.toJson()))), r);
    });
  });

  group('CulturalNameProfile (culture, language, era, whitelist)', () {
    test('trims cultureId, languageId, profileId', () {
      final p = profile(profileId: ' p ', cultureId: ' c ', languageId: ' l ');
      expect(p.profileId, 'p');
      expect(p.cultureId, 'c');
      expect(p.languageId, 'l');
    });

    test('rejects blank identifiers', () {
      expect(() => profile(profileId: '  '), throwsArgumentError);
      expect(() => profile(cultureId: ''), throwsArgumentError);
      expect(() => profile(languageId: '   '), throwsArgumentError);
    });

    test('requires at least one entity type', () {
      expect(() => profile(entityTypes: const {}), throwsArgumentError);
    });

    test('entityTypes normalized to canonical order', () {
      final p = profile(
        entityTypes: const <NameEntityType>{
          NameEntityType.place,
          NameEntityType.person,
        },
      );
      expect(p.entityTypes, [NameEntityType.person, NameEntityType.place]);
      expect(
        () => p.entityTypes.add(NameEntityType.deity),
        throwsUnsupportedError,
      );
    });

    test('title referencing type outside whitelist is rejected', () {
      expect(
        () => profile(
          entityTypes: const {NameEntityType.person},
          titles: [
            title('t', entityTypes: const {NameEntityType.place}),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('affix referencing type outside whitelist is rejected', () {
      expect(
        () => profile(
          entityTypes: const {NameEntityType.person},
          affixRules: [
            affix('r', entityTypes: const {NameEntityType.deity}),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('duplicate title and affix ids rejected', () {
      expect(
        () => profile(titles: [title('t'), title('t')]),
        throwsArgumentError,
      );
      expect(
        () => profile(
          entityTypes: const {NameEntityType.person, NameEntityType.place},
          affixRules: [affix('r'), affix('r')],
        ),
        throwsArgumentError,
      );
    });

    test('era is optional and stored by identity', () {
      expect(profile().era, isNull);
      final e = era('e1');
      expect(profile(eraSection: e).era, e);
    });

    test('defaultContext preserved', () {
      expect(
        profile(defaultContext: SocialContext.ceremonial).defaultContext,
        SocialContext.ceremonial,
      );
    });

    test('titlesApplyingTo filters and sorts by id', () {
      final p = profile(
        titles: [
          title('z-lord'),
          title('a-lady'),
          title('x-place', entityTypes: const {NameEntityType.place}),
        ],
      );
      expect(
        p
            .titlesApplyingTo(NameEntityType.person, SocialContext.formal)
            .map((t) => t.id),
        ['a-lady', 'z-lord'],
      );
    });

    test('affixesApplyingTo filters by type and context', () {
      final p = profile(
        entityTypes: const {
          NameEntityType.person,
          NameEntityType.place,
          NameEntityType.artifact,
        },
        affixRules: [
          affix('b-ne'),
          affix('a-ham', kind: NameAffixKind.suffix),
          affix(
            'c-forge',
            entityTypes: const {NameEntityType.artifact},
            contexts: const {SocialContext.sacred},
          ),
        ],
      );
      expect(
        p
            .affixesApplyingTo(NameEntityType.place, SocialContext.everyday)
            .map((r) => r.id),
        ['a-ham', 'b-ne'],
      );
      expect(
        p.affixesApplyingTo(NameEntityType.place, SocialContext.formal),
        isEmpty,
      );
    });

    test('decorateName applies prefixes (id asc, outermost first) then '
        'suffixes (id asc)', () {
      final p = profile(
        entityTypes: const {NameEntityType.person, NameEntityType.place},
        affixRules: [
          affix('p2', text: 'bur'),
          affix('p1', text: 'ne'),
          affix('s1', kind: NameAffixKind.suffix, text: 'heim'),
          affix('s2', kind: NameAffixKind.suffix, text: 'ford'),
        ],
      );
      expect(
        p.decorateName('wic', NameEntityType.place, SocialContext.everyday),
        'burnewicheimford',
      );
      expect(
        p.decorateName('Anya', NameEntityType.person, SocialContext.formal),
        'Anya',
      );
    });

    test('decorateName applies matching affix in everyday context', () {
      final p = profile(affixRules: [affix('r')]);
      expect(
        p.decorateName('wic', NameEntityType.place, SocialContext.everyday),
        'newic',
      );
    });

    test('titlesFor composes full styled name pre then post', () {
      final p = profile(
        titles: [
          title('pre', text: 'Lady'),
          title('post', text: 'the Wise', position: TitlePosition.postName),
        ],
      );
      expect(
        p.titledName('Anya', NameEntityType.person, SocialContext.formal),
        'Lady Anya the Wise',
      );
    });

    test('titledName for non-matching context returns bare name', () {
      final p = profile(titles: [title('pre')]);
      expect(
        p.titledName('Anya', NameEntityType.person, SocialContext.everyday),
        'Anya',
      );
    });

    test('unknown entityType query returns empty lists', () {
      final p = profile(titles: [title('t')], affixRules: []);
      expect(
        p.titlesApplyingTo(NameEntityType.deity, SocialContext.sacred),
        isEmpty,
      );
      expect(
        p.affixesApplyingTo(NameEntityType.deity, SocialContext.sacred),
        isEmpty,
      );
    });

    test('supportsEntityType reflects whitelist', () {
      final p = profile();
      expect(p.supportsEntityType(NameEntityType.person), isTrue);
      expect(p.supportsEntityType(NameEntityType.deity), isFalse);
    });

    test('json roundtrip is byte-identical', () {
      final p = profile(
        eraSection: era('e1', toMarker: 'end', sequence: 2),
        titles: [title('t')],
        affixRules: [affix('r')],
      );
      final json = p.toJson();
      final restored = CulturalNameProfile.fromJson(
        jsonDecode(jsonEncode(json)) as Map<String, Object?>,
      );
      expect(restored, p);
      expect(jsonEncode(restored.toJson()), jsonEncode(json));
    });

    test('fromJson tolerates missing optional collections', () {
      final minimal = <String, Object?>{
        'profileId': 'p',
        'cultureId': 'c',
        'languageId': 'l',
        'entityTypes': <Object?>['person'],
        'defaultContext': 'everyday',
      };
      final p = CulturalNameProfile.fromJson(minimal);
      expect(p.titles, isEmpty);
      expect(p.affixRules, isEmpty);
      expect(p.era, isNull);
    });
  });

  group('NameProfileCatalog (multi-profile selection)', () {
    final northOld = profile(
      profileId: 'north-old',
      eraSection: era('old', sequence: 1, toMarker: 'm09', fromMarker: 'm00'),
      titles: [title('old-title', text: 'Elder')],
    );
    final northNow = profile(
      profileId: 'north-now',
      eraSection: era('now', sequence: 2, fromMarker: 'm10'),
      entityTypes: const {NameEntityType.person, NameEntityType.place},
      titles: [title('now-title', text: 'Lady')],
      affixRules: [affix('now-affix')],
    );
    final south = profile(
      profileId: 'south',
      cultureId: 'southfolk',
      languageId: 'lang-south',
    );

    NameProfileCatalog buildCatalog() =>
        NameProfileCatalog.validated(profiles: [northOld, northNow, south]);

    test('rejects duplicate profile ids', () {
      expect(
        () => NameProfileCatalog.validated(
          profiles: [
            northOld,
            profile(profileId: 'north-old'),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('empty catalog is allowed', () {
      final c = NameProfileCatalog.validated(profiles: const []);
      expect(c.count, 0);
      expect(c.profilesForCulture('any'), isEmpty);
    });

    test('profilesForCulture and profilesForLanguage filter sorted by id', () {
      final c = buildCatalog();
      expect(c.profilesForCulture('northfolk').map((p) => p.profileId), [
        'north-now',
        'north-old',
      ]);
      expect(c.profilesForLanguage('lang-south').map((p) => p.profileId), [
        'south',
      ]);
    });

    test('activeProfileFor picks era-matching profile by sequence rank', () {
      final c = buildCatalog();
      expect(
        c
            .activeProfileFor(cultureId: 'northfolk', marker: 'm05', rank: 5)
            ?.profileId,
        'north-old',
      );
      expect(
        c
            .activeProfileFor(cultureId: 'northfolk', marker: 'm12', rank: 12)
            ?.profileId,
        'north-now',
      );
    });

    test('activeProfileFor returns null for unknown culture', () {
      expect(
        buildCatalog().activeProfileFor(
          cultureId: 'nope',
          marker: 'm5',
          rank: 5,
        ),
        isNull,
      );
    });

    test('activeProfileFor falls back to eraless profile', () {
      final c = NameProfileCatalog.validated(
        profiles: [profile(profileId: 'eraless', eraSection: null)],
      );
      expect(
        c
            .activeProfileFor(cultureId: 'northfolk', marker: 'zz', rank: null)
            ?.profileId,
        'eraless',
      );
    });

    test('count reflects registered profiles', () {
      expect(buildCatalog().count, 3);
    });
  });
}
