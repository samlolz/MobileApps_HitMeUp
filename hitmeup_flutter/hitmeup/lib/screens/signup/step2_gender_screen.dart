import 'package:flutter/material.dart';
import '../../widgets/common_widgets.dart';
import 'step4_location_screen.dart';

class Step2GenderScreen extends StatefulWidget {
  const Step2GenderScreen({
    super.key,
    required this.name,
    required this.email,
    required this.password,
    required this.birthday,
  });

  final String name;
  final String email;
  final String password;
  final DateTime birthday;

  @override
  State<Step2GenderScreen> createState() => _Step2GenderScreenState();
}

class _Step2GenderScreenState extends State<Step2GenderScreen> {
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
    color: Color(0xFF656565),
  );

  static const Color _continueButtonColor = Colors.white;

  String? _selectedGender;
  String? _errorText;

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
                        child: StepIndicator(totalSteps: 6, currentStep: 2),
                      ),
                      const SizedBox(height: 36),
                      const Text(
                        'Your Gender',
                        style: _headerTextStyle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose the gender that best describe you',
                        style: _inputTextStyle.copyWith(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 48),
                      _buildGenderButton('Woman'),
                      const SizedBox(height: 14),
                      _buildGenderButton('Man'),
                      if (_errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorText!,
                          style: const TextStyle(
                            color: Color(0xFFFFD8D8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 240),
                      Text(
                        'Make friends with people\nwho match your vibe!',
                        style: _headerTextStyle.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 321,
                        child: Container(
                          height: 1,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      _buildContinueButton(),
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

  Widget _buildGenderButton(String label) {
    final isSelected = _selectedGender == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = label),
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

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 67,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _continueButtonColor,
          disabledBackgroundColor: _continueButtonColor,
          foregroundColor: const Color(0xFF656565),
          disabledForegroundColor: const Color(0xFF656565),
          elevation: 3,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: () {
          if (_selectedGender == null) {
            setState(() {
              _errorText = 'Please select your gender first.';
            });
            return;
          }

          final backendGender = _selectedGender == 'Woman' ? 'female' : 'male';

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Step4LocationScreen(
                name: widget.name,
                email: widget.email,
                password: widget.password,
                birthday: widget.birthday,
                gender: backendGender,
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