import 'package:flutter/material.dart';
import '../../widgets/common_bottom_nav_bar.dart';
import '../../Utils/Utils.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  late AnimationController _animationController;
  late Animation<Color?> _backgroundColorAnimation;
  late Animation<Color?> _borderColorAnimation;

  // Recent search data
  final List<String> _recentSearches = ['politics', 'policy', 'critism'];

  // Trending news data
  final List<Map<String, dynamic>> _trendingNews = [
    {
      'rank': '01',
      'source': 'CNN News',
      'sourceIcon': Icons.circle,
      'title': 'New Breakthrough in Quantum Computing Promises Unprecedented...',
      'timeAgo': '1 day ago',
      'readTime': '4 min read',
    },
    {
      'rank': '02',
      'source': 'CNBC News',
      'sourceIcon': Icons.circle,
      'title': 'Study Suggests Link Between Gut Microbiome and Mental Health Diso...',
      'timeAgo': '1 day ago',
      'readTime': '4 min read',
    },
    {
      'rank': '03',
      'source': 'FOX News',
      'sourceIcon': Icons.circle,
      'title': 'Global Markets React to Central Bank\'s Interest Rate Decision',
      'timeAgo': '1 day ago',
      'readTime': '4 min read',
    },
  ];

  // Search results data
  final List<Map<String, dynamic>> _searchResults = [
    {
      'source': 'FOX News',
      'sourceIcon': Icons.circle,
      'title': 'Geopolitical Tensions Escalate as Ukra[ine-Russia...',
      'highlight': 'Ukra',
      'timeAgo': '1 day ago',
      'readTime': '4 min read',
      'thumbnail': 'https://images.unsplash.com/photo-1495020689067-958852a7765e?w=200&h=150&fit=crop',
    },
    {
      'source': 'FOX News',
      'sourceIcon': Icons.circle,
      'title': 'Ukra[ine Implements Economic Reforms to Stren...',
      'highlight': 'Ukra',
      'timeAgo': '1 day ago',
      'readTime': '4 min read',
      'thumbnail': 'https://images.unsplash.com/photo-1523995462485-3d171b5c8fa9?w=200&h=150&fit=crop',
    },
    {
      'source': 'FOX News',
      'sourceIcon': Icons.circle,
      'title': 'Geopolitical Tensions Escalate as Ukra[ine-Russia...',
      'highlight': 'Ukra',
      'timeAgo': '1 day ago',
      'readTime': '4 min read',
      'thumbnail': 'https://images.unsplash.com/photo-1495020689067-958852a7765e?w=200&h=150&fit=crop',
    },
  ];

  @override
  void initState() {
    super.initState();
    Utils.selectIndex = 1; // Set current tab index

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Background color animation
    _backgroundColorAnimation = ColorTween(
      begin: const Color(0xFFF5F5F5), // Light gray
      end: const Color(0xFFFFE8EC), // Light red/pink
    ).animate(_animationController);

    // Border color animation
    _borderColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: const Color(0xFFE20035), // Red border
    ).animate(_animationController);

    // Listen to focus changes
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearching = _searchFocusNode.hasFocus;
        if (_isSearching) {
          _animationController.forward();
        } else {
          if (_searchController.text.isEmpty) {
            _animationController.reverse();
          }
        }
      });
    });

    // Listen to text changes
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _isSearching = false;
    });
  }

  void _removeRecentSearch(String search) {
    setState(() {
      _recentSearches.remove(search);
    });
  }

  void _clearAllRecentSearches() {
    setState(() {
      _recentSearches.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar section
            _buildSearchBar(),

            // Content section
            Expanded(
              child: _isSearching || _searchController.text.isNotEmpty
                  ? _buildSearchResults()
                  : _buildIdleContent(),
            ),
          ],
        ),
      ),
      floatingActionButton: !_isSearching && _searchController.text.isEmpty
          ? FloatingActionButton(
              onPressed: () {
                // Handle FAB action
              },
              backgroundColor: const Color(0xFFE20035),
              child: const Icon(
                Icons.edit,
                color: Colors.white,
              ),
            )
          : null,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              color: _backgroundColorAnimation.value,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _borderColorAnimation.value ?? Colors.transparent,
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 16,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF8E8E93),
                ),
                suffixIcon: (_isSearching || _searchController.text.isNotEmpty)
                    ? IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Color(0xFF8E8E93),
                        ),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIdleContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Search Section
          if (_recentSearches.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Search',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearAllRecentSearches,
                    child: const Text(
                      'Clear all',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFE20035),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildRecentSearchChips(),
            const SizedBox(height: 24),
          ],

          // Trending on Headnews Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Trending on Headnews',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Handle view all
                  },
                  child: const Text(
                    'View all',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFE20035),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildTrendingList(),
        ],
      ),
    );
  }

  Widget _buildRecentSearchChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _recentSearches.map((search) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    search,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _removeRecentSearch(search),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrendingList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _trendingNews.length,
      itemBuilder: (context, index) {
        final news = _trendingNews[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildTrendingItem(news),
        );
      },
    );
  }

  Widget _buildTrendingItem(Map<String, dynamic> news) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rank number
        SizedBox(
          width: 40,
          child: Text(
            news['rank'],
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.grey.withValues(alpha: 0.3),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Source with icon
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE20035),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      news['sourceIcon'],
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    news['source'],
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8E8E93),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                news['title'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),

              // Meta info
              Row(
                children: [
                  Text(
                    news['timeAgo'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '•',
                    style: TextStyle(
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    news['readTime'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildSearchResultItem(result),
        );
      },
    );
  }

  Widget _buildSearchResultItem(Map<String, dynamic> result) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Source with icon
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0066CC),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      result['sourceIcon'],
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    result['source'],
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8E8E93),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.more_vert,
                    color: Color(0xFF8E8E93),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Title with highlight
              _buildHighlightedTitle(result['title'], result['highlight']),
              const SizedBox(height: 8),

              // Meta info
              Row(
                children: [
                  Text(
                    result['timeAgo'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '•',
                    style: TextStyle(
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    result['readTime'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Thumbnail
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 90,
            height: 90,
            color: Colors.grey[300],
            child: Image.network(
              result['thumbnail'],
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

  Widget _buildHighlightedTitle(String title, String highlight) {
    final parts = title.split(highlight);
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black,
          height: 1.3,
        ),
        children: [
          TextSpan(text: parts[0]),
          TextSpan(
            text: highlight,
            style: const TextStyle(
              color: Color(0xFFE20035),
            ),
          ),
          if (parts.length > 1) TextSpan(text: parts[1]),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return const CommonBottomNavBar();
  }
}

