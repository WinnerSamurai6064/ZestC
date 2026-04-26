class User {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? bio;

  User({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeen,
    this.bio,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'],
        username: j['username'],
        displayName: j['display_name'] ?? j['username'],
        avatarUrl: j['avatar_url'],
        isOnline: j['is_online'] ?? false,
        lastSeen: j['last_seen'] != null ? DateTime.parse(j['last_seen']) : null,
        bio: j['bio'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'is_online': isOnline,
        'last_seen': lastSeen?.toIso8601String(),
        'bio': bio,
      };
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String? content;
  final String? imageUrl;
  final MessageStatus status;
  final DateTime createdAt;
  final bool isDeleted;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.content,
    this.imageUrl,
    this.status = MessageStatus.sent,
    required this.createdAt,
    this.isDeleted = false,
  });

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: j['id'],
        chatId: j['chat_id'],
        senderId: j['sender_id'],
        content: j['content'],
        imageUrl: j['image_url'],
        status: MessageStatus.values.firstWhere(
          (e) => e.name == (j['status'] ?? 'sent'),
          orElse: () => MessageStatus.sent,
        ),
        createdAt: DateTime.parse(j['created_at']),
        isDeleted: j['is_deleted'] ?? false,
      );

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
}

enum MessageStatus { sending, sent, delivered, read }

class Chat {
  final String id;
  final List<User> participants;
  final Message? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;

  Chat({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.unreadCount = 0,
    required this.updatedAt,
  });

  User otherUser(String myId) =>
      participants.firstWhere((u) => u.id != myId, orElse: () => participants.first);

  factory Chat.fromJson(Map<String, dynamic> j, String myId) {
    final parts = (j['participants'] as List? ?? [])
        .map((u) => User.fromJson(u))
        .toList();
    return Chat(
      id: j['id'],
      participants: parts,
      lastMessage: j['last_message'] != null
          ? Message.fromJson(j['last_message'])
          : null,
      unreadCount: j['unread_count'] ?? 0,
      updatedAt: DateTime.parse(j['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
