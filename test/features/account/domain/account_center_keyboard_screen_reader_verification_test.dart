import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_accessibility.dart';
import 'package:void_scriptor/features/account/domain/account_center_design_tokens.dart';
import 'package:void_scriptor/features/account/domain/account_center_information_architecture.dart';
import 'package:void_scriptor/features/account/domain/account_center_keyboard_screen_reader_verification.dart';

/// 115.48 — Keyboard & Screen Reader Verification (bagian domain).
///
/// Audit ini SENGAJA data-only dan fail-closed: setiap permukaan yang
/// tidak punya bukti keyboard/pembaca layar dihitung `uncovered`, bukan
/// lolos. Sertifikasi AT native, kontras terukur, dan audit bercabang
/// multi-viewport tetap di luar cakupan lokal ini.
void main() {
  group('115.48 canonical required_evidence', () {
    test('enam bucket kanonik 115.48 ter-pin dan urut', () {
      expect(
        AccountCenterKeyboardScreenReader.canonicalRequiredEvidence,
        <String>[
          'focus_order',
          'keyboard_results',
          'screen_reader_results',
          'status_announcements',
          'dialog_results',
          'chart_alternatives',
        ],
      );
      expect(
        AccountCenterKeyboardScreenReader.canonicalAcceptance,
        AccountCenterKeyboardScreenReader.canonicalRequiredEvidence,
      );
    });

    test(
      'sumber kanonik + spec di-pin SHA-256 yang sama seperti kontrak 115.5-115.47',
      () {
        // SHA-256 yang sama seperti AccountCenterDesignTokens (115.5) dan
        // AccountCenterAccessibility (115.7): kalau sprint_115.json atau spec
        // diganti, kontrak ini harus ikut gagal loudly, bukan diam-diam memakai
        // sumber lain.
        expect(
          AccountCenterKeyboardScreenReader.canonicalSprintSha256,
          AccountCenterAccessibility.canonicalSprintSha256,
        );
        expect(
          AccountCenterKeyboardScreenReader.specSha256,
          AccountCenterDesignTokens.specSha256,
        );
        expect(
          AccountCenterKeyboardScreenReader.canonicalSprintSha256,
          'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba',
        );
        expect(
          AccountCenterKeyboardScreenReader.specSha256,
          'f0589fe77428b94a608f44939df8bbd599e11b45d8605c59866ddaede99bd88a',
        );
      },
    );

    test('objective 115.48 verbatim: delapan permukaan wajib diaudit', () {
      expect(
        AccountCenterKeyboardScreenReader.canonicalObjective,
        'Verify all tabs, cards, provider tiles, charts, menus, dialogs, '
        'forms, and sensitive actions.',
      );
      expect(
        AccountCenterKeyboardScreenReader.auditedSurfaceKinds,
        <AccountCenterSurfaceKind>[
          AccountCenterSurfaceKind.tab,
          AccountCenterSurfaceKind.card,
          AccountCenterSurfaceKind.providerTile,
          AccountCenterSurfaceKind.chart,
          AccountCenterSurfaceKind.menu,
          AccountCenterSurfaceKind.dialog,
          AccountCenterSurfaceKind.form,
          AccountCenterSurfaceKind.sensitiveAction,
        ],
      );
    });
  });

  group('115.48 focus_order', () {
    test('urutan fokus default menutupi sembilan tab IA tepat satu kali', () {
      final order = AccountCenterKeyboardScreenReader.expectedFocusStops;
      final tabSlugs = order
          .where((stop) => stop.target == AccountCenterFocusTarget.tab)
          .map((stop) => stop.tabSlug)
          .toList();
      expect(
        tabSlugs,
        AccountCenterInformationArchitecture.tabs
            .map((tab) => tab.slug)
            .toList(),
        reason: 'sembilan tab IA harus muncul sekali, dalam urutan kanonik',
      );
    });

    test('notifikasi non-interaktif tidak pernah menjadi focus stop', () {
      expect(
        AccountCenterKeyboardScreenReader.expectedFocusStops.any(
          (stop) => stop.target == AccountCenterFocusTarget.notifications,
        ),
        isFalse,
        reason: '115.7: tombol notifikasi belum punya aksi → bukan focus stop',
      );
    });

    test(
      'validateFocusOrder menolak duplikat, tabel kosong, dan tab tak dikenal',
      () {
        final valid = AccountCenterKeyboardScreenReader.expectedFocusStops
            .toList();
        expect(
          () => AccountCenterKeyboardScreenReader.validateFocusOrder(valid),
          returnsNormally,
        );

        expect(
          () => AccountCenterKeyboardScreenReader.validateFocusOrder(
            <({AccountCenterFocusTarget target, String? tabSlug})>[],
          ),
          throwsArgumentError,
        );

        final duplicated =
            <({AccountCenterFocusTarget target, String? tabSlug})>[
              for (final stop in valid) stop,
              valid.last,
            ];
        expect(
          () =>
              AccountCenterKeyboardScreenReader.validateFocusOrder(duplicated),
          throwsArgumentError,
          reason: 'focus stop ganda = urutan traversal ambigu',
        );

        final unknownTab =
            <({AccountCenterFocusTarget target, String? tabSlug})>[
              for (final stop in valid)
                if (stop.tabSlug == 'billing')
                  (target: AccountCenterFocusTarget.tab, tabSlug: 'not_a_tab')
                else
                  stop,
            ];
        expect(
          () =>
              AccountCenterKeyboardScreenReader.validateFocusOrder(unknownTab),
          throwsArgumentError,
          reason: 'slug tab di luar IA kanonik harus fail-closed',
        );
      },
    );

    test('tab non-interaktif (tanpa aksi) tidak boleh diklaim fokus', () {
      expect(
        () => AccountCenterKeyboardScreenReader.requireFocusable((
          target: AccountCenterFocusTarget.notifications,
          tabSlug: null,
        ), actionable: false),
        throwsStateError,
      );
      expect(
        () => AccountCenterKeyboardScreenReader.requireFocusable((
          target: AccountCenterFocusTarget.tab,
          tabSlug: 'overview',
        ), actionable: false),
        returnsNormally,
      );
    });
  });

  group('115.48 screen_reader_results — affordance jujur', () {
    test('entri navigasi struktural tidak boleh diklaim sebagai button', () {
      // 115.45/115.46/115.48: rail kiri, rail terlipat, dan navigasi atas
      // TIDAK punya callback apa pun. `Semantics(button: true)` di sana
      // mengNXcep pembaca layar "tombol" yang tidak melakukan apa-apa.
      expect(
        AccountCenterKeyboardScreenReader.navigationEntryMayClaimButton(
          actionable: false,
        ),
        isFalse,
      );
      expect(
        AccountCenterKeyboardScreenReader.navigationEntryMayClaimButton(
          actionable: true,
        ),
        isTrue,
      );
    });

    test('entri navigasi struktural tetap terbaca sebagai daftar section', () {
      expect(
        AccountCenterKeyboardScreenReader.navigationEntrySemantics(
          label: 'Connected Services',
          actionable: false,
        ).button,
        isFalse,
      );
      expect(
        AccountCenterKeyboardScreenReader.navigationEntrySemantics(
          label: 'Connected Services',
          actionable: false,
        ).label,
        'Connected Services',
      );
    });

    test('label kosong ditolak fail-closed (bukan label kosong diumumkan)', () {
      expect(
        () => AccountCenterKeyboardScreenReader.navigationEntrySemantics(
          label: '   ',
          actionable: false,
        ),
        throwsArgumentError,
      );
    });
  });

  group('115.48 status_announcements', () {
    test('perpindahan tab mengumumkan tab yang dipilih', () {
      expect(
        AccountCenterKeyboardScreenReader.tabSelectedAnnouncement('Overview'),
        'Overview tab selected',
      );
    });

    test('pengumuman tab menolak label kosong', () {
      expect(
        () => AccountCenterKeyboardScreenReader.tabSelectedAnnouncement(' '),
        throwsArgumentError,
      );
    });

    test(
      'drawer bunyi announcing dibuka ATAU ditutup, tidak pernah senyap',
      () {
        expect(
          AccountCenterKeyboardScreenReader.summaryDrawerAnnouncement(
            open: true,
          ),
          'Account summary shown',
        );
        expect(
          AccountCenterKeyboardScreenReader.summaryDrawerAnnouncement(
            open: false,
          ),
          'Account summary hidden',
        );
      },
    );

    test(
      'sheet provider memakai builder label yang sama dengan tile (115.7)',
      () {
        final announcement =
            AccountCenterKeyboardScreenReader.providerDetailsAnnouncement(
              name: 'OpenAI',
              status: 'Not connected',
              opening: true,
            );
        expect(announcement, contains('OpenAI'));
        expect(announcement, contains('Not connected'));
        expect(
          announcement,
          contains(
            AccountCenterAccessibility.providerSemanticsLabel(
              'OpenAI',
              'Not connected',
            ),
          ),
          reason: 'satu sumber label; tile dan sheet tidak boleh berbeda',
        );
        expect(
          AccountCenterKeyboardScreenReader.providerDetailsAnnouncement(
            name: 'OpenAI',
            status: 'Not connected',
            opening: false,
          ),
          contains('closed'),
        );
      },
    );

    test('pengumuman sheet menolak nama/status kosong', () {
      expect(
        () => AccountCenterKeyboardScreenReader.providerDetailsAnnouncement(
          name: '',
          status: 'Not connected',
          opening: true,
        ),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterKeyboardScreenReader.providerDetailsAnnouncement(
          name: 'OpenAI',
          status: '',
          opening: true,
        ),
        throwsArgumentError,
      );
    });

    test('jumlah hasil search diumumkan dengan bentuk jamak yang benar', () {
      expect(
        AccountCenterKeyboardScreenReader.searchResultsAnnouncement(0),
        'No account sections match that search.',
      );
      expect(
        AccountCenterKeyboardScreenReader.searchResultsAnnouncement(1),
        '1 account section matches that search.',
      );
      expect(
        AccountCenterKeyboardScreenReader.searchResultsAnnouncement(4),
        '4 account sections match that search.',
      );
    });

    test('jumlah hasil search negatif ditolak (bukan "0 sections match")', () {
      expect(
        () => AccountCenterKeyboardScreenReader.searchResultsAnnouncement(-1),
        throwsArgumentError,
      );
    });
  });

  group('115.48 dialog_results', () {
    test('dialog search punya field berlabel, bukan hanya hint', () {
      expect(
        AccountCenterKeyboardScreenReader.searchFieldLabel,
        'Search tabs and sections',
      );
      expect(
        AccountCenterKeyboardScreenReader.searchFieldHint,
        'Type a section name',
      );
      expect(
        AccountCenterKeyboardScreenReader.requireFieldLabel(
          AccountCenterKeyboardScreenReader.searchFieldLabel,
        ),
        'Search tabs and sections',
      );
      expect(
        () => AccountCenterKeyboardScreenReader.requireFieldLabel(''),
        throwsArgumentError,
        reason: 'field tanpa label = pembaca layar tidak tahu apa yang diisi',
      );
    });

    test('Escape menutup dialog lewat DismissIntent yang disediakan app', () {
      expect(AccountCenterKeyboardScreenReader.dismissKeys, <String>['Escape']);
      expect(
        AccountCenterKeyboardScreenReader.requireDismissKey('Escape'),
        isNotNull,
      );
      expect(
        () => AccountCenterKeyboardScreenReader.requireDismissKey('F4'),
        throwsArgumentError,
      );
    });

    test('hasil dialog adalah target sentuh >= 44px', () {
      expect(
        AccountCenterKeyboardScreenReader.searchResultTargetSize.height,
        greaterThanOrEqualTo(AccountCenterAccessibility.minimumTouchTarget),
      );
      expect(
        AccountCenterKeyboardScreenReader.searchResultTargetIsReachable,
        isTrue,
      );
      expect(
        AccountCenterAccessibility.meetsTouchTarget(
          Size(
            AccountCenterKeyboardScreenReader.searchResultTargetSize.width,
            AccountCenterKeyboardScreenReader.searchResultTargetSize.height,
          ),
        ),
        isTrue,
      );
    });
  });

  group('115.48 chart_alternatives', () {
    test('dua chart wajib punya alternatif teks yang tidak boleh kosong', () {
      expect(
        AccountCenterKeyboardScreenReader.requiredChartAlternatives,
        <String>['AI USAGE THIS MONTH', 'STORAGE DISTRIBUTION'],
      );
      final audit = AccountCenterKeyboardScreenReader.auditChartAlternatives(
        const <String, String>{
          'AI USAGE THIS MONTH':
              'AI USAGE THIS MONTH. Prompt 120, completion 30.',
          'STORAGE DISTRIBUTION':
              'STORAGE DISTRIBUTION. Images 2.0 GB, text 0.4 GB.',
        },
      );
      expect(audit.isComplete, isTrue);
      expect(audit.missing, isEmpty);
      expect(audit.alternatives.length, 2);
    });

    test('chart tanpa alternatif atau alternatif kosong = belum lengkap', () {
      final audit = AccountCenterKeyboardScreenReader.auditChartAlternatives(
        const <String, String>{
          'AI USAGE THIS MONTH': 'AI USAGE THIS MONTH. Prompt 120.',
        },
      );
      expect(audit.isComplete, isFalse);
      expect(audit.missing, <String>['STORAGE DISTRIBUTION']);

      final blank = AccountCenterKeyboardScreenReader.auditChartAlternatives(
        const <String, String>{
          'AI USAGE THIS MONTH': 'AI USAGE THIS MONTH. Prompt 120.',
          'STORAGE DISTRIBUTION': '   ',
        },
      );
      expect(blank.isComplete, isFalse);
      expect(blank.missing, <String>['STORAGE DISTRIBUTION']);
    });

    test('alternatif yang tidak menyebut judul chart ditolak', () {
      final audit = AccountCenterKeyboardScreenReader.auditChartAlternatives(
        const <String, String>{
          'AI USAGE THIS MONTH': 'Some numbers without a heading.',
          'STORAGE DISTRIBUTION': 'STORAGE DISTRIBUTION. Images 2.0 GB.',
        },
      );
      expect(audit.mislabeled, <String>['AI USAGE THIS MONTH']);
      expect(audit.isComplete, isFalse);
    });
  });

  group('115.48 sensitive actions — laporan jujur', () {
    test('tujuh aksi sensitif spec 115.54 dikunci dari security_contract', () {
      expect(AccountCenterKeyboardScreenReader.sensitiveActions, <String>[
        'reveal_or_replace_key',
        'disconnect_provider',
        'delete_cloud_backup',
        'change_billing',
        'remove_team_member',
        'export_account_data',
        'delete_account',
      ]);
    });

    test('permukaan yang belum ada dilaporkan notExposed, bukan PASS', () {
      final exposure =
          AccountCenterKeyboardScreenReader.assessSensitiveActionExposure(
            performed: const <String>{},
          );
      expect(exposure.state, AccountCenterSensitiveExposure.notExposed);
      expect(exposure.isVerified, isFalse);
      expect(
        exposure.unverified,
        AccountCenterKeyboardScreenReader.sensitiveActions,
      );
    });

    test(
      'aksi sensitif tanpa reauth = fail-closed (bukan allege verified)',
      () {
        final exposure =
            AccountCenterKeyboardScreenReader.assessSensitiveActionExposure(
              performed: const <String>{'delete_account'},
              reauthenticated: const <String>{},
            );
        expect(
          exposure.state,
          AccountCenterSensitiveExposure.exposedWithoutReauth,
        );
        expect(exposure.isVerified, isFalse);
        expect(exposure.unverified, <String>['delete_account']);
      },
    );

    test('nama aksi di luar daftar spec ditolak fail-closed', () {
      expect(
        () => AccountCenterKeyboardScreenReader.assessSensitiveActionExposure(
          performed: const <String>{'drop_database'},
        ),
        throwsArgumentError,
      );
    });

    test('hanya aksi yang benar-benar di-reauth yang terverifikasi', () {
      final exposure =
          AccountCenterKeyboardScreenReader.assessSensitiveActionExposure(
            performed: const <String>{'delete_account', 'change_billing'},
            reauthenticated: const <String>{'delete_account'},
          );
      expect(exposure.state, AccountCenterSensitiveExposure.exposedWithReauth);
      expect(exposure.unverified, <String>['change_billing']);
      expect(exposure.isVerified, isFalse);
    });
  });

  group('115.48 audit report — fail-closed', () {
    test('permukaan tanpa bukti = uncovered, laporan belum lengkap', () {
      final report = AccountCenterKeyboardScreenReader.audit(
        audited: const <AccountCenterSurfaceKind>{
          AccountCenterSurfaceKind.tab,
          AccountCenterSurfaceKind.dialog,
        },
      );
      expect(report.isComplete, isFalse);
      expect(report.uncovered, <AccountCenterSurfaceKind>[
        AccountCenterSurfaceKind.card,
        AccountCenterSurfaceKind.providerTile,
        AccountCenterSurfaceKind.chart,
        AccountCenterSurfaceKind.menu,
        AccountCenterSurfaceKind.form,
        AccountCenterSurfaceKind.sensitiveAction,
      ]);
      expect(report.covered, <AccountCenterSurfaceKind>{
        AccountCenterSurfaceKind.tab,
        AccountCenterSurfaceKind.dialog,
      });
    });

    test('audit lengkap hanya bila delapan permukaan punya bukti', () {
      final report = AccountCenterKeyboardScreenReader.audit(
        audited: AccountCenterKeyboardScreenReader.auditedSurfaceKinds.toSet(),
      );
      expect(report.isComplete, isTrue);
      expect(report.uncovered, isEmpty);
    });

    test('bukti yang tidak dikenal tidak dihitung sebagai cakupan', () {
      // Enam bucket kanonik saja TIDAK membuktikan delapan permukaan: ini
      // justru bentuk laporan yang terlalu longgar, jadi harus tetap
      // `isComplete == false`.
      final report = AccountCenterKeyboardScreenReader.audit(
        audited: const <AccountCenterSurfaceKind>{},
        evidence: AccountCenterKeyboardScreenReader.canonicalRequiredEvidence,
      );
      expect(report.isComplete, isFalse);
      expect(report.uncovered.length, 8);
      expect(report.evidence, hasLength(6));
    });

    test('bucket bukti harus berasal dari required_evidence kanonik', () {
      expect(
        () => AccountCenterKeyboardScreenReader.audit(
          audited: AccountCenterKeyboardScreenReader.auditedSurfaceKinds
              .toSet(),
          evidence: const <String>{'made_up_bucket'},
        ),
        throwsArgumentError,
      );
    });
  });

  group('115.48 manifest bukti', () {
    test('manifest ada, valid, dan mengunci sumber + acceptance', () {
      final file = File(AccountCenterKeyboardScreenReader.manifestPath);
      expect(file.existsSync(), isTrue, reason: 'manifest 115.48 belum ada');
      final manifest =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(manifest['canonical_step'], '115.48');
      expect(
        (manifest['sources'] as Map<String, dynamic>)['canonical_steps']
            as Map<String, dynamic>,
        containsPair(
          'sha256',
          AccountCenterKeyboardScreenReader.canonicalSprintSha256,
        ),
      );

      final required = (manifest['required_evidence'] as Map<String, dynamic>)
          .keys
          .toList();
      expect(
        required,
        AccountCenterKeyboardScreenReader.canonicalRequiredEvidence,
        reason: 'enam bucket kanonik harus utuh dan berurutan di manifest',
      );

      for (final entry
          in (manifest['required_evidence'] as Map<String, dynamic>).entries) {
        expect(
          (entry.value as Map<String, dynamic>)['verified_by'],
          isNotEmpty,
          reason: '${entry.key} harus menyebut cara pembuktiannya',
        );
      }

      expect(manifest['domain'], AccountCenterKeyboardScreenReader.domainPath);
      expect(manifest['tests'], AccountCenterKeyboardScreenReader.testPaths);
      expect(
        manifest['deferred_external'],
        containsAll(<String>[
          'native_screen_reader_certification',
          'measured_contrast',
          'hosted_ci',
          'public_trust_signing',
          'production_telemetry',
          'hardware',
          'adoption',
          'publication',
        ]),
        reason: 'sertifikasi AT native tidak boleh diklaim PASS dari cron',
      );
    });
  });
}
