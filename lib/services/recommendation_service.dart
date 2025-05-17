import 'package:cloud_firestore/cloud_firestore.dart';

/// توصية بناءً على العلامات التي شاهدها المستخدم
Future<List<DocumentSnapshot>> getContentBasedRecommendations(String uid) async {
  final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  final List<dynamic> viewedTags = userDoc.data()?['viewedTags'] ?? [];

  final snapshot = await FirebaseFirestore.instance
      .collection('products')
      .where('tags', arrayContainsAny: viewedTags.take(10).toList())
      .limit(10)
      .get();

  return snapshot.docs;
}

/// توصية بناءً على التصنيفات التي يتفاعل معها المستخدم
Future<List<DocumentSnapshot>> getCategoryBasedRecommendations(String uid) async {
  final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  final List<dynamic> recentCategories = userDoc.data()?['recentCategories'] ?? [];

  final snapshot = await FirebaseFirestore.instance
      .collection('products')
      .where('category', whereIn: recentCategories.take(3))
      .where('createdBy', isNotEqualTo: uid)
      .limit(10)
      .get();

  return snapshot.docs;
}

/// توصية عبر Collaborative Filtering (من إعجابات مستخدمين مشابهين)
Future<List<DocumentSnapshot>> getCollaborativeRecommendations(String uid) async {
  final myLikesSnapshot = await FirebaseFirestore.instance
      .collection('likes')
      .where('userId', isEqualTo: uid)
      .get();

  final likedProductIds = myLikesSnapshot.docs.map((doc) => doc['productId']).toSet();

  final peerLikesSnapshot = await FirebaseFirestore.instance
      .collection('likes')
      .where('productId', whereIn: likedProductIds.take(10).toList())
      .get();

  final peerUserIds = peerLikesSnapshot.docs
      .map((doc) => doc['userId'])
      .where((id) => id != uid)
      .toSet();

  final allPeerLikesSnapshot = await FirebaseFirestore.instance
      .collection('likes')
      .where('userId', whereIn: peerUserIds.take(10).toList())
      .get();

  final recommendedProductIds = allPeerLikesSnapshot.docs
      .map((doc) => doc['productId'])
      .where((id) => !likedProductIds.contains(id))
      .toSet();

  final recommendedSnapshot = await FirebaseFirestore.instance
      .collection('products')
      .where(FieldPath.documentId, whereIn: recommendedProductIds.take(10).toList())
      .get();

  return recommendedSnapshot.docs;
}

/// دمج النتائج من جميع استراتيجيات التوصية
Future<List<DocumentSnapshot>> getCombinedRecommendations(String uid) async {
  final contentBased = await getContentBasedRecommendations(uid);
  final collaborative = await getCollaborativeRecommendations(uid);
  final categoryBased = await getCategoryBasedRecommendations(uid);

  final all = {...contentBased, ...collaborative, ...categoryBased}.toList();
  all.shuffle();
  return all.take(10).toList();
}