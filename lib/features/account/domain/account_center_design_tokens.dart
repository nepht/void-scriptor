/// 115.5 — Account Center Design Tokens.
///
/// Sumber otoritatif: `account_cloud_center_spec.json` (document_role
/// `PRODUCT_UI_TECHNICAL_SPEC`), SHA-256
/// `f0589fe77428b94a608f44939df8bbd599e11b45d8605c59866ddaede99bd88a`.
/// Snapshot manifest di repo:
/// `docs/planning/v1.2/sprint_115_account_center_design_tokens.json`.
///
/// Kelompok wajib sesuai kontrak sprint 115.5 (`required_tokens`):
/// layout, spacing, radius, typography, icon_sizes, avatar_sizes,
/// progress_bar, density. Kelompok pendukung (card / provider_tile /
/// service_row) ditranskripsikan karena memuat ukuran yang juga disebut
/// product spec di bawah `visual_tokens`.
///
/// Nilai di sini TIDAK boleh diubah tanpa perubahan product spec: test
/// `test/features/account/domain/account_center_design_tokens_test.dart`
/// memaku setiap angka ke snapshot manifest dan (bila path sumber ada di
/// mesin ini) meng-hash ulang file spec.
library;

/// Layout: `spec.layout` (reference_desktop + breakpoints).
final class AccountCenterLayoutTokens {
  const AccountCenterLayoutTokens({
    this.viewportMinWidth = 1440,
    this.topBarHeight = 56,
    this.leftNavigationWidth = 192,
    this.rightSummaryWidth = 272,
    this.bottomStatusHeight = 40,
    this.pageHorizontalPadding = 16,
    this.pageVerticalPadding = 12,
    this.columnGap = 12,
    this.cardGap = 10,
    this.centerContentMinWidth = 900,
    this.headerHeight = 76,
    this.tabBarHeight = 40,
    this.breakpoints = const [
      (name: 'wide_desktop', minWidth: 1440.0, maxWidth: null),
      (name: 'desktop', minWidth: 1180.0, maxWidth: 1439.0),
      (name: 'compact_desktop', minWidth: 900.0, maxWidth: 1179.0),
      (name: 'tablet', minWidth: 600.0, maxWidth: 899.0),
      (name: 'mobile', minWidth: null, maxWidth: 599.0),
    ],
  });

  final double viewportMinWidth;
  final double topBarHeight;
  final double leftNavigationWidth;
  final double rightSummaryWidth;
  final double bottomStatusHeight;
  final double pageHorizontalPadding;
  final double pageVerticalPadding;
  final double columnGap;
  final double cardGap;
  final double centerContentMinWidth;
  final double headerHeight;
  final double tabBarHeight;

  /// `spec.layout.breakpoints` — `minWidth` null saat spec tidak menyebutnya.
  final List<({double? maxWidth, double? minWidth, String name})> breakpoints;
}

/// `spec.visual_tokens.spacing_px`.
final class AccountCenterSpacingTokens {
  const AccountCenterSpacingTokens({
    this.twoXs = 4,
    this.xs = 6,
    this.sm = 8,
    this.md = 12,
    this.lg = 16,
    this.xl = 24,
    this.twoXl = 32,
  });

  final double twoXs;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double twoXl;
}

/// `spec.visual_tokens.radius_px`.
final class AccountCenterRadiusTokens {
  const AccountCenterRadiusTokens({
    this.control = 6,
    this.tile = 8,
    this.card = 10,
    this.dialog = 12,
    this.pill = 999,
  });

  final double control;
  final double tile;
  final double card;
  final double dialog;
  final double pill;
}

/// `spec.visual_tokens.typography_px`.
final class AccountCenterTypographyTokens {
  const AccountCenterTypographyTokens({
    this.pageTitle = 20,
    this.sectionTitle = 12,
    this.body = 13,
    this.caption = 11,
    this.metric = 18,
  });

  final double pageTitle;
  final double sectionTitle;
  final double body;
  final double caption;
  final double metric;
}

/// `spec.visual_tokens` ikon: nav/action/section/page + tile/row/dot.
final class AccountCenterIconSizeTokens {
  const AccountCenterIconSizeTokens({
    this.navigation = 20,
    this.action = 20,
    this.section = 24,
    this.page = 36,
    this.providerTile = 28,
    this.serviceRow = 24,
    this.statusDot = 8,
  });

  final double navigation;
  final double action;
  final double section;
  final double page;
  final double providerTile;
  final double serviceRow;
  final double statusDot;
}

/// `spec.visual_tokens.profile_avatar`.
final class AccountCenterAvatarSizeTokens {
  const AccountCenterAvatarSizeTokens({
    this.image = 80,
    this.ring = 96,
    this.compact = 40,
  });

  final double image;
  final double ring;
  final double compact;
}

/// `spec.visual_tokens.progress_bar_height_px`.
final class AccountCenterProgressTokens {
  const AccountCenterProgressTokens({this.height = 8});

  final double height;
}

/// `spec.layout.density` (default, supported, target sentuh/keyboard).
final class AccountCenterDensityTokens {
  const AccountCenterDensityTokens({
    this.defaultDensity = 'COMFORTABLE',
    this.supported = const ['COMPACT', 'COMFORTABLE', 'SPACIOUS'],
    this.minimumTouchTarget = 44,
    this.minimumKeyboardTarget = 32,
  });

  final String defaultDensity;
  final List<String> supported;
  final double minimumTouchTarget;
  final double minimumKeyboardTarget;
}

/// `spec.visual_tokens.card`.
final class AccountCenterCardTokens {
  const AccountCenterCardTokens({this.minWidth = 220, this.padding = 14});

  final double minWidth;
  final double padding;
}

/// `spec.visual_tokens.provider_tile`.
final class AccountCenterProviderTileTokens {
  const AccountCenterProviderTileTokens({
    this.minHeight = 56,
    this.paddingX = 12,
    this.paddingY = 10,
    this.iconSize = 28,
    this.statusDot = 8,
  });

  final double minHeight;
  final double paddingX;
  final double paddingY;
  final double iconSize;
  final double statusDot;
}

/// `spec.visual_tokens.service_row`.
final class AccountCenterServiceRowTokens {
  const AccountCenterServiceRowTokens({
    this.minHeight = 44,
    this.iconSize = 24,
    this.gap = 10,
  });

  final double minHeight;
  final double iconSize;
  final double gap;
}

/// Registry tunggal kelompok token Account & Cloud Center.
abstract final class AccountCenterDesignTokens {
  /// Path snapshot manifest bukti 115.5 (di dalam repo).
  static const String manifestPath =
      'docs/planning/v1.2/sprint_115_account_center_design_tokens.json';

  /// Path sumber product spec (canonical archive; dipakai test untuk
  /// meng-hash ulang bila file ada di mesin ini).
  static const String specDocument =
      'C:/Users/nepht/Documents/Codex/2026-08-22/'
      'referenced-chatgpt-conversation-this-is-an-2/outputs/'
      'account_cloud_center_spec.json';

  static const String specSha256 =
      'f0589fe77428b94a608f44939df8bbd599e11b45d8605c59866ddaede99bd88a';

  /// Urutan `required_tokens` pada langkah kanonik 115.5 di sprint_115.json.
  static const List<String> requiredTokenGroups = <String>[
    'layout',
    'spacing',
    'radius',
    'typography',
    'icon_sizes',
    'avatar_sizes',
    'progress_bar',
    'density',
  ];

  static const AccountCenterLayoutTokens layout = AccountCenterLayoutTokens();
  static const AccountCenterSpacingTokens spacing =
      AccountCenterSpacingTokens();
  static const AccountCenterRadiusTokens radius = AccountCenterRadiusTokens();
  static const AccountCenterTypographyTokens typography =
      AccountCenterTypographyTokens();
  static const AccountCenterIconSizeTokens iconSizes =
      AccountCenterIconSizeTokens();
  static const AccountCenterAvatarSizeTokens avatarSizes =
      AccountCenterAvatarSizeTokens();
  static const AccountCenterProgressTokens progressBar =
      AccountCenterProgressTokens();
  static const AccountCenterDensityTokens density =
      AccountCenterDensityTokens();
  static const AccountCenterCardTokens card = AccountCenterCardTokens();
  static const AccountCenterProviderTileTokens providerTile =
      AccountCenterProviderTileTokens();
  static const AccountCenterServiceRowTokens serviceRow =
      AccountCenterServiceRowTokens();
}
