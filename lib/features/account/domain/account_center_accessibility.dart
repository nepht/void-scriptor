/// 115.7 — Accessibility Interaction Baseline.
///
/// Kontrak tunggal untuk focus order, keyboard behavior, semantics label,
/// text alternative chart, target sentuh, scaling, dan reduced motion di
/// Account & Cloud Center.
///
/// Sumber otoritatif: `account_cloud_center_spec.json`
/// (`accessibility.requirements` + `layout.density`), SHA-256
/// `f0589fe77428b94a608f44939df8bbd599e11b45d8605c59866ddaede99bd88a`.
/// Acceptance kanonik step 115.7 di `sprint_115.json`: `keyboard_complete`,
/// `visible_focus`, `screen_reader_labels`, `chart_text_alternative`,
/// `44px_touch_target`, `200_percent_scale`.
///
/// Audit AT native/keluar layar, kontras terukur, dan verifikasi seluruh
/// surface (dialog, chart, menu) tetap di 115.48; lokalisasi/pemanjangan teks
/// penuh di 115.49.
library;

import 'package:flutter/widgets.dart';

import 'account_center_design_tokens.dart';

/// Nama node fokus yang menyusun urutan traversal keyboard Account & Cloud
/// Center pada state default (guest, belum ada project aktif).
enum AccountCenterFocusTarget {
  /// Tombol pencarian header.
  search,

  /// Tombol notifikasi header (belum punya aksi → tidak dapat difokuskan).
  notifications,

  /// Tab IA aktif; gunakan slug tab sebagai identitas traversal.
  tab,

  /// Aksi sign-in pada kartu ringkasan akun.
  signIn,

  /// Action row pada kartu QUICK ACTIONS (mis. Sync Now / Backup Project).
  quickAction,
}

/// Kontrak aksesibilitas yang dipakai domain, widget, dan test.
abstract final class AccountCenterAccessibility {
  /// Path manifest bukti 115.7 di repo.
  static const String manifestPath =
      'docs/planning/v1.2/sprint_115_accessibility_interaction_baseline.json';

  /// Path domain untuk manifest `domain`.
  static const String domainPath =
      'lib/features/account/domain/account_center_accessibility.dart';

  static const List<String> testPaths = <String>[
    'test/features/account/domain/account_center_accessibility_test.dart',
    'test/features/account/presentation/'
        'account_cloud_center_accessibility_test.dart',
  ];

  /// Sumber product spec (identik dengan kontrak 115.5/115.6).
  static const String specDocument = AccountCenterDesignTokens.specDocument;
  static const String specSha256 = AccountCenterDesignTokens.specSha256;

  /// Sumber sprint kanonik; test memaku acceptance 115.7 lewat hash ini.
  static const String canonicalSprintPath =
      'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/'
      'sprint_115.json';
  static const String canonicalSprintSha256 =
      'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba';

  /// Target sentuh minimum spec (`layout.density.minimum_touch_target_px`).
  static const double minimumTouchTarget = 44;

  /// Target keyboard minimum spec (`layout.density.minimum_keyboard_target_px`).
  static const double minimumKeyboardTarget = 32;

  /// Skala teks maksimum yang harus didukung (`UI supports 200 percent
  /// scaling and text expansion`).
  static const double maximumSupportedTextScale = 2.0;

  /// Lebar focus ring tab strip (px) — kontras terhadap teks & underline.
  static const double tabFocusRingWidth = 2;

  /// Enam acceptance kanonik 115.7 sesuai `sprint_115.json`.
  static const List<String> canonicalAcceptance = <String>[
    'keyboard_complete',
    'visible_focus',
    'screen_reader_labels',
    'chart_text_alternative',
    '44px_touch_target',
    '200_percent_scale',
  ];

  /// Delapan butir `spec.accessibility.requirements` verbatim.
  static const List<String> specRequirements = <String>[
    'Complete keyboard navigation and visible focus.',
    'Provider name and connection status announced as text.',
    'Charts include data table or textual summary.',
    'Progress bars expose used, quota, percentage, and freshness.',
    'Color is not the only carrier of connection or health state.',
    'UI supports 200 percent scaling and text expansion.',
    'Reduced-motion mode disables decorative motion.',
    'Touch targets are at least 44 by 44 px.',
  ];

  /// Urutan fokus header → tab → aksi, memakai slug tab kanonik.
  static const List<({AccountCenterFocusTarget target, String? tabSlug})>
  defaultFocusOrder = <({AccountCenterFocusTarget target, String? tabSlug})>[
    (target: AccountCenterFocusTarget.search, tabSlug: null),
    (target: AccountCenterFocusTarget.notifications, tabSlug: null),
    (target: AccountCenterFocusTarget.tab, tabSlug: 'overview'),
    (target: AccountCenterFocusTarget.tab, tabSlug: 'connected_accounts'),
    (target: AccountCenterFocusTarget.tab, tabSlug: 'cloud_storage'),
    (target: AccountCenterFocusTarget.tab, tabSlug: 'ai_providers'),
    (target: AccountCenterFocusTarget.tab, tabSlug: 'api_keys'),
    (target: AccountCenterFocusTarget.tab, tabSlug: 'team_collaboration'),
    (target: AccountCenterFocusTarget.tab, tabSlug: 'security'),
    (target: AccountCenterFocusTarget.tab, tabSlug: 'backup_sync'),
    (target: AccountCenterFocusTarget.tab, tabSlug: 'billing'),
    (target: AccountCenterFocusTarget.signIn, tabSlug: null),
  ];

  /// Label semantics untuk ikon header yang tidak punya teks child.
  static const String searchSemanticsLabel = 'Search account sections';
  static const String notificationsSemanticsLabel =
      'Notifications (coming soon)';

  /// Nama node fokus yang dapat menerima traversal keyboard.
  ///
  /// `notifications` sengaja tidak dapat difokuskan: tombolnya `null` action
  /// dan akan diumumkan sebagai label non-interaktif saja, bukan stop
  /// keyboard trap.
  static bool isFocusable(AccountCenterFocusTarget target) =>
      target != AccountCenterFocusTarget.notifications;

  /// Semantics label provider = "name, status" (spec: provider name AND
  /// connection status announced as text). Argumen kosong ditolak fail-closed
  /// agar status tidak pernah hilang diam-diam.
  static String providerSemanticsLabel(String name, String status) {
    final trimmedName = name.trim();
    final trimmedStatus = status.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
    if (trimmedStatus.isEmpty) {
      throw ArgumentError.value(status, 'status', 'must not be empty');
    }
    return '$trimmedName, $trimmedStatus';
  }

  /// Textual summary chart yang boleh diumumkan sebagai alternatif Semantics.
  ///
  /// Judul wajib agar screen reader tahu card mana yang dibaca; facts boleh
  /// kosong (chart belum punya data) tapi TIDAK boleh berisi string kosong di
  /// tengah daftar.
  static String chartTextAlternative({
    required String title,
    required Iterable<String> facts,
  }) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'must not be empty');
    }
    final cleanFacts = facts
        .map((fact) => fact.trim())
        .where((fact) => fact.isNotEmpty)
        .toList(growable: false);
    if (cleanFacts.isEmpty) {
      return trimmedTitle;
    }
    return '$trimmedTitle. ${cleanFacts.join(' ')}';
  }

  /// Skala teks yang didukung widget test. Nilai non-finite, <= 0, atau di atas
  /// [maximumSupportedTextScale] ditolak fail-closed.
  static double validateTextScale(double scale) {
    if (!scale.isFinite || scale <= 0) {
      throw ArgumentError.value(
        scale,
        'scale',
        'must be a finite positive text scale',
      );
    }
    if (scale > maximumSupportedTextScale) {
      throw ArgumentError.value(
        scale,
        'scale',
        'must not exceed $maximumSupportedTextScale (200 percent scaling)',
      );
    }
    return scale;
  }

  /// Mode reduced motion dari ambient MediaQuery.
  ///
  /// Account & Cloud Center sendiri tidak menjalankan animasi dekoratif, jadi
  /// nilai ini menjadi satu-satunya sumber keputusan ketika chrome animatif
  /// (115.45-115.47) ditambahkan: `true` → gerak dekoratif dimatikan.
  static bool reducedMotion(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  /// Actionable widget harus >= [minimumTouchTarget] tinggi & lebar.
  ///
  /// Widget non-interaktif (label teks, kartu informatif) tidak dipatok; test
  /// memanggil helper ini hanya untuk `onTap`/`onPressed` non-null.
  static bool meetsTouchTarget(Size size) =>
      size.width >= minimumTouchTarget && size.height >= minimumTouchTarget;

  /// Tab strip (tinggi 40) harus >= [minimumKeyboardTarget].
  static bool meetsKeyboardTarget(Size size) =>
      size.height >= minimumKeyboardTarget;
}
