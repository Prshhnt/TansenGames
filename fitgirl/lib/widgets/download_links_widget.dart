import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/article_link.dart';
import '../models/download_link.dart';
import '../services/api_service.dart';
import '../screens/extracted_links_screen.dart';

/// Displays download mirrors for a selected article
/// Allows users to open or copy links
class DownloadLinksWidget extends StatelessWidget {
  final ArticleLink article;
  final List<DownloadLink> downloadMirrors;
  final VoidCallback onBack;

  const DownloadLinksWidget({
    super.key,
    required this.article,
    required this.downloadMirrors,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with back button and article title
        Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              TextButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to search results'),
              ),

              const SizedBox(height: 12),

              // Article title
              Text(
                article.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // Mirror count
              Text(
                '${downloadMirrors.length} download mirror${downloadMirrors.length != 1 ? 's' : ''} found',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),

        // Download mirrors list with smooth scrolling
        Expanded(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              scrollbars: true,
              physics: const BouncingScrollPhysics(),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(24.0),
              itemCount: downloadMirrors.length,
              itemBuilder: (context, index) {
                final link = downloadMirrors[index];

                return _DownloadLinkCard(link: link, index: index + 1);
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

  const _DownloadLinkCard({required this.link, required this.index});

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
      // Open regular link in browser
      await _openLink(context);
    }
  }

  Future<void> _decryptAndShowLinks(BuildContext context) async {
    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Decrypting and extracting links...'),
              ],
            ),
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

      // Navigate to extracted links screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ExtractedLinksScreen(mirrorName: widget.link.text, urls: urls),
        ),
      );
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

  Future<void> _openLink(BuildContext context) async {
    final uri = Uri.parse(widget.link.url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open link')));
      }
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
        child: Card(
          elevation: _isHovered ? 4 : 2,
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
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${widget.index}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
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
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
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
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock,
                                    size: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'ENCRYPTED',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
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
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.link,
                        size: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.link.url,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.8),
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
                    // Copy button
                    OutlinedButton.icon(
                      onPressed: () => _copyLink(context),
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy'),
                    ),

                    const SizedBox(width: 8),

                    // Main action button (Decrypt or Open)
                    FilledButton.icon(
                      onPressed: () => _handleLinkClick(context),
                      icon: Icon(
                        isPrivateBin ? Icons.lock_open : Icons.open_in_new,
                        size: 18,
                      ),
                      label: Text(isPrivateBin ? 'Decrypt' : 'Open'),
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
