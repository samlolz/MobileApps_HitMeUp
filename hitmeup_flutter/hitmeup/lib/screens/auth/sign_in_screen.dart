import 'package:flutter/material.dart';
import '../../widgets/common_widgets.dart';
import '../../theme/app_theme.dart';
import '../signup/step1_intro_screen.dart';
import '../mainApp/discover.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF448AFF),
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  _buildLogo(),
                  const SizedBox(height: 36),
                  const Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildTransparentField(
                    hint: 'Username or Email',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 14),
                  _buildTransparentField(
                    hint: 'Password',
                    icon: Icons.lock_outline_rounded,
                    obscure: true,
                  ),
                  const SizedBox(height: 24),
                  _buildButton(
                    label: 'LOGIN',
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const SwipeCardScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _googleIcon(),
                      const SizedBox(width: 20),
                      _appleIcon(),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDivider(),
                  const SizedBox(height: 20),
                  _buildButton(
                    label: 'Sign Up',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const Step1IntroScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 255,
      height: 255,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/hitmeup.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.people_rounded, size: 90, color: AppColors.pinkTop),
        ),
      ),
    );
  }

  Widget _buildTransparentField({
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6750A4),
          width: 1.5,
        ),
      ),
      child: TextField(
        obscureText: obscure,
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black54),
          prefixIcon: Icon(icon, color: Colors.black54, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildButton({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textDark,
          elevation: 3,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _googleIcon() {
    return GestureDetector(
      onTap: () {},
      child: Image.asset(
        'assets/google_icon.png',
        width: 36,
        height: 36,
      ),
    );
  }

  Widget _appleIcon() {
    return GestureDetector(
      onTap: () {},
      child: const Icon(
        Icons.apple_rounded,
        size: 40,
        color: Colors.black,
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: Colors.black26)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: Colors.black26)),
      ],
    );
  }
}