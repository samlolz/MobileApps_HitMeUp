
class DirectChat {
  final int id;
  final int user1;
  final int user2;
  final String name;
  final String lastMessage;
  final String? avatarUrl;
  final String? createdAt;
  final String? updatedAt;

  const DirectChat({
    required this.id,
    required this.user1,
    required this.user2,
    required this.name,
    required this.lastMessage,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory DirectChat.fromJson(Map<String, dynamic> json, {
    required String otherUserName,
    String? otherUserAvatar,
  }) {
    return DirectChat(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      user1: json['user1'] is int ? json['user1'] : int.parse(json['user1'].toString()),
      user2: json['user2'] is int ? json['user2'] : int.parse(json['user2'].toString()),
      name: otherUserName,
      lastMessage: json['lastMessage'] as String? ?? '',
      avatarUrl: otherUserAvatar,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}

class DirectMessage {
  final int id;
  final int chat;
  final int sender;
  final String text;
  final String? image;
  final String? video;
  final String? voiceRecording;
  final bool hasPoll;
  final String createdAt;

  const DirectMessage({
    required this.id,
    required this.chat,
    required this.sender,
    required this.text,
    this.image,
    this.video,
    this.voiceRecording,
    required this.hasPoll,
    required this.createdAt,
  });

  factory DirectMessage.fromJson(Map<String, dynamic> json) {
    return DirectMessage(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      chat: json['chat'] is int ? json['chat'] : int.parse(json['chat'].toString()),
      sender: json['sender'] is int ? json['sender'] : int.parse(json['sender'].toString()),
      text: json['text'] as String? ?? '',
      image: json['image'] as String?,
      video: json['video'] as String?,
      voiceRecording: json['voiceRecording'] as String?,
      hasPoll: json['hasPoll'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class Community {
  final String id;
  final String name;
  final int participants;
  final String? imageUrl;
  final bool isCreate;

  const Community({
    required this.id,
    required this.name,
    required this.participants,
    this.imageUrl,
    this.isCreate = false,
  });
}