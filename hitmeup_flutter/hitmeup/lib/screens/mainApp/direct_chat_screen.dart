import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../../theme/app_theme.dart';
import 'chat_models.dart';
import 'ai_chat_screen.dart';
import '../../services/chat_service.dart';
import '../../services/auth_session.dart';

class DirectChatScreen extends StatefulWidget {
  final DirectChat chat;
  const DirectChatScreen({super.key, required this.chat});

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  static const int _messagePageSize = 20;
  static const double _topLoadThreshold = 120.0;
  static const String _galleryPermissionMessage =
      'Please allow gallery access so you can choose an image to send.';
  static const String _microphonePermissionMessage =
      'Please allow microphone access so you can record voice messages.';

  static const TextStyle _chatNameTextStyle = TextStyle(
    fontFamily: 'Konkhmer Sleokchher',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 0,
    color: Colors.black,
  );

  static const TextStyle _chatMessageTextStyle = TextStyle(
    fontFamily: 'IBM Plex Sans Devanagari',
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 0,
    color: Colors.black87,
  );

  static const TextStyle _chatAiTitleTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 0,
    color: Colors.white,
  );

  static const TextStyle _chatAiSubtitleTextStyle = TextStyle(
    fontFamily: 'Konkhmer Sleokchher',
    fontSize: 9,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 0,
    color: Colors.white70,
  );

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _showAttachMenu = false;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isPickingImage = false;
  bool _isCreatingPoll = false;
  bool _isVotingPoll = false;
  bool _isLoadingMoreMessages = false;
  bool _hasMoreOlderMessages = true;
  bool _isRecordingVoice = false;
  bool _isSendingVoice = false;
  Duration _voiceRecordDuration = Duration.zero;
  Timer? _voiceRecordTimer;
  String? _playingVoiceUrl;
  bool _isVoicePlaying = false;
  final ImagePicker _imagePicker = ImagePicker();
  Timer? _messagePollingTimer;

  String get _chatAvatarUrl {
    final value = (widget.chat.avatarUrl ?? '').trim();
    if (value.isEmpty) {
      return 'assets/FallBackProfile.png';
    }
    return value;
  }

  bool get _chatAvatarIsAsset => _chatAvatarUrl.startsWith('assets/');

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
    _loadMessages();
    _startMessagePolling();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _voiceRecordTimer?.cancel();
    _messagePollingTimer?.cancel();
    unawaited(_audioRecorder.cancel());
    unawaited(_audioRecorder.dispose());
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

  Future<void> _loadMessages() async {
    try {
      final messages = await ChatService.fetchMessages(
        widget.chat.id,
        limit: _messagePageSize,
      );
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
          _hasMoreOlderMessages = messages.length == _messagePageSize;
        });
        _scrollToBottomUntilStable();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $e')),
        );
      }
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_isLoading ||
        _isLoadingMoreMessages ||
        !_hasMoreOlderMessages ||
        _messages.isEmpty) {
      return;
    }

    final oldestMessageId = _messageIdFromMessage(_messages.first);
    if (oldestMessageId == null) {
      return;
    }

    final oldPixels = _scrollController.hasClients
        ? _scrollController.position.pixels
        : 0.0;
    final oldMaxScrollExtent = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0.0;

    setState(() {
      _isLoadingMoreMessages = true;
    });

    try {
      final olderMessages = await ChatService.fetchMessages(
        widget.chat.id,
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
        _scrollController.jumpTo(targetOffset.clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        ));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading older messages: $e')),
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

  void _startMessagePolling() {
    _messagePollingTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (mounted && !_isLoading) {
        _pollForNewMessages();
      }
    });
  }

  Future<void> _pollForNewMessages() async {
    if (_messages.isEmpty) {
      return;
    }

    try {
      final lastMessage = _messages.last;
      final lastMessageId = _messageIdFromMessage(lastMessage);
      if (lastMessageId == null) {
        return;
      }

      final newMessages = await ChatService.fetchMessages(
        widget.chat.id,
        limit: _messagePageSize,
        afterId: lastMessageId,
      );

      if (!mounted || newMessages.isEmpty) {
        return;
      }

      setState(() {
        _messages.addAll(newMessages);
      });
      _scrollToBottom();
    } catch (_) {
      // Silently ignore polling errors
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final userId = AuthSession.instance.userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not logged in')),
      );
      return;
    }

    _controller.clear();
    setState(() => _isSending = true);

    try {
      final message = await ChatService.sendMessage(
        chatId: widget.chat.id,
        senderId: userId,
        text: text,
      );

      if (mounted) {
        setState(() {
          _messages.add(message);
          _isSending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  Future<void> _pickAndSendGalleryImage() async {
    if (_isPickingImage) {
      return;
    }

    if (_showAttachMenu) {
      setState(() {
        _showAttachMenu = false;
      });
    }

    try {
      final hasPermission = await _ensureGalleryPermission();
      if (!hasPermission || !mounted) {
        return;
      }

      if (mounted) {
        setState(() {
          _isPickingImage = true;
        });
      }

      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1440,
      );

      if (pickedFile == null || !mounted) {
        return;
      }

      final userId = AuthSession.instance.userId;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not logged in')),
        );
        return;
      }

      final imageBytes = await pickedFile.readAsBytes();
      final sentMessage = await ChatService.sendImageMessage(
        chatId: widget.chat.id,
        senderId: userId,
        imageBytes: imageBytes,
        fileName: pickedFile.name,
      );

      if (mounted) {
        setState(() {
          _messages.add(sentMessage);
        });
        _scrollToBottomWithSettling();
      }
    } on MissingPluginException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image picker is not available yet.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  Future<void> _pickAndSendCameraImage() async {
    if (_isPickingImage) {
      return;
    }

    if (_showAttachMenu) {
      setState(() {
        _showAttachMenu = false;
      });
    }

    try {
      if (mounted) {
        setState(() {
          _isPickingImage = true;
        });
      }

      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1440,
      );

      if (pickedFile == null || !mounted) {
        return;
      }

      final userId = AuthSession.instance.userId;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not logged in')),
        );
        return;
      }

      final imageBytes = await pickedFile.readAsBytes();
      final sentMessage = await ChatService.sendImageMessage(
        chatId: widget.chat.id,
        senderId: userId,
        imageBytes: imageBytes,
        fileName: pickedFile.name,
      );

      if (mounted) {
        setState(() {
          _messages.add(sentMessage);
        });
        _scrollToBottomWithSettling();
      }
    } on MissingPluginException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera is not available yet.')),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Camera permission or access issue: ${e.message ?? e.code}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending camera image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  Future<void> _showCreatePollDialog() async {
    if (_isCreatingPoll) {
      return;
    }

    if (_showAttachMenu) {
      setState(() {
        _showAttachMenu = false;
      });
    }

    final questionController = TextEditingController();
    final optionControllers = [
      TextEditingController(),
      TextEditingController(),
    ];
    String? validationMessage;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create Poll',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: questionController,
                        decoration: InputDecoration(
                          hintText: 'Poll question...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...List.generate(optionControllers.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextField(
                            controller: optionControllers[index],
                            decoration: InputDecoration(
                              hintText: 'Option ${index + 1}',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                        );
                      }),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: optionControllers.length >= 6
                                ? null
                                : () {
                                    setDialogState(() {
                                      optionControllers.add(
                                        TextEditingController(),
                                      );
                                    });
                                  },
                            icon: const Icon(Icons.add),
                            label: const Text('Add option'),
                          ),
                        ],
                      ),
                      if (validationMessage != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          validationMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.pinkTop,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            final question = questionController.text.trim();
                            final options = optionControllers
                                .map((controller) => controller.text.trim())
                                .where((value) => value.isNotEmpty)
                                .toList();

                            if (question.isEmpty) {
                              setDialogState(() {
                                validationMessage = 'Please enter a poll question.';
                              });
                              return;
                            }

                            if (options.length < 2) {
                              setDialogState(() {
                                validationMessage = 'Please provide at least 2 options.';
                              });
                              return;
                            }

                            Navigator.of(dialogContext).pop({
                              'question': question,
                              'options': options,
                            });
                          },
                          child: const Text(
                            'Create',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    final question = (result['question'] as String?)?.trim() ?? '';
    final options = (result['options'] as List<dynamic>? ?? const <dynamic>[])
        .map((value) => value.toString().trim())
        .where((value) => value.isNotEmpty)
        .toList();

    await _sendPollMessage(question: question, options: options);
  }

  Future<void> _sendPollMessage({
    required String question,
    required List<String> options,
  }) async {
    if (_isCreatingPoll) {
      return;
    }

    final userId = AuthSession.instance.userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not logged in')),
      );
      return;
    }

    final pendingId = 'pending_poll_${DateTime.now().microsecondsSinceEpoch}';
    final pendingMessage = {
      'id': pendingId,
      'chat': widget.chat.id,
      'sender': userId,
      'text': '',
      'image': null,
      'poll': null,
      'hasPoll': true,
      'created_at': DateTime.now().toIso8601String(),
      'localType': 'pollLoading',
    };

    setState(() {
      _isCreatingPoll = true;
      _messages.add(pendingMessage);
    });
    _scrollToBottom(animated: false);

    try {
      final createdMessage = await ChatService.sendPollMessage(
        chatId: widget.chat.id,
        senderId: userId,
        pollQuestion: question,
        pollOptions: options,
      );

      if (mounted) {
        setState(() {
          final pendingIndex = _messages.indexWhere((message) => message['id'] == pendingId);
          if (pendingIndex != -1) {
            _messages[pendingIndex] = createdMessage;
          } else {
            _messages.add(createdMessage);
          }
        });
        _scrollToBottom(animated: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.removeWhere((message) => message['id'] == pendingId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending poll: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingPoll = false;
        });
      }
    }
  }

  Future<void> _voteOnPoll({
    required int messageId,
    required int optionId,
  }) async {
    if (_isVotingPoll) {
      return;
    }

    final voterId = AuthSession.instance.userId;
    if (voterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not logged in')),
      );
      return;
    }

    setState(() {
      _isVotingPoll = true;
    });

    try {
      await ChatService.sendPollVote(
        optionId: optionId,
        voterId: voterId,
      );

      final updatedMessage = await ChatService.fetchMessageById(messageId);

      if (!mounted) {
        return;
      }

      setState(() {
        final messageIndex = _messages.indexWhere((message) {
          final id = message['id'] is int
              ? message['id'] as int
              : int.tryParse(message['id'].toString());
          return id == messageId;
        });

        if (messageIndex != -1) {
          _messages[messageIndex] = updatedMessage;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error voting on poll: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVotingPoll = false;
        });
      }
    }
  }

  Future<bool> _ensureGalleryPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      var photosStatus = await Permission.photos.status;
      if (photosStatus.isGranted || photosStatus.isLimited) {
        return true;
      }
      if (photosStatus.isDenied || photosStatus.isRestricted) {
        photosStatus = await Permission.photos.request();
      }
      if (photosStatus.isGranted || photosStatus.isLimited) {
        return true;
      }

      var storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) {
        return true;
      }
      if (storageStatus.isDenied || storageStatus.isRestricted) {
        storageStatus = await Permission.storage.request();
      }
      if (storageStatus.isGranted) {
        return true;
      }

      return _showGalleryPermissionSettingsDialog();
    }

    var status = await Permission.photos.status;
    if (status.isGranted || status.isLimited) {
      return true;
    }
    if (status.isDenied || status.isRestricted) {
      status = await Permission.photos.request();
    }
    if (status.isGranted || status.isLimited) {
      return true;
    }

    return _showGalleryPermissionSettingsDialog();
  }

  Future<bool> _showGalleryPermissionSettingsDialog() async {
    final shouldOpenSettings = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Gallery Permission Needed'),
          content: const Text(_galleryPermissionMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );

    if (shouldOpenSettings == true) {
      try {
        await openAppSettings();
      } on MissingPluginException {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Open Settings is unavailable right now. Please fully restart the app and try again.',
              ),
            ),
          );
        }
      }
    }

    return false;
  }

  Future<bool> _ensureMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (status.isGranted) {
      return true;
    }
    if (status.isDenied || status.isRestricted) {
      status = await Permission.microphone.request();
    }
    if (status.isGranted) {
      return true;
    }

    return _showMicrophonePermissionSettingsDialog();
  }

  Future<bool> _showMicrophonePermissionSettingsDialog() async {
    final shouldOpenSettings = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Microphone Permission Needed'),
          content: const Text(_microphonePermissionMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );

    if (shouldOpenSettings == true) {
      try {
        await openAppSettings();
      } on MissingPluginException {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Open Settings is unavailable right now. Please fully restart the app and try again.',
              ),
            ),
          );
        }
      }
    }

    return false;
  }

  Future<void> _startVoiceRecording() async {
    if (_isRecordingVoice || _isSendingVoice || _isSending) {
      return;
    }

    FocusScope.of(context).unfocus();

    final hasPermission = await _ensureMicrophonePermission();
    if (!hasPermission || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Microphone permission is required to record voice messages.',
            ),
          ),
        );
      }
      return;
    }

    final canRecord = await _audioRecorder.hasPermission();
    if (!canRecord || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Unable to access microphone on this device right now.'),
          ),
        );
      }
      return;
    }

    if (_showAttachMenu) {
      setState(() {
        _showAttachMenu = false;
      });
    }

    try {
      final recordingPath =
          '${Directory.systemTemp.path}${Platform.pathSeparator}voice_${DateTime.now().microsecondsSinceEpoch}.m4a';
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: recordingPath,
      );

      _voiceRecordTimer?.cancel();
      setState(() {
        _isRecordingVoice = true;
        _voiceRecordDuration = Duration.zero;
      });

      _voiceRecordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || !_isRecordingVoice) {
          return;
        }
        setState(() {
          _voiceRecordDuration += const Duration(seconds: 1);
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to start recording: $e')),
        );
      }
    }
  }

  Future<void> _deleteVoiceRecording() async {
    try {
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.cancel();
      }
    } catch (_) {
      // Best effort cleanup.
    }

    _voiceRecordTimer?.cancel();
    if (mounted) {
      setState(() {
        _isRecordingVoice = false;
        _isSendingVoice = false;
        _voiceRecordDuration = Duration.zero;
      });
    }
  }

  Future<void> _sendVoiceRecording() async {
    if (!_isRecordingVoice || _isSendingVoice) {
      return;
    }

    final userId = AuthSession.instance.userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not logged in')),
      );
      return;
    }

    setState(() {
      _isSendingVoice = true;
    });

    try {
      final path = await _audioRecorder.stop();
      _voiceRecordTimer?.cancel();

      if (path == null || path.isEmpty) {
        throw Exception('No recording captured.');
      }

      final audioBytes = await File(path).readAsBytes();
      final fileName = path.split(Platform.pathSeparator).last;

      final sentMessage = await ChatService.sendVoiceMessage(
        chatId: widget.chat.id,
        senderId: userId,
        audioBytes: audioBytes,
        fileName: fileName,
      );

      if (mounted) {
        setState(() {
          _messages.add(sentMessage);
          _isRecordingVoice = false;
          _isSendingVoice = false;
          _voiceRecordDuration = Duration.zero;
        });
        _scrollToBottomWithSettling();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRecordingVoice = false;
          _isSendingVoice = false;
          _voiceRecordDuration = Duration.zero;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending voice message: $e')),
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
          const SnackBar(
            content:
                Text('Voice playback timed out. Please try again.'),
          ),
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
          duration: const Duration(milliseconds: 220),
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

  Map<String, dynamic> _toDisplayMessage(Map<String, dynamic> msg) {
    final userId = AuthSession.instance.userId;
    final senderId = msg['sender'] is int
        ? msg['sender']
        : int.tryParse(msg['sender'].toString()) ?? 0;
    final isMe = senderId == userId;

    final poll = msg['poll'] is Map<String, dynamic>
        ? msg['poll'] as Map<String, dynamic>
        : null;
    final hasPoll = msg['hasPoll'] == true || poll != null;
    final localType = msg['localType']?.toString();

    return {
      'id': msg['id'],
      'chatId': msg['chat'],
      'senderId': senderId,
      'text': msg['text'] ?? '',
      'image': msg['image'] as String?,
      'voiceRecording': msg['voiceRecording'] as String?,
      'poll': poll,
      'isMe': isMe,
      'time': _formatTime(msg['created_at'] ?? ''),
      'sender': widget.chat.name,
      'type': localType ?? (hasPoll ? 'poll' : 'text'),
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
    } catch (e) {
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
                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(),
                      )
                    else
                      ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final rawMessage = _messages[index];
                          return _buildMessage(_toDisplayMessage(rawMessage));
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
                    // Chat.AI banner
                    GestureDetector(
                      onTap: () {
                        final currentUserId = AuthSession.instance.userId;
                        if (currentUserId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Not logged in')),
                          );
                          return;
                        }

                        final contextUserId = widget.chat.user1 == currentUserId
                            ? widget.chat.user2
                            : widget.chat.user1;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AiChatScreen(
                              contextUserId: contextUserId,
                              contextTitle: widget.chat.name,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        height: 64,
                        margin:
                            const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.blueBottom,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/AIBrain.png',
                              width: 28,
                              height: 28,
                              fit: BoxFit.contain,
                              color: Colors.white,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.psychology_rounded,
                                  color: Colors.white,
                                  size: 28),
                            ),
                            const SizedBox(width: 12),
                            Container(
                                width: 1,
                                height: 40,
                                color: Colors.white),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Ask help to Chat.AI',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                Text(
                                  'ask AI to help you with itinerary or others...',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white70),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Input bar
                    Container(
                      color: Colors.transparent,
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 4,
                        bottom:
                            MediaQuery.of(context).padding.bottom + 8,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(28),
                          border:
                              Border.all(color: Colors.grey.shade300),
                        ),
                        child: _isRecordingVoice
                            ? _buildVoiceRecorderBar()
                            : _buildTextInputBar(),
                      ),
                    ),
                  ],
                ),

                if (_showAttachMenu && !_isRecordingVoice)
                  Positioned(
                    bottom: 60 +
                        MediaQuery.of(context).padding.bottom,
                    left: 16,
                    child: AnimatedOpacity(
                      opacity: 1.0,
                      duration:
                          const Duration(milliseconds: 250),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF448AFF),
                              Colors.white,
                              Color(0xFFFF4081)
                            ],
                            stops: [0.0, 0.5, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                                color:
                                    Colors.black.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                          _buildAttachItem(
                            'assets/galleryIcon.png',
                            'Gallery',
                            onTap: _pickAndSendGalleryImage),
                            const SizedBox(height: 6),
                          _buildAttachItem(
                            'assets/cameraIcon.png',
                            'Camera',
                            onTap: _pickAndSendCameraImage),
                            const SizedBox(height: 6),
                          _buildAttachItem(
                            'assets/pollsIcon.png',
                            'Poll',
                            onTap: _showCreatePollDialog),
                          ],
                        ),
                      ),
                    ),
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
          bottom: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 25, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          CircleAvatar(
            radius: 28,
            backgroundColor:
                AppColors.pinkTop.withOpacity(0.2),
            child: ClipOval(
              child: SizedBox(
                width: 56,
                height: 56,
                child: _chatAvatarIsAsset
                    ? Image.asset(
                        _chatAvatarUrl,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        _chatAvatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/FallBackProfile.png',
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(widget.chat.name,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildTextInputBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() => _showAttachMenu = !_showAttachMenu),
          child: AnimatedRotation(
            turns: _showAttachMenu ? 0.125 : 0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: const Icon(Icons.add, size: 20, color: Colors.black),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Message',
              hintStyle: TextStyle(color: Colors.black38),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          height: 36,
          child: IconButton(
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            tooltip: 'Record voice message',
            onPressed: _startVoiceRecording,
            icon: const Icon(Icons.mic, color: Colors.black, size: 24),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _isSending ? null : _sendMessage,
          child: _isSending
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Image.asset(
                  'assets/sendMessage.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.arrow_upward,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildVoiceRecorderBar() {
    return Row(
      children: [
        const Icon(Icons.graphic_eq, color: Colors.redAccent, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Recording ${_formatDuration(_voiceRecordDuration)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        IconButton(
          onPressed: _isSendingVoice ? null : _deleteVoiceRecording,
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          tooltip: 'Delete recording',
        ),
        _isSendingVoice
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                onPressed: _sendVoiceRecording,
                icon: const Icon(Icons.send_rounded, color: Colors.black),
                tooltip: 'Send voice message',
              ),
      ],
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final isMe = msg['isMe'] as bool;
    final sender = msg['sender'] as String? ?? '';
    final text = msg['text'] as String;
    final time = msg['time'] as String;
    final imageUrl = msg['image'] as String?;
    final voiceUrl = msg['voiceRecording'] as String?;
    final type = msg['type'] as String? ?? 'text';

    if (type == 'pollLoading') {
      return _buildPollLoadingMessage(msg);
    }

    if (type == 'poll' && msg['poll'] is Map<String, dynamic>) {
      return _buildPollMessage(msg);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth:
                      MediaQuery.of(context).size.width * 0.65),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? const Color(0xFF73A4F5)
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft:
                      Radius.circular(isMe ? 16 : 4),
                  bottomRight:
                      Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  if (!isMe && sender.isNotEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: 4),
                      child: Text(sender,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                    ),
                  if (imageUrl != null && imageUrl.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 180,
                          height: 180,
                          color: Colors.grey.shade300,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image_rounded,
                            color: Colors.black45,
                          ),
                        ),
                      ),
                    ),
                    if (text.isNotEmpty) const SizedBox(height: 8),
                  ],
                  if (voiceUrl != null && voiceUrl.isNotEmpty) ...[
                    Container(
                      constraints: const BoxConstraints(minWidth: 170),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.white.withOpacity(0.16) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => _toggleVoicePlayback(voiceUrl),
                            child: Icon(
                              (_playingVoiceUrl == _resolveMediaUrl(voiceUrl) && _isVoicePlaying)
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_fill_rounded,
                              size: 28,
                              color: isMe ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Voice message',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isMe ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: 13,
                          color: isMe ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (voiceUrl == null || voiceUrl.isEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment:
                          CrossAxisAlignment.end,
                      children: [
                        if (text.isNotEmpty)
                          Flexible(
                            child: Text(
                              text,
                              style: TextStyle(
                                fontSize: 13,
                                color: isMe ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        if (text.isNotEmpty) const SizedBox(width: 8),
                        Text(time,
                            style: TextStyle(
                                fontSize: 10,
                                color: isMe
                                    ? Colors.white70
                                    : Colors.black45)),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollLoadingMessage(Map<String, dynamic> msg) {
    final isMe = msg['isMe'] as bool;
    final sender = msg['sender'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                color: const Color(0xFF73A4F5),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe && sender.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        sender,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Creating poll...',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollProgressBar(double progress) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: double.infinity,
        child: Container(
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF2859C5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: clampedProgress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
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
    );
  }

  Future<void> _showPollVotesDialog(Map<String, dynamic> poll) async {
    final options = (poll['options'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(dialogContext).size.height * 0.7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Poll votes',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: options.map((option) {
                        final optionName = (option['optionName'] as String?)?.trim() ?? 'Option';
                        final voteCount = option['voteCount'] is int
                            ? option['voteCount'] as int
                            : int.tryParse(option['voteCount'].toString()) ?? 0;
                        final votes = (option['votes'] as List<dynamic>? ?? const <dynamic>[])
                            .whereType<Map<String, dynamic>>()
                            .toList();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      optionName,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Text(
                                    '$voteCount',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (votes.isEmpty)
                                const Text(
                                  'No votes yet',
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                )
                              else
                                Column(
                                  children: votes.map((vote) {
                                    final voterName = (vote['voterName'] as String?)?.trim();
                                    final voterProfile = (vote['voterProfile'] as String?)?.trim();

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 15,
                                            backgroundColor: Colors.grey.shade200,
                                            backgroundImage: voterProfile != null && voterProfile.isNotEmpty
                                                ? NetworkImage(_resolveMediaUrl(voterProfile))
                                                : null,
                                            child: (voterProfile == null || voterProfile.isEmpty)
                                                ? const Icon(Icons.person, size: 16, color: Colors.black54)
                                                : null,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              (voterName == null || voterName.isEmpty) ? 'Unknown user' : voterName,
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPollMessage(Map<String, dynamic> msg) {
    final isMe = msg['isMe'] as bool;
    final sender = msg['sender'] as String? ?? '';
    final time = msg['time'] as String;
    final poll = msg['poll'] as Map<String, dynamic>;
    final messageId = msg['id'] is int
        ? msg['id'] as int
        : int.tryParse(msg['id'].toString()) ?? -1;
    final currentUserId = AuthSession.instance.userId;

    final question = (poll['question'] as String?)?.trim() ?? 'Poll';
    final options = (poll['options'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();

    int? selectedOptionId;
    for (final option in options) {
      final votes = option['votes'] as List<dynamic>? ?? const <dynamic>[];
      for (final vote in votes) {
        if (vote is Map<String, dynamic>) {
          final voterId = vote['voter'] is int
              ? vote['voter'] as int
              : int.tryParse(vote['voter'].toString());
          final optionId = option['id'] is int
              ? option['id'] as int
              : int.tryParse(option['id'].toString());
          if (currentUserId != null && voterId == currentUserId && optionId != null) {
            selectedOptionId = optionId;
            break;
          }
        }
      }
      if (selectedOptionId != null) {
        break;
      }
    }

    final hasVoted = selectedOptionId != null;
    final totalVotes = options.fold<int>(
      0,
      (sum, option) =>
          sum +
          (option['voteCount'] is int
              ? option['voteCount'] as int
              : int.tryParse(option['voteCount'].toString()) ?? 0),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF73A4F5) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe && sender.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        sender,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  Text(
                    question,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...options.map((option) {
                    final optionId = option['id'] is int
                        ? option['id'] as int
                        : int.tryParse(option['id'].toString()) ?? -1;
                    final optionName =
                        (option['optionName'] as String?)?.trim() ??
                            'Option';
                    final voteCount = option['voteCount'] is int
                        ? option['voteCount'] as int
                        : int.tryParse(option['voteCount'].toString()) ?? 0;
                    final isSelected = selectedOptionId == optionId;
                    final progress =
                        totalVotes == 0 ? 0.0 : voteCount / totalVotes;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: GestureDetector(
                        onTap: hasVoted || _isVotingPoll
                            ? null
                            : () {
                                if (messageId < 0 || optionId < 0) {
                                  return;
                                }
                                _voteOnPoll(
                                    messageId: messageId, optionId: optionId);
                              },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    isSelected ? Colors.black : Colors.transparent,
                                border: Border.all(
                                  color: Colors.black,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          optionName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      if (hasVoted)
                                        Text(
                                          '$voteCount',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (hasVoted) ...[
                                    const SizedBox(height: 6),
                                    _buildPollProgressBar(progress),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          time,
                          style: const TextStyle(fontSize: 10, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  if (hasVoted) ...[
                    const SizedBox(height: 6),
                    Container(height: 2, color: Colors.white),
                    TextButton(
                        onPressed: () => _showPollVotesDialog(poll),
                      child: const Center(
                        child: Text(
                          'View votes',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachItem(
    String imageAssetPath,
    String label, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 99,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 8),
            Image.asset(
              imageAssetPath,
              width: 13,
              height: 13,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}