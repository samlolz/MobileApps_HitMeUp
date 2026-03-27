import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showAttachMenu = false;

  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Hi AI, boleh tolong rekomendasikan saya outlet matcha yang enak dengan range harga 40K - 80K di sekitar blok m?',
      'isMe': true,
    },
    {
      'text': 'Tentu saja! Saya akan buatkan opsi untuk kamu memilih outlet matcha yang enak dengan range harga 40K - 80K di daerah blok m:',
      'isMe': false,
      'hasPlaces': true,
    },
    {'text': 'terimakasih, sangat membantu!', 'isMe': true},
    {'text': 'Dan juga, bantu aku cari kegiatan bareng siti untuk sehabis minum matcha!', 'isMe': true},
    {
      'text': 'Berdasarkan genre film kesukaan kalian yaitu horror, berikut rekomendasi film horror yang sedang tayang di bioskop daerah Blok M',
      'isMe': false,
      'hasMovies': true,
    },
  ];

  final List<Map<String, String>> _places = [
    {'name': 'MATCHAMAN', 'type': 'Kedai Teh', 'address': 'Blok M, Kota Jakarta Selatan', 'review': '"Rasanya mirip senye literatur!"', 'image': 'https://i.pravatar.cc/60?img=1'},
    {'name': 'MADMATCHA', 'type': 'Kedai Kopi', 'address': 'Blok M, Kota Jakarta Selatan', 'review': '"Enak, tapi porsinya kurang"', 'image': 'https://i.pravatar.cc/60?img=2'},
    {'name': 'MATTEA SOCIAL SPACE', 'type': 'Kedai Kopi', 'address': 'Blok M, Kota Jakarta Selatan', 'review': '"Sukai semua menu"', 'image': 'https://i.pravatar.cc/60?img=3'},
  ];

  final List<Map<String, String>> _movies = [
    {'title': 'WHISTLE', 'genre': 'Horror', 'image': 'https://image.tmdb.org/t/p/w200/1E5baAaEse26fej7uHcjOgEE2t2.jpg'},
    {'title': 'KAFIR, GERBANG SUKMA', 'genre': 'Horror', 'image': 'https://image.tmdb.org/t/p/w200/qNBAXBIQlnOThrVvA6mA2B5ggV6.jpg'},
    {'title': 'LIFT', 'genre': 'Horror', 'image': 'https://image.tmdb.org/t/p/w200/rzdPqYx7Um4FUZeD8wpXqjAUcEr.jpg'},
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
                              hintText: 'Mau nanya apa nih ....',
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
          Image.asset(
            'assets/AIBrain.png',
            width: 28, height: 28,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.psychology_rounded, size: 28, color: Colors.black),
          ),
          const SizedBox(width: 8),
          const Text(
            'Chat.AI',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const Spacer(),
          const CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final isMe = msg['isMe'] as bool;
    final hasPlaces = msg['hasPlaces'] as bool? ?? false;
    final hasMovies = msg['hasMovies'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            Image.asset(
              'assets/AIBrain.png',
              width: 28, height: 28,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.psychology_rounded, size: 28, color: Colors.black54),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(msg['text'], style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  if (hasPlaces) ...[const SizedBox(height: 12), _buildPlacesCard()],
                  if (hasMovies) ...[const SizedBox(height: 12), _buildMoviesCard()],
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlacesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          ..._places.map((place) => Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    place['image']!, width: 50, height: 50, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 50, height: 50,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.store, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place['name']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Row(children: [
                        ...List.generate(4, (_) => const Icon(Icons.star, size: 10, color: Colors.amber)),
                        const Icon(Icons.star_half, size: 10, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(place['type']!, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                      ]),
                      Text(place['address']!, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                      Text(place['review']!, style: const TextStyle(fontSize: 9, color: Colors.grey, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ],
            ),
          )),
          Container(
            height: 120,
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Icon(Icons.map_rounded, size: 48, color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildMoviesCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bioskop / BLOK M PLAZA:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _movies.map((movie) => Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  movie['image']!, width: 75, height: 110, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 75, height: 110,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.movie, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 75,
                child: Text(
                  movie['title']!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
              Text(movie['genre']!, style: const TextStyle(fontSize: 9, color: Colors.grey)),
            ],
          )).toList(),
        ),
      ],
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