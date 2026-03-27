import 'package:flutter/material.dart';

import 'chat.dart';
import 'discover.dart';
import 'profile.dart';
import 'requests.dart';
import '../../theme/app_theme.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  static const int _diamondBalance = 17;
  int _selectedBottomNavIndex = 3;

  final List<_FriendData> _friends = const [
    _FriendData(
      name: 'Siti Ratmawati',
      birthday: '15 December 2006',
      gender: 'Woman',
      location: 'Gading Serpong',
      interests: 'Cooking, Roblox, and Watch horror films',
      avatarUrl: 'https://i.pravatar.cc/160?img=44',
    ),
    _FriendData(
      name: 'Budi Amman',
      birthday: '6 March 2003',
      gender: 'Man',
      location: 'Bintaro',
      interests: 'Actor, Plays free fire, and Plays Padel',
      avatarUrl: 'https://i.pravatar.cc/160?img=13',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Your Friends',
          style: TextStyle(
            color: Colors.black,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
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
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.diamond_rounded,
                      color: Color(0xFF448AFF),
                      size: 20,
                    ),
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
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            itemCount: _friends.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _FriendTile(data: _friends[index]);
            },
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
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.data});

  final _FriendData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 367,
      height: 109,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              data.avatarUrl,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_rounded, size: 48, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.birthday,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF767676),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.gender,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF767676),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.location,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF767676),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.interests,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF767676),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _FriendData {
  const _FriendData({
    required this.name,
    required this.birthday,
    required this.gender,
    required this.location,
    required this.interests,
    required this.avatarUrl,
  });

  final String name;
  final String birthday;
  final String gender;
  final String location;
  final String interests;
  final String avatarUrl;
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
              imageAssetPath: 'assets/navbar/discover.png',
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
              imageAssetPath: 'assets/navbar/friendsSelected.png',
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
          width: 56, height: 56,
          child: Center(
            child: SizedBox(
              width: 40, height: 40,
              child: Image.asset(
                imageAssetPath,
                width: 32, height: 32,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(fallbackIcon, color: Colors.black, size: 24);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}