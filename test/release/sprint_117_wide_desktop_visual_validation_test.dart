import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/auth/auth_controller.dart';
import 'package:void_scriptor/features/account/domain/account_cloud_snapshot.dart';
import 'package:void_scriptor/features/account/domain/account_center_design_tokens.dart';
import 'package:void_scriptor/features/account/domain/account_center_storage_usage_card.dart';
import 'package:void_scriptor/features/account/domain/account_center_wide_desktop_frame.dart';
import 'package:void_scriptor/features/account/presentation/account_cloud_center_screen.dart';
import 'package:void_scriptor/features/account/presentation/storage_usage_card.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_wide_desktop_visual_validation.dart';

/// 117.23 — drill visual wide desktop.
///
/// Mengukur layar Account & Cloud Center yang benar-benar di-render pada
/// viewport referensi 1536x1024 lalu menyerahkan fakta itu ke gate
/// gagal-tertutup [Sprint117WideDesktopVisualValidation]. Delapan area
/// `required_evidence` kanonik diukur di sini, bukan dibaca dari token.

const Size _viewport = Size(1536, 1024);
const String _manifestPath =
    'docs/evidence/sprint-117-23-manifest-20261001.json';

Future<void> _pumpCenter(WidgetTester tester) async {
  tester.view.physicalSize = _viewport;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    const ProviderScope(child: MaterialApp(home: AccountCloudCenterScreen())),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Rect? _rectIfPresent(WidgetTester tester, Finder finder) =>
    finder.evaluate().isEmpty ? null : tester.getRect(finder);

List<Widget> _keyedWidgets(WidgetTester tester, String prefix) => tester
    .widgetList<Widget>(
      find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey &&
            (w.key as ValueKey).value is String &&
            ((w.key as ValueKey).value as String).startsWith(prefix),
      ),
    )
    .toList();

Sprint117VisualCheck _sizeCheck({
  required String area,
  required String check,
  required double declared,
  required double? observed,
  String note = '',
}) {
  if (observed == null) {
    return Sprint117VisualCheck.violation(
      area: area,
      check: check,
      declared: declared.toStringAsFixed(1),
      observed: 'widget absent',
      note: note,
    );
  }
  final matches = (observed - declared).abs() <= 0.5;
  return matches
      ? Sprint117VisualCheck.pass(
          area: area,
          check: check,
          declared: declared.toStringAsFixed(1),
          observed: observed.toStringAsFixed(1),
          note: note,
        )
      : Sprint117VisualCheck.violation(
          area: area,
          check: check,
          declared: declared.toStringAsFixed(1),
          observed: observed.toStringAsFixed(1),
          note: note,
        );
}

/// Ukur seluruh fakta layar referensi yang sudah ter-pump.
List<Sprint117VisualCheck> _measureCenter(
  WidgetTester tester, {
  required String exception,
  required List<String> expectedStatusTexts,
}) {
  const layoutTokens = AccountCenterDesignTokens.layout;
  const cardTokens = AccountCenterDesignTokens.card;
  const avatarSizes = AccountCenterDesignTokens.avatarSizes;
  const iconSizes = AccountCenterDesignTokens.iconSizes;
  final frame = AccountCenterWideDesktopFrame.resolve(
    width: _viewport.width,
    height: _viewport.height,
  )!;
  final checks = <Sprint117VisualCheck>[];

  // ---- 1536x1024 ----
  checks.add(
    exception == 'null'
        ? Sprint117VisualCheck.pass(
            area: '1536x1024',
            check: 'render_without_exception',
            declared: 'no exception at 1536x1024',
            observed: 'exception=null physical=1536.0x1024.0',
          )
        : Sprint117VisualCheck.violation(
            area: '1536x1024',
            check: 'render_without_exception',
            declared: 'no exception at 1536x1024',
            observed: 'exception=$exception',
          ),
  );

  const bandKeys = <String>[
    'account-center-left-navigation',
    'account-center-main-grid',
    'account-center-right-rail',
    'account-center-status-bar',
  ];
  var present = 0;
  for (final key in bandKeys) {
    if (find.byKey(ValueKey(key)).evaluate().isNotEmpty) {
      present++;
    }
  }
  checks.add(
    present == bandKeys.length
        ? Sprint117VisualCheck.pass(
            area: '1536x1024',
            check: 'frame_bands_present',
            declared: '${bandKeys.length}/${bandKeys.length}',
            observed: '$present/${bandKeys.length}',
          )
        : Sprint117VisualCheck.violation(
            area: '1536x1024',
            check: 'frame_bands_present',
            declared: '${bandKeys.length}/${bandKeys.length}',
            observed: '$present/${bandKeys.length}',
          ),
  );

  final nav = _rectIfPresent(
    tester,
    find.byKey(const ValueKey('account-center-left-navigation')),
  );
  final grid = _rectIfPresent(
    tester,
    find.byKey(const ValueKey('account-center-main-grid')),
  );
  final rail = _rectIfPresent(
    tester,
    find.byKey(const ValueKey('account-center-right-rail')),
  );
  final status = _rectIfPresent(
    tester,
    find.byKey(const ValueKey('account-center-status-bar')),
  );

  // ---- layout_dimensions ----
  const layoutArea = 'layout_dimensions';
  checks.add(
    _sizeCheck(
      area: layoutArea,
      check: 'left_navigation_width',
      declared: frame.leftNavigationWidth,
      observed: nav?.width,
      note: 'kontrak frame 115.45 vs band ter-render',
    ),
  );
  checks.add(
    _sizeCheck(
      area: layoutArea,
      check: 'main_grid_width',
      declared: frame.mainWidth,
      observed: grid?.width,
    ),
  );
  checks.add(
    _sizeCheck(
      area: layoutArea,
      check: 'right_rail_width',
      declared: frame.rightRailWidth,
      observed: rail?.width,
    ),
  );
  checks.add(
    _sizeCheck(
      area: layoutArea,
      check: 'status_bar_height',
      declared: frame.statusBarHeight,
      observed: status?.height,
    ),
  );
  checks.add(
    _sizeCheck(
      area: layoutArea,
      check: 'main_grid_height',
      declared: frame.gridHeight,
      observed: grid?.height,
    ),
  );
  checks.add(
    _sizeCheck(
      area: layoutArea,
      check: 'page_horizontal_padding',
      declared: layoutTokens.pageHorizontalPadding,
      observed: nav?.left,
      note: 'band nav mulai dari padding halaman',
    ),
  );
  checks.add(
    _sizeCheck(
      area: layoutArea,
      check: 'status_bar_top',
      declared:
          _viewport.height -
          layoutTokens.pageVerticalPadding -
          frame.statusBarHeight,
      observed: status?.top,
      note: 'status bar menempel di tepi bawah viewport',
    ),
  );

  // ---- card_grid ----
  const gridArea = 'card_grid';
  final anchorWidgets = _keyedWidgets(tester, 'account-anchor-');
  final cardWidgets = _keyedWidgets(tester, 'account-overview-card-');
  final anchorRects = <String, Rect>{
    for (final a in anchorWidgets)
      (a.key! as ValueKey).value as String: tester.getRect(find.byWidget(a)),
  };
  final cardRects = <String, Rect>{
    for (final c in cardWidgets)
      (c.key! as ValueKey).value as String: tester.getRect(find.byWidget(c)),
  };
  final anchorsSorted = anchorRects.entries.toList()
    ..sort((a, b) => a.value.top.compareTo(b.value.top));

  // Kartu dikelompokkan ke anchor yang membungkusnya, lalu ke baris fisik
  // (kartu dengan `top` sama = satu baris).
  final cardsBySection = <String, List<MapEntry<String, Rect>>>{};
  for (final card in cardRects.entries) {
    for (final anchor in anchorsSorted) {
      if (card.value.top >= anchor.value.top - 0.5 &&
          card.value.top < anchor.value.bottom) {
        cardsBySection.putIfAbsent(anchor.key, () => []).add(card);
        break;
      }
    }
  }
  final rowColumns = <int>[];
  final cardCounts = <int>[];
  var uniformLines = true;
  var uniformDetail = 'all lines uniform';
  var minCardWidth = double.infinity;
  for (final anchor in anchorsSorted) {
    final cards = (cardsBySection[anchor.key] ?? const []).toList()
      ..sort((a, b) => a.value.top.compareTo(b.value.top));
    cardCounts.add(cards.length);
    final lines = <double, List<Rect>>{};
    for (final card in cards) {
      lines.putIfAbsent(card.value.top, () => []).add(card.value);
      if (card.value.width < minCardWidth) minCardWidth = card.value.width;
    }
    rowColumns.add(
      lines.values.map((l) => l.length).fold<int>(0, (m, n) => n > m ? n : m),
    );
    for (final line in lines.values) {
      final widths = line.map((r) => r.width).toList();
      final spread =
          widths.reduce((a, b) => a > b ? a : b) -
          widths.reduce((a, b) => a < b ? a : b);
      if (spread > 0.5) {
        uniformLines = false;
        uniformDetail = 'spread=$spread in ${anchor.key}';
      }
    }
  }
  checks.add(
    _listCheck(
      area: gridArea,
      check: 'row_columns',
      declared: frame.rowColumns,
      observed: rowColumns,
      note: 'kolom per baris = aturan fit card.minWidth terhadap band main',
    ),
  );
  checks.add(
    _listCheck(
      area: gridArea,
      check: 'card_counts',
      declared: AccountCenterWideDesktopFrame.rowCardCounts,
      observed: cardCounts,
      note: 'jumlah kartu per baris mockup 3/5/5',
    ),
  );
  checks.add(
    minCardWidth.isFinite && minCardWidth >= cardTokens.minWidth - 0.5
        ? Sprint117VisualCheck.pass(
            area: gridArea,
            check: 'card_min_width',
            declared: cardTokens.minWidth.toStringAsFixed(1),
            observed: minCardWidth.toStringAsFixed(1),
          )
        : Sprint117VisualCheck.violation(
            area: gridArea,
            check: 'card_min_width',
            declared: cardTokens.minWidth.toStringAsFixed(1),
            observed: minCardWidth.isFinite
                ? minCardWidth.toStringAsFixed(1)
                : 'no cards measured',
          ),
  );
  checks.add(
    uniformLines
        ? Sprint117VisualCheck.pass(
            area: gridArea,
            check: 'cards_uniform_per_line',
            declared: 'equal width within each physical line',
            observed: uniformDetail,
          )
        : Sprint117VisualCheck.violation(
            area: gridArea,
            check: 'cards_uniform_per_line',
            declared: 'equal width within each physical line',
            observed: uniformDetail,
          ),
  );

  // Baris mockup harus MENGISI band di bawah chrome: tanpa sisa mati dan
  // tanpa luapan ke status bar.
  Rect? lastAnchor;
  for (final anchor in anchorsSorted) {
    if (lastAnchor == null || anchor.value.bottom > lastAnchor.bottom) {
      lastAnchor = anchor.value;
    }
  }
  if (grid == null || lastAnchor == null) {
    checks.add(
      Sprint117VisualCheck.violation(
        area: gridArea,
        check: 'rows_fill_band',
        declared: 'dead band 0.0, no overflow',
        observed: grid == null ? 'grid absent' : 'no anchors rendered',
      ),
    );
  } else {
    final dead = grid.bottom - lastAnchor.bottom;
    final overflow = lastAnchor.bottom - grid.bottom;
    final ok = dead.abs() <= 0.5 && overflow <= 0.5;
    final observed =
        'dead=${dead.toStringAsFixed(1)} overflow=${overflow.toStringAsFixed(1)} '
        'gridBottom=${grid.bottom.toStringAsFixed(1)} '
        'lastAnchorBottom=${lastAnchor.bottom.toStringAsFixed(1)}';
    checks.add(
      ok
          ? Sprint117VisualCheck.pass(
              area: gridArea,
              check: 'rows_fill_band',
              declared: 'dead band 0.0, no overflow',
              observed: observed,
              note:
                  'chrome=${(lastAnchor.top - grid.top).toStringAsFixed(1)} px di atas baris',
            )
          : Sprint117VisualCheck.violation(
              area: gridArea,
              check: 'rows_fill_band',
              declared: 'dead band 0.0, no overflow',
              observed: observed,
              note:
                  'chrome=${(lastAnchor.top - grid.top).toStringAsFixed(1)} px di atas baris',
            ),
    );
  }

  // ---- avatar ----
  const avatarArea = 'avatar';
  final avatarFinder = find.byKey(const ValueKey('account-profile-avatar'));
  final avatarRect = _rectIfPresent(tester, avatarFinder);
  checks.add(
    _sizeCheck(
      area: avatarArea,
      check: 'image_size',
      declared: avatarSizes.image,
      observed: avatarRect?.width,
      note: 'token profile_avatar.image_size_px',
    ),
  );
  if (avatarRect == null) {
    checks.add(
      Sprint117VisualCheck.violation(
        area: avatarArea,
        check: 'ring_size',
        declared: avatarSizes.ring.toStringAsFixed(1),
        observed: 'profile avatar absent',
      ),
    );
    checks.add(
      Sprint117VisualCheck.violation(
        area: avatarArea,
        check: 'compact_size',
        declared: avatarSizes.compact.toStringAsFixed(1),
        observed: 'profile avatar absent',
      ),
    );
  } else {
    // Cincin = kotak nenek moyang berukuran ring dan sepusat dengan avatar.
    final ancestorWidths = <double>[];
    double? ringWidth;
    tester.element(avatarFinder).visitAncestorElements((ancestor) {
      final renderObject = ancestor.renderObject;
      if (renderObject is RenderBox && renderObject.hasSize) {
        final size = renderObject.size;
        final origin = renderObject.localToGlobal(Offset.zero);
        final rect = Rect.fromLTWH(
          origin.dx,
          origin.dy,
          size.width,
          size.height,
        );
        ancestorWidths.add(size.width);
        final centered = (rect.center - avatarRect.center).distance <= 0.5;
        if (centered &&
            (size.width - avatarSizes.ring).abs() <= 0.5 &&
            (size.height - avatarSizes.ring).abs() <= 0.5) {
          ringWidth = size.width;
        }
      }
      return true;
    });
    checks.add(
      ringWidth != null
          ? Sprint117VisualCheck.pass(
              area: avatarArea,
              check: 'ring_size',
              declared: avatarSizes.ring.toStringAsFixed(1),
              observed: ringWidth!.toStringAsFixed(1),
            )
          : Sprint117VisualCheck.unmet(
              area: avatarArea,
              check: 'ring_size',
              declared: avatarSizes.ring.toStringAsFixed(1),
              observed:
                  'no ${avatarSizes.ring.toStringAsFixed(1)}px concentric ancestor '
                  '(ancestor widths: ${ancestorWidths.take(6).map((w) => w.toStringAsFixed(1)).join(",")})',
              note:
                  'token profile_avatar.ring_size_px dideklarasikan tetapi layar referensi tidak menggambar cincin',
            ),
    );
    final compactAvatars = <double>[];
    for (final widget in _keyedWidgets(tester, 'account-profile-avatar')) {
      final rect = tester.getRect(find.byWidget(widget));
      if ((rect.width - avatarSizes.compact).abs() <= 0.5) {
        compactAvatars.add(rect.width);
      }
    }
    checks.add(
      compactAvatars.isNotEmpty
          ? Sprint117VisualCheck.pass(
              area: avatarArea,
              check: 'compact_size',
              declared: avatarSizes.compact.toStringAsFixed(1),
              observed: compactAvatars.length.toString(),
            )
          : Sprint117VisualCheck.unmet(
              area: avatarArea,
              check: 'compact_size',
              declared: avatarSizes.compact.toStringAsFixed(1),
              observed:
                  '0 avatars at ${avatarSizes.compact.toStringAsFixed(1)}px; '
                  'profile avatar rendered once at ${avatarRect.width.toStringAsFixed(1)}px',
              note:
                  'token profile_avatar.compact_size_px tidak punya konteks render di layar referensi',
            ),
    );
  }

  // ---- icons ----
  const iconArea = 'icons';
  final tokenSizes = <double>{
    iconSizes.navigation,
    iconSizes.action,
    iconSizes.section,
    iconSizes.page,
    iconSizes.providerTile,
    iconSizes.serviceRow,
    iconSizes.statusDot,
  };
  final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
  final outOfToken = <String>[];
  final unpinned = <String>[];
  final navIconSizes = <double>{};
  Rect? settingsIconRect;
  for (final icon in icons) {
    final rect = tester.getRect(find.byWidget(icon));
    final width = rect.width;
    if (!tokenSizes.contains(width)) {
      outOfToken.add(width.toStringAsFixed(1));
    }
    if (icon.size == null) {
      unpinned.add(
        'U+${icon.icon?.codePoint.toRadixString(16)}@${width.toStringAsFixed(1)}',
      );
    }
    if (nav != null && rect.left < nav.right && rect.top < nav.bottom) {
      navIconSizes.add(width);
    }
    if (icon.icon == Icons.settings_outlined) {
      settingsIconRect = rect;
    }
  }
  checks.add(
    outOfToken.isEmpty
        ? Sprint117VisualCheck.pass(
            area: iconArea,
            check: 'token_set_membership',
            declared: tokenSizes
                .map((s) => s.toStringAsFixed(1))
                .toList()
                .toString(),
            observed: '${icons.length} icons, all sizes in token set',
          )
        : Sprint117VisualCheck.violation(
            area: iconArea,
            check: 'token_set_membership',
            declared: tokenSizes
                .map((s) => s.toStringAsFixed(1))
                .toList()
                .toString(),
            observed:
                '${outOfToken.length} of ${icons.length} icons outside token set: '
                '${outOfToken.join(",")}',
            note: 'ukuran ikon yang lahir dari IconTheme ambient, bukan token',
          ),
  );
  checks.add(
    unpinned.isEmpty
        ? Sprint117VisualCheck.pass(
            area: iconArea,
            check: 'explicit_token_pinning',
            declared: 'every rendered Icon pins an explicit token size',
            observed: '${icons.length} icons, all explicit',
          )
        : Sprint117VisualCheck.violation(
            area: iconArea,
            check: 'explicit_token_pinning',
            declared: 'every rendered Icon pins an explicit token size',
            observed:
                '${unpinned.length} of ${icons.length} unpinned: '
                '${unpinned.join(",")}',
          ),
  );
  checks.add(
    navIconSizes.isNotEmpty &&
            navIconSizes.every((s) => s == iconSizes.navigation)
        ? Sprint117VisualCheck.pass(
            area: iconArea,
            check: 'navigation_icon_size',
            declared: iconSizes.navigation.toStringAsFixed(1),
            observed: navIconSizes
                .map((s) => s.toStringAsFixed(1))
                .toSet()
                .toString(),
          )
        : Sprint117VisualCheck.violation(
            area: iconArea,
            check: 'navigation_icon_size',
            declared: iconSizes.navigation.toStringAsFixed(1),
            observed: navIconSizes.isEmpty
                ? 'no icons in navigation band'
                : navIconSizes
                      .map((s) => s.toStringAsFixed(1))
                      .toSet()
                      .toString(),
          ),
  );
  checks.add(
    _sizeCheck(
      area: iconArea,
      check: 'storage_action_icon_size',
      declared: iconSizes.action,
      observed: settingsIconRect?.width,
      note: 'ikon tombol Manage storage = action_icon_size_px 20',
    ),
  );

  // ---- progress (fakta layar referensi; tinggi bar diukur terpisah) ----
  const progressArea = 'progress';
  final barCount = tester
      .widgetList<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
      .length;
  checks.add(
    barCount == 0
        ? Sprint117VisualCheck.pass(
            area: progressArea,
            check: 'no_bar_without_data',
            declared: '0 bars while no quota data exists',
            observed: 'LinearProgressIndicator count=0',
            note: 'kartu storage jujur menampilkan Usage unavailable',
          )
        : Sprint117VisualCheck.violation(
            area: progressArea,
            check: 'no_bar_without_data',
            declared: '0 bars while no quota data exists',
            observed: 'LinearProgressIndicator count=$barCount',
            note: 'bar dirender tanpa data kuota',
          ),
  );
  final screenSource = File(
    'lib/features/account/presentation/account_cloud_center_screen.dart',
  ).readAsStringSync();
  final callSites = RegExp(
    r'StorageUsageCard\(([^)]*)\)',
  ).allMatches(screenSource).toList();
  final withData = callSites.where((m) => m.group(1)!.contains('data:')).length;
  checks.add(
    withData > 0
        ? Sprint117VisualCheck.pass(
            area: progressArea,
            check: 'production_data_supplier',
            declared: '>=1 shipped call site supplies StorageUsageCardData',
            observed: '${callSites.length} call sites, $withData with data:',
          )
        : Sprint117VisualCheck.unmet(
            area: progressArea,
            check: 'production_data_supplier',
            declared: '>=1 shipped call site supplies StorageUsageCardData',
            observed:
                '${callSites.length} shipped call site(s), 0 pass data: '
                '(StorageUsageCard(onManage: ...))',
            note:
                'token progress bar terbukti jalan saat data ada (cek bar_height_with_data), '
                'tetapi tidak ada jalur produksi yang menyuplai data kuota',
          ),
  );

  // ---- charts ----
  const chartsArea = 'charts';
  const chartTitles = <String, String>{
    'account-ai-usage-chart': 'AI USAGE THIS MONTH',
    'account-storage-donut': 'STORAGE DISTRIBUTION',
  };
  for (final entry in chartTitles.entries) {
    final key = entry.key;
    final title = entry.value;
    final finder = find.byKey(ValueKey(key));
    if (finder.evaluate().isEmpty) {
      checks.add(
        Sprint117VisualCheck.violation(
          area: chartsArea,
          check: key,
          declared: 'painted at reference with accessible text alternative',
          observed: 'chart absent',
        ),
      );
      continue;
    }
    final rect = tester.getRect(finder);
    final painter = tester.widget<CustomPaint>(finder).painter?.runtimeType;
    final labels = <String>[];
    for (final semantics
        in find
            .ancestor(of: finder, matching: find.byType(Semantics))
            .evaluate()) {
      final label = (semantics.widget as Semantics).properties.label;
      if (label != null && label.trim().isNotEmpty) labels.add(label);
    }
    final matched = labels.where((l) => l.contains(title)).toList();
    final sized = rect.width > 0 && rect.height > 0;
    final labelled = matched.isNotEmpty;
    final observed =
        '${rect.width.toStringAsFixed(1)}x${rect.height.toStringAsFixed(1)} '
        'painter=$painter candidates=${labels.length} '
        'labelChars=${matched.isEmpty ? 0 : matched.first.length}';
    checks.add(
      sized && labelled
          ? Sprint117VisualCheck.pass(
              area: chartsArea,
              check: key,
              declared: 'painted at reference with accessible text alternative',
              observed: observed,
            )
          : Sprint117VisualCheck.violation(
              area: chartsArea,
              check: key,
              declared: 'painted at reference with accessible text alternative',
              observed: observed,
              note: !sized ? 'zero-size paint' : 'no non-empty semantics label',
            ),
    );
  }

  // ---- status_bar ----
  const statusArea = 'status_bar';
  checks.add(
    _sizeCheck(
      area: statusArea,
      check: 'height',
      declared: frame.statusBarHeight,
      observed: status?.height,
    ),
  );
  final expectedTexts = expectedStatusTexts;
  final observedTexts = status == null
      ? <String>[]
      : find
            .descendant(
              of: find.byKey(const ValueKey('account-center-status-bar')),
              matching: find.byType(Text),
            )
            .evaluate()
            .map((e) => (e.widget as Text).data ?? '')
            .toList();
  final itemsMatch =
      observedTexts.length == expectedTexts.length &&
      List<int>.generate(
        expectedTexts.length,
        (i) => i,
      ).every((i) => observedTexts[i] == expectedTexts[i]);
  checks.add(
    itemsMatch
        ? Sprint117VisualCheck.pass(
            area: statusArea,
            check: 'items_from_snapshot',
            declared: expectedTexts.join(' | '),
            observed: observedTexts.join(' | '),
            note: 'nilai diturunkan dari AccountCloudSnapshot tanpa fabrikasi',
          )
        : Sprint117VisualCheck.violation(
            area: statusArea,
            check: 'items_from_snapshot',
            declared: expectedTexts.join(' | '),
            observed: observedTexts.join(' | '),
          ),
  );

  return checks;
}

Sprint117VisualCheck _listCheck({
  required String area,
  required String check,
  required List<int> declared,
  required List<int> observed,
  String note = '',
}) {
  final same =
      declared.length == observed.length &&
      List<int>.generate(
        declared.length,
        (i) => i,
      ).every((i) => declared[i] == observed[i]);
  return same
      ? Sprint117VisualCheck.pass(
          area: area,
          check: check,
          declared: declared.toString(),
          observed: observed.toString(),
          note: note,
        )
      : Sprint117VisualCheck.violation(
          area: area,
          check: check,
          declared: declared.toString(),
          observed: observed.toString(),
          note: note,
        );
}

/// Pump kartu storage dengan data kuota nyata dan ukur tinggi progress bar.
Future<double?> _measureProgressWithQuota(WidgetTester tester) async {
  final data = StorageUsageCardData.fromBytes(
    providerId: 'google_drive',
    accountLabel: 'Choi Drive',
    usedBytes: 256 * 1024 * 1024,
    quotaBytes: 1024 * 1024 * 1024,
    measuredAt: DateTime.utc(2026, 10, 1),
    now: DateTime.utc(2026, 10, 1, 1),
  );
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 400, child: StorageUsageCard(data: data)),
        ),
      ),
    ),
  );
  await tester.pump();
  final bars = tester
      .widgetList<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
      .toList();
  if (bars.isEmpty) return null;
  return tester.getRect(find.byWidget(bars.first)).height;
}

void main() {
  group('117.23 wide desktop visual validation', () {
    testWidgets(
      'gate passes on facts measured from the shipped screen at 1536x1024',
      (tester) async {
        await _pumpCenter(tester);
        final exception = tester.takeException();
        expect(exception, isNull, reason: 'layar melempar exception');

        // Nilai status bar dibaca dari sesi yang sama yang dipakai layar
        // (authControllerProvider), sehingga ekspektasi tidak mengarang.
        final container = ProviderScope.containerOf(
          tester.element(find.byType(AccountCloudCenterScreen)),
        );
        final session = container.read(authControllerProvider).valueOrNull;
        final expectedStatusTexts = <String>[];
        for (final item in AccountCenterWideDesktopFrame.statusBarItems(
          AccountCloudSnapshot.localOnly(session: session),
        )) {
          expectedStatusTexts
            ..add(item.label)
            ..add(item.value);
        }
        final checks = _measureCenter(
          tester,
          exception: '$exception',
          expectedStatusTexts: expectedStatusTexts,
        );
        final progressHeight = await _measureProgressWithQuota(tester);
        expect(tester.takeException(), isNull);
        final progressHeightDeclared =
            AccountCenterDesignTokens.progressBar.height;
        checks.add(
          progressHeight == null
              ? Sprint117VisualCheck.violation(
                  area: 'progress',
                  check: 'bar_height_with_data',
                  declared: progressHeightDeclared.toStringAsFixed(1),
                  observed: 'no bar rendered with quota data',
                )
              : (progressHeight - progressHeightDeclared).abs() <= 0.5
              ? Sprint117VisualCheck.pass(
                  area: 'progress',
                  check: 'bar_height_with_data',
                  declared: progressHeightDeclared.toStringAsFixed(1),
                  observed: progressHeight.toStringAsFixed(1),
                  note: 'token progress_bar_height_px diukur pada bar terisi',
                )
              : Sprint117VisualCheck.violation(
                  area: 'progress',
                  check: 'bar_height_with_data',
                  declared: progressHeightDeclared.toStringAsFixed(1),
                  observed: progressHeight.toStringAsFixed(1),
                ),
        );

        final result = Sprint117WideDesktopVisualValidation.evaluate(checks);
        final dump = checks
            .map(
              (c) =>
                  '${c.status.name} ${c.code} declared=${c.declared} '
                  'observed=${c.observed}',
            )
            .join('\n');
        expect(
          result.pass,
          isTrue,
          reason: 'failures=${result.failures}\n$dump',
        );
        expect(
          result.checks.map((c) => c.area).toSet(),
          Sprint117WideDesktopVisualValidation.requiredAreas.toSet(),
          reason: 'delapan area required_evidence harus terukur',
        );
        expect(
          result.violationCodes,
          isEmpty,
          reason: 'violation=${result.violationCodes}',
        );
        // Cek terarah: dua mekanisme yang pernah fail-open tetap dipegang.
        final rowsFill = result.checks.singleWhere(
          (c) => c.check == 'rows_fill_band',
        );
        expect(
          rowsFill.status,
          Sprint117VisualStatus.pass,
          reason: rowsFill.observed,
        );
        final tokenSet = result.checks.singleWhere(
          (c) => c.check == 'token_set_membership',
        );
        expect(
          tokenSet.status,
          Sprint117VisualStatus.pass,
          reason: tokenSet.observed,
        );
        final pinning = result.checks.singleWhere(
          (c) => c.check == 'explicit_token_pinning',
        );
        expect(
          pinning.status,
          Sprint117VisualStatus.pass,
          reason: pinning.observed,
        );
        final actionIcon = result.checks.singleWhere(
          (c) => c.check == 'storage_action_icon_size',
        );
        expect(
          actionIcon.status,
          Sprint117VisualStatus.pass,
          reason: actionIcon.observed,
        );

        // `unmet` harus tampil sebagai open item, bukan lenyap diam-diam.
        expect(
          result.openItems,
          containsAll(const <String>[
            'avatar:ring_size',
            'progress:production_data_supplier',
          ]),
        );

        final writeManifest =
            Platform.environment['SPRINT_117_23_MANIFEST'] == '1';
        if (writeManifest) {
          File(_manifestPath).writeAsStringSync(
            '${const JsonEncoder.withIndent('  ').convert(result.toJson())}\n',
          );
        }
      },
    );

    test('gate fails closed on structural holes', () {
      List<Sprint117VisualCheck> minimal() => [
        for (final area in Sprint117WideDesktopVisualValidation.requiredAreas)
          Sprint117VisualCheck.pass(
            area: area,
            check: 'probe',
            declared: 'declared',
            observed: 'observed',
          ),
      ];

      final healthy = Sprint117WideDesktopVisualValidation.evaluate(minimal());
      expect(healthy.pass, isTrue, reason: healthy.failures.toString());
      expect(healthy.failures, isEmpty);

      final missingArea = List<Sprint117VisualCheck>.from(minimal())
        ..removeWhere((c) => c.area == 'charts');
      final missingResult = Sprint117WideDesktopVisualValidation.evaluate(
        missingArea,
      );
      expect(missingResult.pass, isFalse);
      expect(missingResult.failures, contains('missing_area:charts'));

      final vacuous = List<Sprint117VisualCheck>.from(minimal())
        ..removeWhere((c) => c.area == 'charts')
        ..add(
          Sprint117VisualCheck.pass(
            area: 'charts',
            check: 'probe',
            declared: 'declared',
            observed: '   ',
          ),
        );
      final vacuousResult = Sprint117WideDesktopVisualValidation.evaluate(
        vacuous,
      );
      expect(vacuousResult.pass, isFalse);
      expect(vacuousResult.failures, contains('vacuous:charts:probe'));

      final duplicate = <Sprint117VisualCheck>[...minimal(), minimal().first];
      final duplicateResult = Sprint117WideDesktopVisualValidation.evaluate(
        duplicate,
      );
      expect(duplicateResult.pass, isFalse);
      expect(
        duplicateResult.failures,
        contains('duplicate_check:1536x1024:probe'),
      );

      final noPass = <Sprint117VisualCheck>[
        for (final area in Sprint117WideDesktopVisualValidation.requiredAreas)
          Sprint117VisualCheck.unmet(
            area: area,
            check: 'probe',
            declared: 'declared',
            observed: 'observed',
          ),
      ];
      final noPassResult = Sprint117WideDesktopVisualValidation.evaluate(
        noPass,
      );
      expect(noPassResult.pass, isFalse);
      expect(noPassResult.failures, hasLength(8));
      expect(noPassResult.failures.first, 'area_without_pass:1536x1024');

      final violation = <Sprint117VisualCheck>[
        for (final check in minimal())
          check.area == 'avatar'
              ? Sprint117VisualCheck.violation(
                  area: 'avatar',
                  check: 'probe',
                  declared: 'declared',
                  observed: 'observed',
                )
              : check,
      ];
      final violationResult = Sprint117WideDesktopVisualValidation.evaluate(
        violation,
      );
      expect(violationResult.pass, isFalse);
      expect(violationResult.violationCodes, ['avatar:probe']);

      final unknown = <Sprint117VisualCheck>[
        ...minimal(),
        Sprint117VisualCheck.pass(
          area: 'not_an_area',
          check: 'probe',
          declared: 'declared',
          observed: 'observed',
        ),
      ];
      final unknownResult = Sprint117WideDesktopVisualValidation.evaluate(
        unknown,
      );
      expect(unknownResult.pass, isFalse);
      expect(unknownResult.failures, contains('unknown_area:not_an_area'));

      final empty = Sprint117WideDesktopVisualValidation.evaluate(
        const <Sprint117VisualCheck>[],
      );
      expect(empty.pass, isFalse);
      expect(empty.failures, ['no_checks']);
    });
  });
}
