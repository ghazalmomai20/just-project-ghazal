// lib/providers/chat_service.dart
// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // إرسال رسالة
  Future<void> sendMessage({
    required String receiverId,
    required String content,
    String? attachmentUrl,
    String? attachmentType,
  }) async {
    final String currentUserId = _auth.currentUser!.uid;
    final Timestamp timestamp = Timestamp.now();

    // إنشاء معرف فريد للرسالة
    final String messageId = _firestore.collection('messages').doc().id;

    // إنشاء نموذج الرسالة
    Message message = Message(
      id: messageId,
      senderId: currentUserId,
      receiverId: receiverId,
      content: content,
      timestamp: timestamp.toDate(),
      attachmentUrl: attachmentUrl,
      attachmentType: attachmentType,
    );

    // تخزين الرسالة في Firestore
    await _firestore.collection('messages').doc(messageId).set(message.toJson());

    // تحديث آخر رسالة في قائمة المحادثات
    await _updateChatList(currentUserId, receiverId, content, timestamp);
  }

  // الحصول على الرسائل بين مستخدمين
  Stream<List<Message>> getMessages(String otherUserId) {
    final String currentUserId = _auth.currentUser!.uid;

    return _firestore
        .collection('messages')
        .where('senderId', whereIn: [currentUserId, otherUserId])
        .where('receiverId', whereIn: [currentUserId, otherUserId])
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Message.fromJson(doc.data())).toList());
  }

  // تحديث قائمة المحادثات
  Future<void> _updateChatList(
      String currentUserId,
      String otherUserId,
      String lastMessage,
      Timestamp timestamp,
      ) async {
    // تحديث قائمة المحادثات للمستخدم الحالي
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('chats')
        .doc(otherUserId)
        .set({
      'userId': otherUserId,
      'lastMessage': lastMessage,
      'timestamp': timestamp,
      'unreadCount': 0,
    }, SetOptions(merge: true));

    // تحديث قائمة المحادثات للمستخدم الآخر
    await _firestore
        .collection('users')
        .doc(otherUserId)
        .collection('chats')
        .doc(currentUserId)
        .set({
      'userId': currentUserId,
      'lastMessage': lastMessage,
      'timestamp': timestamp,
      'unreadCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  // الحصول على قائمة المحادثات
  Stream<QuerySnapshot> getChatList() {
    final String currentUserId = _auth.currentUser!.uid;

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // تعليم الرسائل كمقروءة
  Future<void> markAsRead(String otherUserId) async {
    final String currentUserId = _auth.currentUser!.uid;

    // تحديث الرسائل
    final QuerySnapshot unreadMessages = await _firestore
        .collection('messages')
        .where('senderId', isEqualTo: otherUserId)
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    WriteBatch batch = _firestore.batch();
    unreadMessages.docs.forEach((doc) {
      batch.update(doc.reference, {'isRead': true});
    });

    // تحديث عداد الرسائل غير المقروءة
    batch.update(
        _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('chats')
            .doc(otherUserId),
        {'unreadCount': 0}
    );

    await batch.commit();
  }
}