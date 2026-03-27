import 'package:flutter/material.dart';

import 'chat.dart';
import 'discover.dart';
import 'friends.dart';
import 'profile.dart';
import '../../theme/app_theme.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  static const int _diamondBalance = 17;
  int _selectedBottomNavIndex = 1;

  final List<_RequestData> _requests = [
    _RequestData(name: 'Fiolline Olivia', age: 23, level: 1, imageUrl: 'https://i.pravatar.cc/300?img=47', diamonds: 5),
    _RequestData(name: 'Andhikara Parasha', age: 25, level: 5, imageUrl: 'https://i.pravatar.cc/300?img=11', diamonds: 5),
    _RequestData(name: 'Joshua Imannuel', age: 22, level: 3, imageUrl: 'https://i.pravatar.cc/300?img=13', diamonds: 5),
    _RequestData(name: 'Taranitha Gea', age: 21, level: 3, imageUrl: 'https://i.pravatar.cc/300?img=44', diamonds: 5),
  ];

  void _showResultDialog(BuildContext context, _RequestData data, bool accepted) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 3 / 4,
                child: Image.network(
                  data.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.person, size: 80, color: Colors.grey),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                        children: [
                          const TextSpan(text: 'You are now '),
                          TextSpan(
                            text: accepted ? 'friends' : 'reject',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: accepted ? Colors.green : Colors.red,
                            ),
                          ),
                          const TextSpan(text: ' being friends with'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (Navigator.canPop(context)) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        title: Text(
          'Requests',
          style: AppTextStyles.heading.copyWith(color: Colors.black),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF448AFF)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/diamond.png',
                    width: 20, height: 20,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.diamond_rounded, color: Color(0xFF448AFF), size: 20),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '$_diamondBalance',
                    style: TextStyle(color: Color(0xFF4F8FF7), fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: _selectedBottomNavIndex,
        onItemTap: _handleBottomNavTap,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradient.background),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 121, height: 123,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.blueBottom, width: 5),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/profilepic.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.person, size: 60, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Alfraz Aldebaran', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                            SizedBox(height: 4),
                            Text('Level 1', style: TextStyle(fontSize: 11, color: Color(0xFFCCCCCC))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Get more friends', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              // Grid — Expanded agar mengisi sisa layar tanpa overflow
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double totalWidth = constraints.maxWidth - 16 * 2 - 20;
                    final double cardWidth = totalWidth / 2;
                    final double totalHeight = constraints.maxHeight - 20 - 16;
                    final double cardHeight = totalHeight / 2;

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: [
                          // Row 1
                          SizedBox(
                            height: cardHeight,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: cardWidth,
                                  child: _RequestCard(
                                    data: _requests[0],
                                    onAccept: () => _showResultDialog(context, _requests[0], true),
                                    onReject: () => _showResultDialog(context, _requests[0], false),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                SizedBox(
                                  width: cardWidth,
                                  child: _RequestCard(
                                    data: _requests[1],
                                    onAccept: () => _showResultDialog(context, _requests[1], true),
                                    onReject: () => _showResultDialog(context, _requests[1], false),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Row 2
                          SizedBox(
                            height: cardHeight,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: cardWidth,
                                  child: _RequestCard(
                                    data: _requests[2],
                                    onAccept: () => _showResultDialog(context, _requests[2], true),
                                    onReject: () => _showResultDialog(context, _requests[2], false),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                SizedBox(
                                  width: cardWidth,
                                  child: _RequestCard(
                                    data: _requests[3],
                                    onAccept: () => _showResultDialog(context, _requests[3], true),
                                    onReject: () => _showResultDialog(context, _requests[3], false),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleBottomNavTap(int index) {
    if (index == _selectedBottomNavIndex) return;
    final Widget? destination = switch (index) {
      0 => const SwipeCardScreen(),
      1 => const RequestsScreen(),
      2 => const ChatScreen(),
      3 => const FriendsScreen(),
      4 => const ProfileScreen(),
      _ => null,
    };
    if (destination == null) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.data, required this.onAccept, required this.onReject});
  final _RequestData data;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              data.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300, child: const Icon(Icons.person, size: 60, color: Colors.grey)),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.75), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8, left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7BC2D2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -6),
                      child: const Text('+', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, height: 1.0)),
                    ),
                    const SizedBox(width: 2),
                    Image.asset(
                      'assets/diamond.png',
                      width: 18, height: 18,
                      color: const Color(0xFF448AFF),
                      errorBuilder: (_, __, ___) => const Icon(Icons.diamond_rounded, color: Color(0xFF448AFF), size: 18),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${data.diamonds}',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8, right: 8,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onReject,
                    child: Container(
                      width: 28, height: 28,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onAccept,
                    child: Container(
                      width: 28, height: 28,
                      decoration: const BoxDecoration(color: Colors.teal, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 10, left: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${data.name} (${data.age})', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('Level ${data.level}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestData {
  const _RequestData({required this.name, required this.age, required this.level, required this.imageUrl, required this.diamonds});
  final String name;
  final int age;
  final int level;
  final String imageUrl;
  final int diamonds;
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.selectedIndex, required this.onItemTap});
  final int selectedIndex;
  final ValueChanged<int> onItemTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomNavItem(imageAssetPath: 'assets/navbar/discover.png', fallbackIcon: Icons.home_rounded, selected: selectedIndex == 0, onTap: () => onItemTap(0)),
            _BottomNavItem(imageAssetPath: 'assets/navbar/requestsSelected.png', fallbackIcon: Icons.grid_view_rounded, selected: selectedIndex == 1, onTap: () => onItemTap(1)),
            _BottomNavItem(imageAssetPath: 'assets/navbar/chat.png', fallbackIcon: Icons.chat_bubble_outline_rounded, selected: selectedIndex == 2, onTap: () => onItemTap(2)),
            _BottomNavItem(imageAssetPath: 'assets/navbar/friends.png', fallbackIcon: Icons.groups_rounded, selected: selectedIndex == 3, onTap: () => onItemTap(3)),
            _BottomNavItem(imageAssetPath: 'assets/navbar/profile.png', fallbackIcon: Icons.account_circle_outlined, selected: selectedIndex == 4, onTap: () => onItemTap(4)),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({required this.imageAssetPath, required this.fallbackIcon, required this.selected, required this.onTap});
  final String imageAssetPath;
  final IconData fallbackIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 56, height: 56,
          child: Center(
            child: SizedBox(
              width: 40, height: 40,
              child: Image.asset(imageAssetPath, width: 32, height: 32, fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) => Icon(fallbackIcon, color: Colors.black, size: 24)),
            ),
          ),
        ),
      ),
    );
  }
}