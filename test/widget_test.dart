import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/main.dart';

void main() {
  testWidgets('menampilkan identitas aplikasi multiplatform', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: VoidScriptorApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Void Scriptor (Multiplatform)'), findsOneWidget);
    expect(find.text('Halo, Void Scriptor Multiplatform!'), findsOneWidget);
  });
}
