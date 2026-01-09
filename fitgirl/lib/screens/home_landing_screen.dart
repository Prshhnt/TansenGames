import 'package:flutter/material.dart';
import '../constants/hero_tags.dart';
import '../models/article_link.dart';
import '../models/home_data.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom/custom_button.dart';
import '../widgets/custom/custom_scrollbar.dart';
import '../widgets/custom/skeleton.dart';
import 'game_details_screen.dart';
import '../models/download_link.dart';

/// Home tab redesigned to mirror the provided HTML layout with placeholder data.
class HomeLandingScreen extends StatefulWidget {
  final VoidCallback? onNavigateToSearch;
  final VoidCallback? onNavigateToDownloads;
  final VoidCallback? onNavigateToPopular;

  const HomeLandingScreen({
    super.key,
    this.onNavigateToSearch,
    this.onNavigateToDownloads,
    this.onNavigateToPopular,
  });

  @override
  State<HomeLandingScreen> createState() => _HomeLandingScreenState();
}

class _HomeLandingScreenState extends State<HomeLandingScreen> {
  bool _expandingSearch = false;
  final ApiService _apiService = ApiService();
  HomeData? _homeData;
  bool _isLoadingHome = true;
  String? _homeError;
  bool _isOpeningGame = false;
  ArticleLink? _selectedArticle;
  List<DownloadLink> _selectedMirrors = [];
  String? _detailsError;
  bool _loadingDetails = false;

  Future<void> _triggerSearch() async {
    if (_expandingSearch) return;
    setState(() => _expandingSearch = true);
    await Future.delayed(const Duration(milliseconds: 260));
    widget.onNavigateToSearch?.call();
    setState(() => _expandingSearch = false);
  }

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  Future<void> _loadHome() async {
    setState(() {
      _isLoadingHome = true;
      _homeError = null;
    });
    try {
      final data = await _apiService.fetchHome(maxItems: 12, imageSize: 'medium');
      if (!mounted) return;
      setState(() {
        _homeData = data;
        _isLoadingHome = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _homeError = e.toString();
        _isLoadingHome = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mirror the search tab experience: keep the shell and swap only the body between
    // the landing sections and the inlined game details, without opening a new page.
    if (_selectedArticle != null) {
      if (_loadingDetails) {
        return const _LandingDetailsSkeleton();
      }

      if (_detailsError != null) {
        return Container(
          color: AppTheme.backgroundDark,
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppTheme.statusError),
                const SizedBox(height: 12),
                Text(
                  _detailsError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'NotoSans'),
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
          onNavigateToDownloads: widget.onNavigateToDownloads,
        ),
      );
    }

    final controller = ScrollController();
    return Container(
      color: AppTheme.backgroundDark,
      child: CustomScrollbar(
        controller: controller,
        child: SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context),
              if (_isOpeningGame)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    color: AppTheme.primary,
                    backgroundColor: AppTheme.borderColor,
                  ),
                ),
              if (_homeError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(
                    _homeError!,
                    style: const TextStyle(color: AppTheme.statusError, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),
              if (_isLoadingHome) ...[
                const _HomeSkeleton(),
              ] else ...[
                _heroSection(context),
                const SizedBox(height: 24),
                _justUpdatedSection(context),
                const SizedBox(height: 16),
                _upcomingSection(),
                const SizedBox(height: 24),
                _trendingSection(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Home',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
          ],
        ),
        const Spacer(),
        _searchField(context),
        const SizedBox(width: 12),
        _iconButton(Icons.notifications, onTap: () {}),
        const SizedBox(width: 8),
        _iconButton(Icons.account_circle, onTap: () {}),
      ],
    );
  }

  Widget _searchField(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width;
    final expandedWidth = (maxWidth * 0.5).clamp(260.0, 640.0);
    return Hero(
      tag: searchBarHeroTag,
      flightShuttleBuilder: (context, animation, flightDirection, fromContext, toContext) {
        final target = flightDirection == HeroFlightDirection.push
            ? toContext.widget
            : fromContext.widget;
        return FadeTransition(
          opacity: animation.drive(CurveTween(curve: Curves.easeInOut)),
          child: target,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOutCubic,
          width: _expandingSearch ? expandedWidth : 260,
          child: TextField(
            readOnly: true,
            onTap: _triggerSearch,
            decoration: InputDecoration(
              hintText: 'Search games, repacks...',
              hintStyle: const TextStyle(color: AppTheme.slate400, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: AppTheme.slate400),
              filled: true,
              fillColor: AppTheme.surfaceHover,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.surfaceHover),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.surfaceHover),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
              ),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: AppTheme.surfaceHover,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _heroSection(BuildContext context) {
    final featured = _homeData?.featured;
    final title = _sanitizeTitle(featured?.title ?? 'Featured repack coming soon');
    final version = featured?.version?.trim();
    final repackSize = featured?.repackSize?.trim();
    final subtitle = [version, repackSize].where((v) => v != null && v!.isNotEmpty).join(' - ');

    return Container(
      height: 360,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor),
        color: AppTheme.surfaceDark,
        image: featured?.image != null && featured!.image!.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(featured.image!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [
                  AppTheme.backgroundDark.withOpacity(0.9),
                  AppTheme.backgroundDark.withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _pill('Featured Repack', AppTheme.primary),
                    if (version != null && version.isNotEmpty)
                      _pill('Updated', AppTheme.surfaceHover),
                  ],
                ),
                const Spacer(),
                Text(
                  title.isEmpty ? 'Featured repack' : title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle.isEmpty ? 'Stay tuned for the next drop' : subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontFamily: 'NotoSans',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    PrimaryButton(
                      label: 'Download Repack',
                      icon: Icons.download,
                      onPressed: featured != null && featured.url.isNotEmpty
                          ? () => _openHomeItem(featured)
                          : widget.onNavigateToSearch,
                    ),
                    const SizedBox(width: 10),
                    SecondaryButton(
                      label: 'View Details',
                      icon: Icons.open_in_new,
                      onPressed: featured != null && featured.url.isNotEmpty
                          ? () => _openHomeItem(featured)
                          : widget.onNavigateToSearch,
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

  Widget _justUpdatedSection(BuildContext context) {
    final latest = _homeData?.latest ?? _placeholderItems(6);
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1200
        ? 5
        : width > 1000
            ? 4
            : width > 800
                ? 3
                : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.new_releases, color: AppTheme.primary),
                SizedBox(width: 8),
                Text(
                  'Just Updated',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: widget.onNavigateToSearch,
              child: const Text(
                'View All',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'NotoSans',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.62,
          ),
          itemCount: latest.length,
          itemBuilder: (context, index) => _gameCard(latest[index]),
        ),
      ],
    );
  }

  Widget _upcomingSection() {
    final upcoming = _homeData?.upcoming ?? [];
    if (upcoming.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.schedule, color: Colors.amberAccent),
            SizedBox(width: 8),
            Text(
              'Upcoming Repacks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: upcoming
              .map((text) => _miniTag(_sanitizeTitle(text)))
              .toList(),
        ),
      ],
    );
  }

  Widget _gameCard(HomeItem data) {
    final title = _sanitizeTitle(data.title);
    final version = data.version?.trim();
    final size = data.repackSize?.trim();
    return InkWell(
      onTap: () => _openHomeItem(data),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surfaceHover,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
                image: data.image != null && data.image!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(data.image!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    version?.isNotEmpty == true ? version! : 'New',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontFamily: 'Monospace',
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title.isEmpty ? 'Title pending' : title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'NotoSans',
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  size?.isNotEmpty == true ? size! : 'Size pending',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.slate400,
                    fontFamily: 'NotoSans',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHover,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        version?.isNotEmpty == true ? version! : 'Latest',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.slate400,
                          fontFamily: 'NotoSans',
                        ),
                      ),
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

  Widget _trendingSection(BuildContext context) {
    final popular = _homeData?.popular ?? [];
    final trending = popular.isNotEmpty
        ? popular
            .take(9)
            .map(
              (item) => _TrendingCardData(
                title: _sanitizeTitle(item.title),
                version: '',
                size: '',
                downloads: '',
                imageUrl: item.posterUrl ?? '',
                url: item.url,
              ),
            )
            .toList()
        : _placeholderTrending(6);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1100
            ? 3
            : width >= 780
                ? 2
                : 1;
        const spacing = 12.0;
        final itemWidth =
            (width - spacing * (crossAxisCount - 1)) / crossAxisCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.trending_up, color: Colors.orangeAccent),
                SizedBox(width: 8),
                Text(
                  'Trending Now',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: trending
                  .map(
                    (t) => SizedBox(
                      width: itemWidth,
                      child: _trendingCard(
                        t,
                        onTap: t.url.isNotEmpty
                            ? () => _openTrending(t)
                            : null,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _trendingCard(_TrendingCardData data, {VoidCallback? onTap}) {
    final title = _sanitizeTitle(data.title);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHover,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(10),
                image: data.imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(data.imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty ? 'Popular repack' : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFamily: 'NotoSans',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.version.isNotEmpty ? data.version : 'Freshly seeded',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.slate400,
                      fontFamily: 'NotoSans',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _miniTag(data.size.isNotEmpty ? data.size : 'Popular'),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          const Icon(Icons.download, size: 14, color: Colors.greenAccent),
                          const SizedBox(width: 4),
                          Text(
                            data.downloads.isNotEmpty ? data.downloads : 'Live',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.greenAccent,
                              fontFamily: 'Monospace',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _iconButton(Icons.arrow_forward, onTap: onTap),
          ],
        ),
      ),
    );
  }

  Future<void> _openHomeItem(HomeItem item) async {
    if (item.url.isEmpty) {
      _showSnackbar('This repack does not have a page yet.');
      return;
    }
    final article = ArticleLink(
      title: _sanitizeTitle(item.title).isEmpty ? item.title : _sanitizeTitle(item.title),
      url: item.url,
      posterUrl: item.image,
    );
    await _openArticle(article);
  }

  Future<void> _openTrending(_TrendingCardData data) async {
    if (data.url.isEmpty) {
      _showSnackbar('This repack does not have a page yet.');
      return;
    }
    final article = ArticleLink(
      title: _sanitizeTitle(data.title).isEmpty ? data.title : _sanitizeTitle(data.title),
      url: data.url,
      posterUrl: data.imageUrl.isNotEmpty ? data.imageUrl : null,
    );
    await _openArticle(article);
  }

  Future<void> _openArticle(ArticleLink article) async {
    if (_isOpeningGame) return;
    setState(() {
      _isOpeningGame = true;
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
    } finally {
      if (mounted) setState(() => _isOpeningGame = false);
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
    await _openArticle(article);
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : AppTheme.surfaceHover,
      ),
    );
  }


  Widget _miniTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.slate400,
          fontFamily: 'Monospace',
        ),
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontFamily: 'SpaceGrotesk',
        ),
      ),
    );
  }
}

class _TrendingCardData {
  final String title;
  final String version;
  final String size;
  final String downloads;
  final String imageUrl;
  final String url;

  const _TrendingCardData({
    required this.title,
    required this.version,
    required this.size,
    required this.downloads,
    required this.imageUrl,
    required this.url,
  });
}

List<HomeItem> _placeholderItems(int count) {
  return List.generate(
    count,
    (index) => const HomeItem(
      title: 'Placeholder',
      url: '',
      image: null,
      version: '',
      publishedDate: '',
      repackSize: '',
    ),
  );
}

List<_TrendingCardData> _placeholderTrending(int count) {
  return List.generate(
    count,
    (index) => const _TrendingCardData(
      title: 'Popular repack',
      version: '',
      size: '',
      downloads: '',
      imageUrl: '',
      url: '',
    ),
  );
}

String _sanitizeTitle(String value) {
  final cleaned = value.replaceAll(RegExp(r'^[\u2022\-\s]+'), '');
  return cleaned.trim();
}

class _LandingDetailsSkeleton extends StatelessWidget {
  const _LandingDetailsSkeleton();

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

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1200
        ? 5
        : width > 1000
            ? 4
            : width > 800
                ? 3
                : 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero skeleton
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: const SkeletonBlock(width: double.infinity, height: 360),
        ),
        const SizedBox(height: 24),
        // Just updated title
        Row(
          children: const [
            SkeletonBlock(width: 140, height: 20),
            SizedBox(width: 12),
            SkeletonBlock(width: 80, height: 16),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.62,
          ),
          itemCount: crossAxisCount * 2,
          itemBuilder: (_, __) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Expanded(
                child: SkeletonBlock(width: double.infinity, height: double.infinity),
              ),
              SizedBox(height: 8),
              SkeletonBlock(width: 120, height: 14),
              SizedBox(height: 6),
              SkeletonBlock(width: 100, height: 12),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SkeletonBlock(width: 160, height: 18),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: List.generate(
            6,
            (_) => const SkeletonBlock(width: 120, height: 24, borderRadius: BorderRadius.all(Radius.circular(8))),
          ),
        ),
        const SizedBox(height: 24),
        const SkeletonBlock(width: 140, height: 20),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(
            crossAxisCount * 2,
            (_) => const SizedBox(
              width: 320,
              child: SkeletonBlock(width: double.infinity, height: 110, borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
          ),
        ),
      ],
    );
  }
}
