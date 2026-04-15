import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/auth_session.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({
    super.key,
    this.contextUserId,
    this.contextCommunityId,
    this.contextTitle,
  });

  final int? contextUserId;
  final int? contextCommunityId;
  final String? contextTitle;

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  static const int _messagePageSize = 20;
  static const double _topLoadThreshold = 120.0;
  static const String _assistantTypingMarker = '__assistant_typing__';

  static const TextStyle _chatBubbleTextStyle = TextStyle(
    fontSize: 13,
    color: Colors.black,
  );

  static const TextStyle _chatInputTextStyle = TextStyle(
    fontFamily: 'Konkhmer Sleokchher',
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 1.0,
    letterSpacing: 0,
    color: Colors.black,
  );

  static const TextStyle _chatInputHintTextStyle = TextStyle(
    fontFamily: 'Konkhmer Sleokchher',
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 1.0,
    letterSpacing: 0,
    color: Colors.black38,
  );

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isLoading = true;
  bool _isInitializingChat = true;
  bool _isSending = false;
  bool _isLoadingMoreMessages = false;
  bool _hasMoreOlderMessages = true;
  String? _playingVoiceUrl;
  bool _isVoicePlaying = false;

  int? _aiChatId;
  List<Map<String, dynamic>> _messages = [];
  String? _mainUserProfileUrl;
  final Map<int, Map<String, dynamic>> _recommendedProfiles = {};
  final Set<int> _submittingFriendRequests = <int>{};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isVoicePlaying = state == PlayerState.playing;
        if (state == PlayerState.stopped) {
          _playingVoiceUrl = null;
        }
      });
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isVoicePlaying = false;
        _playingVoiceUrl = null;
      });
    });
    _initializeChat();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    unawaited(_audioPlayer.stop());
    unawaited(_audioPlayer.dispose());
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    if (_scrollController.position.pixels <= _topLoadThreshold) {
      _loadOlderMessages();
    }
  }

  String _screenSubtitle() {
    final title = widget.contextTitle?.trim();
    if (title != null && title.isNotEmpty) {
      return title;
    }
    if (widget.contextUserId != null) {
      return 'AI chat in direct context';
    }
    if (widget.contextCommunityId != null) {
      return 'AI chat in community context';
    }
    return 'Personal AI chat';
  }

  String? _resolveProfileUrl(dynamic rawPath) {
    final value = (rawPath ?? '').toString().trim();
    if (value.isEmpty) {
      return null;
    }
    return _resolveMediaUrl(value);
  }

  Future<void> _loadMainUserProfile(int userId) async {
    final cachedUser = AuthSession.instance.currentUser;
    final cachedProfileUrl = _resolveProfileUrl(cachedUser?['profilepicture']);
    if (cachedProfileUrl != null && mounted) {
      setState(() {
        _mainUserProfileUrl = cachedProfileUrl;
      });
    }

    try {
      final userData = await ChatService.fetchUser(userId);
      final freshProfileUrl = _resolveProfileUrl(userData['profilepicture']);

      if (!mounted) {
        return;
      }

      setState(() {
        _mainUserProfileUrl = freshProfileUrl;
      });

      final mergedUser = <String, dynamic>{
        ...?cachedUser,
        ...userData,
      };
      unawaited(AuthSession.instance.saveUser(mergedUser));
    } catch (_) {
      // Keep cached avatar if user fetch fails.
    }
  }

  Future<void> _initializeChat() async {
    final userId = AuthSession.instance.userId;
    if (userId == null) {
      if (mounted) {
        setState(() {
          _isInitializingChat = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not logged in')),
        );
      }
      return;
    }

    unawaited(_loadMainUserProfile(userId));

    try {
      final aiChat = await ChatService.ensureAiChat(
        mainUserId: userId,
        contextUserId: widget.contextUserId,
        contextCommunityId: widget.contextCommunityId,
      );

      final chatId = aiChat['id'] is int
          ? aiChat['id'] as int
          : int.tryParse(aiChat['id'].toString());
      if (chatId == null) {
        throw Exception('Invalid AI chat id received from server.');
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _aiChatId = chatId;
        _isInitializingChat = false;
      });

      await _loadMessages();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializingChat = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize AI chat: $e')),
        );
      }
    }
  }

  Future<void> _loadMessages() async {
    final chatId = _aiChatId;
    if (chatId == null) {
      return;
    }

    try {
      final messages = await ChatService.fetchAiMessages(
        chatId,
        limit: _messagePageSize,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _messages = messages;
        _isLoading = false;
        _hasMoreOlderMessages = messages.length == _messagePageSize;
      });
      unawaited(_syncRecommendationProfilesFromMessages());
      _scrollToBottomUntilStable();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading AI messages: $e')),
        );
      }
    }
  }

  Future<void> _loadOlderMessages() async {
    final chatId = _aiChatId;
    if (chatId == null || _isLoading || _isLoadingMoreMessages || !_hasMoreOlderMessages || _messages.isEmpty) {
      return;
    }

    final oldestMessageId = _messageIdFromMessage(_messages.first);
    if (oldestMessageId == null) {
      return;
    }

    final oldPixels = _scrollController.hasClients ? _scrollController.position.pixels : 0.0;
    final oldMaxScrollExtent = _scrollController.hasClients ? _scrollController.position.maxScrollExtent : 0.0;

    setState(() {
      _isLoadingMoreMessages = true;
    });

    try {
      final olderMessages = await ChatService.fetchAiMessages(
        chatId,
        limit: _messagePageSize,
        beforeId: oldestMessageId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        if (olderMessages.isNotEmpty) {
          _messages = [...olderMessages, ..._messages];
        }
        _hasMoreOlderMessages = olderMessages.length == _messagePageSize;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) {
          return;
        }

        final newMaxScrollExtent = _scrollController.position.maxScrollExtent;
        final delta = newMaxScrollExtent - oldMaxScrollExtent;
        final targetOffset = oldPixels + delta;
        _scrollController.jumpTo(targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading older AI messages: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMoreMessages = false;
        });
      }
    }
  }

  int? _messageIdFromMessage(Map<String, dynamic> message) {
    final idValue = message['id'];
    if (idValue is int) {
      return idValue;
    }
    return int.tryParse(idValue.toString());
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    final userId = AuthSession.instance.userId;
    final chatId = _aiChatId;
    if (userId == null || chatId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not logged in or AI chat unavailable')),
      );
      return;
    }

    _controller.clear();
    setState(() => _isSending = true);

    try {
      final userMessage = await ChatService.sendAiMessage(
        chatId: chatId,
        senderId: userId,
        text: text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(userMessage);
        _insertAssistantTypingPlaceholder();
      });
      _scrollToBottomWithSettling();

      await _sendAssistantReplyFor();
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending AI message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _sendAssistantReplyFor() async {
    final chatId = _aiChatId;
    if (chatId == null) {
      return;
    }

    try {
      final aiMessage = await ChatService.generateAiReply(
        chatId: chatId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _replaceAssistantTypingPlaceholder(aiMessage);
      });

      final rawText = (aiMessage['text'] ?? '').toString();
      final recommendedIds = _extractRecommendationIds(rawText);
      if (recommendedIds.isNotEmpty) {
        unawaited(_loadRecommendedProfiles(recommendedIds));
      }

      _scrollToBottomWithSettling();
    } catch (e) {
      if (mounted) {
        setState(_removeAssistantTypingPlaceholder);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate AI reply: $e')),
        );
      }
    }
  }

  String _resolveMediaUrl(String rawUrl) {
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }
    if (rawUrl.startsWith('/')) {
      return '${ChatService.baseUrl}$rawUrl';
    }
    return '${ChatService.baseUrl}/$rawUrl';
  }

  Future<void> _toggleVoicePlayback(String rawVoiceUrl) async {
    final resolvedUrl = _resolveMediaUrl(rawVoiceUrl);
    try {
      if (_playingVoiceUrl == resolvedUrl && _isVoicePlaying) {
        await _audioPlayer.pause();
        return;
      }

      await _audioPlayer.stop();
      final response = await http.get(Uri.parse(resolvedUrl)).timeout(
        const Duration(seconds: 15),
      );
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw Exception('Voice file could not be loaded (${response.statusCode}).');
      }

      setState(() {
        _playingVoiceUrl = resolvedUrl;
      });
      await _audioPlayer.play(BytesSource(response.bodyBytes));
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice playback request timed out.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to play voice message: $e')),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      final target = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  void _scrollToBottomWithSettling() {
    _scrollToBottom();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        _scrollToBottom(animated: false);
      }
    });
  }

  void _scrollToBottomUntilStable({int maxAttempts = 8}) {
    double previousExtent = -1;

    void runAttempt(int attempt) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      final currentExtent = _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo(currentExtent);

      final isStable = (currentExtent - previousExtent).abs() < 1;
      if (attempt >= maxAttempts || (attempt > 1 && isStable)) {
        return;
      }

      previousExtent = currentExtent;
      Future.delayed(const Duration(milliseconds: 140), () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          runAttempt(attempt + 1);
        });
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      runAttempt(1);
    });
  }

  List<int> _extractRecommendationIds(String text) {
    if (text.trim().isEmpty) {
      return [];
    }

    final matches = RegExp(r'\[FRIEND_REC\]\s*(\d+)\s*\[/FRIEND_REC\]', caseSensitive: false).allMatches(text);
    final ids = <int>[];
    for (final match in matches) {
      final parsed = int.tryParse(match.group(1) ?? '');
      if (parsed != null) {
        ids.add(parsed);
      }
    }

    if (ids.isEmpty) {
      final fallbackMatch = RegExp(r'\[FRIEND_REC\]\s*(\d+)', caseSensitive: false).firstMatch(text);
      final fallbackId = int.tryParse(fallbackMatch?.group(1) ?? '');
      if (fallbackId != null) {
        ids.add(fallbackId);
      }
    }

    return ids.toSet().toList();
  }

  void _insertAssistantTypingPlaceholder() {
    if (_messages.any((message) => message['_localType'] == _assistantTypingMarker)) {
      return;
    }

    _messages.add({
      'id': 'assistant-typing-${DateTime.now().microsecondsSinceEpoch}',
      'text': '',
      'image': null,
      'voiceRecording': null,
      'isMe': false,
      'isFromAI': true,
      'recommendedUserIds': const <int>[],
      'time': '',
      '_localType': _assistantTypingMarker,
    });
  }

  void _replaceAssistantTypingPlaceholder(Map<String, dynamic> aiMessage) {
    final placeholderIndex = _messages.indexWhere((message) => message['_localType'] == _assistantTypingMarker);
    if (placeholderIndex == -1) {
      _messages.add(aiMessage);
      return;
    }

    _messages[placeholderIndex] = aiMessage;
  }

  void _removeAssistantTypingPlaceholder() {
    _messages.removeWhere((message) => message['_localType'] == _assistantTypingMarker);
  }

  String _stripRecommendationMarkers(String text) {
    return text
        .replaceAll(RegExp(r'\[FRIEND_REC\]\s*\d+\s*\[/FRIEND_REC\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  Future<void> _loadRecommendedProfiles(List<int> userIds) async {
    for (final userId in userIds) {
      if (_recommendedProfiles.containsKey(userId)) {
        continue;
      }
      try {
        final userData = await ChatService.fetchUser(userId);
        if (!mounted) {
          return;
        }
        setState(() {
          _recommendedProfiles[userId] = userData;
        });
      } catch (_) {
        // Ignore missing profile details silently.
      }
    }
  }

  Future<void> _syncRecommendationProfilesFromMessages() async {
    final ids = <int>{};
    for (final message in _messages) {
      final text = (message['text'] ?? '').toString();
      ids.addAll(_extractRecommendationIds(text));
    }

    if (ids.isNotEmpty) {
      await _loadRecommendedProfiles(ids.toList());
    }
  }

  Future<void> _sendFriendRequestToUser(int receiverId) async {
    final requesterId = AuthSession.instance.userId;
    if (requesterId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not logged in')),
        );
      }
      return;
    }

    if (_submittingFriendRequests.contains(receiverId)) {
      return;
    }

    setState(() {
      _submittingFriendRequests.add(receiverId);
    });

    try {
      final response = await http.post(
        Uri.parse('${ChatService.baseUrl}/api/friend-requests/send-friend-request/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requester_id': requesterId,
          'receiver_id': receiverId,
        }),
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request sent')),
        );
      } else {
        String detail = 'Failed to send friend request';
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          detail = (body['detail'] ?? detail).toString();
        } catch (_) {
          detail = 'Failed to send friend request (${response.statusCode})';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(detail)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send friend request: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _submittingFriendRequests.remove(receiverId);
        });
      }
    }
  }

  Map<String, dynamic> _toDisplayMessage(Map<String, dynamic> msg) {
    if (msg['_localType'] == _assistantTypingMarker) {
      return {
        'id': msg['id'],
        'text': '',
        'image': null,
        'voiceRecording': null,
        'isMe': false,
        'isFromAI': true,
        'recommendedUserIds': const <int>[],
        'time': '',
        'isTyping': true,
      };
    }

    final currentUserId = AuthSession.instance.userId;
    final senderId = msg['sender'] is int
        ? msg['sender'] as int
        : int.tryParse(msg['sender']?.toString() ?? '');
    final isFromAI = msg['isFromAI'] == true;
    final isMe = !isFromAI && senderId != null && senderId == currentUserId;

    final rawText = (msg['text'] ?? '').toString();
    final recommendationIds = _extractRecommendationIds(rawText);

    return {
      'id': msg['id'],
      'text': _stripRecommendationMarkers(rawText),
      'image': msg['image'] as String?,
      'voiceRecording': msg['voiceRecording'] as String?,
      'isMe': isMe,
      'isFromAI': isFromAI,
      'recommendedUserIds': recommendationIds,
    };
  }

  String _formatTime(String dateTimeString) {
    try {
      final wibTime = DateTime.parse(dateTimeString)
          .toUtc()
          .add(const Duration(hours: 7));
      final hour = wibTime.hour.toString().padLeft(2, '0');
      final minute = wibTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: Container(
        color: const Color(0xFFFCE4EC),
        child: Column(
          children: [
            Container(color: Colors.white, child: _buildAppBar(context)),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFF4081), Color(0xFFFCE4EC)],
                  ),
                ),
                child: Stack(
                  children: [
                    if (_isInitializingChat || _isLoading)
                      const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    else
                      ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final rawMessage = _messages[index];
                          return _buildMessageWithRecommendations(_toDisplayMessage(rawMessage));
                        },
                      ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    if (_isLoadingMoreMessages)
                      Positioned(
                        top: 8,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Loading older messages...',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      color: Colors.white,
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 4,
                        bottom: MediaQuery.of(context).padding.bottom + 8,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _buildTextInputBar(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 8,
        right: 16,
        bottom: 8,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          Image.asset(
            'assets/AIBrain.png',
            width: 28,
            height: 28,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.psychology_rounded, size: 28, color: Colors.black),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Chat.AI',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                Text(
                  _screenSubtitle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInputBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            minLines: 1,
            maxLines: null,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              hintText: 'Ask Chat.AI anything...',
              hintStyle: _chatInputHintTextStyle,
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: _chatInputTextStyle,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _isSending ? null : _sendMessage,
          child: Icon(
            Icons.arrow_upward,
            color: _isSending ? Colors.black26 : Colors.black,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final isMe = msg['isMe'] as bool;
    final isFromAI = msg['isFromAI'] as bool? ?? false;
    final isTyping = msg['isTyping'] as bool? ?? false;
    final text = msg['text'] as String? ?? '';
    final imageUrl = msg['image'] as String?;
    final voiceUrl = msg['voiceRecording'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Image.asset(
                'assets/AIBrain.png',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.psychology_rounded, size: 28, color: Colors.black54),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isMe ? 14 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 14),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isTyping) const _AiTypingIndicator(),
                  if (text.trim().isNotEmpty)
                    Text(
                      text,
                      style: _chatBubbleTextStyle,
                    ),
                  if (imageUrl != null && imageUrl.trim().isNotEmpty) ...[
                    if (text.trim().isNotEmpty) const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        _resolveMediaUrl(imageUrl),
                        width: 170,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 170,
                          height: 110,
                          color: Colors.grey.shade200,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                  if (voiceUrl != null && voiceUrl.trim().isNotEmpty) ...[
                    if (text.trim().isNotEmpty || (imageUrl != null && imageUrl.trim().isNotEmpty)) const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _toggleVoicePlayback(voiceUrl),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _playingVoiceUrl == _resolveMediaUrl(voiceUrl) && _isVoicePlaying
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_fill_rounded,
                              size: 20,
                              color: Colors.black87,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Voice message',
                              style: _chatBubbleTextStyle,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isMe)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.black12,
                backgroundImage: _mainUserProfileUrl != null
                    ? NetworkImage(_mainUserProfileUrl!)
                    : null,
                onBackgroundImageError: _mainUserProfileUrl != null
                    ? (_, __) {
                        if (!mounted) {
                          return;
                        }
                        setState(() {
                          _mainUserProfileUrl = null;
                        });
                      }
                    : null,
                child: _mainUserProfileUrl == null
                    ? const Icon(Icons.person, color: Colors.black54, size: 18)
                    : null,
              ),
            )
          else if (isFromAI)
            const SizedBox(width: 2),
        ],
      ),
    );
  }

  Widget _buildMessageWithRecommendations(Map<String, dynamic> msg) {
    final messageWidget = _buildMessage(msg);
    final isFromAI = msg['isFromAI'] == true;
    final ids = (msg['recommendedUserIds'] as List<dynamic>? ?? const <dynamic>[])
        .map((value) => value is int ? value : int.tryParse(value.toString()))
        .whereType<int>()
        .toList();

    if (!isFromAI || ids.isEmpty) {
      return messageWidget;
    }

    final cards = <Widget>[];
    for (final userId in ids) {
      final profile = _recommendedProfiles[userId];
      if (profile != null) {
        cards.add(Padding(
          padding: const EdgeInsets.only(left: 36, top: 6, bottom: 8),
          child: _buildRecommendedProfileCard(profile),
        ));
      }
    }

    if (cards.isEmpty) {
      return messageWidget;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        messageWidget,
        ...cards,
      ],
    );
  }

  Widget _buildRecommendedProfileCard(Map<String, dynamic> profile) {
    final userId = profile['id'] is int ? profile['id'] as int : int.tryParse('${profile['id']}') ?? 0;
    final name = (profile['name'] ?? '').toString();
    final location = (profile['location'] ?? '').toString();
    final level = profile['level'] is int ? profile['level'] as int : int.tryParse('${profile['level']}') ?? 1;
    final profileUrl = _resolveProfileUrl(profile['profilepicture']);
    final isSubmitting = _submittingFriendRequests.contains(userId);

    return Container(
      width: 230,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFECECEC),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 0.78,
              child: profileUrl != null
                  ? Image.network(
                      profileUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade300,
                        alignment: Alignment.center,
                        child: const Icon(Icons.person, size: 42, color: Colors.black45),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade300,
                      alignment: Alignment.center,
                      child: const Icon(Icons.person, size: 42, color: Colors.black45),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black54, blurRadius: 3)],
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Level $level${location.isNotEmpty ? ' • $location' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 26,
            child: ElevatedButton(
              onPressed: userId <= 0 || isSubmitting ? null : () => _sendFriendRequestToUser(userId),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF00A0D8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('TAMBAH'),
            ),
          ),
        ],
      ),
    );
  }

}

class _AiTypingIndicator extends StatefulWidget {
  const _AiTypingIndicator();

  @override
  State<_AiTypingIndicator> createState() => _AiTypingIndicatorState();
}

class _AiTypingIndicatorState extends State<_AiTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _dotScale(int index) {
    final phase = (_controller.value + (index * 0.2)) % 1.0;
    final intensity = phase < 0.5 ? phase / 0.5 : (1 - phase) / 0.5;
    return 0.78 + (0.35 * intensity.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Padding(
              padding: EdgeInsets.only(right: index == 2 ? 0 : 4),
              child: Transform.scale(
                scale: _dotScale(index),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
