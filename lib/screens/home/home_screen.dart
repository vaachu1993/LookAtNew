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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final FeedService _feedService = FeedService();
  final FavoriteService _favoriteService = FavoriteService();

  List<ArticleModel> _articles = [];
  bool _isLoading = true;
  bool _isLoadingFromCache = false;
  String? _errorMessage;
  String? _cacheWarning;

  // Track favorites by articleId -> favoriteId mapping
  Map<String, String> _favoriteIds = {};

  // Current category (có thể mở rộng cho multi-category)
  String _currentCategory = 'all';

  // Flag to check if need to fetch RSS after login
  bool _hasCheckedLoginFlag = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadFeed(forceRefresh: false); // Cold start - check cache first
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check arguments once after login
    if (!_hasCheckedLoginFlag) {
      _hasCheckedLoginFlag = true;
      _checkLoginFlag();
    }
  }

  /// Check nếu user vừa login và cần fetch RSS
  void _checkLoginFlag() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args['shouldFetchRss'] == true) {
      // User vừa login → Fetch RSS ngay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _loadFeed(forceRefresh: true); // Fetch RSS + get feed
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // App resume từ background
    if (state == AppLifecycleState.resumed) {
      _handleAppResume();
    }
  }

  /// Xử lý khi app resume từ background
  Future<void> _handleAppResume() async {
    // Kiểm tra có cần fetch không dựa trên thời gian
    final shouldFetch = await _feedService.shouldFetchOnResume(_currentCategory);

    if (shouldFetch) {
      // >= 10 phút → fetch mới
      await _loadFeed(forceRefresh: true, silent: true);
    }
    // < 5 phút → không làm gì, dùng cache hiện tại
  }

  /// Load feed với cache logic
  ///
  /// [forceRefresh] - true = pull-to-refresh (fetch RSS + get feed), false = check cache
  /// [silent] - true = không show loading UI (background refresh)
  Future<void> _loadFeed({
    bool forceRefresh = false,
    bool silent = false,
  }) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _cacheWarning = null;
      });
    }

    // Load feed with RSS fetch logic
    // forceRefresh = true → Fetch RSS mới từ nguồn rồi get feed
    // forceRefresh = false → Chỉ get feed (dùng cache nếu có)
    late dynamic response;

    if (forceRefresh) {
      // Pull-to-refresh → Fetch RSS mới rồi get feed
      response = await _feedService.fetchRssAndGetFeed(
        category: _currentCategory,
        silent: silent,
      );
    } else {
      // Cold start hoặc background refresh → Chỉ get feed từ database
      final feedResponse = await _feedService.getFeed(
        category: _currentCategory,
        forceRefresh: false,
      );
      // Wrap vào response tương tự
      response = _FeedLoadResult(
        feedResponse: feedResponse,
        rssFetchSuccess: false,
      );
    }

    // Load favorites in parallel
    final favoritesResponse = await _favoriteService.getFavorites();

    // Extract feedResponse
    final feedResponse = response is FeedResponseWithRssFetch
        ? response.feedResponse
        : (response as _FeedLoadResult).feedResponse;

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
          _isLoadingFromCache = feedResponse.fromCache;
          _cacheWarning = feedResponse.cacheWarning;
        });

        // Show appropriate indicator
        if (!silent && mounted) {
          if (response is FeedResponseWithRssFetch && response.rssFetchSuccess) {
            // RSS fetch thành công - show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.refresh, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${response.articlesCount} new articles fetched',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.green.shade700,
              ),
            );
          } else if (feedResponse.fromCache) {
            // Dùng cache - show cache indicator
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.offline_bolt, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feedResponse.cacheWarning ?? 'Showing cached articles',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.orange.shade700,
              ),
            );
          }
        }
      } else {
        setState(() {
          _errorMessage = feedResponse.error ?? 'Failed to load feed';
          _isLoading = false;
          _isLoadingFromCache = false;
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
                    color: Color(article.placeholderColor).withValues(alpha: 0.3),
                    child: article.hasThumbnail
                        ? Image.network(
                            article.thumbnail,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: Colors.white.withValues(alpha: 0.5),
                                  strokeWidth: 2,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholder(article);
                            },
                          )
                        : _buildPlaceholder(article),
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
                  color: Color(article.placeholderColor).withValues(alpha: 0.2),
                  child: article.hasThumbnail
                      ? Image.network(
                          article.thumbnail,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: Color(article.placeholderColor).withValues(alpha: 0.5),
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              _getCategoryIcon(article.category),
                              color: Color(article.placeholderColor).withValues(alpha: 0.5),
                              size: 32,
                            );
                          },
                        )
                      : Icon(
                          _getCategoryIcon(article.category),
                          color: Color(article.placeholderColor).withValues(alpha: 0.5),
                          size: 32,
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

  /// Build placeholder khi không có thumbnail
  Widget _buildPlaceholder(ArticleModel article) {
    return Container(
      color: Color(article.placeholderColor).withValues(alpha: 0.2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getCategoryIcon(article.category),
            color: Color(article.placeholderColor).withValues(alpha: 0.7),
            size: 48,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              article.category.toUpperCase(),
              style: TextStyle(
                color: Color(article.placeholderColor),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Get icon dựa trên category
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'technology':
        return Icons.computer;
      case 'business':
        return Icons.business_center;
      case 'sports':
        return Icons.sports_soccer;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.health_and_safety;
      case 'science':
        return Icons.science;
      case 'politics':
        return Icons.account_balance;
      default:
        return Icons.article;
    }
  }
}

/// Helper class để wrap FeedResponse khi không fetch RSS
class _FeedLoadResult {
  final FeedResponse feedResponse;
  final bool rssFetchSuccess;

  _FeedLoadResult({
    required this.feedResponse,
    required this.rssFetchSuccess,
  });
}
