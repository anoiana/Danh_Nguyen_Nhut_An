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
    apiKey: 'AIzaSyCu6DchQoQb4Iiw58_OxAYgoiQKLsJy6nM',
    appId: '1:458510471300:web:8ef22f10a2324fdae6b2d1',
    messagingSenderId: '458510471300',
    projectId: 'flutterfinal-34766',
    authDomain: 'flutterfinal-34766.firebaseapp.com',
    storageBucket: 'flutterfinal-34766.firebasestorage.app',
    measurementId: 'G-N74P3BCNL4',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBcLBGcp5jIrMsbLhfMwyWfUxLBdXe5tw8',
    appId: '1:458510471300:android:dd50a226da2de2b4e6b2d1',
    messagingSenderId: '458510471300',
    projectId: 'flutterfinal-34766',
    storageBucket: 'flutterfinal-34766.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBf4etG2KatXlp3Zo7nnf4bCEqv0vYnj88',
    appId: '1:458510471300:ios:3601e0931d11f1dfe6b2d1',
    messagingSenderId: '458510471300',
    projectId: 'flutterfinal-34766',
    storageBucket: 'flutterfinal-34766.firebasestorage.app',
    iosBundleId: 'com.example.crossPlatformMobileAppDevelopment',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBf4etG2KatXlp3Zo7nnf4bCEqv0vYnj88',
    appId: '1:458510471300:ios:3601e0931d11f1dfe6b2d1',
    messagingSenderId: '458510471300',
    projectId: 'flutterfinal-34766',
    storageBucket: 'flutterfinal-34766.firebasestorage.app',
    iosBundleId: 'com.example.crossPlatformMobileAppDevelopment',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCu6DchQoQb4Iiw58_OxAYgoiQKLsJy6nM',
    appId: '1:458510471300:web:28227c3548e4c0e4e6b2d1',
    messagingSenderId: '458510471300',
    projectId: 'flutterfinal-34766',
    authDomain: 'flutterfinal-34766.firebaseapp.com',
    storageBucket: 'flutterfinal-34766.firebasestorage.app',
    measurementId: 'G-2QDFXLC7FY',
  );
}
