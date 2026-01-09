import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/download_manager.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom/custom_button.dart';
import '../widgets/custom/custom_scrollbar.dart';

/// Screen to display extracted download URLs from decrypted PrivateBin paste
class ExtractedLinksScreen extends StatefulWidget {
  final String mirrorName;
  final List<String> urls;

  const ExtractedLinksScreen({
    super.key,
    required this.mirrorName,
    required this.urls,
  });

  @override
  State<ExtractedLinksScreen> createState() => _ExtractedLinksScreenState();
}

class _ExtractedLinksScreenState extends State<ExtractedLinksScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section with close button
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
                Row(
                  children: [
                    const Icon(
                      Icons.link,
                      size: 28,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Download Links',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontFamily: 'SpaceGrotesk',
                            ),
                          ),
                          Text(
                            widget.mirrorName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.slate400,
                              fontFamily: 'NotoSans',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButtonCustom(
                      icon: Icons.close,
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.urls.length} link${widget.urls.length != 1 ? 's' : ''} extracted',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.slate400,
                    fontFamily: 'NotoSans',
                  ),
                ),
              ],
            ),
          ),

          // URLs list with smooth scrolling
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false,
                physics: const BouncingScrollPhysics(),
              ),
              child: CustomScrollbar(
                controller: _scrollController,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(24.0),
                  itemCount: widget.urls.length,
                  itemBuilder: (context, index) {
                    final url = widget.urls[index];
                    return _ExtractedLinkCard(url: url, index: index + 1);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual extracted link card
class _ExtractedLinkCard extends StatefulWidget {
  final String url;
  final int index;

  const _ExtractedLinkCard({required this.url, required this.index});

  @override
  State<_ExtractedLinkCard> createState() => _ExtractedLinkCardState();
}

class _ExtractedLinkCardState extends State<_ExtractedLinkCard> {
  bool _isHovered = false;
  bool _isProcessing = false;
  final DownloadManager _downloadManager = DownloadManager();
  final ApiService _apiService = ApiService();

  bool _isFuckingFastLink() {
    return widget.url.toLowerCase().contains('fuckingfast');
  }

  Future<void> _handleDownload(BuildContext context) async {
    if (_isFuckingFastLink()) {
      // Extract real download URL from FuckingFast page
      await _extractAndDownloadFromFuckingFast(context);
    } else {
      // Direct download
      await _startDirectDownload(context);
    }
  }

  Future<void> _extractAndDownloadFromFuckingFast(BuildContext context) async {
    setState(() => _isProcessing = true);

    try {
      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Extracting download link from FuckingFast...'),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );

      // Extract real download URL
      final buttons = await _apiService.extractFuckingFastButtons(widget.url);

      if (!mounted) return;

      if (buttons.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No download links found on this page'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isProcessing = false);
        return;
      }

      // Use the first download link found
      final downloadUrl = buttons.first.url;
      final fileName = _extractFileName(downloadUrl);

      // Start download
      await _downloadManager.startDownload(downloadUrl, fileName);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download started: $fileName'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              // TODO: Navigate to downloads tab
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to extract download: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _startDirectDownload(BuildContext context) async {
    setState(() => _isProcessing = true);

    try {
      final fileName = _extractFileName(widget.url);
      await _downloadManager.startDownload(widget.url, fileName);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download started: $fileName'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              // TODO: Navigate to downloads tab
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start download: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  String _extractFileName(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final fileName = pathSegments.last;
        if (fileName.isNotEmpty && fileName.contains('.')) {
          return fileName;
        }
      }
      // Fallback to generic name
      return 'download_${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      return 'download_${DateTime.now().millisecondsSinceEpoch}';
    }
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

  IconData _getIconForUrl(String url) {
    final urlLower = url.toLowerCase();
    if (urlLower.contains('magnet:')) {
      return Icons.download;
    } else if (urlLower.contains('torrent')) {
      return Icons.cloud_download;
    } else if (urlLower.contains('gofile')) {
      return Icons.folder;
    } else if (urlLower.contains('filecrypt')) {
      return Icons.lock;
    } else {
      return Icons.language;
    }
  }

  @override
  Widget build(BuildContext context) {
    final domain = _getDomainFromUrl(widget.url);
    final icon = _getIconForUrl(widget.url);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Card(
          elevation: _isHovered ? 4 : 2,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with index and domain
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

                    // Icon
                    Icon(
                      icon,
                      color: AppTheme.primary,
                      size: 24,
                    ),

                    const SizedBox(width: 12),

                    // Domain name
                    Expanded(
                      child: Text(
                        domain,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.slate300,
                            fontFamily: 'SpaceGrotesk'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Full URL
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.slate800),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.link,
                        size: 16,
                        color: AppTheme.slate400,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.url,
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.slate300,
                              fontFamily: 'NotoSans',
                            ),
                          maxLines: 2,
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
                    // Copy button
                    OutlinedButton.icon(
                      onPressed: _isProcessing ? null : () => _copyLink(context),
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy'),
                    ),

                    const SizedBox(width: 8),

                    // Download button (replaces Open button)
                    FilledButton.icon(
                      onPressed: _isProcessing ? null : () => _handleDownload(context),
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(
                              _isFuckingFastLink() ? Icons.download : Icons.download,
                              size: 18,
                            ),
                      label: Text(_isFuckingFastLink() ? 'Download' : 'Download'),
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
