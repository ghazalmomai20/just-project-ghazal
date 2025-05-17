import 'package:cloud_firestore/cloud_firestore.dart';

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
