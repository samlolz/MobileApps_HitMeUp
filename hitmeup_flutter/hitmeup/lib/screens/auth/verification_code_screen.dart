import 'package:flutter/material.dart';
import '../../services/api_config.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'verification_success_screen.dart';

class VerificationCodeScreen extends StatefulWidget {
  final String email;
  final String? identifier;
  final bool isSignup;
  final String provider;

  const VerificationCodeScreen({
    super.key,
    required this.email,
    this.identifier,
    this.isSignup = false,
    this.provider = 'google',
  });

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  bool _isVerifying = false;
  String? _errorMessage;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(4, (_) => TextEditingController());
    _focusNodes = List.generate(4, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final code = _controllers.map((c) => c.text).join();

    if (code.length < 4) {
      setState(() {
        _errorMessage = 'Please enter all 4 digits.';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/verify-oauth-code/');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': widget.email,
              'code': code,
              'identifier': widget.identifier,
              'is_signup': widget.isSignup,
              'provider': widget.provider,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VerificationSuccessScreen(
              email: widget.email,
              user: decoded is Map<String, dynamic> ? decoded : null,
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = _extractBackendError(response.body);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Connection error. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _isResending = true;
    });

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/resend-oauth-code/');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': widget.email,
              'provider': widget.provider,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code resent to your email'),
            backgroundColor: Colors.green,
          ),
        );
        // Clear the current code
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to resend code'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
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
      // Fallback
    }
    return 'Verification failed. Please check the code.';
  }

  void _handleCodeInput(String value, int index) {
    if (value.length == 1) {
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 40),
                      const Text(
                        'Verification',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Text(
                              'Please enter your\nverification code',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'the code is sent to your email',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(
                                4,
                                (index) => _buildCodeInputField(index),
                              ),
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFF8B0000),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 24),
                            GestureDetector(
                              onTap: _isResending ? null : _resendCode,
                              child: Text(
                                'Resend Code',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _isResending ? Colors.grey : const Color(0xFF448AFF),
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF448AFF),
                                  foregroundColor: Colors.white,
                                  elevation: 3,
                                  shadowColor: Colors.black26,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: _isVerifying ? null : _verifyCode,
                                child: _isVerifying
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Verify',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

  Widget _buildCodeInputField(int index) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFE91E63),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        maxLength: 1,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        onChanged: (value) => _handleCodeInput(value, index),
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
