import 'package:flutter/material.dart';
import '../../widgets/common_widgets.dart';
import 'step6_interests_screen.dart';

class Step5MeetGenderScreen extends StatefulWidget {
  const Step5MeetGenderScreen({super.key});

  @override
  State<Step5MeetGenderScreen> createState() => _Step5MeetGenderScreenState();
}

class _Step5MeetGenderScreenState extends State<Step5MeetGenderScreen> {
  String? _selected;

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
                        child: StepIndicator(totalSteps: 6, currentStep: 4),
                      ),
                      const SizedBox(height: 36),
                      const Text(
                        'Who do you want to meet?',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose the gender that you want to meet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 48),
                      _buildOptionButton('Woman'),
                      const SizedBox(height: 14),
                      _buildOptionButton('Man'),
                      const SizedBox(height: 14),
                      _buildOptionButton('Everyone'),
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

  Widget _buildOptionButton(String label) {
    final isSelected = _selected == label;
    return GestureDetector(
      onTap: () => setState(() => _selected = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 47,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF4081) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFFF4081),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
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
            MaterialPageRoute(builder: (_) => const Step6InterestsScreen()),
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