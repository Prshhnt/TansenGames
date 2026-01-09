import 'package:flutter/material.dart';
import '../models/article_link.dart';
import '../models/download_link.dart';
import '../services/search_history_service.dart';
import '../services/api_service.dart';
import '../widgets/download_links_widget.dart';
import '../theme/app_theme.dart';
import '../widgets/custom/custom_button.dart';

/// History screen showing clicked article links
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final SearchHistoryService _historyService = SearchHistoryService();
  final ApiService _apiService = ApiService();
  List<Map<String, String>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await _historyService.getArticleHistory();
    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all history?'),
        actions: [
          SecondaryButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context, false),
          ),
          const SizedBox(width: 8),
          PrimaryButton(
            label: 'Clear',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _historyService.clearHistory();
      _loadHistory();
    }
  }

  Future<void> _removeItem(String url) async {
    await _historyService.removeFromHistory(url);
    _loadHistory();
  }

  Future<void> _fetchDownloadMirrors(String title, String url) async {
    try {
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
                  'Fetching download mirrors...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );

      final links = await _apiService.fetchDownloadMirrors(url);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Show download mirrors in full screen without app bar
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            body: links.isEmpty
                ? const Center(child: Text('No download mirrors found'))
                : DownloadLinksWidget(
                    article: ArticleLink(title: title, url: url),
                    downloadMirrors: links,
                    onBack: () => Navigator.pop(context),
                  ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Show error
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
          actions: [
            PrimaryButton(
              label: 'OK',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Custom header replacing AppBar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceDark,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderColor),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.history,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 12),
                const Text(
                  'History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
                const Spacer(),
                SecondaryButton(
                  label: 'Clear history',
                  icon: Icons.delete_sweep,
                  onPressed: _history.isNotEmpty ? _clearHistory : null,
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _history.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: AppTheme.primary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No history yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontFamily: 'SpaceGrotesk',
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Articles you visit will appear here',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.slate400,
                                fontFamily: 'NotoSans',
                              ),
                            ),
                          ],
                        ),
                      )
                    : ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          scrollbars: true,
                          physics: const BouncingScrollPhysics(),
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _history.length,
                          itemBuilder: (context, index) {
                            final article = _history[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _fetchDownloadMirrors(
                                    article['title']!,
                                    article['url']!,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.videogame_asset,
                                          color: AppTheme.primary,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                article['title']!,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                  fontFamily: 'SpaceGrotesk',
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _formatTimestamp(article['timestamp']!),
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
                                          tooltip: 'Remove',
                                          onPressed: () => _removeItem(article['url']!),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) {
        return '${diff.inMinutes} minutes ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} hours ago';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }
}
