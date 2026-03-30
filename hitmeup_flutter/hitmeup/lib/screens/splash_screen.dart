import 'package:flutter/material.dart';
import '../services/auth_session.dart';
import '../widgets/common_widgets.dart';
import '../theme/app_theme.dart';
import 'mainApp/discover.dart';
import 'auth/sign_in_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isCheckingSession = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
    _restoreSession();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onLogoTap() {
    if (_isCheckingSession) {
      return;
    }

    final destination = AuthSession.instance.isLoggedIn
        ? const SwipeCardScreen()
        : const SignInScreen();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Future<void> _restoreSession() async {
    await AuthSession.instance.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _isCheckingSession = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: GestureDetector(
                onTap: _onLogoTap,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildLogoCircle(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoCircle() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/hitmeup.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.people_rounded, size: 80, color: AppColors.pinkTop),
        ),
      ),
    );
  }
}