import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'chat_models.dart';
import 'ai_chat_screen.dart';

class CommunityChatScreen extends StatefulWidget {
  final Community community;
  const CommunityChatScreen({super.key, required this.community});

  @override
  State<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showAttachMenu = false;
  int? _selectedPollOption;
  bool _hasVoted = false;

  final List<Map<String, dynamic>> _messages = [
    {'text': 'Malam ini mau mabar ga?', 'isMe': false, 'sender': 'Rosia morens', 'time': '16:07'},
    {'text': 'wii boleh tu, ayoo', 'isMe': false, 'sender': 'Petra', 'time': '16:10'},
    {'text': 'enaknya jam berapa ya?', 'isMe': false, 'sender': 'Kiranti', 'time': '16:18'},
    {'text': 'Jam 21.00, bagaimana?', 'isMe': true, 'sender': '', 'time': '16:26'},
    {'text': 'Bolehhh tu', 'isMe': false, 'sender': 'Rosia morens', 'time': '16:28'},
    {'isPoll': true, 'time': '16:30'},
    {'text': 'Gass ramaikan!!', 'isMe': true, 'sender': '', 'time': '16:31'},
    {'text': 'Iya nih sudah lama tidak mabar', 'isMe': false, 'sender': 'Vania kursel', 'time': '17:00'},
    {'text': 'Maaf ya teman - teman tidak bisa ikut dulu', 'isMe': false, 'sender': 'Yuqi nako', 'time': '18:10'},
  ];

  final List<String> _pollOptions = ['Ayoo mabar!!', 'Maaf lagi gabisa'];
  final List<int> _pollVotes = [24, 7];

  // rgba(115, 164, 245, 1)
  static const Color _bubbleBlue = Color(0xFF73A4F5);

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
                    ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) {
                        final msg = _messages[i];
                        if (msg['isPoll'] == true) return _buildPollBubble();
                        return _buildMessage(msg);
                      },
                    ),
                  ],
                ),
              ),
            ),
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
                                  GestureDetector(
                                    onTap: () {
                                      setState(() => _showAttachMenu = false);
                                      _showCreatePollDialog(context);
                                    },
                                    child: _buildAttachItem(Icons.align_horizontal_left_rounded, 'Poll'),
                                  ),
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
            backgroundImage: widget.community.imageUrl != null ? NetworkImage(widget.community.imageUrl!) : null,
            backgroundColor: AppColors.pinkTop.withOpacity(0.2),
            child: widget.community.imageUrl == null ? const Icon(Icons.people_rounded, color: AppColors.pinkTop) : null,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.community.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
              Text('${widget.community.participants} Participants', style: const TextStyle(fontSize: 11, color: Colors.black54)),
            ],
          ),
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
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? _bubbleBlue : Colors.white,
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
                      child: Text(
                        sender,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: 13,
                            color: isMe ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
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

  Widget _buildProgressBar(double progress) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 14,
        decoration: BoxDecoration(
          color: const Color(0xFF2859C5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: clampedProgress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollBubble() {
    final totalVotes = _pollVotes.reduce((a, b) => a + b);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: _bubbleBlue,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Yang ikut malem ini mabar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 4),
            Text(
              '$totalVotes votes',
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
            const SizedBox(height: 14),
            ...List.generate(_pollOptions.length, (i) {
              final isSelected = _selectedPollOption == i;
              final voteCount = _hasVoted ? _pollVotes[i] : 0;
              final optionVotes = _pollVotes[i];
              final progress = totalVotes == 0 ? 0.0 : optionVotes / totalVotes;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: GestureDetector(
                  onTap: () {
                    if (!_hasVoted) {
                      setState(() {
                        _selectedPollOption = i;
                        _pollVotes[i]++;
                        _hasVoted = true;
                      });
                    }
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.black : Colors.transparent,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
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
                                    _pollOptions[i],
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                                  ),
                                ),
                                if (_hasVoted) ...[
                                  SizedBox(
                                    width: 36, height: 20,
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: 0,
                                          child: CircleAvatar(
                                            radius: 10,
                                            backgroundImage: NetworkImage(
                                              i == 0 ? 'https://i.pravatar.cc/40?img=44' : 'https://i.pravatar.cc/40?img=13',
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 14,
                                          child: CircleAvatar(
                                            radius: 10,
                                            backgroundImage: NetworkImage(
                                              i == 0 ? 'https://i.pravatar.cc/40?img=11' : 'https://i.pravatar.cc/40?img=24',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$voteCount',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            _buildProgressBar(progress),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('16:30', style: TextStyle(fontSize: 10, color: Colors.black54)),
                  SizedBox(width: 4),
                  Icon(Icons.done_all, size: 12, color: Colors.black54),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Container(height: 2, color: Colors.white),
            TextButton(
              onPressed: () {},
              child: const Center(
                child: Text(
                  'View votes',
                  style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePollDialog(BuildContext context) {
    final questionController = TextEditingController();
    final option1Controller = TextEditingController();
    final option2Controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Buat Poll', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: questionController,
                decoration: InputDecoration(
                  hintText: 'Pertanyaan poll...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: option1Controller,
                decoration: InputDecoration(
                  hintText: 'Opsi 1',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: option2Controller,
                decoration: InputDecoration(
                  hintText: 'Opsi 2',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pinkTop,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _messages.add({'isPoll': true, 'time': '16:35'}));
                  },
                  child: const Text('Buat Poll', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
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