import 'package:flutter/material.dart';
import '../../widgets/common_widgets.dart';
import 'step6_interests_screen.dart';

class Step5MeetGenderScreen extends StatefulWidget {
  const Step5MeetGenderScreen({
    super.key,
    required this.name,
    required this.email,
    required this.password,
    required this.gender,
    required this.birthday,
    required this.location,
  });

  final String name;
  final String email;
  final String password;
  final String gender;
  final DateTime birthday;
  final String location;

  @override
  State<Step5MeetGenderScreen> createState() => _Step5MeetGenderScreenState();
}

class _Step5MeetGenderScreenState extends State<Step5MeetGenderScreen> {
  static const TextStyle _headerTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 25,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.0,
    color: Colors.white,
  );

  static const TextStyle _inputTextStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 19,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.0,
    color: Colors.white,
  );

  static const TextStyle _continueButtonTextStyle = TextStyle(
    fontFamily: 'Konkhmer Sleokchher',
    fontSize: 19,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.0,
    color: Colors.white,
  );

  static const Color _continueButtonColor = Color.fromRGBO(101, 101, 101, 1);

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
                        style: _headerTextStyle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose the gender that you want to meet',
                        style: _inputTextStyle.copyWith(
                          fontSize: 18,
                          color: Colors.white70,
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
            style: _inputTextStyle.copyWith(
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
          backgroundColor: _continueButtonColor,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Step6InterestsScreen(
                name: widget.name,
                email: widget.email,
                password: widget.password,
                gender: widget.gender,
                birthday: widget.birthday,
                location: widget.location,
                meetGender: _selected,
              ),
            ),
          );
        },
        child: const Text(
          'CONTINUE',
          style: _continueButtonTextStyle,
        ),
      ),
    );
  }
}