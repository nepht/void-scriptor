// Sprint 111.34 - Cultural Ownership & Usage Context (domain-only).
//
// Acceptance canonical sprint_111.json dipetakan:
// - regions      -> IdiomRegionRef (wilayah pemakaian + stance)
// - cultures     -> IdiomCultureRef (budaya pemakai/penghindar)
// - factions     -> IdiomFactionRef (role ScopeFactionRole 111.5 + stance)
// - professions  -> IdiomProfessionRef (profesi penutur)
// - eras         -> IdiomEraRange (marker cerita + sequence rank, 111.27/30)
// - contexts     -> IdiomContextUsage atas SocialContext 111.30
// - register     -> IdiomRegister ladder formalitas + registerFor(context)
//
// "Pihak yang menghindari ungkapan" dimodelkan lewat IdiomUseStance.avoided
// pada tiap facet, bukan tabel terpisah. Murni data + query deterministik:
// pemeriksaan konsistensi/anakronisme milik 111.36, bukan slice ini.
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_idiom_usage.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_name_profiles.dart'
    show SocialContext;
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_scope.dart'
    show ScopeFactionRole;

IdiomRegionRef region(
  String id, {
  IdiomUseStance stance = IdiomUseStance.common,
}) => IdiomRegionRef.validated(regionId: id, stance: stance);

IdiomCultureRef culture(
  String id, {
  IdiomUseStance stance = IdiomUseStance.common,
}) => IdiomCultureRef.validated(cultureId: id, stance: stance);

IdiomFactionRef faction(
  String id, {
  ScopeFactionRole role = ScopeFactionRole.owning,
  IdiomUseStance stance = IdiomUseStance.common,
}) => IdiomFactionRef.validated(factionId: id, role: role, stance: stance);

IdiomProfessionRef profession(
  String id, {
  IdiomUseStance stance = IdiomUseStance.common,
}) => IdiomProfessionRef.validated(professionId: id, stance: stance);

IdiomEraRange era(String id, {String? toMarker, int? sequence}) =>
    IdiomEraRange.validated(
      eraId: id,
      label: 'Era $id',
      fromMarker: 'm01',
      toMarker: toMarker,
      sequence: sequence,
    );

IdiomContextUsage contextUsage(SocialContext ctx, IdiomRegister register) =>
    IdiomContextUsage.validated(context: ctx, register: register);

IdiomUsageProfile profile(
  String idiomId, {
  List<IdiomRegionRef> regions = const <IdiomRegionRef>[],
  List<IdiomCultureRef> cultures = const <IdiomCultureRef>[],
  List<IdiomFactionRef> factions = const <IdiomFactionRef>[],
  List<IdiomProfessionRef> professions = const <IdiomProfessionRef>[],
  List<IdiomEraRange> eras = const <IdiomEraRange>[],
  List<IdiomContextUsage> contexts = const <IdiomContextUsage>[],
  IdiomRegister defaultRegister = IdiomRegister.neutral,
  String note = '',
}) => IdiomUsageProfile.validated(
  idiomId: idiomId,
  defaultRegister: defaultRegister,
  regions: regions,
  cultures: cultures,
  factions: factions,
  professions: professions,
  eras: eras,
  contexts: contexts,
  note: note,
);

void main() {
  group('IdiomUseStance', () {
    test('setiap stance punya label non-kosong', () {
      for (final s in IdiomUseStance.values) {
        expect(s.label.trim(), isNotEmpty);
        expect(s.name, isNotEmpty);
      }
    });

    test('weight ladder unik dan menaik sesuai urutan enum', () {
      final weights = IdiomUseStance.values.map((s) => s.weight).toList();
      expect(weights.toSet().length, weights.length);
      for (var i = 1; i < weights.length; i++) {
        expect(weights[i], greaterThan(weights[i - 1]));
      }
    });

    test('hanya avoided yang menandai penghindaran', () {
      for (final s in IdiomUseStance.values) {
        expect(s.isAvoidance, s == IdiomUseStance.avoided);
      }
    });
  });

  group('IdiomRegister', () {
    test('formalitas menaik ketat sepanjang enum', () {
      for (var i = 1; i < IdiomRegister.values.length; i++) {
        expect(
          IdiomRegister.values[i].formality,
          greaterThan(IdiomRegister.values[i - 1].formality),
        );
      }
    });

    test('label non-kosong dan atLeast/refleksif konsisten', () {
      for (final r in IdiomRegister.values) {
        expect(r.label.trim(), isNotEmpty);
        expect(r.atLeast(r), isTrue);
        expect(r.moreFormalThan(r), isFalse);
      }
    });

    test('perbandingan formalitas dua arah', () {
      expect(IdiomRegister.formal.atLeast(IdiomRegister.colloquial), isTrue);
      expect(IdiomRegister.colloquial.atLeast(IdiomRegister.formal), isFalse);
      expect(
        IdiomRegister.formal.moreFormalThan(IdiomRegister.colloquial),
        isTrue,
      );
    });
  });

  group('ref facet kepemilikan', () {
    test('region: id wajib non-kosong dan dipangkas', () {
      final r = region('  northern-isles  ');
      expect(r.regionId, 'northern-isles');
      expect(() => region('   '), throwsArgumentError);
    });

    test('region: stance default common dan note dipangkas', () {
      final r = IdiomRegionRef.validated(regionId: 'r1', note: '  hi  ');
      expect(r.stance, IdiomUseStance.common);
      expect(r.note, 'hi');
    });

    test('culture dan profession menolak id blank', () {
      expect(() => culture(''), throwsArgumentError);
      expect(() => profession('  '), throwsArgumentError);
    });

    test('faction menyimpan role 111.5 dan stance', () {
      final f = faction(
        'guild-of-scribes',
        role: ScopeFactionRole.influencedBy,
        stance: IdiomUseStance.avoided,
      );
      expect(f.factionId, 'guild-of-scribes');
      expect(f.role, ScopeFactionRole.influencedBy);
      expect(f.stance.isAvoidance, isTrue);
      expect(() => faction(' '), throwsArgumentError);
    });

    test('ref facet punya equality struktural dan hashCode', () {
      expect(region('a'), region('a'));
      expect(region('a').hashCode, region('a').hashCode);
      expect(region('a', stance: IdiomUseStance.avoided), isNot(region('a')));
      expect(culture('a'), isNot(profession('a')));
    });

    test('ref facet toJson/fromJson roundtrip', () {
      final values = <Object>[
        region('r', stance: IdiomUseStance.primary),
        culture('c', stance: IdiomUseStance.avoided),
        faction('f', role: ScopeFactionRole.opposedTo),
        profession('p', stance: IdiomUseStance.occasional),
      ];
      for (final v in values) {
        final json = (v as dynamic).toJson() as Map<String, Object?>;
        final back = (v as dynamic).runtimeType == IdiomRegionRef
            ? IdiomRegionRef.fromJson(json)
            : (v as dynamic).runtimeType == IdiomCultureRef
            ? IdiomCultureRef.fromJson(json)
            : (v as dynamic).runtimeType == IdiomFactionRef
            ? IdiomFactionRef.fromJson(json)
            : IdiomProfessionRef.fromJson(json);
        expect(back, v);
      }
    });
  });

  group('IdiomEraRange', () {
    test('eraId, label, dan fromMarker wajib non-kosong', () {
      expect(
        () => IdiomEraRange.validated(eraId: '', label: 'x', fromMarker: 'm01'),
        throwsArgumentError,
      );
      expect(
        () =>
            IdiomEraRange.validated(eraId: 'e', label: ' ', fromMarker: 'm01'),
        throwsArgumentError,
      );
      expect(
        () => IdiomEraRange.validated(eraId: 'e', label: 'x', fromMarker: ' '),
        throwsArgumentError,
      );
    });

    test('toMarker ongoing dan describe', () {
      final ongoing = era('e1');
      expect(ongoing.isOngoing, isTrue);
      expect(ongoing.describe(), contains('ongoing'));
      final closed = era('e2', toMarker: 'm08');
      expect(closed.isOngoing, isFalse);
      expect(closed.describe(), contains('m01..m08'));
    });

    test('toMarker blank ditolak, null diterima', () {
      expect(
        () => IdiomEraRange.validated(
          eraId: 'e',
          label: 'x',
          fromMarker: 'm01',
          toMarker: '  ',
        ),
        throwsArgumentError,
      );
    });

    test('coversMarker inklusif leksikografis pada marker ter-zero-pad', () {
      final e = IdiomEraRange.validated(
        eraId: 'e',
        label: 'x',
        fromMarker: 'm02',
        toMarker: 'm05',
      );
      expect(e.coversMarker('m01'), isFalse);
      expect(e.coversMarker('m02'), isTrue);
      expect(e.coversMarker(' m04 '), isTrue);
      expect(e.coversMarker('m05'), isTrue);
      expect(e.coversMarker('m06'), isFalse);
    });

    test('compare menempatkan sequence null terakhir lalu eraId', () {
      final a = era('a', sequence: 1);
      final b = era('b', sequence: 2);
      final c = era('c');
      final sorted = <IdiomEraRange>[c, b, a]..sort(IdiomEraRange.compare);
      expect(sorted.map((e) => e.eraId), <String>['a', 'b', 'c']);
      expect(IdiomEraRange.compare(a, a), 0);
    });

    test('era roundtrip JSON dan equality', () {
      final e = era('e7', toMarker: 'm09', sequence: 3);
      expect(IdiomEraRange.fromJson(e.toJson()), e);
      expect(e.hashCode, era('e7', toMarker: 'm09', sequence: 3).hashCode);
    });
  });

  group('IdiomContextUsage', () {
    test('register wajib ada dan note dipangkas', () {
      final u = IdiomContextUsage.validated(
        context: SocialContext.formal,
        register: IdiomRegister.formal,
        note: '  court  ',
      );
      expect(u.context, SocialContext.formal);
      expect(u.register, IdiomRegister.formal);
      expect(u.note, 'court');
    });

    test('contextUsage roundtrip JSON dan equality', () {
      final u = contextUsage(SocialContext.sacred, IdiomRegister.ceremonial);
      expect(IdiomContextUsage.fromJson(u.toJson()), u);
      expect(
        u,
        isNot(contextUsage(SocialContext.sacred, IdiomRegister.neutral)),
      );
    });
  });

  group('IdiomUsageProfile.validated', () {
    test('idiomId wajib non-kosong dan dipangkas', () {
      expect(
        () => IdiomUsageProfile.validated(idiomId: '  '),
        throwsArgumentError,
      );
      expect(profile(' idm-1 ').idiomId, 'idm-1');
    });

    test('facet kosong diperbolehkan (sengaja longgar, mirror 111.5)', () {
      final p = profile('idm-1');
      expect(p.regionCount, 0);
      expect(p.hasAnyFacet, isFalse);
      expect(p.usedInRegion('anything'), isTrue);
      expect(p.usedByCulture('anything'), isTrue);
    });

    test('duplikat regionId ditolak toleran kasus dan whitespace', () {
      expect(
        () => profile(
          'idm-1',
          regions: <IdiomRegionRef>[region('north'), region(' NORTH ')],
        ),
        throwsArgumentError,
      );
    });

    test('duplikat cultureId, professionId, dan eraId ditolak', () {
      expect(
        () => profile(
          'idm-1',
          cultures: <IdiomCultureRef>[culture('c'), culture('c')],
        ),
        throwsArgumentError,
      );
      expect(
        () => profile(
          'idm-1',
          professions: <IdiomProfessionRef>[profession('p'), profession('P')],
        ),
        throwsArgumentError,
      );
      expect(
        () => profile('idm-1', eras: <IdiomEraRange>[era('e'), era('e')]),
        throwsArgumentError,
      );
    });

    test('factionId wajib unik lintas role', () {
      expect(
        () => profile(
          'idm-1',
          factions: <IdiomFactionRef>[
            faction('f', role: ScopeFactionRole.owning),
            faction('f', role: ScopeFactionRole.controlling),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => profile(
          'idm-1',
          factions: <IdiomFactionRef>[
            faction('f1'),
            faction('f2', role: ScopeFactionRole.opposedTo),
          ],
        ),
        returnsNormally,
      );
    });

    test('satu SocialContext hanya boleh punya satu register', () {
      expect(
        () => profile(
          'idm-1',
          contexts: <IdiomContextUsage>[
            contextUsage(SocialContext.formal, IdiomRegister.formal),
            contextUsage(SocialContext.formal, IdiomRegister.neutral),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('koleksi profil immutable', () {
      final p = profile('idm-1', regions: <IdiomRegionRef>[region('r')]);
      expect(() => p.regions.add(region('r2')), throwsUnsupportedError);
      expect(() => p.eras.add(era('e')), throwsUnsupportedError);
      expect(
        () => p.contexts.add(
          contextUsage(SocialContext.sacred, IdiomRegister.ceremonial),
        ),
        throwsUnsupportedError,
      );
    });

    test('count per facet akurat', () {
      final p = profile(
        'idm-1',
        regions: <IdiomRegionRef>[region('r1'), region('r2')],
        cultures: <IdiomCultureRef>[culture('c1')],
        factions: <IdiomFactionRef>[faction('f1')],
        professions: <IdiomProfessionRef>[profession('p1'), profession('p2')],
        eras: <IdiomEraRange>[era('e1')],
        contexts: <IdiomContextUsage>[
          contextUsage(SocialContext.formal, IdiomRegister.formal),
        ],
      );
      expect(p.regionCount, 2);
      expect(p.cultureCount, 1);
      expect(p.factionCount, 1);
      expect(p.professionCount, 2);
      expect(p.eraCount, 1);
      expect(p.contextCount, 1);
      expect(p.hasAnyFacet, isTrue);
    });
  });

  group('IdiomUsageProfile lookup', () {
    final p = profile(
      'idm-1',
      regions: <IdiomRegionRef>[
        region('isle', stance: IdiomUseStance.primary),
        region('waste', stance: IdiomUseStance.avoided),
      ],
      cultures: <IdiomCultureRef>[
        culture('salt-folk', stance: IdiomUseStance.common),
        culture('court', stance: IdiomUseStance.avoided),
      ],
      factions: <IdiomFactionRef>[
        faction(
          'singers',
          role: ScopeFactionRole.owning,
          stance: IdiomUseStance.primary,
        ),
        faction('inquisitors', role: ScopeFactionRole.opposedTo),
      ],
      professions: <IdiomProfessionRef>[
        profession('sailor', stance: IdiomUseStance.primary),
        profession('notary', stance: IdiomUseStance.occasional),
      ],
      eras: <IdiomEraRange>[
        IdiomEraRange.validated(
          eraId: 'e-mid',
          label: 'Middle',
          fromMarker: 'm03',
          toMarker: 'm06',
          sequence: 2,
        ),
      ],
      contexts: <IdiomContextUsage>[
        contextUsage(SocialContext.ceremonial, IdiomRegister.ceremonial),
        contextUsage(SocialContext.everyday, IdiomRegister.colloquial),
      ],
      defaultRegister: IdiomRegister.neutral,
    );

    test('lookup ref per facet toleran whitespace', () {
      expect(p.regionFor(' ISLE ')?.stance, IdiomUseStance.primary);
      expect(p.cultureFor('court')?.stance, IdiomUseStance.avoided);
      expect(p.factionFor('singers')?.role, ScopeFactionRole.owning);
      expect(p.professionFor('notary')?.stance, IdiomUseStance.occasional);
      expect(p.eraFor('e-mid')?.label, 'Middle');
      expect(
        p.contextUsageFor(SocialContext.everyday)?.register,
        IdiomRegister.colloquial,
      );
    });

    test('lookup id tak dikenal mengembalikan null', () {
      expect(p.regionFor('unknown'), isNull);
      expect(p.cultureFor(''), isNull);
      expect(p.factionFor('nope'), isNull);
      expect(p.professionFor('  '), isNull);
      expect(p.eraFor('nope'), isNull);
      expect(p.contextUsageFor(SocialContext.secret), isNull);
    });

    test('predikat pemakaian menghormati stance avoided', () {
      expect(p.usedInRegion('isle'), isTrue);
      expect(p.usedInRegion('waste'), isFalse);
      expect(p.avoidedByRegion('waste'), isTrue);
      expect(p.usedByCulture('court'), isFalse);
      expect(p.avoidedByCulture('court'), isTrue);
      expect(p.usedWithFaction('inquisitors'), isTrue);
      expect(p.usedByProfession('sailor'), isTrue);
    });

    test('registerFor memakai override konteks lalu default', () {
      expect(p.registerFor(SocialContext.ceremonial), IdiomRegister.ceremonial);
      expect(p.registerFor(SocialContext.everyday), IdiomRegister.colloquial);
      expect(p.registerFor(SocialContext.sacred), IdiomRegister.neutral);
    });

    test('usableIn: kosong = bebas, terisi = whitelist', () {
      expect(p.usableIn(SocialContext.formal), isFalse);
      expect(p.usableIn(SocialContext.everyday), isTrue);
      expect(profile('idm-2').usableIn(SocialContext.secret), isTrue);
    });

    test('activeAtMarker memakai rentang era; kosong = selalu aktif', () {
      expect(p.activeAtMarker('m02'), isFalse);
      expect(p.activeAtMarker('m04'), isTrue);
      expect(p.activeAtMarker('m07'), isFalse);
      expect(profile('idm-2').activeAtMarker('m99'), isTrue);
    });

    test('kumpulan id tersusun per stance', () {
      expect(p.primaryRegionIds, <String>['isle']);
      expect(p.avoidedCultureIds, <String>['court']);
      expect(p.primaryProfessionIds, <String>['sailor']);
      expect(p.roleForFaction('singers'), ScopeFactionRole.owning);
      expect(p.factionRoleIds(ScopeFactionRole.opposedTo), <String>[
        'inquisitors',
      ]);
    });

    test('effectiveStanceFor dan facets menghindari memayungi semua facet', () {
      expect(
        p.effectiveStanceFor(IdiomOwnershipFacet.region, 'waste'),
        IdiomUseStance.avoided,
      );
      expect(
        p.effectiveStanceFor(IdiomOwnershipFacet.profession, 'sailor'),
        IdiomUseStance.primary,
      );
      expect(
        p.effectiveStanceFor(IdiomOwnershipFacet.culture, 'unknown'),
        isNull,
      );
      expect(p.avoidingFacets, <String>['culture:court', 'region:waste']);
      expect(p.hasAvoiders, isTrue);
    });

    test('kumpulan id gabungan terurut dan dedup per facet', () {
      expect(p.allRegionIds, containsAll(<String>['isle', 'waste']));
      expect(p.allCultureIds, <String>['court', 'salt-folk']);
      expect(p.allProfessionIds, <String>['notary', 'sailor']);
      expect(p.eraIds, <String>['e-mid']);
      expect(p.usedContexts, <SocialContext>{
        SocialContext.ceremonial,
        SocialContext.everyday,
      });
    });
  });

  group('IdiomUsageProfile serialisasi', () {
    test('toJson memuat seluruh facet dan fromJson bolak-balik', () {
      final p = profile(
        'idm-9',
        regions: <IdiomRegionRef>[region('r1')],
        cultures: <IdiomCultureRef>[
          culture('c1', stance: IdiomUseStance.avoided),
        ],
        factions: <IdiomFactionRef>[
          faction('f1', role: ScopeFactionRole.alliedWith),
        ],
        professions: <IdiomProfessionRef>[profession('p1')],
        eras: <IdiomEraRange>[era('e1', toMarker: 'm05', sequence: 1)],
        contexts: <IdiomContextUsage>[
          contextUsage(SocialContext.secret, IdiomRegister.honorific),
        ],
        defaultRegister: IdiomRegister.formal,
        note: '  dicatat  ',
      );
      final json = p.toJson();
      expect(json['idiomId'], 'idm-9');
      expect(json['defaultRegister'], 'formal');
      expect(json['regions'], hasLength(1));
      expect(IdiomUsageProfile.fromJson(json), p);
      expect(
        jsonEncode(p.toJson()),
        jsonEncode(IdiomUsageProfile.fromJson(json).toJson()),
      );
    });

    test('fromJson menolak record tanpa idiomId', () {
      expect(
        () => IdiomUsageProfile.fromJson(<String, Object?>{'note': 'x'}),
        throwsA(anything),
      );
    });

    test('profil dengan facet sama setara; id berbeda tidak', () {
      final a = profile('idm-a', regions: <IdiomRegionRef>[region('r')]);
      final b = profile('idm-a', regions: <IdiomRegionRef>[region('r')]);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a,
        isNot(profile('idm-b', regions: <IdiomRegionRef>[region('r')])),
      );
    });

    test('toString menyebut idiomId', () {
      expect(profile('idm-z').toString(), contains('idm-z'));
    });
  });

  group('IdiomOwnershipFacet', () {
    test('empat facet kepemilikan dengan label non-kosong', () {
      expect(IdiomOwnershipFacet.values, hasLength(4));
      for (final f in IdiomOwnershipFacet.values) {
        expect(f.label.trim(), isNotEmpty);
      }
    });
  });

  group('IdiomUsageCatalog', () {
    final catalog = IdiomUsageCatalog.withProfiles(<IdiomUsageProfile>[
      profile(
        'idm-b',
        regions: <IdiomRegionRef>[
          region('isle'),
          region('waste', stance: IdiomUseStance.avoided),
        ],
        cultures: <IdiomCultureRef>[
          culture('salt-folk', stance: IdiomUseStance.primary),
        ],
        professions: <IdiomProfessionRef>[profession('sailor')],
        eras: <IdiomEraRange>[
          IdiomEraRange.validated(
            eraId: 'e-old',
            label: 'Old',
            fromMarker: 'm01',
            toMarker: 'm04',
            sequence: 1,
          ),
        ],
        contexts: <IdiomContextUsage>[
          contextUsage(SocialContext.everyday, IdiomRegister.colloquial),
        ],
      ),
      profile(
        'idm-a',
        regions: <IdiomRegionRef>[
          region('isle', stance: IdiomUseStance.common),
        ],
        factions: <IdiomFactionRef>[
          faction('singers', stance: IdiomUseStance.avoided),
        ],
        defaultRegister: IdiomRegister.formal,
      ),
    ]);

    test('catalog kosong valid', () {
      expect(IdiomUsageCatalog.empty().profileCount, 0);
      expect(IdiomUsageCatalog.empty().profiles, isEmpty);
      expect(IdiomUsageCatalog.empty().profileFor('x'), isNull);
    });

    test('idiomId wajib unik lintas profil', () {
      expect(
        () => IdiomUsageCatalog.withProfiles(<IdiomUsageProfile>[
          profile('idm-x'),
          profile('idm-x'),
        ]),
        throwsArgumentError,
      );
    });

    test('profiles terurut idiomId dan immutable', () {
      expect(catalog.idiomIds, <String>['idm-a', 'idm-b']);
      expect(
        () => catalog.profiles.add(profile('idm-c')),
        throwsUnsupportedError,
      );
    });

    test('lookup profil toleran whitespace', () {
      expect(catalog.profileFor(' idm-b ')?.idiomId, 'idm-b');
      expect(catalog.profileFor(''), isNull);
    });

    test('agregasi id lintas profil terurut dedup', () {
      expect(catalog.regionIds, <String>['isle', 'waste']);
      expect(catalog.cultureIds, <String>['salt-folk']);
      expect(catalog.factionIds, <String>['singers']);
      expect(catalog.professionIds, <String>['sailor']);
      expect(catalog.eraIds, <String>['e-old']);
      expect(catalog.ownerIds(IdiomOwnershipFacet.culture), <String>[
        'salt-folk',
      ]);
    });

    test('ownerIds mengecualikan pihak yang menghindari', () {
      expect(catalog.ownerIds(IdiomOwnershipFacet.region), <String>['isle']);
      expect(catalog.avoiderIds(IdiomOwnershipFacet.region), <String>['waste']);
      expect(catalog.avoiderIds(IdiomOwnershipFacet.faction), <String>[
        'singers',
      ]);
      expect(catalog.avoiderIds(IdiomOwnershipFacet.profession), isEmpty);
    });

    test('reverse index per facet deterministic', () {
      expect(catalog.idiomsUsedInRegion('isle'), <String>['idm-a', 'idm-b']);
      expect(catalog.idiomsAvoidedInRegion('waste'), <String>['idm-b']);
      // idm-a tidak mendeklarasikan facet budaya/profesi sama sekali,
      // sehingga secara kontrak ia TIDAK membatasi pihak manapun (111.5).
      expect(catalog.idiomsUsedByCulture('salt-folk'), <String>[
        'idm-a',
        'idm-b',
      ]);
      expect(catalog.idiomsUsedByProfession('sailor'), <String>[
        'idm-a',
        'idm-b',
      ]);
      expect(catalog.idiomsAvoidedByCulture('court'), isEmpty);
      expect(catalog.idiomsAvoidedByFaction('singers'), <String>['idm-a']);
      expect(catalog.idiomsAvoidedByProfession('sailor'), isEmpty);
      expect(catalog.idiomsUsedInRegion('nowhere'), isEmpty);
    });

    test('register agregat per konteks dan per bahasa wilayah', () {
      expect(catalog.contextCounts(), <SocialContext, int>{
        SocialContext.everyday: 1,
      });
      expect(catalog.registersInUse(), contains(IdiomRegister.formal));
      expect(catalog.registersInUse(), contains(IdiomRegister.colloquial));
      expect(catalog.mostFormalIdiomId(), 'idm-a');
      expect(IdiomUsageCatalog.empty().mostFormalIdiomId(), isNull);
    });

    test('totalReferrantCount menjumlah seluruh facet', () {
      // idm-b: 2 region + 1 budaya + 1 profesi + 1 era + 1 konteks = 6
      // idm-a: 1 region + 1 faksi = 2
      expect(catalog.totalReferrantCount, 8);
    });

    test('catalog roundtrip JSON mempertahankan urutan', () {
      final back = IdiomUsageCatalog.fromJson(
        jsonDecode(jsonEncode(catalog.toJson())) as Map<String, Object?>,
      );
      expect(back.idiomIds, catalog.idiomIds);
      expect(jsonEncode(back.toJson()), jsonEncode(catalog.toJson()));
    });

    test('toString menyebut jumlah profil', () {
      expect(catalog.toString(), contains('2'));
    });
  });

  group('IdiomUsageFilter', () {
    final catalog = IdiomUsageCatalog.withProfiles(<IdiomUsageProfile>[
      profile(
        'idm-1',
        regions: <IdiomRegionRef>[region('isle')],
        cultures: <IdiomCultureRef>[culture('salt-folk')],
        professions: <IdiomProfessionRef>[profession('sailor')],
        eras: <IdiomEraRange>[
          IdiomEraRange.validated(
            eraId: 'e-old',
            label: 'Old',
            fromMarker: 'm01',
            toMarker: 'm04',
            sequence: 1,
          ),
        ],
        contexts: <IdiomContextUsage>[
          contextUsage(SocialContext.everyday, IdiomRegister.colloquial),
        ],
      ),
      profile(
        'idm-2',
        cultures: <IdiomCultureRef>[
          culture('court', stance: IdiomUseStance.avoided),
        ],
        factions: <IdiomFactionRef>[faction('singers')],
        defaultRegister: IdiomRegister.formal,
        eras: <IdiomEraRange>[
          IdiomEraRange.validated(
            eraId: 'e-new',
            label: 'New',
            fromMarker: 'm05',
            sequence: 2,
          ),
        ],
      ),
    ]);

    test('filter kosong meloloskan semua profil', () {
      const f = IdiomUsageFilter();
      expect(f.isEmpty, isTrue);
      expect(f.apply(catalog).map((p) => p.idiomId), <String>[
        'idm-1',
        'idm-2',
      ]);
      expect(f.describe(), contains('semua'));
    });

    test('filter idiomId tunggal', () {
      const f = IdiomUsageFilter(idiomId: 'idm-2');
      expect(f.apply(catalog).map((p) => p.idiomId), <String>['idm-2']);
    });

    test('filter region/culture/faction/profession di-AND-kan', () {
      const f = IdiomUsageFilter(regionId: 'isle', cultureId: 'salt-folk');
      expect(f.apply(catalog).map((p) => p.idiomId), <String>['idm-1']);
      const miss = IdiomUsageFilter(regionId: 'isle', cultureId: 'court');
      expect(miss.apply(catalog), isEmpty);
    });

    test('filter konteks dan marker era', () {
      // idm-2 tidak mendeklarasikan konteks -> tidak membatasi (lolos).
      const f = IdiomUsageFilter(context: SocialContext.everyday);
      expect(f.apply(catalog).map((p) => p.idiomId), <String>[
        'idm-1',
        'idm-2',
      ]);
      // konteks yang DILARANG profil terbatas: idm-1 punya daftar konteks
      // eksplisit tanpa `sacred` -> tersaring keluar.
      const restricted = IdiomUsageFilter(context: SocialContext.sacred);
      expect(restricted.apply(catalog).map((p) => p.idiomId), <String>[
        'idm-2',
      ]);
      const atMarker = IdiomUsageFilter(atMarker: 'm06');
      expect(atMarker.apply(catalog).map((p) => p.idiomId), <String>['idm-2']);
      expect(
        const IdiomUsageFilter(
          atMarker: 'm02',
        ).apply(catalog).map((p) => p.idiomId),
        <String>['idm-1'],
      );
    });

    test('filter jendela formalitas memakai register efektif konteks', () {
      const f = IdiomUsageFilter(
        context: SocialContext.everyday,
        maxFormality: IdiomRegister.neutral,
      );
      expect(f.apply(catalog).map((p) => p.idiomId), <String>['idm-1']);
      const hi = IdiomUsageFilter(minFormality: IdiomRegister.formal);
      expect(hi.apply(catalog).map((p) => p.idiomId), <String>['idm-2']);
    });

    test('requireAvoidance hanya profil dengan penghindaran', () {
      const f = IdiomUsageFilter(requireAvoidance: true);
      expect(f.apply(catalog).map((p) => p.idiomId), <String>['idm-2']);
      const owned = IdiomUsageFilter(
        facet: IdiomOwnershipFacet.culture,
        requireAvoidance: true,
      );
      expect(owned.apply(catalog).map((p) => p.idiomId), <String>['idm-2']);
    });

    test('describe menyebut tiap filter aktif', () {
      const f = IdiomUsageFilter(
        regionId: 'isle',
        context: SocialContext.sacred,
        minFormality: IdiomRegister.formal,
        requireAvoidance: true,
      );
      final d = f.describe();
      expect(d, contains('region=isle'));
      expect(d, contains('context='));
      expect(d, contains('minRegister='));
      expect(d, contains('avoided'));
      expect(f.isEmpty, isFalse);
    });

    test('apply hasil immutable dan terurut idiomId', () {
      const f = IdiomUsageFilter();
      final res = f.apply(catalog);
      expect(() => res.add(profile('idm-3')), throwsUnsupportedError);
    });

    test('filter dengan id blank diperlakukan sebagai tanpa filter', () {
      const f = IdiomUsageFilter(regionId: '   ');
      expect(f.isEmpty, isTrue);
      expect(f.apply(catalog).length, 2);
    });
  });
}
