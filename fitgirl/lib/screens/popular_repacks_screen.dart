import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/article_link.dart';
import '../services/api_service.dart';
import 'game_details_screen.dart';
import '../widgets/custom/skeleton.dart';
import '../models/download_link.dart';

/// Popular Repacks screen - displays most popular repacks
class PopularRepacksScreen extends StatefulWidget {
  const PopularRepacksScreen({super.key});

  @override
  State<PopularRepacksScreen> createState() => _PopularRepacksScreenState();
}

class _PopularRepacksScreenState extends State<PopularRepacksScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<ArticleLink> _popularRepacks = [];
  ArticleLink? _selectedArticle;
  List<DownloadLink> _selectedMirrors = [];
  bool _loadingDetails = false;
  String? _detailsError;

  @override
  void initState() {
    super.initState();
    _fetchPopularRepacks();
  }

  Future<void> _fetchPopularRepacks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repacks = await _apiService.fetchPopularRepacks(imageSize: 'full');
      setState(() {
        _popularRepacks = repacks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceDark,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderColor),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.local_fire_department, color: AppTheme.primary),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Popular Repacks',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'SpaceGrotesk',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Top trending releases curated from FitGirl',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.slate400,
                        fontFamily: 'NotoSans',
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                          ),
                        )
                      : const Icon(Icons.refresh, color: AppTheme.slate300),
                  onPressed: _isLoading ? null : _fetchPopularRepacks,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedArticle != null) {
      if (_loadingDetails) {
        return const _PopularDetailsSkeleton();
      }

      if (_detailsError != null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.statusError),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _detailsError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontFamily: 'NotoSans'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: _retrySelected,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: _clearSelection,
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    label: const Text('Back', style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            ],
          ),
        );
      }

      return Container(
        color: AppTheme.backgroundDark,
        padding: const EdgeInsets.only(top: 8),
        child: GameDetailsScreen(
          article: _selectedArticle!,
          mirrors: _selectedMirrors,
          embedded: true,
          onBack: _clearSelection,
        ),
      );
    }

    if (_isLoading) {
      return const _PopularSkeletonGrid();
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error loading popular repacks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.slate400,
                  fontFamily: 'NotoSans',
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchPopularRepacks,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_popularRepacks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppTheme.slate500,
            ),
            SizedBox(height: 16),
            Text(
              'No popular repacks found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
          ],
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1200
      ? 4
      : width > 900
        ? 3
        : width > 640
          ? 2
          : 1;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.68,
        ),
        itemCount: _popularRepacks.length,
        itemBuilder: (context, index) {
          final repack = _popularRepacks[index];
          return _PopularRepackCard(
            repack: repack,
            index: index + 1,
            onOpen: _openRepack,
          );
        },
      ),
    );
  }

  Future<void> _openRepack(ArticleLink article) async {
    setState(() {
      _selectedArticle = article;
      _selectedMirrors = [];
      _detailsError = null;
      _loadingDetails = true;
    });

    try {
      final mirrors = await _apiService.fetchDownloadMirrors(article.url);
      if (!mounted) return;
      setState(() {
        _selectedMirrors = mirrors;
        _loadingDetails = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detailsError = 'Unable to open repack: ${e.toString().replaceFirst('Exception: ', '')}';
        _loadingDetails = false;
      });
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedArticle = null;
      _selectedMirrors = [];
      _detailsError = null;
      _loadingDetails = false;
    });
  }

  Future<void> _retrySelected() async {
    final article = _selectedArticle;
    if (article == null) return;
    await _openRepack(article);
  }
}

/// Individual popular repack card
class _PopularRepackCard extends StatefulWidget {
  final ArticleLink repack;
  final int index;
  final Future<void> Function(ArticleLink) onOpen;

  const _PopularRepackCard({
    required this.repack,
    required this.index,
    required this.onOpen,
  });

  @override
  State<_PopularRepackCard> createState() => _PopularRepackCardState();
}

class _PopularRepackCardState extends State<_PopularRepackCard> {
  bool _isHovered = false;
  bool _isOpening = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered ? AppTheme.primary.withOpacity(0.4) : AppTheme.borderColor,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isOpening
                  ? null
                  : () async {
                      setState(() => _isOpening = true);
                      try {
                        await widget.onOpen(widget.repack);
                      } finally {
                        if (mounted) setState(() => _isOpening = false);
                      }
                    },
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  // Poster background
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: widget.repack.posterUrl != null && widget.repack.posterUrl!.isNotEmpty
                          ? Image.network(
                              widget.repack.posterUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: AppTheme.surfaceDark),
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: AppTheme.surfaceDark,
                                  alignment: Alignment.center,
                                  child: const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(color: AppTheme.surfaceDark),
                    ),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.45, 0.75, 1.0],
                          colors: [
                            Colors.black.withOpacity(0.02),
                            Colors.black.withOpacity(0.18),
                            Colors.black.withOpacity(0.65),
                            Colors.black.withOpacity(0.9),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Bottom vignette for text legibility
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 120,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.0),
                            Colors.black.withOpacity(0.75),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.local_fire_department, size: 14, color: Colors.white70),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Top ${widget.index + 1}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontFamily: 'NotoSans',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            if (_isOpening)
                              const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          widget.repack.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontFamily: 'SpaceGrotesk',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tap to view repack details',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontFamily: 'NotoSans',
                          ),
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
    );
  }
}

class _PopularSkeletonGrid extends StatelessWidget {
  const _PopularSkeletonGrid();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1200
        ? 4
        : width > 900
            ? 3
            : width > 640
                ? 2
                : 1;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.68,
        ),
        itemCount: crossAxisCount * 2,
        itemBuilder: (_, __) => ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: const [
              Positioned.fill(
                child: SkeletonBlock(width: double.infinity, height: double.infinity),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: SkeletonBlock(width: double.infinity, height: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopularDetailsSkeleton extends StatelessWidget {
  const _PopularDetailsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundDark,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SizedBox(height: 12),
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
