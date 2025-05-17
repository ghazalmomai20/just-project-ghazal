import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_product_page.dart';
import 'settings_page.dart';
import 'chat_list_page.dart';
import 'favorites_page.dart';
import 'profile_page.dart';
import 'notifications_page.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  String _username = 'User';
  String _selectedCategory = 'All';
  String _searchQuery = '';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.all_inclusive, 'label': 'All'},
    {'icon': Icons.book, 'label': 'Books'},
    {'icon': Icons.school, 'label': 'Lab Coat'},
    {'icon': Icons.laptop, 'label': 'Laptop'},
    {'icon': Icons.medical_services, 'label': 'Medical'},
    {'icon': Icons.architecture, 'label': 'Engineering'},
    {'icon': Icons.color_lens, 'label': 'Arts'},
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
    _loadUsername();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _username = user?.displayName ?? 'User';
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF1976D2);
    final Color backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildAppBar(context, primaryColor),
              _buildSearchBar(primaryColor),
              SizedBox(height: 80, child: _buildCategorySelector(primaryColor)),
              Expanded(child: _buildPostsGrid(primaryColor)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductPage()));
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(primaryColor),
    );
  }

  Widget _buildAppBar(BuildContext context, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      color: primaryColor,
      child: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.person, color: Colors.white)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_getGreeting()},', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
              Text(_username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage())),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: primaryColor,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey[600], size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: const InputDecoration(
                  hintText: 'Search posts...',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            Icon(Icons.filter_list, color: primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(Color primaryColor) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final isSelected = _selectedCategory == category['label'];

        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = category['label']),
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            width: 65,
            child: Column(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                  ),
                  child: Icon(category['icon'], size: 20, color: isSelected ? Colors.white : primaryColor),
                ),
                const SizedBox(height: 4),
                Text(
                  category['label'],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? primaryColor : Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavBar(Color primaryColor) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6,
      color: Theme.of(context).colorScheme.surface,
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 'Home', true, primaryColor),
            _buildNavItem(Icons.favorite_border, 'Favorites', false, primaryColor),
            const SizedBox(width: 32),
            _buildNavItem(Icons.chat_bubble_outline, 'Messages', false, primaryColor),
            _buildNavItem(Icons.person_outline, 'Profile', false, primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected, Color primaryColor) {
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? primaryColor : Colors.grey[600], size: 20),
          const SizedBox(height: 1),
          Text(label, style: TextStyle(fontSize: 10, color: isSelected ? primaryColor : Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildPostsGrid(Color primaryColor) {
    final query = FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Error loading posts'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final posts = snapshot.data!.docs;
        final filteredPosts = posts.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['name']?.toLowerCase() ?? '';
          final category = data['category'] ?? '';
          final matchesSearch = name.contains(_searchQuery.toLowerCase());
          final matchesCategory = _selectedCategory == 'All' || category == _selectedCategory;
          return matchesSearch && matchesCategory;
        }).toList();

        if (filteredPosts.isEmpty) return const Center(child: Text('No posts found.'));

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.75,
          ),
          itemCount: filteredPosts.length,
          itemBuilder: (context, index) {
            final data = filteredPosts[index].data() as Map<String, dynamic>;
            final name = data['name'] ?? '';
            final price = data['price']?.toString() ?? '0';
            final imageUrl = data['imageUrl'] ?? '';

            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: imageUrl.isNotEmpty
                        ? Image.network(imageUrl, height: 120, width: double.infinity, fit: BoxFit.cover)
                        : Container(height: 120, color: Colors.grey[300], child: const Icon(Icons.image)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text("\$$price", style: TextStyle(color: primaryColor, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
