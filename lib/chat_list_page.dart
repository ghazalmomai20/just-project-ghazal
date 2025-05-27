import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_page.dart';
import 'package:intl/intl.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  String _searchQuery = '';

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat('hh:mm a').format(date);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(date); // Day name
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  Map<String, String> _getOtherUserData(Map<String, dynamic> data, String currentUserId) {
    final users = data['participants'] as List;
    final userNames = data['userNames'] as Map<String, dynamic>? ?? {};
    final userAvatars = data['userAvatars'] as Map<String, dynamic>? ?? {};

    final otherUserId = users.firstWhere((id) => id != currentUserId, orElse: () => '');

    return {
      'id': otherUserId,
      'name': userNames[otherUserId] ?? 'Unknown User',
      'avatar': userAvatars[otherUserId] ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid ?? '';
    final userName = currentUser?.displayName ?? 'Me';
    final userAvatar = currentUser?.photoURL ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B3B98),
        elevation: 0,
        title: const Text('Chats',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20
            )
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ChatSearchDelegate(
                    userId: userId,
                    userName: userName,
                    userAvatar: userAvatar
                ),
              );
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chat_rooms')
            .where('participants', arrayContains: userId)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B3B98)),
                )
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start chatting with sellers!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final otherUser = _getOtherUserData(data, userId);
              final lastMsg = data['lastMessage'] ?? '';
              final lastMsgType = data['lastMessageType'] ?? 'text';
              final time = _formatTime(data['lastMessageTime']);
              final unreadCount = (data['unreadCount'] as Map<String, dynamic>?)?[userId] ?? 0;
              final isOnline = data['isOnline'] ?? false;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: otherUser['avatar']!.isNotEmpty ? NetworkImage(otherUser['avatar']!) : null,
                  child: otherUser['avatar']!.isEmpty ? Text(otherUser['name']![0].toUpperCase()) : null,
                ),
                title: Text(otherUser['name']!),
                subtitle: Text(_getDisplayMessage(lastMsg, lastMsgType)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(time, style: const TextStyle(fontSize: 12)),
                    if (unreadCount > 0)
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.red,
                        child: Text('$unreadCount', style: const TextStyle(fontSize: 12, color: Colors.white)),
                      ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        receiverId: otherUser['id']!,
                        receiverName: otherUser['name']!,
                        receiverAvatar: otherUser['avatar']!,
                        userName: userName,
                        userAvatar: userAvatar,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _getDisplayMessage(String message, String type) {
    switch (type) {
      case 'image':
        return '📷 Photo';
      case 'file':
        return '📎 File';
      case 'audio':
        return '🎵 Audio';
      case 'video':
        return '🎬 Video';
      default:
        return message;
    }
  }
}

class ChatSearchDelegate extends SearchDelegate<String> {
  final String userId;
  final String userName;
  final String userAvatar;

  ChatSearchDelegate({required this.userId, required this.userName, required this.userAvatar});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return const Center(child: Text('Type to search conversations...'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chat_rooms')
          .where('participants', arrayContains: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final userNames = data['userNames'] as Map<String, dynamic>? ?? {};
          final otherUserId = (data['participants'] as List).firstWhere((id) => id != userId, orElse: () => '');
          final otherName = userNames[otherUserId] ?? '';
          return otherName.toLowerCase().contains(query.toLowerCase());
        }).toList();

        if (filteredDocs.isEmpty) return const Center(child: Text('No conversations found'));

        return ListView.builder(
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final data = filteredDocs[index].data() as Map<String, dynamic>;
            final userNames = data['userNames'] as Map<String, dynamic>? ?? {};
            final userAvatars = data['userAvatars'] as Map<String, dynamic>? ?? {};
            final otherUserId = (data['participants'] as List).firstWhere((id) => id != userId, orElse: () => '');
            final otherName = userNames[otherUserId] ?? 'Unknown User';
            final otherAvatar = userAvatars[otherUserId] ?? '';

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: otherAvatar.isNotEmpty ? NetworkImage(otherAvatar) : null,
                child: otherAvatar.isEmpty ? Text(otherName.isNotEmpty ? otherName[0] : '?') : null,
              ),
              title: Text(otherName),
              onTap: () {
                close(context, '');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatPage(
                      receiverId: otherUserId,
                      receiverName: otherName,
                      receiverAvatar: otherAvatar,
                      userName: userName,
                      userAvatar: userAvatar,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
