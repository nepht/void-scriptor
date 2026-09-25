/// Sprint 115.3 — Global Information Architecture contract.
///
/// Satu sumber kebenaran untuk route global Account & Cloud Center, sembilan
/// tab kanonik, deep link, breadcrumb, search index, dan profile shortcut.
/// Murni Dart tanpa dependensi Flutter supaya domain test bisa memvalidasi
/// manifest `docs/planning/v1.2/sprint_115_global_information_architecture.json`.
library;

/// Satu tab navigasi di Account & Cloud Center.
class AccountCenterTab {
  const AccountCenterTab({
    required this.slug,
    required this.label,
    required this.searchKeywords,
  });

  /// Nilai `?tab=` untuk deep link (slug kanonik dari product spec).
  final String slug;

  /// Label tab yang dirender di UI.
  final String label;

  /// Kata kunci pencarian (label/aksi/section terkait) untuk search index.
  final List<String> searchKeywords;
}

abstract final class AccountCenterInformationArchitecture {
  /// Route global kanonik sesuai product spec `account_cloud_center_spec.json`.
  static const String canonicalRoute = '/account/cloud-center';

  /// Alias lama; tetap diterima dan di-redirect ke kanonik tanpa kehilangan
  /// query (bookmark/deep-link lama tidak putus).
  static const String legacyRoute = '/account-cloud';

  /// Parameter query deep link tab, mis. `/account/cloud-center?tab=billing`.
  static const String tabQueryParameter = 'tab';

  /// Akar breadcrumb dua level (`root / tab label`).
  static const String breadcrumbRoot = 'Account & Cloud Center';

  /// Key navigasi profil (top-bar account menu) yang menunjuk route kanonik.
  static const String profileShortcutKey = 'account-cloud';

  /// Sembilan tab kanonik dalam urutan product spec.
  static const List<AccountCenterTab> tabs = <AccountCenterTab>[
    AccountCenterTab(
      slug: 'overview',
      label: 'Overview',
      searchKeywords: [
        'authentication',
        'quick connect',
        'activity',
        'summary',
        'overview',
      ],
    ),
    AccountCenterTab(
      slug: 'connected_accounts',
      label: 'Connected Accounts',
      searchKeywords: [
        'identity',
        'sign in',
        'google',
        'github',
        'oauth',
        'email',
      ],
    ),
    AccountCenterTab(
      slug: 'cloud_storage',
      label: 'Cloud Storage',
      searchKeywords: [
        'storage',
        'quota',
        'google drive',
        'onedrive',
        'dropbox',
        'backup',
      ],
    ),
    AccountCenterTab(
      slug: 'ai_providers',
      label: 'AI Providers',
      searchKeywords: ['openai', 'gemini', 'models', 'ai usage', 'gateway'],
    ),
    AccountCenterTab(
      slug: 'api_keys',
      label: 'API Keys',
      searchKeywords: [
        'credentials',
        'developer tools',
        'creative tools',
        'vault',
        'secrets',
      ],
    ),
    AccountCenterTab(
      slug: 'team_collaboration',
      label: 'Team & Collaboration',
      searchKeywords: ['members', 'seats', 'invitations', 'roles', 'team'],
    ),
    AccountCenterTab(
      slug: 'security',
      label: 'Security',
      searchKeywords: [
        'sessions',
        'mfa',
        'password',
        'activity log',
        'protection',
      ],
    ),
    AccountCenterTab(
      slug: 'backup_sync',
      label: 'Backup & Sync',
      searchKeywords: [
        'restore',
        'folder backup',
        'synchronization',
        'data protection',
      ],
    ),
    AccountCenterTab(
      slug: 'billing',
      label: 'Billing',
      searchKeywords: [
        'payment',
        'plan',
        'invoices',
        'credits',
        'subscription',
      ],
    ),
  ];

  /// Tab untuk slug deep link, atau `null` bila slug tidak dikenal (fail closed).
  static AccountCenterTab? tabForSlug(String? slug) {
    if (slug == null || slug.isEmpty) {
      return null;
    }
    for (final tab in tabs) {
      if (tab.slug == slug) {
        return tab;
      }
    }
    return null;
  }

  /// Resolusi tampilan: slug tak dikenal/hilang jatuh ke overview.
  static AccountCenterTab resolveTab(String? slug) =>
      tabForSlug(slug) ?? tabs.first;

  /// Deep link kanonik untuk satu tab.
  static String deepLinkFor(AccountCenterTab tab) =>
      '$canonicalRoute?$tabQueryParameter=${tab.slug}';

  /// Breadcrumb dua level: `[root, tab label]`.
  static List<String> breadcrumbsFor(AccountCenterTab tab) => <String>[
    breadcrumbRoot,
    tab.label,
  ];

  /// Search index tab: cocok label, slug, dan keyword tanpa memedulikan
  /// huruf besar/kecil. Query kosong -> seluruh tab (browse mode).
  static List<AccountCenterTab> search(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return List<AccountCenterTab>.unmodifiable(tabs);
    }
    return tabs
        .where(
          (tab) =>
              tab.label.toLowerCase().contains(normalized) ||
              tab.slug.contains(normalized) ||
              tab.searchKeywords.any(
                (keyword) => keyword.toLowerCase().contains(normalized),
              ),
        )
        .toList(growable: false);
  }
}
