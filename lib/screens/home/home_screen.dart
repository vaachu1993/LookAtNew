import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Fake data for featured news
  final List<Map<String, dynamic>> featuredNews = [
    {
      'image': 'https://images.unsplash.com/photo-1495020689067-958852a7765e?w=600&h=400&fit=crop',
      'publisher': 'BBC News',
      'title': 'Government Introduces New Legislation to Combat Climate Change',
      'timeAgo': '1 day ago',
      'readTime': '4 min read',
    },
    {
      'image': 'https://images.unsplash.com/photo-1523995462485-3d171b5c8fa9?w=600&h=400&fit=crop',
      'publisher': 'BBC News',
      'title': 'Opposition Party Launches Inquiry into Alleged Interference',
      'timeAgo': '1 day ago',
      'readTime': '4 min read',
    },
    {
      'image': 'https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=600&h=400&fit=crop',
      'publisher': 'CNN News',
      'title': 'Tech Giants Announce Major Investment in AI Research',
      'timeAgo': '2 days ago',
      'readTime': '5 min read',
    },
  ];

  // Fake data for recent stories
  final List<Map<String, dynamic>> recentStories = [
    {
      'image': 'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=200&h=200&fit=crop',
      'publisher': 'FOX News',
      'title': 'Global Markets React to Central Bank\'s Interest Rate Decision',
      'timeAgo': '1 day ago',
      'readTime': '4 min read',
    },
    {
      'image': 'https://images.unsplash.com/photo-1473341304170-971dccb5ac1e?w=200&h=200&fit=crop',
      'publisher': 'Reuters',
      'title': 'Scientists Discover Breakthrough in Renewable Energy Storage',
      'timeAgo': '2 days ago',
      'readTime': '6 min read',
    },
    {
      'image': 'https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=200&h=200&fit=crop',
      'publisher': 'The Guardian',
      'title': 'International Summit Addresses Global Food Security Crisis',
      'timeAgo': '3 days ago',
      'readTime': '5 min read',
    },
  ];

  void _onItemTapped(int index) async {
    // Navigate to profile screen when Account tab is tapped
    if (index == 4) {
      // Check if user is logged in before navigating to profile
      final authService = AuthService();
      final isLoggedIn = await authService.isLoggedIn();

      if (!isLoggedIn) {
        // Not logged in, redirect to login
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Vui lòng đăng nhập để xem thông tin tài khoản'),
            backgroundColor: Colors.orange.shade900,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        return;
      }

      // User is logged in, navigate to profile
      if (!mounted) return;
      Navigator.of(context).pushNamed('/profile');
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E12),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Dark top section (Header + Featured News) - Fixed height
            Container(
              color: const Color(0xFF0E0E12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildFeaturedNews(),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // White bottom section (Recent Stories) - Takes remaining space
            Expanded(
              child: _buildRecentStories(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Handle FAB tap
        },
        backgroundColor: const Color(0xFFE20035),
        child: const Icon(
          Icons.edit,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Menu icon - small and compact
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE20035),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.menu,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 24),

          // Title
          const Text(
            'Must you know today',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Date
          const Text(
            'Monday January 16, 2024',
            style: TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedNews() {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: featuredNews.length,
        itemBuilder: (context, index) {
          final news = featuredNews[index];
          return Padding(
            padding: EdgeInsets.only(right: index < featuredNews.length - 1 ? 16 : 0),
            child: _buildFeaturedNewsItem(news),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedNewsItem(Map<String, dynamic> news) {
    return SizedBox(
      width: 230,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image - large, rounded corners, no overlay
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 230,
              height: 160,
              color: Colors.grey[800],
              child: Image.network(
                news['image'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.image,
                      color: Colors.grey,
                      size: 50,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Publisher logo + name
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Color(0xFFE20035),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.article,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                news['publisher'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Title - 2 lines max
          Text(
            news['title'],
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),

          // Meta info
          Row(
            children: [
              Text(
                news['timeAgo'],
                style: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '•',
                style: TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                news['readTime'],
                style: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentStories() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,

      ),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Stories',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Handle view all tap
                  },
                  child: const Text(
                    'View all',
                    style: TextStyle(
                      color: Color(0xFFE20035),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Recent stories list - scrollable
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: recentStories.length,
              itemBuilder: (context, index) {
                final story = recentStories[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < recentStories.length - 1 ? 16 : 80,
                  ),
                  child: _buildRecentStoryItem(story),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentStoryItem(Map<String, dynamic> story) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Publisher logo/avatar
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              story['publisher'][0].toUpperCase(),
              style: const TextStyle(
                color: Color(0xFFE20035),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Content (publisher name, title, meta)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Publisher name
              Text(
                story['publisher'],
                style: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),

              // Title
              Text(
                story['title'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),

              // Meta info
              Row(
                children: [
                  Text(
                    story['timeAgo'],
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '•',
                    style: TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    story['readTime'],
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        // Thumbnail
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 90,
            height: 90,
            color: Colors.grey[300],
            child: Image.network(
              story['image'],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.image,
                    color: Colors.grey,
                    size: 30,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFE20035),
        unselectedItemColor: const Color(0xFF8E8E93),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            label: 'Bookmark',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

