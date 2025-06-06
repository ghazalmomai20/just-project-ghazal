// lib/models/message_model.dart
// ignore_for_file: file_names

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String? attachmentUrl;
  final String? attachmentType; // image, video, audio, etc.

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.attachmentUrl,
    this.attachmentType,
  });

  // تحويل من Firebase Document إلى Object
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      content: json['content'] ?? '',
      timestamp: json['timestamp']?.toDate() ?? DateTime.now(),
      isRead: json['isRead'] ?? false,
      attachmentUrl: json['attachmentUrl'],
      attachmentType: json['attachmentType'],
    );
  }

  // تحويل من Object إلى Json للتخزين في Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp,
      'isRead': isRead,
      'attachmentUrl': attachmentUrl,
      'attachmentType': attachmentType,
    };
  }
}