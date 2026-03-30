import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../widgets/common_widgets.dart';
import '../../theme/app_theme.dart';
import 'step2_gender_screen.dart';

class Step3BirthdayScreen extends StatefulWidget {
  const Step3BirthdayScreen({
    super.key,
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;

  @override
  State<Step3BirthdayScreen> createState() => _Step3BirthdayScreenState();
}

class _Step3BirthdayScreenState extends State<Step3BirthdayScreen> {
  bool _showOnProfile = false;
  DateTime _selectedDate = DateTime(2002, 5, 8);

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
                        child: StepIndicator(totalSteps: 6, currentStep: 1),
                      ),
                      const SizedBox(height: 36),
                      const Text(
                        'Your Birthday',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 40),
                      _buildDatePicker(),
                      const Spacer(),
                      Center(child: _buildShowOnProfile()),
                      const SizedBox(height: 24),
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

  Widget _buildDatePicker() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.blueBottom, width: 1.5),
      ),
      child: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.date,
        initialDateTime: _selectedDate,
        maximumDate: DateTime.now(),
        backgroundColor: Colors.white,
        onDateTimeChanged: (dt) => setState(() => _selectedDate = dt),
      ),
    );
  }

  Widget _buildShowOnProfile() {
    return GestureDetector(
      onTap: () => setState(() => _showOnProfile = !_showOnProfile),
      child: Container(
        width: 182,
        height: 39,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Show on profile',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B6B6B),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _showOnProfile ? Colors.black : Colors.transparent,
                border: Border.all(
                  color: Colors.black,
                  width: 1.5,
                ),
              ),
              child: _showOnProfile
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
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
            MaterialPageRoute(
              builder: (_) => Step2GenderScreen(
                name: widget.name,
                email: widget.email,
                password: widget.password,
                birthday: _selectedDate,
              ),
            ),
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