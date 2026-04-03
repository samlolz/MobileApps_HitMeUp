import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
import '../../services/api_config.dart';
import '../../services/auth_session.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';

// Chat data provider class - used for community chat data
class ChatDataProvider {
  // Centralized community chat data
  static final Map<String, List<Map<String, dynamic>>> communityChatData = {
    'comm_001': [
      {
        'id': 'cm001_001',
        'communityId': 'comm_001',
        'senderId': 'user_rosia',
        'text': 'Malam ini mau mabar ga?',
        'isMe': false,
        'sender': 'Rosia morens',
        'time': '16:07',
        'type': 'text'
      },
      {
        'id': 'cm001_002',
        'communityId': 'comm_001',
        'senderId': 'user_petra',
        'text': 'wii boleh tu, ayoo',
        'isMe': false,
        'sender': 'Petra',
        'time': '16:10',
        'type': 'text'
      },
      {
        'id': 'cm001_003',
        'communityId': 'comm_001',
        'senderId': 'user_kiranti',
        'text': 'enaknya jam berapa ya?',
        'isMe': false,
        'sender': 'Kiranti',
        'time': '16:18',
        'type': 'text'
      },
      {
        'id': 'cm001_004',
        'communityId': 'comm_001',
        'senderId': 'me',
        'text': 'Jam 21.00, bagaimana?',
        'isMe': true,
        'sender': '',
        'time': '16:26',
        'type': 'text'
      },
      {
        'id': 'cm001_005',
        'communityId': 'comm_001',
        'senderId': 'user_rosia',
        'text': 'Bolehhh tu',
        'isMe': false,
        'sender': 'Rosia morens',
        'time': '16:28',
        'type': 'text'
      },
      {
        'id': 'cm001_poll_001',
        'communityId': 'comm_001',
        'isPoll': true,
        'time': '16:30',
        'type': 'poll'
      },
      {
        'id': 'cm001_006',
        'communityId': 'comm_001',
        'senderId': 'me',
        'text': 'Gass ramaikan!!',
        'isMe': true,
        'sender': '',
        'time': '16:31',
        'type': 'text'
      },
      {
        'id': 'cm001_007',
        'communityId': 'comm_001',
        'senderId': 'user_vania',
        'text': 'Iya nih sudah lama tidak mabar',
        'isMe': false,
        'sender': 'Vania kursel',
        'time': '17:00',
        'type': 'text'
      },
      {
        'id': 'cm001_008',
        'communityId': 'comm_001',
        'senderId': 'user_yuqi',
        'text': 'Maaf ya teman - teman tidak bisa ikut dulu',
        'isMe': false,
        'sender': 'Yuqi nako',
        'time': '18:10',
        'type': 'text'
      },
    ],
    'comm_002': [
      {
        'id': 'cm002_001',
        'communityId': 'comm_002',
        'senderId': 'user_ana',
        'text': 'Ada yang udah nonton Kafir: Gerbang Sukma?',
        'isMe': false,
        'sender': 'Ana',
        'time': '19:00',
        'type': 'text'
      },
      {
        'id': 'cm002_002',
        'communityId': 'comm_002',
        'senderId': 'me',
        'text': 'Udah! Serem banget bagian akhirnya',
        'isMe': true,
        'sender': '',
        'time': '19:02',
        'type': 'text'
      },
      {
        'id': 'cm002_003',
        'communityId': 'comm_002',
        'senderId': 'user_deni',
        'text': 'Gue belum, ga ada yang mau nemenin nonton',
        'isMe': false,
        'sender': 'Deni',
        'time': '19:05',
        'type': 'text'
      },
      {
        'id': 'cm002_004',
        'communityId': 'comm_002',
        'senderId': 'user_ana',
        'text': 'Nonton bareng yuk! Sabtu gimana?',
        'isMe': false,
        'sender': 'Ana',
        'time': '19:06',
        'type': 'text'
      },
      {
        'id': 'cm002_005',
        'communityId': 'comm_002',
        'senderId': 'me',
        'text': 'Sabtu oke! Di Blok M Plaza aja',
        'isMe': true,
        'sender': '',
        'time': '19:08',
        'type': 'text'
      },
      {
        'id': 'cm002_006',
        'communityId': 'comm_002',
        'senderId': 'user_deni',
        'text': 'Siap! Jam berapa?',
        'isMe': false,
        'sender': 'Deni',
        'time': '19:09',
        'type': 'text'
      },
    ],
    'comm_003': [
      {
        'id': 'cm003_001',
        'communityId': 'comm_003',
        'senderId': 'user_rio',
        'text': 'Ada yang mau collab bikin konten bareng?',
        'isMe': false,
        'sender': 'Rio',
        'time': '14:00',
        'type': 'text'
      },
      {
        'id': 'cm003_002',
        'communityId': 'comm_003',
        'senderId': 'me',
        'text': 'Mau! Konten apa yang mau dibuat?',
        'isMe': true,
        'sender': '',
        'time': '14:05',
        'type': 'text'
      },
      {
        'id': 'cm003_003',
        'communityId': 'comm_003',
        'senderId': 'user_rio',
        'text': 'Dance challenge yang lagi viral itu loh',
        'isMe': false,
        'sender': 'Rio',
        'time': '14:06',
        'type': 'text'
      },
      {
        'id': 'cm003_004',
        'communityId': 'comm_003',
        'senderId': 'user_mia',
        'text': 'Ih aku mau ikut juga dong!',
        'isMe': false,
        'sender': 'Mia',
        'time': '14:10',
        'type': 'text'
      },
      {
        'id': 'cm003_005',
        'communityId': 'comm_003',
        'senderId': 'me',
        'text': 'Ayo makin rame makin seru!',
        'isMe': true,
        'sender': '',
        'time': '14:11',
        'type': 'text'
      },
    ],
    'comm_004': [
      {
        'id': 'cm004_001',
        'communityId': 'comm_004',
        'senderId': 'user_bro',
        'text': 'Siapa yang rank diamond ke atas?',
        'isMe': false,
        'sender': 'Bro',
        'time': '20:00',
        'type': 'text'
      },
      {
        'id': 'cm004_002',
        'communityId': 'comm_004',
        'senderId': 'me',
        'text': 'Gue platinum, bisa join ga?',
        'isMe': true,
        'time': '20:01',
        'type': 'text'
      },
      {
        'id': 'cm004_003',
        'communityId': 'comm_004',
        'senderId': 'user_bro',
        'text': 'Boleh, asal jangan feeding ya wkwk',
        'isMe': false,
        'sender': 'Bro',
        'time': '20:02',
        'type': 'text'
      },
      {
        'id': 'cm004_004',
        'communityId': 'comm_004',
        'senderId': 'me',
        'text': 'Siap bos! Ready kapanpun',
        'isMe': true,
        'time': '20:03',
        'type': 'text'
      },
    ],
    'comm_005': [
      {
        'id': 'cm005_001',
        'communityId': 'comm_005',
        'senderId': 'user_kevin',
        'text': 'Besok pagi ada slot kosong di lapangan GBK jam 7',
        'isMe': false,
        'sender': 'Kevin',
        'time': '21:00',
        'type': 'text'
      },
      {
        'id': 'cm005_002',
        'communityId': 'comm_005',
        'senderId': 'me',
        'text': 'Wah oke banget! Siapa yang mau join?',
        'isMe': true,
        'sender': '',
        'time': '21:01',
        'type': 'text'
      },
      {
        'id': 'cm005_003',
        'communityId': 'comm_005',
        'senderId': 'user_tari',
        'text': 'Aku mau! Udah lama ga main padel',
        'isMe': false,
        'sender': 'Tari',
        'time': '21:02',
        'type': 'text'
      },
      {
        'id': 'cm005_004',
        'communityId': 'comm_005',
        'senderId': 'user_kevin',
        'text': 'Oke kita berempat cukup, gas!',
        'isMe': false,
        'sender': 'Kevin',
        'time': '21:03',
        'type': 'text'
      },
    ],
  };
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  int _diamondBalance = 17;
  int _selectedBottomNavIndex = 2;
  List<DirectChat> _directChats = [];
  List<_CommunityItemData> _communities = const [
    _CommunityItemData(
      id: 'create_new',
      title: 'Create a new\ncommunity',
      participants: '',
      icon: Icons.add,
      iconBackground: Color(0xFFD6E5EA),
    ),
  ];

  List<_ChatPreviewData> get _recentChats => _directChats
      .map((chat) => _ChatPreviewData(
            id: chat.id.toString(),
            name: chat.name,
            message: chat.lastMessage,
            avatarUrl: chat.avatarUrl ?? 'https://i.pravatar.cc/160?img=1',
            directChat: chat,
          ))
      .toList();

  @override
  void initState() {
    super.initState();
    _hydrateDiamondsFromSession();
    _loadLoggedInUserDiamonds();
    _loadDirectChats();
    _loadUserCommunities();
  }

  String _resolveCommunityImageUrl(dynamic rawPath) {
    final value = (rawPath ?? '').toString().trim();
    if (value.isEmpty) {
      return 'assets/FallBackProfile.png';
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final path = value.startsWith('/') ? value : '/$value';
    return '$base$path';
  }

  Future<void> _loadUserCommunities() async {
    final userId = AuthSession.instance.userId;
    if (userId == null) {
      return;
    }

    try {
      final userData = await ChatService.fetchUser(userId);
      final userCommunityIds = ((userData['communities'] as List?) ?? const [])
          .map((id) => id.toString())
          .toSet();

      final allCommunities = await ChatService.fetchCommunities();
      final userCommunities = allCommunities.where((community) {
        final communityId = community['id']?.toString();
        return communityId != null && userCommunityIds.contains(communityId);
      }).map((community) {
        final rawPicture = community['communityPicture'];
        final hasPicture = rawPicture != null && rawPicture.toString().trim().isNotEmpty;
        return _CommunityItemData(
          id: (community['id'] ?? '').toString(),
          title: (community['name'] ?? 'Community').toString(),
          participants: '${community['totalParticipants'] ?? 0} Participants',
          imageUrl: hasPicture ? _resolveCommunityImageUrl(rawPicture) : 'assets/FallBackProfile.png',
          imageIsAsset: !hasPicture,
        );
      }).toList();

      userCommunities.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

      if (!mounted) return;
      setState(() {
        _communities = [
          ...userCommunities,
          const _CommunityItemData(
            id: 'create_new',
            title: 'Create a new\ncommunity',
            participants: '',
            icon: Icons.add,
            iconBackground: Color(0xFFD6E5EA),
          ),
        ];
      });
    } catch (_) {
      // Keep only create tile when request fails.
    }
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

  Future<void> _loadDirectChats() async {
    final userId = AuthSession.instance.userId;
    if (userId == null) {
      return;
    }

    try {
      final chats = await ChatService.fetchDirectChats(userId);
      final List<DirectChat> directChats = [];

      for (var chatData in chats) {
        try {
          final otherUser = await ChatService.getOtherUser(
            chat: chatData,
            currentUserId: userId,
          );
          
          final directChat = DirectChat.fromJson(
            chatData,
            otherUserName: otherUser['name'] as String? ?? 'Unknown',
            otherUserAvatar: otherUser['profilepicture'] as String?,
          );
          directChats.add(directChat);
        } catch (e) {
          // Skip chats that fail to load
          continue;
        }
      }

      if (mounted) {
        setState(() {
          _directChats = directChats;
        });
      }
    } catch (e) {
      // Silently fail - will just show empty chats
    }
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
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
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
                        onTap: () {
                          if (chat.directChat == null) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  DirectChatScreen(chat: chat.directChat!),
                            ),
                          );
                        },
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
      ).then((_) {
        _loadUserCommunities();
      });
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CommunityChatScreen(
            community: Community(
              id: data.id,
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
                  ? (data.imageIsAsset
                    ? Image.asset(data.imageUrl!, fit: BoxFit.cover)
                    : Image.network(data.imageUrl!, fit: BoxFit.cover))
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
    required this.id,
    required this.title,
    required this.participants,
    this.imageUrl,
    this.imageIsAsset = false,
    this.icon,
    this.iconBackground,
  });

  final String id;
  final String title;
  final String participants;
  final String? imageUrl;
  final bool imageIsAsset;
  final IconData? icon;
  final Color? iconBackground;
}

class _ChatPreviewData {
  const _ChatPreviewData({
    required this.id,
    required this.name,
    required this.message,
    required this.avatarUrl,
    this.directChat,
  });

  final String id;
  final String name;
  final String message;
  final String avatarUrl;
  final DirectChat? directChat;
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
