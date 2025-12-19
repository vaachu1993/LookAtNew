import 'package:flutter/material.dart';
import '../../widgets/common_bottom_nav_bar.dart';
import '../../models/article_model.dart';
import '../../services/feed_service.dart';
import '../../services/favorite_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FeedService _feedService = FeedService();
  final FavoriteService _favoriteService = FavoriteService();

  List<ArticleModel> _articles = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Track favorites by articleId -> favoriteId mapping
  Map<String, String> _favoriteIds = {};

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Load feed and favorites in parallel
    final feedResponse = await _feedService.getFeed();
    final favoritesResponse = await _favoriteService.getFavorites();

    if (mounted) {
      if (feedResponse.isSuccess) {
        // Build favorite mapping
        final favoriteMap = <String, String>{};
        if (favoritesResponse.isSuccess && favoritesResponse.favorites != null) {
          for (var fav in favoritesResponse.favorites!) {
            favoriteMap[fav.articleId] = fav.id;
          }
        }

        // Mark articles as bookmarked
        final articles = feedResponse.articles!.map((article) {
          final isFavorite = favoriteMap.containsKey(article.id);
          return article.copyWith(isBookmarked: isFavorite);
        }).toList();

        setState(() {
          _articles = articles;
          _favoriteIds = favoriteMap;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = feedResponse.error ?? 'Failed to load feed';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite(ArticleModel article) async {
    final isCurrentlyFavorite = article.isBookmarked;

    // Optimistic UI update
    setState(() {
      final index = _articles.indexWhere((a) => a.id == article.id);
      if (index != -1) {
        _articles[index] = article.copyWith(isBookmarked: !isCurrentlyFavorite);
      }
    });

    if (isCurrentlyFavorite) {
      // Remove favorite
      final favoriteId = _favoriteIds[article.id];
      if (favoriteId != null) {
        final response = await _favoriteService.removeFavorite(favoriteId);
        if (response.isSuccess) {
          setState(() {
            _favoriteIds.remove(article.id);
          });
        } else {
          // Revert on error
          setState(() {
            final index = _articles.indexWhere((a) => a.id == article.id);
            if (index != -1) {
              _articles[index] = article.copyWith(isBookmarked: true);
            }
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response.error ?? 'Failed to remove favorite')),
            );
          }
        }
      }
    } else {
      // Add favorite
      final response = await _favoriteService.addFavorite(article.id);
      if (response.isSuccess && response.favorite != null) {
        setState(() {
          _favoriteIds[article.id] = response.favorite!.id;
        });
      } else {
        // Revert on error
        setState(() {
          final index = _articles.indexWhere((a) => a.id == article.id);
          if (index != -1) {
            _articles[index] = article.copyWith(isBookmarked: false);
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error ?? 'Failed to add favorite')),
          );
        }
      }
    }
  }

  List<ArticleModel> get _featuredArticles {
    return _articles.take(3).toList();
  }

  List<ArticleModel> get _recentArticles {
    return _articles.skip(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E12),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _articles.isEmpty
                  ? _buildEmptyState()
                  : _buildContent(),
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

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFFE20035),
          ),
          SizedBox(height: 16),
          Text(
            'Loading feed...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFFE20035),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadFeed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE20035),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inbox_outlined,
              color: Colors.grey,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'No articles available',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check back later for new content',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadFeed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE20035),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text(
                'Refresh',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadFeed,
      color: const Color(0xFFE20035),
      child: SafeArea(
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
                  if (_featuredArticles.isNotEmpty) _buildFeaturedNews(),
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
        itemCount: _featuredArticles.length,
        itemBuilder: (context, index) {
          final article = _featuredArticles[index];
          return Padding(
            padding: EdgeInsets.only(right: index < _featuredArticles.length - 1 ? 16 : 0),
            child: _buildFeaturedNewsItem(article),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedNewsItem(ArticleModel article) {
    return GestureDetector(
      onTap: () {
        // Navigate to article detail or open link
      },
      child: SizedBox(
        width: 230,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with bookmark icon
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 230,
                    height: 160,
                    color: Colors.grey[800],
                    child: article.thumbnail.isNotEmpty
                        ? Image.network(
                            article.thumbnail,
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
                          )
                        : Container(
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.article,
                              color: Colors.grey,
                              size: 50,
                            ),
                          ),
                  ),
                ),
                // Bookmark button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(article),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        article.isBookmarked ? Icons.favorite : Icons.favorite_border,
                        color: article.isBookmarked ? const Color(0xFFE20035) : Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
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
                Expanded(
                  child: Text(
                    article.source,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Title - 2 lines max
            Text(
              article.title,
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
                Expanded(
                  child: Text(
                    article.timeAgo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 11,
                    ),
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
                  article.readTime,
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
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
            child: _recentArticles.isEmpty
                ? const Center(
                    child: Text(
                      'No recent stories available',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _recentArticles.length,
                    itemBuilder: (context, index) {
                      final article = _recentArticles[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < _recentArticles.length - 1 ? 16 : 80,
                        ),
                        child: _buildRecentStoryItem(article),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentStoryItem(ArticleModel article) {
    return GestureDetector(
      onTap: () {
        // Navigate to article detail or open link
      },
      child: Row(
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
                article.source.isNotEmpty
                    ? article.source[0].toUpperCase()
                    : 'N',
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
                  article.source,
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),

                // Title
                Text(
                  article.title,
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
                    Expanded(
                      child: Text(
                        article.timeAgo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 10,
                        ),
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
                      article.readTime,
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

          // Thumbnail with bookmark icon
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 90,
                  height: 90,
                  color: Colors.grey[300],
                  child: article.thumbnail.isNotEmpty
                      ? Image.network(
                          article.thumbnail,
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
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.article,
                            color: Colors.grey,
                            size: 30,
                          ),
                        ),
                ),
              ),
              // Bookmark button
              Positioned(
                bottom: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _toggleFavorite(article),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      article.isBookmarked ? Icons.favorite : Icons.favorite_border,
                      color: article.isBookmarked ? const Color(0xFFE20035) : Colors.grey,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return CommonBottomNavBar(
      currentIndex: 0, // Home tab active
    );
  }
}

