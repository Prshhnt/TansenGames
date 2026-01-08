import 'package:flutter/material.dart';
import '../models/article_link.dart';
import '../models/download_link.dart';
import '../services/api_service.dart';
import '../services/search_history_service.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/article_list_widget.dart';
import '../widgets/download_links_widget.dart';
import '../widgets/error_widget.dart';

/// Home screen - main functionality
/// Manages the search flow and displays results
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // API service for backend communication
  final ApiService _apiService = ApiService();
  final SearchHistoryService _historyService = SearchHistoryService();

  // Text controller for search input
  final TextEditingController _searchController = TextEditingController();

  // State management
  bool _isLoading = false;
  String? _errorMessage;

  List<ArticleLink> _searchResults = [];
  List<DownloadLink> _downloadMirrors = [];
  ArticleLink? _selectedArticle;

  // Track current view state
  ViewState _viewState = ViewState.initial;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Execute search query
  Future<void> _performSearch() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      _showSnackBar('Please enter a search query');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _searchResults = [];
      _downloadMirrors = [];
      _selectedArticle = null;
      _viewState = ViewState.loading;
    });

    try {
      final results = await _apiService.searchGames(query);

      setState(() {
        _searchResults = results;
        _isLoading = false;
        _viewState = results.isEmpty
            ? ViewState.empty
            : ViewState.searchResults;
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

      setState(() {
        _downloadMirrors = links;
        _isLoading = false;
        _viewState = links.isEmpty
            ? ViewState.empty
            : ViewState.downloadMirrors;
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

  /// Show snackbar message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bool showCentered = _viewState == ViewState.initial && !_isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: showCentered
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Big controller icon
                  Icon(
                    Icons.videogame_asset,
                    size: 120,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 40),
                  // Search bar
                  SearchBarWidget(
                    controller: _searchController,
                    onSearch: _performSearch,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Search bar at top
                SearchBarWidget(
                  controller: _searchController,
                  onSearch: _performSearch,
                  isLoading: _isLoading,
                ),

                const Divider(height: 1),

                // Content area with smooth scrolling
                Expanded(
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      scrollbars: true,
                      physics: const BouncingScrollPhysics(),
                    ),
                    child: _buildContent(),
                  ),
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
        return ErrorDisplayWidget(
          message: _errorMessage ?? 'An unknown error occurred',
          onRetry: () {
            if (_selectedArticle != null) {
              _onArticleSelected(_selectedArticle!);
            } else {
              _performSearch();
            }
          },
        );

      case ViewState.empty:
        return _buildEmptyState();

      case ViewState.searchResults:
        return ArticleListWidget(
          articles: _searchResults,
          onArticleSelected: _onArticleSelected,
        );

      case ViewState.downloadMirrors:
        return DownloadLinksWidget(
          article: _selectedArticle!,
          downloadMirrors: _downloadMirrors,
          onBack: _backToSearchResults,
        );
    }
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Search for games',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a game name to find repacks',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            _selectedArticle != null
                ? 'Fetching download mirrors...'
                : 'Searching...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search query',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
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
}
