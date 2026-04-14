import 'package:flutter/material.dart';
import '../../widgets/common_widgets.dart';
import '../mainApp/discover.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const TextStyle _headerTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 25,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.0,
    color: Colors.white,
  );

  static const TextStyle _subtitleTextStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 19,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.0,
    color: Colors.white70,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite_rounded,
                    size: 80, color: Colors.white),
                const SizedBox(height: 20),
                const Text(
                  'Welcome to HitMeUp! 🎉',
                  style: _headerTextStyle,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your profile is ready.\nStart connecting!',
                  textAlign: TextAlign.center,
                  style: _subtitleTextStyle,
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: PrimaryButton(
                    label: 'EXPLORE',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SwipeCardScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
