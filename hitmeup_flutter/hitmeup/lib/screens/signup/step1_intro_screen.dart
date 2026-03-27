import 'package:flutter/material.dart';
import '../../widgets/common_widgets.dart';
import 'step3_birthday_screen.dart';

class Step1IntroScreen extends StatelessWidget {
  const Step1IntroScreen({super.key});

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
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 32),
                      _buildField(hint: 'Input your name'),
                      const SizedBox(height: 20),
                      _buildField(hint: 'Input mail'),
                      const SizedBox(height: 20),
                      _buildField(hint: 'Input password', obscure: true),
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

  Widget _buildField({required String hint, bool obscure = false}) {
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
        obscureText: obscure,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const Step3BirthdayScreen()),
          );
        },
        child: const Text(
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