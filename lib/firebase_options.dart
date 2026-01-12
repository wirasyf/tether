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
  
  // Web config - You need to add a web app in Firebase Console and get these values
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC_PLACEHOLDER_WEB_API_KEY',
    appId: '1:PLACEHOLDER:web:PLACEHOLDER',
    messagingSenderId: 'PLACEHOLDER',
    projectId: _projectId,
    databaseURL: _databaseURL,
    authDomain: '$_projectId.firebaseapp.com',
  );

  // Android config - You need to add an Android app and download google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC_PLACEHOLDER_ANDROID_API_KEY',
    appId: '1:PLACEHOLDER:android:PLACEHOLDER',
    messagingSenderId: 'PLACEHOLDER',
    projectId: _projectId,
    databaseURL: _databaseURL,
  );

  // iOS config
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC_PLACEHOLDER_IOS_API_KEY',
    appId: '1:PLACEHOLDER:ios:PLACEHOLDER',
    messagingSenderId: 'PLACEHOLDER',
    projectId: _projectId,
    databaseURL: _databaseURL,
    iosBundleId: 'com.example.tether',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC_PLACEHOLDER_MACOS_API_KEY',
    appId: '1:PLACEHOLDER:macos:PLACEHOLDER',
    messagingSenderId: 'PLACEHOLDER',
    projectId: _projectId,
    databaseURL: _databaseURL,
    iosBundleId: 'com.example.tether',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC_PLACEHOLDER_WINDOWS_API_KEY',
    appId: '1:PLACEHOLDER:windows:PLACEHOLDER',
    messagingSenderId: 'PLACEHOLDER',
    projectId: _projectId,
    databaseURL: _databaseURL,
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyC_PLACEHOLDER_LINUX_API_KEY',
    appId: '1:PLACEHOLDER:linux:PLACEHOLDER',
    messagingSenderId: 'PLACEHOLDER',
    projectId: _projectId,
    databaseURL: _databaseURL,
  );
}
