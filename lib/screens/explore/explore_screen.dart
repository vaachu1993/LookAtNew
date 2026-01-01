import 'package:flutter/material.dart';
import '../../Components/BottomNavigationBarComponent.dart';
import '../../Utils/Utils.dart';
import '../../models/article_model.dart';
import '../../services/article_service.dart';
import '../../services/category_service.dart';
import '../article/article_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  final ArticleService _articleService = ArticleService();
  final CategoryService _categoryService = CategoryService();

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  late AnimationController _animationController;
  late Animation<Color?> _backgroundColorAnimation;
  late Animation<Color?> _borderColorAnimation;

  // Article data
  List<ArticleModel> _allArticles = [];
  List<ArticleModel> _filteredArticles = [];
  List<ArticleModel> _searchResults = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Categories
  List<String> _categories = [];
  String _currentCategory = 'all';

  // Recent search data (stored locally)
  final List<String> _recentSearches = [];

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
      _performSearch(_searchController.text);
    });

    // Load articles
    _loadArticles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Load all articles from API
  Future<void> _loadArticles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _articleService.getAllArticles();

    if (response.isSuccess && response.articles != null && response.articles!.isNotEmpty) {
      // Sort by pubDate (newest first)
      final sortedArticles = List<ArticleModel>.from(response.articles!);
      sortedArticles.sort((a, b) => b.pubDate.compareTo(a.pubDate));

      setState(() {
        _allArticles = sortedArticles;
        _filteredArticles = sortedArticles;
        _isLoading = false;
      });

      // Extract categories from articles
      _updateCategoriesFromArticles();
    } else {
      setState(() {
        _errorMessage = response.error ?? 'Không thể tải bài viết';
        _isLoading = false;
      });
    }
  }

  /// Update categories from articles
  void _updateCategoriesFromArticles() {
    if (_allArticles.isNotEmpty) {
      final extractedCategories = _categoryService.extractCategoriesFromArticles(_allArticles);
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

    _filterArticlesByCategory();
  }

  /// Filter articles by category
  void _filterArticlesByCategory() {
    setState(() {
      if (_currentCategory == 'all') {
        _filteredArticles = List.from(_allArticles);
      } else {
        _filteredArticles = _allArticles.where((article) =>
          article.category.toLowerCase() == _currentCategory.toLowerCase()
        ).toList();
      }
    });
  }

  /// Perform search on articles
  void _performSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _searchResults = [];
      } else {
        final lowerQuery = query.toLowerCase();
        _searchResults = _allArticles.where((article) {
          final titleMatch = article.title.toLowerCase().contains(lowerQuery);

          return titleMatch;
        }).toList();

        // Sort search results by relevance (title matches first)
        _searchResults.sort((a, b) {
          final aTitle = a.title.toLowerCase().contains(lowerQuery);
          final bTitle = b.title.toLowerCase().contains(lowerQuery);

          if (aTitle && !bTitle) return -1;
          if (!aTitle && bTitle) return 1;

          // If both or neither match title, sort by date
          return b.pubDate.compareTo(a.pubDate);
        });
      }
    });
  }

  void _clearSearch() {
    // Add to recent searches if there was text
    if (_searchController.text.isNotEmpty && !_recentSearches.contains(_searchController.text)) {
      setState(() {
        _recentSearches.insert(0, _searchController.text);
        // Keep only last 10 searches
        if (_recentSearches.length > 10) {
          _recentSearches.removeLast();
        }
      });
    }

    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _isSearching = false;
      _searchResults = [];
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
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMessage != null
                      ? _buildErrorState()
                      : (_isSearching || _searchController.text.isNotEmpty)
                          ? _buildSearchResults()
                          : _buildIdleContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFFE20035),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFFE20035),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Đã có lỗi xảy ra',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadArticles,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE20035),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
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
                hintText: 'Tìm kiếm theo tiêu đề',
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
    return Column(
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
                  'Tìm kiếm gần đây',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                GestureDetector(
                  onTap: _clearAllRecentSearches,
                  child: const Text(
                    'Xóa tất cả',
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
          const SizedBox(height: 16),
        ],

        // Category buttons
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
        const SizedBox(height: 16),

        // Articles list
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _currentCategory == 'all'
                    ? 'Tất cả bài báo'
                    : _getCategoryLabel(_currentCategory),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                '${_filteredArticles.length} bài báo',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Articles list
        Expanded(
          child: _filteredArticles.isEmpty
              ? Center(
                  child: Text(
                    'No articles found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredArticles.length,
                  itemBuilder: (context, index) {
                    final article = _filteredArticles[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildArticleItem(article),
                    );
                  },
                ),
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

  Widget _buildArticleItem(ArticleModel article) {
    return GestureDetector(
      onTap: () async {
        final updatedArticle = await Navigator.push<ArticleModel>(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleDetailScreen(article: article),
          ),
        );

        // Update article state if it changed (not just bookmark)
        if (updatedArticle != null) {
          setState(() {
            // Update in filtered list
            final index = _filteredArticles.indexWhere((a) => a.id == updatedArticle.id);
            if (index != -1) {
              _filteredArticles[index] = updatedArticle;
            }
            // Update in all articles list
            final allIndex = _allArticles.indexWhere((a) => a.id == updatedArticle.id);
            if (allIndex != -1) {
              _allArticles[allIndex] = updatedArticle;
            }
            // Update in search results
            final searchIndex = _searchResults.indexWhere((a) => a.id == updatedArticle.id);
            if (searchIndex != -1) {
              _searchResults[searchIndex] = updatedArticle;
            }
          });
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
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
                  : const Icon(
                      Icons.image,
                      color: Colors.grey,
                      size: 30,
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Source
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE20035),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.newspaper,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        article.source,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8E8E93),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  article.title,
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
                      _formatTimeAgo(article.pubDate),
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
                      _getCategoryLabel(article.category),
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
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy kết quả cho "${_searchController.text}"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final article = _searchResults[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildSearchResultItem(article),
        );
      },
    );
  }

  Widget _buildSearchResultItem(ArticleModel article) {
    return GestureDetector(
      onTap: () async {
        final updatedArticle = await Navigator.push<ArticleModel>(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleDetailScreen(article: article),
          ),
        );

        // Update article state if it changed
        if (updatedArticle != null) {
          setState(() {
            final index = _filteredArticles.indexWhere((a) => a.id == updatedArticle.id);
            if (index != -1) {
              _filteredArticles[index] = updatedArticle;
            }
            final allIndex = _allArticles.indexWhere((a) => a.id == updatedArticle.id);
            if (allIndex != -1) {
              _allArticles[allIndex] = updatedArticle;
            }
            final searchIndex = _searchResults.indexWhere((a) => a.id == updatedArticle.id);
            if (searchIndex != -1) {
              _searchResults[searchIndex] = updatedArticle;
            }
          });
        }
      },
      child: Row(
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
                      child: const Icon(
                        Icons.newspaper,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        article.source,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8E8E93),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Title with highlight
                _buildHighlightedText(article.title, _searchController.text),
                const SizedBox(height: 8),

                // Meta info
                Row(
                  children: [
                    Text(
                      _formatTimeAgo(article.pubDate),
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
                      _getCategoryLabel(article.category),
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
                  : const Icon(
                      Icons.image,
                      color: Colors.grey,
                      size: 30,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black,
          height: 1.3,
        ),
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black,
          height: 1.3,
        ),
      );
    }

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
          if (index > 0) TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: const TextStyle(
              color: Color(0xFFE20035),
              backgroundColor: Color(0xFFFFE8EC),
            ),
          ),
          if (index + query.length < text.length)
            TextSpan(text: text.substring(index + query.length)),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return const BottomNavigationBarComponent();
  }
}

