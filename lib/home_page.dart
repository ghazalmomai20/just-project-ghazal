import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'add_product_page.dart';
import 'settings_page.dart';
import 'chat_list_page.dart';
import 'favorites_page.dart';
import 'profile_page.dart';
import 'notifications_page.dart';
import 'post_details_page.dart';
import 'package:just_store_clean/widgets/favorite_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  String _username = 'User';
  String _selectedCategory = 'All';
  String _searchQuery = '';

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.all_inclusive, 'label': 'All', 'gradient': [Color(0xFF0288D1), Color(0xFF42A5F5)]},
    {'icon': Icons.book, 'label': 'Books', 'gradient': [Color(0xFF0288D1), Color(0xFF42A5F5)]},
    {'icon': Icons.school, 'label': 'Lab Coat', 'gradient': [Color(0xFF0288D1), Color(0xFF42A5F5)]},
    {'icon': Icons.laptop, 'label': 'Laptop', 'gradient': [Color(0xFF0288D1), Color(0xFF42A5F5)]},
    {'icon': Icons.medical_services, 'label': 'Medical', 'gradient': [Color(0xFF0288D1), Color(0xFF42A5F5)]},
    {'icon': Icons.architecture, 'label': 'Engineering', 'gradient': [Color(0xFF0288D1), Color(0xFF42A5F5)]},
    {'icon': Icons.color_lens, 'label': 'Arts', 'gradient': [Color(0xFF0288D1), Color(0xFF42A5F5)]},
  ];

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _fadeController.forward();
    _slideController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUsername());
  }

  Future<void> _loadUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final displayName = user.displayName;
      final emailName = user.email?.split('@').first ?? 'User';
      setState(() {
        _username = (displayName != null && displayName.trim().isNotEmpty) ? displayName : emailName;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildAppBar(),
                _buildSearchBar(),
                SizedBox(height: 90, child: _buildCategorySelector()),
                Expanded(child: _buildPostsGrid()),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
backgroundColor: const Color(0xFF0288D1),        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductPage()));
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Color(0xFF1976D2), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_getGreeting()},',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                const SizedBox(height: 2),
                Text(_username,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
              ],
            ),
          ),
          _buildAppBarButton(Icons.notifications_outlined, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
          }),
          const SizedBox(width: 8),
          _buildAppBarButton(Icons.settings_outlined, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
          }),
        ],
      ),
    );
  }

  Widget _buildAppBarButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.search, color:Color(0xFF1976D2)),
            ),
            Expanded(
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: const InputDecoration(
                  hintText: 'Search for products...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final isSelected = _selectedCategory == category['label'];
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = category['label']),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            width: 70,
            child: Column(
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    gradient: isSelected ? LinearGradient(colors: category['gradient']) : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(category['icon'], color: isSelected ? Colors.white : Colors.blue),
                ),
                const SizedBox(height: 8),
                Text(category['label'], style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'Home', true),
          _buildNavItem(Icons.favorite, 'Favorites', false),
          const SizedBox(width: 40,),
          _buildNavItem(Icons.chat, 'Messages', false),
          _buildNavItem(Icons.person, 'Profile', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return InkWell(
      onTap: () {
        if (label == 'Favorites') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesPage()));
        } else if (label == 'Messages') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListPage()));
        } else if (label == 'Profile') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userName: _username)));
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ?Color(0xFF1976D2) : Colors.grey),
          Text(label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Color(0xFF1976D2) : Colors.grey,
              )),
        ],
      ),
    );
  }

  Widget _buildPostsGrid() {
    final query = FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Error loading posts'));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No posts found'));

        final posts = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['name']?.toLowerCase() ?? '';
          final category = data['category'] ?? '';
          return name.contains(_searchQuery.toLowerCase()) &&
              (_selectedCategory == 'All' || _selectedCategory == category);
        }).toList();

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final doc = posts[index];
            final data = doc.data() as Map<String, dynamic>;
            final postId = doc.id;

            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PostDetailsPage(postId: postId, postData: data)),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).cardColor,
                  boxShadow: [BoxShadow(color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.1), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: data['imageUrl'] != null && data['imageUrl'] != ''
                                ? Image.network(data['imageUrl'], fit: BoxFit.cover, width: double.infinity)
                                : Container(color: Colors.grey[200]),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: FavoriteButton(
                              productId: postId,
                              productData: {
                                'title': data['name'],
                                'image': data['imageUrl'],
                                'price': data['price'],
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${data['price']} JD', style: const TextStyle(color: Colors.green)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
