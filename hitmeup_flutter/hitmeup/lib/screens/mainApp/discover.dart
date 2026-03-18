import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'chat.dart';
import 'friends.dart';
import 'profile.dart';
import 'requests.dart';
import '../../theme/app_theme.dart';

class SwipeCardScreen extends StatefulWidget {
  const SwipeCardScreen({super.key});

  @override
  State<SwipeCardScreen> createState() => _SwipeCardScreenState();
}

class _SwipeCardScreenState extends State<SwipeCardScreen> {
  static const double _swipeThreshold = 140;
  static const Duration _animationDuration = Duration(milliseconds: 260);
  static const double _maxDragDistance = 220;
  static const double _maxLift = 42;
  static const double _maxRotation = 0.14;
  static const int _diamondBalance = 17;

  final List<ProfileCardData> _profiles = const [
    ProfileCardData(
      name: 'Frezz',
      age: 25,
      level: 3,
      location: 'Bintaro, Tangerang Selatan',
      score: 3,
      imageUrl: 'https://i.pravatar.cc/900?img=12',
    ),
    ProfileCardData(
      name: 'Alea',
      age: 23,
      level: 5,
      location: 'Kemang, Jakarta Selatan',
      score: 8,
      imageUrl: 'https://i.pravatar.cc/900?img=32',
    ),
    ProfileCardData(
      name: 'Rafi',
      age: 27,
      level: 4,
      location: 'Cilandak, Jakarta Selatan',
      score: 6,
      imageUrl: 'https://i.pravatar.cc/900?img=15',
    ),
    ProfileCardData(
      name: 'Naya',
      age: 24,
      level: 2,
      location: 'BSD, Tangerang',
      score: 4,
      imageUrl: 'https://i.pravatar.cc/900?img=47',
    ),
  ];

  Offset _dragOffset = Offset.zero;
  int _currentIndex = 0;
  int _selectedBottomNavIndex = 0;
  bool _isAnimating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        title: Text(
          'Discover',
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
                border: Border.all(
                  color: const Color(0xFF448AFF),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/diamond.png',
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '$_diamondBalance',
                    style: TextStyle(
                      color: Color(0xFF4F8FF7),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradient.background),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomCenter,
                        children: [
                          for (
                            int depth = math.min(2, _profiles.length - 1);
                            depth >= 0;
                            depth--
                          )
                            _buildLayeredCard(constraints, depth),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Transform.translate(
                  offset: const Offset(0, 0),
                  child: _BottomSwipeBar(
                    onReject: () => _swipeCard(-1),
                    onAccept: () => _swipeCard(1),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLayeredCard(BoxConstraints constraints, int depth) {
    final profile = _profiles[(_currentIndex + depth) % _profiles.length];
    final isTopCard = depth == 0;
    final rawHorizontalDrag = _dragOffset.dx;
    final constrainedHorizontalDrag = rawHorizontalDrag.clamp(
      -_maxDragDistance,
      _maxDragDistance,
    );
    final normalizedDrag = (constrainedHorizontalDrag / _maxDragDistance).clamp(
      -1.0,
      1.0,
    );
    const double scale = 1.0;
    const double verticalOffset = 0.0;
    final horizontalOffset = isTopCard ? rawHorizontalDrag : 0.0;
    final dragYOffset = isTopCard ? -normalizedDrag.abs() * _maxLift : 0.0;
    final rotation = isTopCard ? -normalizedDrag * _maxRotation : 0.0;

    return AnimatedContainer(
      duration: _isAnimating ? _animationDuration : Duration.zero,
      curve: Curves.easeOut,
      transform: Matrix4.identity()
        ..translate(horizontalOffset, verticalOffset + dragYOffset)
        ..rotateZ(rotation)
        ..scale(scale),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: isTopCard
            ? GestureDetector(
                onPanUpdate: _isAnimating
                    ? null
                    : (details) {
                        setState(() {
                          final nextDx = (_dragOffset.dx + details.delta.dx)
                              .clamp(-_maxDragDistance, _maxDragDistance);
                          _dragOffset = Offset(nextDx, 0);
                        });
                      },
                onPanEnd: _isAnimating ? null : (_) => _handlePanEnd(),
                child: _ProfileCard(profile: profile),
              )
            : IgnorePointer(child: _ProfileCard(profile: profile)),
      ),
    );
  }

  void _handlePanEnd() {
    if (_dragOffset.dx.abs() >= _swipeThreshold) {
      _swipeCard(_dragOffset.dx.isNegative ? -1 : 1);
      return;
    }

    setState(() {
      _dragOffset = Offset.zero;
    });
  }

  Future<void> _swipeCard(double direction) async {
    if (_isAnimating) {
      return;
    }

    final screenWidth = MediaQuery.of(context).size.width;

    setState(() {
      _isAnimating = true;
      _dragOffset = Offset(direction * (screenWidth + 180), -_maxLift * 0.9);
    });

    await Future<void>.delayed(_animationDuration);

    if (!mounted) {
      return;
    }

    setState(() {
      _currentIndex = (_currentIndex + 1) % _profiles.length;
      _dragOffset = Offset.zero;
      _isAnimating = false;
    });
  }

  void _handleBottomNavTap(int index) {
    if (index == _selectedBottomNavIndex) {
      return;
    }

    final Widget? destination = switch (index) {
      0 => const SwipeCardScreen(),
      1 => const RequestsScreen(),
      2 => const ChatScreen(),
      3 => const FriendsScreen(),
      4 => const ProfileScreen(),
      _ => null,
    };

    if (destination == null) {
      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});

  final ProfileCardData profile;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AspectRatio(
        aspectRatio: 0.60,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(profile.imageUrl, fit: BoxFit.cover),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.18),
                      Colors.black.withValues(alpha: 0.62),
                    ],
                    stops: const [0, 0.45, 1],
                  ),
                ),
              ),
              Positioned(
                top: 18,
                right: 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7BC2D2),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '-',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Image.asset(
                        'assets/diamond.png',
                        width: 18,
                        height: 18,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${profile.score}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${profile.name} ${profile.age}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Level ${profile.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.location,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
  }
}

class _BottomSwipeBar extends StatelessWidget {
  const _BottomSwipeBar({required this.onReject, required this.onAccept});

  final VoidCallback onReject;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 54,
            height: 54,
            child: _BarIconButton(
              icon: Icons.thumb_down_alt_rounded,
              color: const Color.fromARGB(255, 233, 30, 33),
              onTap: onReject,
            ),
          ),
          SizedBox(
            width: 54,
            height: 54,
            child: _BarIconButton(
              icon: Icons.thumb_up_alt_rounded,
              color: const Color.fromARGB(255, 29, 233, 182),
              onTap: onAccept,
            ),
          ),
        ],
      ),
    );
  }
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomNavItem(
              imageAssetPath: 'assets/navbar/discoverSelected.png',
              fallbackIcon: Icons.home_rounded,
              selected: selectedIndex == 0,
              onTap: () => onItemTap(0),
            ),
            _BottomNavItem(
              imageAssetPath: 'assets/navbar/requests.png',
              fallbackIcon: Icons.grid_view_rounded,
              selected: selectedIndex == 1,
              onTap: () => onItemTap(1),
            ),
            _BottomNavItem(
              imageAssetPath: 'assets/navbar/chat.png',
              fallbackIcon: Icons.chat_bubble_outline_rounded,
              selected: selectedIndex == 2,
              onTap: () => onItemTap(2),
            ),
            _BottomNavItem(
              imageAssetPath: 'assets/navbar/friends.png',
              fallbackIcon: Icons.groups_rounded,
              selected: selectedIndex == 3,
              onTap: () => onItemTap(3),
            ),
            _BottomNavItem(
              imageAssetPath: 'assets/navbar/profile.png',
              fallbackIcon: Icons.account_circle_outlined,
              selected: selectedIndex == 4,
              onTap: () => onItemTap(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.imageAssetPath,
    required this.fallbackIcon,
    required this.selected,
    required this.onTap,
  });

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
          width: 56,
          height: 56,
          child: Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: Image.asset(
                imageAssetPath,
                width: 32,
                height: 32,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint(
                    'Bottom nav asset failed: $imageAssetPath -> $error',
                  );
                  return Icon(
                    fallbackIcon,
                    color: Colors.black,
                    size: 24,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarIconButton extends StatelessWidget {
  const _BarIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Center(
          child: Icon(icon, color: color, size: 54),
        ),
      ),
    );
  }
}

class ProfileCardData {
  const ProfileCardData({
    required this.name,
    required this.age,
    required this.level,
    required this.location,
    required this.score,
    required this.imageUrl,
  });

  final String name;
  final int age;
  final int level;
  final String location;
  final int score;
  final String imageUrl;
}
