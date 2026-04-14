import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/common_widgets.dart';
import '../../services/api_config.dart';
import 'step3_birthday_screen.dart';

class Step1IntroScreen extends StatefulWidget {
  final String? initialName;
  final String? initialEmail;

  const Step1IntroScreen({
    super.key,
    this.initialName,
    this.initialEmail,
  });

  @override
  State<Step1IntroScreen> createState() => _Step1IntroScreenState();
}

class _Step1IntroScreenState extends State<Step1IntroScreen> {
  static const TextStyle _screenTitleTextStyle = TextStyle(
    fontFamily: 'Konkhmer Sleokchher',
    fontSize: 30,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.0,
  );

  static const TextStyle _inputTextStyle = TextStyle(
    fontFamily: 'Inria Serif',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.white,
  );

  static const TextStyle _inputHintTextStyle = TextStyle(
    fontFamily: 'Inria Serif',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.white,
  );

  static const TextStyle _buttonTextStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.5,
    color: Color(0xFF656565),
  );

  static const TextStyle _errorTextStyle = TextStyle(
    fontFamily: 'Konkhmer Sleokchher',
    color: Color.fromARGB(255, 247, 107, 107),
    fontSize: 12,
  );

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorText;
  bool _isCheckingEmail = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialName != null && widget.initialName!.trim().isNotEmpty) {
      _nameController.text = widget.initialName!.trim();
    }
    if (widget.initialEmail != null && widget.initialEmail!.trim().isNotEmpty) {
      _emailController.text = widget.initialEmail!.trim();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onContinuePressed() async {
    if (_isCheckingEmail) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        _errorText = 'Please fill name, email, and password.';
      });
      return;
    }

    if (!email.contains('@')) {
      setState(() {
        _errorText = 'Please enter a valid email address.';
      });
      return;
    }

    setState(() {
      _isCheckingEmail = true;
      _errorText = null;
    });

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/check-email/');

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 12));

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final exists = decoded is Map<String, dynamic> && decoded['exists'] == true;

        if (exists) {
          setState(() {
            _errorText = 'This email is already registered. Please use a different email.';
          });
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Step3BirthdayScreen(
              name: name,
              email: email,
              password: password,
            ),
          ),
        );
        return;
      }

      setState(() {
        _errorText = 'Unable to verify email right now. Please try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorText = 'Cannot reach server to verify email. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingEmail = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          SignupAppBar(onBack: () => Navigator.pop(context)),
          Expanded(
            child: GradientBackground(
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(left: 36, right: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Center(
                        child: StepIndicator(totalSteps: 6, currentStep: 0),
                      ),
                      const SizedBox(height: 36),
                      const Text(
                        'Hello! Please introduce\nyourself',
                        style: _screenTitleTextStyle,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 32),
                      _buildField(
                        hint: 'Input your name',
                        controller: _nameController,
                      ),
                      const SizedBox(height: 20),
                      _buildField(
                        hint: 'Input mail',
                        controller: _emailController,
                      ),
                      const SizedBox(height: 20),
                      _buildField(
                        hint: 'Input password',
                        controller: _passwordController,
                        obscure: true,
                      ),
                      if (_errorText != null) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _errorText!,
                            style: _errorTextStyle,
                          ),
                        ),
                      ],
                      const Spacer(),
                      _buildContinueButton(context),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String hint,
    required TextEditingController controller,
    bool obscure = false,
  }) {
    return Container(
      height: 53,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF6750A4),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: _inputTextStyle,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: _inputHintTextStyle,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 67,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF656565),
          elevation: 3,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: _isCheckingEmail ? null : _onContinuePressed,
        child: _isCheckingEmail
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF656565),
                ),
              )
            : const Text(
                'CONTINUE',
                style: _buttonTextStyle,
              ),
      ),
    );
  }
}