import 'package:flutter/material.dart';
import '../models/article_link.dart';
import '../models/download_link.dart';
import '../services/api_service.dart';
import '../services/search_history_service.dart';
import '../widgets/custom/custom_search_bar.dart';
import '../widgets/custom/custom_filter_chips.dart';
import '../widgets/custom/game_list_item.dart';
import '../widgets/custom/custom_scrollbar.dart';
import '../widgets/custom/skeleton.dart';
import '../widgets/custom/custom_button.dart';
import '../widgets/download_links_widget.dart';
import '../theme/app_theme.dart';
import 'game_details_screen.dart';

/// Home screen - redesigned to match HTML mockup
/// Features: Custom search bar, filter chips, game list with hover effects
class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToDownloads;

  const HomeScreen({super.key, this.onNavigateToDownloads});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final SearchHistoryService _historyService = SearchHistoryService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _searchResultsController = ScrollController();

  bool _isLoading = false;
  String? _errorMessage;
  List<ArticleLink> _searchResults = [];
  List<DownloadLink> _downloadMirrors = [];
  ArticleLink? _selectedArticle;
  ViewState _viewState = ViewState.initial;
  String? _selectedSort;
  double _searchTime = 0.0;

  @override
  void dispose() {
    _searchResultsController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _searchResults = [];
      _downloadMirrors = [];
      _selectedArticle = null;
      _viewState = ViewState.loading;
    });

    final stopwatch = Stopwatch()..start();
    try {
      final results = await _apiService.searchGames(query);
      stopwatch.stop();

      setState(() {
        _searchResults = results;
        _searchTime = stopwatch.elapsedMilliseconds / 1000;
        _isLoading = false;
        _viewState = results.isEmpty ? ViewState.empty : ViewState.searchResults;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
        _viewState = ViewState.error;
      });
    }
  }

  /// Handle article selection and fetch download mirrors
  Future<void> _onArticleSelected(ArticleLink article) async {
    // Save to history
    await _historyService.addArticle(article.title, article.url);

    setState(() {
      _selectedArticle = article;
      _isLoading = true;
      _errorMessage = null;
      _downloadMirrors = [];
      _viewState = ViewState.loading;
    });

    try {
      final links = await _apiService.fetchDownloadMirrors(article.url);
      if (!mounted) return;

      setState(() {
        _selectedArticle = article;
        _downloadMirrors = links;
        _isLoading = false;
        _viewState = ViewState.gameDetails;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
        _viewState = ViewState.error;
      });
    }
  }

  /// Navigate back to search results
  void _backToSearchResults() {
    setState(() {
      _selectedArticle = null;
      _downloadMirrors = [];
      _viewState = ViewState.searchResults;
    });
  }

  @override
  Widget build(BuildContext context) {
    final showSearchChrome = _viewState == ViewState.initial ||
        _viewState == ViewState.loading ||
        _viewState == ViewState.empty ||
        _viewState == ViewState.searchResults;

    return Container(
      color: AppTheme.backgroundDark,
      child: Column(
        children: [
          if (showSearchChrome)
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: CustomSearchBar(
                      controller: _searchController,
                      onSearch: _performSearch,
                      isLoading: _isLoading,
                    ),
                  ),
                  if (_viewState == ViewState.searchResults) ...[
                    const SizedBox(height: 24),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: CustomFilterChips(
                        selectedSort: _selectedSort,
                        onSortChanged: (sort) {
                          setState(() {
                            _selectedSort = sort;
                          });
                        },
                        resultCount: _searchResults.length,
                        searchTime: _searchTime,
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Content area
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  /// Build content based on current state
  Widget _buildContent() {
    switch (_viewState) {
      case ViewState.initial:
        return _buildInitialState();

      case ViewState.loading:
        return _buildLoadingState();

      case ViewState.error:
        return _buildErrorState();

      case ViewState.empty:
        return _buildEmptyState();

      case ViewState.searchResults:
        return _buildSearchResults();

      case ViewState.downloadMirrors:
        return DownloadLinksWidget(
          article: _selectedArticle!,
          downloadMirrors: _downloadMirrors,
          onBack: _backToSearchResults,
          onNavigateToDownloads: widget.onNavigateToDownloads,
        );
      case ViewState.gameDetails:
        return GameDetailsScreen(
          article: _selectedArticle!,
          mirrors: _downloadMirrors,
          embedded: true,
          onBack: _backToSearchResults,
          onNavigateToDownloads: widget.onNavigateToDownloads,
        );
    }
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: const Icon(
              Icons.search,
              size: 64,
              color: AppTheme.slate400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Search for games',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter a game name to find repacks',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.slate400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    if (_selectedArticle != null && _viewState == ViewState.loading) {
      return const _GameDetailsSkeleton();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: GameListSkeletonList(itemCount: 6),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: const Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppTheme.slate400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No results found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try a different search query',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.slate400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.statusError.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.statusError.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.statusError,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'An unknown error occurred',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.slate400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                if (_selectedArticle != null) {
                  _onArticleSelected(_selectedArticle!);
                } else {
                  _performSearch();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF0B6FD8)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: CustomScrollbar(
            controller: _searchResultsController,
            child: ListView.separated(
              controller: _searchResultsController,
              itemCount: _searchResults.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final article = _searchResults[index];
                return GameListItem(
                  article: article,
                  onTap: () => _onArticleSelected(article),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

}

class _GameDetailsSkeleton extends StatelessWidget {
  const _GameDetailsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonBlock(width: 140, height: 16),
            SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBlock(width: 180, height: 260),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBlock(width: double.infinity, height: 22),
                      SizedBox(height: 10),
                      SkeletonBlock(width: double.infinity, height: 14),
                      SizedBox(height: 10),
                      SkeletonBlock(width: 220, height: 14),
                      SizedBox(height: 16),
                      SkeletonBlock(width: double.infinity, height: 40),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            SkeletonBlock(width: 200, height: 16),
            SizedBox(height: 12),
            SkeletonBlock(width: double.infinity, height: 120),
          ],
        ),
      ),
    );
  }
}

/// Enum to track different view states
enum ViewState {
  initial, // Initial state before any search
  loading, // Loading data from backend
  error, // Error occurred
  empty, // No results found
  searchResults, // Displaying search results
  downloadMirrors, // Displaying download mirrors
  gameDetails, // Embedded game details view
}
