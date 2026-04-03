import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/api_config.dart';
import '../../services/auth_session.dart';
import '../../theme/app_theme.dart';
import 'chat.dart';
import 'discover.dart';
import 'profile.dart';
import 'requests.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  int _diamondBalance = 17;
  int _selectedBottomNavIndex = 3;
  bool _isLoadingFriends = true;
  String? _friendsError;
  List<_FriendData> _friends = const [];

  @override
  void initState() {
    super.initState();
    _hydrateDiamondsFromSession();
    _loadFriendsFromApi();
  }

  void _hydrateDiamondsFromSession() {
    final cachedUser = AuthSession.instance.currentUser;
    final diamondsRaw = cachedUser?['diamonds'];
    final diamonds = diamondsRaw is int
        ? diamondsRaw
        : int.tryParse(diamondsRaw?.toString() ?? '');
    if (diamonds != null) {
      _diamondBalance = diamonds;
    }
  }

  Future<void> _loadFriendsFromApi() async {
    final userId = AuthSession.instance.userId;
    if (userId == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingFriends = false;
        _friendsError = 'No logged-in user found.';
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
          _isLoadingFriends = false;
          _friendsError = 'Failed to load friends (${response.statusCode}).';
        });
        return;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoadingFriends = false;
          _friendsError = 'Invalid friends response from server.';
        });
        return;
      }

      final diamondsRaw = decoded['diamonds'];
      final diamonds = diamondsRaw is int
          ? diamondsRaw
          : int.tryParse(diamondsRaw?.toString() ?? '');
      final friendIds = _extractFriendIds(decoded['friends']);
      final friends = await _loadFriendDetails(friendIds);

      if (!mounted) {
        return;
      }

      setState(() {
        if (diamonds != null) {
          _diamondBalance = diamonds;
        }
        _friends = friends;
        _isLoadingFriends = false;
        _friendsError = null;
      });

      await AuthSession.instance.saveUser(decoded);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingFriends = false;
        _friendsError = 'Unable to connect to backend at ${ApiConfig.baseUrl}.';
      });
    }
  }

  List<int> _extractFriendIds(dynamic rawFriends) {
    if (rawFriends is! List) {
      return const [];
    }

    final friendIds = <int>[];
    for (final friend in rawFriends) {
      if (friend is int) {
        friendIds.add(friend);
        continue;
      }

      if (friend is String) {
        final parsed = int.tryParse(friend);
        if (parsed != null) {
          friendIds.add(parsed);
        }
        continue;
      }

      if (friend is Map<String, dynamic>) {
        final rawId = friend['id'];
        if (rawId is int) {
          friendIds.add(rawId);
        } else {
          final parsed = int.tryParse(rawId?.toString() ?? '');
          if (parsed != null) {
            friendIds.add(parsed);
          }
        }
      }
    }

    return friendIds.toSet().toList();
  }

  Future<List<_FriendData>> _loadFriendDetails(List<int> friendIds) async {
    if (friendIds.isEmpty) {
      return const [];
    }

    final results = await Future.wait(
      friendIds.map((friendId) async {
        try {
          final response = await http
              .get(Uri.parse('${ApiConfig.baseUrl}/api/users/$friendId/'))
              .timeout(const Duration(seconds: 12));

          if (response.statusCode < 200 || response.statusCode >= 300) {
            return null;
          }

          final decoded = jsonDecode(response.body);
          if (decoded is! Map<String, dynamic>) {
            return null;
          }

          return _FriendData.fromApi(decoded);
        } catch (_) {
          return null;
        }
      }),
    );

    final friends = results.whereType<_FriendData>().toList();
    friends.sort(
      (left, right) => left.name.toLowerCase().compareTo(right.name.toLowerCase()),
    );
    return friends;
  }

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
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.diamond_rounded,
                      color: Color(0xFF448AFF),
                      size: 20,
                    ),
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
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradient.background),
        child: SafeArea(
          top: false,
          child: _buildFriendsBody(),
        ),
      ),
    );
  }

  Widget _buildFriendsBody() {
    if (_isLoadingFriends) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_friendsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _friendsError!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (_friends.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'You do not have any friends yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      itemCount: _friends.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _FriendTile(data: _friends[index]);
      },
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
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 48,
                  color: Colors.grey,
                ),
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

  factory _FriendData.fromApi(Map<String, dynamic> userData) {
    final name = (userData['name'] as String?)?.trim();
    final birthday = _formatBirthdayValue(userData['birthday'] as String?);
    final gender = _formatGenderValue(userData['gender'] as String?);
    final location = (userData['location'] as String?)?.trim();
    final interests = _formatInterests(userData);
    final profilePicture = _resolveProfilePictureUrl(
      (userData['profilepicture'] as String?)?.trim(),
    );

    return _FriendData(
      name: (name != null && name.isNotEmpty) ? name : 'Unknown friend',
      birthday: birthday,
      gender: gender,
      location: (location != null && location.isNotEmpty)
          ? location
          : 'No location set',
      interests: interests,
      avatarUrl: profilePicture ?? '',
    );
  }

  final String name;
  final String birthday;
  final String gender;
  final String location;
  final String interests;
  final String avatarUrl;
}

String _formatBirthdayValue(String? value) {
  if (value == null || value.isEmpty) {
    return 'Birthday not set';
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
    return 'Gender not set';
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

String _formatInterests(Map<String, dynamic> userData) {
  final interests = [
    (userData['intrest1'] as String?)?.trim(),
    (userData['intrest2'] as String?)?.trim(),
    (userData['intrest3'] as String?)?.trim(),
    (userData['intrest4'] as String?)?.trim(),
  ].whereType<String>().where((value) => value.isNotEmpty).toList();

  if (interests.isEmpty) {
    return 'No interests added';
  }

  return interests.join(', ');
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
    final isLocalHost = parsed.host == '127.0.0.1' || parsed.host == 'localhost';
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