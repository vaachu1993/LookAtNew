import 'package:flutter/material.dart';
import 'package:lookat_app/screens/explore/explore_screen.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../Components/BottomNavigationBarComponent.dart';
import '../../models/article_model.dart';
import '../../services/article_service.dart';
import '../../services/favorite_service.dart';
import '../../services/category_service.dart';
import '../../Utils/Utils.dart';
import '../article/article_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final ArticleService _articleService = ArticleService();
  final FavoriteService _favoriteService = FavoriteService();
  final CategoryService _categoryService = CategoryService();

  List<ArticleModel> _allArticles = []; // Tất cả articles
  List<ArticleModel> _articles = []; // Filtered articles theo category
  bool _isLoading = true;
  String? _errorMessage;

  // Track favorites by articleId -> favoriteId mapping
  Map<String, String> _favoriteIds = {};

  // Categories
  List<String> _categories = [];
  bool _isCategoriesLoading = true;

  // Current category (có thể mở rộng cho multi-category)
  String _currentCategory = 'all';

  @override
  void initState() {
    super.initState();
    Utils.selectIndex = 0; // Set current tab index
    WidgetsBinding.instance.addObserver(this);
    // Load articles trước, categories sẽ được extract từ articles
    // Điều này đảm bảo category names khớp với data thực tế
    _loadArticles(fetchRss: true);
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

    // App resume từ background → fetch RSS + articles
    if (state == AppLifecycleState.resumed) {
      _loadArticles(fetchRss: true, silent: true);
    }
  }

  /// Update categories từ articles
  /// Luôn extract từ articles để đảm bảo category names khớp với data thực tế
  void _updateCategoriesFromArticles() {
    if (_allArticles.isNotEmpty) {
      final extractedCategories = _categoryService.extractCategoriesFromArticles(_allArticles);
      if (extractedCategories.isNotEmpty) {
        setState(() {
          _categories = extractedCategories;
          _isCategoriesLoading = false;
        });
      }
    }
  }

  /// Xử lý khi chọn category
  void _onCategorySelected(String category) {
    if (_currentCategory == category) return;

    setState(() {
      _currentCategory = category;
    });

    // Filter lại từ _allArticles thay vì reload từ API
    _filterArticlesByCategory();
  }

  /// Filter articles theo category đã chọn
  void _filterArticlesByCategory() {
    setState(() {
      if (_currentCategory == 'all') {
        _articles = List.from(_allArticles);
      } else {
        _articles = _allArticles.where((article) =>
          article.category.toLowerCase() == _currentCategory.toLowerCase()
        ).toList();
      }
    });
  }

  /// Load articles với RSS fetch
  ///
  /// [fetchRss] - true = fetch RSS mới trước khi lấy articles
  /// [silent] - true = không show loading UI (background refresh)
  Future<void> _loadArticles({
    bool fetchRss = true,
    bool silent = false,
  }) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    late ArticleResponseWithRssFetch response;

    if (fetchRss) {
      // Fetch RSS mới từ nguồn rồi lấy TẤT CẢ articles
      // Không filter theo category ở API để tránh lỗi khi backend đổi tên
      response = await _articleService.fetchRssAndGetArticles(
        category: null, // Luôn lấy tất cả
      );
    } else {
      // Chỉ lấy TẤT CẢ articles (không fetch RSS)
      final articleResponse = await _articleService.getAllArticles();

      response = ArticleResponseWithRssFetch(
        articleResponse: articleResponse,
        rssFetchSuccess: false,
        articlesCount: 0,
      );
    }

    // Load favorites in parallel
    final favoritesResponse = await _favoriteService.getFavorites();

    if (mounted) {
      final articleResponse = response.articleResponse;

      if (articleResponse.isSuccess && articleResponse.articles != null) {
        // Build favorite mapping
        final favoriteMap = <String, String>{};
        if (favoritesResponse.isSuccess && favoritesResponse.favorites != null) {
          for (var fav in favoritesResponse.favorites!) {
            favoriteMap[fav.articleId] = fav.id;
          }
        }

        // Mark articles as bookmarked
        var articles = articleResponse.articles!.map((article) {
          final isFavorite = favoriteMap.containsKey(article.id);
          return article.copyWith(isBookmarked: isFavorite);
        }).toList();

        // Sắp xếp theo pubDate giảm dần (bài mới nhất trước)
        articles.sort((a, b) => b.pubDate.compareTo(a.pubDate));

        // Lưu tất cả articles
        _allArticles = articles;

        // Filter theo category hiện tại
        var filteredArticles = articles;
        if (_currentCategory != 'all') {
          filteredArticles = articles.where((article) =>
            article.category.toLowerCase() == _currentCategory.toLowerCase()
          ).toList();
        }

        setState(() {
          _articles = filteredArticles;
          _favoriteIds = favoriteMap;
          _isLoading = false;
        });

        // Update categories từ articles nếu chưa có
        _updateCategoriesFromArticles();

        // Show success message nếu RSS fetch thành công
        if (!silent && mounted && response.rssFetchSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.refresh, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đã cập nhật ${response.articlesCount} bài viết mới',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = articleResponse.error ?? 'Không thể tải bài viết';
          _isLoading = false;
        });

        // Show error nếu có
        if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage!),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
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
    // Lấy ngày hôm nay (chỉ ngày, không có giờ)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Lọc các tin tức trong ngày hôm nay
    return _articles.skip(3).where((article) {
      final publishedDate = DateTime(
        article.pubDate.year,
        article.pubDate.month,
        article.pubDate.day,
      );
      return publishedDate.isAtSameMomentAs(today);
    }).toList();
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
    );
  }

  Widget _buildLoadingState() {
    // Tạo dummy articles cho skeleton
    final dummyArticles = List.generate(
      8,
      (index) => ArticleModel(
        id: 'dummy_$index',
        title: 'Loading article title that spans multiple lines',
        description: 'Loading article description',
        thumbnail: '',
        link: '',
        source: 'Loading Source',
        pubDate: DateTime.now(),
        createdAt: DateTime.now(),
        category: 'loading',
      ),
    );

    double height = MediaQuery.of(context).size.height;

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          // Dark top section (Header + Featured News) - Background
          SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Container(
              color: const Color(0xFF0E0E12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  // Category buttons skeleton
                  Skeletonizer(
                    enabled: true,
                    child: SizedBox(
                      height: 42,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(right: index < 4 ? 12 : 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1C1E),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Category',
                                style: TextStyle(
                                  color: Color(0xFF8E8E93),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Featured news skeleton
                  Skeletonizer(
                    enabled: true,
                    child: SizedBox(
                      height: 280,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: 3,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(right: index < 2 ? 16 : 0),
                            child: _buildFeaturedNewsItem(dummyArticles[index]),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // White bottom section (Recent Stories) - DraggableScrollableSheet
          DraggableScrollableSheet(
            initialChildSize: 0.47,
            minChildSize: 0.47,
            maxChildSize: 0.9,
            snap: true,
            snapSizes: const [0.55, 0.9],
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Drag handle indicator
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Section header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tin tức gần đây',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Skeletonizer(
                            enabled: true,
                            child: Container(
                              width: 60,
                              height: 16,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE20035),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Recent stories skeleton
                    Expanded(
                      child: Skeletonizer(
                        enabled: true,
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: 5,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index < 4 ? 16 : 80,
                              ),
                              child: _buildRecentStoryItem(dummyArticles[index + 3]),
                            );
                          },
                        ),
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
              onPressed: () => _loadArticles(fetchRss: true),
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
            Text(
              _currentCategory == 'all'
                ? 'No articles available'
                : 'No articles in "${_getCategoryLabel(_currentCategory)}"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentCategory == 'all'
                ? 'Pull down to refresh or check back later'
                : 'Try selecting a different category or refresh',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_currentCategory != 'all')
                  ElevatedButton(
                    onPressed: () => _onCategorySelected('all'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (_currentCategory != 'all')
                  const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    // Reset về 'all' và force refresh
                    setState(() {
                      _currentCategory = 'all';
                    });
                    _loadArticles(fetchRss: true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE20035),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: () => _loadArticles(fetchRss: true),
      color: const Color(0xFFE20035),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Dark top section (Header + Featured News) - Background
            SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Container(
                color: const Color(0xFF0E0E12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    // Category buttons
                    if (!_isCategoriesLoading && _categories.isNotEmpty)
                      _buildCategoryButtons(),
                    if (!_isCategoriesLoading && _categories.isNotEmpty)
                      const SizedBox(height: 16),
                    if (_featuredArticles.isNotEmpty) _buildFeaturedNews(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // White bottom section (Recent Stories) - DraggableScrollableSheet
            DraggableScrollableSheet(
              initialChildSize: 0.47, // Bắt đầu ở 35% màn hình (thấp hơn)
              minChildSize: 0.47, // Tối thiểu 35% (cố định ở vị trí này khi kéo xuống)
              maxChildSize: 0.9, // Tối đa 90%
              snap: true,
              snapSizes: const [0.47, 0.9], // Các vị trí snap
              builder: (context, scrollController) {
                return _buildRecentStories(scrollController);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Format current date
    final now = DateTime.now();
    final days = ['Thứ hai', 'Thứ ba', 'Thứ tư', 'Thứ năm', 'Thứ sáu', 'Thứ bảy', 'Chủ nhật'];
    final months = ['Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
                    'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'];
    final dayName = days[now.weekday - 1];
    final monthName = months[now.month - 1];
    final dateString = '$dayName, Ngày ${now.day} ${monthName} Năm ${now.year}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            'Tin tức hôm nay',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            dateString,
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButtons() {
    // Thêm "Tất cả" vào đầu danh sách
    final allCategories = ['all', ..._categories];

    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: allCategories.length,
        itemBuilder: (context, index) {
          final category = allCategories[index];
          final isSelected = _currentCategory == category;

          return Padding(
            padding: EdgeInsets.only(right: index < allCategories.length - 1 ? 12 : 0),
            child: _buildCategoryButton(
              label: _getCategoryLabel(category),
              isSelected: isSelected,
              onTap: () => _onCategorySelected(category),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE20035) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFE20035) : const Color(0xFF3A3A3C),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF8E8E93),
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  String _getCategoryLabel(String category) {
    if (category == 'all') return 'Tất cả';

    // Viết hoa chữ cái đầu
    return category[0].toUpperCase() + category.substring(1);
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
      onTap: () async {
        final updatedArticle = await Navigator.push<ArticleModel>(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleDetailScreen(article: article),
          ),
        );

        // Update article state if bookmark changed
        if (updatedArticle != null && updatedArticle.isBookmarked != article.isBookmarked) {
          setState(() {
            final index = _articles.indexWhere((a) => a.id == updatedArticle.id);
            if (index != -1) {
              _articles[index] = updatedArticle;
            }
            final allIndex = _allArticles.indexWhere((a) => a.id == updatedArticle.id);
            if (allIndex != -1) {
              _allArticles[allIndex] = updatedArticle;
            }

            // Update favorite IDs map
            if (updatedArticle.isBookmarked) {
              // Article is now bookmarked, we should have the favoriteId
              // This will be managed by the detail screen
            } else {
              // Article is no longer bookmarked
              _favoriteIds.remove(updatedArticle.id);
            }
          });
        }
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

  Widget _buildRecentStories(ScrollController scrollController) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle indicator
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tin tức gần đây',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ExploreScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Xem tất cả',
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
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Chưa có tin tức mới trong ngày',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kéo xuống để làm mới',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
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
      onTap: () async {
        final updatedArticle = await Navigator.push<ArticleModel>(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleDetailScreen(article: article),
          ),
        );

        // Update article state if bookmark changed
        if (updatedArticle != null && updatedArticle.isBookmarked != article.isBookmarked) {
          setState(() {
            final index = _articles.indexWhere((a) => a.id == updatedArticle.id);
            if (index != -1) {
              _articles[index] = updatedArticle;
            }
            final allIndex = _allArticles.indexWhere((a) => a.id == updatedArticle.id);
            if (allIndex != -1) {
              _allArticles[allIndex] = updatedArticle;
            }

            // Update favorite IDs map
            if (updatedArticle.isBookmarked) {
              // Article is now bookmarked
            } else {
              // Article is no longer bookmarked
              _favoriteIds.remove(updatedArticle.id);
            }
          });
        }
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
    return const BottomNavigationBarComponent();
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

