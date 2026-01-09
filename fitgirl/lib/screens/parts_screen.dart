import 'package:flutter/material.dart';
import '../models/article_link.dart';
import '../services/api_service.dart';
import '../services/download_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/custom/breadcrumb_navigation.dart';
import '../widgets/custom/custom_button.dart';
import '../widgets/custom/custom_scrollbar.dart';

class PartItem {
  final String filename;
  final String size;
  final PartStatus status;
  final String url;

  const PartItem({required this.filename, required this.size, required this.status, required this.url});
}

enum PartStatus { online, offline, slow }

/// Download provider parts table inspired by the HTML mockup.
class PartsScreen extends StatefulWidget {
  final ArticleLink article;
  final String providerName;
  final List<String> urls;
  final bool embedded;
  final VoidCallback? onBack;
  final VoidCallback? onNavigateToDownloads;

  const PartsScreen({
    super.key,
    required this.article,
    required this.providerName,
    required this.urls,
    this.embedded = false,
    this.onBack,
    this.onNavigateToDownloads,
  });

  @override
  State<PartsScreen> createState() => _PartsScreenState();
}

class _PartsScreenState extends State<PartsScreen> {
  late final ScrollController _pageController;
  final DownloadManager _downloadManager = DownloadManager();
  final ApiService _apiService = ApiService();
  final Set<int> _processing = {};

  String _regexFilename(String source) {
    // Capture common archive filename patterns embedded in query strings or paths.
    final match = RegExp(r'[^/?&]*part\d+\.\w+', caseSensitive: false).firstMatch(source);
    return match?.group(0) ?? '';
  }

  String _stripHashPrefix(String input) {
    // Some providers prepend a token before '#' — keep only what follows the last '#'.
    if (!input.contains('#')) return input.trim();
    return input.split('#').last.trim();
  }

  @override
  void initState() {
    super.initState();
    _pageController = ScrollController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<PartItem> _mapUrlsToParts() {
    return List.generate(widget.urls.length, (index) {
      final url = widget.urls[index];
      final decoded = Uri.decodeFull(url);
      final uri = Uri.tryParse(decoded);

      String name = 'part-${index + 1}.rar';
      if (uri != null) {
        // Prefer explicit filename query param if present.
        final filenameParam = uri.queryParameters.entries
            .firstWhere(
              (e) => e.key.toLowerCase().contains('file') || e.key.toLowerCase().contains('name'),
              orElse: () => const MapEntry('', ''),
            )
            .value;

        if (filenameParam.isNotEmpty) {
          name = filenameParam;
        } else if (_regexFilename(decoded).isNotEmpty) {
          name = _regexFilename(decoded);
        } else if (uri.pathSegments.isNotEmpty) {
          name = uri.pathSegments.last;
        } else {
          name = decoded.split('/').isNotEmpty ? decoded.split('/').last : decoded;
        }
      } else {
        final regexName = _regexFilename(decoded);
        name = regexName.isNotEmpty
            ? regexName
            : (decoded.split('/').isNotEmpty ? decoded.split('/').last : decoded);
      }

      name = _stripHashPrefix(name);

      final lowered = url.toLowerCase();
      final status = lowered.contains('offline')
          ? PartStatus.offline
          : lowered.contains('slow')
              ? PartStatus.slow
              : PartStatus.online;

      return PartItem(
        filename: name,
        size: 'Unknown',
        status: status,
        url: url,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final parts = _mapUrlsToParts();

    final content = CustomScrollbar(
      controller: _pageController,
      child: SingleChildScrollView(
        controller: _pageController,
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: _buildTable(parts),
            ),
            _buildFooter(parts),
          ],
        ),
      ),
    );

    if (widget.embedded) {
      return Container(color: AppTheme.backgroundDark, child: content);
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: content,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF111A22),
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.onBack != null) ...[
            Row(
              children: [
                SecondaryButton(
                  label: 'Back to details',
                  icon: Icons.arrow_back,
                  onPressed: widget.onBack,
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          BreadcrumbNavigation(
            items: [
              BreadcrumbItem(label: 'Search', icon: Icons.search),
              BreadcrumbItem(label: widget.article.title, icon: Icons.videogame_asset),
              BreadcrumbItem(label: widget.providerName, icon: Icons.cloud_download),
              const BreadcrumbItem(label: 'Parts', icon: Icons.table_rows),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.providerName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.slate800,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: const Text(
                  'Updated recently',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.slate300,
                    fontFamily: 'NotoSans',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.article.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Verify and download individual parts. Ensure you have enough disk space before proceeding.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.slate400,
              fontFamily: 'NotoSans',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SecondaryButton(
                label: 'Copy Links',
                icon: Icons.copy,
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              PrimaryButton(
                label: 'Download All',
                icon: Icons.download,
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<PartItem> parts) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeaderRow(),
          const Divider(height: 1, color: AppTheme.borderColor),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: parts.length,
            itemBuilder: (context, index) {
              final part = parts[index];
              return _buildRow(part, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      color: const Color(0xFF192633),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: const [
          Expanded(
            flex: 6,
            child: Text(
              'Filename',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.slate300,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Size',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.slate300,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Status',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.slate300,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Action',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate300,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(PartItem part, int index) {
    final statusChip = _statusChip(part.status);

    return Container(
      decoration: BoxDecoration(
        color: index.isEven ? AppTheme.surfaceDark : AppTheme.surfaceHover.withOpacity(0.2),
        border: const Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF233648),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.folder_zip, color: AppTheme.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    part.filename,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'NotoSans',
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              part.size,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.slate400,
                fontFamily: 'Monospace',
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: statusChip,
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: PrimaryButton(
                label: _processing.contains(index) ? 'Working...' : 'Download',
                icon: _processing.contains(index) ? Icons.hourglass_empty : Icons.download,
                onPressed: _processing.contains(index)
                    ? null
                    : () => _handleDownload(part, index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDownload(PartItem part, int index) async {
    setState(() => _processing.add(index));

    try {
      var downloadUrl = part.url;

      if (_isFuckingFast(part.url)) {
        final buttons = await _apiService.extractFuckingFastButtons(part.url);
        if (buttons.isEmpty) {
          _showSnack('No download buttons found for this provider', Colors.orange);
          setState(() => _processing.remove(index));
          return;
        }
        downloadUrl = buttons.first.url;
      }

      final fileName = _extractFileName(downloadUrl);
      await _downloadManager.startDownload(downloadUrl, fileName);
      _showSnack('Download started: $fileName', Colors.green);
    } catch (e) {
      _showSnack('Download failed: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _processing.remove(index));
      }
    }
  }

  bool _isFuckingFast(String url) => url.toLowerCase().contains('fuckingfast');

  String _extractFileName(String url) {
    try {
      final uri = Uri.parse(url);
      final last = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'download.bin';
      if (last.isNotEmpty) return last;
    } catch (_) {}
    return 'download.bin';
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Expanded(child: Text(message)),
            if (widget.onNavigateToDownloads != null)
              TextButton(
                onPressed: () {
                  widget.onNavigateToDownloads?.call();
                },
                child: const Text('View', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
        backgroundColor: color,
      ),
    );
  }

  Widget _statusChip(PartStatus status) {
    Color bg;
    Color border;
    Color fg;
    String label;

    switch (status) {
      case PartStatus.offline:
        bg = Colors.red.withOpacity(0.1);
        border = Colors.red.withOpacity(0.2);
        fg = Colors.red;
        label = 'Offline';
        break;
      case PartStatus.slow:
        bg = Colors.amber.withOpacity(0.1);
        border = Colors.amber.withOpacity(0.2);
        fg = Colors.amber;
        label = 'Slow';
        break;
      case PartStatus.online:
      default:
        bg = Colors.green.withOpacity(0.1);
        border = Colors.green.withOpacity(0.2);
        fg = Colors.green;
        label = 'Online';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
              fontFamily: 'NotoSans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(List<PartItem> parts) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF111A22),
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Row(
            children: [
              const Icon(Icons.folder_open, size: 18, color: AppTheme.slate500),
              const SizedBox(width: 8),
              Text(
                'Parts: ${parts.length}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.slate300,
                  fontFamily: 'NotoSans',
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 18, color: AppTheme.slate700),
          const SizedBox(width: 16),
          const Text(
            'Powered by provider API',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'NotoSans',
            ),
          ),
          const Spacer(),
          const Text(
            'Mock data only — hook up real sizes/status when available',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.slate500,
              fontFamily: 'NotoSans',
            ),
          ),
        ],
      ),
    );
  }
}
