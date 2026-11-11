import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static bool get isConfigured => true;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        return web;
    }
  }

  // Cấu hình Firebase cho dự án GiuaKi (giuaki-958ed)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAtA6IIQqvGylHFFyqWp905HYaW-DCISts',
    appId: '1:702548172635:web:7f4acbc4a2de3a802bc47e',
    messagingSenderId: '702548172635',
    projectId: 'giuaki-958ed',
    authDomain: 'giuaki-958ed.firebaseapp.com',
    storageBucket: 'giuaki-958ed.firebasestorage.app',
    measurementId: 'G-GJ7NPEBM0J',
  );

  // Cấu hình cho Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAtA6IIQqvGylHFFyqWp905HYaW-DCISts',
    appId: '1:702548172635:web:7f4acbc4a2de3a802bc47e',
    messagingSenderId: '702548172635',
    projectId: 'giuaki-958ed',
    storageBucket: 'giuaki-958ed.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAtA6IIQqvGylHFFyqWp905HYaW-DCISts',
    appId: '1:702548172635:web:7f4acbc4a2de3a802bc47e',
    messagingSenderId: '702548172635',
    projectId: 'giuaki-958ed',
    storageBucket: 'giuaki-958ed.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAtA6IIQqvGylHFFyqWp905HYaW-DCISts',
    appId: '1:702548172635:web:7f4acbc4a2de3a802bc47e',
    messagingSenderId: '702548172635',
    projectId: 'giuaki-958ed',
    storageBucket: 'giuaki-958ed.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAtA6IIQqvGylHFFyqWp905HYaW-DCISts',
    appId: '1:702548172635:web:7f4acbc4a2de3a802bc47e',
    messagingSenderId: '702548172635',
    projectId: 'giuaki-958ed',
    authDomain: 'giuaki-958ed.firebaseapp.com',
    storageBucket: 'giuaki-958ed.firebasestorage.app',
  );
}
