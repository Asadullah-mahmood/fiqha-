import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:quranpak/screens/Auth/Login.dart';
import 'package:quranpak/screens/HomeScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  @override
  void initState() {
    _navigate();
    super.initState();
  }

  void _navigate() async {
    final prefs = await SharedPreferences.getInstance();

   final isLoggedin = prefs.getBool("isLoggedIn") ?? false;


    await Future.delayed(Duration(seconds: 5), () {
      if(isLoggedin){
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return HomeScreen();
          },
        ),
      );
    }else {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              return LoginScreen();
            },
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Lottie.asset('assets/animations/splash.json', repeat: false),
      ),
    );
  }
}
