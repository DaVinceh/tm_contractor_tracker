import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  // This will be initialized from google-services.json on Android
  // and GoogleService-Info.plist on iOS

  static Future<void> initialize() async {
    if (kIsWeb) {
      // Web configuration
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "YOUR_WEB_API_KEY",
          authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
          projectId: "YOUR_PROJECT_ID",
          storageBucket: "YOUR_PROJECT_ID.appspot.com",
          messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
          appId: "YOUR_APP_ID",
        ),
      );
    } else {
      // Mobile configuration (uses google-services.json on Android)
      await Firebase.initializeApp();
    }
  }
}
