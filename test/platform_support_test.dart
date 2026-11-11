import 'package:flutter_test/flutter_test.dart';
import 'package:focus_clock/core/platform_support.dart';

void main() {
  test('does not subscribe to native app-link streams on web', () {
    expect(shouldSubscribeToAppLinks(isWeb: true), isFalse);
  });

  test('keeps native app-link streams enabled off web', () {
    expect(shouldSubscribeToAppLinks(isWeb: false), isTrue);
  });
}
