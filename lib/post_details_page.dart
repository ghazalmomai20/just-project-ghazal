// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/notification_service.dart';

class PostDetailsPage extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> postData;

  const PostDetailsPage({
    super.key,
    required this.postId,
    required this.postData,
  });

  @override
  State<PostDetailsPage> createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends State<PostDetailsPage> with TickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  bool _isLiked = false;
  int _likesCount = 0;
  List<Map<String, dynamic>> _comments = [];

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _likeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _likeAnimation;

  @override
  void initState() {
    super.initState();
    _loadPostStats();
    _loadComments();

    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _likeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _likeAnimation = Tween<double>(begin: 1.0, end: 1.3)
        .animate(CurvedAnimation(parent: _likeController, curve: Curves.elasticOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _likeController.dispose();
    super.dispose();
  }

  Future<void> _loadPostStats() async {
    final doc = await FirebaseFirestore.instance.collection('posts').doc(widget.postId).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _likesCount = data['likesCount'] ?? 0;
        _isLiked = (data['likedBy'] as List?)?.contains(FirebaseAuth.instance.currentUser?.uid) ?? false;
      });
    }
  }

  Future<void> _loadComments() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .get();

    setState(() {
      _comments = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    });
  }

  Future<void> _toggleLike() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _likeController.forward().then((_) {
      _likeController.reverse();
    });

    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });

    try {
      final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final doc = await transaction.get(postRef);
        final data = doc.data()!;
        final likedBy = List<String>.from(data['likedBy'] ?? []);

        if (likedBy.contains(userId)) {
          likedBy.remove(userId);
          transaction.update(postRef, {
            'likedBy': likedBy,
            'likesCount': (data['likesCount'] ?? 0) - 1,
          });
        } else {
          likedBy.add(userId);
          transaction.update(postRef, {
            'likedBy': likedBy,
            'likesCount': (data['likesCount'] ?? 0) + 1,
          });
        }
      });

      if (_isLiked) {
        final postOwnerId = widget.postData['ownerId'];
        if (postOwnerId != null && postOwnerId != userId) {
          final currentUser = FirebaseAuth.instance.currentUser;
          
          await FirestoreNotificationService.sendProductLikeNotification(
            productOwnerUid: postOwnerId,
            senderUid: userId,
            senderName: currentUser?.displayName ?? currentUser?.email?.split('@')[0] ?? 'Anonymous',
            senderImageUrl: currentUser?.photoURL ?? '',
            productId: widget.postId,
            productName: widget.postData['name'] ?? 'Product',
          );
        }
      }

    } catch (e) {
      setState(() {
        _isLiked = !_isLiked;
        _likesCount += _isLiked ? 1 : -1;
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating like: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('❌ Error toggling like: $e');
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final commentText = _commentController.text.trim();

    try {
      _commentController.clear();

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .add({
        'text': commentText,
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _loadComments();

      final postOwnerId = widget.postData['ownerId'];
      if (postOwnerId != null && postOwnerId != user.uid) {
        await FirestoreNotificationService.sendProductCommentNotification(
          productOwnerUid: postOwnerId,
          senderUid: user.uid,
          senderName: user.displayName ?? user.email?.split('@')[0] ?? 'Anonymous',
          senderImageUrl: user.photoURL ?? '',
          productId: widget.postId,
          productName: widget.postData['name'] ?? 'Product',
          commentText: commentText,
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment completed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _commentController.text = commentText;
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding comment: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      print('❌ Error adding comment: $e');
    }
  }

  // 👈 دالة جديدة لتعديل التعليق
  Future<void> _editComment(String commentId, String currentText) async {
    final TextEditingController editController = TextEditingController(text: currentText);
    
    final newText = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(
            hintText: 'Edit your comment...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, editController.text.trim()),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (newText != null && newText.isNotEmpty && newText != currentText) {
      try {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .doc(commentId)
            .update({
          'text': newText,
          'editedAt': FieldValue.serverTimestamp(),
        });

        await _loadComments();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comment updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating comment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        print('❌ Error updating comment: $e');
      }
    }

    editController.dispose();
  }

  // 👈 دالة جديدة لحذف التعليق
  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .doc(commentId)
            .delete();

        await _loadComments();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comment deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting comment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        print('❌ Error deleting comment: $e');
      }
    }
  }

  Future<void> _messageOwner() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening chat with owner...'),
        backgroundColor: Color(0xFF1976D2),
      ),
    );
  }

  bool _isOwner() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final postOwnerId = widget.postData['ownerId'] ?? '';
    return currentUserId != null && currentUserId == postOwnerId;
  }

  Future<void> _editPost() async {
    Navigator.pushNamed(
      context,
      '/edit_product',
      arguments: {
        'postId': widget.postId,
        'postData': widget.postData,
      },
    );
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        await FirebaseFirestore.instance.collection('posts').doc(widget.postId).delete();

        Navigator.pop(context);
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.postData['name'] ?? 'Untitled';
    final price = widget.postData['price']?.toString() ?? '0';
    final description = widget.postData['description'] ?? '';
    final imageUrl = widget.postData['imageUrl'] ?? '';
    final condition = widget.postData['condition'] ?? 'Good';
    final location = widget.postData['location'] ?? 'Unknown';
    final category = widget.postData['category'] ?? '';
    final ownerName = widget.postData['ownerName'] ?? 'Anonymous';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(imageUrl, name),
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    _buildPostInfo(name, price, description, condition, location, category, ownerName),
                    _buildActionButtons(),
                    _buildLikesSection(),
                    _buildCommentsSection(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildCommentInput(),
    );
  }

  Widget _buildSliverAppBar(String imageUrl, String name) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: const Color(0xFF1976D2),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1976D2)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ScaleTransition(
            scale: _likeAnimation,
            child: IconButton(
              icon: Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked ? Colors.red : const Color(0xFF1976D2),
              ),
              onPressed: _toggleLike,
            ),
          ),
        ),
        if (_isOwner())
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF1976D2)),
              onSelected: (value) {
                if (value == 'edit') {
                  _editPost();
                } else if (value == 'delete') {
                  _deletePost();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit, color: Color(0xFF1976D2)),
                    title: Text('Edit Post'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete Post'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.image_not_supported, size: 60, color: Colors.white),
              ),
            )
                : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.image, size: 60, color: Colors.white),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostInfo(String name, String price, String description,
      String condition, String location, String category, String ownerName) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "$price JD",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getConditionColor(condition),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  condition,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seller',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    ownerName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildInfoItem(Icons.location_on, 'Location', location),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem(Icons.category, 'Category', category),
              ),
            ],
          ),

          if (description.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1976D2).withOpacity(0.1)),
              ),
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1976D2).withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1976D2), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1976D2).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _messageOwner,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.message, color: Colors.white),
                label: const Text(
                  'Message Owner',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1976D2), width: 2),
            ),
            child: IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sharing post...'),
                    backgroundColor: Color(0xFF1976D2),
                  ),
                );
              },
              icon: const Icon(Icons.share, color: Color(0xFF1976D2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLikesSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: _toggleLike,
        child: Row(
          children: [
            ScaleTransition(
              scale: _likeAnimation,
              child: Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked ? Colors.red : const Color(0xFF1976D2),
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$_likesCount ${_likesCount == 1 ? 'like' : 'likes'}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.comment, color: Color(0xFF1976D2), size: 24),
                const SizedBox(width: 8),
                Text(
                  'Comments (${_comments.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
              ],
            ),
          ),
          if (_comments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.comment_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No comments yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    Text(
                      'Be the first to comment!',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: _comments.length,
              separatorBuilder: (context, index) => Divider(
                color: Colors.grey[200],
                height: 1,
              ),
              itemBuilder: (context, index) {
                final comment = _comments[index];
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                final isOwner = comment['userId'] == currentUserId; // 👈 فحص إذا كان صاحب التعليق
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    comment['userName'] ?? 'Anonymous',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1976D2),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                // 👈 إظهار قائمة الخيارات فقط لصاحب التعليق
                                if (isOwner)
                                  PopupMenuButton<String>(
                                    icon: Icon(
                                      Icons.more_vert,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _editComment(comment['id'], comment['text'] ?? '');
                                      } else if (value == 'delete') {
                                        _deleteComment(comment['id']);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 16, color: Color(0xFF1976D2)),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, size: 16, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              comment['text'] ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF2C3E50),
                                height: 1.3,
                              ),
                            ),
                            // 👈 إظهار علامة "edited" إذا تم تعديل التعليق
                            if (comment['editedAt'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'edited',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFB),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF1976D2).withOpacity(0.2)),
                ),
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Write a comment...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                onPressed: _addComment,
                icon: const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'new':
        return const Color(0xFF4CAF50);
      case 'excellent':
        return const Color(0xFF2196F3);
      case 'good':
        return const Color(0xFFFF9800);
      case 'fair':
        return const Color(0xFFFF5722);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}