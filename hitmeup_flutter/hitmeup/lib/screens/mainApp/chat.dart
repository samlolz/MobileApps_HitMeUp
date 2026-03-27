import 'package:flutter/material.dart';

import 'community.dart';
import 'discover.dart';
import 'friends.dart';
import 'profile.dart';
import 'requests.dart';
import 'ai_chat_screen.dart';
import 'community_chat_screen.dart';
import 'create_community_screen.dart';
import 'direct_chat_screen.dart';
import 'chat_models.dart';
import '../../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const int _diamondBalance = 17;

  int _selectedBottomNavIndex = 2;

  final List<_CommunityItemData> _communities = const [
    _CommunityItemData(
      title: 'Rblx Geng',
      participants: '75 Participants',
      imageUrl: 'https://i.pravatar.cc/240?img=11',
    ),
    _CommunityItemData(
      title: 'Penyuka Horror',
      participants: '24 Participants',
      imageUrl: 'https://i.pravatar.cc/240?img=24',
    ),
    _CommunityItemData(
      title: 'Tiktokers',
      participants: '48 Participants',
      imageUrl: 'https://i.pravatar.cc/240?img=41',
    ),
    _CommunityItemData(
      title: 'Mabar ff',
      participants: '50 Participants',
      icon: Icons.groups_rounded,
      iconBackground: Color(0xFFF53D84),
    ),
    _CommunityItemData(
      title: 'Main Padel Yuk!',
      participants: '15 Participants',
      icon: Icons.groups_rounded,
      iconBackground: Color(0xFFF53D84),
    ),
    _CommunityItemData(
      title: 'Create a new\ncommunity',
      participants: '',
      icon: Icons.add,
      iconBackground: Color(0xFFD6E5EA),
    ),
  ];

  final List<_ChatPreviewData> _recentChats = const [
    _ChatPreviewData(
      name: 'Siti Ratmawati',
      message: 'Baiklah, see you Alfraz',
      avatarUrl: 'https://i.pravatar.cc/160?img=44',
    ),
    _ChatPreviewData(
      name: 'Budi Amman',
      message: 'WAHHH PANTESAN HAHAHHA',
      avatarUrl: 'https://i.pravatar.cc/160?img=13',
    ),
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
          'Chat',
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
        selectedIndex: 2,
        onItemTap: _handleBottomNavTap,
      ),
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppGradient.background),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
              child: Column(
                children: [
                  // Chat.AI
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AiChatScreen()),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/AIBrain.png',
                              width: 30,
                              height: 30,
                              fit: BoxFit.contain,
                            ),
                            Container(
                              width: 1,
                              height: 58,
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              color: const Color(0xFF717171),
                            ),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Chat.AI',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 25,
                                      fontWeight: FontWeight.w800,
                                      height: 1,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'temukan keluh kesah mu disini dengan bantuan AI',
                                    style: TextStyle(
                                      color: Color(0xFF6A6A6A),
                                      fontSize: 9,
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
                  ),
                  const SizedBox(height: 16),
                  // Community section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 10,
                          runSpacing: 10,
                          children: _communities
                              .map((item) => _CommunityItemTile(
                                    data: item,
                                    onTap: () => _handleCommunityTap(item),
                                  ))
                              .toList(),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CommunityScreen(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: const Padding(
                              padding: EdgeInsets.only(right: 2, top: 2),
                              child: Text(
                                'more...',
                                style: TextStyle(
                                  color: Color(0xFF5A5A5A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Recent chats
                  ..._recentChats.map(
                    (chat) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RecentChatTile(
                        data: chat,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DirectChatScreen(
                              chat: DirectChat(
                                name: chat.name,
                                lastMessage: chat.message,
                                avatarUrl: chat.avatarUrl,
                              ),
                            ),
                          ),
                        ),
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

  void _handleCommunityTap(_CommunityItemData data) {
    if (data.icon == Icons.add) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CreateCommunityScreen()),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CommunityChatScreen(
            community: Community(
              name: data.title,
              participants: int.tryParse(
                    data.participants.replaceAll(RegExp(r'[^0-9]'), ''),
                  ) ??
                  0,
              imageUrl: data.imageUrl,
            ),
          ),
        ),
      );
    }
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

class _CommunityItemTile extends StatelessWidget {
  const _CommunityItemTile({required this.data, required this.onTap});

  final _CommunityItemData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 102,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                clipBehavior: Clip.antiAlias,
                child: data.imageUrl != null
                    ? Image.network(data.imageUrl!, fit: BoxFit.cover)
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          color: data.iconBackground ?? const Color(0xFFD6E5EA),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          data.icon ?? Icons.groups_rounded,
                          size: 56,
                          color: data.icon == Icons.add
                              ? Colors.black
                              : const Color(0xFFE9FFFF),
                        ),
                      ),
              ),
              const SizedBox(height: 6),
              Text(
                data.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              if (data.participants.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    data.participants,
                    style: const TextStyle(
                      color: Color(0xFF5E5E5E),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
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

class _RecentChatTile extends StatelessWidget {
  const _RecentChatTile({required this.data, required this.onTap});

  final _ChatPreviewData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F3),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(data.avatarUrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF4F4F4F),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
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

class _CommunityItemData {
  const _CommunityItemData({
    required this.title,
    required this.participants,
    this.imageUrl,
    this.icon,
    this.iconBackground,
  });

  final String title;
  final String participants;
  final String? imageUrl;
  final IconData? icon;
  final Color? iconBackground;
}

class _ChatPreviewData {
  const _ChatPreviewData({
    required this.name,
    required this.message,
    required this.avatarUrl,
  });

  final String name;
  final String message;
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
              imageAssetPath: 'assets/navbar/chatSelected.png',
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