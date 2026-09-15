// Sprint 111.26 - Theology, Deity & Doctrine Model.
//
// RED contract test: stores deities with their divine domains, doctrines,
// rituals, religious institutions, taboos, sacred texts, and the schisms
// that split institutions apart — with referential integrity enforced at
// the record boundary (a schism can only split registered institutions, a
// ritual can only name a registered deity, and so on).
//
// Domain-only: no persistence, UI, locale, network, wall clock, or random.

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_theology.dart';

Deity _deity(
  String id, {
  String? name,
  DeityRole role = DeityRole.other,
  List<DivineDomain> domains = const [],
  String? parentDeityId,
}) {
  return Deity.validated(
    deityId: id,
    name: name ?? 'Deity $id',
    role: role,
    domains: domains,
    parentDeityId: parentDeityId,
  );
}

Doctrine _doctrine(
  String id, {
  DoctrineKind kind = DoctrineKind.tenet,
  String? sourceTextId,
}) {
  return Doctrine.validated(
    doctrineId: id,
    title: 'Doctrine $id',
    statement: 'Statement of $id',
    kind: kind,
    sourceTextId: sourceTextId,
  );
}

Ritual _ritual(
  String id, {
  String? deityId,
  RitualCadence cadence = RitualCadence.annual,
}) {
  return Ritual.validated(
    ritualId: id,
    name: 'Ritual $id',
    deityId: deityId,
    cadence: cadence,
  );
}

ReligiousInstitution _institution(
  String id, {
  String? headDeityId,
  InstitutionKind kind = InstitutionKind.church,
  List<String> doctrineIds = const [],
}) {
  return ReligiousInstitution.validated(
    institutionId: id,
    name: 'Institution $id',
    headDeityId: headDeityId,
    kind: kind,
    doctrineIds: doctrineIds,
  );
}

Taboo _taboo(
  String id, {
  TabooSeverity severity = TabooSeverity.mild,
  String? deityId,
}) {
  return Taboo.validated(
    tabooId: id,
    description: 'Do not cross $id',
    severity: severity,
    deityId: deityId,
  );
}

SacredText _text(
  String id, {
  TextCanonicity canonicity = TextCanonicity.canonical,
}) {
  return SacredText.validated(
    textId: id,
    title: 'Text $id',
    canonicity: canonicity,
  );
}

SchismEvent _schism(
  String id, {
  required String parentInstitutionId,
  required String offspringInstitutionId,
  String? doctrineId,
}) {
  return SchismEvent.validated(
    schismId: id,
    name: 'Schism $id',
    parentInstitutionId: parentInstitutionId,
    offspringInstitutionId: offspringInstitutionId,
    doctrineId: doctrineId,
  );
}

TheologyRecord _record({
  String theologyId = 'faith-1',
  String name = 'Faith of the Twin Stars',
  List<Deity> deities = const [],
  List<Doctrine> doctrines = const [],
  List<Ritual> rituals = const [],
  List<ReligiousInstitution> institutions = const [],
  List<Taboo> taboos = const [],
  List<SacredText> texts = const [],
  List<SchismEvent> schisms = const [],
}) {
  return TheologyRecord.validated(
    theologyId: theologyId,
    name: name,
    deities: deities,
    doctrines: doctrines,
    rituals: rituals,
    institutions: institutions,
    taboos: taboos,
    texts: texts,
    schisms: schisms,
  );
}

void main() {
  group('DeityRole', () {
    test('exposes stable UI labels', () {
      expect(DeityRole.values.map((r) => r.label), [
        'Supreme',
        'Creator',
        'Sustainer',
        'Destruction',
        'War',
        'Wisdom',
        'Nature',
        'Underworld',
        'Trickster',
        'Other',
      ]);
    });
  });

  group('DoctrineKind', () {
    test('exposes stable UI labels', () {
      expect(DoctrineKind.values.map((k) => k.label), [
        'Tenet',
        'Moral Law',
        'Sacrament',
        'Mystery',
        'Eschatology',
        'Other',
      ]);
    });
  });

  group('RitualCadence', () {
    test('exposes stable UI labels', () {
      expect(RitualCadence.values.map((c) => c.label), [
        'Daily',
        'Weekly',
        'Seasonal',
        'Annual',
        'Life Event',
        'Once in Ages',
        'Other',
      ]);
    });
  });

  group('InstitutionKind', () {
    test('exposes stable UI labels', () {
      expect(InstitutionKind.values.map((k) => k.label), [
        'Church',
        'Religious Order',
        'Sect',
        'Seminary',
        'Shrine',
        'Clergy House',
        'Other',
      ]);
    });
  });

  group('TabooSeverity', () {
    test('weights are strictly increasing along the ladder', () {
      final weights = TabooSeverity.values.map((s) => s.weight).toList();
      expect(weights, [1, 2, 3]);
      for (var i = 1; i < weights.length; i++) {
        expect(weights[i], greaterThan(weights[i - 1]));
      }
    });

    test('labels are stable', () {
      expect(TabooSeverity.values.map((s) => s.label), [
        'Mild',
        'Grave',
        'Mortal',
      ]);
    });
  });

  group('TextCanonicity', () {
    test('weights are strictly increasing along the ladder', () {
      final weights = TextCanonicity.values.map((c) => c.weight).toList();
      expect(weights, [0, 1, 2, 3]);
      for (var i = 1; i < weights.length; i++) {
        expect(weights[i], greaterThan(weights[i - 1]));
      }
    });

    test('labels are stable', () {
      expect(TextCanonicity.values.map((c) => c.label), [
        'Apocryphal',
        'Disputed',
        'Canonical',
        'Revealed',
      ]);
    });
  });

  group('DivineDomain', () {
    test('validated trims ids, names, and optional description', () {
      final domain = DivineDomain.validated(
        domainId: ' dom-sun ',
        name: ' Sun ',
        description: ' giver of light ',
      );
      expect(domain.domainId, 'dom-sun');
      expect(domain.name, 'Sun');
      expect(domain.description, 'giver of light');
    });

    test('rejects empty domainId and name; blank description rejected', () {
      expect(
        () => DivineDomain.validated(domainId: ' ', name: 'Sun'),
        throwsArgumentError,
      );
      expect(
        () => DivineDomain.validated(domainId: 'd', name: '  '),
        throwsArgumentError,
      );
      expect(
        () => DivineDomain.validated(
          domainId: 'd',
          name: 'Sun',
          description: '   ',
        ),
        throwsArgumentError,
      );
    });
  });

  group('Deity', () {
    test('validated trims identity and keeps role + immortality', () {
      final deity = Deity.validated(
        deityId: ' dy-a ',
        name: ' Aelyra ',
        role: DeityRole.wisdom,
        immortal: false,
      );
      expect(deity.deityId, 'dy-a');
      expect(deity.name, 'Aelyra');
      expect(deity.role, DeityRole.wisdom);
      expect(deity.roleLabel, 'Wisdom');
      expect(deity.immortal, isFalse);
      expect(deity.isOfRole(DeityRole.wisdom), isTrue);
      expect(deity.isOfRole(DeityRole.war), isFalse);
    });

    test('defaults: role other, immortal true, no domains', () {
      final deity = Deity.validated(deityId: 'd', name: 'D');
      expect(deity.role, DeityRole.other);
      expect(deity.immortal, isTrue);
      expect(deity.domains, isEmpty);
      expect(deity.parentDeityId, isNull);
    });

    test('rejects duplicate domain ids and blank epithets/epithet dupes', () {
      expect(
        () => Deity.validated(deityId: 'd', name: 'D', domains: const []),
        returnsNormally,
      );
      expect(
        () => Deity.validated(
          deityId: 'd',
          name: 'D',
          domains: [
            DivineDomain.validated(domainId: 'x', name: 'Fire'),
            DivineDomain.validated(domainId: 'x', name: 'Ash'),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => Deity.validated(
          deityId: 'd',
          name: 'D',
          epithets: const ['Star', '  '],
        ),
        throwsArgumentError,
      );
      expect(
        () => Deity.validated(
          deityId: 'd',
          name: 'D',
          epithets: const ['Star', 'star'],
        ),
        throwsArgumentError,
      );
    });

    test('domainIds sorted immutable; hasDomain trims lookup', () {
      final deity = Deity.validated(
        deityId: 'd',
        name: 'D',
        domains: [
          DivineDomain.validated(domainId: 'b', name: 'Sea'),
          DivineDomain.validated(domainId: 'a', name: 'Sun'),
        ],
      );
      expect(deity.domainIds, ['a', 'b']);
      expect(deity.hasDomain(' a '), isTrue);
      expect(deity.hasDomain('zz'), isFalse);
      expect(() => deity.domainIds.add('c'), throwsUnsupportedError);
    });
  });

  group('Doctrine', () {
    test('validated requires ids/title/statement; optional fields trimmed', () {
      final doctrine = Doctrine.validated(
        doctrineId: ' doc-1 ',
        title: ' Night Keeps Silence ',
        statement: ' Speak no word after dusk. ',
        sourceTextId: ' txt-1 ',
        note: ' early form ',
      );
      expect(doctrine.doctrineId, 'doc-1');
      expect(doctrine.title, 'Night Keeps Silence');
      expect(doctrine.statement, 'Speak no word after dusk.');
      expect(doctrine.sourceTextId, 'txt-1');
      expect(doctrine.note, 'early form');
      expect(doctrine.kind, DoctrineKind.tenet);
      expect(doctrine.kindLabel, 'Tenet');
    });

    test('rejects blank required fields and blank optionals', () {
      expect(
        () => Doctrine.validated(doctrineId: ' ', title: 'T', statement: 'S'),
        throwsArgumentError,
      );
      expect(
        () => Doctrine.validated(doctrineId: 'd', title: ' ', statement: 'S'),
        throwsArgumentError,
      );
      expect(
        () => Doctrine.validated(doctrineId: 'd', title: 'T', statement: '  '),
        throwsArgumentError,
      );
      expect(
        () => Doctrine.validated(
          doctrineId: 'd',
          title: 'T',
          statement: 'S',
          sourceTextId: '  ',
        ),
        throwsArgumentError,
      );
    });
  });

  group('Ritual', () {
    test('validated trims; offerings non-empty and unique', () {
      final ritual = Ritual.validated(
        ritualId: ' r-1 ',
        name: ' Kindling ',
        deityId: ' dy-a ',
        cadence: RitualCadence.daily,
        offerings: const [' oil ', 'oil-seed'],
      );
      expect(ritual.ritualId, 'r-1');
      expect(ritual.name, 'Kindling');
      expect(ritual.deityId, 'dy-a');
      expect(ritual.cadence, RitualCadence.daily);
      expect(ritual.cadenceLabel, 'Daily');
      expect(ritual.offerings, ['oil', 'oil-seed']);
    });

    test('rejects blank ids and blank offering entries', () {
      expect(
        () => Ritual.validated(ritualId: ' ', name: 'R'),
        throwsArgumentError,
      );
      expect(
        () => Ritual.validated(ritualId: 'r', name: ' '),
        throwsArgumentError,
      );
      expect(
        () => Ritual.validated(
          ritualId: 'r',
          name: 'R',
          offerings: const ['flower', ' '],
        ),
        throwsArgumentError,
      );
    });

    test('communal rituals carry null deityId', () {
      final ritual = Ritual.validated(ritualId: 'r', name: 'R');
      expect(ritual.deityId, isNull);
    });
  });

  group('ReligiousInstitution', () {
    test('validated trims and guards duplicate doctrine refs', () {
      final inst = ReligiousInstitution.validated(
        institutionId: ' i-1 ',
        name: ' Order of the Veil ',
        kind: InstitutionKind.order,
        headDeityId: ' dy-a ',
        headClericId: ' hc-1 ',
        doctrineIds: const ['doc-1', 'doc-2'],
        foundedMarker: ' era-third ',
      );
      expect(inst.institutionId, 'i-1');
      expect(inst.name, 'Order of the Veil');
      expect(inst.kind, InstitutionKind.order);
      expect(inst.kindLabel, 'Religious Order');
      expect(inst.headDeityId, 'dy-a');
      expect(inst.headClericId, 'hc-1');
      expect(inst.doctrineIds, ['doc-1', 'doc-2']);
      expect(inst.teachesDoctrine(' doc-1 '), isTrue);
      expect(inst.teachesDoctrine('doc-9'), isFalse);
      expect(
        () => ReligiousInstitution.validated(
          institutionId: 'i',
          name: 'I',
          doctrineIds: const ['doc-1', 'doc-1'],
        ),
        throwsArgumentError,
      );
    });

    test('rejects blank required ids and blank founded marker', () {
      expect(
        () => ReligiousInstitution.validated(institutionId: ' ', name: 'I'),
        throwsArgumentError,
      );
      expect(
        () => ReligiousInstitution.validated(institutionId: 'i', name: ' '),
        throwsArgumentError,
      );
      expect(
        () => ReligiousInstitution.validated(
          institutionId: 'i',
          name: 'I',
          foundedMarker: '  ',
        ),
        throwsArgumentError,
      );
    });
  });

  group('Taboo', () {
    test('validated requires description; severity ladder exposed', () {
      final taboo = Taboo.validated(
        tabooId: ' t-1 ',
        description: ' Never speak the true name at dusk ',
        severity: TabooSeverity.mortal,
        deityId: ' dy-a ',
        atonement: ' Three days of silence ',
      );
      expect(taboo.tabooId, 't-1');
      expect(taboo.description, 'Never speak the true name at dusk');
      expect(taboo.severity, TabooSeverity.mortal);
      expect(taboo.severityLabel, 'Mortal');
      expect(taboo.deityId, 'dy-a');
      expect(taboo.atonement, 'Three days of silence');
    });

    test('rejects blank tabooId and description', () {
      expect(
        () => Taboo.validated(tabooId: ' ', description: 'D'),
        throwsArgumentError,
      );
      expect(
        () => Taboo.validated(tabooId: 't', description: '  '),
        throwsArgumentError,
      );
    });
  });

  group('SacredText', () {
    test('validated trims and keeps canonicity ladder', () {
      final text = SacredText.validated(
        textId: ' txt-1 ',
        title: ' The Book of Quiet Fires ',
        canonicity: TextCanonicity.revealed,
        authorship: ' the first keepers ',
      );
      expect(text.textId, 'txt-1');
      expect(text.title, 'The Book of Quiet Fires');
      expect(text.canonicity, TextCanonicity.revealed);
      expect(text.canonicityLabel, 'Revealed');
      expect(text.authorship, 'the first keepers');
    });

    test('rejects blank textId/title and blank authorship', () {
      expect(
        () => SacredText.validated(textId: ' ', title: 'T'),
        throwsArgumentError,
      );
      expect(
        () => SacredText.validated(textId: 't', title: ' '),
        throwsArgumentError,
      );
      expect(
        () => SacredText.validated(textId: 't', title: 'T', authorship: '   '),
        throwsArgumentError,
      );
    });
  });

  group('SchismEvent', () {
    test('validated requires both institution ends', () {
      final schism = SchismEvent.validated(
        schismId: ' s-1 ',
        name: ' The Ashen Split ',
        parentInstitutionId: ' i-old ',
        offspringInstitutionId: ' i-new ',
        doctrineId: ' doc-x ',
        marker: ' year-812 ',
      );
      expect(schism.schismId, 's-1');
      expect(schism.name, 'The Ashen Split');
      expect(schism.parentInstitutionId, 'i-old');
      expect(schism.offspringInstitutionId, 'i-new');
      expect(schism.doctrineId, 'doc-x');
      expect(schism.marker, 'year-812');
      expect(schism.tanglesWith(' i-new '), isTrue);
      expect(schism.tanglesWith('other'), isFalse);
    });

    test('rejects blank schismId, name, or either institution end', () {
      expect(
        () => SchismEvent.validated(
          schismId: ' ',
          name: 'S',
          parentInstitutionId: 'p',
          offspringInstitutionId: 'o',
        ),
        throwsArgumentError,
      );
      expect(
        () => SchismEvent.validated(
          schismId: 's',
          name: ' ',
          parentInstitutionId: 'p',
          offspringInstitutionId: 'o',
        ),
        throwsArgumentError,
      );
      expect(
        () => SchismEvent.validated(
          schismId: 's',
          name: 'S',
          parentInstitutionId: ' ',
          offspringInstitutionId: 'o',
        ),
        throwsArgumentError,
      );
      expect(
        () => SchismEvent.validated(
          schismId: 's',
          name: 'S',
          parentInstitutionId: 'p',
          offspringInstitutionId: '  ',
        ),
        throwsArgumentError,
      );
    });
  });

  group('TheologyRecord identity', () {
    test('rejects blank theologyId and name', () {
      expect(() => _record(theologyId: ' '), throwsArgumentError);
      expect(() => _record(name: '  '), throwsArgumentError);
    });

    test('empty collections are allowed and immutable', () {
      final record = _record();
      expect(record.deityCount, 0);
      expect(record.doctrineCount, 0);
      expect(record.ritualCount, 0);
      expect(record.institutionCount, 0);
      expect(record.tabooCount, 0);
      expect(record.textCount, 0);
      expect(record.schismCount, 0);
      expect(record.deityIds, isEmpty);
      expect(() => record.deities.add(_deity('d')), throwsUnsupportedError);
    });

    test('guards duplicate ids within every collection', () {
      expect(
        () => _record(deities: [_deity('d'), _deity('d')]),
        throwsArgumentError,
      );
      expect(
        () => _record(doctrines: [_doctrine('a'), _doctrine('a')]),
        throwsArgumentError,
      );
      expect(
        () => _record(rituals: [_ritual('r'), _ritual('r')]),
        throwsArgumentError,
      );
      expect(
        () => _record(institutions: [_institution('i'), _institution('i')]),
        throwsArgumentError,
      );
      expect(
        () => _record(taboos: [_taboo('t'), _taboo('t')]),
        throwsArgumentError,
      );
      expect(
        () => _record(texts: [_text('x'), _text('x')]),
        throwsArgumentError,
      );
      expect(
        () => _record(
          institutions: [_institution('i-old'), _institution('i-new')],
          schisms: [
            _schism(
              's',
              parentInstitutionId: 'i-old',
              offspringInstitutionId: 'i-new',
            ),
            _schism(
              's',
              parentInstitutionId: 'i-old',
              offspringInstitutionId: 'i-new',
            ),
          ],
        ),
        throwsArgumentError,
      );
    });
  });

  group('TheologyRecord referential integrity', () {
    test('schism must split two registered institutions', () {
      expect(
        () => _record(
          institutions: [_institution('i-old')],
          schisms: [
            _schism(
              's',
              parentInstitutionId: 'i-old',
              offspringInstitutionId: 'i-ghost',
            ),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => _record(
          institutions: [_institution('i-new')],
          schisms: [
            _schism(
              's',
              parentInstitutionId: 'i-ghost',
              offspringInstitutionId: 'i-new',
            ),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => _record(
          institutions: [_institution('i-old'), _institution('i-new')],
          schisms: [
            _schism(
              's',
              parentInstitutionId: 'i-old',
              offspringInstitutionId: 'i-new',
            ),
          ],
        ),
        returnsNormally,
      );
    });

    test('ritual deityId must reference a registered deity', () {
      expect(
        () => _record(rituals: [_ritual('r', deityId: 'dy-missing')]),
        throwsArgumentError,
      );
      expect(
        () => _record(
          deities: [_deity('dy-a')],
          rituals: [_ritual('r', deityId: 'dy-a')],
        ),
        returnsNormally,
      );
    });

    test('taboo and institution head deity must be registered', () {
      expect(
        () => _record(taboos: [_taboo('t', deityId: 'ghost')]),
        throwsArgumentError,
      );
      expect(
        () => _record(institutions: [_institution('i', headDeityId: 'ghost')]),
        throwsArgumentError,
      );
      expect(
        () => _record(
          deities: [_deity('dy-a')],
          taboos: [_taboo('t', deityId: 'dy-a')],
          institutions: [_institution('i', headDeityId: 'dy-a')],
        ),
        returnsNormally,
      );
    });

    test('institution doctrineIds must all be registered doctrines', () {
      expect(
        () => _record(
          institutions: [
            _institution('i', doctrineIds: const ['doc-x']),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => _record(
          doctrines: [_doctrine('doc-x')],
          institutions: [
            _institution('i', doctrineIds: const ['doc-x']),
          ],
        ),
        returnsNormally,
      );
    });

    test('doctrine sourceTextId and schism doctrineId must be registered', () {
      expect(
        () =>
            _record(doctrines: [_doctrine('doc-1', sourceTextId: 'txt-ghost')]),
        throwsArgumentError,
      );
      expect(
        () => _record(
          institutions: [_institution('i-old'), _institution('i-new')],
          schisms: [
            _schism(
              's',
              parentInstitutionId: 'i-old',
              offspringInstitutionId: 'i-new',
              doctrineId: 'doc-ghost',
            ),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => _record(
          doctrines: [_doctrine('doc-1', sourceTextId: 'txt-1')],
          texts: [_text('txt-1')],
          institutions: [_institution('i-old'), _institution('i-new')],
          schisms: [
            _schism(
              's',
              parentInstitutionId: 'i-old',
              offspringInstitutionId: 'i-new',
              doctrineId: 'doc-1',
            ),
          ],
        ),
        returnsNormally,
      );
    });
  });

  group('TheologyRecord indexes', () {
    final record = _record(
      deities: [
        _deity(
          'dy-b',
          role: DeityRole.war,
          domains: [DivineDomain.validated(domainId: 'dom-fire', name: 'Fire')],
        ),
        _deity(
          'dy-a',
          role: DeityRole.wisdom,
          domains: [
            DivineDomain.validated(domainId: 'dom-fire', name: 'Fire'),
            DivineDomain.validated(domainId: 'dom-sun', name: 'Sun'),
          ],
        ),
      ],
      doctrines: [_doctrine('doc-2'), _doctrine('doc-1')],
      rituals: [
        _ritual('r-2', deityId: 'dy-a'),
        _ritual('r-1', deityId: 'dy-a'),
        _ritual('r-0', deityId: 'dy-b'),
      ],
      institutions: [
        _institution('i-1', headDeityId: 'dy-a', doctrineIds: const ['doc-1']),
      ],
      taboos: [
        _taboo('t-1', severity: TabooSeverity.grave),
        _taboo('t-2', severity: TabooSeverity.mortal),
      ],
      texts: [_text('x-1', canonicity: TextCanonicity.canonical)],
      schisms: [
        _schism(
          's-1',
          parentInstitutionId: 'i-1',
          offspringInstitutionId: 'i-1',
        ),
      ],
    );

    test('counts reflect every collection', () {
      expect(record.deityCount, 2);
      expect(record.doctrineCount, 2);
      expect(record.ritualCount, 3);
      expect(record.institutionCount, 1);
      expect(record.tabooCount, 2);
      expect(record.textCount, 1);
      expect(record.schismCount, 1);
    });

    test('id getters are sorted and immutable', () {
      expect(record.deityIds, ['dy-a', 'dy-b']);
      expect(record.doctrineIds, ['doc-1', 'doc-2']);
      expect(record.ritualIds, ['r-0', 'r-1', 'r-2']);
      expect(record.institutionIds, ['i-1']);
      expect(record.tabooIds, ['t-1', 't-2']);
      expect(record.textIds, ['x-1']);
      expect(record.schismIds, ['s-1']);
      expect(() => record.deityIds.add('zz'), throwsUnsupportedError);
    });

    test('hasX lookups trim and miss quietly', () {
      expect(record.hasDeity(' dy-a '), isTrue);
      expect(record.hasDoctrine('doc-9'), isFalse);
      expect(record.hasRitual('r-0'), isTrue);
      expect(record.hasInstitution('i-1'), isTrue);
      expect(record.hasTaboo('t-2'), isTrue);
      expect(record.hasText('x-1'), isTrue);
      expect(record.hasSchism('s-1'), isTrue);
      expect(record.hasSchism('s-nope'), isFalse);
    });

    test('deityNameFor resolves registered ids only', () {
      expect(record.deityNameFor(' dy-a '), 'Deity dy-a');
      expect(record.deityNameFor('ghost'), isNull);
    });

    test('deitiesWithRole and deityIdsGoverningDomain are sorted', () {
      expect(record.deitiesWithRole(DeityRole.war), ['dy-b']);
      expect(record.deitiesWithRole(DeityRole.wisdom), ['dy-a']);
      expect(record.deitiesWithRole(DeityRole.supreme), isEmpty);
      expect(record.deityIdsGoverningDomain('dom-fire'), ['dy-a', 'dy-b']);
      expect(record.deityIdsGoverningDomain('dom-sun'), ['dy-a']);
      expect(record.deityIdsGoverningDomain(' dom-fire '), ['dy-a', 'dy-b']);
    });

    test('ritualIdsForDeity and institutionIdsForDeity filter refs', () {
      expect(record.ritualIdsForDeity('dy-a'), ['r-1', 'r-2']);
      expect(record.ritualIdsForDeity('dy-b'), ['r-0']);
      expect(record.ritualIdsForDeity('ghost'), isEmpty);
      expect(record.institutionIdsForDeity('dy-a'), ['i-1']);
      expect(record.institutionIdsForDeity('dy-b'), isEmpty);
    });

    test('institutionIdsTeaching filters doctrine refs', () {
      expect(record.institutionIdsTeaching('doc-1'), ['i-1']);
      expect(record.institutionIdsTeaching('doc-2'), isEmpty);
    });

    test('taboosAtLeast and maxTabooSeverity follow the ladder', () {
      final grave = record.taboosAtLeast(TabooSeverity.grave);
      expect(grave.map((t) => t.tabooId), ['t-1', 't-2']);
      final mortal = record.taboosAtLeast(TabooSeverity.mortal);
      expect(mortal.map((t) => t.tabooId), ['t-2']);
      expect(record.maxTabooSeverity, TabooSeverity.mortal);
      expect(_record().maxTabooSeverity, isNull);
    });

    test('textIdsAtLeast follows the canonicity ladder', () {
      expect(record.textIdsAtLeast(TextCanonicity.canonical), ['x-1']);
      expect(record.textIdsAtLeast(TextCanonicity.revealed), isEmpty);
    });

    test('schismsSplittingFrom returns schisms tangled with institution', () {
      final split = record.schismsSplittingFrom('i-1');
      expect(split.map((s) => s.schismId), ['s-1']);
      expect(record.schismsSplittingFrom('ghost'), isEmpty);
    });

    test('parentDeityIds stays null for unlinked deities', () {
      final record2 = _record(
        deities: [
          _deity('dy-parent'),
          _deity('dy-child', parentDeityId: 'dy-parent'),
        ],
      );
      expect(record2.deities.first.parentDeityId, isNull);
      expect(record2.deities.last.parentDeityId, 'dy-parent');
    });
  });

  group('TheologyQuery', () {
    final war = _record(
      theologyId: 'f-war',
      deities: [_deity('d1', role: DeityRole.war)],
      doctrines: [_doctrine('doc-1', kind: DoctrineKind.moralLaw)],
      rituals: [_ritual('r1', cadence: RitualCadence.daily)],
      institutions: [_institution('i1', kind: InstitutionKind.order)],
      taboos: [_taboo('t1', severity: TabooSeverity.mortal)],
      texts: [_text('x1', canonicity: TextCanonicity.revealed)],
    );
    final quiet = _record(
      theologyId: 'f-quiet',
      deities: [_deity('d2', role: DeityRole.nature)],
      doctrines: [_doctrine('doc-2', kind: DoctrineKind.mystery)],
      rituals: [_ritual('r2', cadence: RitualCadence.annual)],
      institutions: [_institution('i2', kind: InstitutionKind.shrine)],
      taboos: [_taboo('t2', severity: TabooSeverity.mild)],
      texts: [_text('x2', canonicity: TextCanonicity.apocryphal)],
    );

    test('empty query matches everything and describes itself', () {
      const query = TheologyQuery();
      expect(query.isEmpty, isTrue);
      expect(query.matches(war), isTrue);
      expect(query.matches(quiet), isTrue);
      expect(query.describe(), 'TheologyQuery(no filters)');
    });

    test('role, kind, cadence, institution filters discriminate', () {
      expect(const TheologyQuery(role: DeityRole.war).matches(war), isTrue);
      expect(const TheologyQuery(role: DeityRole.war).matches(quiet), isFalse);
      expect(
        const TheologyQuery(doctrineKind: DoctrineKind.moralLaw).matches(war),
        isTrue,
      );
      expect(
        const TheologyQuery(cadence: RitualCadence.annual).matches(war),
        isFalse,
      );
      expect(
        const TheologyQuery(
          institutionKind: InstitutionKind.shrine,
        ).matches(quiet),
        isTrue,
      );
    });

    test('severity and canonicity minimums are inclusive', () {
      expect(
        const TheologyQuery(minTabooSeverity: TabooSeverity.grave).matches(war),
        isTrue,
      );
      expect(
        const TheologyQuery(
          minTabooSeverity: TabooSeverity.grave,
        ).matches(quiet),
        isFalse,
      );
      expect(
        const TheologyQuery(
          minCanonicity: TextCanonicity.revealed,
        ).matches(war),
        isTrue,
      );
      expect(
        const TheologyQuery(
          minCanonicity: TextCanonicity.revealed,
        ).matches(quiet),
        isFalse,
      );
    });

    test('describe names the active filters', () {
      final text = const TheologyQuery(
        role: DeityRole.war,
        minTabooSeverity: TabooSeverity.mortal,
      ).describe();
      expect(text, contains('role: War'));
      expect(text, contains('minTabooSeverity: Mortal'));
    });
  });

  group('TheologyCatalog', () {
    test('withRecords rejects duplicate theologyId and sorts by id', () {
      expect(
        () => TheologyCatalog.withRecords([
          _record(theologyId: 'a'),
          _record(theologyId: 'a'),
        ]),
        throwsArgumentError,
      );
      final catalog = TheologyCatalog.withRecords([
        _record(theologyId: 'b'),
        _record(theologyId: 'a'),
      ]);
      expect(catalog.theologyIds, ['a', 'b']);
      expect(catalog.length, 2);
      expect(catalog.isEmpty, isFalse);
      expect(catalog.recordFor(' a ')?.name, isNotNull);
      expect(catalog.recordFor('ghost'), isNull);
    });

    test('empty catalog behaves', () {
      final catalog = TheologyCatalog.empty();
      expect(catalog.isEmpty, isTrue);
      expect(catalog.records, isEmpty);
      expect(catalog.theologyIds, isEmpty);
      expect(catalog.totalDeityCount, 0);
      expect(catalog.theologyIdsWithDeityRole(DeityRole.war), isEmpty);
      expect(catalog.institutionIdsInvolvedInSchisms(), isEmpty);
    });

    test('theologyIdsWithDeityRole is deterministic and deduped', () {
      final catalog = TheologyCatalog.withRecords([
        _record(
          theologyId: 'z',
          deities: [_deity('d1', role: DeityRole.war)],
        ),
        _record(
          theologyId: 'a',
          deities: [
            _deity('d2', role: DeityRole.war),
            _deity('d3', role: DeityRole.nature),
          ],
        ),
      ]);
      expect(catalog.theologyIdsWithDeityRole(DeityRole.war), ['a', 'z']);
      expect(catalog.theologyIdsWithDeityRole(DeityRole.supreme), isEmpty);
    });

    test('institutionIdsInvolvedInSchisms aggregates sorted and deduped', () {
      final catalog = TheologyCatalog.withRecords([
        _record(
          theologyId: 'f1',
          institutions: [_institution('i-b'), _institution('i-a')],
          schisms: [
            _schism(
              's1',
              parentInstitutionId: 'i-b',
              offspringInstitutionId: 'i-a',
            ),
          ],
        ),
        _record(
          theologyId: 'f2',
          institutions: [_institution('i-a'), _institution('i-c')],
          schisms: [
            _schism(
              's2',
              parentInstitutionId: 'i-a',
              offspringInstitutionId: 'i-c',
            ),
          ],
        ),
      ]);
      expect(catalog.institutionIdsInvolvedInSchisms(), ['i-a', 'i-b', 'i-c']);
    });

    test('totalDeityCount sums across records', () {
      final catalog = TheologyCatalog.withRecords([
        _record(theologyId: 'a', deities: [_deity('d1'), _deity('d2')]),
        _record(theologyId: 'b', deities: [_deity('d3')]),
      ]);
      expect(catalog.totalDeityCount, 3);
    });

    test('query returns sorted subset', () {
      final catalog = TheologyCatalog.withRecords([
        _record(
          theologyId: 'z',
          deities: [_deity('d1', role: DeityRole.war)],
        ),
        _record(
          theologyId: 'a',
          deities: [_deity('d2', role: DeityRole.war)],
        ),
        _record(theologyId: 'm'),
      ]);
      final matched = catalog.query(const TheologyQuery(role: DeityRole.war));
      expect(matched.map((r) => r.theologyId), ['a', 'z']);
    });

    test('records view is immutable', () {
      final catalog = TheologyCatalog.withRecords([_record(theologyId: 'a')]);
      expect(
        () => catalog.records.add(_record(theologyId: 'b')),
        throwsUnsupportedError,
      );
    });
  });
}
