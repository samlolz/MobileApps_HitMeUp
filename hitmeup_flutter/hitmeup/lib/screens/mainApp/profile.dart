import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/api_config.dart';
import '../../services/auth_session.dart';
import '../../theme/app_theme.dart';
import 'chat.dart';
import 'discover.dart';
import 'editProfile.dart';
import 'friends.dart';
import 'requests.dart';
import 'settings.dart';
import '../auth/sign_in_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const TextStyle _profileNameTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 17,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.0,
    color: Color(0xFF1F1F1F),
  );

  static const TextStyle _profileInfoLabelStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.0,
    color: Color(0xFF202020),
  );

  static const TextStyle _profileInfoValueStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.0,
    color: Color.fromRGBO(118, 118, 118, 1),
  );

  static const TextStyle _editButtonTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 17,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.0,
    color: Colors.white,
  );

  int _diamondBalance = 17;
  bool _isLoadingProfile = true;
  String? _profileError;

  int _selectedBottomNavIndex = 4;

  // Profile data
  String _name = 'Alfraz Aldebaran';
  String _birthday = '30 September 2006';
  String _gender = 'Man';
  String _location = 'Tangerang Selatan';
  String _wantToMeet = 'Everyone';
  bool _showBirthday = true;
  String? _profilePictureUrl;
  List<String> _interests = [
    'Watch horror films',
    'Roblox',
    'Content Creator',
    'Matcha',
  ];

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
    final name = (userData['name'] as String?)?.trim();
    final birthdayRaw = (userData['birthday'] as String?)?.trim();
    final genderRaw = (userData['gender'] as String?)?.trim();
    final location = (userData['location'] as String?)?.trim();
    final wantToMeetRaw = (userData['wanttomeet'] as String?)?.trim();
    final showBirthdayRaw = userData['showbirthday'];
    final profilePictureRaw = (userData['profilepicture'] as String?)?.trim();

    final interests = [
      (userData['intrest1'] as String?)?.trim(),
      (userData['intrest2'] as String?)?.trim(),
      (userData['intrest3'] as String?)?.trim(),
      (userData['intrest4'] as String?)?.trim(),
    ].whereType<String>().where((value) => value.isNotEmpty).toList();

    _name = (name != null && name.isNotEmpty) ? name : _name;
    _birthday = _formatBirthdayValue(birthdayRaw);
    _gender = _formatGenderValue(genderRaw);
    _wantToMeet = _formatWantToMeetValue(wantToMeetRaw);
    _showBirthday = _parseBoolValue(showBirthdayRaw, defaultValue: true);
    _location =
        (location != null && location.isNotEmpty) ? location : _location;
    _profilePictureUrl = _resolveProfilePictureUrl(profilePictureRaw);
    _interests = interests.isNotEmpty ? interests : _interests;

    final diamondsRaw = userData['diamonds'];
    if (diamondsRaw is int) {
      _diamondBalance = diamondsRaw;
    } else if (diamondsRaw is String) {
      _diamondBalance = int.tryParse(diamondsRaw) ?? _diamondBalance;
    }
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

  String _formatGenderValue(String? value) {
    if (value == null || value.isEmpty) {
      return _gender;
    }

    switch (value.toLowerCase()) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      default:
        return value;
    }
  }

  String _formatWantToMeetValue(String? value) {
    if (value == null || value.isEmpty) {
      return _wantToMeet;
    }

    switch (value.toLowerCase()) {
      case 'man':
        return 'Man';
      case 'woman':
        return 'Woman';
      case 'everyone':
      case 'anyone':
        return 'Everyone';
      default:
        return value;
    }
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

  String? _resolveProfilePictureUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) {
      return null;
    }

    final normalizedRaw = rawUrl.replaceAll('\\', '/').trim();
    if (normalizedRaw.isEmpty) {
      return null;
    }

    final parsed = Uri.tryParse(normalizedRaw);
    final apiBase = Uri.parse(ApiConfig.baseUrl);

    if (parsed != null && parsed.hasScheme) {
      final isLocalHost =
          parsed.host == '127.0.0.1' || parsed.host == 'localhost';
      if (isLocalHost && apiBase.host != parsed.host) {
        return apiBase
            .replace(
              path: parsed.path,
              query: parsed.query,
              fragment: parsed.fragment,
            )
            .toString();
      }
      return normalizedRaw;
    }

    final base = Uri.parse('${ApiConfig.baseUrl}/');
    final withMediaPrefix =
        normalizedRaw.startsWith('/') ? normalizedRaw : '/media/$normalizedRaw';
    return base.resolve(withMediaPrefix).toString();
  }

  Widget _buildProfileImage() {
    if (_profilePictureUrl == null || _profilePictureUrl!.isEmpty) {
      return Image.asset('assets/FallBackProfile.png', fit: BoxFit.cover);
    }

    return Image.network(
      _profilePictureUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Image.asset('assets/FallBackProfile.png', fit: BoxFit.cover);
      },
    );
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
                mainAxisSize: MainAxisSize.min,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 37,
                        height: 37,
                        child: GestureDetector(
                          onTap: _handleSettingsTap,
                          child: Image.asset(
                            'assets/setting-icon.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) {
                              return const Icon(
                                Icons.settings_outlined,
                                color: Colors.black,
                                size: 30,
                              );
                            },
                          ),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 37,
                        height: 37,
                        child: GestureDetector(
                          onTap: _handleSignOut,
                          child: Image.asset(
                            'assets/SignOut.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 180,
                    height: 180,
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF448AFF),
                    ),
                    child: ClipOval(
                      child: Container(
                        color: Colors.white,
                        child: _buildProfileImage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _name,
                      textAlign: TextAlign.center,
                      style: _profileNameTextStyle,
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
                      color: Colors.white.withOpacity(0.84),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        _ProfileInfoRow(
                          label: 'Birthday date',
                          value: _birthday,
                          labelStyle: _profileInfoLabelStyle,
                          valueStyle: _profileInfoValueStyle,
                        ),
                        const SizedBox(height: 10),
                        _ProfileInfoRow(
                          label: 'Gender',
                          value: _gender,
                          labelStyle: _profileInfoLabelStyle,
                          valueStyle: _profileInfoValueStyle,
                        ),
                        const SizedBox(height: 10),
                        _ProfileInfoRow(
                          label: 'Location',
                          value: _location,
                          labelStyle: _profileInfoLabelStyle,
                          valueStyle: _profileInfoValueStyle,
                        ),
                        const SizedBox(height: 10),
                        _ProfileInfoRow(
                          label: 'My interests',
                          value: _interests.join('\n'),
                          alignTop: true,
                          labelStyle: _profileInfoLabelStyle,
                          valueStyle: _profileInfoValueStyle,
                        ),
                        const SizedBox(height: 10),
                        _ProfileInfoRow(
                          label: 'Who do you want to meet?',
                          value: _wantToMeet,
                          alignTop: true,
                          centerValueY: true,
                          labelStyle: _profileInfoLabelStyle,
                          valueStyle: _profileInfoValueStyle,
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
                        textStyle: _editButtonTextStyle,
                      ),
                      child: const Text(
                        'Edit profile',
                        style: _editButtonTextStyle,
                        textAlign: TextAlign.center,
                      ),
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
          initialWantToMeet: _wantToMeet,
          initialProfilePictureUrl: _profilePictureUrl,
          initialInterests: _interests,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _applyUserData(result);
        _profileError = null;
        _isLoadingProfile = false;
      });

      await AuthSession.instance.saveUser(result);
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

  Future<void> _handleSettingsTap() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );

    if (!mounted) {
      return;
    }

    await _loadProfileFromApi();
  }

  Future<void> _handleSignOut() async {
    showModalBottomSheet<bool>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Are you sure want to log out?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F1F1F),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              const Divider(
                height: 1,
                color: Color.fromARGB(255, 0, 0, 0),
                thickness: 1,
              ),
              const SizedBox(height: 5),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context, true);
                        await AuthSession.instance.clear();
                        if (!mounted) {
                          return;
                        }
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignInScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Log out',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color.fromRGBO(233, 30, 33, 1),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5F5F5),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.label,
    required this.value,
    this.alignTop = false,
    this.centerValueY = false,
    required this.labelStyle,
    required this.valueStyle,
  });

  final String label;
  final String value;
  final bool alignTop;
  final bool centerValueY;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    const effectiveLabelStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Color(0xFF202020),
    );
    final effectiveValueStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: Colors.black.withOpacity(0.52),
    );

    return Row(
      crossAxisAlignment:
          centerValueY ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 132,
          child: Text(
            label,
            softWrap: true,
            style: effectiveLabelStyle,
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              var valueTopPadding = 0.0;

              if (alignTop && !centerValueY) {
                final painter = TextPainter(
                  text: TextSpan(text: label, style: effectiveLabelStyle),
                  textDirection: TextDirection.ltr,
                )..layout(maxWidth: 132);

                final lineCount = painter.computeLineMetrics().length;
                if (lineCount > 1) {
                  final lineHeight = painter.preferredLineHeight;
                  valueTopPadding = (lineCount - 1) * lineHeight;
                }
              }

              return Padding(
                padding: EdgeInsets.only(top: valueTopPadding),
                child: Text(
                  value,
                  style: effectiveValueStyle,
                ),
              );
            },
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
