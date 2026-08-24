import 'package:flutter_test/flutter_test.dart';
import 'package:focus_clock/firebase_options.dart';

void main() {
  group('DefaultFirebaseOptions', () {
    test('Web options contain valid rync432 credentials', () {
      final web = DefaultFirebaseOptions.web;
      expect(web.projectId, 'rync432');
      expect(web.apiKey, 'AIzaSyB7F4Hjqs9K3R2qu1AJ8eobgdW_eXHTlDw');
      expect(web.appId, '1:607666586504:web:0141bd10c4ca3fde58303d');
      expect(web.authDomain, 'rync432.firebaseapp.com');
      expect(web.storageBucket, 'rync432.firebasestorage.app');
    });

    test('Android options contain valid rync432 credentials', () {
      final android = DefaultFirebaseOptions.android;
      expect(android.projectId, 'rync432');
      expect(android.apiKey, 'AIzaSyBwl3JlTDzbdCEpHlBM-jb6_k1KZ7SO1tY');
      expect(android.appId, '1:607666586504:android:e1b67edc1c08371558303d');
      expect(android.storageBucket, 'rync432.firebasestorage.app');
    });

    test('Desktop options (Windows & Linux) configured properly', () {
      final linux = DefaultFirebaseOptions.linux;
      expect(linux.projectId, 'rync432');
      expect(linux.apiKey.isNotEmpty, isTrue);

      final windows = DefaultFirebaseOptions.windows;
      expect(windows.projectId, 'rync432');
      expect(windows.apiKey.isNotEmpty, isTrue);
    });
  });
}
