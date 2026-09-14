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
    apiKey: 'AIzaSyDd4dJwKWhFN9AGtIFtcePvlzMwpQutc5A',
    appId: '1:924276518347:web:c0086c3046f35d9de65a4e',
    messagingSenderId: '924276518347',
    projectId: 'moaz4travel',
    authDomain: 'moaz4travel.firebaseapp.com',
    storageBucket: 'moaz4travel.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC8g6zIkien6yWRs_wauM5JmOwRlqwafOs',
    appId: '1:924276518347:android:9601cfd233e4a2c8e65a4e',
    messagingSenderId: '924276518347',
    projectId: 'moaz4travel',
    storageBucket: 'moaz4travel.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAC7Qtv_IZuWjmYJTlMCAaSIzHzkLfc-TQ',
    appId: '1:924276518347:ios:5fdeeb788a70f08ee65a4e',
    messagingSenderId: '924276518347',
    projectId: 'moaz4travel',
    storageBucket: 'moaz4travel.firebasestorage.app',
    iosBundleId: 'com.example.travel',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAC7Qtv_IZuWjmYJTlMCAaSIzHzkLfc-TQ',
    appId: '1:924276518347:ios:5fdeeb788a70f08ee65a4e',
    messagingSenderId: '924276518347',
    projectId: 'moaz4travel',
    storageBucket: 'moaz4travel.firebasestorage.app',
    iosBundleId: 'com.example.travel',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDd4dJwKWhFN9AGtIFtcePvlzMwpQutc5A',
    appId: '1:924276518347:web:4b43e3b5fbfc0f14e65a4e',
    messagingSenderId: '924276518347',
    projectId: 'moaz4travel',
    authDomain: 'moaz4travel.firebaseapp.com',
    storageBucket: 'moaz4travel.firebasestorage.app',
  );
}
