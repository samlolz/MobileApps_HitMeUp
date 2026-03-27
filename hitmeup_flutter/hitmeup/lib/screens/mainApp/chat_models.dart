class DirectChat {
  final String name;
  final String lastMessage;
  final String? avatarUrl;

  const DirectChat({
    required this.name,
    required this.lastMessage,
    this.avatarUrl,
  });
}

class Community {
  final String name;
  final int participants;
  final String? imageUrl;
  final bool isCreate;

  const Community({
    required this.name,
    required this.participants,
    this.imageUrl,
    this.isCreate = false,
  });
}