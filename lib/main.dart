import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:quranpak/screens/onBoarding/splashScreen.dart';
import 'package:quranpak/utils/AppTheme.dart';
import 'package:quranpak/utils/QuranAudioPlayer.dart';
import 'package:quranpak/utils/QuranProvider.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  tz.initializeTimeZones();

  // Initialize downloader
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => QuranProvider()),
        ChangeNotifierProvider(create: (context) => QuranAudioPlayer(),)
      ],
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<PermissionStatus> getPermission() async {
    return await Permission.location.request();
  }

  @override
  Widget build(BuildContext context) {
    getPermission();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fiqha',
      theme: AppTheme.lightTheme,
      home: const Splashscreen(),
    );
  }
}
