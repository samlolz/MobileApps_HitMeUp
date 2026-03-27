import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'chat_models.dart';
import 'ai_chat_screen.dart';

class DirectChatScreen extends StatefulWidget {
  final DirectChat chat;
  const DirectChatScreen({super.key, required this.chat});

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showAttachMenu = false;

  final List<Map<String, dynamic>> _messages = [
    {'text': 'Hi, kamu suka minum matcha?', 'isMe': true, 'time': '15:59'},
    {'text': 'Ih matcha favorite aku bgt, kamu suka juga?', 'isMe': false, 'time': '16:00', 'sender': 'Siti Ratmawati'},
    {'text': 'Suka, karena aku suka after taste nya gitu loh ada pahit pahitnya', 'isMe': true, 'time': '16:25'},
    {'text': 'Aku tau beberapa outlet matcha yang enak bgt di Blok M, wanna hangout?', 'isMe': true, 'time': '16:25'},
    {'text': 'Boleh, gimana kalo misalnya sabtu aja? Aku lagi sibuk bgt ngurusin organisasi di kuliah nih', 'isMe': false, 'time': '16:26', 'sender': 'Siti Ratmawati'},
    {'text': 'Okaay, berhubung rumah kita deket nanti aku jemput aja yaa dirumah kamu! See ya', 'isMe': true, 'time': '16:26'},
    {'text': 'Baiklah, see you Alfraz', 'isMe': false, 'time': '16:26', 'sender': 'Siti Ratmawati'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    Positioned(
                      top: 0, left: 0, right: 0,
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
                    ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                      children: _messages.map((msg) => _buildMessage(msg)).toList(),
                    ),
                  ],
                ),
              ),
            ),
            // Chat.AI banner
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiChatScreen()),
              ),
              child: Container(
                width: double.infinity,
                height: 64,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4081),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/AIBrain.png',
                      width: 50, height: 50,
                      fit: BoxFit.contain,
                      color: Colors.white,
                      errorBuilder: (_, __, ___) => const Icon(Icons.psychology_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Container(width: 1, height: 40, color: Colors.white),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Ask help to Chat.AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('ask AI to help you with itinerary or others...', style: TextStyle(fontSize: 9, color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Input bar
            Container(
              color: Colors.white,
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 4,
                bottom: MediaQuery.of(context).padding.bottom + 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _showAttachMenu
                        ? AnimatedOpacity(
                            opacity: 1.0,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Color(0xFF448AFF), Colors.white, Color(0xFFFF4081)],
                                  stops: [0.0, 0.5, 1.0],
                                ),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildAttachItem(Icons.photo_library_rounded, 'Gallery'),
                                  const SizedBox(height: 6),
                                  _buildAttachItem(Icons.camera_alt_rounded, 'Camera'),
                                  const SizedBox(height: 6),
                                  _buildAttachItem(Icons.align_horizontal_left_rounded, 'Poll'),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _showAttachMenu = !_showAttachMenu),
                          child: AnimatedRotation(
                            turns: _showAttachMenu ? 0.125 : 0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2)),
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
                        const Icon(Icons.mic, color: Colors.black, size: 24),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_upward, color: Colors.black, size: 24),
                      ],
                    ),
                  ),
                ],
              ),
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
        left: 8, right: 16, bottom: 8,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          CircleAvatar(
            radius: 28,
            backgroundImage: widget.chat.avatarUrl != null ? NetworkImage(widget.chat.avatarUrl!) : null,
            backgroundColor: AppColors.pinkTop.withOpacity(0.2),
          ),
          const SizedBox(width: 12),
          Text(widget.chat.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final isMe = msg['isMe'] as bool;
    final sender = msg['sender'] as String? ?? '';
    final text = msg['text'] as String;
    final time = msg['time'] as String;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF73A4F5) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe && sender.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(sender, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(child: Text(text, style: TextStyle(fontSize: 13, color: isMe ? Colors.white : Colors.black87))),
                      const SizedBox(width: 8),
                      Text(time, style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.black45)),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.done_all, size: 12, color: Colors.white70),
                      ],
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

  Widget _buildAttachItem(IconData icon, String label) {
    return Container(
      width: 99, height: 24,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.pinkTop.withOpacity(0.4), width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(icon, size: 13, color: Colors.black87),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }
}