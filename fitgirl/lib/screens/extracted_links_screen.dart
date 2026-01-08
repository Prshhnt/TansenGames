import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen to display extracted download URLs from decrypted PrivateBin paste
class ExtractedLinksScreen extends StatelessWidget {
  final String mirrorName;
  final List<String> urls;

  const ExtractedLinksScreen({
    super.key,
    required this.mirrorName,
    required this.urls,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(mirrorName)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
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
                Row(
                  children: [
                    Icon(
                      Icons.link,
                      size: 28,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Download Links',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${urls.length} link${urls.length != 1 ? 's' : ''} extracted',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),

          // URLs list with smooth scrolling
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: true,
                physics: const BouncingScrollPhysics(),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(24.0),
                itemCount: urls.length,
                itemBuilder: (context, index) {
                  final url = urls[index];
                  return _ExtractedLinkCard(url: url, index: index + 1);
                },
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

  Future<void> _openLink(BuildContext context) async {
    final uri = Uri.parse(widget.url);

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

                    // Icon
                    Icon(
                      icon,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),

                    const SizedBox(width: 12),

                    // Domain name
                    Expanded(
                      child: Text(
                        domain,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Full URL
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
                          widget.url,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.8),
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
                      onPressed: () => _copyLink(context),
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy'),
                    ),

                    const SizedBox(width: 8),

                    // Open button
                    FilledButton.icon(
                      onPressed: () => _openLink(context),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Open'),
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
