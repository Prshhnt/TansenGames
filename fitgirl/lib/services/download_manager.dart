import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Represents a single download task
class DownloadTask {
  final String id;
  final String url;
  final String fileName;
  String filePath;
  DownloadStatus status;
  double progress;
  int downloadedBytes;
  int totalBytes;
  String? error;
  CancelToken? cancelToken;

  DownloadTask({
    required this.id,
    required this.url,
    required this.fileName,
    this.filePath = '',
    this.status = DownloadStatus.queued,
    this.progress = 0.0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.error,
    this.cancelToken,
  });

  String get statusText {
    switch (status) {
      case DownloadStatus.queued:
        return 'Queued';
      case DownloadStatus.downloading:
        return 'Downloading';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.completed:
        return 'Completed';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get progressText {
    if (totalBytes > 0) {
      final downloaded = _formatBytes(downloadedBytes);
      final total = _formatBytes(totalBytes);
      return '$downloaded / $total (${(progress * 100).toStringAsFixed(1)}%)';
    }
    return '${(progress * 100).toStringAsFixed(1)}%';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

enum DownloadStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

/// Download Manager - handles all file downloads in the app
class DownloadManager {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  final Dio _dio = Dio();
  final Map<String, DownloadTask> _downloads = {};
  final StreamController<List<DownloadTask>> _downloadsController =
      StreamController<List<DownloadTask>>.broadcast();

  Stream<List<DownloadTask>> get downloadsStream => _downloadsController.stream;
  List<DownloadTask> get downloads => _downloads.values.toList();

  /// Start a new download
  Future<String> startDownload(String url, String fileName) async {
    // Generate unique ID for this download
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    // Get downloads directory
    final downloadsDir = await _getDownloadsDirectory();
    final filePath = path.join(downloadsDir, fileName);

    // Create download task
    final task = DownloadTask(
      id: id,
      url: url,
      fileName: fileName,
      filePath: filePath,
      status: DownloadStatus.queued,
      cancelToken: CancelToken(),
    );

    _downloads[id] = task;
    _notifyListeners();

    // Start downloading
    _download(task);

    return id;
  }

  /// Internal download method
  Future<void> _download(DownloadTask task) async {
    try {
      task.status = DownloadStatus.downloading;
      _notifyListeners();

      await _dio.download(
        task.url,
        task.filePath,
        cancelToken: task.cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            task.downloadedBytes = received;
            task.totalBytes = total;
            task.progress = received / total;
            _notifyListeners();
          }
        },
      );

      task.status = DownloadStatus.completed;
      task.progress = 1.0;
      _notifyListeners();
    } catch (e) {
      if (task.cancelToken?.isCancelled ?? false) {
        task.status = DownloadStatus.cancelled;
        task.error = 'Download cancelled by user';
      } else {
        task.status = DownloadStatus.failed;
        task.error = e.toString();
      }
      _notifyListeners();
    }
  }

  /// Pause a download
  void pauseDownload(String id) {
    final task = _downloads[id];
    if (task != null && task.status == DownloadStatus.downloading) {
      task.cancelToken?.cancel('Paused by user');
      task.status = DownloadStatus.paused;
      _notifyListeners();
    }
  }

  /// Resume a paused download
  Future<void> resumeDownload(String id) async {
    final task = _downloads[id];
    if (task != null && task.status == DownloadStatus.paused) {
      task.cancelToken = CancelToken();
      await _download(task);
    }
  }

  /// Cancel a download
  void cancelDownload(String id) {
    final task = _downloads[id];
    if (task != null) {
      task.cancelToken?.cancel('Cancelled by user');
      task.status = DownloadStatus.cancelled;
      _notifyListeners();
    }
  }

  /// Retry a failed download
  Future<void> retryDownload(String id) async {
    final task = _downloads[id];
    if (task != null && task.status == DownloadStatus.failed) {
      task.cancelToken = CancelToken();
      task.error = null;
      task.progress = 0.0;
      task.downloadedBytes = 0;
      await _download(task);
    }
  }

  /// Remove a download from the list
  void removeDownload(String id) {
    _downloads.remove(id);
    _notifyListeners();
  }

  /// Clear completed downloads
  void clearCompleted() {
    _downloads.removeWhere(
      (key, value) => value.status == DownloadStatus.completed,
    );
    _notifyListeners();
  }

  /// Open downloaded file location
  Future<void> openFileLocation(String id) async {
    final task = _downloads[id];
    if (task != null && task.status == DownloadStatus.completed) {
      final directory = path.dirname(task.filePath);
      // Open file explorer at the location
      if (Platform.isWindows) {
        await Process.run('explorer', [directory]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [directory]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [directory]);
      }
    }
  }

  /// Get downloads directory
  Future<String> _getDownloadsDirectory() async {
    if (Platform.isWindows) {
      // Use Downloads folder on Windows
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        final downloadsPath = path.join(userProfile, 'Downloads', 'Tansen Games');
        final directory = Directory(downloadsPath);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        return downloadsPath;
      }
    }
    
    // Fallback to app documents directory
    final directory = await getApplicationDocumentsDirectory();
    final downloadsPath = path.join(directory.path, 'downloads');
    final downloadsDir = Directory(downloadsPath);
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    return downloadsPath;
  }

  void _notifyListeners() {
    _downloadsController.add(downloads);
  }

  void dispose() {
    _downloadsController.close();
  }
}
