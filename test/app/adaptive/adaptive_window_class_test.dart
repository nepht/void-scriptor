import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/adaptive/adaptive_window_class.dart';

void main() {
  group('AdaptiveWindowClass', () {
    test('mengklasifikasikan lebar compact untuk mobile', () {
      expect(AdaptiveWindowClass.fromWidth(599), AdaptiveWindowClass.compact);
    });

    test('mengklasifikasikan lebar medium untuk tablet', () {
      expect(AdaptiveWindowClass.fromWidth(600), AdaptiveWindowClass.medium);
      expect(AdaptiveWindowClass.fromWidth(1199), AdaptiveWindowClass.medium);
    });

    test('mengklasifikasikan lebar expanded untuk desktop', () {
      expect(AdaptiveWindowClass.fromWidth(1200), AdaptiveWindowClass.expanded);
    });
  });
}
