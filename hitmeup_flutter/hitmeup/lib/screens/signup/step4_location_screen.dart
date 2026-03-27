import 'package:flutter/material.dart';
import '../../widgets/common_widgets.dart';
import 'step5_meet_gender_screen.dart';

class Step4LocationScreen extends StatefulWidget {
  const Step4LocationScreen({super.key});

  @override
  State<Step4LocationScreen> createState() => _Step4LocationScreenState();
}

class _Step4LocationScreenState extends State<Step4LocationScreen> {
  String _selectedLocation = 'Tangerang Selatan';

  final List<String> _locations = [
    'Tangerang Selatan',
    'Jakarta Selatan',
    'Jakarta Pusat',
    'Jakarta Barat',
    'Jakarta Timur',
    'Jakarta Utara',
    'Depok',
    'Bekasi',
    'Bogor',
    'Bandung',
    'Surabaya',
    'Yogyakarta',
    'Medan',
    'Makassar',
  ];

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
                        child: StepIndicator(totalSteps: 6, currentStep: 3),
                      ),
                      const SizedBox(height: 36),
                      const Text(
                        'Where do you live?',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildDropdown(),
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

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF6750A4),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLocation,
          isExpanded: true,
          dropdownColor: const Color(0xFF6750A4),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white,
          ),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
          onChanged: (value) {
            if (value != null) setState(() => _selectedLocation = value);
          },
          items: _locations
              .map((loc) => DropdownMenuItem(
                    value: loc,
                    child: Text(
                      loc,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ))
              .toList(),
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
            MaterialPageRoute(builder: (_) => const Step5MeetGenderScreen()),
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