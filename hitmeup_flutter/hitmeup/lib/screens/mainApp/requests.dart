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
				child: const SafeArea(
					top: false,
					child: Center(
						child: Text(
							'Requests Screen',
							style: TextStyle(
								color: Colors.white,
								fontSize: 20,
								fontWeight: FontWeight.w700,
							),
						),
					),
				),
			),
		);
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
              imageAssetPath: 'assets/navbar/requestsSelected.png',
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
