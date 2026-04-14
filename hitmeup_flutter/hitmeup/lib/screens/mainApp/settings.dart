import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/api_config.dart';
import '../../services/auth_session.dart';
import '../../theme/app_theme.dart';
import 'chat.dart';
import 'discover.dart';
import 'friends.dart';
import 'profile.dart';
import 'requests.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _diamondBalance = 17;
  bool _isLoadingProfile = true;
  bool _isSavingShowBirthday = false;
  String? _profileError;
  String? _saveError;
  int _selectedBottomNavIndex = 4;

  String _birthday = '30 September 2006';
  bool _showBirthday = true;

  @override
  void initState() {
    super.initState();
    _hydrateFromSession();
    _loadProfileFromApi();
  }

  void _hydrateFromSession() {
    final cachedUser = AuthSession.instance.currentUser;
    if (cachedUser == null) {
      return;
    }

    _applyUserData(cachedUser);
  }

  Future<void> _loadProfileFromApi() async {
    final userId = AuthSession.instance.userId;
    if (userId == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingProfile = false;
        _profileError = 'No logged-in user found.';
      });
      return;
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/$userId/');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 12));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoadingProfile = false;
          _profileError = 'Failed to load profile (${response.statusCode}).';
        });
        return;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoadingProfile = false;
          _profileError = 'Invalid profile response from server.';
        });
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _applyUserData(decoded);
        _isLoadingProfile = false;
        _profileError = null;
      });

      await AuthSession.instance.saveUser(decoded);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingProfile = false;
        _profileError = 'Unable to connect to backend at ${ApiConfig.baseUrl}.';
      });
    }
  }

  void _applyUserData(Map<String, dynamic> userData) {
    final birthdayRaw = (userData['birthday'] as String?)?.trim();
    final showBirthdayRaw = userData['showbirthday'];

    final diamondsRaw = userData['diamonds'];
    if (diamondsRaw is int) {
      _diamondBalance = diamondsRaw;
    } else if (diamondsRaw is String) {
      _diamondBalance = int.tryParse(diamondsRaw) ?? _diamondBalance;
    }

    _birthday = _formatBirthdayValue(birthdayRaw);
    _showBirthday = _parseBoolValue(showBirthdayRaw, defaultValue: true);
  }

  bool _parseBoolValue(dynamic value, {required bool defaultValue}) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    if (value is num) {
      return value != 0;
    }
    return defaultValue;
  }

  String _formatBirthdayValue(String? value) {
    if (value == null || value.isEmpty) {
      return _birthday;
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }

    const monthNames = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${parsed.day} ${monthNames[parsed.month - 1]} ${parsed.year}';
  }

  Future<void> _saveShowBirthday(bool value) async {
    if (_isSavingShowBirthday) {
      return;
    }

    final userId = AuthSession.instance.userId;
    if (userId == null) {
      setState(() {
        _saveError = 'No logged-in user found.';
      });
      return;
    }

    final previousValue = _showBirthday;
    setState(() {
      _showBirthday = value;
      _isSavingShowBirthday = true;
      _saveError = null;
    });

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/$userId/edit-user/');

    try {
      final response = await http
          .patch(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'showbirthday': value}),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (!mounted) {
          return;
        }
        setState(() {
          _showBirthday = previousValue;
          _isSavingShowBirthday = false;
          _saveError = 'Save failed (${response.statusCode}).';
        });
        return;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        if (!mounted) {
          return;
        }
        setState(() {
          _showBirthday = previousValue;
          _isSavingShowBirthday = false;
          _saveError = 'Invalid settings response from server.';
        });
        return;
      }

      await AuthSession.instance.saveUser(decoded);

      if (!mounted) {
        return;
      }

      setState(() {
        _applyUserData(decoded);
        _isSavingShowBirthday = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _showBirthday = previousValue;
        _isSavingShowBirthday = false;
        _saveError = 'Cannot connect to backend. Ensure Django is running on ${ApiConfig.baseUrl}.';
      });
    }
  }

  void _toggleShowBirthday() {
    if (_isSavingShowBirthday) {
      return;
    }

    _saveShowBirthday(!_showBirthday);
  }

  String _birthdaySubtitle() {
    return '${_showBirthday ? 'Show' : 'Hide'} : $_birthday';
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
          'Settings',
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
                  Text(
                    '$_diamondBalance',
                    style: const TextStyle(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoadingProfile)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      ),
                    ),
                  if (_profileError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _profileError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8B0000),
                        ),
                      ),
                    ),
                  const Text(
                    'Privacy',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _toggleShowBirthday,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF5B5B5B),
                          width: 1.1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Show Birthday on Profile',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _birthdaySubtitle(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6E6E6E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _isSavingShowBirthday
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _showBirthday
                                        ? const Color(0xFF4F8FF7)
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: const Color(0xFF111111),
                                      width: 1.4,
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                  if (_saveError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _saveError!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8B0000),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleBottomNavTap(int index) {
    if (index == _selectedBottomNavIndex && index != 4) {
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
            color: Colors.black.withOpacity(0.08),
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
