import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'add_product_page.dart';
import 'settings_page.dart';
import 'chat_list_page.dart';
import 'favorites_page.dart';
import 'profile_page.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  String _username = 'User';
  String _selectedCategory = 'All';
  String _searchQuery = ''; // ✅ متغير البحث الجديد
  final Color _primaryColor = const Color(0xFF1976D2);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

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
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'User';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildAppBar(context),
              _buildSearchBar(),
              SizedBox(height: 80, child: _buildCategorySelector()),
              Expanded(child: _buildPostsGrid()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primaryColor,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductPage()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _primaryColor,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.3),
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Welcome,", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
              Text(
                _username,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const Spacer(),
          _buildAnimatedIcon(Icons.notifications_outlined, () {}),
          _buildAnimatedIcon(Icons.settings, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
          }),
        ],
      ),
    );
  }

  Widget _buildAnimatedIcon(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, color: Colors.white),
      onPressed: onPressed,
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: _primaryColor,
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
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Search posts...',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            Icon(Icons.filter_list, color: _primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
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
                    color: isSelected ? _primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                  ),
                  child: Icon(
                    category['icon'],
                    size: 20,
                    color: isSelected ? Colors.white : _primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category['label'],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? _primaryColor : Colors.grey[700],
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

  Widget _buildBottomNavBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6,
      color: Colors.white,
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 'Home', true),
            _buildNavItem(Icons.favorite_border, 'Favorites', false),
            const SizedBox(width: 32),
            _buildNavItem(Icons.chat_bubble_outline, 'Messages', false),
            _buildNavItem(Icons.person_outline, 'Profile', false),
          ],
        ),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? _primaryColor : Colors.grey[600], size: 20),
          const SizedBox(height: 1),
          Text(label, style: TextStyle(fontSize: 10, color: isSelected ? _primaryColor : Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildPostsGrid() {
    final query = _selectedCategory == 'All'
        ? FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true)
        : FirebaseFirestore.instance
        .collection('posts')
        .where('category', isEqualTo: _selectedCategory)
        .orderBy('timestamp', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Error loading posts'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final posts = snapshot.data!.docs;

        final filteredPosts = _searchQuery.isEmpty
            ? posts
            : posts.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['name']?.toLowerCase() ?? '';
          return name.contains(_searchQuery.toLowerCase());
        }).toList();

        if (filteredPosts.isEmpty) {
          return const Center(child: Text('No posts found.'));
        }

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
                color: Colors.white,
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
                        Text("\$$price", style: TextStyle(color: _primaryColor, fontSize: 14)),
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
