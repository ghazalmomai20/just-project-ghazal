import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'default_channel_id',
      'Default Channel',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }
}

class FirestoreNotificationService {
  // إرسال إشعار عند الإعجاب بمنشور
  static Future<void> sendLikeNotification({
    required String postOwnerUid,
    required String senderUid,
    required String senderName,
    required String senderImageUrl,
    required String postId,
  }) async {
    if (postOwnerUid == senderUid) return;

    await FirebaseFirestore.instance.collection('notifications').add({
      'uid': postOwnerUid,
      'senderUid': senderUid,
      'senderName': senderName,
      'senderImageUrl': senderImageUrl,
      'type': 'like',
      'postId': postId,
      'timestamp': Timestamp.now(),
      'message': '$senderName أُعجب بمنشورك',
    });
  }

  // إرسال إشعار عند التعليق على منشور
  static Future<void> sendCommentNotification({
    required String postOwnerUid,
    required String senderUid,
    required String senderName,
    required String senderImageUrl,
    required String postId,
  }) async {
    if (postOwnerUid == senderUid) return;

    await FirebaseFirestore.instance.collection('notifications').add({
      'uid': postOwnerUid,
      'senderUid': senderUid,
      'senderName': senderName,
      'senderImageUrl': senderImageUrl,
      'type': 'comment',
      'postId': postId,
      'timestamp': Timestamp.now(),
      'message': '$senderName علّق على منشورك',
    });
  }

  // إرسال إشعار عند إرسال رسالة
  static Future<void> sendMessageNotification({
    required String receiverUid,
    required String senderUid,
    required String senderName,
    required String senderImageUrl,
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'uid': receiverUid,
      'senderUid': senderUid,
      'senderName': senderName,
      'senderImageUrl': senderImageUrl,
      'type': 'message',
      'timestamp': Timestamp.now(),
      'message': '$senderName أرسل لك رسالة',
    });
  }
}