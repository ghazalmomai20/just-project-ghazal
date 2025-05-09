import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: true,
        backgroundColor: const Color(0xFF1746A2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No notifications yet"));
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            separatorBuilder: (context, index) => const Divider(),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final bool isRead = data['isRead'] ?? false;
              final String title = data['title'] ?? 'No Title';
              final String body = data['body'] ?? '';
              final Timestamp timestamp = data['timestamp'] ?? Timestamp.now();

              final DateFormat formatter = DateFormat.yMMMd().add_jm();
              final String time = formatter.format(timestamp.toDate());

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getTypeColor(data['type']),
                  child: _getTypeIcon(data['type']),
                ),
                title: Text(title, style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                subtitle: Text(body),
                trailing: Text(time, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                tileColor: isRead ? null : Colors.deepPurple.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  // Handle action and mark as read
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('notifications')
                      .doc(docs[index].id)
                      .update({'isRead': true});
                  
                  // Navigate to related screen based on notification type (optional)
                },
              );
            },
          );
        },
      ),
    );
  }

  Icon _getTypeIcon(String? type) {
    switch (type) {
      case 'question':
        return const Icon(Icons.question_answer, color: Colors.white);
      case 'sold':
        return const Icon(Icons.sell, color: Colors.white);
      case 'report':
        return const Icon(Icons.report, color: Colors.white);
      default:
        return const Icon(Icons.notifications, color: Colors.white);
    }
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'question':
        return Colors.blueAccent;
      case 'sold':
        return Colors.green;
      case 'report':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }
}
