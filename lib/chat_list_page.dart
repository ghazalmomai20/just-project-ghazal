import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'chat_page.dart';
import 'dart:math' as math;

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> with SingleTickerProviderStateMixin {
  final List<ChatUser> _chatUsers = [
    ChatUser(
      name: 'علي محمد',
      avatar: 'https://randomuser.me/api/portraits/men/1.jpg',
      lastMessage: 'مرحباً، كيف حالك اليوم؟',
      time: '09:45',
      unreadCount: 3,
    ),
    ChatUser(
      name: 'سارة أحمد',
      avatar: 'https://randomuser.me/api/portraits/women/1.jpg',
      lastMessage: 'هل المنتج ما زال متوفراً؟',
      time: 'الأمس',
      unreadCount: 0,
    ),
    ChatUser(
      name: 'محمد خالد',
      avatar: 'https://randomuser.me/api/portraits/men/2.jpg',
      lastMessage: 'شكراً لك، سأتواصل معك لاحقاً',
      time: 'الأمس',
      unreadCount: 0,
    ),
    ChatUser(
      name: 'لينا فادي',
      avatar: 'https://randomuser.me/api/portraits/women/2.jpg',
      lastMessage: 'تم الاتفاق، سأرسل لك العنوان',
      time: 'الإثنين',
      unreadCount: 1,
    ),
    ChatUser(
      name: 'خالد عمر',
      avatar: 'https://randomuser.me/api/portraits/men/3.jpg',
      lastMessage: 'هل يمكن تخفيض السعر قليلاً؟',
      time: 'الأحد',
      unreadCount: 0,
    ),
  ];

  String _searchQuery = '';
  late AnimationController _animationController;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        _searchQuery = '';
      }
    });
  }

  void _deleteChat(ChatUser user) {
    final index = _chatUsers.indexOf(user);
    if (index != -1) {
      setState(() {
        final removedItem = _chatUsers.removeAt(index);
        _listKey.currentState?.removeItem(
          index,
              (context, animation) => _buildChatItem(removedItem, animation),
          duration: const Duration(milliseconds: 300),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حذف المحادثة مع ${user.name}'),
          action: SnackBarAction(
            label: 'تراجع',
            onPressed: () {
              setState(() {
                _chatUsers.insert(index, user);
                _listKey.currentState?.insertItem(index, duration: const Duration(milliseconds: 300));
              });
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredUsers = _chatUsers
        .where((user) => user.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF3B3B98),
          statusBarIconBrightness: Brightness.light,
        ),
        backgroundColor: const Color(0xFF3B3B98),
        elevation: 0,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, -0.5),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: _isSearching
              ? TextField(
            key: const ValueKey('searchField'),
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'البحث...',
              hintStyle: const TextStyle(color: Colors.white70),
              border: InputBorder.none,
              prefixIcon: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: _toggleSearch,
              ),
            ),
            autofocus: true,
          )
              : const Text(
            'المحادثات',
            key: ValueKey('title'),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: _toggleSearch,
            ),
        ],
      ),
      backgroundColor: isDark ? Colors.black : Colors.grey[100],
      body: Column(
        children: [
          _buildOnlineUsersBar(),
          Expanded(
            child: _isSearching
                ? ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                return _buildChatItem(filteredUsers[index], const AlwaysStoppedAnimation(1));
              },
            )
                : AnimatedList(
              key: _listKey,
              initialItemCount: _chatUsers.length,
              itemBuilder: (context, index, animation) {
                return _buildChatItem(_chatUsers[index], animation);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3B3B98),
        child: const Icon(Icons.add_comment, color: Colors.white),
        onPressed: () {
          // Open new chat creation screen
        },
      ),
    );
  }

  Widget _buildOnlineUsersBar() {
    return Container(
      height: 100,
      color: const Color(0xFF3B3B98).withOpacity(0.8),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: _chatUsers.length,
        itemBuilder: (context, index) {
          final user = _chatUsers[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Stack(
                  children: [
                    Hero(
                      tag: 'avatar-${user.name}',
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          image: DecorationImage(
                            image: NetworkImage(user.avatar),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.name.split(' ')[0],
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatItem(ChatUser user, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
      child: FadeTransition(
        opacity: animation,
        child: Dismissible(
          key: Key(user.name),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _deleteChat(user),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => ChatPage(
                    userName: user.name,
                    userAvatar: user.avatar,
                  ),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                        .chain(CurveTween(curve: Curves.ease));
                    return SlideTransition(position: animation.drive(tween), child: child);
                  },
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[900]
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Hero(
                      tag: 'avatar-${user.name}',
                      child: CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(user.avatar),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                user.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                  user.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                              Text(
                                user.time,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: user.unreadCount > 0
                                      ? const Color(0xFF3B3B98)
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  user.lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: user.unreadCount > 0
                                        ? (Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black)
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                              if (user.unreadCount > 0)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF3B3B98),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    user.unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChatUser {
  final String name;
  final String avatar;
  final String lastMessage;
  final String time;
  final int unreadCount;

  ChatUser({
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
  });
}