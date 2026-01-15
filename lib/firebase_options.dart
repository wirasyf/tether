// Firebase configuration for Tether app
// Project: tether-app-e4d6d (Singapore)

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
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
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Database URL from Singapore region
  static const String _databaseURL = 'https://tether-app-e4d6d-default-rtdb.asia-southeast1.firebasedatabase.app';
  static const String _projectId = 'tether-app-e4d6d';
  

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA8cH0Dd62MZ9Q6gz90XmUb8tuTkcNHXo0',
    appId: '1:595138255070:web:fc888a4e506a4087c1ca4f',
    messagingSenderId: '595138255070',
    projectId: 'tether-app-e4d6d',
    authDomain: 'tether-app-e4d6d.firebaseapp.com',
    databaseURL: 'https://tether-app-e4d6d-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'tether-app-e4d6d.firebasestorage.app',
    measurementId: 'G-1ZF4JESP67',
  );

  // Web config - You need to add a web app in Firebase Console and get these values

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD_b5rpvQrHXamLdax35APAyg4tbJxmKWc',
    appId: '1:595138255070:android:63f4abe8f3d45a42c1ca4f',
    messagingSenderId: '595138255070',
    projectId: 'tether-app-e4d6d',
    databaseURL: 'https://tether-app-e4d6d-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'tether-app-e4d6d.firebasestorage.app',
  );

  // Android config - You need to add an Android app and download google-services.json

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBE2TOcfn2vHMsZPaRtfc6iRQAYVVhwwFk',
    appId: '1:595138255070:ios:e37a4ebd3073f4c1c1ca4f',
    messagingSenderId: '595138255070',
    projectId: 'tether-app-e4d6d',
    databaseURL: 'https://tether-app-e4d6d-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'tether-app-e4d6d.firebasestorage.app',
    iosBundleId: 'com.example.tether',
  );

  // iOS config

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBE2TOcfn2vHMsZPaRtfc6iRQAYVVhwwFk',
    appId: '1:595138255070:ios:e37a4ebd3073f4c1c1ca4f',
    messagingSenderId: '595138255070',
    projectId: 'tether-app-e4d6d',
    databaseURL: 'https://tether-app-e4d6d-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'tether-app-e4d6d.firebasestorage.app',
    iosBundleId: 'com.example.tether',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA8cH0Dd62MZ9Q6gz90XmUb8tuTkcNHXo0',
    appId: '1:595138255070:web:95767dc4e0476172c1ca4f',
    messagingSenderId: '595138255070',
    projectId: 'tether-app-e4d6d',
    authDomain: 'tether-app-e4d6d.firebaseapp.com',
    databaseURL: 'https://tether-app-e4d6d-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'tether-app-e4d6d.firebasestorage.app',
    measurementId: 'G-2EKZYPKNG7',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyC_PLACEHOLDER_LINUX_API_KEY',
    appId: '1:PLACEHOLDER:linux:PLACEHOLDER',
    messagingSenderId: 'PLACEHOLDER',
    projectId: _projectId,
    databaseURL: _databaseURL,
  );
}