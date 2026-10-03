import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/content_capabilities/domain/content_capability_catalog.dart';
import 'package:void_scriptor/features/content_capabilities/presentation/content_capability_matrix_screen.dart';

/// Batas traversal. Siklus nyata di viewport lebar adalah 24 node
/// (1 kolom pencarian + 6 filter chip + 17 kartu modul), jadi 40 memberi
/// ruang untuk satu putaran penuh tanpa keliru berhenti di tengah.
const int _maxStops = 40;

/// Siklus fokus pada layout lebar, 24 node: kolom pencarian, enam chip
/// filter menurut nilai enum maturity, lalu 17 kartu modul sesuai urutan
/// katalog. Siklus ini bersifat melingkar, jadi urutan yang terukur dari
/// traversal selalu berupa rotasi dari daftar ini, tergantung node tempat
/// traversal mulai.
const List<String> _wideCycle = <String>[
  'Semua',
  'Full 0',
  'Partial 9',
  'Domain Only 6',
  'UI Only 1',
  'Planned 1',
  'Novel & Scene',
  'Character',
  'World & Locations',
  'Project Bible & Lore',
  'Timeline & Events',
  'Assets & References',
  'Cinema & Shots',
  'Audio, Music & SFX',
  'AI Generation Outputs',
  'Dialogue',
  'Plot, Subplot & Quest',
  'Pacing & POV',
  'Herbology & Alchemy',
  'Economy & Travel',
  'Culture, Language & Idioms',
  'Creature, Vehicle & Prop Cards',
  'Reader Annotations',
  'field:search',
];

/// Node fokus pada keadaan kosong: chip filter tetap ada, kartu modul hilang,
/// dan tombol pemulihan filter masuk sebagai ganti di posisi kartu pertama.
const List<String> _emptyCycle = <String>[
  'Semua',
  'Full 0',
  'Partial 9',
  'Domain Only 6',
  'UI Only 1',
  'Planned 1',
  'Reset filter',
  'field:search',
];

/// Rotasi siklus sehingga dimulai dari `anchor`.
///
/// Traversal melingkar, jadi node pertama yang tercatat bukan kontrak yang
/// relevan — yang relevan adalah urutan relatif dan penutupan siklusnya.
/// Fokus awal setelah `pumpWidget` belum ada, sehingga Tab pertama masuk dari
/// awal traversal (`field:search`); sedangkan setelah `enterText` fokus
/// tertahan di dalam `TextField` dan Tab pertama melompat ke node berikutnya.
/// Fokus dari `tap` tombol yang lalu hilang juga menerapkan aturan yang sama.
List<String> _rotatedTo(List<String> cycle, String anchor) {
  final index = cycle.indexOf(anchor);
  if (index < 0) {
    throw StateError('anchor "$anchor" tidak ada dalam siklus $cycle');
  }
  return <String>[...cycle.sublist(index), ...cycle.sublist(0, index)];
}

/// Membuktikan satu putaran penuh traversal: `count` node pertama membentuk
/// rotasi siklus dari `anchor`, dan node berikutnya kembali ke `anchor`.
void _expectFullCycle(
  List<({String label, Rect rect})> stops,
  List<String> cycle,
  String anchor,
) {
  expect(
    _labels(stops.take(cycle.length)),
    _rotatedTo(cycle, anchor),
    reason:
        'Urutan Tab harus mengikuti urutan baca layar sebagai satu siklus '
        'utuh: kolom pencarian, enam chip filter menurut nilai enum maturity, '
        'lalu kartu modul sesuai urutan katalog.',
  );
  expect(
    stops[cycle.length].label,
    anchor,
    reason:
        'Setelah satu putaran, traversal kembali ke node awal: siklus '
        'tertutup, tidak ada node yang tersesat, hilang, atau mengganda.',
  );
}

/// Label diambil dari `Text` pertama yang bukan `Icon` di subtree node fokus.
/// Kolom pencarian tidak punya `Text` di subtree fokusnya, jadi diberi label
/// eksplisit lewat jenis ancestor-nya.
String _labelOf(BuildContext focusContext) {
  if (focusContext.findAncestorWidgetOfExactType<TextField>() != null) {
    return 'field:search';
  }
  var text = '';
  void visit(Element element) {
    if (text.isNotEmpty) return;
    final widget = element.widget;
    if (widget is Icon) return;
    if (widget is Text && widget.data?.trim().isNotEmpty == true) {
      text = widget.data!.trim();
      return;
    }
    element.visitChildren(visit);
  }

  visit(focusContext as Element);
  return text.isEmpty ? 'widget:${focusContext.widget.runtimeType}' : text;
}

/// Traversal mentah tanpa deteksi siklus berbasis `Rect`.
///
/// Pada layar ini `Rect` kartu modul yang berada di bawah viewport dilaporkan
/// pada offset yang dijepit oleh cache sliver, sehingga beberapa kartu berbagi
/// `Rect` identik meski node fokusnya berbeda. Deteksi siklus berbasis `Rect`
/// akan berhenti lebih awal dan salah menghitung jumlah stop. Karena itu
/// siklus di sini dideteksi dari urutan label, bukan dari geometri.
Future<List<({String label, Rect rect})>> _stops(WidgetTester tester) async {
  final stops = <({String label, Rect rect})>[];
  for (var i = 0; i < _maxStops; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) break;
    final object = context.findRenderObject();
    final rect = object is RenderBox && object.hasSize
        ? object.localToGlobal(Offset.zero) & object.size
        : Rect.zero;
    stops.add((label: _labelOf(context), rect: rect));
  }
  return stops;
}

List<String> _labels(Iterable<({String label, Rect rect})> stops) =>
    stops.map((stop) => stop.label).toList();

/// Potret berhenti fokus milik satu siklus penuh saja.
///
/// Traversal sengaja dibaca melebihi satu siklus supaya penutupan siklus bisa
/// dibuktikan; seluruh helper geometri di bawah hanya boleh melihat satu
/// putaran agar indeksnya tidak bergeser saat siklus berulang.
List<({String label, Rect rect})> _oneCycle(
  List<({String label, Rect rect})> stops,
  List<String> cycle,
) => stops.take(cycle.length).toList();

/// Enam node chip filter, dalam urutan enum maturity.
///
/// Dipilih lewat label, bukan lewat indeks tetap, supaya pemeriksaan
/// geometri tetap benar walau traversal dimulai dari titik berbeda pada siklus.
List<Rect> _chipRects(List<({String label, Rect rect})> stops) => <Rect>[
  for (final stop in stops)
    if (_chipLabels.contains(stop.label)) stop.rect,
];

/// Node kartu modul, yaitu seluruh node siklus di luar chip filter dan kolom
/// pencarian.
List<Rect> _cardRects(List<({String label, Rect rect})> stops) => <Rect>[
  for (final stop in stops)
    if (!_chipLabels.contains(stop.label) && stop.label != 'field:search')
      stop.rect,
];

const List<String> _chipLabels = <String>[
  'Semua',
  'Full 0',
  'Partial 9',
  'Domain Only 6',
  'UI Only 1',
  'Planned 1',
];

Widget _screen() => const MaterialApp(home: ContentCapabilityMatrixScreen());

void _viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('Content Capability Matrix Screen — kontrak focus order 2.4.3', () {
    testWidgets('viewport lebar menyisir tepat 24 node lalu mengulang', (
      tester,
    ) async {
      _viewport(tester, const Size(1536, 1024));
      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();

      final stops = await _stops(tester);

      expect(stops.length, greaterThanOrEqualTo(_wideCycle.length + 1));
      _expectFullCycle(stops, _wideCycle, 'field:search');
      expect(
        stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
        isTrue,
        reason: 'Setiap stop fokus harus punya area non-zero.',
      );
    });

    testWidgets('jumlah kartu modul fokus sama dengan katalog', (tester) async {
      _viewport(tester, const Size(1536, 1024));
      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();

      final stops = await _stops(tester);

      // Siklus: 6 chip filter, 1 kolom pencarian, 17 kartu modul. Putar ke
      // anchor kolom pencarian supaya kartu mulai pada indeks 7.
      final cardLabels = _rotatedTo(
        _labels(stops.take(_wideCycle.length)),
        'field:search',
      ).skip(7).toList();
      expect(
        cardLabels.length,
        ContentCapabilityCatalog.modules.length,
        reason:
            'Setiap modul di katalog harus punya tepat satu header '
            '`ExpansionTile` yang bisa difokus; tidak boleh ada modul yang '
            'lewat dari traversal.',
      );
      expect(
        cardLabels,
        ContentCapabilityCatalog.modules.map((module) => module.label).toList(),
        reason:
            'Urutan kartu fokus mengikuti urutan katalog, bukan urutan '
            'geometri render.',
      );
    });

    testWidgets('chip filter dibaca mendatar lalu turun ke baris berikutnya', (
      tester,
    ) async {
      _viewport(tester, const Size(1536, 1024));
      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();

      final stops = await _stops(tester);
      final chipRects = _chipRects(_oneCycle(stops, _wideCycle));

      // Baris chip pada 1536 px: [Semua, Full, Partial, Domain Only],
      // lalu [UI Only, Planned].
      expect(
        chipRects[0].top,
        chipRects[1].top,
        reason: 'Semua dan Full berbagi satu baris fokus.',
      );
      expect(
        chipRects[1].top,
        chipRects[2].top,
        reason: 'Full dan Partial berbagi satu baris fokus.',
      );
      expect(
        chipRects[2].top,
        chipRects[3].top,
        reason: 'Partial dan Domain Only berbagi satu baris fokus.',
      );
      expect(
        chipRects[0].left,
        lessThan(chipRects[1].left),
        reason: 'Semua dibaca sebelum Full (kiri ke kanan).',
      );
      expect(
        chipRects[1].left,
        lessThan(chipRects[2].left),
        reason: 'Full dibaca sebelum Partial (kiri ke kanan).',
      );
      expect(
        chipRects[4].top,
        chipRects[5].top,
        reason: 'UI Only dan Planned berbagi baris fokus kedua.',
      );
      expect(
        chipRects[4].left,
        lessThan(chipRects[5].left),
        reason: 'UI Only dibaca sebelum Planned (kiri ke kanan).',
      );
      expect(
        chipRects[4].top,
        greaterThan(chipRects[3].top),
        reason: 'Baris kedua chip harus turun, bukan tetap di baris pertama.',
      );
      expect(
        chipRects.last.right,
        lessThanOrEqualTo(1536),
        reason: 'Chip terakhir tidak boleh meluber melewati viewport.',
      );
    });

    testWidgets('kartu modul satu kolom penuh dan dibaca atas ke bawah', (
      tester,
    ) async {
      _viewport(tester, const Size(1536, 1024));
      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();

      final stops = await _stops(tester);
      final cycle = _oneCycle(stops, _wideCycle);
      final cardRects = _cardRects(cycle);

      expect(
        cardRects.map((rect) => rect.width).toSet().length,
        1,
        reason: 'Semua kartu modul memakai satu lebar kolom penuh yang sama.',
      );
      expect(
        cardRects.map((rect) => rect.left).toSet().length,
        1,
        reason: 'Semua kartu modul sejajar pada satu margin kiri yang sama.',
      );
      // Hanya delapan kartu pertama yang benar-benar ter-layout di dalam
      // viewport; kartu berikutnya ada di luar area terlihat sehingga `Rect`
      //-nya dijepit cache sliver dan tidak boleh dipakai sebagai bukti urutan.
      for (var i = 1; i < 8; i++) {
        expect(
          cardRects[i].top,
          greaterThan(cardRects[i - 1].top),
          reason: 'Kartu modul fokus harus dibaca atas ke bawah.',
        );
      }
      final chipRects = _chipRects(cycle);
      expect(
        cardRects.first.top,
        greaterThan(chipRects.last.bottom),
        reason:
            'Kartu modul pertama harus muncul setelah baris chip filter '
            'terakhir, bukan tumpang tindih dengannya.',
      );
      expect(
        cardRects.last.right,
        lessThanOrEqualTo(1536),
        reason: 'Kartu modul tidak boleh meluber melewati viewport.',
      );
    });

    testWidgets('viewport sempit tetap menyisir 24 node tanpa kontrol hilang', (
      tester,
    ) async {
      _viewport(tester, const Size(390, 844));
      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();

      final stops = await _stops(tester);

      expect(tester.takeException(), isNull);
      expect(stops.length, greaterThanOrEqualTo(_wideCycle.length + 1));
      _expectFullCycle(stops, _wideCycle, 'field:search');
      expect(
        stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
        isTrue,
      );
      expect(
        stops.every((stop) => stop.rect.right <= 390.5),
        isTrue,
        reason:
            'Tidak ada node fokus yang boleh meluber melewati viewport '
            'sempit.',
      );
    });

    testWidgets(
      'sempit: chip membungkus ke empat baris dan kartu jadi satu kolom',
      (tester) async {
        _viewport(tester, const Size(390, 844));
        await tester.pumpWidget(_screen());
        await tester.pumpAndSettle();

        final stops = await _stops(tester);
        final cycle = _oneCycle(stops, _wideCycle);
        final chipRects = _chipRects(cycle);

        // Baris chip pada 390 px: [Semua, Full], [Partial], [Domain Only],
        // [UI Only, Planned].
        expect(
          chipRects[0].top,
          chipRects[1].top,
          reason: 'Semua dan Full masih sebaris di viewport sempit.',
        );
        expect(
          chipRects[2].top,
          greaterThan(chipRects[1].top),
          reason: 'Partial turun ke baris ketiga karena tidak cukup ruang.',
        );
        expect(
          chipRects[3].top,
          greaterThan(chipRects[2].top),
          reason: 'Domain Only turun ke baris keempat.',
        );
        expect(
          chipRects[4].top,
          chipRects[5].top,
          reason: 'UI Only dan Planned kembali sebaris di baris terakhir chip.',
        );
        expect(
          chipRects[4].left,
          lessThan(chipRects[5].left),
          reason: 'UI Only dibaca sebelum Planned pada baris yang sama.',
        );

        expect(
          _cardRects(cycle).map((rect) => rect.width).toSet().length,
          1,
          reason: 'Di bawah 480 px seluruh kartu memakai satu kolom.',
        );
      },
    );

    testWidgets('keadaan kosong menyisakan delapan node dan tombol pemulihan', (
      tester,
    ) async {
      _viewport(tester, const Size(1536, 1024));
      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('content-capability-search')),
        'zzzqqqxxx',
      );
      await tester.pumpAndSettle();

      final stops = await _stops(tester);

      expect(stops.length, greaterThanOrEqualTo(_emptyCycle.length + 1));
      // `enterText` menahan fokus di dalam kolom pencarian, jadi traversal
      // dimulai dari node sesudahnya, yaitu chip filter pertama.
      _expectFullCycle(stops, _emptyCycle, 'Semua');
      expect(
        find.byType(ExpansionTile),
        findsNothing,
        reason: 'Kartu modul hilang saat tidak ada hasil pencarian.',
      );
      expect(
        stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
        isTrue,
        reason: 'Tombol pemulihan filter tetap punya area fokus non-zero.',
      );
    });

    testWidgets('tombol pemulihan filter mengembalikan daftar modul', (
      tester,
    ) async {
      _viewport(tester, const Size(1536, 1024));
      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('content-capability-search')),
        'zzzqqqxxx',
      );
      await tester.pumpAndSettle();
      expect(find.text('Reset filter'), findsOneWidget);

      await tester.tap(find.text('Reset filter'));
      await tester.pumpAndSettle();

      expect(find.text('Reset filter'), findsNothing);
      final restored = await _stops(tester);
      expect(restored.length, greaterThanOrEqualTo(_wideCycle.length + 1));
      // Node tombol pemulihan hilang dari pohon, jadi FocusManager mengembalikan
      // fokus ke akar scope dan traversal berikutnya masuk dari awal lagi —
      // persis seperti keadaan sebelum filter diisi.
      _expectFullCycle(restored, _wideCycle, 'Semua');
    });
  });
}
