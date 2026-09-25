import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gif_view/gif_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

import 'package:quranpak/models/UserModel.dart';
import 'package:quranpak/screens/Auth/askFiqha.dart';
import 'package:quranpak/screens/HomeScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  /// Shows a toastification error/success message.
  void _showToast({
    required String title,
    required String description,
    required ToastificationType type,
  }) {
    toastification.show(
      context: context,
      type: type,
      title: Text(title),
      description: Text(description),
      autoCloseDuration: const Duration(seconds: 3),
      alignment: Alignment.topCenter,
      borderRadius: BorderRadius.circular(12),
    );
  }

  Future<void> _continueWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();

      final GoogleSignInAccount? googleUser =
      await googleSignIn.authenticate(scopeHint: ['email', 'profile']);

      if (googleUser == null) {
        // User cancelled the picker
        setState(() => _isLoading = false);
        return;
      }

      final authClient = googleUser.authorizationClient;
      final authorization =
      await authClient.authorizeScopes(['email', 'profile']);

      final String? accessToken = authorization.accessToken;
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'idToken is missing';
      }

      final credentials = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );

      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credentials);

      final user = userCredential.user;

      if (user == null) {
        _showToast(
          title: 'Error',
          description: 'Could not retrieve account. Please try again.',
          type: ToastificationType.error,
        );
        return;
      }

      _showToast(
        title: 'Welcome',
        description: 'Signed in as ${user.email}',
        type: ToastificationType.success,
      );

      // Check if user exists in Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // Create new user record
        final newUser = UserModel(
          id: user.uid,
          name: user.displayName,
          email: user.email,
          photoUrl: user.photoURL,
        );
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(newUser.toMap());


        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const askFiqha()),
          );
        }
      } else {
        // User exists, check maslak


        final data = userDoc.data();
        if (data != null && data['maslak'] != null) {
          if (mounted) {
            await prefs.setBool('isLoggedIn', true);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        } else {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const askFiqha()),
            );
          }
        }
      }
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        _showToast(
          title: 'Cancelled',
          description: 'Sign-in cancelled.',
          type: ToastificationType.warning,
        );
      } else {
        _showToast(
          title: 'Google Sign-In Failed',
          description: '${e.code}',
          type: ToastificationType.error,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showToast(
        title: 'Authentication Failed',
        description: e.message ?? 'Unknown error',
        type: ToastificationType.error,
      );
    } catch (e) {
      _showToast(
        title: 'Sign-in Failed',
        description: e.toString(),
        type: ToastificationType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // App logo — animated Quran GIF
              Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(20),
                child: GifView.asset(
                  'assets/image/quran.gif',
                  fit: BoxFit.contain,
                  frameRate: 30,
                ),
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                'Welcome Back',
                style: GoogleFonts.lato(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Sign in to continue your journey',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                ),
              ),

              const Spacer(flex: 3),

              // Continue with Google button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _continueWithGoogle,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade300, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Color(0xFF1B5E20),
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.google,
                        color: Colors.grey.shade600,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Continue with Google',
                        style: GoogleFonts.lato(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Terms text
              Text(
                'By continuing, you agree to our Terms & Privacy Policy.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 12,
                  color: Colors.black45,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}