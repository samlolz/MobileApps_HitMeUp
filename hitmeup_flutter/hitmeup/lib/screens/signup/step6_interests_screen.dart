import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/api_config.dart';
import '../../services/auth_session.dart';
import '../../widgets/common_widgets.dart';
import '../../theme/app_theme.dart';
import '../mainApp/discover.dart';

class Step6InterestsScreen extends StatefulWidget {
  const Step6InterestsScreen({
    super.key,
    required this.name,
    required this.email,
    required this.password,
    required this.gender,
    required this.birthday,
    required this.location,
    this.meetGender,
  });

  final String name;
  final String email;
  final String password;
  final String gender;
  final DateTime birthday;
  final String location;
  final String? meetGender;

  @override
  State<Step6InterestsScreen> createState() => _Step6InterestsScreenState();
}

class _Step6InterestsScreenState extends State<Step6InterestsScreen> {
  final Map<String, String?> _selectedInterests = {};
  bool _isSubmitting = false;
  String? _submitError;

  final Map<String, List<String>> _categories = {
    'Lifestyles': [
      'Content Creator', 'Gamer', 'Youtuber', 'Actor',
      'Voice Actor', 'Choreographer', 'Streamer', 'Freelance',
    ],
    'TV & Movies': [
      'Amazon Prime', 'TV', 'Netflix', 'Disney+',
      'Video', 'WeTv', 'Drakor.id',
    ],
    'Activities': [
      'Social Media', 'Vlogging', 'Youtube', 'Memes',
      'Video Gaming', 'Film Making', 'Theatre', 'Thrifting',
    ],
    'Games': [
      'Mobile Legends', 'PUBG', 'Roblox', 'Township',
      'Candy Crush', 'Freefire', 'Hayday',
    ],
  };

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
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Center(
                        child: StepIndicator(totalSteps: 6, currentStep: 5),
                      ),
                      const SizedBox(height: 8),
                      _buildHeaderCard(),
                      const SizedBox(height: 32),
                      ..._categories.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                height: 34,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: entry.value.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (_, i) {
                                    final item = entry.value[i];
                                    final isSelected = _selectedInterests[entry.key] == item;
                                    return GestureDetector(
                                      onTap: () => setState(() {
                                        if (_selectedInterests[entry.key] == item) {
                                          _selectedInterests[entry.key] = null;
                                        } else {
                                          _selectedInterests[entry.key] = item;
                                        }
                                      }),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        width: 99,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.blueBottom
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.blueBottom
                                                : Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            item,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? Colors.white
                                                  : AppColors.textDark,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (_submitError != null) ...[
                        Text(
                          _submitError!,
                          style: const TextStyle(
                            color: Color(0xFFFFD8D8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 40),
                      _buildContinueButton(context),
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

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pick your interests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              decoration: TextDecoration.underline,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "We'll recommend people you have more in common with",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF636363),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitSignup() async {
    if (_isSubmitting) return;

    final selectedInterests = _selectedInterests.values
        .where((interest) => interest != null)
        .cast<String>()
        .toList();

    final payload = {
      'name': widget.name,
      'email': widget.email,
      'password': widget.password,
      'gender': widget.gender,
      'birthday': widget.birthday.toIso8601String().split('T').first,
      'location': widget.location,
      'intrest1': selectedInterests.isNotEmpty ? selectedInterests[0] : '',
      'intrest2': selectedInterests.length > 1 ? selectedInterests[1] : '',
      'intrest3': selectedInterests.length > 2 ? selectedInterests[2] : '',
      'intrest4': selectedInterests.length > 3 ? selectedInterests[3] : '',
      'diamonds': 20,
    };

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/');

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 12));

      debugPrint('Signup payload: ${jsonEncode(payload)}');
      debugPrint('Signup response (${response.statusCode}): ${response.body}');

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final createdUser = _tryParseUserObject(response.body);
        if (createdUser != null) {
          await AuthSession.instance.saveUser(createdUser);
        }

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SwipeCardScreen()),
          (route) => false,
        );
        return;
      }

      final backendMessage = _extractBackendError(response.body);
      setState(() {
        _submitError =
            'Signup failed (${response.statusCode}): $backendMessage';
      });
    } catch (_) {
      if (!mounted) return;
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
      // Intentionally ignore parse errors and continue without cached session.
    }
    return null;
  }

  String _extractBackendError(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);

      if (decoded is List && decoded.isNotEmpty) {
        return decoded.first.toString();
      }

      if (decoded is String && decoded.trim().isNotEmpty) {
        return decoded;
      }

      if (decoded is Map<String, dynamic>) {
        final lines = <String>[];
        decoded.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            lines.add('$key: ${value.first}');
          } else if (value is Map<String, dynamic> && value.isNotEmpty) {
            lines.add('$key: ${value.values.first}');
          } else if (value is String && value.trim().isNotEmpty) {
            lines.add('$key: $value');
          }
        });

        if (lines.isNotEmpty) {
          return lines.join(' | ');
        }
      }
    } catch (_) {
      // Keep a generic message if body is not JSON.
    }

    final trimmed = responseBody.trim();
    if (trimmed.isNotEmpty) {
      return trimmed.length > 180 ? '${trimmed.substring(0, 180)}...' : trimmed;
    }

    return 'Please check your input data.';
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
        onPressed: _isSubmitting ? null : _submitSignup,
        child: _isSubmitting
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Color(0xFF656565),
                ),
          ),
      ),
    );
  }
}