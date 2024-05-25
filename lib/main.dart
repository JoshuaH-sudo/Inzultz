import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inzultz/screens/auth.dart';
import 'package:inzultz/screens/send.dart';
import 'package:inzultz/models/db_collection.dart';
import 'firebase_options.dart';
import 'package:logging/logging.dart';

final log = Logger('MainScreen');
FirebaseAnalytics analytics = FirebaseAnalytics.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    print('Running in debug mode');
    try {
      // FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      // await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      // FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
    } catch (e) {
      // ignore: avoid_print
      print('Could not connect to emulators: $e');
    }
  }

  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return;
    }

    await FirebaseFirestore.instance
        .collection(DBCollection.users)
        .doc(currentUser.uid)
        .update({
      'FCMToken': fcmToken,
    });
  }).onError((err) {
    log.severe(err);
  });

  runApp(const ProviderScope(
    child: MainApp(),
  ));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  setFCMToken() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return;
    }

    final fcm = FirebaseMessaging.instance;
    final notificationSettings = await fcm.requestPermission();
    if (notificationSettings.authorizationStatus ==
        AuthorizationStatus.denied) {
      return;
    }
    final token = await fcm.getToken();

    await FirebaseFirestore.instance
        .collection(DBCollection.users)
        .doc(currentUser.uid)
        .update({
      'FCMToken': token,
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'inzultz',
      theme: ThemeData().copyWith(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 63, 17, 177)),
      ),
      home: StreamBuilder(
        // Can produce multiple values over time unlike FutureBuilder.
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            setFCMToken();
            return const SendScreen();
          }

          // if (snapshot.connectionState == ConnectionState.waiting) {
          //   // return const SplashScreen();
          // }
          return const AuthScreen();
        },
      ),
    );
  }
}
