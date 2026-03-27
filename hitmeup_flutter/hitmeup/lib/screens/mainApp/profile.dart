import 'package:flutter/material.dart';

import 'chat.dart';
import 'discover.dart';
import 'editProfile.dart';
import 'friends.dart';
import 'requests.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
	const ProfileScreen({super.key});

	@override
	State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
	static const int _diamondBalance = 17;

	int _selectedBottomNavIndex = 4;

	// Profile data
	String _name = 'Alfraz Aldebaran';
	String _birthday = '30 September 2006';
	String _gender = 'Man';
	String _location = 'Tangerang Selatan';
	List<String> _interests = [
		'Watch horror films',
		'Roblox',
		'Content Creator',
		'Matcha',
	];

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: Colors.transparent,
			appBar: AppBar(
				automaticallyImplyLeading: false,
				backgroundColor: const Color.fromARGB(255, 255, 255, 255),
				elevation: 0,
				title: Text(
					'Profile',
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
		body: Container(
			decoration: const BoxDecoration(gradient: AppGradient.background),
			child: SafeArea(
				top: false,
				child: SingleChildScrollView(
					padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
					child: ConstrainedBox(
						constraints: BoxConstraints(
							minHeight: MediaQuery.of(context).size.height - 120,
						),
						child: Column(
							mainAxisSize: MainAxisSize.min,
							children: [
								Container(
									width: 180,
									height: 180,
									padding: const EdgeInsets.all(5),
									decoration: const BoxDecoration(
										shape: BoxShape.circle,
										color: Color(0xFF2E8DFF),
									),
									child: const CircleAvatar(
										backgroundImage: AssetImage('assets/profilepic.png'),
									),
								),
								const SizedBox(height: 12),
								Container(
									padding: const EdgeInsets.symmetric(
										horizontal: 28,
										vertical: 8,
									),
									decoration: BoxDecoration(
										color: Colors.white.withValues(alpha: 0.92),
										borderRadius: BorderRadius.circular(16),
									),
								child: Text(
									_name,
									style: const TextStyle(
											fontSize: 17,
											fontWeight: FontWeight.w700,
											color: Color(0xFF1F1F1F),
										),
									),
								),
								const SizedBox(height: 18),
								Container(
									width: double.infinity,
									padding: const EdgeInsets.symmetric(
										horizontal: 16,
										vertical: 14,
									),
									decoration: BoxDecoration(
										color: Colors.white.withValues(alpha: 0.84),
										borderRadius: BorderRadius.circular(14),
									),
									child: Column(
										children: [
											_ProfileInfoRow(
												label: 'Birthday date',
												value: _birthday,
											),
											const SizedBox(height: 10),
											_ProfileInfoRow(label: 'Gender', value: _gender),
											const SizedBox(height: 10),
											_ProfileInfoRow(
												label: 'Location',
												value: _location,
											),
											const SizedBox(height: 10),
											_ProfileInfoRow(
												label: 'My interests',
												value: _interests.join('\n'),
<<<<<<< HEAD:MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/hitmeup_flutter/hitmeup/lib/screens/mainApp/profile.dart
=======
												alignTop: true,
>>>>>>> b08e7bd95fdc7cd8a471cf7b3f92860581c8f222:MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/hitmeup_flutter/hitmeup/lib/screens/mainApp/profile.dart
											),
										],
									),
								),
								const SizedBox(height: 16),
								SizedBox(
									width: 200,
									height: 44,
									child: OutlinedButton(
										onPressed: _navigateToEditProfile,
										style: OutlinedButton.styleFrom(
											backgroundColor: const Color(0xFFF83D8D),
											foregroundColor: Colors.white,
											side: const BorderSide(
												color: Color(0xFF2E8DFF),
												width: 2,
											),
											shape: RoundedRectangleBorder(
												borderRadius: BorderRadius.circular(20),
											),
											textStyle: const TextStyle(
											fontSize: 17,
												fontWeight: FontWeight.w600,
											),
										),
										child: const Text('Edit profile'),
									),
								),
							],
						),
					),
				),
			),
		),
	);
	}

	void _navigateToEditProfile() async {
		final result = await Navigator.of(context).push(
			MaterialPageRoute(
				builder: (context) => EditProfileScreen(
					initialName: _name,
					initialBirthday: _birthday,
					initialGender: _gender,
					initialLocation: _location,
					initialInterests: _interests,
				),
			),
		);

		if (result != null && result is Map) {
			setState(() {
				_name = result['name'] ?? _name;
				_birthday = result['birthday'] ?? _birthday;
				_gender = result['gender'] ?? _gender;
				_location = result['location'] ?? _location;
				_interests = result['interests'] ?? _interests;
			});
		}
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

class _ProfileInfoRow extends StatelessWidget {
<<<<<<< HEAD:MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/hitmeup_flutter/hitmeup/lib/screens/mainApp/profile.dart
	const _ProfileInfoRow({required this.label, required this.value});

	final String label;
	final String value;
=======
	const _ProfileInfoRow({
		required this.label,
		required this.value,
		this.alignTop = false,
	});

	final String label;
	final String value;
	final bool alignTop;
>>>>>>> b08e7bd95fdc7cd8a471cf7b3f92860581c8f222:MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/hitmeup_flutter/hitmeup/lib/screens/mainApp/profile.dart

	@override
	Widget build(BuildContext context) {
		return Row(
<<<<<<< HEAD:MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/hitmeup_flutter/hitmeup/lib/screens/mainApp/profile.dart
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				SizedBox(
					width: 120,
					child: Text(
						label,
						style: const TextStyle(
							fontSize: 18,
							fontWeight: FontWeight.w600,
							color: Color(0xFF202020),
=======
			crossAxisAlignment:
				alignTop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
			children: [
				SizedBox(
					width: 132,
					child: Padding(
						padding: EdgeInsets.only(top: alignTop ? 2 : 0),
						child: Text(
							label,
							maxLines: 1,
							overflow: TextOverflow.ellipsis,
							style: const TextStyle(
								fontSize: 18,
								fontWeight: FontWeight.w600,
								color: Color(0xFF202020),
							),
>>>>>>> b08e7bd95fdc7cd8a471cf7b3f92860581c8f222:MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/hitmeup_flutter/hitmeup/lib/screens/mainApp/profile.dart
						),
					),
				),
				Expanded(
<<<<<<< HEAD:MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/hitmeup_flutter/hitmeup/lib/screens/mainApp/profile.dart
					child: Text(
						value,
						style: TextStyle(
							fontSize: 18,
							height: 1.25,
							fontWeight: FontWeight.w500,
							color: Colors.black.withValues(alpha: 0.52),
=======
					child: Align(
						alignment: Alignment.centerLeft,
						child: Text(
							value,
							style: TextStyle(
								fontSize: 18,
								height: 1.25,
								fontWeight: FontWeight.w500,
								color: Colors.black.withValues(alpha: 0.52),
							),
>>>>>>> b08e7bd95fdc7cd8a471cf7b3f92860581c8f222:MobileApps_HitMeUp-main/MobileApps_HitMeUp-main/hitmeup_flutter/hitmeup/lib/screens/mainApp/profile.dart
						),
					),
				),
			],
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
							imageAssetPath: 'assets/navbar/profileSelected.png',
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

