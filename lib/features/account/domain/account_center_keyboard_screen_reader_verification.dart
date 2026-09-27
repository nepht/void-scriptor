/// 115.48 — Keyboard & Screen Reader Verification.
///
/// Kontrak audit keyboard/pembaca layar untuk Account & Cloud Center.
///
/// Enam `required_evidence` kanonik step 115.48 di `sprint_115.json`
/// (SHA-256 `c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba`):
/// `focus_order`, `keyboard_results`, `screen_reader_results`,
/// `status_announcements`, `dialog_results`, `chart_alternatives`.
///
/// Objective kanonik: "Verify all tabs, cards, provider tiles, charts, menus,
/// dialogs, forms, and sensitive actions." Delapan permukaan itu dipin
/// [auditedSurfaceKinds] dan audit TIDAK pernah dianggap lengkap bila satu
/// permukaan saja belum punya bukti.
///
/// Prinsip fail-closed yang dipegang file ini:
/// * entri navigasi struktural tidak boleh diumumkan `button` tanpa aksi —
///   affordance palsu adalah cacat aksesibilitas, bukan gain;
/// * perubahan status yang terlihat (tab, drawer, sheet, hasil search) wajib
///   punya pengumuman; diam adalah kegagalan, bukan hemat;
/// * field form wajib punya label, bukan hanya `hintText`;
/// * aksi sensitif yang tidak diekspos dilaporkan `notExposed`, bukan
///   `PASS`. Sertifikasi AT native, kontras terukur, dan audit lintas
///   viewport penuh tetap di luar cakupan lokal (lihat [deferredExternal]).
///
/// Label provider TIDAK dikarang di sini: pengumuman sheet memakai
/// [AccountCenterAccessibility.providerSemanticsLabel] yang sama dengan
/// `_ProviderTile`, jadi tile dan sheet tidak mungkin berbeda.
///
/// Murni Dart (tanpa `package:flutter`) supaya domain test bisa memvalidasi
/// manifest `docs/planning/v1.2/sprint_115_keyboard_screen_reader_verification.json`.
library;

import 'account_center_accessibility.dart';
import 'account_center_design_tokens.dart';
import 'account_center_information_architecture.dart';

/// Satu permukaan yang wajib diaudit pada step 115.48, sesuai objective
/// kanonik. Urutan == urutan kalimat pada objective.
enum AccountCenterSurfaceKind {
  /// Sembilan tab IA.
  tab,

  /// Kartu ringkasan/dashboard.
  card,

  /// Tile provider pada QUICK CONNECT.
  providerTile,

  /// Chart AI usage dan storage distribution.
  chart,

  /// Menu navigasi (rail kiri, rail terlipat, navigasi atas).
  menu,

  /// Dialog pencarian bagian akun.
  dialog,

  /// Field isian (dialog pencarian).
  form,

  /// Aksi sensitif dari `security_contract.sensitive_actions`.
  sensitiveAction,
}

/// Tingkat paparan aksi sensitif terhadap verifikasi 115.48.
enum AccountCenterSensitiveExposure {
  /// Aksi belum diekspos di permukaan — tidak boleh diklaim terverifikasi.
  notExposed,

  /// Aksi diekspos tanpa reauth: fail-closed, belum terverifikasi.
  exposedWithoutReauth,

  /// Diekspos dengan reauth, tetapi belum ada bukti screen reader native.
  exposedWithReauth,
}

/// Hasil audit sensitivity yang HONEST: [isVerified] hanya mungkin `true`
/// bila setiap aksi yang diekspos punya reauth; empty default tetap
/// `notExposed` + belum terverifikasi.
final class AccountCenterSensitiveExposureReport {
  const AccountCenterSensitiveExposureReport({
    required this.state,
    required this.verified,
    required this.unverified,
  });

  final AccountCenterSensitiveExposure state;

  /// Aksi yang benar-benar punya reauth.
  final List<String> verified;

  /// Aksi diekspos tetapi belum terverifikasi (paling sering: belum di-reauth).
  final List<String> unverified;

  /// Audit lokal tidak pernah menyatakan PASS untuk aksi sensitif: bukti
  ///ell'sAT native berada di luar cakupan (lihat [deferredExternal]).
  bool get isVerified => false;
}

/// Hasil audit alternatif teks chart.
final class AccountCenterChartAlternativeAudit {
  const AccountCenterChartAlternativeAudit({
    required this.missing,
    required this.mislabeled,
    required this.alternatives,
  });

  /// Chart wajib yang tidak punya alternatif teks sama sekali.
  final List<String> missing;

  /// Chart yang punya alternatif tapi tidak menyebut judulnya, sehingga
  /// pembaca layar tidak tahu card mana yang sedang dibaca.
  final List<String> mislabeled;

  /// Alternatif teks yang diamankan, per judul chart.
  final Map<String, String> alternatives;

  /// Lengkap hanya bila tidak ada chart hilang maupun salah label.
  bool get isComplete => missing.isEmpty && mislabeled.isEmpty;
}

/// Hasil audit cakupan seluruh permukaan 115.48.
final class AccountCenterKeyboardScreenReaderAudit {
  const AccountCenterKeyboardScreenReaderAudit({
    required this.covered,
    required this.uncovered,
    required this.evidence,
  });

  /// Permukaan yang punya bukti.
  final Set<AccountCenterSurfaceKind> covered;

  /// Permukaan tanpa bukti — dilaporkan apa adanya, bukan disembunyikan.
  final List<AccountCenterSurfaceKind> uncovered;

  /// Bucket `required_evidence` yang dipakai.
  final Set<String> evidence;

  /// Audit lengkap hanya bila DELAPAN permukaan punya bukti. Enam bucket
  /// evidence tanpa bukti permukaan tidak pernah-DDUP: `focus_order` +
  /// `chart_alternatives` tidak membuktikan menu/dialog/form/aksi sensitif.
  bool get isComplete => uncovered.isEmpty;
}

/// Semantics navigasi struktural: label boleh, `button` hanya bila ada aksi.
final class AccountCenterNavigationEntrySemantics {
  const AccountCenterNavigationEntrySemantics({
    required this.label,
    required this.button,
  });

  final String label;

  /// Hanya `true` bila entri benar-benar dapat diaktifkan.
  final bool button;
}

/// Kontrak audit keyboard & pembaca layar 115.48.
abstract final class AccountCenterKeyboardScreenReader {
  /// Path manifest bukti 115.48 di repo.
  static const String manifestPath =
      'docs/planning/v1.2/sprint_115_keyboard_screen_reader_verification.json';

  /// Path domain untuk manifest `domain`.
  static const String domainPath =
      'lib/features/account/domain/account_center_keyboard_screen_reader_verification.dart';

  static const List<String> testPaths = <String>[
    'test/features/account/domain/'
        'account_center_keyboard_screen_reader_verification_test.dart',
    'test/features/account/presentation/'
        'account_cloud_center_keyboard_screen_reader_test.dart',
  ];

  static const String specDocument = AccountCenterDesignTokens.specDocument;
  static const String specSha256 = AccountCenterDesignTokens.specSha256;

  static const String canonicalSprintPath =
      'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/'
      'sprint_115.json';
  static const String canonicalSprintSha256 =
      'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba';

  /// Objective kanonik 115.48 verbatim dari `sprint_115.json`.
  static const String canonicalObjective =
      'Verify all tabs, cards, provider tiles, charts, menus, dialogs, '
      'forms, and sensitive actions.';

  /// Enam `required_evidence` kanonik, berurutan.
  static const List<String> canonicalRequiredEvidence = <String>[
    'focus_order',
    'keyboard_results',
    'screen_reader_results',
    'status_announcements',
    'dialog_results',
    'chart_alternatives',
  ];

  /// Alias: required_evidence 115.48 inilah acceptance step-nya.
  static const List<String> canonicalAcceptance = canonicalRequiredEvidence;

  /// Delapan permukaan wajib menurut [canonicalObjective].
  static const List<AccountCenterSurfaceKind> auditedSurfaceKinds =
      <AccountCenterSurfaceKind>[
        AccountCenterSurfaceKind.tab,
        AccountCenterSurfaceKind.card,
        AccountCenterSurfaceKind.providerTile,
        AccountCenterSurfaceKind.chart,
        AccountCenterSurfaceKind.menu,
        AccountCenterSurfaceKind.dialog,
        AccountCenterSurfaceKind.form,
        AccountCenterSurfaceKind.sensitiveAction,
      ];

  /// Gate yang TIDAK boleh diklaim PASS dari bukti lokal.
  static const List<String> deferredExternal = <String>[
    'native_screen_reader_certification',
    'measured_contrast',
    'hosted_ci',
    'public_trust_signing',
    'production_telemetry',
    'hardware',
    'adoption',
    'publication',
  ];

  /// Tujuh aksi sensitif dari `security_contract.sensitive_actions`.
  static const List<String> sensitiveActions = <String>[
    'reveal_or_replace_key',
    'disconnect_provider',
    'delete_cloud_backup',
    'change_billing',
    'remove_team_member',
    'export_account_data',
    'delete_account',
  ];

  /// Chart yang wajib punya alternatif teks (dipin dari 115.7/115.47).
  static const List<String> requiredChartAlternatives = <String>[
    'AI USAGE THIS MONTH',
    'STORAGE DISTRIBUTION',
  ];

  /// Label field pencarian. `hintText` saja tidak cukup: hint hilang begitu
  /// pengguna mengetik, jadi pembaca layar harus punya label permanen.
  static const String searchFieldLabel = 'Search tabs and sections';

  /// Hint tetap ada sebagai bantuan visual; label di atas yang wajib.
  static const String searchFieldHint = 'Type a section name';

  /// Tombol yang menutup dialog tanpa mouse.
  static const List<String> dismissKeys = <String>['Escape'];

  /// Ukuran target hasil dialog, dalam px. Record (bukan `Size`) supaya file
  /// ini tetap murni Dart tanpa dependensi `package:flutter` — sama seperti
  /// `referenceViewport` pada kontrak grid 115.6. Lebar 320 = lebar minimum
  /// dialog spec; tinggi 44 = `density.minimum_touch_target_px` 115.7.
  static ({double width, double height}) get searchResultTargetSize =>
      const (width: 320, height: 44);

  /// `dialog_results`: tinggi target hasil dialog >= 44px.
  static bool get searchResultTargetIsReachable =>
      searchResultTargetSize.height >=
      AccountCenterAccessibility.minimumTouchTarget;

  /// Urutan fokus yang diharapkan: header, sembilan tab, aksi sign-in.
  ///
  /// Diturunkan dari [AccountCenterAccessibility.defaultFocusOrder] agar
  /// 115.48 tidak memperkenalkan urutan fokus kedua yang bisa menyimpang dari
  /// 115.7. Entri yang [AccountCenterAccessibility.isFocusable] nyatakan false
  /// TIDAK ikut: notifikasi belum punya aksi, jadi menghitungnya sebagai focus
  /// stop akan mengarang stop yang tidak ada.
  static List<({AccountCenterFocusTarget target, String? tabSlug})>
  get expectedFocusStops =>
      <({AccountCenterFocusTarget target, String? tabSlug})>[
        for (final stop in AccountCenterAccessibility.defaultFocusOrder)
          if (AccountCenterAccessibility.isFocusable(stop.target)) stop,
      ];

  /// Audit cakupan: permukaan tanpa bukti dilaporkan apa adanya.
  ///
  /// [evidence] harus berasal dari [canonicalRequiredEvidence]; bucket di luar
  /// daftar itu ditolak fail-closed supaya laporan tidak bisa "memenuhi"
  /// cakupan dengan bukti yang tidak relevan.
  static AccountCenterKeyboardScreenReaderAudit audit({
    required Set<AccountCenterSurfaceKind> audited,
    Iterable<String> evidence = canonicalRequiredEvidence,
  }) {
    final buckets = evidence.toSet();
    final unknown = buckets.difference(canonicalRequiredEvidence.toSet());
    if (unknown.isNotEmpty) {
      throw ArgumentError.value(
        unknown.join(', '),
        'evidence',
        'must all be canonical 115.48 required_evidence buckets',
      );
    }
    final remaining = Set<AccountCenterSurfaceKind>.of(audited);
    final uncovered = <AccountCenterSurfaceKind>[
      for (final kind in auditedSurfaceKinds)
        if (!remaining.remove(kind)) kind,
    ];
    final covered = auditedSurfaceKinds.where(audited.contains).toSet();
    return AccountCenterKeyboardScreenReaderAudit(
      covered: covered,
      uncovered: uncovered,
      evidence: Set<String>.unmodifiable(buckets),
    );
  }

  /// Validasi urutan fokus: setiap tab IA tepat satu kali, target
  /// non-interaktif tidak boleh jadi focus stop, dan tabel kosong ditolak.
  static void validateFocusOrder(
    List<({AccountCenterFocusTarget target, String? tabSlug})> order,
  ) {
    if (order.isEmpty) {
      throw ArgumentError.value(order, 'order', 'must not be empty');
    }
    final canonicalSlugs = AccountCenterInformationArchitecture.tabs
        .map((tab) => tab.slug)
        .toList();
    final seen = <String>{};
    final seenStops = <String>{};
    for (final stop in order) {
      final identity = '${stop.target.name}:${stop.tabSlug ?? ''}';
      if (!seenStops.add(identity)) {
        throw ArgumentError.value(
          identity,
          'order',
          'must not repeat a focus stop',
        );
      }
      switch (stop.target) {
        case AccountCenterFocusTarget.tab:
          final slug = stop.tabSlug;
          if (slug == null || !canonicalSlugs.contains(slug)) {
            throw ArgumentError.value(
              slug,
              'order',
              'tab focus stop must carry a slug from the canonical IA',
            );
          }
          if (!seen.add(slug)) {
            throw ArgumentError.value(
              slug,
              'order',
              'must not repeat a tab focus stop',
            );
          }
        case AccountCenterFocusTarget.search:
        case AccountCenterFocusTarget.signIn:
        case AccountCenterFocusTarget.quickAction:
          break;
        case AccountCenterFocusTarget.notifications:
          throw StateError(
            'notifications is not a focus stop by design (no action yet)',
          );
      }
    }
    if (seen.length != canonicalSlugs.length) {
      throw ArgumentError.value(
        seen.length,
        'order',
        'must cover all ${canonicalSlugs.length} canonical IA tabs',
      );
    }
  }

  /// Guard focusability: entri yang tidak dapat diaktifkan tidak boleh
  /// diklaim dapat difokuskan.
  static ({AccountCenterFocusTarget target, String? tabSlug}) requireFocusable(
    ({AccountCenterFocusTarget target, String? tabSlug}) stop, {
    required bool actionable,
  }) {
    if (!actionable &&
        stop.target != AccountCenterFocusTarget.tab &&
        stop.target != AccountCenterFocusTarget.signIn) {
      throw StateError('${stop.target} is not focusable without an action');
    }
    return stop;
  }

  /// Affordance jujur: entri navigasi struktural hanya boleh diklaim
  /// `button` bila punya aksi nyata.
  static bool navigationEntryMayClaimButton({required bool actionable}) =>
      actionable;

  /// Semantics navigasi struktural yang jujur.
  static AccountCenterNavigationEntrySemantics navigationEntrySemantics({
    required String label,
    required bool actionable,
  }) {
    final normalized = label.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(label, 'label', 'must not be empty');
    }
    return AccountCenterNavigationEntrySemantics(
      label: normalized,
      button: navigationEntryMayClaimButton(actionable: actionable),
    );
  }

  /// Pengumuman perpindahan tab.
  static String tabSelectedAnnouncement(String tabLabel) {
    final normalized = tabLabel.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(tabLabel, 'tabLabel', 'must not be empty');
    }
    return '$normalized tab selected';
  }

  /// Pengumuman drawer ringkasan — keduanya terdengar, bukan hanya yang buka.
  static String summaryDrawerAnnouncement({required bool open}) =>
      open ? 'Account summary shown' : 'Account summary hidden';

  /// Pengumuman sheet detail provider.
  ///
  /// Label provider dibangun dari [AccountCenterAccessibility
  /// .providerSemanticsLabel] yang sama dengan `_ProviderTile`, jadi sheet
  /// dan tile tidak bisa berbeda.
  static String providerDetailsAnnouncement({
    required String name,
    required String status,
    required bool opening,
  }) {
    final label = AccountCenterAccessibility.providerSemanticsLabel(
      name,
      status,
    );
    return opening
        ? 'Provider details opened. $label'
        : 'Provider details closed. $label';
  }

  /// Pengumuman jumlah hasil pencarian, bentuk jamak benar dan nol
  /// memakai kalimat yang sama dengan teks terlihat.
  static String searchResultsAnnouncement(int count) {
    if (count < 0) {
      throw ArgumentError.value(count, 'count', 'must not be negative');
    }
    if (count == 0) {
      return 'No account sections match that search.';
    }
    return count == 1
        ? '1 account section matches that search.'
        : '$count account sections match that search.';
  }

  /// Label field form wajib ada dan non-kosong.
  static String requireFieldLabel(String? label) {
    final normalized = label?.trim() ?? '';
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        label,
        'label',
        'form field must carry a non-empty label for screen readers',
      );
    }
    return normalized;
  }

  /// Hanya tombol yang memang menutup dialog yang diterima.
  static String requireDismissKey(String key) {
    final normalized = key.trim();
    if (!dismissKeys.contains(normalized)) {
      throw ArgumentError.value(
        key,
        'key',
        'must be one of $dismissKeys so the dialog can close without a mouse',
      );
    }
    return normalized;
  }

  /// Audit alternatif teks chart: chart hilang dan chart salah label
  /// dilaporkan terpisah supaya sumber kekurangannya jelas.
  static AccountCenterChartAlternativeAudit auditChartAlternatives(
    Map<String, String> alternatives,
  ) {
    final missing = <String>[];
    final mislabeled = <String>[];
    final secured = <String, String>{};
    for (final title in requiredChartAlternatives) {
      final alternative = alternatives[title]?.trim() ?? '';
      if (alternative.isEmpty) {
        missing.add(title);
        continue;
      }
      if (!alternative.contains(title)) {
        mislabeled.add(title);
        continue;
      }
      secured[title] = alternative;
    }
    return AccountCenterChartAlternativeAudit(
      missing: List<String>.unmodifiable(missing),
      mislabeled: List<String>.unmodifiable(mislabeled),
      alternatives: Map<String, String>.unmodifiable(secured),
    );
  }

  /// Paparan aksi sensitif — fail-closed dan tidak pernah PASS.
  ///
  /// Nama aksi di luar [sensitiveActions] ditolak agar laporan tidak bisa
  /// memuat aksi karangan.
  static AccountCenterSensitiveExposureReport assessSensitiveActionExposure({
    required Set<String> performed,
    Set<String> reauthenticated = const <String>{},
  }) {
    final unknown = <String>{
      ...performed,
      ...reauthenticated,
    }.difference(sensitiveActions.toSet());
    if (unknown.isNotEmpty) {
      throw ArgumentError.value(
        unknown.join(', '),
        'performed',
        'must all be canonical spec sensitive actions',
      );
    }
    final unverified = performed.difference(reauthenticated).toList()..sort();
    if (performed.isEmpty) {
      return AccountCenterSensitiveExposureReport(
        state: AccountCenterSensitiveExposure.notExposed,
        verified: const <String>[],
        unverified: List<String>.unmodifiable(sensitiveActions),
      );
    }
    if (reauthenticated.isEmpty) {
      return AccountCenterSensitiveExposureReport(
        state: AccountCenterSensitiveExposure.exposedWithoutReauth,
        verified: const <String>[],
        unverified: List<String>.unmodifiable(unverified),
      );
    }
    return AccountCenterSensitiveExposureReport(
      state: AccountCenterSensitiveExposure.exposedWithReauth,
      verified: List<String>.unmodifiable(
        performed.intersection(reauthenticated).toList()..sort(),
      ),
      unverified: List<String>.unmodifiable(unverified),
    );
  }
}
