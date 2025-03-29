// loading_screen.dart
import 'dart:math' as math;

import 'package:crypto_navigator/main.dart';
import 'package:crypto_navigator/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class LoadingScreen extends StatefulWidget {
  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _initializeApp();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Always show loading screen for at least 3 seconds
    await Future.delayed(Duration(seconds: 3));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => AuthCheckScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDarkMode ? Color(0xFF03DAC6) : primaryColor.withOpacity(0.8);
    final textColor = Theme.of(context).textTheme.titleLarge?.color;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated crypto icon
            FadeIn(
              duration: Duration(milliseconds: 1200),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, child) {
                  return Transform.rotate(
                    angle: _controller.value * 2 * math.pi,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor,
                          width: 4,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.currency_bitcoin,
                          color: secondaryColor,
                          size: 60,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 30),

            // App name
            FadeIn(
              delay: Duration(milliseconds: 300),
              duration: Duration(milliseconds: 1500),
              child: Text(
                "CryptoNavigator",
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),

            SizedBox(height: 8),

            // Tagline
            FadeIn(
              delay: Duration(milliseconds: 600),
              duration: Duration(milliseconds: 1500),
              child: Text(
                "Track. Analyze. Predict.",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: textColor?.withOpacity(0.7),
                ),
              ),
            ),

            SizedBox(height: 40),

            // Progress indicator
            FadeIn(
              delay: Duration(milliseconds: 900),
              duration: Duration(milliseconds: 1500),
              child: Container(
                width: 200,
                child: LinearProgressIndicator(
                  backgroundColor:
                      isDarkMode ? Color(0xFF2A2A2A) : Color(0xFFF0F0F0),
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Separate authentication check screen
class AuthCheckScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final session = snapshot.data!.session;
          return session != null ? HomeScreen() : LoginScreen();
        }

        // Show a simpler loading indicator while checking auth state
        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
