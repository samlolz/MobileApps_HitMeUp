import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/api_config.dart';
import '../../services/auth_session.dart';
import '../../services/oauth_service.dart';
import '../../widgets/common_widgets.dart';
import '../../theme/app_theme.dart';
import '../signup/step1_intro_screen.dart';
import '../mainApp/discover.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isSubmitting = false;
  String? _submitError;
  bool _isGoogleLoading = false;
  final OAuthService _oauthService = OAuthService();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleLoading) return;

    setState(() {
      _isGoogleLoading = true;
      _submitError = null;
    });

    try {
      final result = await _oauthService.signInWithGoogle();

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _submitError = 'Google sign-in failed or was cancelled.';
        });
        return;
      }

      final status = result['status'] as String?;
      if (status == 'linked') {
        final linkedUser = result['user'];
        if (linkedUser is Map<String, dynamic>) {
          await AuthSession.instance.saveUser(linkedUser);
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SwipeCardScreen()),
          );
          return;
        }
      }

      if (status == 'signup_required') {
        final prefillEmail = (result['email'] as String?) ?? '';
        final prefillName = (result['name'] as String?) ?? '';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Step1IntroScreen(
              initialName: prefillName,
              initialEmail: prefillEmail,
            ),
          ),
        );
        return;
      }

      setState(() {
        _submitError = (result['detail'] as String?) ?? 'Google sign-in failed.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitError = 'Google sign-in error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  Future<void> _submitSignIn() async {
    if (_isSubmitting) {
      return;
    }

    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      setState(() {
        _submitError = 'Please enter both username/email and password.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/login/');

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'identifier': identifier,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (!mounted) {
        return;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final user = _tryParseUserObject(response.body);
        if (user != null) {
          await AuthSession.instance.saveUser(user);
        }

        if (!mounted) {
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SwipeCardScreen()),
        );
        return;
      }

      setState(() {
        _submitError =
            'Login failed (${response.statusCode}): ${_extractBackendError(response.body)}';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _submitError =
            'Cannot connect to backend. Ensure Django is running on ${ApiConfig.baseUrl}.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Map<String, dynamic>? _tryParseUserObject(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // Intentionally ignored.
    }
    return null;
  }

  String _extractBackendError(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is String && decoded.trim().isNotEmpty) {
        return decoded;
      }

      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.trim().isNotEmpty) {
          return detail;
        }
      }
    } catch (_) {
      // Keep fallback below.
    }

    final trimmed = responseBody.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }

    return 'Please check your credentials.';
  }

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
                    controller: _identifierController,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  _buildTransparentField(
                    hint: 'Password',
                    icon: Icons.lock_outline_rounded,
                    obscure: true,
                    controller: _passwordController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submitSignIn(),
                  ),
                  if (_submitError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _submitError!,
                      style: const TextStyle(
                        color: Color(0xFF8B0000),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildButton(
                    label: 'LOGIN',
                    onPressed: _isSubmitting ? null : _submitSignIn,
                    isLoading: _isSubmitting,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _googleIcon(),
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
            color: Colors.black.withValues(alpha: 0.15),
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
    required TextEditingController controller,
    bool obscure = false,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
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
        controller: controller,
        obscureText: obscure,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
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

  Widget _buildButton({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
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
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textDark,
                ),
              )
            : Text(
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
      onTap: _isGoogleLoading ? null : _handleGoogleSignIn,
      child: Opacity(
        opacity: _isGoogleLoading ? 0.5 : 1.0,
        child: _isGoogleLoading
            ? const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            : Image.asset(
                'assets/google_icon.png',
                width: 36,
                height: 36,
              ),
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