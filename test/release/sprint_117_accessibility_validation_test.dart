import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/auth/auth_session.dart';
import 'package:void_scriptor/features/account/domain/account_center_accessibility.dart';
import 'package:void_scriptor/features/account/domain/account_center_design_tokens.dart';
import 'package:void_scriptor/features/account/domain/account_center_information_architecture.dart';
import 'package:void_scriptor/features/account/domain/account_center_keyboard_screen_reader_verification.dart';
import 'package:void_scriptor/features/account/domain/account_center_storage_usage_card.dart';
import 'package:void_scriptor/features/account/domain/account_cloud_snapshot.dart';
import 'package:void_scriptor/features/account/presentation/account_cloud_center_screen.dart';
import 'package:void_scriptor/features/account/presentation/storage_usage_card.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_accessibility_validation.dart';

/// 117.25 — Accessibility Validation drill.
///
/// Mengukur delapan area bukti wajib step kanonik `117.25`
/// (`keyboard`, `focus`, `screen_reader`, `status_text`, `chart_alternative`,
/// `progress_semantics`, `touch_targets`, `scaling`) langsung pada layar
/// Account & Cloud Center yang benar-benar dirender dan diinteraksikan.
///
/// Seluruh cek diikat ke [Sprint117AccessibilityValidation] dengan gerbang
/// gagal-tertutup: area yang hilang, vacuous, duplikat, atau memiliki
/// pelanggaran akan mematikan `pass`.

const String _manifestPath =
    'docs/evidence/sprint-117-25-manifest-20261001.json';

final AccountCloudSnapshot _guest = AccountCloudSnapshot.localOnly(
  session: const AuthSession.guest(),
);

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  double textScale = 1.0,
  bool disableAnimations = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
          ),
          child: AccountCloudCenterScreen(snapshot: _guest),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

String _drain(WidgetTester tester) {
  final collected = <String>[];
  Object? error;
  while ((error = tester.takeException()) != null) {
    collected.add(error.toString().split('\n').first);
  }
  return collected.isEmpty ? 'none' : collected.join(' | ');
}

void _walk(SemanticsNode? node, void Function(SemanticsNode) visit) {
  if (node == null) return;
  visit(node);
  node.visitChildren((child) {
    _walk(child, visit);
    return true;
  });
}

Sprint117AccessibilityCheck _boolCheck({
  required String area,
  required String check,
  required bool ok,
  required String declared,
  required String observed,
  String note = '',
}) => ok
    ? Sprint117AccessibilityCheck.pass(
        area: area,
        check: check,
        declared: declared,
        observed: observed,
        note: note,
      )
    : Sprint117AccessibilityCheck.violation(
        area: area,
        check: check,
        declared: declared,
        observed: observed,
        note: note,
      );

Sprint117AccessibilityCheck _numCheck({
  required String area,
  required String check,
  required double declared,
  required double? observed,
  double tolerance = 0.5,
  String observedFallback = 'widget absent',
  String note = '',
}) {
  if (observed == null) {
    return Sprint117AccessibilityCheck.violation(
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
      ? Sprint117AccessibilityCheck.pass(
          area: area,
          check: check,
          declared: declared.toStringAsFixed(1),
          observed: observedText,
          note: note,
        )
      : Sprint117AccessibilityCheck.violation(
          area: area,
          check: check,
          declared: declared.toStringAsFixed(1),
          observed: observedText,
          note: note,
        );
}

void main() {
  group('117.25 accessibility validation', () {
    testWidgets('gate passes on facts measured from the shipped screen', (
      tester,
    ) async {
      final checks = <Sprint117AccessibilityCheck>[];

      // ============================================================
      // 1. KEYBOARD (1440x900)
      // ============================================================
      const areaKeyboard = 'keyboard';
      await _pump(tester, const Size(1440, 900));

      // 1.1 Search button reachable on first tab
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final searchFinder = find.widgetWithIcon(IconButton, Icons.search);
      final focus1 = FocusManager.instance.primaryFocus;
      final searchBox = tester.renderObject<RenderBox>(searchFinder);
      final searchRect = searchBox.localToGlobal(Offset.zero) & searchBox.size;
      final fBox1 = (focus1?.context as Element?)?.renderObject as RenderBox?;
      final fRect1 = fBox1 != null
          ? fBox1.localToGlobal(Offset.zero) & fBox1.size
          : Rect.zero;
      checks.add(
        _boolCheck(
          area: areaKeyboard,
          check: 'first_stop_is_search',
          ok: fRect1.overlaps(searchRect),
          declared: 'stop #1 adalah tombol search header',
          observed:
              'focus=$fRect1 search=$searchRect overlaps=${fRect1.overlaps(searchRect)}',
          note: '115.7/115.48 keyboard baseline',
        ),
      );

      // 1.2 Nine tabs reached in canonical IA order
      final tabLabels = AccountCenterInformationArchitecture.tabs
          .map((t) => t.label)
          .toList();
      final stripFinder = find.byKey(
        const ValueKey('account-center-tab-strip'),
      );
      var tabsReached = 0;
      for (var i = 0; i < tabLabels.length; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 30));
        final expectedLabel = tabLabels[i];
        final tabTarget = find.descendant(
          of: stripFinder,
          matching: find.text(expectedLabel),
        );
        if (tabTarget.evaluate().isNotEmpty) {
          final tbBox = tester.renderObject<RenderBox>(tabTarget.first);
          final tbRect = tbBox.localToGlobal(Offset.zero) & tbBox.size;
          final fCur =
              (FocusManager.instance.primaryFocus?.context as Element?)
                      ?.renderObject
                  as RenderBox?;
          final fCurRect = fCur != null
              ? fCur.localToGlobal(Offset.zero) & fCur.size
              : Rect.zero;
          if (fCurRect.overlaps(tbRect)) {
            tabsReached++;
          }
        }
      }
      checks.add(
        _boolCheck(
          area: areaKeyboard,
          check: 'tabs_traversed_in_canonical_ia_order',
          ok: tabsReached == 9,
          declared: '9/9 tab IA kanonik tercapai berurutan lewat keyboard',
          observed: '$tabsReached/9 tab tercapai',
          note: 'Overview s/d Billing',
        ),
      );

      // 1.3 Panel actions reachable after tab strip
      var authButtonsReached = 0;
      for (var i = 0; i < 2; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final fCur =
            (FocusManager.instance.primaryFocus?.context as Element?)
                    ?.renderObject
                as RenderBox?;
        final fCurRect = fCur != null
            ? fCur.localToGlobal(Offset.zero) & fCur.size
            : Rect.zero;
        final editProfile = find.widgetWithText(OutlinedButton, 'Edit Profile');
        final addMethod = find.widgetWithText(
          OutlinedButton,
          '+ Add Another Method',
        );
        if (editProfile.evaluate().isNotEmpty &&
            fCurRect.overlaps(tester.getRect(editProfile))) {
          authButtonsReached++;
        } else if (addMethod.evaluate().isNotEmpty &&
            fCurRect.overlaps(tester.getRect(addMethod))) {
          authButtonsReached++;
        }
      }
      checks.add(
        _boolCheck(
          area: areaKeyboard,
          check: 'panel_actions_reachable',
          ok: authButtonsReached >= 2,
          declared: 'tombol aksi panel (Edit Profile & Add Method) tercapai',
          observed: '$authButtonsReached/2 tombol tercapai',
          note: '115.36 mockup auth stop',
        ),
      );

      // 1.4 Traversal loop does not trap and throws zero unhandled exceptions
      for (var i = 0; i < 10; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      checks.add(
        _boolCheck(
          area: areaKeyboard,
          check: 'traversal_no_exceptions',
          ok: _drain(tester) == 'none',
          declared: 'nol unhandled exception selama traversal keyboard',
          observed: 'exception=${_drain(tester)}',
        ),
      );

      // ============================================================
      // 2. FOCUS (ring, visibility, reduced motion)
      // ============================================================
      const areaFocus = 'focus';
      // 2.1 Tab focus ring width equals contract token
      Finder tabInk(String label) => find
          .ancestor(of: find.text(label), matching: find.byType(InkWell))
          .first;
      final overviewInk = tabInk('Overview');
      final animatedBox = tester.widget<AnimatedContainer>(
        find
            .descendant(
              of: overviewInk,
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      final decoration = animatedBox.decoration as BoxDecoration;
      final border = decoration.border as Border?;
      checks.add(
        _numCheck(
          area: areaFocus,
          check: 'tab_focus_ring_width',
          declared: AccountCenterAccessibility.tabFocusRingWidth,
          observed: border?.top.width,
          note: 'kontrak 115.7 tabFocusRingWidth=2px',
        ),
      );

      // 2.2 Tab active state carries Semantics isSelected
      final overviewSem = tester.getSemantics(overviewInk).getSemanticsData();
      checks.add(
        _boolCheck(
          area: areaFocus,
          check: 'active_tab_semantics_selected',
          ok: overviewSem.flagsCollection.isSelected == Tristate.isTrue,
          declared: 'tab aktif Overview memiliki Semantics isSelected=true',
          observed: 'isSelected=${overviewSem.flagsCollection.isSelected}',
          note: 'screen reader feedback',
        ),
      );

      // 2.3 Reduced motion disabled-animations ambient flag honored
      tester.view.reset();
      await _pump(tester, const Size(1440, 900), disableAnimations: true);
      final screenCtx = tester.element(find.byType(AccountCloudCenterScreen));
      final reducedHonored = AccountCenterAccessibility.reducedMotion(
        screenCtx,
      );
      checks.add(
        _boolCheck(
          area: areaFocus,
          check: 'reduced_motion_honored',
          ok: reducedHonored,
          declared: 'reducedMotion(context) membaca ambient disableAnimations',
          observed: 'reducedMotion=$reducedHonored',
          note: 'WCAG 2.3.3',
        ),
      );

      // 2.4 Focus reveal: SETIAP tab yang menerima fokus harus tergulir masuk
      // viewport strip horizontal.
      //
      // Fakta dari probe: framework traversal memanggil
      // `FocusTraversalPolicy.defaultTraversalRequestFocusCallback`, yang
      // memakai `Scrollable.ensureVisible(alignment: 1)` — HANYA menggulir
      // MAJU (`keepVisibleAtEnd`). Setelah traversal melewati seluruh strip
      // dan wrap ke awal, fokus kembali ke tab yang sudah tergulir ke luar
      // viewport, sementara strip tidak ikut bergulir balik: fokus mendarat di
      // x=-715.8 s/d -67.0 (probe3 #15-#18, probe7 #15-#18 & #29-#31).
      // Jadi yang diukur BUKAN "semua tab sekaligus terlihat" (9 tab
      // berjumlah ~1790px tak mungkin muat di 1440), melainkan: setiap
      // langkah traversal menjaga fokus yang sedang aktif di dalam viewport.
      tester.view.reset();
      await _pump(tester, const Size(1440, 900));
      var traversalSteps = 0;
      var focusKeptInView = 0;
      final outOfViewLog = <String>[];
      for (var i = 0; i < 26; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 30));
        final ctx = FocusManager.instance.primaryFocus?.context;
        if (ctx == null) continue;
        final ro = (ctx as Element).renderObject;
        if (ro is! RenderBox || !ro.attached) continue;
        final rect = ro.localToGlobal(Offset.zero) & ro.size;
        traversalSteps++;
        final inView =
            rect.left >= 0 && rect.right <= 1440 && rect.bottom <= 900;
        if (inView) {
          focusKeptInView++;
        } else if (outOfViewLog.length < 6) {
          outOfViewLog.add(
            '#$i left=${rect.left.toStringAsFixed(1)} '
            'right=${rect.right.toStringAsFixed(1)}',
          );
        }
      }
      checks.add(
        _boolCheck(
          area: areaFocus,
          check: 'focus_kept_in_view_during_traversal',
          ok: focusKeptInView == traversalSteps,
          declared:
              'setiap langkah traversal keyboard menyisakan fokus di dalam '
              'viewport (strip horizontal ikut digulir ke fokus)',
          observed:
              '$focusKeptInView/$traversalSteps langkah in-view'
              '${outOfViewLog.isEmpty ? '' : ' [oov ${outOfViewLog.join(' ')}]'}',
          note: 'WCAG 2.4.7 Focus Visible / traversal keep-visible',
        ),
      );

      // ============================================================
      // 3. SCREEN READER (semantics sweep 1440 & 390)
      // ============================================================
      // 117.25: node Semantics chart WAJIB diukur lewat `getSemantics(finder)`.
      // Menyusuri `rootSemanticsNode` lalu memfilter flag `isImage` returns 0
      // di test env: owner belum menyusun annotation tree platform, sehingga
      // node yang sebenarnya berlabel penuh (terbukti di probe8: 4 hit,
      // `isImage=true`) tak terlihat oleh filter itu. Kanal yang dipakai
      // platform untuk shed semantics adalah `getSemantics`.
      const areaScreenReader = 'screen_reader';
      tester.view.reset();
      await _pump(tester, const Size(1440, 900));

      // 3.1 Search button carries explicit semantics label
      final searchSemNode = tester.getSemantics(
        find.bySemanticsLabel(AccountCenterAccessibility.searchSemanticsLabel),
      );
      final searchData = searchSemNode.getSemanticsData();
      checks.add(
        _boolCheck(
          area: areaScreenReader,
          check: 'search_button_semantics_label',
          ok:
              searchData.label ==
              AccountCenterAccessibility.searchSemanticsLabel,
          declared: AccountCenterAccessibility.searchSemanticsLabel,
          observed: searchData.label,
          note: '115.7 screen reader label',
        ),
      );

      // 3.2 Provider semantics label format: "Name, Status"
      final pLabel = AccountCenterAccessibility.providerSemanticsLabel(
        'Google Drive',
        'Not connected',
      );
      const expectedPLabel = 'Google Drive, Not connected';
      checks.add(
        _boolCheck(
          area: areaScreenReader,
          check: 'provider_semantics_label_format',
          ok: pLabel == expectedPLabel,
          declared: expectedPLabel,
          observed: pLabel,
          note: 'AccountCenterAccessibility.providerSemanticsLabel contract',
        ),
      );

      // 3.3 Semantics nodes populated at 1440 (find.bySemanticsLabel)
      final tabSemLabels = find.bySemanticsLabel(
        RegExp('Overview|Connected Accounts|Cloud Storage'),
      );
      checks.add(
        _boolCheck(
          area: areaScreenReader,
          check: 'tab_semantics_labels_present',
          ok: tabSemLabels.evaluate().length >= 3,
          declared: '>=3 tab punya Semantics label eksplisit pada 1440x900',
          observed: '${tabSemLabels.evaluate().length} label ditemukan',
          note: 'IA kanonik sebagai label, bukan hanya glyph',
        ),
      );

      // 3.4 Mobile tree populated + provider tile labels via getSemantics
      tester.view.reset();
      await _pump(tester, const Size(390, 844));
      // ignore: deprecated_member_use
      final owner390 = tester.binding.pipelineOwner.semanticsOwner;
      var semNodeCount390 = 0;
      _walk(owner390?.rootSemanticsNode, (n) => semNodeCount390++);
      checks.add(
        _boolCheck(
          area: areaScreenReader,
          check: 'semantics_tree_populated_390',
          ok: semNodeCount390 >= 15 && _drain(tester) == 'none',
          declared: '>=15 Semantics node aktif pada 390x844',
          observed: '$semNodeCount390 node, exception=${_drain(tester)}',
        ),
      );

      // 3.5 Mobile provider tiles have actionable Semantics with label
      var mobileProviderSemCount = 0;
      // Label dirangkai dari nama provider + status di bawah "Provider details"
      // (lihat `_ProviderRow`), jadi exact match selalu 0 — harus pola.
      final mobileProviderDetails = find.bySemanticsLabel(
        RegExp(r'Provider details'),
      );
      final mobileProviderCount = mobileProviderDetails.evaluate().length;
      for (var i = 0; i < mobileProviderCount; i++) {
        final d = tester
            .getSemantics(mobileProviderDetails.at(i))
            .getSemanticsData();
        if (d.hasAction(SemanticsAction.tap)) mobileProviderSemCount++;
      }
      checks.add(
        _boolCheck(
          area: areaScreenReader,
          check: 'mobile_provider_details_accessible_labels',
          ok: mobileProviderSemCount >= 5,
          declared: '>=5 provider tiles berlabel "Provider details" di mobile',
          observed: '$mobileProviderSemCount tile actionable terdeteksi',
          note: '115.47 mobile provider sheet trigger',
        ),
      );

      // ============================================================
      // 4. STATUS TEXT
      // ============================================================
      // Section ini butuh tree 1440 (ringkasan "0 of N connected" hanya
      // dirender di panel desktop; pada 390 kartu itu tidak ada).
      const areaStatusText = 'status_text';
      tester.view.reset();
      await _pump(tester, const Size(1440, 900));

      // 4.1 Unconnected guest state emits explicit textual status
      final notConnectedFinder = find.text('Not connected');
      checks.add(
        _boolCheck(
          area: areaStatusText,
          check: 'unconnected_status_text_present',
          ok: notConnectedFinder.evaluate().isNotEmpty,
          declared: 'teks status "Not connected" hadir pada layar guest',
          observed: '${notConnectedFinder.evaluate().length} kemunculan',
        ),
      );

      // 4.2 Connection count summary present ("0 of 11 connected")
      final countSummaryFinder = find.textContaining('of 11 connected');
      checks.add(
        _boolCheck(
          area: areaStatusText,
          check: 'connection_count_summary_present',
          ok: countSummaryFinder.evaluate().isNotEmpty,
          declared: 'teks ringkasan "0 of 11 connected" hadir',
          observed: countSummaryFinder.evaluate().isNotEmpty
              ? 'hadir (${countSummaryFinder.evaluate().length})'
              : 'absent',
          note: 'status text agregat',
        ),
      );

      // 4.3 Section headers carry descriptive subtitles
      final subtitleFinder = find.text('Live balances from connected services');
      checks.add(
        _boolCheck(
          area: areaStatusText,
          check: 'section_subtitles_present',
          ok: subtitleFinder.evaluate().isNotEmpty,
          declared:
              'subjudul status "Live balances from connected services" hadir',
          observed: subtitleFinder.evaluate().isNotEmpty ? 'hadir' : 'absent',
        ),
      );

      // ============================================================
      // 5. CHART ALTERNATIVE
      // ============================================================
      // 117.25: alternatif teks chart TIDAK hidup di `Text` — ia adalah node
      // `Semantics(image: true, label: chartTextAlternative(...))` yang
      // membungkus `CustomPaint` (lihat `_AiUsageCard`/
      // `_StorageDistributionCard`). Jadi yang diukur adalah node semantics
      // `image` tersebut, bukan `find.text`. Alternatifnya dibangun dari
      // fakta yang sama dengan teks terlihat, jadi harus memuat judul kartu.
      const areaChart = 'chart_alternative';
      var imageNodes = 0;
      final imageLabels = <String>[];
      final chartFound = <String>[];
      for (final key in const [
        'account-ai-usage-chart',
        'account-storage-donut',
      ]) {
        final target = find.byKey(ValueKey(key));
        final found = target.evaluate().length;
        chartFound.add('$key=$found');
        if (found == 0) continue;
        final d = tester.getSemantics(target).getSemanticsData();
        chartFound.add('$key:isImage=${d.flagsCollection.isImage}');
        if (d.flagsCollection.isImage) {
          imageNodes++;
          imageLabels.add(d.label);
        }
      }
      const chartTitles =
          AccountCenterKeyboardScreenReader.requiredChartAlternatives;
      var chartsAlternativePresent = 0;
      final chartDetail = <String>[];
      for (final title in chartTitles) {
        final hit = imageLabels.any((l) => l.contains(title));
        if (hit) {
          chartsAlternativePresent++;
          chartDetail.add('$title=present');
        } else {
          chartDetail.add('$title=absent');
        }
      }
      checks.add(
        _boolCheck(
          area: areaChart,
          check: 'chart_semantics_alternatives_present',
          ok:
              chartsAlternativePresent == chartTitles.length &&
              imageNodes >= chartTitles.length,
          declared:
              '2/2 chart wajib punya Semantics image berlabel judul '
              '(115.7/115.47 requiredChartAlternatives)',
          observed:
              '$chartsAlternativePresent/2 [${chartDetail.join(' ')}] '
              'imageNode=$imageNodes [${chartFound.join(' ')}]',
          note: 'chartTextAlternative membungkus CustomPaint',
        ),
      );

      // Judul chart wajib muncul pada teks terlihat DAN pada label semantics
      // agar pembaca layar dan pembaca visual mendapat fakta yang sama.
      var chartsVisibleTitle = 0;
      final chartTitleDetail = <String>[];
      for (final title in chartTitles) {
        final inText = find.text(title).evaluate().isNotEmpty;
        final inSem = imageLabels.any((l) => l.contains(title));
        if (inText && inSem) chartsVisibleTitle++;
        chartTitleDetail.add('$title(text=$inText,sem=$inSem)');
      }
      checks.add(
        _boolCheck(
          area: areaChart,
          check: 'chart_title_parity_text_and_semantics',
          ok: chartsVisibleTitle == chartTitles.length,
          declared:
              '2/2 judul chart hadir pada teks terlihat dan label semantics',
          observed: '$chartsVisibleTitle/2 [${chartTitleDetail.join(' ')}]',
          note: 'WCAG 1.1.1 parity teks terlihat vs terbaca',
        ),
      );

      // 5.3 Service rows carry textual provider names alongside icons
      var namedServices = 0;
      for (final name in const [
        'Google Drive',
        'OneDrive',
        'Dropbox',
        'Mega',
        'Local storage',
      ]) {
        if (find.text(name).evaluate().isNotEmpty) {
          namedServices++;
        }
      }
      checks.add(
        _boolCheck(
          area: areaChart,
          check: 'services_have_text_names_alongside_icons',
          ok: namedServices == 5,
          declared: '5/5 service row memiliki nama tekstual eksplisit',
          observed: '$namedServices/5 nama terdeteksi',
          note: 'tidak mengandalkan icon semata',
        ),
      );

      // ============================================================
      // 6. PROGRESS SEMANTICS
      // ============================================================
      const areaProgress = 'progress_semantics';

      // 6.1 Empty guest storage usage card provides textual progress message
      final guestProgressSem = find.bySemanticsLabel(
        RegExp(r'Storage usage progress:'),
      );
      checks.add(
        _boolCheck(
          area: areaProgress,
          check: 'empty_guest_progress_semantics_present',
          ok: guestProgressSem.evaluate().isNotEmpty,
          declared:
              'Semantics berlabel "Storage usage progress: …" hadir di guest',
          observed: guestProgressSem.evaluate().isNotEmpty
              ? 'hadir (${guestProgressSem.evaluate().length})'
              : 'absent',
          note: 'StorageUsageCard fallback message',
        ),
      );

      // 6.2 Data fixture (75% used, 1.02 KB available of 4.1 KB)
      tester.view.reset();
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1;
      final freshFixture = StorageUsageCardData.fromBytes(
        providerId: 'google-drive',
        accountLabel: 'me@example.test',
        usedBytes: 3072,
        quotaBytes: 4096,
        measuredAt: DateTime.utc(2026, 10, 1, 6, 0),
        now: DateTime.utc(2026, 10, 1, 6, 30),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StorageUsageCard(data: freshFixture, onManage: () {}),
          ),
        ),
      );
      await tester.pump();
      // ignore: deprecated_member_use
      final fixtureOwner = tester.binding.pipelineOwner.semanticsOwner;
      String? fixtureLabel;
      String? fixtureValue;
      _walk(fixtureOwner?.rootSemanticsNode, (n) {
        final d = n.getSemanticsData();
        if (d.label.contains('Storage usage progress')) {
          fixtureLabel = d.label;
          fixtureValue = d.value;
        }
      });
      const expectedProgressMsg = '75% used, 1.02 KB available of 4.1 KB';
      checks.add(
        _boolCheck(
          area: areaProgress,
          check: 'fixture_progress_semantics_value',
          ok:
              fixtureValue == expectedProgressMsg &&
              fixtureLabel?.contains(expectedProgressMsg) == true,
          declared: 'value="$expectedProgressMsg"',
          observed: 'label="$fixtureLabel" value="$fixtureValue"',
          note: 'LinearProgressIndicator dibungkus teks terstruktur',
        ),
      );

      // 6.3 Fixture freshness status label present
      final freshnessFinder = find.text('Fresh');
      checks.add(
        _boolCheck(
          area: areaProgress,
          check: 'fixture_freshness_label_present',
          ok: freshnessFinder.evaluate().isNotEmpty,
          declared: 'label status "Fresh" hadir pada kartu fixture',
          observed: freshnessFinder.evaluate().isNotEmpty ? 'hadir' : 'absent',
        ),
      );

      // ============================================================
      // 7. TOUCH TARGETS (WCAG 44x44 minimum, tabs minimumKeyboardTarget)
      // ============================================================
      const areaTouch = 'touch_targets';
      tester.view.reset();
      await _pump(tester, const Size(1440, 900));

      // 7.1 Search icon button has 48x48 hit area
      final searchBox1440 = tester.renderObject<RenderBox>(searchFinder);
      checks.add(
        _boolCheck(
          area: areaTouch,
          check: 'search_button_touch_target_at_least_44',
          ok: searchBox1440.size.width >= 44 && searchBox1440.size.height >= 44,
          declared: '>= 44x44 (token minimumTouchTarget)',
          observed:
              '${searchBox1440.size.width.toStringAsFixed(1)}x'
              '${searchBox1440.size.height.toStringAsFixed(1)}',
          note: 'IconButton desktop',
        ),
      );

      // 7.2 Action buttons (Edit Profile, Add Method) have height >= 44
      final editProfileBtn = find.widgetWithText(
        OutlinedButton,
        'Edit Profile',
      );
      final epBox = tester.renderObject<RenderBox>(editProfileBtn);
      checks.add(
        _boolCheck(
          area: areaTouch,
          check: 'auth_action_buttons_height_at_least_44',
          ok: epBox.size.height >= 44,
          declared: 'height >= 44',
          observed: 'height=${epBox.size.height.toStringAsFixed(1)}',
          note: 'OutlinedButton',
        ),
      );

      // 7.3 Tabs height equals token tabBarHeight (40) >= minimumKeyboardTarget (32)
      final overviewRo = tester.renderObject<RenderBox>(overviewInk);
      checks.add(
        _numCheck(
          area: areaTouch,
          check: 'tab_height_matches_token',
          declared: AccountCenterDesignTokens.layout.tabBarHeight,
          observed: overviewRo.size.height,
          note: '40px memenuhi minimumKeyboardTarget=32px (115.7/115.5)',
        ),
      );

      // 7.4 Mobile quick-action tiles meet 44px minimum height
      tester.view.reset();
      await _pump(tester, const Size(390, 844));
      final backupTile = find.widgetWithText(ListTile, 'Backup Project');
      final backupBox = tester.renderObject<RenderBox>(backupTile);
      checks.add(
        _boolCheck(
          area: areaTouch,
          check: 'mobile_quick_action_tiles_height_at_least_44',
          ok: backupBox.size.height >= 44,
          declared: 'height >= 44',
          observed: 'height=${backupBox.size.height.toStringAsFixed(1)}',
          note: 'ListTile mobile',
        ),
      );

      // 7.5 Mobile bottom navigation action items meet 44px minimum
      final mobileNavSearch = find.widgetWithIcon(IconButton, Icons.search);
      final mSearchBox = tester.renderObject<RenderBox>(mobileNavSearch.first);
      checks.add(
        _boolCheck(
          area: areaTouch,
          check: 'mobile_nav_items_height_at_least_44',
          ok: mSearchBox.size.height >= 44,
          declared: 'height >= 44',
          observed: 'height=${mSearchBox.size.height.toStringAsFixed(1)}',
          note: 'bottom bar action',
        ),
      );

      // ============================================================
      // 8. SCALING (text scale 2.0 / 200% across viewports)
      // ============================================================
      const areaScaling = 'scaling';
      const scaleViewports = [
        Size(1920, 1080),
        Size(1180, 900),
        Size(600, 800),
        Size(390, 844),
      ];
      var viewportsScaledOk = 0;
      final scaleDetails = <String>[];
      for (final size in scaleViewports) {
        tester.view.reset();
        await _pump(tester, size, textScale: 2.0);
        final exc = _drain(tester);
        final hasTitle = find
            .text('ACCOUNT & CLOUD CENTER')
            .evaluate()
            .isNotEmpty;
        final pass = exc == 'none' && hasTitle;
        if (pass) viewportsScaledOk++;
        scaleDetails.add(
          '${size.width.toInt()}x${size.height.toInt()}:'
          '${pass ? 'pass' : 'fail(exc=$exc,title=$hasTitle)'}',
        );
      }
      checks.add(
        _boolCheck(
          area: areaScaling,
          check: 'text_scale_200_all_viewports',
          ok: viewportsScaledOk == scaleViewports.length,
          declared: '4/4 viewport me-render skala teks 200% tanpa crash',
          observed: scaleDetails.join(' '),
          note: 'WCAG 1.4.4 Resize text',
        ),
      );

      // 8.2 Layout reflows under text scale 200% without unbounded crashes
      checks.add(
        _boolCheck(
          area: areaScaling,
          check: 'scaling_no_unhandled_crashes',
          ok: viewportsScaledOk == 4,
          declared: 'nol crash unhandled pada seluruh pengujian 200%',
          observed: '$viewportsScaledOk/4 lulus',
        ),
      );

      // ============================================================
      // EVALUASI GATE
      // ============================================================
      final result = Sprint117AccessibilityValidation.evaluate(checks);
      final dump = checks
          .map(
            (c) =>
                '${c.status.name} ${c.code} declared=${c.declared} '
                'observed=${c.observed}',
          )
          .join('\n');
      expect(result.pass, isTrue, reason: 'failures=${result.failures}\n$dump');
      expect(
        result.checks.map((c) => c.area).toSet(),
        Sprint117AccessibilityValidation.requiredAreas.toSet(),
        reason: 'delapan area required_evidence harus terukur',
      );
      expect(
        result.violationCodes,
        isEmpty,
        reason: result.violationCodes.join(', '),
      );

      final writeManifest =
          Platform.environment['SPRINT_117_25_MANIFEST'] == '1';
      if (writeManifest) {
        File(_manifestPath).writeAsStringSync(
          '${const JsonEncoder.withIndent('  ').convert(result.toJson())}\n',
        );
      }
    });

    test('gate fails closed on structural holes', () {
      List<Sprint117AccessibilityCheck> minimal() => [
        for (final area in Sprint117AccessibilityValidation.requiredAreas)
          Sprint117AccessibilityCheck.pass(
            area: area,
            check: 'probe',
            declared: 'decl',
            observed: 'obs',
          ),
      ];

      expect(
        Sprint117AccessibilityValidation.evaluate(const []).pass,
        isFalse,
        reason: 'no_checks',
      );
      expect(
        Sprint117AccessibilityValidation.evaluate(minimal()).pass,
        isTrue,
        reason: 'minimal 8 pass',
      );

      // missing area
      final withoutScaling = minimal()
          .where((c) => c.area != 'scaling')
          .toList();
      final resMissing = Sprint117AccessibilityValidation.evaluate(
        withoutScaling,
      );
      expect(resMissing.pass, isFalse);
      expect(resMissing.failures, contains('missing_area:scaling'));

      // unknown area
      final withUnknown = [
        ...minimal(),
        Sprint117AccessibilityCheck.pass(
          area: 'color_contrast',
          check: 'foo',
          declared: 'd',
          observed: 'o',
        ),
      ];
      final resUnknown = Sprint117AccessibilityValidation.evaluate(withUnknown);
      expect(resUnknown.pass, isFalse);
      expect(resUnknown.failures, contains('unknown_area:color_contrast'));

      // duplicate check
      final withDup = [
        ...minimal(),
        Sprint117AccessibilityCheck.pass(
          area: 'keyboard',
          check: 'probe',
          declared: 'd',
          observed: 'o',
        ),
      ];
      final resDup = Sprint117AccessibilityValidation.evaluate(withDup);
      expect(resDup.pass, isFalse);
      expect(resDup.failures, contains('duplicate_check:keyboard:probe'));

      // vacuous declared & observed
      final withVac = [
        for (final c in minimal())
          if (c.area == 'keyboard')
            Sprint117AccessibilityCheck.pass(
              area: 'keyboard',
              check: 'probe',
              declared: '  ',
              observed: '',
            )
          else
            c,
      ];
      final resVac = Sprint117AccessibilityValidation.evaluate(withVac);
      expect(resVac.pass, isFalse);
      expect(
        resVac.failures,
        containsAll([
          'vacuous_declared:keyboard:probe',
          'vacuous:keyboard:probe',
        ]),
      );

      // area without pass
      final withoutPass = [
        for (final c in minimal())
          if (c.area == 'keyboard')
            Sprint117AccessibilityCheck.unmet(
              area: 'keyboard',
              check: 'probe',
              declared: 'd',
              observed: 'o',
            )
          else
            c,
      ];
      final resNoPass = Sprint117AccessibilityValidation.evaluate(withoutPass);
      expect(resNoPass.pass, isFalse);
      expect(resNoPass.failures, contains('area_without_pass:keyboard'));

      // violation blocks pass
      final withViolation = [
        ...minimal(),
        Sprint117AccessibilityCheck.violation(
          area: 'keyboard',
          check: 'bad',
          declared: 'd',
          observed: 'o',
        ),
      ];
      final resViol = Sprint117AccessibilityValidation.evaluate(withViolation);
      expect(resViol.pass, isFalse);
      expect(resViol.failures, contains('violation:keyboard:bad'));
    });
  });
}
