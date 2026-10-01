import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/auth/auth_session.dart';
import 'package:void_scriptor/features/account/domain/account_cloud_snapshot.dart';
import 'package:void_scriptor/features/account/domain/account_center_design_tokens.dart';
import 'package:void_scriptor/features/account/domain/account_center_desktop_tablet_adaptation.dart';
import 'package:void_scriptor/features/account/domain/account_center_mobile_adaptation.dart';
import 'package:void_scriptor/features/account/domain/account_center_responsive_grid.dart';
import 'package:void_scriptor/features/account/domain/account_center_wide_desktop_frame.dart';
import 'package:void_scriptor/features/account/presentation/account_cloud_center_screen.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_responsive_layout_validation.dart';

/// 117.24 — drill responsive layout.
///
/// Mengukur layar Account & Cloud Center yang benar-benar di-render pada
/// viewport setiap tier (1920/1440/1439/1180/900/600/390) lalu menyerahkan
/// fakta itu ke gate gagal-tertutup [Sprint117ResponsiveLayoutValidation].
/// Delapan area `required_evidence` kanonik diukur di sini, bukan dibaca
/// dari token.

const String _manifestPath =
    'docs/evidence/sprint-117-24-manifest-20261001.json';

const List<String> _watchedKeys = <String>[
  'account-center-left-navigation',
  'account-center-main-grid',
  'account-center-right-rail',
  'account-center-status-bar',
  'account-center-desktop-left-navigation',
  'account-center-collapsed-rail',
  'account-center-top-navigation',
  'account-center-adaptive-content',
  'account-center-drawer-toggle',
  'account-center-summary-drawer',
  'account-center-mobile-layout',
  'account-center-mobile-content',
  'account-center-mobile-action-bar',
  'account-center-tab-strip',
  'account-center-breadcrumb',
];

final AccountCloudSnapshot _guest = AccountCloudSnapshot.localOnly(
  session: const AuthSession.guest(),
);

/// Fakta terukur dari satu pump viewport.
final class _Facts {
  _Facts({
    required this.size,
    required this.exception,
    required this.rects,
    required this.plan,
    required this.frame,
    required this.adaptive,
    required this.mobile,
    required this.lines,
    required this.cardCount,
    required this.pageScroll,
    required this.pageScrollAncestors,
  });

  final Size size;

  /// Seluruh exception yang ditarik selama pump ini (`none` bila bersih).
  final String exception;

  /// Rect widget ber-key yang hadir pada viewport ini.
  final Map<String, Rect> rects;

  final AccountCenterGridPlan plan;
  final AccountCenterFrameLayout? frame;
  final AccountCenterDesktopTabletLayout? adaptive;
  final AccountCenterMobileLayout? mobile;

  /// Jumlah kartu overview per baris fisik (top identik), urut atas->bawah.
  final List<int> lines;

  final int cardCount;

  /// Offset terbesar atas SEMUA scrollable vertikal yang membungkus tab
  /// aktif — 0.0 pada paint pertama berarti halaman membuka di posisi atas.
  final double pageScroll;
  final int pageScrollAncestors;

  Rect? rect(String key) => rects[key];

  bool has(String key) => rects.containsKey(key);

  int present(Iterable<String> keys) => keys.where(has).length;
}

String _drain(WidgetTester tester) {
  final collected = <String>[];
  Object? error;
  while ((error = tester.takeException()) != null) {
    collected.add(error.toString().split('\n').first);
  }
  return collected.isEmpty ? 'none' : collected.join(' | ');
}

const List<String> _frameKeys = <String>[
  'account-center-left-navigation',
  'account-center-main-grid',
  'account-center-right-rail',
  'account-center-status-bar',
];

Future<_Facts> _pump(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: AccountCloudCenterScreen(snapshot: _guest)),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));

  final rects = <String, Rect>{};
  for (final key in _watchedKeys) {
    final finder = find.byKey(ValueKey(key));
    if (finder.evaluate().isNotEmpty) {
      rects[key] = tester.getRect(finder.first);
    }
  }

  // Kartu overview dikelompokkan ke baris fisik (top sama = satu baris).
  final cards = find
      .byWidgetPredicate(
        (w) =>
            w.key is ValueKey &&
            (w.key! as ValueKey).value is String &&
            ((w.key! as ValueKey).value as String).startsWith(
              'account-overview-card-',
            ),
      )
      .evaluate();
  final byTop = <double, int>{};
  for (final card in cards) {
    final r = tester.getRect(find.byWidget(card.widget));
    byTop.update(r.top, (v) => v + 1, ifAbsent: () => 1);
  }
  final sortedTops = byTop.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  final lines = <int>[for (final e in sortedTops) e.value];

  return _Facts(
    size: size,
    exception: _drain(tester),
    rects: rects,
    plan: AccountCenterResponsiveGrid.resolve(size.width),
    frame: AccountCenterWideDesktopFrame.resolve(
      width: size.width,
      height: size.height,
    ),
    adaptive: AccountCenterDesktopTabletAdaptation.resolve(size.width),
    mobile: AccountCenterMobileAdaptation.resolve(
      viewportWidth: size.width,
      viewportHeight: size.height,
    ),
    lines: lines,
    cardCount: cards.length,
    pageScroll: _pageScrollMax(tester),
    pageScrollAncestors: _verticalScrollAncestorCount(tester),
  );
}

Finder _activeTabLabel(WidgetTester tester) {
  final strip = find.byKey(const ValueKey('account-center-tab-strip'));
  return find.descendant(of: strip, matching: find.text('Overview'));
}

Iterable<ScrollableState> _verticalAncestors(WidgetTester tester) sync* {
  final label = _activeTabLabel(tester);
  if (label.evaluate().isEmpty) {
    return;
  }
  final ancestors = find.ancestor(
    of: label.first,
    matching: find.byType(Scrollable),
  );
  for (var i = 0; i < ancestors.evaluate().length; i++) {
    final state = tester.state<ScrollableState>(ancestors.at(i));
    if (state.position.axis == Axis.vertical) {
      yield state;
    }
  }
}

double _pageScrollMax(WidgetTester tester) {
  var max = 0.0;
  for (final state in _verticalAncestors(tester)) {
    if (state.position.pixels > max) {
      max = state.position.pixels;
    }
  }
  return max;
}

int _verticalScrollAncestorCount(WidgetTester tester) =>
    _verticalAncestors(tester).length;

double? _stripHorizontalOffset(WidgetTester tester) {
  final strip = find.byKey(const ValueKey('account-center-tab-strip'));
  final scroll = find.descendant(of: strip, matching: find.byType(Scrollable));
  if (scroll.evaluate().isEmpty) {
    return null;
  }
  final state = tester.state<ScrollableState>(scroll.first);
  if (state.position.axis != Axis.horizontal) {
    return null;
  }
  return state.position.pixels;
}

Sprint117ResponsiveCheck _boolCheck({
  required String area,
  required String check,
  required bool ok,
  required String declared,
  required String observed,
  String note = '',
}) => ok
    ? Sprint117ResponsiveCheck.pass(
        area: area,
        check: check,
        declared: declared,
        observed: observed,
        note: note,
      )
    : Sprint117ResponsiveCheck.violation(
        area: area,
        check: check,
        declared: declared,
        observed: observed,
        note: note,
      );

/// Cek numerik dengan toleransi [tolerance] (default 0.5px).
Sprint117ResponsiveCheck _numCheck({
  required String area,
  required String check,
  required double declared,
  required double? observed,
  double tolerance = 0.5,
  String observedFallback = 'widget absent',
  String note = '',
}) {
  if (observed == null) {
    return Sprint117ResponsiveCheck.violation(
      area: area,
      check: check,
      declared: declared.toStringAsFixed(1),
      observed: observedFallback,
      note: note,
    );
  }
  final ok = (observed - declared).abs() <= tolerance;
  final observedText = observed.toStringAsFixed(1);
  return ok
      ? Sprint117ResponsiveCheck.pass(
          area: area,
          check: check,
          declared: declared.toStringAsFixed(1),
          observed: observedText,
          note: note,
        )
      : Sprint117ResponsiveCheck.violation(
          area: area,
          check: check,
          declared: declared.toStringAsFixed(1),
          observed: observedText,
          note: note,
        );
}

int _maxLine(List<int> lines) =>
    lines.isEmpty ? 0 : lines.reduce((a, b) => a > b ? a : b);

String _linesText(List<int> lines) => '[${lines.join(', ')}]';

void main() {
  group('117.24 responsive layout validation', () {
    testWidgets(
      'gate passes on facts measured from the shipped screen across tiers',
      (tester) async {
        final checks = <Sprint117ResponsiveCheck>[];

        // ---- viewport: 1920x1080, 1440x900 (boundary), 1439x900 ----
        final wide = await _pump(tester, const Size(1920, 1080));
        final boundary = await _pump(tester, const Size(1440, 900));
        final belowBoundary = await _pump(tester, const Size(1439, 900));

        // ---- 1440_plus ----
        const area1440 = '1440_plus';
        checks.add(
          _boolCheck(
            area: area1440,
            check: 'frame_chrome_1920',
            ok: wide.present(_frameKeys) == 4 && wide.exception == 'none',
            declared: '4/4 band frame 115.45, exception none',
            observed:
                '${wide.present(_frameKeys)}/4 exception=${wide.exception}',
            note: '1920x1080',
          ),
        );
        final frameWide = wide.frame;
        final nav1920 = wide.rect('account-center-left-navigation');
        final grid1920 = wide.rect('account-center-main-grid');
        final rail1920 = wide.rect('account-center-right-rail');
        final status1920 = wide.rect('account-center-status-bar');
        checks.add(
          _boolCheck(
            area: area1440,
            check: 'frame_geometry_1920',
            ok:
                frameWide != null &&
                nav1920 != null &&
                grid1920 != null &&
                rail1920 != null &&
                status1920 != null &&
                (nav1920.width - frameWide.leftNavigationWidth).abs() <= 0.5 &&
                (grid1920.width - frameWide.mainWidth).abs() <= 0.5 &&
                (rail1920.width - frameWide.rightRailWidth).abs() <= 0.5 &&
                (status1920.height - frameWide.statusBarHeight).abs() <= 0.5,
            declared: 'band frame == kontrak 115.45 (nav/main/rail/status)',
            observed:
                'nav=${nav1920?.width.toStringAsFixed(1)}/'
                '${frameWide?.leftNavigationWidth.toStringAsFixed(1)} '
                'main=${grid1920?.width.toStringAsFixed(1)}/'
                '${frameWide?.mainWidth.toStringAsFixed(1)} '
                'rail=${rail1920?.width.toStringAsFixed(1)}/'
                '${frameWide?.rightRailWidth.toStringAsFixed(1)} '
                'status=${status1920?.height.toStringAsFixed(1)}/'
                '${frameWide?.statusBarHeight.toStringAsFixed(1)}',
          ),
        );
        checks.add(
          _boolCheck(
            area: area1440,
            check: 'frame_boundary_1440',
            ok:
                boundary.present(_frameKeys) == 4 &&
                boundary.plan.breakpointName == 'wide_desktop',
            declared: '4/4 band frame pada lebar tepat 1440',
            observed:
                '${boundary.present(_frameKeys)}/4 '
                'tier=${boundary.plan.breakpointName}',
          ),
        );
        checks.add(
          _boolCheck(
            area: area1440,
            check: 'tier_resolution',
            ok:
                wide.plan.breakpointName == 'wide_desktop' &&
                boundary.plan.breakpointName == 'wide_desktop',
            declared: 'wide_desktop@1920 & wide_desktop@1440',
            observed:
                '${wide.plan.breakpointName}@1920 '
                '${boundary.plan.breakpointName}@1440',
          ),
        );

        // ---- viewport: 1180x900 (desktop) ----
        final desktop = await _pump(tester, const Size(1180, 900));
        const area1180 = '1180';
        checks.add(
          _boolCheck(
            area: area1180,
            check: 'desktop_chrome_present',
            ok:
                desktop.has('account-center-desktop-left-navigation') &&
                desktop.has('account-center-drawer-toggle') &&
                !desktop.has('account-center-left-navigation') &&
                !desktop.has('account-center-main-grid') &&
                desktop.exception == 'none',
            declared:
                'desktop_left_navigation + drawer_toggle, band frame '
                'tidak dipaksa, exception none',
            observed:
                'nav=${desktop.has('account-center-desktop-left-navigation')} '
                'toggle=${desktop.has('account-center-drawer-toggle')} '
                'frame_nav=${desktop.has('account-center-left-navigation')} '
                'frame_grid=${desktop.has('account-center-main-grid')} '
                'exception=${desktop.exception}',
          ),
        );
        final nav1180 = desktop.rect('account-center-desktop-left-navigation');
        checks.add(
          _numCheck(
            area: area1180,
            check: 'navigation_band_width',
            declared: AccountCenterDesignTokens.layout.leftNavigationWidth,
            observed: nav1180?.width,
            note: 'band kiri tier desktop == token 115.5',
          ),
        );
        final content1180 = desktop.rect('account-center-adaptive-content');
        checks.add(
          _numCheck(
            area: area1180,
            check: 'content_width_matches_contract',
            declared: desktop.adaptive?.contentWidth ?? -1,
            observed: content1180?.width,
            note: 'lebar konten ter-render == kontrak 115.46',
          ),
        );
        checks.add(
          _boolCheck(
            area: area1180,
            check: 'drawer_capability',
            ok:
                desktop.adaptive?.summaryPresentation ==
                    AccountCenterSummaryPresentation.drawer &&
                desktop.has('account-center-drawer-toggle'),
            declared: 'summaryPresentation=drawer + toggle dirender',
            observed:
                'summary=${desktop.adaptive?.summaryPresentation.name} '
                'toggle=${desktop.has('account-center-drawer-toggle')}',
          ),
        );

        // ---- viewport: 900x800 (compact_desktop) ----
        final compact = await _pump(tester, const Size(900, 800));
        const area900 = '900';
        checks.add(
          _boolCheck(
            area: area900,
            check: 'collapsed_rail_present',
            ok:
                compact.has('account-center-collapsed-rail') &&
                !compact.has('account-center-desktop-left-navigation') &&
                compact.exception == 'none',
            declared:
                'collapsed rail hadir, band navigasi lebar tidak, exception none',
            observed:
                'rail=${compact.has('account-center-collapsed-rail')} '
                'wide_nav='
                '${compact.has('account-center-desktop-left-navigation')} '
                'exception=${compact.exception}',
          ),
        );
        checks.add(
          _numCheck(
            area: area900,
            check: 'collapsed_rail_width',
            declared: AccountCenterDesktopTabletAdaptation.collapsedRailWidth,
            observed: compact.rect('account-center-collapsed-rail')?.width,
            note: 'rail = target sentuh 44 + padding, dari token 115.5',
          ),
        );
        final rail900 = find.byKey(
          const ValueKey('account-center-collapsed-rail'),
        );
        final railLabelCount = rail900.evaluate().isEmpty
            ? -1
            : find
                  .descendant(
                    of: rail900,
                    matching: find.text('Overview', skipOffstage: false),
                  )
                  .evaluate()
                  .length;
        checks.add(
          _boolCheck(
            area: area900,
            check: 'navigation_labels_hidden',
            ok:
                railLabelCount == 0 &&
                compact.adaptive?.navigationLabelsVisible == false,
            declared: '0 label teks di rail + kontrak labelsVisible=false',
            observed:
                'label_texts=$railLabelCount '
                'labelsVisible=${compact.adaptive?.navigationLabelsVisible}',
          ),
        );
        final content900 = compact.rect('account-center-adaptive-content');
        checks.add(
          _numCheck(
            area: area900,
            check: 'content_width_matches_contract',
            declared: compact.adaptive?.contentWidth ?? -1,
            observed: content900?.width,
            note: 'lebar konten ter-render == kontrak 115.46',
          ),
        );

        // ---- viewport: 600x800 (tablet) ----
        final tablet = await _pump(tester, const Size(600, 800));
        const area600 = '600';
        checks.add(
          _boolCheck(
            area: area600,
            check: 'top_navigation_present',
            ok:
                tablet.has('account-center-top-navigation') &&
                tablet.exception == 'none',
            declared: 'top navigation dirender + exception none',
            observed:
                'present=${tablet.has('account-center-top-navigation')} '
                'exception=${tablet.exception}',
            note: 'spec tier tablet: top navigation',
          ),
        );
        checks.add(
          _boolCheck(
            area: area600,
            check: 'no_left_band',
            ok:
                !tablet.has('account-center-desktop-left-navigation') &&
                !tablet.has('account-center-collapsed-rail') &&
                tablet.adaptive?.navigationWidth == 0,
            declared:
                'tanpa band kiri + navigationWidth=0 (nav pindah ke atas)',
            observed:
                'desktop_nav='
                '${tablet.has('account-center-desktop-left-navigation')} '
                'collapsed_rail=${tablet.has('account-center-collapsed-rail')} '
                'navWidth=${tablet.adaptive?.navigationWidth}',
          ),
        );
        final content600 = tablet.rect('account-center-adaptive-content');
        checks.add(
          _numCheck(
            area: area600,
            check: 'content_width_matches_contract',
            declared: tablet.adaptive?.contentWidth ?? -1,
            observed: content600?.width,
            note: 'seluruh lebar tersisa dipakai konten (band nol)',
          ),
        );
        final topNav600 = tablet.rect('account-center-top-navigation');
        final declaredTop =
            AccountCenterDesignTokens.layout.pageVerticalPadding;
        checks.add(
          _boolCheck(
            area: area600,
            check: 'top_navigation_visible_on_open',
            ok: topNav600 != null && topNav600.top >= declaredTop - 0.5,
            declared:
                'nav.top >= ${declaredTop.toStringAsFixed(1)} '
                '(padding halaman atas) saat paint pertama',
            observed: topNav600 == null
                ? 'widget absent'
                : topNav600.top.toStringAsFixed(1),
            note: 'chrome wajib tier tablet tidak boleh terpotong di atas',
          ),
        );
        checks.add(
          _boolCheck(
            area: area600,
            check: 'initial_scroll_at_top',
            ok: tablet.pageScroll <= 0.5,
            declared: '0.0 offset scroll halaman pada paint pertama',
            observed:
                '${tablet.pageScroll.toStringAsFixed(1)} '
                '(vertical ancestors=${tablet.pageScrollAncestors})',
          ),
        );

        // ---- viewport: 390x844 (mobile) ----
        final mobile = await _pump(tester, const Size(390, 844));
        const areaMobile = 'mobile';
        final mobileKeys = <String>[
          'account-center-mobile-layout',
          'account-center-mobile-content',
          'account-center-mobile-action-bar',
        ];
        checks.add(
          _boolCheck(
            area: areaMobile,
            check: 'mobile_chrome_present',
            ok: mobile.present(mobileKeys) == 3 && mobile.exception == 'none',
            declared: '3/3 key chrome mobile 115.47 + exception none',
            observed:
                '${mobile.present(mobileKeys)}/3 '
                'exception=${mobile.exception}',
          ),
        );
        checks.add(
          _numCheck(
            area: areaMobile,
            check: 'action_bar_height',
            declared: mobile.mobile?.actionBarHeight ?? -1,
            observed: mobile.rect('account-center-mobile-action-bar')?.height,
            note: 'bar aksi menempel bawah dari token 115.5',
          ),
        );
        checks.add(
          _boolCheck(
            area: areaMobile,
            check: 'single_column_cards',
            ok: mobile.mobile?.columns == 1 && _maxLine(mobile.lines) == 1,
            declared: 'kolom kontrak=1, baris kartu ter-render max=1',
            observed:
                'contract=${mobile.mobile?.columns} '
                'observed_max=${_maxLine(mobile.lines)} '
                'lines=${_linesText(mobile.lines)}',
          ),
        );
        checks.add(
          _boolCheck(
            area: areaMobile,
            check: 'initial_scroll_at_top',
            ok: mobile.pageScroll <= 0.5,
            declared: '0.0 offset scroll halaman pada paint pertama',
            observed:
                '${mobile.pageScroll.toStringAsFixed(1)} '
                '(vertical ancestors=${mobile.pageScrollAncestors})',
          ),
        );

        // ---- drawer (1180x900) ----
        // Pump ulang 1180: tree terakhir masih tier mobile (390) yang tidak
        // punya drawer toggle; kontrak `desktop` dipakai dari fakta awal.
        await _pump(tester, const Size(1180, 900));
        const areaDrawer = 'drawer';
        final toggle = find.byKey(
          const ValueKey('account-center-drawer-toggle'),
        );
        final drawerKey = find.byKey(
          const ValueKey('account-center-summary-drawer'),
        );
        await tester.tap(toggle);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        final openCount = drawerKey.evaluate().length;
        final drawerRect = openCount == 0 ? null : tester.getRect(drawerKey);
        final contentOpenRect = tester.getRect(
          find.byKey(const ValueKey('account-center-adaptive-content')),
        );
        final openException = _drain(tester);
        await tester.tap(toggle);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        final closeCount = drawerKey.evaluate().length;
        final closeException = _drain(tester);

        checks.add(
          _boolCheck(
            area: areaDrawer,
            check: 'toggle_opens_and_closes_drawer',
            ok: openCount == 1 && closeCount == 0,
            declared: 'tap#1 -> drawer 1, tap#2 -> drawer 0',
            observed: 'open=$openCount close=$closeCount',
          ),
        );
        checks.add(
          _numCheck(
            area: areaDrawer,
            check: 'drawer_width_matches_token',
            declared: AccountCenterDesignTokens.layout.rightSummaryWidth,
            observed: drawerRect?.width,
            note: 'lebar drawer == token ringkasan 115.5',
          ),
        );
        final mainWidthWhenOpen =
            desktop.adaptive?.mainWidthWhenDrawerOpen ?? -1;
        final minMain = AccountCenterDesignTokens.card.minWidth;
        checks.add(
          _boolCheck(
            area: areaDrawer,
            check: 'main_content_keeps_width',
            ok:
                desktop.adaptive != null &&
                (contentOpenRect.width - mainWidthWhenOpen).abs() <= 0.5 &&
                desktop.adaptive!.drawerKeepsMainVisible,
            declared:
                'konten utama saat drawer buka = '
                '${mainWidthWhenOpen.toStringAsFixed(1)} >= '
                '${minMain.toStringAsFixed(1)} (card.minWidth)',
            observed:
                'rendered=${contentOpenRect.width.toStringAsFixed(1)} '
                'keepVisible=${desktop.adaptive?.drawerKeepsMainVisible}',
            note: 'right_drawer tidak boleh menghapus konten utama',
          ),
        );
        checks.add(
          _boolCheck(
            area: areaDrawer,
            check: 'drawer_cycle_no_exception',
            ok: openException == 'none' && closeException == 'none',
            declared: 'exception none saat buka + tutup',
            observed: 'open=$openException close=$closeException',
          ),
        );

        // ---- reflow ----
        const areaReflow = 'reflow';
        final frameBelow = belowBoundary.frame;
        checks.add(
          _numCheck(
            area: areaReflow,
            check: 'columns_1920',
            declared: frameWide == null
                ? -1
                : frameWide.rowColumns
                      .reduce((a, b) => a > b ? a : b)
                      .toDouble(),
            observed: _maxLine(wide.lines).toDouble(),
            note: 'aturan fit frame 115.45 pada band main 1920',
          ),
        );
        final frameBoundary = boundary.frame;
        checks.add(
          _numCheck(
            area: areaReflow,
            check: 'columns_1440',
            declared: frameBoundary == null
                ? -1
                : frameBoundary.rowColumns
                      .reduce((a, b) => a > b ? a : b)
                      .toDouble(),
            observed: _maxLine(boundary.lines).toDouble(),
            note: 'aturan fit frame pada boundary 1440',
          ),
        );
        final content1180w = content1180?.width ?? -1;
        checks.add(
          _numCheck(
            area: areaReflow,
            check: 'columns_1180',
            declared: desktop.plan.columnsFor(content1180w).toDouble(),
            observed: _maxLine(desktop.lines).toDouble(),
            note: 'gridPlan.columnsFor(lebar konten terukur)',
          ),
        );
        final content900w = content900?.width ?? -1;
        checks.add(
          _numCheck(
            area: areaReflow,
            check: 'columns_900',
            declared: compact.plan.columnsFor(content900w).toDouble(),
            observed: _maxLine(compact.lines).toDouble(),
            note: 'gridPlan.columnsFor(lebar konten terukur)',
          ),
        );
        final content600w = content600?.width ?? -1;
        checks.add(
          _numCheck(
            area: areaReflow,
            check: 'columns_600',
            declared: tablet.plan.columnsFor(content600w).toDouble(),
            observed: _maxLine(tablet.lines).toDouble(),
            note: 'gridPlan.columnsFor(lebar konten terukur)',
          ),
        );
        checks.add(
          _numCheck(
            area: areaReflow,
            check: 'columns_mobile',
            declared: mobile.mobile?.columns.toDouble() ?? -1,
            observed: _maxLine(mobile.lines).toDouble(),
            note: 'kolom mobile 115.47 = 1',
          ),
        );
        final observedSequence = <int>[
          _maxLine(wide.lines),
          _maxLine(boundary.lines),
          _maxLine(desktop.lines),
          _maxLine(compact.lines),
          _maxLine(tablet.lines),
          _maxLine(mobile.lines),
        ];
        var monotone = true;
        for (var i = 1; i < observedSequence.length; i++) {
          if (observedSequence[i] > observedSequence[i - 1]) {
            monotone = false;
          }
        }
        final distinct = observedSequence.toSet().length;
        checks.add(
          _boolCheck(
            area: areaReflow,
            check: 'columns_track_viewport',
            ok: monotone && distinct >= 3,
            declared: 'urutan tak-naik 1920->390 dengan >=3 nilai berbeda',
            observed:
                '${_linesText(observedSequence)} distinct=$distinct '
                'monotone=$monotone',
            note: 'grid benar-benar mengikuti viewport, bukan beku',
          ),
        );
        final boundaryAdaptiveKeys = <String>[
          'account-center-desktop-left-navigation',
          'account-center-adaptive-content',
          'account-center-drawer-toggle',
        ];
        checks.add(
          _boolCheck(
            area: areaReflow,
            check: 'tier_boundary_1440',
            ok:
                belowBoundary.present(boundaryAdaptiveKeys) == 3 &&
                !belowBoundary.has('account-center-left-navigation') &&
                boundary.present(_frameKeys) == 4 &&
                !boundary.has('account-center-desktop-left-navigation'),
            declared: '1439=chrome adaptif 115.46, 1440=chrome frame 115.45',
            observed:
                '1439=${belowBoundary.present(boundaryAdaptiveKeys)}/3 '
                'frame_nav=${belowBoundary.has('account-center-left-navigation')} '
                '1440=${boundary.present(_frameKeys)}/4 '
                'adaptive_nav=${boundary.has('account-center-desktop-left-navigation')}',
            note:
                'tier=${belowBoundary.plan.breakpointName} vs '
                '${boundary.plan.breakpointName}; frameBelow='
                '${frameBelow != null}',
          ),
        );

        // ---- no_overflow ----
        const areaNoOverflow = 'no_overflow';
        final allFacts = <_Facts>[
          wide,
          boundary,
          belowBoundary,
          desktop,
          compact,
          tablet,
          mobile,
        ];
        checks.add(
          _boolCheck(
            area: areaNoOverflow,
            check: 'no_exception_viewports',
            ok: allFacts.every((f) => f.exception == 'none'),
            declared: 'exception none di 7 viewport',
            observed: allFacts
                .map((f) => '${f.size.width.toStringAsFixed(0)}:${f.exception}')
                .join(' '),
          ),
        );
        final paddingH = AccountCenterDesignTokens.layout.pageHorizontalPadding;
        final fitParts = <String>[];
        var bandsFit = true;
        for (final f in <_Facts>[desktop, compact, tablet]) {
          final rect = f.rect('account-center-adaptive-content');
          final limit = f.size.width - paddingH;
          final right = rect?.right ?? double.infinity;
          final ok = rect != null && right <= limit + 0.0001;
          if (!ok || f.adaptive?.bandsFit() != true) {
            bandsFit = false;
          }
          fitParts.add(
            '${f.size.width.toStringAsFixed(0)}:'
            '${right == double.infinity ? 'absent' : right.toStringAsFixed(1)}'
            '<=$limit(${f.adaptive?.bandsFit()})',
          );
        }
        checks.add(
          _boolCheck(
            area: areaNoOverflow,
            check: 'bands_fit_adaptive',
            ok: bandsFit,
            declared: 'band navigasi + konten <= lebar viewport - padding',
            observed: fitParts.join(' '),
            note: 'no_horizontal_overflow 115.46',
          ),
        );
        final mobileContent = mobile.rect('account-center-mobile-content');
        final mobileLimit = mobile.size.width - paddingH;
        checks.add(
          _boolCheck(
            area: areaNoOverflow,
            check: 'mobile_content_fits',
            ok:
                mobileContent != null &&
                mobileContent.right <= mobileLimit + 0.0001 &&
                mobileContent.height > 0 &&
                mobile.mobile?.contentAreaPositive == true,
            declared:
                'konten mobile <= ${mobileLimit.toStringAsFixed(1)} '
                'dan tinggi > 0',
            observed: mobileContent == null
                ? 'widget absent'
                : 'right=${mobileContent.right.toStringAsFixed(1)} '
                      'height=${mobileContent.height.toStringAsFixed(1)} '
                      'contentAreaPositive='
                      '${mobile.mobile?.contentAreaPositive}',
          ),
        );

        // ---- evaluasi gate ----
        final result = Sprint117ResponsiveLayoutValidation.evaluate(checks);
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
          Sprint117ResponsiveLayoutValidation.requiredAreas.toSet(),
          reason: 'delapan area required_evidence harus terukur',
        );
        expect(
          result.violationCodes,
          isEmpty,
          reason: result.violationCodes.join(', '),
        );

        // Cek terarah: mekanisme yang pernah fail-open tetap dipegang.
        final topNavVisible = result.checks.singleWhere(
          (c) => c.check == 'top_navigation_visible_on_open',
        );
        expect(
          topNavVisible.status,
          Sprint117ResponsiveStatus.pass,
          reason:
              'tablet membuka halaman dengan navigasi atas utuh: '
              'observed=${topNavVisible.observed}',
        );
        final tabletScroll = result.checks.singleWhere(
          (c) => c.area == '600' && c.check == 'initial_scroll_at_top',
        );
        expect(
          tabletScroll.status,
          Sprint117ResponsiveStatus.pass,
          reason: tabletScroll.observed,
        );
        final mobileScroll = result.checks.singleWhere(
          (c) => c.area == 'mobile' && c.check == 'initial_scroll_at_top',
        );
        expect(
          mobileScroll.status,
          Sprint117ResponsiveStatus.pass,
          reason: mobileScroll.observed,
        );
        final columnsTrack = result.checks.singleWhere(
          (c) => c.check == 'columns_track_viewport',
        );
        expect(
          columnsTrack.status,
          Sprint117ResponsiveStatus.pass,
          reason: columnsTrack.observed,
        );

        final writeManifest =
            Platform.environment['SPRINT_117_24_MANIFEST'] == '1';
        if (writeManifest) {
          File(_manifestPath).writeAsStringSync(
            '${const JsonEncoder.withIndent('  ').convert(result.toJson())}\n',
          );
        }
      },
    );

    testWidgets(
      'active tab reveal stays inside the horizontal strip after fix',
      (tester) async {
        // Niat `_revealInTabStrip` hanya "tab aktif terlihat di tab strip".
        // Dengan deep link `billing` di 600x800, strip tetap harus menggulir
        // horizontal KE tab billing, sedangkan scroll halaman vertikal
        // TIDAK ikut digeser (defect 117.24: nav atas terpotong 32.8px).
        tester.view.physicalSize = const Size(600, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: AccountCloudCenterScreen(
                snapshot: _guest,
                initialTab: 'billing',
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        final stripOffset = _stripHorizontalOffset(tester);
        expect(stripOffset, isNotNull, reason: 'strip horizontal harus ada');
        expect(
          stripOffset!,
          greaterThan(0.0),
          reason:
              'tab billing harus tergulir masuk ke strip '
              '(horizontal offset=$stripOffset)',
        );
        final vertical = _pageScrollMax(tester);
        expect(
          vertical,
          lessThanOrEqualTo(0.5),
          reason:
              'scroll halaman vertikal tidak boleh ikut digeser, '
              'observed=$vertical',
        );
        expect(_drain(tester), 'none');
      },
    );

    test('gate fails closed on structural holes', () {
      List<Sprint117ResponsiveCheck> minimal() => [
        for (final area in Sprint117ResponsiveLayoutValidation.requiredAreas)
          Sprint117ResponsiveCheck.pass(
            area: area,
            check: 'probe',
            declared: 'declared',
            observed: 'observed',
          ),
      ];

      final healthy = Sprint117ResponsiveLayoutValidation.evaluate(minimal());
      expect(healthy.pass, isTrue, reason: healthy.failures.toString());
      expect(healthy.failures, isEmpty);
      expect(healthy.openItems, isEmpty);

      final missingArea = List<Sprint117ResponsiveCheck>.from(minimal())
        ..removeWhere((c) => c.area == 'reflow');
      final missingResult = Sprint117ResponsiveLayoutValidation.evaluate(
        missingArea,
      );
      expect(missingResult.pass, isFalse);
      expect(missingResult.failures, contains('missing_area:reflow'));

      final vacuous = List<Sprint117ResponsiveCheck>.from(minimal())
        ..removeWhere((c) => c.area == 'reflow')
        ..add(
          Sprint117ResponsiveCheck.pass(
            area: 'reflow',
            check: 'probe',
            declared: 'declared',
            observed: '   ',
          ),
        );
      final vacuousResult = Sprint117ResponsiveLayoutValidation.evaluate(
        vacuous,
      );
      expect(vacuousResult.pass, isFalse);
      expect(vacuousResult.failures, contains('vacuous:reflow:probe'));

      final duplicate = <Sprint117ResponsiveCheck>[
        ...minimal(),
        minimal().first,
      ];
      final duplicateResult = Sprint117ResponsiveLayoutValidation.evaluate(
        duplicate,
      );
      expect(duplicateResult.pass, isFalse);
      expect(
        duplicateResult.failures,
        contains('duplicate_check:1440_plus:probe'),
      );

      final noPass = <Sprint117ResponsiveCheck>[
        for (final area in Sprint117ResponsiveLayoutValidation.requiredAreas)
          Sprint117ResponsiveCheck.unmet(
            area: area,
            check: 'probe',
            declared: 'declared',
            observed: 'observed',
          ),
      ];
      final noPassResult = Sprint117ResponsiveLayoutValidation.evaluate(noPass);
      expect(noPassResult.pass, isFalse);
      expect(noPassResult.failures, hasLength(8));
      expect(noPassResult.failures.first, 'area_without_pass:1440_plus');
      expect(noPassResult.openItems, hasLength(8));

      final violation = <Sprint117ResponsiveCheck>[
        for (final check in minimal())
          check.area == 'mobile'
              ? Sprint117ResponsiveCheck.violation(
                  area: 'mobile',
                  check: 'probe',
                  declared: 'declared',
                  observed: 'observed',
                )
              : check,
      ];
      final violationResult = Sprint117ResponsiveLayoutValidation.evaluate(
        violation,
      );
      expect(violationResult.pass, isFalse);
      expect(violationResult.violationCodes, ['mobile:probe']);

      final unknown = <Sprint117ResponsiveCheck>[
        ...minimal(),
        Sprint117ResponsiveCheck.pass(
          area: 'not_an_area',
          check: 'probe',
          declared: 'declared',
          observed: 'observed',
        ),
      ];
      final unknownResult = Sprint117ResponsiveLayoutValidation.evaluate(
        unknown,
      );
      expect(unknownResult.pass, isFalse);
      expect(unknownResult.failures, contains('unknown_area:not_an_area'));

      final empty = Sprint117ResponsiveLayoutValidation.evaluate(
        const <Sprint117ResponsiveCheck>[],
      );
      expect(empty.pass, isFalse);
      expect(empty.failures, ['no_checks']);
    });
  });
}
