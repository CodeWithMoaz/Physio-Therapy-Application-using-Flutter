import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:physiotherapy/view/on_boarding/start_view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'common/color_extension.dart';

Future<void> testFirebaseConnection() async {
  try {
    await FirebaseFirestore.instance.collection('test').doc('test').get();
    debugPrint('Firebase connection is working perfectly!');
  } catch (e) {
    debugPrint('Firebase connection error: $e');
  }
}

Future<void> initializeAIPrograms() async {
  try {
    final aiPrograms = [
      {
        "injury": "Knee",
        "description":
            "Comprehensive knee rehabilitation program focusing on strength, stability, and mobility recovery. Suitable for all individuals with knee conditions.",
        "image": "assets/img/knee.png",
        "rating": 4.5,
        "isAI": true,
      },
      {
        "injury": "Ankle",
        "description":
            "Effective ankle rehabilitation program focusing on stability, flexibility, and strength recovery. Designed for all individuals with ankle conditions.",
        "image": "assets/img/ankle.png",
        "rating": 4.4,
        "isAI": true,
      },
      {
        "injury": "Shoulder",
        "description":
            "Comprehensive shoulder rehabilitation program focusing on mobility, strength, and stability. Suitable for all individuals with shoulder conditions.",
        "image": "assets/img/shoulder.png",
        "rating": 4.6,
        "isAI": true,
      },
      {
        "injury": "Lower Back",
        "description":
            "Gentle back pain management program focusing on posture correction, core strengthening, and flexibility. Designed for all individuals with back conditions.",
        "image": "assets/img/lower_back.png",
        "rating": 4.5,
        "isAI": true,
      },
    ];

    for (var program in aiPrograms) {
      await FirebaseFirestore.instance.collection('ai_programs').add(program);
    }

    debugPrint('AI programs initialized successfully!');
  } catch (e) {
    debugPrint('Error initializing AI programs: $e');
  }
}

Future<void> main() async {
  FlutterError.onError = (details) {
    debugPrint('FLUTTER ERROR: ${details.exception}\n${details.stack}');
  };

  WidgetsFlutterBinding.ensureInitialized();

  // The API key is optional; Firebase can initialize without a local .env file.
  await dotenv.load(fileName: ".env", isOptional: true);

  try {
    // Initialize Firebase with error handling
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    rethrow;
  }

  await testFirebaseConnection();

  // await initializeAIPrograms();

  runApp(const MyApp());

  // runApp(
  //   DevicePreview(
  //     enabled: !kReleaseMode,
  //     builder: (context) => const MyApp(),
  //   ),
  // );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sport Injury Rehab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: TColor.primaryColor1,
        fontFamily: "Poppins",
      ),
      home: const StartView(),
    );
  }
}
