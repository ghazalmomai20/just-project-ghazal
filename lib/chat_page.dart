// ignore_for_file: unused_field

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
// ignore: unnecessary_import
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String receiverAvatar;
  final String userName;
  final String userAvatar;

  const ChatPage({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.receiverAvatar,
    required this.userName,
    required this.userAvatar,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _textFieldFocus = FocusNode();
  final userId = FirebaseAuth.instance.currentUser!.uid;
  late final String chatRoomId;

  bool _isOnline = false;
  DateTime? _lastSeen;
  bool _isTyping = false;
  // ignore: prefer_final_fields
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    chatRoomId = getChatRoomId(userId, widget.receiverId);
    _setupChatRoom();
    _markMessagesAsRead();
    _updateOnlineStatus(true);
    _listenToTyping();
    _listenToOnlineStatus();
  }

  @override
  void dispose() {
    _updateOnlineStatus(false);
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _textFieldFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _updateOnlineStatus(true);
    } else if (state == AppLifecycleState.paused) {
      _updateOnlineStatus(false);
    }
  }

  String getChatRoomId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  Future<void> _setupChatRoom() async {
    final chatRoomRef = FirebaseFirestore.instance.collection('chat_rooms').doc(chatRoomId);

    await chatRoomRef.set({
      'users': [userId, widget.receiverId],
      'userNames': {
        userId: widget.userName,
        widget.receiverId: widget.receiverName,
      },
      'userAvatars': {
        userId: widget.userAvatar,
        widget.receiverId: widget.receiverAvatar,
      },
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _markMessagesAsRead() async {
    final chatRoomRef = FirebaseFirestore.instance.collection('chat_rooms').doc(chatRoomId);

    await chatRoomRef.update({
      'unreadCount.$userId': 0,
    });
  }

  void _updateOnlineStatus(bool isOnline) {
    FirebaseFirestore.instance.collection('user_status').doc(userId).set({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _listenToOnlineStatus() {
    FirebaseFirestore.instance
        .collection('user_status')
        .doc(widget.receiverId)
        .snapshots()
        .listen((doc) {
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _isOnline = data['isOnline'] ?? false;
          _lastSeen = (data['lastSeen'] as Timestamp?)?.toDate();
        });
      }
    });
  }

  void _listenToTyping() {
    FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatRoomId)
        .snapshots()
        .listen((doc) {
      if (doc.exists && mounted) {
        final data = doc.data()!;
        final typingData = data['typing'] as Map<String, dynamic>? ?? {};
        final otherUserTyping = typingData[widget.receiverId] ?? false;

        if (_isTyping != otherUserTyping) {
          setState(() {
            _isTyping = otherUserTyping;
          });
        }
      }
    });
  }

  void _updateTypingStatus(bool isTyping) {
    FirebaseFirestore.instance.collection('chat_rooms').doc(chatRoomId).update({
      'typing.$userId': isTyping,
    });
  }

  Future<void> _sendMessage({String? text, String? imageUrl, String type = 'text'}) async {
    final messageText = text ?? _messageController.text.trim();
    if (messageText.isEmpty && imageUrl == null) return;

    _messageController.clear();
    _updateTypingStatus(false);

    final messageData = {
      'senderId': userId,
      'senderName': widget.userName,
      'senderAvatar': widget.userAvatar,
      'text': messageText,
      'imageUrl': imageUrl,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      'chatId': chatRoomId,
      'isRead': false,
    };

    // Add message to subcollection
    await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(messageData);

    // Update chat room info
    await FirebaseFirestore.instance.collection('chat_rooms').doc(chatRoomId).update({
      'lastMessage': type == 'text' ? messageText : '📷 Photo',
      'lastMessageType': type,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount.${widget.receiverId}': FieldValue.increment(1),
    });

    _scrollToBottom();
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Upload image to Firebase Storage
      final file = File(pickedFile.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child(chatRoomId)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = await storageRef.putFile(file);
      final imageUrl = await uploadTask.ref.getDownloadURL();

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Send message with image
      await _sendMessage(imageUrl: imageUrl, type: 'image');

    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send image: $e')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getOnlineStatus() {
    if (_isOnline) {
      return 'Online';
    } else if (_lastSeen != null) {
      final now = DateTime.now();
      final difference = now.difference(_lastSeen!);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return DateFormat('MMM d').format(_lastSeen!);
      }
    }
    return 'Offline';
  }

  Widget _buildMessage(Map<String, dynamic> msg, bool isMe) {
    final time = (msg['timestamp'] as Timestamp?)?.toDate();
    final formattedTime = time != null ? DateFormat.jm().format(time) : '';
    final messageType = msg['type'] ?? 'text';

    return Container(
      margin: EdgeInsets.only(
        left: isMe ? 50 : 10,
        right: isMe ? 10 : 50,
        top: 2,
        bottom: 2,
      ),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? Color(0xFF1976D2): Colors.grey[300],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 5),
                bottomRight: Radius.circular(isMe ? 5 : 20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (messageType == 'image' && msg['imageUrl'] != null)
                  Container(
                    constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        msg['imageUrl'],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 100,
                            width: 100,
                            color: Colors.grey[300],
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 100,
                            width: 100,
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          );
                        },
                      ),
                    ),
                  ),
                if (msg['text'] != null && msg['text'].toString().isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: messageType == 'image' ? 8 : 0),
                    child: SelectableText(
                      msg['text'] ?? '',
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: isMe ? 0 : 8,
              right: isMe ? 8 : 0,
              top: 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formattedTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg['isRead'] == true ? Icons.done_all : Icons.done,
                    size: 16,
                    color: msg['isRead'] == true ? Colors.blue : Colors.grey,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B3B98),
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: widget.receiverAvatar.isNotEmpty
                      ? NetworkImage(widget.receiverAvatar)
                      : null,
                  child: widget.receiverAvatar.isEmpty
                      ? Text(
                    widget.receiverName.isNotEmpty
                        ? widget.receiverName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                      : null,
                ),
                if (_isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _isTyping ? 'Typing...' : _getOnlineStatus(),
                    style: TextStyle(
                      color: _isTyping ? Colors.greenAccent : Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // Show options menu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc(chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        Text(
                          'Send a message to start the conversation',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == userId;

                    return _buildMessage(msg, isMe);
                  },
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.photo_camera, color: Color(0xFF3B3B98)),
                      onPressed: _sendImage,
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TextField(
                          controller: _messageController,
                          focusNode: _textFieldFocus,
                          maxLines: null,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            border: InputBorder.none,
                          ),
                          onChanged: (text) {
                            final isCurrentlyTyping = text.isNotEmpty;
                            if (isCurrentlyTyping != _isTyping) {
                              _updateTypingStatus(isCurrentlyTyping);
                            }
                          },
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF1976D2), 
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () => _sendMessage(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}