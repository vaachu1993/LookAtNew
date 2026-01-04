import 'package:flutter/material.dart';
import '../../Components/BottomNavigationBarComponent.dart';
import '../../models/favorite_model.dart';
import '../../models/article_model.dart';
import '../../services/favorite_service.dart';
import '../../services/article_service.dart';
import '../../services/category_service.dart';
import '../../Utils/Utils.dart';
import '../article/article_detail_screen.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FavoriteService _favoriteService = FavoriteService();
  final ArticleService _articleService = ArticleService();
  final CategoryService _categoryService = CategoryService();

  List<FavoriteModel> _favorites = [];
  List<FavoriteModel> _filteredFavorites = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Categories
  List<String> _categories = [];
  String _currentCategory = 'all';

  @override
  void initState() {
    super.initState();
    Utils.selectIndex = 2; // Set current tab index
    _tabController = TabController(length: 2, vsync: this);
    _loadFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _favoriteService.getFavorites();

    if (mounted) {
      if (response.isSuccess) {
        // Sort by createdAt (newest first)
        final sortedFavorites = List<FavoriteModel>.from(response.favorites ?? []);
        sortedFavorites.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Enrich favorites with category from database
        await _enrichFavoritesWithCategory(sortedFavorites);

        setState(() {
          _favorites = sortedFavorites;
          _filteredFavorites = _favorites;
          _isLoading = false;
        });
        // Extract categories from favorites
        _updateCategoriesFromFavorites();
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Failed to load favorites';
          _isLoading = false;
        });
      }
    }
  }

  /// Enrich favorites with category data from database
  Future<void> _enrichFavoritesWithCategory(List<FavoriteModel> favorites) async {
    for (int i = 0; i < favorites.length; i++) {
      final favorite = favorites[i];
      if (favorite.article != null && favorite.article!.id.isNotEmpty) {
        try {
          final response = await _articleService.getArticleById(favorite.article!.id);
          if (response.isSuccess && response.article != null && response.article!.category.isNotEmpty) {
            // Create new ArticleModel with category from database
            final enrichedArticle = ArticleModel(
              id: favorite.article!.id,
              title: favorite.article!.title,
              description: favorite.article!.description,
              thumbnail: favorite.article!.thumbnail,
              link: favorite.article!.link,
              source: favorite.article!.source,
              category: response.article!.category, // ✅ Get category from database
              pubDate: favorite.article!.pubDate,
              createdAt: favorite.article!.createdAt,
            );

            // Create new FavoriteModel with enriched article
            favorites[i] = FavoriteModel(
              id: favorite.id,
              articleId: favorite.articleId,
              userId: favorite.userId,
              createdAt: favorite.createdAt,
              article: enrichedArticle,
            );
          }
        } catch (e) {
          // Silently fail for individual articles
          debugPrint('Failed to enrich article ${favorite.article!.id}: $e');
        }
      }
    }
  }

  /// Extract categories from favorites
  void _updateCategoriesFromFavorites() {
    if (_favorites.isNotEmpty) {
      final articlesWithData = _favorites.where((f) => f.article != null).toList();
      final articles = articlesWithData.map((f) => f.article!).toList();
      final extractedCategories = _categoryService.extractCategoriesFromArticles(articles);

      if (extractedCategories.isNotEmpty) {
        setState(() {
          _categories = extractedCategories;
        });
      }
    }
  }

  /// Handle category selection
  void _onCategorySelected(String category) {
    if (_currentCategory == category) return;

    setState(() {
      _currentCategory = category;
    });

    _filterFavoritesByCategory();
  }

  /// Filter favorites by category
  void _filterFavoritesByCategory() {
    setState(() {
      if (_currentCategory == 'all') {
        _filteredFavorites = List.from(_favorites);
      } else {
        _filteredFavorites = _favorites.where((favorite) {
          if (favorite.article == null) return false;
          return favorite.article!.category.toLowerCase() == _currentCategory.toLowerCase();
        }).toList();
      }
    });
  }

  /// Get category label
  String _getCategoryLabel(String category) {
    if (category == 'all') return 'Tất cả';
    // Capitalize first letter
    return category[0].toUpperCase() + category.substring(1);
  }

  Future<void> _removeFavorite(FavoriteModel favorite) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa dấu trang'),
        content: const Text('Bạn có chắc chắn muốn xóa bài viết này khỏi mục đánh dấu lưu trữ của mình không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy bỏ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE20035),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Optimistic UI update
      setState(() {
        _favorites.removeWhere((f) => f.id == favorite.id);
        _filteredFavorites.removeWhere((f) => f.id == favorite.id);
      });
      // Update categories
      _updateCategoriesFromFavorites();

      final response = await _favoriteService.removeFavorite(favorite.id);

      if (!response.isSuccess) {
        // Revert on error
        setState(() {
          _favorites.add(favorite);
        });
        _updateCategoriesFromFavorites();
        _filterFavoritesByCategory();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error ?? 'Failed to remove favorite')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lưu trữ',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadFavorites,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE20035),
        ),
      )
          : _errorMessage != null
          ? _buildErrorState()
          : _favorites.isEmpty
          ? _buildEmptyState()
          : _buildBookmarksContent(),
      bottomNavigationBar: const BottomNavigationBarComponent(),
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
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadFavorites,
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
            Icon(
              Icons.bookmark_border,
              color: Colors.grey[400],
              size: 80,
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có dấu trang nào',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lưu lại những bài viết bạn thích bằng cách nhấn vào biểu tượng trái tim.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarksContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category buttons
        if (_categories.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Danh mục',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildCategoryButtons(),
          const SizedBox(height: 8),
        ],

        // Article count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Text(
            '${_filteredFavorites.length} bài đã lưu',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF8E8E93),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Bookmarks list
        Expanded(
          child: _buildBookmarksList(),
        ),
      ],
    );
  }

  Widget _buildCategoryButtons() {
    // Thêm "Tất cả" vào đầu danh sách
    final allCategories = ['all', ..._categories];

    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
            color: isSelected ? const Color(0xFFE20035) : const Color(0xFFE0E0E0),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookmarksList() {
    return RefreshIndicator(
      onRefresh: _loadFavorites,
      color: const Color(0xFFE20035),
      child: _filteredFavorites.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            _currentCategory == 'all'
                ? 'Chưa có bookmark nào'
                : 'Không có bài báo ${_getCategoryLabel(_currentCategory)}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredFavorites.length,
        itemBuilder: (context, index) {
          final favorite = _filteredFavorites[index];
          return _buildBookmarkItem(favorite);
        },
      ),
    );
  }

  Widget _buildBookmarkItem(FavoriteModel favorite) {
    // If favorite has article data, use it
    final article = favorite.article;

    if (article == null) {
      // Fallback if article data is not included
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Thông tin bài viết không có sẵn',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: () => _removeFavorite(favorite),
            ),
          ],
        ),
      );
    }

    return Dismissible(
      key: Key(favorite.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE20035),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 28,
        ),
      ),
      onDismissed: (direction) => _removeFavorite(favorite),
      child: _buildArticleCard(article, favorite),
    );
  }

  Widget _buildArticleCard(ArticleModel article, FavoriteModel favorite) {
    return GestureDetector(
      onTap: () async {
        final updatedArticle = await Navigator.push<ArticleModel>(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleDetailScreen(article: article),
          ),
        );

        // If article was unbookmarked, remove it from local list smoothly
        if (updatedArticle != null && !updatedArticle.isBookmarked) {
          setState(() {
            _favorites.removeWhere((f) => f.id == favorite.id);
            _filteredFavorites.removeWhere((f) => f.id == favorite.id);
            // Update categories after removal
            _updateCategoriesFromFavorites();
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article image
            if (article.thumbnail.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Container(
                  width: double.infinity,
                  height: 180,
                  color: Colors.grey[300],
                  child: Image.network(
                    article.thumbnail,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            color: Colors.grey,
                            size: 50,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source and category
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE20035).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          article.category,
                          style: const TextStyle(
                            color: Color(0xFFE20035),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          article.source,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    article.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Meta info and actions
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        article.timeAgo,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('•', style: TextStyle(color: Colors.grey)),
                      const SizedBox(width: 8),
                      Text(
                        article.readTime,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      // Delete button
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.grey[600],
                        iconSize: 20,
                        onPressed: () => _removeFavorite(favorite),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
