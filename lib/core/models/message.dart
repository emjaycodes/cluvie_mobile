class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isMe;
  final String? parentId; // For threading
  List<String> reactions; // List of emoji or reaction strings

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.isMe,
    this.parentId,
    this.reactions = const [],
  });
}
