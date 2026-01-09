import 'package:flutter/material.dart';
import '../services/download_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/custom/custom_button.dart';
import '../widgets/custom/status_badge.dart';
import '../widgets/custom/custom_scrollbar.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final DownloadManager _downloadManager = DownloadManager();
  final ScrollController _downloadsScrollController = ScrollController();

  @override
  void dispose() {
    _downloadsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundDark,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildDownloads()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.download,
            color: AppTheme.primary,
          ),
          const SizedBox(width: 12),
          const Text(
            'Downloads',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
          const Spacer(),
          StreamBuilder<List<DownloadTask>>(
            stream: _downloadManager.downloadsStream,
            builder: (context, snapshot) {
              final hasCompleted = snapshot.data?.any(
                    (task) => task.status == DownloadStatus.completed,
                  ) ??
                  false;

              return SecondaryButton(
                label: 'Clear Completed',
                icon: Icons.clear_all,
                onPressed: hasCompleted
                    ? () {
                        _downloadManager.clearCompleted();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cleared completed downloads'),
                          ),
                        );
                      }
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDownloads() {
    return StreamBuilder<List<DownloadTask>>(
      stream: _downloadManager.downloadsStream,
      initialData: _downloadManager.downloads,
      builder: (context, snapshot) {
        final downloads = snapshot.data ?? [];

        if (downloads.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.download_outlined,
                  size: 64,
                  color: AppTheme.slate400,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No downloads yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.slate300,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Downloads will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.slate500,
                    fontFamily: 'NotoSans',
                  ),
                ),
              ],
            ),
          );
        }

        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: CustomScrollbar(
            controller: _downloadsScrollController,
            child: ListView(
              controller: _downloadsScrollController,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                _buildTableHeader(),
                const SizedBox(height: 12),
                ...downloads.map(_buildDownloadRow),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: const [
          _HeaderCell(label: 'File', flex: 5),
          _HeaderCell(label: 'Status', flex: 2),
          _HeaderCell(label: 'Progress', flex: 3),
          _HeaderCell(label: 'Actions', flex: 2, alignEnd: true),
        ],
      ),
    );
  }

  Widget _buildDownloadRow(DownloadTask task) {
    return _DownloadRow(
      task: task,
      onPause: () => _downloadManager.pauseDownload(task.id),
      onResume: () => _downloadManager.resumeDownload(task.id),
      onCancel: () => _downloadManager.cancelDownload(task.id),
      onRetry: () => _downloadManager.retryDownload(task.id),
      onRemove: () => _downloadManager.removeDownload(task.id),
      onOpen: () => _downloadManager.openFileLocation(task.id),
    );
  }

}

class _DownloadRow extends StatefulWidget {
  final DownloadTask task;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;
  final VoidCallback onRetry;
  final VoidCallback onRemove;
  final VoidCallback onOpen;

  const _DownloadRow({
    required this.task,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.onRetry,
    required this.onRemove,
    required this.onOpen,
  });

  @override
  State<_DownloadRow> createState() => _DownloadRowState();
}

class _DownloadRowState extends State<_DownloadRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.surfaceHover : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? AppTheme.primary.withOpacity(0.4)
                : AppTheme.borderColor,
          ),
        ),
        child: Row(
          children: [
            // File column
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.fileName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'SpaceGrotesk',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.statusText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.slate400,
                      fontFamily: 'NotoSans',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Status column
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(
                  label: task.statusText,
                  type: _statusType(task.status),
                ),
              ),
            ),

            // Progress column
            Expanded(
              flex: 3,
              child: task.status == DownloadStatus.downloading ||
                      task.status == DownloadStatus.paused
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProgressBar(progress: task.progress),
                        const SizedBox(height: 6),
                        Text(
                          task.progressText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.slate400,
                            fontFamily: 'NotoSans',
                          ),
                        ),
                      ],
                    )
                  : Text(
                      task.status == DownloadStatus.completed
                          ? 'Ready'
                          : task.statusText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.slate400,
                        fontFamily: 'NotoSans',
                      ),
                    ),
            ),

            // Actions column
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: _buildActions(task),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(DownloadTask task) {
    switch (task.status) {
      case DownloadStatus.downloading:
        return IconButtonCustom(
          icon: Icons.pause,
          tooltip: 'Pause',
          onPressed: widget.onPause,
        );
      case DownloadStatus.paused:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButtonCustom(
              icon: Icons.play_arrow,
              tooltip: 'Resume',
              onPressed: widget.onResume,
            ),
            const SizedBox(width: 8),
            IconButtonCustom(
              icon: Icons.cancel,
              tooltip: 'Cancel',
              onPressed: widget.onCancel,
            ),
          ],
        );
      case DownloadStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButtonCustom(
              icon: Icons.refresh,
              tooltip: 'Retry',
              onPressed: widget.onRetry,
            ),
            const SizedBox(width: 8),
            IconButtonCustom(
              icon: Icons.delete,
              tooltip: 'Remove',
              onPressed: widget.onRemove,
            ),
          ],
        );
      case DownloadStatus.completed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButtonCustom(
              icon: Icons.folder_open,
              tooltip: 'Open folder',
              onPressed: widget.onOpen,
            ),
            const SizedBox(width: 8),
            IconButtonCustom(
              icon: Icons.delete,
              tooltip: 'Remove',
              onPressed: widget.onRemove,
            ),
          ],
        );
      case DownloadStatus.cancelled:
      case DownloadStatus.queued:
        return IconButtonCustom(
          icon: Icons.delete,
          tooltip: 'Remove',
          onPressed: widget.onRemove,
        );
    }
  }

  StatusBadgeType _statusType(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
        return StatusBadgeType.info;
      case DownloadStatus.paused:
        return StatusBadgeType.warning;
      case DownloadStatus.completed:
        return StatusBadgeType.success;
      case DownloadStatus.failed:
        return StatusBadgeType.error;
      case DownloadStatus.cancelled:
      case DownloadStatus.queued:
        return StatusBadgeType.neutral;
    }
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;

  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: AppTheme.slate800,
        borderRadius: BorderRadius.circular(6),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryDark],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final int flex;
  final bool alignEnd;

  const _HeaderCell({
    required this.label,
    required this.flex,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.slate400,
            fontFamily: 'NotoSans',
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

