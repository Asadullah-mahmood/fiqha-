import 'dart:async';
import 'dart:io';
import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/foundation.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:quranpak/screens/onBoarding/splashScreen.dart';
import 'package:quranpak/services/AzanService.dart';
import 'package:quranpak/services/FullSurahDownloadProvider.dart';
import 'package:quranpak/utils/AppTheme.dart';
import 'package:quranpak/utils/BookmarkProvider.dart';
import 'package:quranpak/utils/FullSurahPlayer.dart';
import 'package:quranpak/utils/LastReadProvider.dart';
import 'package:quranpak/utils/QuranAudioPlayer.dart';
import 'package:quranpak/utils/QuranProvider.dart';
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'firebase_options.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // sqfliteFfiInit is desktop-only — DO NOT run on Android/iOS.
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final downloadProvider = FullSurahDownloadProvider();
  final player = FullSurahPlayer();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  tz.initializeTimeZones();

  // 2. Init notifications
  await AzanService.init(flutterLocalNotificationsPlugin);

  final client = DorarClient();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  AudioPlayer.global.setAudioContext(
    AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: true,
        contentType: AndroidContentType.music,
        audioFocus: AndroidAudioFocus.gain,
        usageType: AndroidUsageType.media,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const {AVAudioSessionOptions.mixWithOthers},
      ),
    ),
  );

  final bookmarkProvider = BookmarkProvider();
  final lastReadProvider = LastReadProvider();
  final currentUser = FirebaseAuth.instance.currentUser;
  bookmarkProvider.bindUser(currentUser?.uid);
  lastReadProvider.bindUser(currentUser?.uid);

  // Listen to auth state to bind the user as soon as they sign in
  FirebaseAuth.instance.authStateChanges().listen((user) {
    bookmarkProvider.bindUser(user?.uid);
    lastReadProvider.bindUser(user?.uid);
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => QuranProvider()..bootstrap()),
        ChangeNotifierProvider(create: (context) => QuranAudioPlayer()),
        ChangeNotifierProvider.value(value: downloadProvider),
        ChangeNotifierProvider.value(value: player),
        ChangeNotifierProvider.value(value: bookmarkProvider),
        ChangeNotifierProvider.value(value: lastReadProvider),
      ],
      child: const MyApp(),
    ),
  );

  unawaited(
    AzanService.rescheduleFromCachedLocation().catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      debugPrint('Could not restore prayer alarms on startup: $error');
      debugPrintStack(stackTrace: stackTrace);
    }),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<PermissionStatus> getNotificationPermission() async {
    return await Permission.notification.request();
  }

  Future<PermissionStatus> getPermission() async {
    return await Permission.location.request();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    getPermission();
    AzanService.requestPermissions();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      debugShowMaterialGrid: false,
      title: 'Fiqah',
      theme: AppTheme.lightTheme,
      home: const Splashscreen(),
    );
  }
}
