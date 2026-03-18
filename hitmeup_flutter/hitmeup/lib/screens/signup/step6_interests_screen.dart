import 'package:flutter/material.dart';
import '../../widgets/common_widgets.dart';
import '../../theme/app_theme.dart';
import '../home/discover_screen.dart';

class Step6InterestsScreen extends StatefulWidget {
  const Step6InterestsScreen({super.key});

  @override
  State<Step6InterestsScreen> createState() => _Step6InterestsScreenState();
}

class _Step6InterestsScreenState extends State<Step6InterestsScreen> {
  String? _selected;

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
                                    final isSelected = _selected == item;
                                    return GestureDetector(
                                      onTap: () => setState(() {
                                        _selected =
                                            _selected == item ? null : item;
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
            color: Colors.black.withOpacity(0.08),
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
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SwipeCardScreen()),
            (route) => false,
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