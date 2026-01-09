import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/article_link.dart';
import '../models/download_link.dart';
import '../models/game_metadata.dart';
import '../screens/parts_screen.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom/custom_button.dart';
import '../widgets/custom/breadcrumb_navigation.dart';
import '../widgets/custom/custom_scrollbar.dart';
import '../widgets/custom/custom_sidebar.dart';
import 'main_screen.dart';

/// Game details view inspired by the HTML mockup hero/about/specs layout.
class GameDetailsScreen extends StatefulWidget {
  final ArticleLink article;
  final List<DownloadLink> mirrors;
  final bool embedded;
  final VoidCallback? onBack;
  final VoidCallback? onNavigateToDownloads;

  const GameDetailsScreen({
    super.key,
    required this.article,
    required this.mirrors,
    this.embedded = false,
    this.onBack,
    this.onNavigateToDownloads,
  });

  @override
  State<GameDetailsScreen> createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends State<GameDetailsScreen> {
  late final ScrollController _scrollController;
  late final ApiService _apiService;
  bool _showingParts = false;
  String? _partsProvider;
  List<String> _partsUrls = const [];
  GameMetadata? _metadata;
  bool _metaLoading = true;
  String? _metaError;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _apiService = ApiService();
    _fetchMetadata();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMetadata() async {
    setState(() {
      _metaLoading = true;
      _metaError = null;
    });
    try {
      final data = await _apiService.fetchGameMetadata(
        widget.article.url,
        imageSize: 'full',
      );
      if (!mounted) return;
      setState(() {
        _metadata = data;
        _metaLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _metaError = e.toString();
        _metaLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showingParts && _partsProvider != null) {
      return PartsScreen(
        article: widget.article,
        providerName: _partsProvider!,
        urls: _partsUrls,
        embedded: true,
        onBack: _backFromParts,
        onNavigateToDownloads: widget.onNavigateToDownloads,
      );
    }

    final content = CustomScrollbar(
      controller: _scrollController,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildTopBar(context),
          const SizedBox(height: 12),
          _buildHero(),
          const SizedBox(height: 16),
          _buildTwoColumn(),
          const SizedBox(height: 16),
          _buildMirrors(),
          const SizedBox(height: 24),
          _buildFooter(),
        ],
      ),
    );

    if (widget.embedded) {
      return Container(
        color: AppTheme.backgroundDark,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: content,
        ),
      );
    }

    return Scaffold(backgroundColor: AppTheme.backgroundDark, body: content);
  }

  void _backFromParts() {
    setState(() {
      _showingParts = false;
      _partsProvider = null;
      _partsUrls = const [];
    });
  }

  Widget _buildTopBar(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: PrimaryButton(
        label: 'Back to Search',
        icon: Icons.arrow_back,
        onPressed: () {
          if (widget.onBack != null) {
            widget.onBack!();
          } else {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _buildHero() {
    final title = _metadata?.title.isNotEmpty == true ? _metadata!.title : widget.article.title;
    final desc = _metadata?.description.isNotEmpty == true
        ? _metadata!.description
        : (_metaLoading ? 'Loading metadata…' : 'No description available for this repack yet.');
    final poster = _metadata?.posterUrl ?? '';
    final repackSize = _metadata?.repackSize ?? '';
    final originalSize = _metadata?.originalSize ?? '';
    final selective = _metadata?.selectiveDownload ?? false;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 180,
            height: 270,
            decoration: BoxDecoration(
              color: AppTheme.slate800,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderColor.withOpacity(0.6)),
            ),
            clipBehavior: Clip.hardEdge,
            child: poster.isNotEmpty
                ? Image.network(
                    poster,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _posterFallback(),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return _posterFallback(isLoading: true);
                    },
                  )
                : _posterFallback(isLoading: _metaLoading),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontFamily: 'SpaceGrotesk',
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_metaLoading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _metaError != null
                      ? 'Metadata unavailable: ${_metaError!.replaceFirst('Exception: ', '')}'
                      : desc,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.slate300,
                    height: 1.45,
                    fontFamily: 'NotoSans',
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (repackSize.isNotEmpty) _MetaChip(icon: Icons.compress, label: 'Repack: $repackSize'),
                    if (originalSize.isNotEmpty) _MetaChip(icon: Icons.storage, label: 'Original: $originalSize'),
                    _MetaChip(icon: Icons.cloud_download, label: '${widget.mirrors.length} provider(s)'),
                    if (selective) _MetaChip(icon: Icons.tune, label: 'Selective download'),
                    if ((_metadata?.publishedDate ?? '').isNotEmpty)
                      _MetaChip(icon: Icons.calendar_today, label: 'Published ${_metadata!.publishedDate.split('T').first}'),
                    if ((_metadata?.modifiedDate ?? '').isNotEmpty)
                      _MetaChip(icon: Icons.update, label: 'Updated ${_metadata!.modifiedDate.split('T').first}'),
                    _MetaChip(icon: Icons.link, label: 'Source URL available'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _posterFallback({bool isLoading = false}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.surfaceHover, AppTheme.surfaceDark],
        ),
      ),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              )
            : const Text(
                'No poster',
                style: TextStyle(
                  color: AppTheme.slate400,
                  fontSize: 12,
                  fontFamily: 'NotoSans',
                ),
              ),
      ),
    );
  }

  Widget _buildTwoColumn() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _card(
                title: 'About this release',
                icon: Icons.info,
                child: _metaSection(),
              ),
              const SizedBox(height: 12),
              if ((_metadata?.repackFeatures.isNotEmpty ?? false))
                _card(
                  title: 'Repack features',
                  icon: Icons.list_alt,
                  child: _featuresList(),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _card(
            title: 'Specs & mirrors',
            icon: Icons.dashboard_customize,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _specsBlock(),
                const SizedBox(height: 12),
                const Divider(color: AppTheme.borderColor),
                const SizedBox(height: 12),
                ...widget.mirrors.map(_mirrorTile),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _mirrorTile(DownloadLink link) {
    final isPrivate = link.url.contains('paste.fitgirl-repacks.site');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.cloud, color: AppTheme.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  link.text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'SpaceGrotesk',
                  ),
                  maxLines: 2,
                  softWrap: true,
                ),
                const SizedBox(height: 4),
                Text(
                  link.url,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.slate500,
                    fontFamily: 'NotoSans',
                  ),
                  maxLines: 2,
                  softWrap: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SecondaryButton(
            label: 'Open',
            icon: Icons.open_in_new,
            onPressed: () => _handleMirrorTap(link, isPrivate),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMirrorTap(DownloadLink link, bool isPrivate) async {
    if (isPrivate) {
      await _decryptAndShowLinks(link);
      return;
    }

    await Clipboard.setData(ClipboardData(text: link.url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard')),
    );
  }

  Future<void> _decryptAndShowLinks(DownloadLink link) async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.primary),
              SizedBox(height: 12),
              Text(
                'Decrypting and extracting links...',
                style: TextStyle(color: Colors.white, fontFamily: 'NotoSans'),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final urls = await _apiService.decryptPaste(link.url);
      if (!mounted) return;
      Navigator.pop(context);

      if (urls.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No links found in this paste')),
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _showingParts = true;
        _partsProvider = link.text;
        _partsUrls = urls;
      });
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  Widget _card({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _metaSection() {
    if (_metaLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
      );
    }

    if (_metaError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metadata unavailable.',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontFamily: 'NotoSans',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _metaError!,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.slate400,
              fontFamily: 'NotoSans',
            ),
          ),
          const SizedBox(height: 8),
          SecondaryButton(label: 'Retry', icon: Icons.refresh, onPressed: _fetchMetadata),
        ],
      );
    }

    final meta = _metadata;
    if (meta == null) {
      return const Text(
        'No metadata found.',
        style: TextStyle(fontSize: 14, color: AppTheme.slate300, fontFamily: 'NotoSans'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (meta.description.isNotEmpty)
          Text(
            meta.description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppTheme.slate300,
              fontFamily: 'NotoSans',
            ),
          ),
        if (meta.description.isNotEmpty) const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (meta.genres.isNotEmpty)
              _pill(icon: Icons.category, label: meta.genres.join(' · '), dense: true),
            if (meta.companies.isNotEmpty)
              _pill(icon: Icons.apartment, label: meta.companies, dense: true),
            if (meta.languages.isNotEmpty)
              _pill(icon: Icons.translate, label: meta.languages, dense: true),
            if (meta.requirements.isNotEmpty)
              _pill(icon: Icons.memory, label: meta.requirements, dense: true),
            if (meta.publishedDate.isNotEmpty)
              _pill(icon: Icons.calendar_today, label: 'Published ${meta.publishedDate.split('T').first}', dense: true),
            if (meta.modifiedDate.isNotEmpty)
              _pill(icon: Icons.update, label: 'Updated ${meta.modifiedDate.split('T').first}', dense: true),
          ],
        ),
      ],
    );
  }

  Widget _pill({required IconData icon, required String label, bool dense = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 10 : 12, vertical: dense ? 8 : 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHover,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.slate300),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontFamily: 'NotoSans',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _specsBlock() {
    final meta = _metadata;
    if (meta == null) {
      return const Text(
        'Metadata not loaded.',
        style: TextStyle(fontSize: 13, color: AppTheme.slate400, fontFamily: 'NotoSans'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow(Icons.apartment, 'Companies', meta.companies),
        _infoRow(Icons.translate, 'Languages', meta.languages),
        _infoRow(Icons.memory, 'Requirements', meta.requirements),
        _infoRow(Icons.compress, 'Repack size', meta.repackSize),
        _infoRow(Icons.storage, 'Original size', meta.originalSize),
        _infoRow(Icons.calendar_today, 'Published', meta.publishedDate.split('T').first),
        _infoRow(Icons.update, 'Updated', meta.modifiedDate.split('T').first),
        _infoRow(Icons.tune, 'Selective download', meta.selectiveDownload ? 'Yes' : 'No'),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.slate400),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.slate500,
                    fontFamily: 'NotoSans',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontFamily: 'NotoSans',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featuresList() {
    final meta = _metadata;
    if (meta == null || meta.repackFeatures.isEmpty) {
      return const Text(
        'No features listed.',
        style: TextStyle(fontSize: 13, color: AppTheme.slate400, fontFamily: 'NotoSans'),
      );
    }

    final items = meta.repackFeatures.take(12).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(Icons.check_circle, size: 14, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppTheme.slate300,
                        fontFamily: 'NotoSans',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMirrors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        BreadcrumbNavigation(
          items: [
            BreadcrumbItem(label: 'Search', icon: Icons.search),
            BreadcrumbItem(label: 'Tansen Games', icon: Icons.videogame_asset),
            BreadcrumbItem(label: 'Mirrors', icon: Icons.cloud_download),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text(
        'Tansen Games • Mocked details view',
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.slate500.withOpacity(0.9),
          fontFamily: 'NotoSans',
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHover,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.slate400),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontFamily: 'NotoSans',
            ),
          ),
        ],
      ),
    );
  }
}

/// Wrapper that renders GameDetails inside the main sidebar layout for non-search entries.
class GameDetailsWithSidebar extends StatelessWidget {
  final ArticleLink article;
  final List<DownloadLink> mirrors;
  final int selectedNavIndex;

  const GameDetailsWithSidebar({
    super.key,
    required this.article,
    required this.mirrors,
    required this.selectedNavIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Row(
        children: [
          CustomSidebar(
            selectedIndex: selectedNavIndex,
            onDestinationSelected: (idx) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => MainScreen(initialIndex: idx)),
                (route) => false,
              );
            },
          ),
          Expanded(
            child: GameDetailsScreen(
              article: article,
              mirrors: mirrors,
              embedded: true,
              onBack: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

// Placeholder chips used to show limited metadata until backend supplies more.
