// 이 파일은 `flutterfire configure` 명령으로 자동 생성된다.
// google-services.json을 android/app/에 추가한 뒤 아래 명령을 실행:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// 현재는 Firebase 프로젝트 연결 전 placeholder 파일이다.
// 실행 시 DefaultFirebaseOptions.currentPlatform은 실제 값으로 대체되어야 한다.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions는 이 플랫폼을 지원하지 않습니다. '
          'flutterfire configure를 실행해 실제 파일을 생성하세요.',
        );
    }
  }

  // TODO: flutterfire configure 실행 후 아래 값들을 실제 Firebase 프로젝트 값으로 교체하세요.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'PLACEHOLDER',
    appId: 'PLACEHOLDER',
    messagingSenderId: 'PLACEHOLDER',
    projectId: 'PLACEHOLDER',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'PLACEHOLDER',
    appId: 'PLACEHOLDER',
    messagingSenderId: 'PLACEHOLDER',
    projectId: 'PLACEHOLDER',
    storageBucket: 'PLACEHOLDER',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'PLACEHOLDER',
    appId: 'PLACEHOLDER',
    messagingSenderId: 'PLACEHOLDER',
    projectId: 'PLACEHOLDER',
    storageBucket: 'PLACEHOLDER',
    iosClientId: 'PLACEHOLDER',
    iosBundleId: 'PLACEHOLDER',
  );
}
