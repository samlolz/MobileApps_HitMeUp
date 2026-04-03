import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'chat.dart';
import 'discover.dart';
import 'friends.dart';
import 'profile.dart';
import '../../services/api_config.dart';
import '../../services/auth_session.dart';
import '../../theme/app_theme.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  int _diamondBalance = 17;
  int _selectedBottomNavIndex = 1;
  String _currentUserName = 'Alfraz Aldebaran';
  String _currentUserLevel = 'Level 1';
  String? _currentUserProfilePictureUrl;
  bool _isLoadingRequests = true;
  String? _requestsError;
  final List<_FriendRequestCardData> _incomingRequests = [];

  @override
  void initState() {
    super.initState();
    _hydrateDiamondsFromSession();
    _loadLoggedInUserDiamonds();
    _loadIncomingRequests();
  }

  void _hydrateDiamondsFromSession() {
    final cachedUser = AuthSession.instance.currentUser;
    _applyCurrentUserData(cachedUser);
    final diamondsRaw = cachedUser?['diamonds'];
    final diamonds = diamondsRaw is int
        ? diamondsRaw
        : int.tryParse(diamondsRaw?.toString() ?? '');
    if (diamonds != null) {
      _diamondBalance = diamonds;
    }
  }

  void _applyCurrentUserData(Map<String, dynamic>? userData) {
    if (userData == null) {
      return;
    }

    final name = (userData['name'] as String?)?.trim();
    final levelRaw = userData['level'];
    final level =
        levelRaw is int ? levelRaw : int.tryParse(levelRaw?.toString() ?? '');

    final profilePictureRaw = (userData['profilepicture'] as String?)?.trim();

    if (name != null && name.isNotEmpty) {
      _currentUserName = name;
    }
    if (level != null) {
      _currentUserLevel = 'Level ${level < 1 ? 1 : level}';
    }
    _currentUserProfilePictureUrl =
        _resolveProfilePictureUrl(profilePictureRaw);
  }

  Future<void> _loadLoggedInUserDiamonds() async {
    final userId = AuthSession.instance.userId;
    if (userId == null) {
      return;
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/$userId/');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      _applyCurrentUserData(decoded);

      final diamondsRaw = decoded['diamonds'];
      final diamonds = diamondsRaw is int
          ? diamondsRaw
          : int.tryParse(diamondsRaw?.toString() ?? '');

      if (!mounted || diamonds == null) {
        return;
      }

      setState(() {
        _diamondBalance = diamonds;
      });

      await AuthSession.instance.saveUser(decoded);
    } catch (_) {
      // Keep session value silently when request fails.
    }
  }

  Future<void> _loadIncomingRequests() async {
    final userId = AuthSession.instance.userId;
    if (userId == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingRequests = false;
        _requestsError = 'No logged-in user found.';
      });
      return;
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/friend-requests/?receiver=$userId&status=pending',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 12));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoadingRequests = false;
          _requestsError = 'Failed to load requests (${response.statusCode}).';
        });
        return;
      }

      final decoded = jsonDecode(response.body);
      final List<dynamic> requestJson = decoded is List
          ? decoded
          : decoded is Map<String, dynamic> && decoded['results'] is List
              ? decoded['results'] as List<dynamic>
              : const [];

      final requestMaps =
          requestJson.whereType<Map<String, dynamic>>().toList();
      final cards = <_FriendRequestCardData>[];

      for (final request in requestMaps) {
        final requesterIdRaw = request['requester'];
        final requestIdRaw = request['id'];
        final requesterId = requesterIdRaw is int
            ? requesterIdRaw
            : int.tryParse(requesterIdRaw?.toString() ?? '');
        final requestId = requestIdRaw is int
            ? requestIdRaw
            : int.tryParse(requestIdRaw?.toString() ?? '');

        if (requesterId == null || requestId == null) {
          continue;
        }

        final requesterUser = await _fetchUserById(requesterId);
        if (requesterUser == null) {
          continue;
        }

        cards.add(_mapRequestToCard(
          requestId: requestId,
          requesterId: requesterId,
          requesterData: requesterUser,
        ));
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _incomingRequests
          ..clear()
          ..addAll(cards);
        _isLoadingRequests = false;
        _requestsError = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingRequests = false;
        _requestsError = 'Unable to load friend requests right now.';
      });
    }
  }

  Future<Map<String, dynamic>?> _fetchUserById(int userId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/$userId/');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  _FriendRequestCardData _mapRequestToCard({
    required int requestId,
    required int requesterId,
    required Map<String, dynamic> requesterData,
  }) {
    final name = (requesterData['name'] as String?)?.trim();
    final birthdayRaw = (requesterData['birthday'] as String?)?.trim();
    final age = _calculateAgeFromBirthday(birthdayRaw);
    final levelRaw = requesterData['level'];
    final level = levelRaw is int
        ? levelRaw
        : int.tryParse(levelRaw?.toString() ?? '') ?? 1;
    final diamondsRaw = requesterData['diamonds'];
    final diamonds = diamondsRaw is int
        ? diamondsRaw
        : int.tryParse(diamondsRaw?.toString() ?? '') ?? 0;

    return _FriendRequestCardData(
      requestId: requestId,
      requesterId: requesterId,
      name: name != null && name.isNotEmpty ? name : 'Unknown User',
      age: age,
      level: level < 1 ? 1 : level,
      diamonds: diamonds,
      imageUrl: _resolveProfilePictureUrl(
        (requesterData['profilepicture'] as String?)?.trim(),
      ),
    );
  }

  int _calculateAgeFromBirthday(String? birthdayRaw) {
    if (birthdayRaw == null || birthdayRaw.isEmpty) {
      return 0;
    }

    final birthday = DateTime.tryParse(birthdayRaw);
    if (birthday == null) {
      return 0;
    }

    final now = DateTime.now();
    var age = now.year - birthday.year;
    final hasHadBirthdayThisYear = now.month > birthday.month ||
        (now.month == birthday.month && now.day >= birthday.day);
    if (!hasHadBirthdayThisYear) {
      age -= 1;
    }
    return age < 0 ? 0 : age;
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

  Future<void> _updateRequestStatus(
    _FriendRequestCardData request,
    String status,
  ) async {
    final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/friend-requests/${request.requestId}/');

    try {
      final response = await http
          .patch(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'status': status}),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Update failed');
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _incomingRequests
            .removeWhere((item) => item.requestId == request.requestId);
      });

      _showRequestResultDialog(request, status == 'accepted');

      if (status == 'accepted') {
        final refreshedUser = AuthSession.instance.currentUser;
        final userId = AuthSession.instance.userId;
        if (refreshedUser != null && userId != null) {
          final refreshed = await _fetchUserById(userId);
          if (refreshed != null) {
            await AuthSession.instance.saveUser(refreshed);
            if (!mounted) {
              return;
            }
            _applyCurrentUserData(refreshed);
            final diamondsRaw = refreshed['diamonds'];
            final diamonds = diamondsRaw is int
                ? diamondsRaw
                : int.tryParse(diamondsRaw?.toString() ?? '');
            if (diamonds != null) {
              setState(() {
                _diamondBalance = diamonds;
              });
            }
          }
        }
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Unable to update the request right now.')),
      );
    }
  }

  void _showRequestResultDialog(_FriendRequestCardData data, bool accepted) {
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
                child: (data.imageUrl == null || data.imageUrl!.isEmpty)
                    ? Image.asset(
                        'assets/FallBackProfile.png',
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        data.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/FallBackProfile.png',
                          fit: BoxFit.cover,
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
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
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
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
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
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.diamond_rounded,
                        color: Color(0xFF448AFF),
                        size: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_diamondBalance',
                    style: const TextStyle(
                        color: Color(0xFF4F8FF7),
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
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
                          width: 121,
                          height: 123,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.blueBottom, width: 5),
                          ),
                          child: ClipOval(
                            child: ColoredBox(
                              color: Colors.white,
                              child: _currentUserProfilePictureUrl == null
                                  ? Image.asset(
                                      'assets/FallBackProfile.png',
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      _currentUserProfilePictureUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Image.asset(
                                        'assets/FallBackProfile.png',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_currentUserName,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(_currentUserLevel,
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFFCCCCCC))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Get more friends',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              Expanded(
                child: _isLoadingRequests
                    ? const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        ),
                      )
                    : (_requestsError != null
                        ? Center(
                            child: Text(
                              _requestsError!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF8B0000),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : (_incomingRequests.isEmpty
                            ? const Center(
                                child: Text(
                                  'No pending friend requests.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : GridView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 20,
                                  childAspectRatio: 0.78,
                                ),
                                itemCount: _incomingRequests.length,
                                itemBuilder: (context, index) {
                                  final request = _incomingRequests[index];
                                  return _RequestCard(
                                    data: request,
                                    onAccept: () => _updateRequestStatus(
                                      request,
                                      'accepted',
                                    ),
                                    onReject: () => _updateRequestStatus(
                                      request,
                                      'rejected',
                                    ),
                                  );
                                },
                              ))),
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
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard(
      {required this.data, required this.onAccept, required this.onReject});
  final _FriendRequestCardData data;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: Colors.white,
              child: (data.imageUrl == null || data.imageUrl!.isEmpty)
                  ? Image.asset('assets/FallBackProfile.png', fit: BoxFit.cover)
                  : Image.network(
                      data.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/FallBackProfile.png',
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.75),
                      Colors.transparent
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
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
                      child: const Text('+',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              height: 1.0)),
                    ),
                    const SizedBox(width: 2),
                    Image.asset(
                      'assets/diamond.png',
                      width: 18,
                      height: 18,
                      color: const Color(0xFF448AFF),
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.diamond_rounded,
                          color: Color(0xFF448AFF),
                          size: 18),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${data.diamonds}',
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onReject,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onAccept,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                          color: Colors.teal, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${data.name} (${data.age})',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                  Text('Level ${data.level}',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendRequestCardData {
  const _FriendRequestCardData({
    required this.requestId,
    required this.requesterId,
    required this.name,
    required this.age,
    required this.level,
    required this.imageUrl,
    required this.diamonds,
  });

  final int requestId;
  final int requesterId;
  final String name;
  final int age;
  final int level;
  final String? imageUrl;
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
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -2))
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
                onTap: () => onItemTap(0)),
            _BottomNavItem(
                imageAssetPath: 'assets/navbar/requestsSelected.png',
                fallbackIcon: Icons.grid_view_rounded,
                selected: selectedIndex == 1,
                onTap: () => onItemTap(1)),
            _BottomNavItem(
                imageAssetPath: 'assets/navbar/chat.png',
                fallbackIcon: Icons.chat_bubble_outline_rounded,
                selected: selectedIndex == 2,
                onTap: () => onItemTap(2)),
            _BottomNavItem(
                imageAssetPath: 'assets/navbar/friends.png',
                fallbackIcon: Icons.groups_rounded,
                selected: selectedIndex == 3,
                onTap: () => onItemTap(3)),
            _BottomNavItem(
                imageAssetPath: 'assets/navbar/profile.png',
                fallbackIcon: Icons.account_circle_outlined,
                selected: selectedIndex == 4,
                onTap: () => onItemTap(4)),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem(
      {required this.imageAssetPath,
      required this.fallbackIcon,
      required this.selected,
      required this.onTap});
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
              child: Image.asset(imageAssetPath,
                  width: 32,
                  height: 32,
                  fit: BoxFit.fill,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(fallbackIcon, color: Colors.black, size: 24)),
            ),
          ),
        ),
      ),
    );
  }
}
