// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBJg6SddYc-hrrfpFoDZjsxDQCSQostTWs',
    appId: '1:390443215780:web:0f0891d87298d57abb6f31',
    messagingSenderId: '390443215780',
    projectId: 'mt-dashboard-8f04f',
    authDomain: 'mt-dashboard-8f04f.firebaseapp.com',
    storageBucket: 'mt-dashboard-8f04f.firebasestorage.app',
    measurementId: 'G-50FR8FZP43',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCpjustFzuaw3BwShO-sm6g20wPB0wyb_w',
    appId: '1:390443215780:android:3c025028a9adb929bb6f31',
    messagingSenderId: '390443215780',
    projectId: 'mt-dashboard-8f04f',
    storageBucket: 'mt-dashboard-8f04f.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDxiyJEjHkKLhcf_49kLL3QAgRJrQSGAec',
    appId: '1:390443215780:ios:a2ce3b6698bc3c8cbb6f31',
    messagingSenderId: '390443215780',
    projectId: 'mt-dashboard-8f04f',
    storageBucket: 'mt-dashboard-8f04f.firebasestorage.app',
    iosClientId: '390443215780-4k2fu07nv95ltv3j1hffqjhnp0v1e0tc.apps.googleusercontent.com',
    iosBundleId: 'com.example.mtDashboard',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDxiyJEjHkKLhcf_49kLL3QAgRJrQSGAec',
    appId: '1:390443215780:ios:a2ce3b6698bc3c8cbb6f31',
    messagingSenderId: '390443215780',
    projectId: 'mt-dashboard-8f04f',
    storageBucket: 'mt-dashboard-8f04f.firebasestorage.app',
    iosClientId: '390443215780-4k2fu07nv95ltv3j1hffqjhnp0v1e0tc.apps.googleusercontent.com',
    iosBundleId: 'com.example.mtDashboard',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBJg6SddYc-hrrfpFoDZjsxDQCSQostTWs',
    appId: '1:390443215780:web:ee76203842947687bb6f31',
    messagingSenderId: '390443215780',
    projectId: 'mt-dashboard-8f04f',
    authDomain: 'mt-dashboard-8f04f.firebaseapp.com',
    storageBucket: 'mt-dashboard-8f04f.firebasestorage.app',
    measurementId: 'G-GXEW3XTP5E',
  );
}
