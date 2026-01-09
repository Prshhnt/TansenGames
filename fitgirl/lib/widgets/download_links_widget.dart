import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/article_link.dart';
import '../models/download_link.dart';
import '../services/api_service.dart';
import '../services/download_manager.dart';
import '../theme/app_theme.dart';
import 'custom/custom_button.dart';
import 'custom/breadcrumb_navigation.dart';
import 'custom/status_badge.dart';
import 'custom/custom_scrollbar.dart';
import '../screens/game_details_screen.dart';
import '../screens/parts_screen.dart';

/// Displays download mirrors for a selected article
/// Allows users to open or copy links
class DownloadLinksWidget extends StatefulWidget {
  final ArticleLink article;
  final List<DownloadLink> downloadMirrors;
  final VoidCallback onBack;
  final VoidCallback? onNavigateToDownloads;

  const DownloadLinksWidget({
    super.key,
    required this.article,
    required this.downloadMirrors,
    required this.onBack,
    this.onNavigateToDownloads,
  });

  @override
  State<DownloadLinksWidget> createState() => _DownloadLinksWidgetState();
}

class _DownloadLinksWidgetState extends State<DownloadLinksWidget> {
  // Track if we're showing extracted links
  bool _showingExtractedLinks = false;
  String _extractedMirrorName = '';
  List<String> _extractedUrls = [];
  final ScrollController _mirrorsScrollController = ScrollController();
  final ScrollController _extractedScrollController = ScrollController();

  @override
  void dispose() {
    _mirrorsScrollController.dispose();
    _extractedScrollController.dispose();
    super.dispose();
  }

  void _showExtractedLinks(String mirrorName, List<String> urls) {
    setState(() {
      _showingExtractedLinks = true;
      _extractedMirrorName = mirrorName;
      _extractedUrls = urls;
    });
  }

  void _backToMirrors() {
    setState(() {
      _showingExtractedLinks = false;
      _extractedMirrorName = '';
      _extractedUrls = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showingExtractedLinks) {
      // Show extracted links view
      return _ExtractedLinksView(
        article: widget.article,
        mirrorName: _extractedMirrorName,
        urls: _extractedUrls,
        onBack: _backToMirrors,
        onBackToSearch: widget.onBack,
        scrollController: _extractedScrollController,
        onNavigateToDownloads: widget.onNavigateToDownloads,
      );
    }

    // Show download mirrors view
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with back button and article title
        Container(
          padding: const EdgeInsets.all(24.0),
          decoration: const BoxDecoration(
            color: AppTheme.backgroundDark,
            border: Border(
              bottom: BorderSide(
                color: AppTheme.borderColor,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumb navigation
              BreadcrumbNavigation(
                items: [
                  BreadcrumbItem(
                    label: 'Search',
                    icon: Icons.search,
                    onTap: widget.onBack,
                  ),
                  BreadcrumbItem(
                    label: 'Download Mirrors',
                    icon: Icons.download,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Article title
              Text(
                widget.article.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),

              const SizedBox(height: 8),

              // Mirror count
              Text(
                '${widget.downloadMirrors.length} download mirror${widget.downloadMirrors.length != 1 ? 's' : ''} found',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.slate400,
                  fontFamily: 'NotoSans',
                ),
              ),

              const SizedBox(height: 12),

              // Actions
              Row(
                children: [
                  SecondaryButton(
                    label: 'View Details',
                    icon: Icons.visibility,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GameDetailsScreen(
                            article: widget.article,
                            mirrors: widget.downloadMirrors,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // Download mirrors list with smooth scrolling
        Expanded(
          child: CustomScrollbar(
            controller: _mirrorsScrollController,
            child: ListView.builder(
              controller: _mirrorsScrollController,
              padding: const EdgeInsets.all(24.0),
              itemCount: widget.downloadMirrors.length,
              itemBuilder: (context, index) {
                final link = widget.downloadMirrors[index];

                return _DownloadLinkCard(
                  link: link,
                  index: index + 1,
                  onShowExtractedLinks: _showExtractedLinks,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Individual download mirror card with actions
class _DownloadLinkCard extends StatefulWidget {
  final DownloadLink link;
  final int index;
  final Function(String, List<String>) onShowExtractedLinks;

  const _DownloadLinkCard({
    required this.link,
    required this.index,
    required this.onShowExtractedLinks,
  });

  @override
  State<_DownloadLinkCard> createState() => _DownloadLinkCardState();
}

class _DownloadLinkCardState extends State<_DownloadLinkCard> {
  final ApiService _apiService = ApiService();
  bool _isHovered = false;

  bool _isPrivateBinLink() {
    return widget.link.url.contains('paste.fitgirl-repacks.site');
  }

  Future<void> _handleLinkClick(BuildContext context) async {
    if (_isPrivateBinLink()) {
      // Decrypt PrivateBin paste and show extracted links
      await _decryptAndShowLinks(context);
    } else {
      // Copy regular link (these are article links, not direct downloads)
      await _copyLink(context);
    }
  }

  void _showExtractedLinksInline(
      BuildContext context, String mirrorName, List<String> urls) {
    widget.onShowExtractedLinks(mirrorName, urls);
  }

  Future<void> _decryptAndShowLinks(BuildContext context) async {
    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.primary),
              SizedBox(height: 16),
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
      final urls = await _apiService.decryptPaste(widget.link.url);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (urls.isEmpty) {
        // Show no links found message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No links found in this paste')),
        );
        return;
      }

      // Show extracted links inline by calling parent widget's callback
      if (!mounted) return;
      _showExtractedLinksInline(context, widget.link.text, urls);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: widget.link.url));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPrivateBin = _isPrivateBinLink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered ? AppTheme.primary.withOpacity(0.5) : AppTheme.borderColor,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with index and title
                Row(
                  children: [
                    // Index badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${widget.index}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Link text with badge for PrivateBin
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.link.text,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontFamily: 'SpaceGrotesk',
                              ),
                            ),
                          ),
                          if (isPrivateBin) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.statusWarning.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock,
                                    size: 12,
                                    color: AppTheme.statusWarning,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'ENCRYPTED',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.statusWarning,
                                      fontFamily: 'SpaceGrotesk',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // URL
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.slate800),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.link,
                        size: 16,
                        color: AppTheme.slate500,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.link.url,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.slate400,
                            fontFamily: 'NotoSans',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SecondaryButton(
                      label: 'Copy',
                      icon: Icons.copy,
                      onPressed: () => _copyLink(context),
                    ),
                    const SizedBox(width: 8),
                    PrimaryButton(
                      label: isPrivateBin ? 'Decrypt' : 'Open',
                      icon: isPrivateBin ? Icons.lock_open : Icons.open_in_new,
                      onPressed: () => _handleLinkClick(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// View for displaying extracted links from decrypted PrivateBin paste
class _ExtractedLinksView extends StatelessWidget {
  final ArticleLink article;
  final String mirrorName;
  final List<String> urls;
  final VoidCallback onBack;
  final VoidCallback onBackToSearch;
  final ScrollController scrollController;
  final VoidCallback? onNavigateToDownloads;

  const _ExtractedLinksView({
    required this.article,
    required this.mirrorName,
    required this.urls,
    required this.onBack,
    required this.onBackToSearch,
    required this.scrollController,
    this.onNavigateToDownloads,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with navigation
        Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: AppTheme.backgroundDark,
            border: Border(
              bottom: BorderSide(
                color: AppTheme.borderColor,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumb navigation
              BreadcrumbNavigation(
                items: [
                  BreadcrumbItem(
                    label: 'Search',
                    icon: Icons.search,
                    onTap: onBackToSearch,
                  ),
                  BreadcrumbItem(
                    label: 'Mirrors',
                    icon: Icons.download,
                    onTap: onBack,
                  ),
                  BreadcrumbItem(
                    label: 'Extracted Links',
                    icon: Icons.lock_open,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Article title
              Text(
                article.title,
                style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.slate300,
                      fontFamily: 'SpaceGrotesk',
                    ),
              ),

              const SizedBox(height: 12),

              // Mirror name and link count with badge
              Row(
                children: [
                  StatusBadge(
                    label: mirrorName,
                    type: StatusBadgeType.success,
                    icon: Icons.lock_open,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${urls.length} link${urls.length != 1 ? 's' : ''} extracted',
                    style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.slate400,
                          fontFamily: 'NotoSans',
                        ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  SecondaryButton(
                    label: 'Open Parts View',
                    icon: Icons.table_rows,
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: AppTheme.backgroundDark,
                        builder: (_) {
                          return SafeArea(
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.85,
                              child: PartsScreen(
                                article: article,
                                providerName: mirrorName,
                                urls: urls,
                                embedded: true,
                                onNavigateToDownloads: onNavigateToDownloads,
                                onBack: () => Navigator.of(context).pop(),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // Extracted URLs list
        Expanded(
          child: CustomScrollbar(
            controller: scrollController,
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(24.0),
              itemCount: urls.length,
              itemBuilder: (context, index) {
                final url = urls[index];
                return _ExtractedUrlCard(
                  url: url,
                  index: index + 1,
                  onNavigateToDownloads: onNavigateToDownloads,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Card for individual extracted URL
class _ExtractedUrlCard extends StatefulWidget {
  final String url;
  final int index;
  final VoidCallback? onNavigateToDownloads;

  const _ExtractedUrlCard({required this.url, required this.index, this.onNavigateToDownloads});

  @override
  State<_ExtractedUrlCard> createState() => _ExtractedUrlCardState();
}

class _ExtractedUrlCardState extends State<_ExtractedUrlCard> {
  bool _isHovered = false;
  bool _isProcessing = false;
  final _apiService = ApiService();
  final _downloadManager = DownloadManager();

  bool _isFuckingFastLink(String url) {
    return url.toLowerCase().contains('fuckingfast.co');
  }

  String _extractFileName(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.last;
      }
      return 'download_${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      return 'download_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<void> _handleDownload(BuildContext context) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      if (_isFuckingFastLink(widget.url)) {
        await _extractAndDownloadFromFuckingFast(context);
      } else {
        await _startDirectDownload(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _extractAndDownloadFromFuckingFast(BuildContext context) async {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Extracting download URLs from FuckingFast...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final downloadLinks =
          await _apiService.extractFuckingFastButtons(widget.url);

      if (!context.mounted) return;

      if (downloadLinks.isNotEmpty) {
        // Start download with the first button URL
        final downloadUrl = downloadLinks.first.url;
        final fileName = _extractFileName(downloadUrl);

        _downloadManager.startDownload(downloadUrl, fileName);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Expanded(child: Text('Download started: $fileName')),
                if (widget.onNavigateToDownloads != null)
                  TextButton(
                    onPressed: widget.onNavigateToDownloads,
                    child: const Text('View', style: TextStyle(color: Colors.white)),
                  ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No download URLs found on FuckingFast page'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error extracting download URL: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _startDirectDownload(BuildContext context) async {
    final fileName = _extractFileName(widget.url);

    _downloadManager.startDownload(widget.url, fileName);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Expanded(child: Text('Download started: $fileName')),
            if (widget.onNavigateToDownloads != null)
              TextButton(
                onPressed: widget.onNavigateToDownloads,
                child: const Text('View', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: widget.url));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _getDomainFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final domain = _getDomainFromUrl(widget.url);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isHovered ? AppTheme.surfaceLight : AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? AppTheme.primary.withOpacity(0.4)
                  : AppTheme.borderColor,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 8),
                    )
                  ]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${widget.index}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'NotoSans',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            domain,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'SpaceGrotesk',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              StatusBadge(
                                label: _isFuckingFastLink(widget.url)
                                    ? 'FuckingFast'
                                    : 'Direct',
                                type: _isFuckingFastLink(widget.url)
                                    ? StatusBadgeType.warning
                                    : StatusBadgeType.success,
                                icon: _isFuckingFastLink(widget.url)
                                    ? Icons.flash_on
                                    : Icons.download,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _extractFileName(widget.url),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.slate400,
                                  fontFamily: 'NotoSans',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // URL
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.slate800),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.link,
                        size: 16,
                        color: AppTheme.slate400,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.url,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.slate300,
                            fontFamily: 'NotoSans',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SecondaryButton(
                      label: 'Copy',
                      icon: Icons.copy,
                      onPressed:
                          _isProcessing ? null : () => _copyLink(context),
                    ),
                    const SizedBox(width: 8),
                    PrimaryButton(
                      label: 'Download',
                      icon: Icons.download_rounded,
                      isLoading: _isProcessing,
                      onPressed:
                          _isProcessing ? null : () => _handleDownload(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
