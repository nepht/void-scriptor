import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/adaptive/adaptive_window_class.dart';

void main() {
  group('AdaptiveWindowClass', () {
    test('phone berlaku hingga tepat sebelum 600', () {
      expect(AdaptiveWindowClass.fromWidth(0), AdaptiveWindowClass.phone);
      expect(AdaptiveWindowClass.fromWidth(599), AdaptiveWindowClass.phone);
    });

    test('tablet berlaku dari 600 hingga tepat sebelum 1024', () {
      expect(AdaptiveWindowClass.fromWidth(600), AdaptiveWindowClass.tablet);
      expect(AdaptiveWindowClass.fromWidth(1023), AdaptiveWindowClass.tablet);
    });

    test('compact desktop berlaku dari 1024 hingga tepat sebelum 1440', () {
      expect(
        AdaptiveWindowClass.fromWidth(1024),
        AdaptiveWindowClass.compactDesktop,
      );
      expect(
        AdaptiveWindowClass.fromWidth(1439),
        AdaptiveWindowClass.compactDesktop,
      );
    });

    test('desktop berlaku mulai 1440', () {
      expect(AdaptiveWindowClass.fromWidth(1440), AdaptiveWindowClass.desktop);
      expect(AdaptiveWindowClass.fromWidth(1920), AdaptiveWindowClass.desktop);
    });
  });
}
