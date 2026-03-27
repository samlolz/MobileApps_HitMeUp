import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import 'chat_models.dart';
import 'community_chat_screen.dart';

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'ANAK KULIAH JKT');
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradient.background),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar
              Container(
                color: Colors.white,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                  left: 8, right: 16, bottom: 12,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textDark),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Create a new community',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Profile picture
                          Container(
                            width: 110, height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade200,
                            ),
                            child: const Icon(Icons.person, size: 70, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Change Profile Picture',
                              style: TextStyle(color: AppColors.blueBottom, fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Name field
                          Container(
                            width: 211,
                            height: 34,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFFF4081), width: 2),
                            ),
                            child: Center(
                              child: TextField(
                                controller: _nameController,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Community description label
                          const Text(
                            'Community description',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Description input
                          Container(
                            width: 285,
                            height: 26,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF448AFF), width: 1),
                            ),
                            child: TextField(
                              controller: _descController,
                              style: const TextStyle(fontSize: 11, color: AppColors.textDark),
                              decoration: const InputDecoration(
                                hintText: 'Input description',
                                hintStyle: TextStyle(color: AppColors.textGrey, fontSize: 11),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Maximum participants label
                          const Text(
                            'Maximum participants',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Max participants input
                          Container(
                            width: 285,
                            height: 26,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF448AFF), width: 1),
                            ),
                            child: TextField(
                              controller: _maxController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              style: const TextStyle(fontSize: 11, color: AppColors.textDark),
                              decoration: const InputDecoration(
                                hintText: 'Input number',
                                hintStyle: TextStyle(color: AppColors.textGrey, fontSize: 11),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Create button
                          SizedBox(
                            width: 180, height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.pinkTop,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                elevation: 0,
                              ),
                              onPressed: () {
                                final community = Community(
                                  name: _nameController.text,
                                  participants: int.tryParse(_maxController.text) ?? 1,
                                );
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => CommunityChatScreen(community: community)),
                                );
                              },
                              child: const Text(
                                'Create',
                                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}